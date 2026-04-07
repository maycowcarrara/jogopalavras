const { spawn } = require('node:child_process');
const fs = require('node:fs');
const path = require('node:path');

const rootDir = process.cwd();
const args = process.argv.slice(2);
const command = args[0];
const extraArgs = args.slice(1);

function readLocalProperties() {
  const localPropertiesPath = path.join(rootDir, 'android', 'local.properties');
  if (!fs.existsSync(localPropertiesPath)) {
    return {};
  }

  const content = fs.readFileSync(localPropertiesPath, 'utf8');
  return Object.fromEntries(
    content
      .split(/\r?\n/)
      .map((line) => line.trim())
      .filter((line) => line && !line.startsWith('#') && line.includes('='))
      .map((line) => {
        const index = line.indexOf('=');
        const key = line.slice(0, index).trim();
        const value = line.slice(index + 1).trim().replaceAll('\\\\', '\\');
        return [key, value];
      }),
  );
}

function resolveFlutterCommand() {
  const localProperties = readLocalProperties();
  const configuredSdk = localProperties['flutter.sdk'];

  if (configuredSdk) {
    const flutterBat = path.join(configuredSdk, 'bin', 'flutter.bat');
    if (fs.existsSync(flutterBat)) {
      return flutterBat;
    }
  }

  return 'flutter';
}

function printHelp() {
  console.log(`
Comandos disponíveis:
  npm run doctor
  npm run pub:get
  npm run android:devices
  npm run android:emulators
  npm run android:start -- <emulator-id>
  npm run dev
  npm run dev -- -d emulator-5554
  npm run dev:ads -- -d emulator-5554
  npm run analyze
  npm run test:flutter
  npm run build:apk
  npm run build:aab
  npm run build:aab:ads

Observações:
  - Para descobrir o emulator-id, rode: npm run android:emulators
  - Para ativar anúncios em build/teste, defina a variável ADMOB_ANDROID_INTERSTITIAL_ID.
`);
}

function withAdsDefines(baseArgs) {
  const adUnitId = process.env.ADMOB_ANDROID_INTERSTITIAL_ID ?? '';
  if (!adUnitId.trim()) {
    console.warn(
      'ADMOB_ANDROID_INTERSTITIAL_ID não definido. O build continuará sem ID real de anúncio.',
    );
    return baseArgs;
  }

  return [
    ...baseArgs,
    '--dart-define=ADS_ENABLED=true',
    `--dart-define=ADMOB_ANDROID_INTERSTITIAL_ID=${adUnitId}`,
  ];
}

function runFlutter(flutterArgs) {
  const flutterCommand = resolveFlutterCommand();
  const child = spawn(flutterCommand, flutterArgs, {
    cwd: rootDir,
    stdio: 'inherit',
    shell: false,
  });

  child.on('exit', (code) => {
    process.exit(code ?? 1);
  });
}

switch (command) {
  case 'doctor':
    runFlutter(['doctor', '-v', ...extraArgs]);
    break;
  case 'pub-get':
    runFlutter(['pub', 'get', ...extraArgs]);
    break;
  case 'devices':
    runFlutter(['devices', ...extraArgs]);
    break;
  case 'emulators':
    runFlutter(['emulators', ...extraArgs]);
    break;
  case 'emulator-start': {
    const emulatorId = extraArgs[0];
    if (!emulatorId) {
      console.error('Informe o ID do emulador. Exemplo: npm run android:start -- Pixel_7_API_35');
      process.exit(1);
    }
    runFlutter(['emulators', '--launch', emulatorId]);
    break;
  }
  case 'run': {
    const baseArgs = ['run', ...extraArgs.filter((arg) => arg !== '--ads')];
    const finalArgs = extraArgs.includes('--ads') ? withAdsDefines(baseArgs) : baseArgs;
    runFlutter(finalArgs);
    break;
  }
  case 'analyze':
    runFlutter(['analyze', '--no-pub', ...extraArgs]);
    break;
  case 'test':
    runFlutter(['test', '--no-pub', ...extraArgs]);
    break;
  case 'build-apk': {
    const baseArgs = ['build', 'apk', '--release', ...extraArgs.filter((arg) => arg !== '--ads')];
    const finalArgs = extraArgs.includes('--ads') ? withAdsDefines(baseArgs) : baseArgs;
    runFlutter(finalArgs);
    break;
  }
  case 'build-aab': {
    const baseArgs = [
      'build',
      'appbundle',
      '--release',
      ...extraArgs.filter((arg) => arg !== '--ads'),
    ];
    const finalArgs = extraArgs.includes('--ads') ? withAdsDefines(baseArgs) : baseArgs;
    runFlutter(finalArgs);
    break;
  }
  default:
    printHelp();
    process.exit(command ? 1 : 0);
}
