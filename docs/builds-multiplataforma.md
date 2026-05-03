# Builds multiplataforma

Este guia deixa os comandos prontos para gerar builds web, desktop nativo e
Android App Bundle com arquitetura x64 para ChromeOS e Google Play Games on PC.

## Antes de gerar

Rode uma vez:

```powershell
npm run pub:get
npm run analyze
npm run test:flutter
```

Os comandos curtos tambem copiam os artefatos finais para a pasta `release/`
na raiz do projeto:

```powershell
npm run web
npm run aab
npm run exe
```

As saidas faceis ficam em:

```text
release/web
release/android/entreletras-playstore-pc.aab
release/windows/Entreletras-Windows
```

O `npm run web` tambem publica no Cloudflare Pages e imprime a URL:

```text
https://entreletras.pages.dev
```

No Windows, builds desktop com plugins exigem Developer Mode habilitado. Abra:

```powershell
start ms-settings:developers
```

Ative **Developer Mode**, feche e abra o terminal de novo.

## Web

Build web simples:

```powershell
npm run build:web
```

Build web apontando para o Worker de ranking em producao:

```powershell
npm run build:web:ranking:prod
```

Build web com Wasm:

```powershell
npm run build:web:wasm
```

Saida gerada:

```text
build/web
```

Essa pasta pode ir para Firebase Hosting, Cloudflare Pages, GitHub Pages ou
outro hosting estatico. Teste tambem em um servidor local, porque abrir
`index.html` direto pelo explorador pode quebrar carregamento de assets.

### Colocar a web em producao

O caminho recomendado neste projeto e Cloudflare Pages, porque o ranking ja usa
Cloudflare Workers.

Na primeira vez, entre na conta Cloudflare pelo Wrangler:

```powershell
workers\ranking-api\node_modules\.bin\wrangler.cmd login
```

Depois publique:

```powershell
npm run deploy:web:cloudflare
```

Esse comando gera `build/web` com `RANKING_API_URL` de producao e publica no
projeto Cloudflare Pages chamado `entreletras`. A URL fica no formato:

```text
https://entreletras.pages.dev
```

Para publicar a pasta `build/web` ja existente, sem gerar de novo:

```powershell
npm run deploy:web:cloudflare:existing
```

Para usar outro nome de projeto:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/deploy-web-cloudflare.ps1 -ProjectName meu-projeto -BuildFirst
```

Se ainda nao existir um projeto Pages com esse nome, o Wrangler pode pedir a
confirmacao de criacao durante o primeiro deploy.

## Desktop nativo

No Windows:

```powershell
npm run build:windows
```

Com ranking em producao:

```powershell
npm run build:windows:ranking:prod
```

Saida esperada:

```text
build/windows/x64/runner/Release
```

Linux e macOS precisam ser gerados nos respectivos sistemas:

```powershell
npm run build:linux
npm run build:macos
```

## ChromeOS pela Play Store

Gera um Android App Bundle com `android-x64` explicito para Chromebooks:

```powershell
npm run build:aab:chromeos
```

Com ranking em producao:

```powershell
npm run build:aab:chromeos:ranking:prod
```

Com ranking em producao e anuncios:

```powershell
npm run build:aab:chromeos:ads:ranking:prod
```

Saida gerada:

```text
build/app/outputs/bundle/release/app-release.aab
```

No Play Console, envie esse AAB em uma trilha de teste e confira a
compatibilidade com Chromebooks. Teste teclado, mouse, telas grandes e
redimensionamento da janela.

## Google Play Games on PC

Gera o AAB com `android-x64` explicito para o form factor de PC:

```powershell
npm run build:aab:play-pc
```

Com ranking em producao:

```powershell
npm run build:aab:play-pc:ranking:prod
```

Com ranking em producao e anuncios:

```powershell
npm run build:aab:play-pc:ads:ranking:prod
```

Depois de subir no Play Console, adicione o form factor **Google Play Games on
PC**, rode o jogo no Google Play Games on PC Developer Emulator e valide pelo
Game Readiness Checker.

## Observacoes importantes

- Os comandos `build:aab:*` usam `scripts/build-aab.ps1`, que incrementa a
  versao antes de gerar o bundle.
- Para builds com anuncios, mantenha `ADMOB_ANDROID_APP_ID` configurado no
  ambiente ou em Gradle properties antes de usar comandos com `ads`.
- `google_mobile_ads` e `in_app_update` sao recursos de Android/iOS. Em web e
  desktop nativo, o app deve continuar sem esses recursos.
