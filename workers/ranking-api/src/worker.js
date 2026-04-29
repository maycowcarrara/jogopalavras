const LEVELS = new Set(["easy", "medium", "hard", "pautaLivre"]);
const MAX_ENTRIES = 10;
const MAX_LOG_EVENTS = 8;
const MAX_LOGS_PER_MINUTE = 30;
const LOG_TTL_SECONDS = 60 * 60 * 24 * 30;
const STARTING_SCORES = {
  easy: 1000,
  medium: 1250,
  hard: 1500,
  pautaLivre: 1450,
};
const POINTS_PER_WORD = 30;
const POINTS_PER_SECOND = 1;
const POINTS_PER_ERROR = 50;
const POINTS_PER_HINT = 0;
const POINTS_PER_SKIP = 160;
const CORS_HEADERS = {
  "access-control-allow-origin": "*",
  "access-control-allow-methods": "GET,POST,OPTIONS",
  "access-control-allow-headers": "authorization,content-type,x-admin-token",
  "access-control-max-age": "86400",
};

export default {
  async fetch(request, env) {
    if (request.method === "OPTIONS") {
      return new Response(null, { headers: CORS_HEADERS });
    }

    const url = new URL(request.url);
    if (url.pathname === "/health") {
      return json({ ok: true });
    }

    if (url.pathname === "/admin/logs") {
      if (request.method !== "GET") {
        return json({ error: "method_not_allowed" }, 405);
      }

      return handleAdminLogsGet(url, request, env);
    }

    if (url.pathname === "/logs") {
      if (request.method !== "POST") {
        return json({ error: "method_not_allowed" }, 405);
      }

      return handleLogPost(request, env);
    }

    if (url.pathname === "/players") {
      if (request.method === "GET") {
        return handlePlayersGet(url, env);
      }

      if (request.method === "POST") {
        return handlePlayersPost(request, env);
      }

      return json({ error: "method_not_allowed" }, 405);
    }

    if (url.pathname !== "/ranking") {
      return json({ error: "not_found" }, 404);
    }

    if (request.method === "GET") {
      return handleGet(url, env);
    }

    if (request.method === "POST") {
      return handlePost(request, env);
    }

    return json({ error: "method_not_allowed" }, 405);
  },
};

async function handleGet(url, env) {
  const level = url.searchParams.get("level");
  const stageNumber = normalizeStageNumber(url.searchParams.get("stage"));
  if (level && !LEVELS.has(level)) {
    return json({ error: "invalid_level" }, 400);
  }
  if (url.searchParams.has("stage") && !stageNumber) {
    return json({ error: "invalid_stage" }, 400);
  }
  if (stageNumber && !level) {
    return json({ error: "level_required" }, 400);
  }

  const entries = level
    ? await readLevel(env, level, stageNumber)
    : (await Promise.all([...LEVELS].map((item) => readLevel(env, item)))).flat();

  return json({ entries: sortEntries(entries).slice(0, MAX_ENTRIES) });
}

async function handlePost(request, env) {
  let body;
  try {
    body = await request.json();
  } catch {
    return json({ error: "invalid_json" }, 400);
  }

  const entry = normalizeEntry(body);
  if (!entry) {
    return json({ error: "invalid_entry" }, 400);
  }

  await reserveLegacyInitials(env, [entry]);
  const entries = await readLevel(env, entry.level, entry.stageNumber);
  entries.push(entry);
  const ranking = sortEntries(entries).slice(0, MAX_ENTRIES);
  await env.RANKING_KV.put(
    keyFor(entry.level, entry.stageNumber),
    JSON.stringify(ranking),
  );

  return json({ entries: ranking }, 201);
}

async function handlePlayersGet(url, env) {
  const initials = normalizeInitials(url.searchParams.get("initials"));
  const ownerId = normalizeOwnerId(url.searchParams.get("ownerId"));

  if (!initials) {
    return json({ error: "invalid_initials" }, 400);
  }

  await backfillLegacyInitials(env);
  const available = await isInitialsAvailable(env, initials, {
    ownerId,
    previousInitials: initials,
  });

  return json({ initials, available });
}

