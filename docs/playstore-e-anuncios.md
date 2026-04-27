# Play Store e anuncios

O projeto esta preparado para uma publicacao Android mais organizada, com foco
em jogo casual, inteligente e com anuncios nao intrusivos.

## Requisitos tecnicos

- `applicationId`: `br.com.mrcdev.anagramaoculto`.
- `minSdk`: controlado pelo Flutter atual.
- `targetSdk`: controlado pelo Flutter atual, hoje acima do minimo exigido pela
  Google Play para novos apps.
- assinatura de release: configurada via `android/key.properties`.
- formato de envio: Android App Bundle (`.aab`).
- anuncios: AdMob, desligado por padrao em release ate receber IDs reais por
  `dart-define`.

## Antes de publicar

1. Crie o app na Play Console com o nome `Anagrama Oculto`.
2. Confirme se o `applicationId` atual e definitivo para a sua marca. Depois de
   publicar, trocar o pacote significa publicar outro app.
3. Crie um `android/key.properties` a partir de `android/key.properties.example`.
4. Gere ou aponte para seu keystore de upload.
5. Substitua o `admob_app_id` de teste em
   `android/app/src/main/res/values/strings.xml` pelo App ID real do AdMob.
6. Ative anuncios apenas com IDs reais usando os `dart-define` abaixo.
7. Publique uma politica de privacidade em uma URL acessivel e use o texto-base
   em `docs/privacy-policy.md`.
8. Preencha Segurança de Dados, Anuncios e Classificacao de Conteudo na Play
   Console.
9. Suba primeiro para teste interno/fechado e jogue pelo menos uma rodada em cada
   nivel antes de promover para producao.

## Build sugerido

```bash
flutter build appbundle --release ^
  --dart-define=ADS_ENABLED=true ^
  --dart-define=ADMOB_ANDROID_BANNER_ID=seu_banner_id ^
  --dart-define=ADMOB_ANDROID_INTERSTITIAL_ID=seu_interstitial_id
```

Sem anuncios:

```bash
flutter build appbundle --release
```

## Estrategia de anuncios

- Banner opcional em areas reservadas da selecao de nivel e da tela de jogo.
- Interstitial somente em pausa natural, depois de partidas encerradas, a cada 3
  quebras naturais e com intervalo minimo de 3 minutos.
- Nada aparece no meio do gesto, no inicio de uma jogada ou antes da acao
  escolhida pelo usuario acontecer.
- A intro explica por que os anuncios existem e como eles aparecem.
- Em debug, o app usa IDs de teste do Google.
- Em release, anuncios ficam desligados por padrao ate voce fornecer IDs reais.

## Dados e privacidade

O app nao cria conta, nao pede nome, email ou telefone e nao salva dados em
servidor proprio. Se AdMob for ativado, o SDK de anuncios pode tratar dados
como identificadores do dispositivo, informacoes de anuncios, diagnosticos e
interacoes para exibir/medir publicidade. Isso deve constar na politica de
privacidade e no formulario de Segurança de Dados.

Para lancamento internacional, configure consentimento quando exigido por lei
local, especialmente EEA/Reino Unido, antes de ativar anuncios personalizados.

## Campos da Play Console

- **Contem anuncios**: sim, se publicar com AdMob ligado.
- **Categoria**: Jogos > Palavras.
- **Publico-alvo**: recomendado como publico geral, sem declarar foco em
  criancas, a menos que voce adapte conteudo, anuncios e formulario para
  Families Policy.
- **Classificacao indicativa esperada**: baixa/adequada para todos, mas a
  classificacao final vem do questionario oficial.
- **Permissoes sensiveis**: nenhuma permissao sensivel adicionada pelo app.
- **Advertising ID**: declare uso se AdMob estiver ativo.

## Materiais incluidos

- `docs/play-store-listing.md`: textos para listagem.
- `docs/privacy-policy.md`: texto-base de politica de privacidade.
- `docs/release-checklist.md`: checklist final antes de enviar o `.aab`.
