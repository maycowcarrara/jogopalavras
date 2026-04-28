# Ranking publico e diagnostico

O app pode usar ranking publico e envio remoto de diagnosticos quando for
compilado com a URL da API:

```powershell
C:\Flutter\flutter\bin\flutter.bat build appbundle --release --dart-define=RANKING_API_URL=https://anagrama-oculto-ranking.maycowcarrara.workers.dev
```

Sem `RANKING_API_URL`, o app continua usando ranking local no aparelho e os
diagnosticos ficam apenas na fila local.

## API

Foi incluido um Cloudflare Worker em `workers/ranking-api`.

Endpoints publicos:

- `GET /ranking?level=easy`
- `GET /ranking?level=medium`
- `GET /ranking?level=hard`
- `POST /ranking`
- `POST /logs`

Endpoint protegido:

- `GET /admin/logs`

Corpo do `POST /ranking`:

```json
{
  "initials": "ABC",
  "level": "easy",
  "score": 120,
  "words": 7,
  "elapsedSeconds": 84,
  "completedAt": "2026-04-28T12:00:00.000Z"
}
```

## Diagnostico de erros

O app tem captura global de erros para evitar a tela vermelha em producao:

- `FlutterError.onError`
- `PlatformDispatcher.instance.onError`
- `runZonedGuarded`
- `ErrorWidget.builder`

Quando acontece uma falha, o app mostra uma tela amigavel, salva um diagnostico
local e tenta enviar o evento para o Worker em `POST /logs`. Se a rede falhar,
o log fica em fila local e sera reenviado depois.

Os eventos nao devem incluir dados pessoais. O payload enviado pelo app contem
apenas informacoes tecnicas truncadas:

- timestamp
- origem do erro
- rota/tela atual
- tipo e mensagem do erro
- stack trace truncado
- plataforma
- versao/build mode
- contexto tecnico curto

No Worker, os logs ficam no mesmo KV do ranking com chaves no formato:

```text
logs:v1:AAAA-MM-DD:<uuid>
```

Eles expiram automaticamente em 30 dias.

## Consultar logs

O endpoint admin e protegido por `ADMIN_LOGS_TOKEN`:

```text
GET /admin/logs?limit=20
GET /admin/logs?date=2026-04-28&limit=50
GET /admin/logs?limit=50&cursor=...
```

O token pode ser enviado por `Authorization: Bearer <token>` ou
`x-admin-token: <token>`. No ambiente local deste projeto, o token fica em:

```text
workers/ranking-api/.wrangler/admin-logs-token.txt
```

Esse arquivo fica dentro de `.wrangler/`, que nao deve ir para o Git.

Comando recomendado:

```powershell
npm run admin:logs -- -Limit 20
```

Por padrao, esse comando imprime JSON completo para nao cortar `message` nem
`stackTrace`.

Resumo legivel no terminal:

```powershell
npm run admin:logs -- -Limit 20 -Format Summary
```

Filtrar por data:

```powershell
npm run admin:logs -- -Date 2026-04-28 -Limit 50
```

Consulta manual:

```powershell
$token = Get-Content -Raw workers/ranking-api/.wrangler/admin-logs-token.txt
Invoke-RestMethod `
  -Uri "https://anagrama-oculto-ranking.maycowcarrara.workers.dev/admin/logs?limit=20" `
  -Headers @{ Authorization = "Bearer $token" } |
  ConvertTo-Json -Depth 12
```

Se a resposta trouxer `cursor` e `listComplete` for `false`, use o cursor na
proxima chamada:

```powershell
npm run admin:logs -- -Limit 50 -Cursor "COLE_O_CURSOR_AQUI"
```

## Simular logs

Para testar o Worker sem depender do app:

```powershell
npm run admin:logs:simulate
npm run admin:logs -- -Limit 5
```

Para testar o pipeline pelo app, rode com `SIMULATE_ERROR_REPORT=true`. Isso
registra um diagnostico sintetico no startup sem crashar a experiencia:

```powershell
C:\Flutter\flutter\bin\flutter.bat run `
  --dart-define=RANKING_API_URL=https://anagrama-oculto-ranking.maycowcarrara.workers.dev `
  --dart-define=SIMULATE_ERROR_REPORT=true
```

Depois consulte:

```powershell
npm run admin:logs -- -Limit 5
```

## Deploy

1. Crie um namespace KV no Cloudflare:

```powershell
npx wrangler kv namespace create RANKING_KV
```

2. Copie o `id` gerado para `workers/ranking-api/wrangler.toml`.

3. Configure o token admin para consulta de logs:

```powershell
npx wrangler secret put ADMIN_LOGS_TOKEN
```

4. Publique:

```powershell
npm --prefix workers/ranking-api install
npm --prefix workers/ranking-api run deploy
```

5. Compile o app com:

```powershell
npm run build:aab:ranking:prod
```

O site em `docs/ranking.html` ja aponta para:

```text
https://anagrama-oculto-ranking.maycowcarrara.workers.dev
```

Observacao: o endpoint de ranking e publico para leitura e escrita. Ele valida
formato e limites basicos, mas nao impede pontuacao falsa enviada fora do app.
Para ranking competitivo real, o proximo passo e adicionar autenticacao ou
verificacao do servidor.
