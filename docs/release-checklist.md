# Checklist de publicação

Use este checklist antes de enviar o primeiro `.aab` para a Play Console.

## Código e build

- [ ] Confirmar `version` e `build number` em `pubspec.yaml`.
- [ ] Confirmar `applicationId` definitivo em `android/app/build.gradle.kts`.
- [ ] Configurar `android/key.properties` com keystore de upload.
- [ ] Confirmar `ADMOB_ANDROID_APP_ID` real em `android/gradle.properties`.
- [ ] Confirmar `ADMOB_ANDROID_BANNER_ID` real em `package.json`.
- [ ] Confirmar `ADMOB_ANDROID_INTERSTITIAL_ID` real em `package.json`.
- [ ] Confirmar `docs/app-ads.txt` com `google.com, pub-5325559668232561, DIRECT, f08c47fec0942fa0`.
- [ ] Rodar `flutter analyze --no-pub`.
- [ ] Rodar `flutter test`.
- [ ] Gerar `.aab` de release.
- [ ] Confirmar que o build e `release`; nesse modo o ranking remoto usa a API publica por padrao.
- [ ] Confirmar que `ADMIN_LOGS_TOKEN` existe no Worker para consultar diagnosticos.
- [ ] Testar o bundle em teste interno antes de produção.

## Experiência

- [ ] Jogar uma partida em cada nível.
- [ ] Confirmar que o gesto de arraste não é interrompido por anúncios.
- [ ] Confirmar que banners, se ativos, ficam em áreas reservadas.
- [ ] Confirmar que interstitial aparece somente depois de pausa natural.
- [ ] Confirmar que o aviso de anúncios aparece na intro.
- [ ] Conferir áudio/mute em cada nível.
- [ ] Conferir visual em pelo menos um celular pequeno e um grande.
- [ ] Simular um diagnostico com `npm run admin:logs:simulate`.
- [ ] Consultar diagnosticos com `npm run admin:logs -- -Limit 5`.
- [ ] Em teste interno, abrir o app e confirmar que logs reais aparecem em `/admin/logs`
      se houver falha.

## Play Console

- [ ] Preencher categoria: Jogos > Palavras.
- [ ] Informar que contém anúncios, se AdMob estiver ativo.
- [ ] Declarar Advertising ID, se AdMob estiver ativo.
- [ ] Preencher Segurança de Dados considerando o SDK de anúncios.
- [ ] Preencher Classificação de Conteúdo.
- [ ] Inserir URL pública da política de privacidade.
- [ ] Ativar GitHub Pages em `Settings > Pages > Deploy from a branch > main > /docs`.
- [ ] Testar a URL `https://SEU_USUARIO.github.io/NOME_DO_REPO/privacy-policy.html`.
- [ ] Testar a URL `https://SEU_DOMINIO/app-ads.txt` e confirmar resposta em texto puro, sem cair no `index.html`.
- [ ] Enviar ícone, screenshots e feature graphic.
- [ ] Criar teste interno ou fechado.
- [ ] Revisar relatório pré-lançamento da Play Console.
- [ ] Corrigir crashes, ANRs ou problemas de política antes da produção.

## Sugestão de screenshots

- tela inicial com identidade de jornal;
- seleção de editoria/nível;
- tabuleiro em partida;
- progresso de palavra;
- aviso de anúncios discretos.
