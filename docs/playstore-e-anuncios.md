# Play Store e anúncios

O projeto está preparado para uma publicação Android mais organizada, com foco
em jogo casual, inteligente e com anúncios não intrusivos.

## Requisitos técnicos

- `applicationId`: `br.com.mrcdev.entreletras`.
- `minSdk`: controlado pelo Flutter atual.
- `targetSdk`: controlado pelo Flutter atual, hoje acima do mínimo exigido pela
  Google Play para novos apps.
- assinatura de release: configurada via `android/key.properties`.
- formato de envio: Android App Bundle (`.aab`).
- partidas: jogáveis offline; ranking online, anúncios e diagnósticos dependem
  de conexão.
- anúncios: AdMob, desligado por padrão em release até receber IDs reais por
  `dart-define`.

## Antes de publicar

1. Crie o app na Play Console com o nome `Entreletras: Palavras Ocultas`.
2. Confirme se o `applicationId` atual é definitivo para a sua marca. Depois de
   publicar, trocar o pacote significa publicar outro app.
3. Crie um `android/key.properties` a partir de `android/key.properties.example`.
4. Gere ou aponte para seu keystore de upload.
5. Confirme se os IDs reais do AdMob continuam configurados em
   `android/gradle.properties` e `package.json`.
6. Ative anúncios usando o script `npm run build:aab:ads`.
7. Publique a política de privacidade pelo GitHub Pages usando
   `docs/privacy-policy.html`.
8. Preencha Segurança de Dados, Anúncios e Classificação de Conteúdo na Play
   Console.
9. Suba primeiro para teste interno/fechado e jogue pelo menos uma rodada em cada
   nível antes de promover para produção.

## Build sugerido

```bash
npm run build:aab:ads
```

Sem anúncios:

```bash
flutter build appbundle --release
```

## Estratégia de anúncios

- Banner opcional em áreas reservadas da seleção de nível e da tela de jogo.
- Interstitial somente em pausa natural, depois de partidas encerradas, a cada 3
  quebras naturais e com intervalo mínimo de 3 minutos.
- Nada aparece no meio do gesto, no início de uma jogada ou antes da ação
  escolhida pelo usuário acontecer.
- A intro explica por que os anúncios existem e como eles aparecem.
- Em debug, o app usa IDs de teste do Google.
- Em release, anúncios ficam desligados por padrão até você fornecer IDs reais.

## Dados e privacidade

O app não cria conta e não pede nome, email ou telefone. O ranking online pode
armazenar assinatura, pontuação e dados de rodada, e os diagnósticos podem
armazenar informações técnicas de falhas por até 30 dias. Se AdMob for ativado,
o SDK de anúncios pode tratar dados como identificadores do dispositivo,
informações de anúncios, diagnósticos e interações para exibir/medir
publicidade. Isso deve constar na política de privacidade e no formulário de
Segurança de Dados.

Para lançamento internacional, configure consentimento quando exigido por lei
local, especialmente EEA/Reino Unido, antes de ativar anúncios personalizados.

## Campos da Play Console

- **Contém anúncios**: sim, se publicar com AdMob ligado.
- **Categoria**: Jogos > Palavras.
- **Público-alvo**: recomendado como público geral, sem declarar foco em
  crianças, a menos que você adapte conteúdo, anúncios e formulário para
  Families Policy.
- **Classificação indicativa esperada**: baixa/adequada para todos, mas a
  classificação final vem do questionário oficial.
- **Permissões sensíveis**: nenhuma permissão sensível adicionada pelo app.
- **Advertising ID**: declare uso se AdMob estiver ativo.

## Materiais incluídos

- `docs/play-store-listing.md`: textos para listagem.
- `docs/privacy-policy.md`: texto-base de política de privacidade.
- `docs/privacy-policy.html`: página pública pronta para GitHub Pages.
- `docs/index.html`: página inicial simples do app para GitHub Pages.
- `docs/release-checklist.md`: checklist final antes de enviar o `.aab`.

## Publicar a política pelo GitHub Pages

Use o próprio repositório do app:

1. Faça commit e push dos arquivos da pasta `docs/`.
2. No GitHub, abra o repositório e vá em `Settings > Pages`.
3. Em `Build and deployment`, escolha `Deploy from a branch`.
4. Em `Branch`, selecione `main` e a pasta `/docs`.
5. Salve e aguarde o deploy.

Depois do deploy, a política fica em uma URL neste formato:

```text
https://SEU_USUARIO.github.io/NOME_DO_REPO/privacy-policy.html
```

Se o repositório pertencer a uma organização, use o nome da organização no lugar
de `SEU_USUARIO`. Essa é a URL para informar no campo de política de privacidade
da Play Console.
