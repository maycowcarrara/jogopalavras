# Play Store e anuncios

O projeto ja ficou preparado para uma publicacao Android mais organizada.

## Antes de publicar

- Troque `namespace` e `applicationId` em `android/app/build.gradle.kts` por um identificador unico seu.
- Crie um `android/key.properties` a partir de `android/key.properties.example`.
- Gere ou aponte para seu keystore de upload.
- Substitua o `admob_app_id` de teste em `android/app/src/main/res/values/strings.xml` pelo App ID real do AdMob.
- Ative anuncios apenas com IDs reais usando `--dart-define=ADS_ENABLED=true` e `--dart-define=ADMOB_ANDROID_INTERSTITIAL_ID=...`.
- Revise politica de privacidade, formulario de seguranca de dados e classificacao de conteudo na Play Console.

## Build sugerido

```bash
flutter build appbundle --release --dart-define=ADS_ENABLED=true --dart-define=ADMOB_ANDROID_INTERSTITIAL_ID=seu_id
```

## Estrategia de anuncios

- O app foi configurado para usar interstitial somente em pausas naturais, a cada 3 encerramentos de partida.
- Em debug, ele usa o ID de teste do Google.
- Em release, anuncios ficam desligados por padrao ate voce fornecer o ID real por `dart-define`.