async function handlePlayersPost(request, env) {
  let body;
  try {
    body = await request.json();
  } catch {
    return json({ error: "invalid_json" }, 400);
  }

  const initials = normalizeInitials(body?.initials);
  const previousInitials = normalizeInitials(body?.previousInitials);
  const ownerId = normalizeOwnerId(body?.ownerId);

  if (!initials || !ownerId) {
    return json({ error: "invalid_player" }, 400);
  }

  await backfillLegacyInitials(env);
  const available = await isInitialsAvailable(env, initials, {
    ownerId,
    previousInitials,
  });
  if (!available) {
    return json({ error: "initials_unavailable" }, 409);
  }

  const now = new Date().toISOString();
  await env.RANKING_KV.put(
    playerKeyFor(initials),
    JSON.stringify({ initials, ownerId, claimedAt: now }),
  );

  if (previousInitials && previousInitials !== initials) {
    const previous = await env.RANKING_KV.get(
      playerKeyFor(previousInitials),
      "json",
    );
    if (previous?.ownerId === ownerId) {
      await env.RANKING_KV.delete(playerKeyFor(previousInitials));
    }
  }

  return json({ initials, ok: true }, 201);
}

async function handleAdminLogsGet(url, request, env) {
  if (!env.ADMIN_LOGS_TOKEN) {
    return json({ error: "admin_disabled" }, 404);
  }

  if (!(await isAdminAuthorized(request, env))) {
    return json({ error: "unauthorized" }, 401);
  }

  const requestedLimit = Number(url.searchParams.get("limit") ?? "50");
  const limit = Number.isInteger(requestedLimit)
    ? Math.min(Math.max(requestedLimit, 1), 100)
    : 50;
  const cursor = cleanText(url.searchParams.get("cursor"), 500) || undefined;
  const date = cleanText(url.searchParams.get("date"), 10);
  const prefix = /^\d{4}-\d{2}-\d{2}$/.test(date)
    ? `logs:v1:${date}:`
    : "logs:v1:";

  const listed = await env.RANKING_KV.list({ prefix, limit, cursor });
  const entries = (
    await Promise.all(
      listed.keys.map(async (item) => {
        const event = await env.RANKING_KV.get(item.name, "json");
        return event ? { key: item.name, ...event } : null;
      }),
    )
  )
    .filter(Boolean)
    .sort((a, b) => new Date(b.receivedAt) - new Date(a.receivedAt));

  return json({
    entries,
    cursor: listed.cursor ?? null,
    listComplete: listed.list_complete,
  });
}

async function handleLogPost(request, env) {
  if (!(await allowLogRequest(request, env))) {
    return json({ error: "rate_limited" }, 429);
  }

  let body;
  try {
    body = await request.json();
  } catch {
    return json({ error: "invalid_json" }, 400);
  }

  const rawEvents = Array.isArray(body?.events) ? body.events : [body];
  const events = rawEvents
    .slice(0, MAX_LOG_EVENTS)
    .map(normalizeLogEvent)
    .filter(Boolean);

  if (events.length === 0) {
    return json({ error: "invalid_log" }, 400);
  }

  const day = new Date().toISOString().slice(0, 10);
  await Promise.all(
    events.map((event) =>
      env.RANKING_KV.put(
        `logs:v1:${day}:${crypto.randomUUID()}`,
        JSON.stringify(event),
        { expirationTtl: LOG_TTL_SECONDS },
      ),
    ),
  );

  return json({ ok: true, accepted: events.length }, 202);
}

async function readLevel(env, level, stageNumber = 0) {
  if (stageNumber > 0) {
    return readBucket(env, keyFor(level, stageNumber));
  }

  const legacyEntries = await readBucket(env, keyFor(level));
  const listed = await env.RANKING_KV.list({
    prefix: `ranking:v2:${level}:`,
    limit: 100,
  });
  const stageEntries = (
    await Promise.all(listed.keys.map((item) => readBucket(env, item.name)))
  ).flat();

  return [...legacyEntries, ...stageEntries];
}

async function readBucket(env, key) {
  const rawEntries = await env.RANKING_KV.get(key, "json");
  return Array.isArray(rawEntries)
    ? rawEntries.map(normalizeEntry).filter(Boolean)
    : [];
}

