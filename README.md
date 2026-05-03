# Entreletras: Palavras Ocultas

Jogo mobile em Flutter focado em revelar palavras ocultas em português dentro
de um grid com arraste, visual editorial inspirado em jornal e ritmo de rodada
curto.

## O que existe hoje

- tela de introdução e seleção de nível
- rodadas com baralho de palavras sem repetição imediata
- três níveis com grids `4x4`, `6x6` e `8x8`
- cabeçalho compacto de pontuação com meta de rodada
- card de progresso visual no meio da tela com "cena" sendo revelada aos poucos
- playlist de trilha de fundo alternando entre as musicas de `assets/audio/`
  com botão de mute na tela de jogo
- aviso claro sobre anúncios e objetivo do jogo
- preparação para AdMob com banner reservado e interstitial em pausas naturais
- ranking publico e diagnosticos remotos via Cloudflare Worker
- materiais de Play Store, privacidade e checklist de release em `docs/`

## Loop atual da partida

Cada rodada escolhe uma palavra alvo, espalha as letras no tabuleiro e o jogador monta a resposta arrastando o dedo.

- acerto: soma pontos e revela mais fragmentos da cena
- erro: reduz parte da pontuação e limpa a tentativa atual
- objetivo: chegar a `150` pontos para fechar a rodada

As trilhas usadas nesta versão ficam em `assets/audio/`. A pasta inteira esta
declarada no `pubspec.yaml`, entao esses arquivos ja sao empacotados no app.

O app inicia uma faixa de acordo com o nivel escolhido e, ao final de cada MP3,
avanca automaticamente para a proxima musica da playlist.

Para gerar MP3s menores, instale o `ffmpeg` e rode:

```powershell
npm run audio:compress
```

Por padrao, os arquivos compactados sao escritos em `assets/audio-compressed/`.
Para substituir os MP3s usados pelo app e manter backup dos originais em
`assets/audio-original/`:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/compress-audio.ps1 -InPlace
```

## Estrutura principal

- [`lib/src/screens/intro_screen.dart`](lib/src/screens/intro_screen.dart): entrada do app
- [`lib/src/screens/level_screen.dart`](lib/src/screens/level_screen.dart): escolha de nível
- [`lib/src/screens/game_screen.dart`](lib/src/screens/game_screen.dart): loop principal da partida
- [`lib/src/game/word_bank.dart`](lib/src/game/word_bank.dart): banco de palavras
- [`lib/src/game/word_deck.dart`](lib/src/game/word_deck.dart): embaralhamento sem repetição imediata
- [`lib/src/core/audio/game_music_service.dart`](lib/src/core/audio/game_music_service.dart): controle da música de fundo
- [`lib/src/core/ads/ad_service.dart`](lib/src/core/ads/ad_service.dart): pausas naturais e interstitial

## Banco de palavras

As listas foram curadas a partir de fontes públicas em português brasileiro, filtrando palavras mais comuns, jogáveis e adequadas ao gesto de arraste.

Referências usadas nesta base:

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

## Android, anúncios e publicação

Existe um guia rápido em [docs/playstore-e-anuncios.md](docs/playstore-e-anuncios.md) com os próximos passos para:

- trocar identificador Android
- configurar assinatura de release
- ativar AdMob com IDs reais
- gerar o app bundle para a Play Store
- preencher listagem, segurança de dados e política de privacidade

Materiais de publicação:

- [docs/builds-multiplataforma.md](docs/builds-multiplataforma.md)
- [docs/ranking-api.md](docs/ranking-api.md)
- [docs/index.html](docs/index.html)
- [docs/privacy-policy.html](docs/privacy-policy.html)
- [docs/play-store-listing.md](docs/play-store-listing.md)
- [docs/privacy-policy.md](docs/privacy-policy.md)
- [docs/release-checklist.md](docs/release-checklist.md)

Para publicar a política de privacidade no GitHub Pages, use `Settings > Pages`,
selecione `Deploy from a branch`, branch `main` e pasta `/docs`. A URL ficará no
formato `https://SEU_USUARIO.github.io/NOME_DO_REPO/privacy-policy.html`.

## Logs de erro

O app troca a tela vermelha por uma tela amigavel e registra diagnosticos
locais. Builds com `RANKING_API_URL` enviam esses diagnosticos para o Worker.

Consultar os ultimos logs:

```powershell
npm run admin:logs -- -Limit 20
```

O comando imprime JSON completo para nao truncar a mensagem. Para um resumo:

```powershell
npm run admin:logs -- -Limit 20 -Format Summary
```

Simular um evento seguro para testar o pipeline:

```powershell
npm run admin:logs:simulate
npm run admin:logs -- -Limit 5
```

Detalhes de token, endpoint protegido e filtros ficam em
[docs/ranking-api.md](docs/ranking-api.md).
