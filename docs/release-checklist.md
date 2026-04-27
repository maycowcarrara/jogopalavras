# Checklist de publicacao

Use este checklist antes de enviar o primeiro `.aab` para a Play Console.

## Codigo e build

- [ ] Confirmar `version` e `build number` em `pubspec.yaml`.
- [ ] Confirmar `applicationId` definitivo em `android/app/build.gradle.kts`.
- [ ] Configurar `android/key.properties` com keystore de upload.
- [ ] Trocar `admob_app_id` em `android/app/src/main/res/values/strings.xml`.
- [ ] Definir `ADMOB_ANDROID_BANNER_ID` real, se banner for publicado.
- [ ] Definir `ADMOB_ANDROID_INTERSTITIAL_ID` real, se interstitial for
      publicado.
- [ ] Rodar `flutter analyze --no-pub`.
- [ ] Rodar `flutter test`.
- [ ] Gerar `.aab` de release.
- [ ] Testar o bundle em teste interno antes de producao.

## Experiencia

- [ ] Jogar uma partida em cada nivel.
- [ ] Confirmar que o gesto de arraste nao e interrompido por anuncios.
- [ ] Confirmar que banners, se ativos, ficam em areas reservadas.
- [ ] Confirmar que interstitial aparece somente depois de pausa natural.
- [ ] Confirmar que o aviso de anuncios aparece na intro.
- [ ] Conferir audio/mute em cada nivel.
- [ ] Conferir visual em pelo menos um celular pequeno e um grande.

## Play Console

- [ ] Preencher categoria: Jogos > Palavras.
- [ ] Informar que contem anuncios, se AdMob estiver ativo.
- [ ] Declarar Advertising ID, se AdMob estiver ativo.
- [ ] Preencher Segurança de Dados considerando o SDK de anuncios.
- [ ] Preencher Classificacao de Conteudo.
- [ ] Inserir URL publica da politica de privacidade.
- [ ] Enviar icone, screenshots e feature graphic.
- [ ] Criar teste interno ou fechado.
- [ ] Revisar relatorio pre-lancamento da Play Console.
- [ ] Corrigir crashes, ANRs ou problemas de politica antes da producao.

## Sugestao de screenshots

- tela inicial com identidade de jornal;
- selecao de editoria/nivel;
- tabuleiro em partida;
- progresso de palavra;
- aviso de anuncios discretos.