function normalizeEntry(entry) {
  const initials = normalizeInitials(entry?.initials);
  const level = String(entry?.level ?? "");
  const stageNumber = normalizeStageNumber(
    entry?.stageNumber ?? entry?.stage,
  );
  const score = Number(entry?.score);
  const words = Number(entry?.words);
  const elapsedSeconds = Number(entry?.elapsedSeconds);
  const errors = Number(entry?.errors ?? 0);
  const hintsUsed = Number(entry?.hintsUsed ?? 0);
  const skipsUsed = Number(entry?.skipsUsed ?? 0);
  const completedAt = new Date(entry?.completedAt ?? Date.now());

  if (!initials) {
    return null;
  }
  if (!LEVELS.has(level)) {
    return null;
  }
  if (
    !Number.isInteger(score) ||
    score < 0 ||
    score > startingScoreForLevel(level)
  ) {
    return null;
  }
  if (!Number.isInteger(words) || words < 1 || words > 100) {
    return null;
  }
  if (
    !Number.isInteger(elapsedSeconds) ||
    elapsedSeconds < 0 ||
    elapsedSeconds > 86400
  ) {
    return null;
  }
  if (!Number.isInteger(errors) || errors < 0 || errors > 100) {
    return null;
  }
  if (!Number.isInteger(hintsUsed) || hintsUsed < 0 || hintsUsed > 100) {
    return null;
  }
  if (!Number.isInteger(skipsUsed) || skipsUsed < 0 || skipsUsed > 100) {
    return null;
  }
  if (Number.isNaN(completedAt.valueOf())) {
    return null;
  }

  return {
    initials,
    level,
    score: scoreForPerformance(
      level,
      words,
      elapsedSeconds,
      errors,
      hintsUsed,
      skipsUsed,
    ),
    words,
    elapsedSeconds,
    errors,
    hintsUsed,
    skipsUsed,
    completedAt: completedAt.toISOString(),
    stageNumber,
  };
}

function scoreForPerformance(
  level,
  words,
  elapsedSeconds,
  errors,
  hintsUsed,
  skipsUsed,
) {
  return Math.max(
    0,
    startingScoreForLevel(level) -
      words * POINTS_PER_WORD -
      elapsedSeconds * POINTS_PER_SECOND -
      errors * POINTS_PER_ERROR -
      hintsUsed * POINTS_PER_HINT -
      skipsUsed * POINTS_PER_SKIP,
  );
}

function startingScoreForLevel(level) {
  return STARTING_SCORES[level] ?? STARTING_SCORES.easy;
}

function sortEntries(entries) {
  return [...entries].sort((a, b) => {
    if (b.score !== a.score) {
      return b.score - a.score;
    }
    if (a.words !== b.words) {
      return a.words - b.words;
    }
    if (a.elapsedSeconds !== b.elapsedSeconds) {
      return a.elapsedSeconds - b.elapsedSeconds;
    }
    return new Date(a.completedAt) - new Date(b.completedAt);
  });
}

function keyFor(level, stageNumber = 0) {
  return stageNumber > 0
    ? `ranking:v2:${level}:${stageNumber}`
    : `ranking:v1:${level}`;
}

function playerKeyFor(initials) {
  return `player:v1:${initials}`;
}

async function backfillLegacyInitials(env) {
  const entries = (
    await Promise.all([...LEVELS].map((level) => readLevel(env, level)))
  ).flat();
  await reserveLegacyInitials(env, entries);
}

async function reserveLegacyInitials(env, entries) {
  const initialsList = [
    ...new Set(entries.map((entry) => normalizeInitials(entry.initials)).filter(Boolean)),
  ];

  await Promise.all(
    initialsList.map(async (initials) => {
      const key = playerKeyFor(initials);
      const reservation = await env.RANKING_KV.get(key, "json");
      if (reservation?.ownerId) {
        return;
      }

      await env.RANKING_KV.put(
        key,
        JSON.stringify({
          initials,
          ownerId: `legacy:${initials}`,
          claimedAt: new Date().toISOString(),
          legacy: true,
        }),
      );
    }),
  );
}

