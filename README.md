# Anagrama Oculto

Jogo mobile em Flutter focado em formar palavras em portugues dentro de um grid
com arraste, visual editorial inspirado em jornal e ritmo de rodada curto.

## O que existe hoje

- tela de introducao e selecao de nivel
- rodadas com baralho de palavras sem repeticao imediata
- tres niveis com grids `4x4`, `6x6` e `8x8`
- cabecalho compacto de pontuacao com meta de rodada
- card de progresso visual no meio da tela com "cena" sendo revelada aos poucos
- trilha de fundo por nivel com botao de mute na tela de jogo
- aviso claro sobre anuncios e objetivo do jogo
- preparacao para AdMob com banner reservado e interstitial em pausas naturais
- materiais de Play Store, privacidade e checklist de release em `docs/`

## Loop atual da partida

Cada rodada escolhe uma palavra alvo, espalha as letras no tabuleiro e o jogador monta a resposta arrastando o dedo.

- acerto: soma pontos e revela mais fragmentos da cena
- erro: reduz parte da pontuacao e limpa a tentativa atual
- objetivo: chegar a `100` pontos para fechar a rodada

As trilhas usadas nesta versao ficam em `assets/audio/`:

- `easy_loop.wav`
- `medium_loop.wav`
- `hard_loop.wav`

## Estrutura principal

- [`lib/src/screens/intro_screen.dart`](lib/src/screens/intro_screen.dart): entrada do app
- [`lib/src/screens/level_screen.dart`](lib/src/screens/level_screen.dart): escolha de nivel
- [`lib/src/screens/game_screen.dart`](lib/src/screens/game_screen.dart): loop principal da partida
- [`lib/src/game/word_bank.dart`](lib/src/game/word_bank.dart): banco de palavras
- [`lib/src/game/word_deck.dart`](lib/src/game/word_deck.dart): embaralhamento sem repeticao imediata
- [`lib/src/core/audio/game_music_service.dart`](lib/src/core/audio/game_music_service.dart): controle da musica de fundo
- [`lib/src/core/ads/ad_service.dart`](lib/src/core/ads/ad_service.dart): pausas naturais e interstitial

## Banco de palavras

As listas foram curadas a partir de fontes publicas em portugues brasileiro, filtrando palavras mais comuns, jogaveis e adequadas ao gesto de arraste.

Referencias usadas nesta base:

- `pythonprobr/palavras`
- `fserb/pt-br`

## Como rodar

No terminal da pasta do projeto:

```bash
flutter pub get
flutter run
```

Para validar rapidamente:

```bash
flutter analyze --no-pub
flutter test
```

## Android, anuncios e publicacao

Existe um guia rapido em [docs/playstore-e-anuncios.md](docs/playstore-e-anuncios.md) com os proximos passos para:

- trocar identificador Android
- configurar assinatura de release
- ativar AdMob com IDs reais
- gerar o app bundle para a Play Store
- preencher listagem, seguranca de dados e politica de privacidade

Materiais de publicacao:

- [docs/play-store-listing.md](docs/play-store-listing.md)
- [docs/privacy-policy.md](docs/privacy-policy.md)
- [docs/release-checklist.md](docs/release-checklist.md)
