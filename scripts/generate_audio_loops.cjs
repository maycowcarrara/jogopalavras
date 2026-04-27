const fs = require('fs');
const path = require('path');

const sampleRate = 22050;
const seconds = 16;
const totalSamples = sampleRate * seconds;
const outDir = path.join(__dirname, '..', 'assets', 'audio');

const tracks = [
  {
    file: 'easy_loop.wav',
    bpm: 72,
    root: 60,
    scale: [0, 2, 4, 7, 9],
    chord: [0, 7, 12],
    padGain: 0.09,
    noteGain: 0.18,
    tickGain: 0.018,
    pattern: [0, 2, 4, 2, 7, 4, 2, 0],
  },
  {
    file: 'medium_loop.wav',
    bpm: 84,
    root: 62,
    scale: [0, 2, 3, 5, 7, 9],
    chord: [0, 5, 10],
    padGain: 0.08,
    noteGain: 0.16,
    tickGain: 0.024,
    pattern: [0, 3, 5, 7, 5, 3, 9, 5],
  },
  {
    file: 'hard_loop.wav',
    bpm: 90,
    root: 57,
    scale: [0, 2, 3, 5, 7, 8, 10],
    chord: [0, 7, 10],
    padGain: 0.075,
    noteGain: 0.15,
    tickGain: 0.026,
    pattern: [0, 3, 7, 10, 8, 7, 5, 3],
  },
];

function midiToFrequency(midi) {
  return 440 * 2 ** ((midi - 69) / 12);
}

function envelope(time, duration) {
  if (time < 0 || time > duration) {
    return 0;
  }

  const attack = Math.min(0.035, duration * 0.18);
  const release = Math.min(0.18, duration * 0.36);

  if (time < attack) {
    return time / attack;
  }

  if (time > duration - release) {
    return Math.max(0, (duration - time) / release);
  }

  return 1;
}

function bell(frequency, time) {
  const decay = Math.exp(-time * 2.4);
  const fundamental = Math.sin(2 * Math.PI * frequency * time);
  const overtone = Math.sin(2 * Math.PI * frequency * 2.01 * time) * 0.32;
  return (fundamental + overtone) * decay;
}

function padVoice(frequency, time) {
  const slow = 0.72 + Math.sin(2 * Math.PI * 0.08 * time) * 0.12;
  const base = Math.sin(2 * Math.PI * frequency * time);
  const soft = Math.sin(2 * Math.PI * frequency * 0.5 * time) * 0.46;
  return (base * 0.36 + soft) * slow;
}

function tick(time, beatSeconds, gain) {
  const phase = time % beatSeconds;
  if (phase > 0.045) {
    return 0;
  }

  const decay = Math.exp(-phase * 72);
  return Math.sin(2 * Math.PI * 1200 * phase) * decay * gain;
}

function fadeLoop(value, time) {
  const edge = 0.09;
  const start = Math.min(1, time / edge);
  const end = Math.min(1, (seconds - time) / edge);
  return value * Math.min(start, end);
}

function renderTrack(track) {
  const beatSeconds = 60 / track.bpm;
  const stepSeconds = beatSeconds * 2;
  const buffer = Buffer.alloc(44 + totalSamples * 2);

  writeWavHeader(buffer, totalSamples);

  for (let i = 0; i < totalSamples; i++) {
    const time = i / sampleRate;
    let sample = 0;

    for (const interval of track.chord) {
      sample += padVoice(midiToFrequency(track.root + interval - 12), time) * track.padGain;
    }

    for (let step = 0; step < Math.ceil(seconds / stepSeconds); step++) {
      const start = step * stepSeconds;
      const local = time - start;
      const noteDuration = stepSeconds * 0.92;

      if (local >= 0 && local <= noteDuration) {
        const scaleIndex = track.pattern[step % track.pattern.length];
        const midi = track.root + track.scale[scaleIndex % track.scale.length] + 12;
        sample +=
          bell(midiToFrequency(midi), local) *
          envelope(local, noteDuration) *
          track.noteGain;
      }
    }

    sample += tick(time, beatSeconds * 4, track.tickGain);
    sample = Math.tanh(fadeLoop(sample, time) * 1.1);

    buffer.writeInt16LE(Math.round(sample * 32767), 44 + i * 2);
  }

  fs.writeFileSync(path.join(outDir, track.file), buffer);
}

function writeWavHeader(buffer, samples) {
  const dataSize = samples * 2;
  buffer.write('RIFF', 0);
  buffer.writeUInt32LE(36 + dataSize, 4);
  buffer.write('WAVE', 8);
  buffer.write('fmt ', 12);
  buffer.writeUInt32LE(16, 16);
  buffer.writeUInt16LE(1, 20);
  buffer.writeUInt16LE(1, 22);
  buffer.writeUInt32LE(sampleRate, 24);
  buffer.writeUInt32LE(sampleRate * 2, 28);
  buffer.writeUInt16LE(2, 32);
  buffer.writeUInt16LE(16, 34);
  buffer.write('data', 36);
  buffer.writeUInt32LE(dataSize, 40);
}

fs.mkdirSync(outDir, { recursive: true });
for (const track of tracks) {
  renderTrack(track);
  console.log(`generated ${track.file}`);
}