async function isInitialsAvailable(
  env,
  initials,
  { ownerId, previousInitials } = {},
) {
  const reservation = await env.RANKING_KV.get(playerKeyFor(initials), "json");
  if (reservation?.ownerId && reservation.ownerId !== ownerId) {
    return false;
  }

  if (reservation?.ownerId === ownerId) {
    return true;
  }

  if (previousInitials === initials) {
    return true;
  }

  const entries = (
    await Promise.all([...LEVELS].map((level) => readLevel(env, level)))
  ).flat();
  return !entries.some((entry) => entry.initials === initials);
}

function normalizeInitials(value) {
  const initials = String(value ?? "").trim().toUpperCase();
  return /^[A-Z]{3,5}$/.test(initials) ? initials : "";
}

function normalizeStageNumber(value) {
  if (value === undefined || value === null || value === "") {
    return 0;
  }

  const stageNumber = Number(value);
  return Number.isInteger(stageNumber) && stageNumber > 0 && stageNumber <= 999
    ? stageNumber
    : 0;
}

function normalizeOwnerId(value) {
  const ownerId = String(value ?? "").trim();
  return /^[A-Za-z0-9_-]{16,80}$/.test(ownerId) ? ownerId : "";
}

async function allowLogRequest(request, env) {
  const ip =
    request.headers.get("cf-connecting-ip") ||
    request.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ||
    "unknown";
  const ipHash = await sha256Hex(ip);
  const minute = Math.floor(Date.now() / 60000);
  const key = `logs:rate:v1:${minute}:${ipHash}`;
  const current = Number((await env.RANKING_KV.get(key)) ?? "0");

  if (current >= MAX_LOGS_PER_MINUTE) {
    return false;
  }

  await env.RANKING_KV.put(key, String(current + 1), { expirationTtl: 120 });
  return true;
}

async function isAdminAuthorized(request, env) {
  const authorization = request.headers.get("authorization") ?? "";
  const bearer = authorization.match(/^Bearer\s+(.+)$/i)?.[1] ?? "";
  const token = bearer || request.headers.get("x-admin-token") || "";

  if (!token) {
    return false;
  }

  const [expectedHash, tokenHash] = await Promise.all([
    sha256Hex(env.ADMIN_LOGS_TOKEN),
    sha256Hex(token),
  ]);

  return expectedHash === tokenHash;
}

function normalizeLogEvent(event) {
  const timestamp = new Date(event?.timestamp ?? Date.now());
  const message = cleanText(event?.message, 700);

  if (Number.isNaN(timestamp.valueOf()) || message.length === 0) {
    return null;
  }

  return {
    timestamp: timestamp.toISOString(),
    source: cleanText(event?.source, 80),
    fatal: Boolean(event?.fatal),
    route: cleanText(event?.route, 120),
    errorType: cleanText(event?.errorType, 120),
    message,
    stackTrace: cleanText(event?.stackTrace, 3200),
    platform: cleanText(event?.platform, 40),
    appVersion: cleanText(event?.appVersion, 40),
    buildMode: cleanText(event?.buildMode, 20),
    context: cleanContext(event?.context),
    receivedAt: new Date().toISOString(),
  };
}

function cleanContext(context) {
  if (!context || typeof context !== "object" || Array.isArray(context)) {
    return {};
  }

  const clean = {};
  for (const [key, value] of Object.entries(context).slice(0, 12)) {
    const cleanKey = cleanText(key, 64);
    if (!cleanKey) {
      continue;
    }

    if (
      value === null ||
      typeof value === "boolean" ||
      typeof value === "number"
    ) {
      clean[cleanKey] = value;
    } else {
      clean[cleanKey] = cleanText(value, 240);
    }
  }
  return clean;
}

function cleanText(value, maxLength) {
  const text = String(value ?? "")
    .replace(/[\u0000-\u0008\u000B\u000C\u000E-\u001F]/g, " ")
    .trim();
  return text.length > maxLength ? `${text.slice(0, maxLength)}...` : text;
}

async function sha256Hex(value) {
  const data = new TextEncoder().encode(value);
  const digest = await crypto.subtle.digest("SHA-256", data);
  return [...new Uint8Array(digest)]
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

function json(payload, status = 200) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      ...CORS_HEADERS,
      "content-type": "application/json; charset=utf-8",
      "cache-control": "no-store",
    },
  });
}
