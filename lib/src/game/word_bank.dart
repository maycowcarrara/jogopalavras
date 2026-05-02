import 'package:jogopalavras/src/game/game_level.dart';

class WordEntry {
  const WordEntry(this.text, this.hint, this.extraHint);

  final String text;
  final String hint;
  final String extraHint;
}

// Listas curadas em pt-BR, com pistas em estilo palavras cruzadas: curtas,
// indiretas e sem entregar a resposta.
const Map<GameLevel, List<WordEntry>> _baseWordBank = {
  GameLevel.easy: [
    WordEntry(
      'AÇÃO',
      'Movimento ou escolha que provoca efeito',
      'Tem 4 letras, começa com A e termina com O.',
    ),
    WordEntry(
      'ÁGUA',
      'Some no copo e aparece demais quando falta',
      'Tem 4 letras, começa com Á e termina com A.',
    ),
    WordEntry(
      'ALMA',
      'Parte invisível ligada ao sentir',
      'Tem 4 letras, começa com A e termina com A.',
    ),
    WordEntry(
      'ALTO',
      'Acima da média ou do alcance',
      'Tem 4 letras, começa com A e termina com O.',
    ),
    WordEntry(
      'AMOR',
      'Afeto forte que aproxima pessoas',
      'Tem 4 letras, começa com A e termina com R.',
    ),
    WordEntry(
      'ÁREA',
      'Espaço delimitado para algum uso',
      'Tem 4 letras, começa com Á e termina com A.',
    ),
    WordEntry(
      'ARTE',
      'Expressão criada para provocar olhar ou emoção',
      'Tem 4 letras, começa com A e termina com E.',
    ),
    WordEntry(
      'AULA',
      'Momento em que alguém ensina algo',
      'Tem 4 letras, começa com A e termina com A.',
    ),
    WordEntry(
      'AUTO',
      'Pode indicar algo feito por si mesmo',
      'Tem 4 letras, começa com A e termina com O.',
    ),
    WordEntry(
      'AZUL',
      'Céu limpo costuma vestir essa cor',
      'Tem 4 letras, começa com A e termina com L.',
    ),
    WordEntry(
      'BASE',
      'Sustenta o que vem por cima',
      'Tem 4 letras, começa com B e termina com E.',
    ),
    WordEntry(
      'BELO',
      'Agrada aos olhos ou ao gosto',
      'Tem 4 letras, começa com B e termina com O.',
    ),
    WordEntry(
      'BOCA',
      'Porta do rosto que também guarda opinião',
      'Tem 4 letras, começa com B e termina com A.',
    ),
    WordEntry(
      'BOLA',
      'Quase sempre quer chão livre para correr',
      'Tem 4 letras, começa com B e termina com A.',
    ),
    WordEntry(
      'BOLO',
      'Forno, fatia e aniversário costumam cercá-lo',
      'Tem 4 letras, começa com B e termina com O.',
    ),
    WordEntry(
      'BOTA',
      'Calçado que cobre mais que o pé',
      'Tem 4 letras, começa com B e termina com A.',
    ),
    WordEntry(
      'CABO',
      'Pode ligar aparelhos ou terminar uma extensão',
      'Tem 4 letras, começa com C e termina com O.',
    ),
    WordEntry(
      'CAFÉ',
      'Bebida escura que costuma acordar gente',
      'Tem 4 letras, começa com C e termina com É.',
    ),
    WordEntry(
      'CAMA',
      'Móvel que chama quando o dia pesa',
      'Tem 4 letras, começa com C e termina com A.',
    ),
    WordEntry(
      'CAPA',
      'Protege por fora ou aparece na frente',
      'Tem 4 letras, começa com C e termina com A.',
    ),
    WordEntry(
      'CASA',
      'Endereço afetivo mais que construção',
      'Tem 4 letras, começa com C e termina com A.',
    ),
    WordEntry(
      'CENA',
      'Trecho visível de uma peça ou filme',
      'Tem 4 letras, começa com C e termina com A.',
    ),
    WordEntry(
      'CIMA',
      'Direção oposta ao chão',
      'Tem 4 letras, começa com C e termina com A.',
    ),
    WordEntry(
      'COPO',
      'Fica melhor cheio quando a sede chega',
      'Tem 4 letras, começa com C e termina com O.',
    ),
    WordEntry(
      'COPA',
      'Pode ser torneio ou parte de uma árvore',
      'Tem 4 letras, começa com C e termina com A.',
    ),
    WordEntry(
      'CRUZ',
      'Figura formada por duas linhas que se encontram',
      'Tem 4 letras, começa com C e termina com Z.',
    ),
    WordEntry(
      'DADO',
      'Cai na mesa antes de alguém contar pontos',
      'Tem 4 letras, começa com D e termina com O.',
    ),
    WordEntry(
      'DICA',
      'Ajuda curta que aponta sem resolver',
      'Tem 4 letras, começa com D e termina com A.',
    ),
    WordEntry(
      'DOCE',
      'Costuma disputar espaço depois do almoço',
      'Tem 4 letras, começa com D e termina com E.',
    ),
    WordEntry(
      'FACA',
      'Na cozinha, resolve o que precisa virar pedaço',
      'Tem 4 letras, começa com F e termina com A.',
    ),
    WordEntry(
      'FALA',
      'Som organizado para comunicar',
      'Tem 4 letras, começa com F e termina com A.',
    ),
    WordEntry(
      'FASE',
      'Etapa dentro de uma sequência',
      'Tem 4 letras, começa com F e termina com E.',
    ),
    WordEntry(
      'FATO',
      'Aquilo que aconteceu ou é real',
      'Tem 4 letras, começa com F e termina com O.',
    ),
    WordEntry(
      'FITA',
      'Faixa fina que pode prender ou decorar',
      'Tem 4 letras, começa com F e termina com A.',
    ),
    WordEntry(
      'FOGO',
      'Queima, ilumina e aquece',
      'Tem 4 letras, começa com F e termina com O.',
    ),
    WordEntry(
      'FOTO',
      'Instante que ficou parado por escolha',
      'Tem 4 letras, começa com F e termina com O.',
    ),
    WordEntry(
      'FRIO',
      'Faz casaco parecer boa ideia',
      'Tem 4 letras, começa com F e termina com O.',
    ),
    WordEntry(
      'GATO',
      'Dono do sofá quando ninguém autorizou',
      'Tem 4 letras, começa com G e termina com O.',
    ),
    WordEntry(
      'GOTA',
      'Quase nada de líquido, mas já molha',
      'Tem 4 letras, começa com G e termina com A.',
    ),
    WordEntry(
      'GRÃO',
      'Semente pequena, como arroz ou milho',
      'Tem 4 letras, começa com G e termina com O.',
    ),
    WordEntry(
      'HORA',
      'No relógio, decide se ainda dá tempo',
      'Tem 4 letras, começa com H e termina com A.',
    ),
    WordEntry(
      'ILHA',
      'Lugar onde a margem fica de todos os lados',
      'Tem 4 letras, começa com I e termina com A.',
    ),
    WordEntry(
      'JOGO',
      'Atividade com regras e objetivo',
      'Tem 4 letras, começa com J e termina com O.',
    ),
    WordEntry(
      'LADO',
      'Uma das faces ou direções de algo',
      'Tem 4 letras, começa com L e termina com O.',
    ),
    WordEntry(
      'LAGO',
      'Espelho natural que quase não corre',
      'Tem 4 letras, começa com L e termina com O.',
    ),
    WordEntry(
      'LATA',
      'Quando vazia, faz barulho maior que conteúdo',
      'Tem 4 letras, começa com L e termina com A.',
    ),
    WordEntry(
      'LEVE',
      'Pesa pouco ou acontece sem esforço',
      'Tem 4 letras, começa com L e termina com E.',
    ),
    WordEntry(
      'LIGA',
      'Une peças ou reúne competidores',
      'Tem 4 letras, começa com L e termina com A.',
    ),
    WordEntry(
      'LOJA',
      'Vitrine na frente, caixa no fim',
      'Tem 4 letras, começa com L e termina com A.',
    ),
    WordEntry(
      'LONA',
      'Tecido grosso usado para cobrir',
      'Tem 4 letras, começa com L e termina com A.',
    ),
    WordEntry(
      'LUTA',
      'Disputa física ou esforço por uma causa',
      'Tem 4 letras, começa com L e termina com A.',
    ),
    WordEntry(
      'MAPA',
      'Desenho que orienta trajetos',
      'Tem 4 letras, começa com M e termina com A.',
    ),
    WordEntry(
      'MATA',
      'Trecho com muita vegetação',
      'Tem 4 letras, começa com M e termina com A.',
    ),
    WordEntry(
      'MEDO',
      'Chega antes do perigo encostar de fato',
      'Tem 4 letras, começa com M e termina com O.',
    ),
    WordEntry(
      'MESA',
      'Reúne prato, conversa, tarefa ou decisão',
      'Tem 4 letras, começa com M e termina com A.',
    ),
    WordEntry(
      'MODA',
      'Jeito de vestir ou tendência do momento',
      'Tem 4 letras, começa com M e termina com A.',
    ),
    WordEntry(
      'NOTA',
      'Registro de avaliação ou som musical',
      'Tem 4 letras, começa com N e termina com A.',
    ),
    WordEntry(
      'OBRA',
      'Resultado de construção ou criação',
      'Tem 4 letras, começa com O e termina com A.',
    ),
    WordEntry(
      'OLHO',
      'Janela do rosto para a luz',
      'Tem 4 letras, começa com O e termina com O.',
    ),
    WordEntry(
      'ONDA',
      'Movimento que se levanta no mar',
      'Tem 4 letras, começa com O e termina com A.',
    ),
    WordEntry(
      'OURO',
      'Brilha tanto no cofre quanto no pódio',
      'Tem 4 letras, começa com O e termina com O.',
    ),
    WordEntry(
      'PAPO',
      'Conversa informal e solta',
      'Tem 4 letras, começa com P e termina com O.',
    ),
    WordEntry(
      'PEÇA',
      'Item de um conjunto ou apresentação no palco',
      'Tem 4 letras, começa com P e termina com A.',
    ),
    WordEntry(
      'PELE',
      'Fronteira viva entre o corpo e o mundo',
      'Tem 4 letras, começa com P e termina com E.',
    ),
    WordEntry(
      'PENA',
      'Pode cobrir ave ou indicar castigo',
      'Tem 4 letras, começa com P e termina com A.',
    ),
    WordEntry(
      'PESO',
      'Na balança, transforma corpo em número',
      'Tem 4 letras, começa com P e termina com O.',
    ),
    WordEntry(
      'PISO',
      'Superfície onde se pisa',
      'Tem 4 letras, começa com P e termina com O.',
    ),
    WordEntry(
      'POTE',
      'Guarda sobra como se fosse plano para depois',
      'Tem 4 letras, começa com P e termina com E.',
    ),
    WordEntry(
      'REDE',
      'Malha, conexão ou lugar de descanso',
      'Tem 4 letras, começa com R e termina com E.',
    ),
    WordEntry(
      'RISO',
      'Escapa antes que a seriedade consiga segurar',
      'Tem 4 letras, começa com R e termina com O.',
    ),
    WordEntry(
      'RODA',
      'Sem ela, muito caminho vira arrasto',
      'Tem 4 letras, começa com R e termina com A.',
    ),
    WordEntry(
      'ROSA',
      'Flor famosa ou tom entre vermelho e branco',
      'Tem 4 letras, começa com R e termina com A.',
    ),
    WordEntry(
      'ROTA',
      'Caminho escolhido para chegar',
      'Tem 4 letras, começa com R e termina com A.',
    ),
    WordEntry(
      'SAIA',
      'Roupa que desce da cintura',
      'Tem 4 letras, começa com S e termina com A.',
    ),
    WordEntry(
      'SALA',
      'Ambiente de estar, espera ou aula',
      'Tem 4 letras, começa com S e termina com A.',
    ),
    WordEntry(
      'SEDE',
      'Vontade de beber ou centro de uma instituição',
      'Tem 4 letras, começa com S e termina com E.',
    ),
    WordEntry(
      'SETA',
      'Sinal que aponta direção',
      'Tem 4 letras, começa com S e termina com A.',
    ),
    WordEntry(
      'SINO',
      'Aviso de metal que alcança longe',
      'Tem 4 letras, começa com S e termina com O.',
    ),
    WordEntry(
      'SONO',
      'Pesa nos olhos antes de apagar o dia',
      'Tem 4 letras, começa com S e termina com O.',
    ),
    WordEntry(
      'SUCO',
      'Fruta que resolveu caber no copo',
      'Tem 4 letras, começa com S e termina com O.',
    ),
    WordEntry(
      'TELA',
      'Superfície de imagem, pintura ou aparelho',
      'Tem 4 letras, começa com T e termina com A.',
    ),
    WordEntry(
      'TEMA',
      'Assunto principal de uma conversa',
      'Tem 4 letras, começa com T e termina com A.',
    ),
    WordEntry(
      'TETO',
      'Parte de cima de um cômodo',
      'Tem 4 letras, começa com T e termina com O.',
    ),
    WordEntry(
      'TIPO',
      'Categoria ou espécie',
      'Tem 4 letras, começa com T e termina com O.',
    ),
    WordEntry(
      'TOCA',
      'Abrigo pequeno, geralmente escondido',
      'Tem 4 letras, começa com T e termina com A.',
    ),
    WordEntry(
      'TOPO',
      'Parte mais alta',
      'Tem 4 letras, começa com T e termina com O.',
    ),
    WordEntry(
      'TREM',
      'Longo demais para fazer curva como carro',
      'Tem 4 letras, começa com T e termina com M.',
    ),
    WordEntry(
      'VALE',
      'Região baixa entre elevações',
      'Tem 4 letras, começa com V e termina com E.',
    ),
    WordEntry(
      'VELA',
      'Ilumina com chama ou move barco com vento',
      'Tem 4 letras, começa com V e termina com A.',
    ),
    WordEntry(
      'VIDA',
      'Condição de quem nasce, cresce e respira',
      'Tem 4 letras, começa com V e termina com A.',
    ),
    WordEntry(
      'VILA',
      'Povoado menor que uma cidade',
      'Tem 4 letras, começa com V e termina com A.',
    ),
    WordEntry(
      'VIVO',
      'Com sinais de existência ativa',
      'Tem 4 letras, começa com V e termina com O.',
    ),
    WordEntry(
      'ABRI',
      'Comecei uma passagem que estava fechada',
      'Tem 4 letras, começa com A e termina com I.',
    ),
    WordEntry(
      'ACHA',
      'Encontra algo ou forma uma opinião',
      'Tem 4 letras, começa com A e termina com A.',
    ),
    WordEntry(
      'AGIR',
      'Tomar uma atitude diante de algo',
      'Tem 4 letras, começa com A e termina com R.',
    ),
    WordEntry(
      'ALVO',
      'Ponto que se quer atingir',
      'Tem 4 letras, começa com A e termina com O.',
    ),
    WordEntry(
      'ANEL',
      'Pequeno círculo que pode carregar promessa',
      'Tem 4 letras, começa com A e termina com L.',
    ),
    WordEntry(
      'ARCO',
      'Forma curva ou arma antiga de disparo',
      'Tem 4 letras, começa com A e termina com O.',
    ),
    WordEntry(
      'BALA',
      'Doce pequeno ou projétil',
      'Tem 4 letras, começa com B e termina com A.',
    ),
    WordEntry(
      'BICO',
      'Ponta que aparece em ave, calçado ou bule',
      'Tem 4 letras, começa com B e termina com O.',
    ),
    WordEntry(
      'BRIM',
      'Tecido resistente usado em roupas',
      'Tem 4 letras, começa com B e termina com M.',
    ),
    WordEntry(
      'CALA',
      'Fica em silêncio',
      'Tem 4 letras, começa com C e termina com A.',
    ),
    WordEntry(
      'CALO',
      'Pele endurecida por atrito',
      'Tem 4 letras, começa com C e termina com O.',
    ),
    WordEntry(
      'CANO',
      'Esconde caminho para água, ar ou som',
      'Tem 4 letras, começa com C e termina com O.',
    ),
    WordEntry(
      'CARO',
      'Custa muito ou é querido',
      'Tem 4 letras, começa com C e termina com O.',
    ),
    WordEntry(
      'CEDO',
      'Antes do horário comum',
      'Tem 4 letras, começa com C e termina com O.',
    ),
    WordEntry(
      'CERA',
      'Material usado para brilho ou vedação',
      'Tem 4 letras, começa com C e termina com A.',
    ),
    WordEntry(
      'CHÃO',
      'Tudo cai para ele quando perde apoio',
      'Tem 4 letras, começa com C e termina com O.',
    ),
    WordEntry(
      'COLE',
      'Fixe uma coisa na outra',
      'Tem 4 letras, começa com C e termina com E.',
    ),
    WordEntry(
      'CORO',
      'Muitas vozes tentando parecer uma só',
      'Tem 4 letras, começa com C e termina com O.',
    ),
    WordEntry(
      'COTA',
      'Parte reservada de um total',
      'Tem 4 letras, começa com C e termina com A.',
    ),
    WordEntry(
      'DUNA',
      'O vento empilha e muda de lugar',
      'Tem 4 letras, começa com D e termina com A.',
    ),
    WordEntry(
      'DUTO',
      'Canal fechado para passagem de fluido',
      'Tem 4 letras, começa com D e termina com O.',
    ),
    WordEntry(
      'EIXO',
      'Linha central em torno da qual algo gira',
      'Tem 4 letras, começa com E e termina com O.',
    ),
    WordEntry(
      'FOFO',
      'Dá vontade de apertar ou elogiar',
      'Tem 4 letras, começa com F e termina com O.',
    ),
    WordEntry(
      'FOCO',
      'Ponto principal de atenção',
      'Tem 4 letras, começa com F e termina com O.',
    ),
    WordEntry(
      'FOME',
      'Faz qualquer cheiro parecer convite',
      'Tem 4 letras, começa com F e termina com E.',
    ),
    WordEntry(
      'FUSO',
      'Peça alongada ou faixa de horário',
      'Tem 4 letras, começa com F e termina com O.',
    ),
    WordEntry(
      'GEMA',
      'Parte do ovo ou pedra preciosa',
      'Tem 4 letras, começa com G e termina com A.',
    ),
    WordEntry(
      'GUIA',
      'Orienta caminho, visita ou consulta',
      'Tem 4 letras, começa com G e termina com A.',
    ),
    WordEntry(
      'HINO',
      'Música que pede postura antes da letra',
      'Tem 4 letras, começa com H e termina com O.',
    ),
    WordEntry(
      'JOIA',
      'Pequeno brilho que costuma valer mais que tamanho',
      'Tem 4 letras, começa com J e termina com A.',
    ),
    WordEntry(
      'JUDO',
      'No tatame, força demais pode virar queda',
      'Tem 4 letras, começa com J e termina com O.',
    ),
    WordEntry(
      'JURA',
      'Promete com força ou solenidade',
      'Tem 4 letras, começa com J e termina com A.',
    ),
    WordEntry(
      'LAÇO',
      'Nó decorativo ou vínculo afetivo',
      'Tem 4 letras, começa com L e termina com O.',
    ),
    WordEntry(
      'LISO',
      'Sem rugas, ondulações ou aspereza',
      'Tem 4 letras, começa com L e termina com O.',
    ),
    WordEntry(
      'LIXO',
      'Quando perde uso, ainda precisa de destino',
      'Tem 4 letras, começa com L e termina com O.',
    ),
    WordEntry(
      'LUPA',
      'Faz o detalhe pequeno ocupar a cena',
      'Tem 4 letras, começa com L e termina com A.',
    ),
    WordEntry(
      'LUAR',
      'Claridade da lua',
      'Tem 4 letras, começa com L e termina com R.',
    ),
    WordEntry(
      'LUXO',
      'Conforto caro ou refinado',
      'Tem 4 letras, começa com L e termina com O.',
    ),
    WordEntry(
      'MAÇÃ',
      'Pode ir na lancheira ou aparecer em conto famoso',
      'Tem 4 letras, começa com M e termina com Ã.',
    ),
    WordEntry(
      'MALA',
      'Guarda roupas e objetos em viagem',
      'Tem 4 letras, começa com M e termina com A.',
    ),
    WordEntry(
      'MARÉ',
      'Sobe e desce no litoral',
      'Tem 4 letras, começa com M e termina com É.',
    ),
    WordEntry(
      'MEIA',
      'Roupa usada no pé ou metade de algo',
      'Tem 4 letras, começa com M e termina com A.',
    ),
    WordEntry(
      'MEIO',
      'Centro, recurso ou metade',
      'Tem 4 letras, começa com M e termina com O.',
    ),
    WordEntry(
      'MIMO',
      'Carinho ou pequeno presente',
      'Tem 4 letras, começa com M e termina com O.',
    ),
    WordEntry(
      'MITO',
      'Narrativa simbólica ou fama exagerada',
      'Tem 4 letras, começa com M e termina com O.',
    ),
    WordEntry(
      'MOÇA',
      'Mulher jovem',
      'Tem 4 letras, começa com M e termina com A.',
    ),
    WordEntry(
      'MURO',
      'Parede externa que cerca um espaço',
      'Tem 4 letras, começa com M e termina com O.',
    ),
    WordEntry(
      'NOME',
      'Identifica pessoa, lugar ou coisa',
      'Tem 4 letras, começa com N e termina com E.',
    ),
    WordEntry(
      'NOVO',
      'Feito ou visto há pouco tempo',
      'Tem 4 letras, começa com N e termina com O.',
    ),
    WordEntry(
      'PATO',
      'Anda estranho, nada bem e frequenta piada',
      'Tem 4 letras, começa com P e termina com O.',
    ),
    WordEntry(
      'PERA',
      'Fruta doce de formato alongado',
      'Tem 4 letras, começa com P e termina com A.',
    ),
    WordEntry(
      'PICO',
      'Ponto mais alto ou momento intenso',
      'Tem 4 letras, começa com P e termina com O.',
    ),
    WordEntry(
      'POÇO',
      'Profundidade feita para buscar o que não está à vista',
      'Tem 4 letras, começa com P e termina com O.',
    ),
    WordEntry(
      'POVO',
      'Conjunto de habitantes ou comunidade',
      'Tem 4 letras, começa com P e termina com O.',
    ),
    WordEntry(
      'ZONA',
      'Área definida por uso ou regra',
      'Tem 4 letras, começa com Z e termina com A.',
    ),
    WordEntry(
      'RAIO',
      'Descarga elétrica ou linha de luz',
      'Tem 4 letras, começa com R e termina com O.',
    ),
    WordEntry(
      'RAIZ',
      'Parte que prende planta ao solo',
      'Tem 4 letras, começa com R e termina com Z.',
    ),
    WordEntry(
      'RAMO',
      'Galho ou área de atividade',
      'Tem 4 letras, começa com R e termina com O.',
    ),
    WordEntry(
      'RARO',
      'Difícil de encontrar',
      'Tem 4 letras, começa com R e termina com O.',
    ),
    WordEntry(
      'RASO',
      'Com pouca profundidade',
      'Tem 4 letras, começa com R e termina com O.',
    ),
    WordEntry(
      'RUGA',
      'Marca dobrada na pele ou tecido',
      'Tem 4 letras, começa com R e termina com A.',
    ),
    WordEntry(
      'SEDA',
      'Tecido fino e brilhante',
      'Tem 4 letras, começa com S e termina com A.',
    ),
    WordEntry(
      'SELO',
      'Marca de envio, autenticação ou coleção',
      'Tem 4 letras, começa com S e termina com O.',
    ),
    WordEntry(
      'SINA',
      'Destino visto como inevitável',
      'Tem 4 letras, começa com S e termina com A.',
    ),
    WordEntry(
      'TALO',
      'Haste que sustenta folha ou flor',
      'Tem 4 letras, começa com T e termina com O.',
    ),
    WordEntry(
      'TIRA',
      'Faixa estreita de material',
      'Tem 4 letras, começa com T e termina com A.',
    ),
    WordEntry(
      'TUBO',
      'Peça oca e comprida',
      'Tem 4 letras, começa com T e termina com O.',
    ),
    WordEntry(
      'URNA',
      'Recebe votos ou cinzas',
      'Tem 4 letras, começa com U e termina com A.',
    ),
    WordEntry(
      'URSO',
      'Abraço de pelúcia imita sua fama grande',
      'Tem 4 letras, começa com U e termina com O.',
    ),
    WordEntry(
      'VASO',
      'Recipiente para flores ou plantas',
      'Tem 4 letras, começa com V e termina com O.',
    ),
    WordEntry(
      'VOTO',
      'Escolha registrada em eleição',
      'Tem 4 letras, começa com V e termina com O.',
    ),
    WordEntry(
      'XALE',
      'Peça de tecido usada nos ombros',
      'Tem 4 letras, começa com X e termina com E.',
    ),
    WordEntry(
      'ALÇA',
      'Sem ela, carregar vira aperto',
      'Tem 4 letras, começa com A e termina com A.',
    ),
    WordEntry(
      'BULE',
      'Leva calor à mesa antes da xícara',
      'Tem 4 letras, começa com B e termina com E.',
    ),
    WordEntry(
      'CAIS',
      'Borda onde a viagem encosta',
      'Tem 4 letras, começa com C e termina com S.',
    ),
    WordEntry(
      'CEIA',
      'À noite, transforma mesa em ritual',
      'Tem 4 letras, começa com C e termina com A.',
    ),
    WordEntry(
      'DAMA',
      'No tabuleiro ou no salão, não passa despercebida',
      'Tem 4 letras, começa com D e termina com A.',
    ),
    WordEntry(
      'DEDO',
      'Conta pouco, aponta muito e deixa marca',
      'Tem 4 letras, começa com D e termina com O.',
    ),
    WordEntry(
      'FARO',
      'Pista que chega antes dos olhos',
      'Tem 4 letras, começa com F e termina com O.',
    ),
    WordEntry(
      'FENO',
      'O campo seco guardado para depois',
      'Tem 4 letras, começa com F e termina com O.',
    ),
    WordEntry(
      'FERA',
      'Assusta na mata ou impressiona no talento',
      'Tem 4 letras, começa com F e termina com A.',
    ),
    WordEntry(
      'FIEL',
      'Mantém compromisso mesmo quando muda o vento',
      'Tem 4 letras, começa com F e termina com L.',
    ),
    WordEntry(
      'FILA',
      'Paciência organizada em ordem de chegada',
      'Tem 4 letras, começa com F e termina com A.',
    ),
    WordEntry(
      'FIOS',
      'Linhas discretas que ligam, prendem ou conduzem',
      'Tem 4 letras, começa com F e termina com S.',
    ),
    WordEntry(
      'IOGA',
      'Prática que une postura, respiração e equilíbrio',
      'Tem 4 letras, começa com I e termina com A.',
    ),
    WordEntry(
      'GALO',
      'Relógio vivo de muitos quintais',
      'Tem 4 letras, começa com G e termina com O.',
    ),
    WordEntry(
      'GELO',
      'Some devagar quando o copo esquenta',
      'Tem 4 letras, começa com G e termina com O.',
    ),
    WordEntry(
      'JATO',
      'Sai com força ou cruza o céu em alta velocidade',
      'Tem 4 letras, começa com J e termina com O.',
    ),
    WordEntry(
      'LAMA',
      'Chão que resolveu grudar no pé',
      'Tem 4 letras, começa com L e termina com A.',
    ),
    WordEntry(
      'LIMA',
      'Fruta ácida ou ferramenta de desgaste',
      'Tem 4 letras, começa com L e termina com A.',
    ),
    WordEntry(
      'LOBO',
      'Canino selvagem de vida em grupo',
      'Tem 4 letras, começa com L e termina com O.',
    ),
    WordEntry(
      'LUVA',
      'Segunda pele para trabalho, frio ou cuidado',
      'Tem 4 letras, começa com L e termina com A.',
    ),
    WordEntry(
      'MOLA',
      'Guarda força para devolver movimento',
      'Tem 4 letras, começa com M e termina com A.',
    ),
    WordEntry(
      'NAVE',
      'Veículo imaginado para atravessar o espaço',
      'Tem 4 letras, começa com N e termina com E.',
    ),
    WordEntry(
      'NOJO',
      'Repulsa diante de cheiro, cena ou gosto ruim',
      'Tem 4 letras, começa com N e termina com O.',
    ),
    WordEntry(
      'NATA',
      'Camada cremosa que pode surgir no leite',
      'Tem 4 letras, começa com N e termina com A.',
    ),
    WordEntry(
      'PANO',
      'Pode virar limpeza, embrulho ou improviso',
      'Tem 4 letras, começa com P e termina com O.',
    ),
    WordEntry(
      'PATA',
      'A mesa tem; certos bichos também',
      'Tem 4 letras, começa com P e termina com A.',
    ),
    WordEntry(
      'PIPA',
      'Só brinca direito quando o vento participa',
      'Tem 4 letras, começa com P e termina com A.',
    ),
    WordEntry(
      'PUMA',
      'Corre pela pedra com silêncio de caça',
      'Tem 4 letras, começa com P e termina com A.',
    ),
    WordEntry(
      'RALO',
      'Some com a água, mas tenta segurar o resto',
      'Tem 4 letras, começa com R e termina com O.',
    ),
    WordEntry(
      'RIMA',
      'Quando finais diferentes resolvem combinar',
      'Tem 4 letras, começa com R e termina com A.',
    ),
    WordEntry(
      'RODO',
      'Varre líquido sem ser vassoura',
      'Tem 4 letras, começa com R e termina com O.',
    ),
    WordEntry(
      'SAPO',
      'Salto curto perto de brejo costuma denunciar',
      'Tem 4 letras, começa com S e termina com O.',
    ),
    WordEntry(
      'SILO',
      'Celeiro vertical para muita colheita',
      'Tem 4 letras, começa com S e termina com O.',
    ),
    WordEntry(
      'TAÇA',
      'Ergue-se quando o brinde merece altura',
      'Tem 4 letras, começa com T e termina com A.',
    ),
    WordEntry(
      'TATU',
      'Casco baixo e mania de abrir caminho no chão',
      'Tem 4 letras, começa com T e termina com U.',
    ),
    WordEntry(
      'TORÓ',
      'Quando cai, guarda-chuva vira urgência',
      'Tem 4 letras, começa com T e termina com Ó.',
    ),
    WordEntry(
      'TRIO',
      'Conjunto formado por três partes ou pessoas',
      'Tem 4 letras, começa com T e termina com O.',
    ),
    WordEntry(
      'VARA',
      'Peça comprida usada para medir, apoiar ou pescar',
      'Tem 4 letras, começa com V e termina com A.',
    ),
    WordEntry(
      'VEIA',
      'Caminho interno por onde o sangue retorna',
      'Tem 4 letras, começa com V e termina com A.',
    ),
    WordEntry(
      'VIGA',
      'Peça comprida que ajuda a sustentar construção',
      'Tem 4 letras, começa com V e termina com A.',
    ),
  ],
  GameLevel.medium: [
    WordEntry(
      'AJUDA',
      'Chega quando uma tarefa pesa para uma pessoa só',
      'Tem 5 letras, começa com A e termina com A.',
    ),
    WordEntry(
      'AMIGA',
      'Companhia feminina para confidência e parceria',
      'Tem 5 letras, começa com A e termina com A.',
    ),
    WordEntry(
      'AMIGO',
      'Companhia de confiança em fases boas e ruins',
      'Tem 5 letras, começa com A e termina com O.',
    ),
    WordEntry(
      'AREIA',
      'Grãos que ficam no pé depois da praia',
      'Tem 5 letras, começa com A e termina com A.',
    ),
    WordEntry(
      'BARCO',
      'Não usa estrada, mas também leva passageiros',
      'Tem 5 letras, começa com B e termina com O.',
    ),
    WordEntry(
      'BEBIDA',
      'Vai ao copo antes de matar sede ou brindar',
      'Tem 6 letras, começa com B e termina com A.',
    ),
    WordEntry(
      'BONECA',
      'Imita gente pequena na mão de uma criança',
      'Tem 6 letras, começa com B e termina com A.',
    ),
    WordEntry(
      'BOSQUE',
      'Árvores próximas, mas sem virar grande mata',
      'Tem 6 letras, começa com B e termina com E.',
    ),
    WordEntry(
      'BRILHO',
      'A luz chama atenção ao bater numa superfície',
      'Tem 6 letras, começa com B e termina com O.',
    ),
    WordEntry(
      'BRISA',
      'Vento leve que quase não bagunça nada',
      'Tem 5 letras, começa com B e termina com A.',
    ),
    WordEntry(
      'CAIXA',
      'Guarda por dentro ou atende no comércio',
      'Tem 5 letras, começa com C e termina com A.',
    ),
    WordEntry(
      'CAMISA',
      'Peça que costuma aparecer antes do casaco',
      'Tem 6 letras, começa com C e termina com A.',
    ),
    WordEntry(
      'CAMPO',
      'Aberto, rural ou marcado para jogo',
      'Tem 5 letras, começa com C e termina com O.',
    ),
    WordEntry(
      'CANETA',
      'Pequeno instrumento que deixa rastro de tinta',
      'Tem 6 letras, começa com C e termina com A.',
    ),
    WordEntry(
      'CARRO',
      'Garagem, trânsito e volante fazem parte dele',
      'Tem 5 letras, começa com C e termina com O.',
    ),
    WordEntry(
      'CARTA',
      'Mensagem que viaja dobrada ou em envelope',
      'Tem 5 letras, começa com C e termina com A.',
    ),
    WordEntry(
      'CHAVE',
      'Pequena peça que libera acesso',
      'Tem 5 letras, começa com C e termina com E.',
    ),
    WordEntry(
      'CHEIRO',
      'Às vezes denuncia comida antes dos olhos',
      'Tem 6 letras, começa com C e termina com O.',
    ),
    WordEntry(
      'CHUVA',
      'Nuvens carregadas e ruas molhadas costumam avisar',
      'Tem 5 letras, começa com C e termina com A.',
    ),
    WordEntry(
      'CLARO',
      'Quando a visão ou a ideia deixa de confundir',
      'Tem 5 letras, começa com C e termina com O.',
    ),
    WordEntry(
      'COISA',
      'Serve quando o nome certo fugiu',
      'Tem 5 letras, começa com C e termina com A.',
    ),
    WordEntry(
      'COMIDA',
      'Chega ao prato quando a fome aperta',
      'Tem 6 letras, começa com C e termina com A.',
    ),
    WordEntry(
      'CONTA',
      'Pode chegar depois do jantar ou morar no banco',
      'Tem 5 letras, começa com C e termina com A.',
    ),
    WordEntry(
      'CORPO',
      'Cabeça, tronco e membros formam esse conjunto',
      'Tem 5 letras, começa com C e termina com O.',
    ),
    WordEntry(
      'CUIDAR',
      'Atenção prática para evitar dano ou abandono',
      'Tem 6 letras, começa com C e termina com R.',
    ),
    WordEntry(
      'CURSO',
      'Pode ser estudo ou caminho de água',
      'Tem 5 letras, começa com C e termina com O.',
    ),
    WordEntry(
      'CURVA',
      'Na estrada, obriga a mudar a direção',
      'Tem 5 letras, começa com C e termina com A.',
    ),
    WordEntry(
      'DANÇA',
      'Movimento que escuta o ritmo',
      'Tem 5 letras, começa com D e termina com A.',
    ),
    WordEntry(
      'EQUIPE',
      'Quando funciona, cada pessoa cobre uma parte',
      'Tem 6 letras, começa com E e termina com E.',
    ),
    WordEntry(
      'ESCOLA',
      'Lugar onde rotina e aprendizado se encontram',
      'Tem 6 letras, começa com E e termina com A.',
    ),
    WordEntry(
      'ESPAÇO',
      'Quando falta, tudo fica apertado',
      'Tem 6 letras, começa com E e termina com O.',
    ),
    WordEntry(
      'ESTILO',
      'Dá para reconhecer no jeito de vestir ou criar',
      'Tem 6 letras, começa com E e termina com O.',
    ),
    WordEntry(
      'FESTA',
      'Convite, música e comemoração costumam aparecer',
      'Tem 5 letras, começa com F e termina com A.',
    ),
    WordEntry(
      'FIGURA',
      'Pode ser imagem, forma ou alguém marcante',
      'Tem 6 letras, começa com F e termina com A.',
    ),
    WordEntry(
      'FILME',
      'História que se move diante dos olhos',
      'Tem 5 letras, começa com F e termina com E.',
    ),
    WordEntry(
      'FLORES',
      'Costumam chegar com cor, perfume ou intenção',
      'Tem 6 letras, começa com F e termina com S.',
    ),
    WordEntry(
      'FONTE',
      'Lugar de onde algo começa a sair',
      'Tem 5 letras, começa com F e termina com E.',
    ),
    WordEntry(
      'FORMA',
      'Pode ser vista no contorno ou usada como molde',
      'Tem 5 letras, começa com F e termina com A.',
    ),
    WordEntry(
      'FRUTA',
      'Doce natural que muitas vezes vem com casca',
      'Tem 5 letras, começa com F e termina com A.',
    ),
    WordEntry(
      'FUTURO',
      'Ainda não chegou, mas já recebe planos',
      'Tem 6 letras, começa com F e termina com O.',
    ),
    WordEntry(
      'GRUPO',
      'Juntos por afinidade, tarefa ou acaso',
      'Tem 5 letras, começa com G e termina com O.',
    ),
    WordEntry(
      'HORTA',
      'Pequeno campo de temperos e verduras',
      'Tem 5 letras, começa com H e termina com A.',
    ),
    WordEntry(
      'IDEIAS',
      'Surgem antes de planos, projetos e soluções',
      'Tem 6 letras, começa com I e termina com S.',
    ),
    WordEntry(
      'INÍCIO',
      'Vem antes do desenvolvimento e do fim',
      'Tem 6 letras, começa com I e termina com O.',
    ),
    WordEntry(
      'JANELA',
      'Abertura que deixa entrar luz e mundo',
      'Tem 6 letras, começa com J e termina com A.',
    ),
    WordEntry(
      'JARDIM',
      'Natureza organizada perto de casa',
      'Tem 6 letras, começa com J e termina com M.',
    ),
    WordEntry(
      'LINHA',
      'Pode desenhar, costurar ou organizar fila',
      'Tem 5 letras, começa com L e termina com A.',
    ),
    WordEntry(
      'LISTA',
      'Ordem simples para não depender da memória',
      'Tem 5 letras, começa com L e termina com A.',
    ),
    WordEntry(
      'LIVRO',
      'Páginas presas que esperam leitura',
      'Tem 5 letras, começa com L e termina com O.',
    ),
    WordEntry(
      'LUGAR',
      'Onde algo cabe, acontece ou espera',
      'Tem 5 letras, começa com L e termina com R.',
    ),
    WordEntry(
      'MAGIA',
      'Truque de palco ou poder de conto fantástico',
      'Tem 5 letras, começa com M e termina com A.',
    ),
    WordEntry(
      'MANHÃ',
      'Começo claro do expediente do dia',
      'Tem 5 letras, começa com M e termina com Ã.',
    ),
    WordEntry(
      'MARCA',
      'Sinal que fica depois do contato',
      'Tem 5 letras, começa com M e termina com A.',
    ),
    WordEntry(
      'MELHOR',
      'Resultado que vence a comparação',
      'Tem 6 letras, começa com M e termina com R.',
    ),
    WordEntry(
      'MOTIVO',
      'Fica por trás de uma escolha ou atitude',
      'Tem 6 letras, começa com M e termina com O.',
    ),
    WordEntry(
      'MUNDO',
      'Tudo ao redor quando a escala fica grande',
      'Tem 5 letras, começa com M e termina com O.',
    ),
    WordEntry(
      'MÚSICA',
      'Som organizado para mexer com o tempo',
      'Tem 6 letras, começa com M e termina com A.',
    ),
    WordEntry(
      'NÍVEL',
      'Grau que mede etapa, altura ou desafio',
      'Tem 5 letras, começa com N e termina com L.',
    ),
    WordEntry(
      'NOITE',
      'Chega quando o sol sai de cena',
      'Tem 5 letras, começa com N e termina com E.',
    ),
    WordEntry(
      'NUVEM',
      'Forma passageira suspensa no céu',
      'Tem 5 letras, começa com N e termina com M.',
    ),
    WordEntry(
      'PAPEL',
      'Aceita tinta, embrulho, conta ou rascunho',
      'Tem 5 letras, começa com P e termina com L.',
    ),
    WordEntry(
      'PAREDE',
      'Pode dividir cômodos e receber quadros',
      'Tem 6 letras, começa com P e termina com E.',
    ),
    WordEntry(
      'PASSO',
      'Pequeno avanço de caminhada ou processo',
      'Tem 5 letras, começa com P e termina com O.',
    ),
    WordEntry(
      'PEIXE',
      'Vive na água e costuma escapar do anzol',
      'Tem 5 letras, começa com P e termina com E.',
    ),
    WordEntry(
      'PENSAR',
      'Trabalho interno antes da fala ou ação',
      'Tem 6 letras, começa com P e termina com R.',
    ),
    WordEntry(
      'PINTAR',
      'Dar cor onde antes havia superfície',
      'Tem 6 letras, começa com P e termina com R.',
    ),
    WordEntry(
      'PLANO',
      'Organiza o que vem antes da execução',
      'Tem 5 letras, começa com P e termina com O.',
    ),
    WordEntry(
      'PONTO',
      'Marca mínima que pode encerrar frase ou contar placar',
      'Tem 5 letras, começa com P e termina com O.',
    ),
    WordEntry(
      'PORTA',
      'Separa ambientes e decide passagem',
      'Tem 5 letras, começa com P e termina com A.',
    ),
    WordEntry(
      'PRAIA',
      'Areia, mar e guarda-sol aparecem juntos ali',
      'Tem 5 letras, começa com P e termina com A.',
    ),
    WordEntry(
      'PRATO',
      'Base redonda de refeição e apresentação',
      'Tem 5 letras, começa com P e termina com O.',
    ),
    WordEntry(
      'PRAZER',
      'Satisfação sentida no corpo ou na mente',
      'Tem 6 letras, começa com P e termina com R.',
    ),
    WordEntry(
      'QUADRO',
      'Pode receber pintura, giz ou planejamento',
      'Tem 6 letras, começa com Q e termina com O.',
    ),
    WordEntry(
      'QUARTO',
      'Cama e descanso costumam ocupar esse cômodo',
      'Tem 6 letras, começa com Q e termina com O.',
    ),
    WordEntry(
      'QUENTE',
      'Quando a temperatura passa do confortável',
      'Tem 6 letras, começa com Q e termina com E.',
    ),
    WordEntry(
      'RISADA',
      'Escapa em som quando algo tem graça',
      'Tem 6 letras, começa com R e termina com A.',
    ),
    WordEntry(
      'RITMO',
      'Organiza música, passos ou batidas',
      'Tem 5 letras, começa com R e termina com O.',
    ),
    WordEntry(
      'ROUPA',
      'Antes de sair, muita gente escolhe uma',
      'Tem 5 letras, começa com R e termina com A.',
    ),
    WordEntry(
      'SABOR',
      'O paladar reconhece no primeiro pedaço',
      'Tem 5 letras, começa com S e termina com R.',
    ),
    WordEntry(
      'SAÚDE',
      'Quando falta, o corpo costuma avisar',
      'Tem 5 letras, começa com S e termina com E.',
    ),
    WordEntry(
      'SEMANA',
      'Sete dias com começo, meio e fim',
      'Tem 6 letras, começa com S e termina com A.',
    ),
    WordEntry(
      'SONHAR',
      'Pode acontecer dormindo ou planejando algo desejado',
      'Tem 6 letras, começa com S e termina com R.',
    ),
    WordEntry(
      'SORRIR',
      'A boca muda antes mesmo da fala',
      'Tem 6 letras, começa com S e termina com R.',
    ),
    WordEntry(
      'TARDE',
      'Período em que o dia já passou da metade',
      'Tem 5 letras, começa com T e termina com E.',
    ),
    WordEntry(
      'TEATRO',
      'Palco, plateia e atores se encontram ali',
      'Tem 6 letras, começa com T e termina com O.',
    ),
    WordEntry(
      'TEMPO',
      'Mede duração, muda o clima e cobra paciência',
      'Tem 5 letras, começa com T e termina com O.',
    ),
    WordEntry(
      'TERRA',
      'Chão, planeta ou matéria nas mãos',
      'Tem 5 letras, começa com T e termina com A.',
    ),
    WordEntry(
      'TOMATE',
      'Vermelho que aparece na salada e no molho',
      'Tem 6 letras, começa com T e termina com E.',
    ),
    WordEntry(
      'TOQUE',
      'Contato leve ou aviso sonoro',
      'Tem 5 letras, começa com T e termina com E.',
    ),
    WordEntry(
      'TRAMA',
      'Pode cruzar fios ou complicar uma história',
      'Tem 5 letras, começa com T e termina com A.',
    ),
    WordEntry(
      'TRILHA',
      'Caminho estreito ou som que acompanha cena',
      'Tem 6 letras, começa com T e termina com A.',
    ),
    WordEntry(
      'VENTO',
      'Ar em deslocamento, visível só pelo efeito',
      'Tem 5 letras, começa com V e termina com O.',
    ),
    WordEntry(
      'VIAGEM',
      'Mala e passagem costumam vir antes dela',
      'Tem 6 letras, começa com V e termina com M.',
    ),
    WordEntry(
      'VIOLA',
      'Cordas com sotaque de música caipira',
      'Tem 5 letras, começa com V e termina com A.',
    ),
    WordEntry(
      'VIRADA',
      'Momento em que direção, jogo ou fase muda',
      'Tem 6 letras, começa com V e termina com A.',
    ),
    WordEntry(
      'VITRAL',
      'Vidro que colore a luz antes de ela entrar',
      'Tem 6 letras, começa com V e termina com L.',
    ),
    WordEntry(
      'VOLTA',
      'Retorno ao ponto que já foi conhecido',
      'Tem 5 letras, começa com V e termina com A.',
    ),
    WordEntry(
      'ABRIGO',
      'Vira destino quando chuva ou perigo apertam',
      'Tem 6 letras, começa com A e termina com O.',
    ),
    WordEntry(
      'ACORDO',
      'Depois da conversa, as partes aceitam o mesmo ponto',
      'Tem 6 letras, começa com A e termina com O.',
    ),
    WordEntry(
      'ALTURA',
      'Pode impressionar num prédio ou numa pessoa',
      'Tem 6 letras, começa com A e termina com A.',
    ),
    WordEntry(
      'AMARGO',
      'Nem todo sabor marcante agrada de primeira',
      'Tem 6 letras, começa com A e termina com O.',
    ),
    WordEntry(
      'ÂNGULO',
      'Muda quando duas linhas deixam de seguir juntas',
      'Tem 6 letras, começa com Â e termina com O.',
    ),
    WordEntry(
      'APLAUSO',
      'Palmas que respondem a uma boa apresentação',
      'Tem 7 letras, começa com AP e termina com O.',
    ),
    WordEntry(
      'ARQUIVO',
      'Fica quieto até alguém precisar consultar',
      'Tem 7 letras, começa com AR e termina com O.',
    ),
    WordEntry(
      'ASSUNTO',
      'Toda conversa precisa de um para começar',
      'Tem 7 letras, começa com AS e termina com O.',
    ),
    WordEntry(
      'BAIRRO',
      'Identidade de cidade em escala menor',
      'Tem 6 letras, começa com B e termina com O.',
    ),
    WordEntry(
      'BALCÃO',
      'Entre cliente e atendimento, costuma haver um',
      'Tem 6 letras, começa com B e termina com O.',
    ),
    WordEntry(
      'BARULHO',
      'Som que atrapalha quando passa do limite',
      'Tem 7 letras, começa com BA e termina com O.',
    ),
    WordEntry(
      'BATALHA',
      'Disputa que pede estratégia, força e resistência',
      'Tem 7 letras, começa com BA e termina com A.',
    ),
    WordEntry(
      'BILHETE',
      'Mensagem curta que também pode liberar entrada',
      'Tem 7 letras, começa com BI e termina com E.',
    ),
    WordEntry(
      'BOLSA',
      'Pode guardar objetos ou oscilar no mercado',
      'Tem 5 letras, começa com B e termina com A.',
    ),
    WordEntry(
      'BOTÃO',
      'Pequeno detalhe que prende ou aciona',
      'Tem 5 letras, começa com B e termina com O.',
    ),
    WordEntry(
      'BRANCO',
      'Papel sem tinta costuma lembrar essa cor',
      'Tem 6 letras, começa com B e termina com O.',
    ),
    WordEntry(
      'CABINE',
      'Espaço pequeno para comando, chamada ou troca',
      'Tem 6 letras, começa com C e termina com E.',
    ),
    WordEntry(
      'CADEIA',
      'Pode prender pessoas ou ligar uma sequência',
      'Tem 6 letras, começa com C e termina com A.',
    ),
    WordEntry(
      'CADERNO',
      'Companheiro de aula, pauta ou anotação',
      'Tem 7 letras, começa com CA e termina com O.',
    ),
    WordEntry(
      'CÂMERA',
      'Lente e botão ajudam a guardar uma imagem',
      'Tem 6 letras, começa com C e termina com A.',
    ),
    WordEntry(
      'CANÇÃO',
      'Letra e melodia se juntam para ser ouvidas',
      'Tem 6 letras, começa com C e termina com O.',
    ),
    WordEntry(
      'CAPITAL',
      'Pode comandar um mapa ou sustentar um negócio',
      'Tem 7 letras, começa com CA e termina com L.',
    ),
    WordEntry(
      'CASACO',
      'Entra em cena quando o frio aperta',
      'Tem 6 letras, começa com C e termina com O.',
    ),
    WordEntry(
      'CENOURA',
      'No prato, entrega cor antes do sabor',
      'Tem 7 letras, começa com CE e termina com A.',
    ),
    WordEntry(
      'CÉLULA',
      'Pequena unidade onde a vida se organiza',
      'Tem 6 letras, começa com C e termina com A.',
    ),
    WordEntry(
      'CÍRCULO',
      'Figura em que o fim volta ao começo',
      'Tem 7 letras, começa com CÍ e termina com O.',
    ),
    WordEntry(
      'CLIENTE',
      'Entra para comprar, contratar ou ser atendido',
      'Tem 7 letras, começa com CL e termina com E.',
    ),
    WordEntry(
      'COLEGA',
      'Nem sempre é amigo, mas divide rotina',
      'Tem 6 letras, começa com C e termina com A.',
    ),
    WordEntry(
      'COLUNA',
      'Pode sustentar prédio ou opinião impressa',
      'Tem 6 letras, começa com C e termina com A.',
    ),
    WordEntry(
      'CONVITE',
      'Antes da festa, costuma chegar o chamado',
      'Tem 7 letras, começa com CO e termina com E.',
    ),
    WordEntry(
      'COSTURA',
      'Quando o tecido se separa, ela resolve',
      'Tem 7 letras, começa com CO e termina com A.',
    ),
    WordEntry(
      'COZINHA',
      'Lugar onde cheiro bom costuma nascer primeiro',
      'Tem 7 letras, começa com CO e termina com A.',
    ),
    WordEntry(
      'CRÉDITO',
      'Confiança que pode virar compra ou mérito',
      'Tem 7 letras, começa com CR e termina com O.',
    ),
    WordEntry(
      'DEBATE',
      'Opiniões diferentes se enfrentam com argumentos',
      'Tem 6 letras, começa com D e termina com E.',
    ),
    WordEntry(
      'DEGRAU',
      'Cada um aproxima um pouco mais do alto',
      'Tem 6 letras, começa com D e termina com U.',
    ),
    WordEntry(
      'DESVIO',
      'A rota muda quando o caminho principal falha',
      'Tem 6 letras, começa com D e termina com O.',
    ),
    WordEntry(
      'DIÁRIO',
      'Registro que acompanha o passar dos dias',
      'Tem 6 letras, começa com D e termina com O.',
    ),
    WordEntry(
      'DIRETO',
      'Vai ao ponto sem fazer curva',
      'Tem 6 letras, começa com D e termina com O.',
    ),
    WordEntry(
      'DISPUTA',
      'Quando dois querem o mesmo lugar',
      'Tem 7 letras, começa com DI e termina com A.',
    ),
    WordEntry(
      'DOMÍNIO',
      'Pode ser controle, conhecimento ou endereço',
      'Tem 7 letras, começa com DO e termina com O.',
    ),
    WordEntry(
      'DÚVIDA',
      'Aparece quando a certeza ainda não fechou',
      'Tem 6 letras, começa com D e termina com A.',
    ),
    WordEntry(
      'EDITAL',
      'Documento que anuncia regras antes da disputa',
      'Tem 6 letras, começa com E e termina com L.',
    ),
    WordEntry(
      'EFEITO',
      'Aparece depois que algo provoca mudança',
      'Tem 6 letras, começa com E e termina com O.',
    ),
    WordEntry(
      'ENSAIO',
      'Antes da estreia, ainda permite ajuste e erro',
      'Tem 6 letras, começa com E e termina com O.',
    ),
    WordEntry(
      'ENTRADA',
      'Primeiro passo para dentro ou para o começo',
      'Tem 7 letras, começa com EN e termina com A.',
    ),
    WordEntry(
      'ESCADA',
      'Ajuda a vencer diferenças de altura',
      'Tem 6 letras, começa com E e termina com A.',
    ),
    WordEntry(
      'ESPUMA',
      'Bolhas claras aparecem no sabão ou na onda',
      'Tem 6 letras, começa com E e termina com A.',
    ),
    WordEntry(
      'ESTANTE',
      'Lugar onde lombadas ficam em exposição',
      'Tem 7 letras, começa com ES e termina com E.',
    ),
    WordEntry(
      'EXAME',
      'Momento em que algo passa por avaliação',
      'Tem 5 letras, começa com E e termina com E.',
    ),
    WordEntry(
      'FÁBRICA',
      'Onde matéria-prima ganha forma repetida',
      'Tem 7 letras, começa com FÁ e termina com A.',
    ),
    WordEntry(
      'FATURA',
      'Chega depois do consumo e pede acerto',
      'Tem 6 letras, começa com F e termina com A.',
    ),
    WordEntry(
      'FERIADO',
      'Pausa marcada no calendário comum',
      'Tem 7 letras, começa com FE e termina com O.',
    ),
    WordEntry(
      'FILTRO',
      'Deixa passar só o que interessa',
      'Tem 6 letras, começa com F e termina com O.',
    ),
    WordEntry(
      'FIRMA',
      'Pode ser negócio estabelecido ou nome assinado',
      'Tem 5 letras, começa com F e termina com A.',
    ),
    WordEntry(
      'FOLHETO',
      'Pequeno impresso que tenta chamar atenção',
      'Tem 7 letras, começa com FO e termina com O.',
    ),
    WordEntry(
      'FRANGO',
      'Presença comum em almoço simples ou assado',
      'Tem 6 letras, começa com F e termina com O.',
    ),
    WordEntry(
      'FRONTE',
      'Na cabeça, fica acima dos olhos',
      'Tem 6 letras, começa com F e termina com E.',
    ),
    WordEntry(
      'GANCHO',
      'Prende, puxa ou deixa continuação no ar',
      'Tem 6 letras, começa com G e termina com O.',
    ),
    WordEntry(
      'GARAGEM',
      'Quando o carro descansa, costuma ir para lá',
      'Tem 7 letras, começa com GA e termina com M.',
    ),
    WordEntry(
      'GARRAFA',
      'Mantém o líquido pronto para servir',
      'Tem 7 letras, começa com GA e termina com A.',
    ),
    WordEntry(
      'GESTÃO',
      'Faz decisões, recursos e pessoas funcionarem juntos',
      'Tem 6 letras, começa com G e termina com O.',
    ),
    WordEntry(
      'GOVERNO',
      'Conjunto que decide rumos públicos',
      'Tem 7 letras, começa com GO e termina com O.',
    ),
    WordEntry(
      'HÁBITO',
      'Repetição que quase vira automático',
      'Tem 6 letras, começa com H e termina com O.',
    ),
    WordEntry(
      'HERANÇA',
      'O que chega de quem veio antes',
      'Tem 7 letras, começa com HE e termina com A.',
    ),
    WordEntry(
      'HORÁRIO',
      'Organiza compromissos antes que virem atraso',
      'Tem 7 letras, começa com HO e termina com O.',
    ),
    WordEntry(
      'IMPULSO',
      'Vem rápido, antes da razão organizar tudo',
      'Tem 7 letras, começa com IM e termina com O.',
    ),
    WordEntry(
      'ÍNDICE',
      'Ajuda a encontrar parte dentro do todo',
      'Tem 6 letras, começa com Í e termina com E.',
    ),
    WordEntry(
      'JOGADA',
      'Um lance pode mudar a partida',
      'Tem 6 letras, começa com J e termina com A.',
    ),
    WordEntry(
      'JORNAL',
      'Notícia organizada para circular',
      'Tem 6 letras, começa com J e termina com L.',
    ),
    WordEntry(
      'LAVOURA',
      'Campo tratado com intenção de colheita',
      'Tem 7 letras, começa com LA e termina com A.',
    ),
    WordEntry(
      'LEGENDA',
      'Texto pequeno que ajuda imagem ou fala',
      'Tem 7 letras, começa com LE e termina com A.',
    ),
    WordEntry(
      'LIMITE',
      'Linha que avisa onde parar',
      'Tem 6 letras, começa com L e termina com E.',
    ),
    WordEntry(
      'MANUAL',
      'Quando a dúvida é prática, ele orienta',
      'Tem 6 letras, começa com M e termina com L.',
    ),
    WordEntry(
      'MARGEM',
      'Espaço lateral onde o principal não ocupa',
      'Tem 6 letras, começa com M e termina com M.',
    ),
    WordEntry(
      'MÉDICO',
      'Jaleco, consulta e diagnóstico apontam para ele',
      'Tem 6 letras, começa com M e termina com O.',
    ),
    WordEntry(
      'MENSAL',
      'Volta sempre no ritmo do calendário',
      'Tem 6 letras, começa com M e termina com L.',
    ),
    WordEntry(
      'MINUTO',
      'Sessenta segundos podem decidir muita coisa',
      'Tem 6 letras, começa com M e termina com O.',
    ),
    WordEntry(
      'MODELO',
      'Serve de referência antes da cópia ou foto',
      'Tem 6 letras, começa com M e termina com O.',
    ),
    WordEntry(
      'MOTOR',
      'Fica escondido, mas faz a máquina andar',
      'Tem 5 letras, começa com M e termina com R.',
    ),
    WordEntry(
      'OFERTA',
      'Quando parece vantajosa, chama comprador',
      'Tem 6 letras, começa com O e termina com A.',
    ),
    WordEntry(
      'OFÍCIO',
      'Pode ser trabalho aprendido ou documento formal',
      'Tem 6 letras, começa com O e termina com O.',
    ),
    WordEntry(
      'PALÁCIO',
      'Reis, presidentes ou grandes cerimônias cabem nele',
      'Tem 7 letras, começa com PA e termina com O.',
    ),
    WordEntry(
      'PARQUE',
      'Árvores, bancos e lazer dão pista do lugar',
      'Tem 6 letras, começa com P e termina com E.',
    ),
    WordEntry(
      'PEDIDO',
      'Começa com uma vontade e espera resposta',
      'Tem 6 letras, começa com P e termina com O.',
    ),
    WordEntry(
      'PILOTO',
      'Conduz rota ou testa ideia antes dos outros',
      'Tem 6 letras, começa com P e termina com O.',
    ),
    WordEntry(
      'PISCINA',
      'Água controlada para lazer ou treino',
      'Tem 7 letras, começa com PI e termina com A.',
    ),
    WordEntry(
      'POSTURA',
      'Aparece tanto na coluna quanto na atitude',
      'Tem 7 letras, começa com PO e termina com A.',
    ),
    WordEntry(
      'PRENSA',
      'Máquina que vence pelo aperto',
      'Tem 6 letras, começa com P e termina com A.',
    ),
    WordEntry(
      'QUINTAL',
      'Parte da casa onde o ar circula melhor',
      'Tem 7 letras, começa com QU e termina com L.',
    ),
    WordEntry(
      'RECEITA',
      'Pode guiar cozinha ou explicar entrada de caixa',
      'Tem 7 letras, começa com RE e termina com A.',
    ),
    WordEntry(
      'RECORTE',
      'Parte escolhida de uma cena maior',
      'Tem 7 letras, começa com RE e termina com E.',
    ),
    WordEntry(
      'RELATO',
      'Alguém conta o que viu, viveu ou ouviu',
      'Tem 6 letras, começa com R e termina com O.',
    ),
    WordEntry(
      'RESUMO',
      'Fica menor sem perder a ideia central',
      'Tem 6 letras, começa com R e termina com O.',
    ),
    WordEntry(
      'ROTEIRO',
      'Antes da viagem ou da cena, ele guia',
      'Tem 7 letras, começa com RO e termina com O.',
    ),
    WordEntry(
      'SALÁRIO',
      'Retorno regular pelo trabalho feito',
      'Tem 7 letras, começa com SA e termina com O.',
    ),
    WordEntry(
      'SEMENTE',
      'Pequena no solo, pode virar planta',
      'Tem 7 letras, começa com SE e termina com E.',
    ),
    WordEntry(
      'SOMBRA',
      'Aparece quando algo interrompe a luz',
      'Tem 6 letras, começa com S e termina com A.',
    ),
    WordEntry(
      'SUJEITO',
      'Pode agir na frase ou andar pela rua',
      'Tem 7 letras, começa com SU e termina com O.',
    ),
    WordEntry(
      'TALENTO',
      'Quando a facilidade aparece antes do treino pesado',
      'Tem 7 letras, começa com TA e termina com O.',
    ),
    WordEntry(
      'TECIDO',
      'Fios juntos ganham forma útil',
      'Tem 6 letras, começa com T e termina com O.',
    ),
    WordEntry(
      'TÍTULO',
      'Nome que fica acima ou reconhecimento conquistado',
      'Tem 6 letras, começa com T e termina com O.',
    ),
    WordEntry(
      'TORCIDA',
      'Grita junto quando o time entra em campo',
      'Tem 7 letras, começa com TO e termina com A.',
    ),
    WordEntry(
      'TRÁFEGO',
      'Fluxo que pode travar rua ou rede',
      'Tem 7 letras, começa com TR e termina com O.',
    ),
    WordEntry(
      'TREINO',
      'Repetição feita antes de valer de verdade',
      'Tem 6 letras, começa com T e termina com O.',
    ),
    WordEntry(
      'UNIDADE',
      'Uma parte que ainda pertence ao conjunto',
      'Tem 7 letras, começa com UN e termina com E.',
    ),
    WordEntry(
      'VAREJO',
      'Venda em escala de consumidor',
      'Tem 6 letras, começa com V e termina com O.',
    ),
    WordEntry(
      'VIZINHO',
      'Mora perto o bastante para cruzar no portão',
      'Tem 7 letras, começa com VI e termina com O.',
    ),
    WordEntry(
      'ABISMO',
      'Quando o chão some, o olhar demora a voltar',
      'Tem 6 letras, começa com A e termina com O.',
    ),
    WordEntry(
      'ACERVO',
      'Memória guardada que espera nova consulta',
      'Tem 6 letras, começa com A e termina com O.',
    ),
    WordEntry(
      'AGENDA',
      'Tenta impedir que o futuro vire confusão',
      'Tem 6 letras, começa com A e termina com A.',
    ),
    WordEntry(
      'ALFACE',
      'Verde que dá volume sem pesar no prato',
      'Tem 6 letras, começa com A e termina com E.',
    ),
    WordEntry(
      'ALUGUEL',
      'Uso com prazo, dono e cobrança combinados',
      'Tem 7 letras, começa com AL e termina com L.',
    ),
    WordEntry(
      'AMEIXA',
      'Doce por fora, guarda dureza no centro',
      'Tem 6 letras, começa com A e termina com A.',
    ),
    WordEntry(
      'ANZOL',
      'Pequeno risco escondido atrás da isca',
      'Tem 5 letras, começa com A e termina com L.',
    ),
    WordEntry(
      'APITO',
      'Um sopro que consegue interromper movimento',
      'Tem 5 letras, começa com A e termina com O.',
    ),
    WordEntry(
      'ATALHO',
      'Economia de caminho que nem sempre economiza história',
      'Tem 6 letras, começa com A e termina com O.',
    ),
    WordEntry(
      'AURORA',
      'A noite ainda está saindo quando ela aparece',
      'Tem 6 letras, começa com A e termina com A.',
    ),
    WordEntry(
      'BACIA',
      'Recebe água sem pedir lugar fixo',
      'Tem 5 letras, começa com B e termina com A.',
    ),
    WordEntry(
      'BALDE',
      'Quando cheio, faz a alça cobrar força',
      'Tem 5 letras, começa com B e termina com E.',
    ),
    WordEntry(
      'BANHO',
      'Pequena chuva particular dentro de casa',
      'Tem 5 letras, começa com B e termina com O.',
    ),
    WordEntry(
      'BARRIL',
      'Volume guardado em corpo arredondado',
      'Tem 6 letras, começa com B e termina com L.',
    ),
    WordEntry(
      'BASTÃO',
      'Na mão certa, apoia, rege ou rebate',
      'Tem 6 letras, começa com B e termina com O.',
    ),
    WordEntry(
      'BEIJO',
      'Sinal sem fala que pode dizer demais',
      'Tem 5 letras, começa com B e termina com O.',
    ),
    WordEntry(
      'BOLHA',
      'Nasce cheia de ar e morre com pouco toque',
      'Tem 5 letras, começa com B e termina com A.',
    ),
    WordEntry(
      'BONDE',
      'Anda preso ao caminho que a rua desenhou',
      'Tem 5 letras, começa com B e termina com E.',
    ),
    WordEntry(
      'BRONZE',
      'Entre medalha e pele, lembra sol e metal',
      'Tem 6 letras, começa com B e termina com E.',
    ),
    WordEntry(
      'CABELO',
      'Muda de corte e muda quase tudo no rosto',
      'Tem 6 letras, começa com C e termina com O.',
    ),
    WordEntry(
      'CABRA',
      'No sertão, sobe onde muito bicho hesita',
      'Tem 5 letras, começa com C e termina com A.',
    ),
    WordEntry(
      'CACAU',
      'Antes da barra doce, foi semente amarga',
      'Tem 5 letras, começa com C e termina com U.',
    ),
    WordEntry(
      'CADETE',
      'Aluno em formação militar',
      'Tem 6 letras, começa com C e termina com E.',
    ),
    WordEntry(
      'CAJADO',
      'Apoio de caminhada com ar de história antiga',
      'Tem 6 letras, começa com C e termina com O.',
    ),
    WordEntry(
      'CALÇADA',
      'A rua passa ao lado; os passos ficam nela',
      'Tem 7 letras, começa com CA e termina com A.',
    ),
    WordEntry(
      'CAMADA',
      'Uma por cima da outra muda espessura e sentido',
      'Tem 6 letras, começa com C e termina com A.',
    ),
    WordEntry(
      'CANECA',
      'Segura calor sem que a mão pague sozinha',
      'Tem 6 letras, começa com C e termina com A.',
    ),
    WordEntry(
      'CARTAZ',
      'Grita parado numa parede ou poste',
      'Tem 6 letras, começa com C e termina com Z.',
    ),
    WordEntry(
      'CASULO',
      'Pausa fechada antes de outra forma surgir',
      'Tem 6 letras, começa com C e termina com O.',
    ),
    WordEntry(
      'CEBOLA',
      'Quanto mais se abre, mais pode molhar os olhos',
      'Tem 6 letras, começa com C e termina com A.',
    ),
    WordEntry(
      'CEDRO',
      'Perfume de árvore que também vira móvel',
      'Tem 5 letras, começa com C e termina com O.',
    ),
    WordEntry(
      'CHALÉ',
      'Casa pequena com vontade de montanha',
      'Tem 5 letras, começa com C e termina com É.',
    ),
    WordEntry(
      'CICLO',
      'Sequência que termina voltando ao começo',
      'Tem 5 letras, começa com C e termina com O.',
    ),
    WordEntry(
      'CINEMA',
      'Escuro coletivo diante de uma história iluminada',
      'Tem 6 letras, começa com C e termina com A.',
    ),
    WordEntry(
      'COLHER',
      'Leva pequenas porções sem fazer alarde',
      'Tem 6 letras, começa com C e termina com R.',
    ),
    WordEntry(
      'CORDÃO',
      'Prende ou enfeita com a mesma simplicidade',
      'Tem 6 letras, começa com C e termina com O.',
    ),
    WordEntry(
      'COROA',
      'Na cabeça ou na conquista, sugere lugar alto',
      'Tem 5 letras, começa com C e termina com A.',
    ),
    WordEntry(
      'DENTES',
      'Aparecem no sorriso e trabalham no silêncio',
      'Tem 6 letras, começa com D e termina com S.',
    ),
    WordEntry(
      'ENIGMA',
      'Pergunta que se esconde dentro da própria pista',
      'Tem 6 letras, começa com E e termina com A.',
    ),
    WordEntry(
      'FIVELA',
      'Pequena peça que decide se algo fecha',
      'Tem 6 letras, começa com F e termina com A.',
    ),
    WordEntry(
      'FOGÃO',
      'Ponto quente onde receita vira cheiro',
      'Tem 5 letras, começa com F e termina com O.',
    ),
    WordEntry(
      'FUNIL',
      'Faz o largo obedecer ao estreito',
      'Tem 5 letras, começa com F e termina com L.',
    ),
    WordEntry(
      'GAVETA',
      'Esconde miudezas em silêncio horizontal',
      'Tem 6 letras, começa com G e termina com A.',
    ),
    WordEntry(
      'GIRINO',
      'Ainda não salta, mas já anuncia mudança',
      'Tem 6 letras, começa com G e termina com O.',
    ),
    WordEntry(
      'LÂMINA',
      'Fina o bastante para separar com perigo',
      'Tem 6 letras, começa com L e termina com A.',
    ),
    WordEntry(
      'MOEDAS',
      'Dinheiro que denuncia presença pelo barulho',
      'Tem 6 letras, começa com M e termina com S.',
    ),
    WordEntry(
      'MUSEU',
      'O passado fica em pé para visita',
      'Tem 5 letras, começa com M e termina com U.',
    ),
    WordEntry(
      'NAVIO',
      'Cidade pequena atravessando água grande',
      'Tem 5 letras, começa com N e termina com O.',
    ),
    WordEntry(
      'POMAR',
      'Conjunto de promessas penduradas em galhos',
      'Tem 5 letras, começa com P e termina com R.',
    ),
    WordEntry(
      'QUEIJO',
      'Leite que ganhou forma, cheiro e paciência',
      'Tem 6 letras, começa com Q e termina com O.',
    ),
    WordEntry(
      'RAQUETE',
      'Braço com tela para devolver velocidade',
      'Tem 7 letras, começa com RA e termina com E.',
    ),
    WordEntry(
      'RELÓGIO',
      'Máquina pequena que manda em atrasos grandes',
      'Tem 7 letras, começa com RE e termina com O.',
    ),
    WordEntry(
      'TAPETE',
      'Piso que tenta parecer mais acolhedor',
      'Tem 6 letras, começa com T e termina com E.',
    ),
    WordEntry(
      'VARANDA',
      'Dentro de casa, mas com vontade de rua',
      'Tem 7 letras, começa com VA e termina com A.',
    ),
  ],
  GameLevel.hard: [
    WordEntry(
      'ALEGRIA',
      'Costuma aparecer em sorriso, festa ou boa notícia',
      'Tem 7 letras, começa com AL e termina com A.',
    ),
    WordEntry(
      'AMBIENTE',
      'O lugar e o clima ao redor contam juntos',
      'Tem 8 letras, começa com AM e termina com E.',
    ),
    WordEntry(
      'ANIMAIS',
      'Seres vivos fora do reino vegetal',
      'Tem 7 letras, começa com AN e termina com S.',
    ),
    WordEntry(
      'ATENÇÃO',
      'Sem ela, até instrução simples passa batida',
      'Tem 7 letras, começa com AT e termina com O.',
    ),
    WordEntry(
      'ATITUDE',
      'O que alguém faz pesa mais que discurso',
      'Tem 7 letras, começa com AT e termina com E.',
    ),
    WordEntry(
      'AVENTURA',
      'Viagem ou situação com risco e descoberta',
      'Tem 8 letras, começa com AV e termina com A.',
    ),
    WordEntry(
      'CAMINHO',
      'Liga partida e chegada, com ou sem mapa',
      'Tem 7 letras, começa com CA e termina com O.',
    ),
    WordEntry(
      'CENÁRIO',
      'Fundo preparado para a cena acontecer',
      'Tem 7 letras, começa com CE e termina com O.',
    ),
    WordEntry(
      'CÉREBRO',
      'Dentro da cabeça, coordena memória e movimento',
      'Tem 7 letras, começa com CÉ e termina com O.',
    ),
    WordEntry(
      'CIRCUITO',
      'Percurso que costuma voltar ao próprio começo',
      'Tem 8 letras, começa com CI e termina com O.',
    ),
    WordEntry(
      'CONTROLE',
      'Pode estar no painel, na mão ou na decisão',
      'Tem 8 letras, começa com CO e termina com E.',
    ),
    WordEntry(
      'CORAÇÃO',
      'Órgão real que a linguagem transformou em símbolo',
      'Tem 7 letras, começa com CO e termina com O.',
    ),
    WordEntry(
      'CRIANÇA',
      'Brinquedos, escola e crescimento cercam essa fase',
      'Tem 7 letras, começa com CR e termina com A.',
    ),
    WordEntry(
      'CRIATIVO',
      'Encontra solução nova com material comum',
      'Tem 8 letras, começa com CR e termina com O.',
    ),
    WordEntry(
      'CUIDADO',
      'Chega antes para evitar machucado ou perda',
      'Tem 7 letras, começa com CU e termina com O.',
    ),
    WordEntry(
      'CULTURA',
      'O que um grupo aprende, repete e transforma',
      'Tem 7 letras, começa com CU e termina com A.',
    ),
    WordEntry(
      'DECISÃO',
      'Depois dela, uma opção fica para trás',
      'Tem 7 letras, começa com DE e termina com O.',
    ),
    WordEntry(
      'DESAFIO',
      'Tarefa que mede vontade e preparo',
      'Tem 7 letras, começa com DE e termina com O.',
    ),
    WordEntry(
      'DESENHO',
      'Lápis e traços transformam ideia em imagem',
      'Tem 7 letras, começa com DE e termina com O.',
    ),
    WordEntry(
      'DINHEIRO',
      'Compra pão, paga conta e circula no bolso',
      'Tem 8 letras, começa com DI e termina com O.',
    ),
    WordEntry(
      'DOMINGO',
      'Dia que costuma desacelerar a semana',
      'Tem 7 letras, começa com DO e termina com O.',
    ),
    WordEntry(
      'EDUCAÇÃO',
      'Aprendizado que vai além da sala',
      'Tem 8 letras, começa com ED e termina com O.',
    ),
    WordEntry(
      'EMPRESA',
      'Tem equipe, cliente, trabalho e resultado',
      'Tem 7 letras, começa com EM e termina com A.',
    ),
    WordEntry(
      'ENERGIA',
      'Sem ela, movimento e luz perdem força',
      'Tem 7 letras, começa com EN e termina com A.',
    ),
    WordEntry(
      'ENCONTRO',
      'Duas agendas combinam o mesmo lugar',
      'Tem 8 letras, começa com EN e termina com O.',
    ),
    WordEntry(
      'ESCOLHA',
      'Entre opções, uma acaba vencendo',
      'Tem 7 letras, começa com ES e termina com A.',
    ),
    WordEntry(
      'ESPECIAL',
      'Recebe destaque por não parecer comum',
      'Tem 8 letras, começa com ES e termina com L.',
    ),
    WordEntry(
      'ESTRELA',
      'Brilha no céu e também pode nomear famoso',
      'Tem 7 letras, começa com ES e termina com A.',
    ),
    WordEntry(
      'EXEMPLO',
      'Um caso pode explicar melhor que teoria',
      'Tem 7 letras, começa com EX e termina com O.',
    ),
    WordEntry(
      'FAMÍLIA',
      'Laço que pode vir de sangue, cuidado ou convivência',
      'Tem 7 letras, começa com FA e termina com A.',
    ),
    WordEntry(
      'FANTASIA',
      'Pode vestir uma pessoa ou morar na imaginação',
      'Tem 8 letras, começa com FA e termina com A.',
    ),
    WordEntry(
      'FLORESTA',
      'Muitas árvores formando quase um mundo próprio',
      'Tem 8 letras, começa com FL e termina com A.',
    ),
    WordEntry(
      'FOGUETE',
      'Sobe com força para sair da Terra',
      'Tem 7 letras, começa com FO e termina com E.',
    ),
    WordEntry(
      'FUTEBOL',
      'Campo, rede e torcida giram em torno da bola',
      'Tem 7 letras, começa com FU e termina com L.',
    ),
    WordEntry(
      'GALÁXIA',
      'Muitas estrelas reunidas numa escala imensa',
      'Tem 7 letras, começa com GA e termina com A.',
    ),
    WordEntry(
      'HISTÓRIA',
      'O tempo organizado para ser contado',
      'Tem 8 letras, começa com HI e termina com A.',
    ),
    WordEntry(
      'IMAGINAR',
      'Ver uma cena por dentro antes de ela existir',
      'Tem 8 letras, começa com IM e termina com R.',
    ),
    WordEntry(
      'INFÂNCIA',
      'Primeiros anos marcados por brincar e crescer',
      'Tem 8 letras, começa com IN e termina com A.',
    ),
    WordEntry(
      'JUSTIÇA',
      'Equilíbrio buscado quando há conflito',
      'Tem 7 letras, começa com JU e termina com A.',
    ),
    WordEntry(
      'MANEIRA',
      'O jeito muda mesmo quando a tarefa é igual',
      'Tem 7 letras, começa com MA e termina com A.',
    ),
    WordEntry(
      'MATERIAL',
      'Antes de construir, é preciso escolher o que usar',
      'Tem 8 letras, começa com MA e termina com L.',
    ),
    WordEntry(
      'MEMÓRIA',
      'Guarda nomes, cenas e aprendizados',
      'Tem 7 letras, começa com ME e termina com A.',
    ),
    WordEntry(
      'MERCADO',
      'Lugar ou sistema onde valor encontra interesse',
      'Tem 7 letras, começa com ME e termina com O.',
    ),
    WordEntry(
      'MISTURA',
      'Depois dela, separar pode ficar difícil',
      'Tem 7 letras, começa com MI e termina com A.',
    ),
    WordEntry(
      'MOLÉCULA',
      'Átomos se juntam numa escala invisível a olho nu',
      'Tem 8 letras, começa com MO e termina com A.',
    ),
    WordEntry(
      'MOMENTO',
      'Um instante pode bastar para mudar a situação',
      'Tem 7 letras, começa com MO e termina com O.',
    ),
    WordEntry(
      'MONTANHA',
      'Sobe na paisagem e desafia trilhas',
      'Tem 8 letras, começa com MO e termina com A.',
    ),
    WordEntry(
      'NATUREZA',
      'O mundo físico antes da intervenção humana',
      'Tem 8 letras, começa com NA e termina com A.',
    ),
    WordEntry(
      'NAVEGAR',
      'Seguir rota por água, mapa ou tela',
      'Tem 7 letras, começa com NA e termina com R.',
    ),
    WordEntry(
      'OBJETIVO',
      'A meta que dá direção ao esforço',
      'Tem 8 letras, começa com OB e termina com O.',
    ),
    WordEntry(
      'PACIÊNCIA',
      'Ajuda a esperar sem perder a calma',
      'Tem 9 letras, começa com PA e termina com A.',
    ),
    WordEntry(
      'PALAVRAS',
      'Unidades que fazem frase ganhar forma',
      'Tem 8 letras, começa com PA e termina com S.',
    ),
    WordEntry(
      'PASSADO',
      'Já ficou para trás, mas ainda deixa marca',
      'Tem 7 letras, começa com PA e termina com O.',
    ),
    WordEntry(
      'PESQUISA',
      'Pergunta organizada em busca de resposta',
      'Tem 8 letras, começa com PE e termina com A.',
    ),
    WordEntry(
      'PINTURA',
      'Cor aplicada até virar imagem ou cobertura',
      'Tem 7 letras, começa com PI e termina com A.',
    ),
    WordEntry(
      'PLANETA',
      'Gira no espaço e pode ter luas ao redor',
      'Tem 7 letras, começa com PL e termina com A.',
    ),
    WordEntry(
      'POLÍTICA',
      'Envolve governo, voto e decisões coletivas',
      'Tem 8 letras, começa com PO e termina com A.',
    ),
    WordEntry(
      'PRESENTE',
      'Pode ser instante atual ou embrulho recebido',
      'Tem 8 letras, começa com PR e termina com E.',
    ),
    WordEntry(
      'PROBLEMA',
      'Algo no caminho pedindo solução',
      'Tem 8 letras, começa com PR e termina com A.',
    ),
    WordEntry(
      'PROCESSO',
      'Resultado dividido em etapas',
      'Tem 8 letras, começa com PR e termina com O.',
    ),
    WordEntry(
      'PRODUTO',
      'O que chega depois de fabricação ou criação',
      'Tem 7 letras, começa com PR e termina com O.',
    ),
    WordEntry(
      'PROJETO',
      'Ideia organizada antes de virar obra',
      'Tem 7 letras, começa com PR e termina com O.',
    ),
    WordEntry(
      'PRÓXIMO',
      'Pode estar perto no mapa, no tempo ou no afeto',
      'Tem 7 letras, começa com PR e termina com O.',
    ),
    WordEntry(
      'QUESTÃO',
      'Pode vir como pergunta ou como assunto sensível',
      'Tem 7 letras, começa com QU e termina com O.',
    ),
    WordEntry(
      'RECURSOS',
      'Meios disponíveis antes da execução',
      'Tem 8 letras, começa com RE e termina com S.',
    ),
    WordEntry(
      'RESPOSTA',
      'O que a pergunta tenta provocar',
      'Tem 8 letras, começa com RE e termina com A.',
    ),
    WordEntry(
      'SEGREDO',
      'Informação que pouca gente deve saber',
      'Tem 7 letras, começa com SE e termina com O.',
    ),
    WordEntry(
      'SENTIDO',
      'Direção, significado ou percepção: depende do contexto',
      'Tem 7 letras, começa com SE e termina com O.',
    ),
    WordEntry(
      'SISTEMA',
      'Partes conectadas tentando funcionar como conjunto',
      'Tem 7 letras, começa com SI e termina com A.',
    ),
    WordEntry(
      'SUCESSO',
      'Resultado bom o bastante para ser reconhecido',
      'Tem 7 letras, começa com SU e termina com O.',
    ),
    WordEntry(
      'SURPRESA',
      'O inesperado aparece antes da reação',
      'Tem 8 letras, começa com SU e termina com A.',
    ),
    WordEntry(
      'TESOURO',
      'Valor escondido ou protegido demais',
      'Tem 7 letras, começa com TE e termina com O.',
    ),
    WordEntry(
      'TRABALHO',
      'Esforço organizado para produzir algo',
      'Tem 8 letras, começa com TR e termina com O.',
    ),
    WordEntry(
      'UNIVERSO',
      'Quando a escala inclui tudo que existe',
      'Tem 8 letras, começa com UN e termina com O.',
    ),
    WordEntry(
      'VERDADE',
      'Aquilo que resiste melhor à checagem',
      'Tem 7 letras, começa com VE e termina com E.',
    ),
    WordEntry(
      'ABERTURA',
      'Pode ser passagem, início ou primeira apresentação',
      'Tem 8 letras, começa com AB e termina com A.',
    ),
    WordEntry(
      'ACIDENTE',
      'Quando o imprevisto deixa marca no caminho',
      'Tem 8 letras, começa com AC e termina com E.',
    ),
    WordEntry(
      'ACRÍLICO',
      'Parece vidro, mas veio da família dos plásticos',
      'Tem 8 letras, começa com AC e termina com O.',
    ),
    WordEntry(
      'ALFABETO',
      'A ordem básica por trás de quase todo texto',
      'Tem 8 letras, começa com AL e termina com O.',
    ),
    WordEntry(
      'ALIMENTO',
      'Vai ao prato para manter o corpo funcionando',
      'Tem 8 letras, começa com AL e termina com O.',
    ),
    WordEntry(
      'ALMOFADA',
      'Macia, recebe a cabeça no sofá ou na cama',
      'Tem 8 letras, começa com AL e termina com A.',
    ),
    WordEntry(
      'ANÁLISE',
      'Divide o assunto em partes para entender melhor',
      'Tem 7 letras, começa com AN e termina com E.',
    ),
    WordEntry(
      'APARELHO',
      'Objeto técnico que ganha nome pela função',
      'Tem 8 letras, começa com AP e termina com O.',
    ),
    WordEntry(
      'APETITE',
      'Aparece antes do prato chegar',
      'Tem 7 letras, começa com AP e termina com E.',
    ),
    WordEntry(
      'APROVADO',
      'Depois da avaliação, é o resultado desejado',
      'Tem 8 letras, começa com AP e termina com O.',
    ),
    WordEntry(
      'ARQUITETO',
      'Desenha espaços antes de eles existirem',
      'Tem 9 letras, começa com AR e termina com O.',
    ),
    WordEntry(
      'ASSENTO',
      'Em sala cheia, vira disputa discreta',
      'Tem 7 letras, começa com AS e termina com O.',
    ),
    WordEntry(
      'AUDIÇÃO',
      'Sentido que funciona mesmo de olhos fechados',
      'Tem 7 letras, começa com AU e termina com O.',
    ),
    WordEntry(
      'AUTORIDADE',
      'Quando uma voz passa a ter peso oficial',
      'Tem 10 letras, começa com AU e termina com E.',
    ),
    WordEntry(
      'BAGAGEM',
      'Pode ir no porta-malas ou vir da experiência',
      'Tem 7 letras, começa com BA e termina com M.',
    ),
    WordEntry(
      'BALANÇO',
      'Pode embalar criança ou fechar contas',
      'Tem 7 letras, começa com BA e termina com O.',
    ),
    WordEntry(
      'BANDEIRA',
      'Tecido que carrega identidade coletiva',
      'Tem 8 letras, começa com BA e termina com A.',
    ),
    WordEntry(
      'BATERIA',
      'Energia guardada ou ritmo em sequência',
      'Tem 7 letras, começa com BA e termina com A.',
    ),
    WordEntry(
      'BIBLIOTECA',
      'Estantes e silêncio ajudam a consulta',
      'Tem 10 letras, começa com BI e termina com A.',
    ),
    WordEntry(
      'BICICLETA',
      'Duas rodas, equilíbrio e esforço próprio',
      'Tem 9 letras, começa com BI e termina com A.',
    ),
    WordEntry(
      'BIOLOGIA',
      'Área que pergunta como a vida funciona',
      'Tem 8 letras, começa com BI e termina com A.',
    ),
    WordEntry(
      'BORBOLETA',
      'Depois da transformação, ganha asas coloridas',
      'Tem 9 letras, começa com BO e termina com A.',
    ),
    WordEntry(
      'BRINQUEDO',
      'Na mão de criança, vira coisa séria',
      'Tem 9 letras, começa com BR e termina com O.',
    ),
    WordEntry(
      'CALENDÁRIO',
      'O tempo distribuído em quadrinhos',
      'Tem 10 letras, começa com CA e termina com O.',
    ),
    WordEntry(
      'CAMPEÃO',
      'Recebe taça quando a disputa termina',
      'Tem 7 letras, começa com CA e termina com O.',
    ),
    WordEntry(
      'CAPÍTULO',
      'Parte que pausa a história sem encerrá-la',
      'Tem 8 letras, começa com CA e termina com O.',
    ),
    WordEntry(
      'CARREIRA',
      'Caminho longo feito de escolhas profissionais',
      'Tem 8 letras, começa com CA e termina com A.',
    ),
    WordEntry(
      'CARTÓRIO',
      'Reconhece firma e registra documento',
      'Tem 8 letras, começa com CA e termina com O.',
    ),
    WordEntry(
      'CATEGORIA',
      'Agrupa diferenças sob um mesmo critério',
      'Tem 9 letras, começa com CA e termina com A.',
    ),
    WordEntry(
      'CATEDRAL',
      'Grande igreja, muitas vezes símbolo de uma cidade',
      'Tem 8 letras, começa com CA e termina com L.',
    ),
    WordEntry(
      'CAVERNA',
      'Refúgio natural aberto na pedra',
      'Tem 7 letras, começa com CA e termina com A.',
    ),
    WordEntry(
      'CIDADÃO',
      'Tem direitos, deveres e participação pública',
      'Tem 7 letras, começa com CI e termina com O.',
    ),
    WordEntry(
      'COBERTOR',
      'Camada extra quando a noite esfria',
      'Tem 8 letras, começa com CO e termina com R.',
    ),
    WordEntry(
      'COMÉRCIO',
      'Troca organizada entre oferta e procura',
      'Tem 8 letras, começa com CO e termina com O.',
    ),
    WordEntry(
      'COMPASSO',
      'Ajuda a medir ritmo ou desenhar precisão',
      'Tem 8 letras, começa com CO e termina com O.',
    ),
    WordEntry(
      'CONSELHO',
      'Pode orientar, mesmo sem obrigar ninguém',
      'Tem 8 letras, começa com CO e termina com O.',
    ),
    WordEntry(
      'CONTRATO',
      'Promessa que ganhou forma legal',
      'Tem 8 letras, começa com CO e termina com O.',
    ),
    WordEntry(
      'CORAGEM',
      'Age mesmo com medo ainda presente',
      'Tem 7 letras, começa com CO e termina com M.',
    ),
    WordEntry(
      'CORREDOR',
      'Pode acelerar numa pista ou ligar cômodos',
      'Tem 8 letras, começa com CO e termina com R.',
    ),
    WordEntry(
      'CORTINA',
      'Entre janela e sala, controla luz e privacidade',
      'Tem 7 letras, começa com CO e termina com A.',
    ),
    WordEntry(
      'CRITÉRIO',
      'Define a régua antes de avaliar',
      'Tem 8 letras, começa com CR e termina com O.',
    ),
    WordEntry(
      'CRÔNICA',
      'Texto que encontra assunto no cotidiano',
      'Tem 7 letras, começa com CR e termina com A.',
    ),
    WordEntry(
      'DELEGADO',
      'Recebe poder para representar ou investigar',
      'Tem 8 letras, começa com DE e termina com O.',
    ),
    WordEntry(
      'DESERTO',
      'Onde a falta de água molda a paisagem',
      'Tem 7 letras, começa com DE e termina com O.',
    ),
    WordEntry(
      'DETALHE',
      'Pequeno o bastante para escapar, grande para importar',
      'Tem 7 letras, começa com DE e termina com E.',
    ),
    WordEntry(
      'DIÁLOGO',
      'Quando duas vozes realmente se alternam',
      'Tem 7 letras, começa com DI e termina com O.',
    ),
    WordEntry(
      'DIRETOR',
      'Comanda bastidores em escola, filme ou empresa',
      'Tem 7 letras, começa com DI e termina com R.',
    ),
    WordEntry(
      'DISCIPLINA',
      'Pode ser matéria escolar ou autocontrole',
      'Tem 10 letras, começa com DI e termina com A.',
    ),
    WordEntry(
      'DISTÂNCIA',
      'O espaço que separa presença e chegada',
      'Tem 9 letras, começa com DI e termina com A.',
    ),
    WordEntry(
      'DOCUMENTO',
      'Papel ou arquivo que sustenta uma versão oficial',
      'Tem 9 letras, começa com DO e termina com O.',
    ),
    WordEntry(
      'ELEIÇÃO',
      'Escolha coletiva registrada em votos',
      'Tem 7 letras, começa com EL e termina com O.',
    ),
    WordEntry(
      'ELEVADOR',
      'Atalho vertical para vencer andares',
      'Tem 8 letras, começa com EL e termina com R.',
    ),
    WordEntry(
      'EMBALAGEM',
      'Protege o produto e tenta chamar atenção',
      'Tem 9 letras, começa com EM e termina com M.',
    ),
    WordEntry(
      'ENTREVISTA',
      'Perguntas preparadas buscam informação de alguém',
      'Tem 10 letras, começa com EN e termina com A.',
    ),
    WordEntry(
      'EQUILÍBRIO',
      'Quando forças diferentes deixam de derrubar',
      'Tem 10 letras, começa com EQ e termina com O.',
    ),
    WordEntry(
      'ESCÂNDALO',
      'Fato que ganha volume pela indignação pública',
      'Tem 9 letras, começa com ES e termina com O.',
    ),
    WordEntry(
      'ESCRITÓRIO',
      'Ambiente onde mesa, tarefa e prazo se encontram',
      'Tem 10 letras, começa com ES e termina com O.',
    ),
    WordEntry(
      'ESTÚDIO',
      'Espaço preparado para gravar ou criar',
      'Tem 7 letras, começa com ES e termina com O.',
    ),
    WordEntry(
      'EXPEDIÇÃO',
      'Viagem movida por objetivo e descoberta',
      'Tem 9 letras, começa com EX e termina com O.',
    ),
    WordEntry(
      'FERRAMENTA',
      'Na mão certa, facilita conserto ou trabalho',
      'Tem 10 letras, começa com FE e termina com A.',
    ),
    WordEntry(
      'FESTIVAL',
      'Várias atrações reunidas sob uma mesma data',
      'Tem 8 letras, começa com FE e termina com L.',
    ),
    WordEntry(
      'FÓRMULA',
      'Quando uma regra vira caminho repetível',
      'Tem 7 letras, começa com FÓ e termina com A.',
    ),
    WordEntry(
      'FRONTEIRA',
      'Linha que separa mapas e autoridades',
      'Tem 9 letras, começa com FR e termina com A.',
    ),
    WordEntry(
      'GELADEIRA',
      'Caixa fria que prolonga comida',
      'Tem 9 letras, começa com GE e termina com A.',
    ),
    WordEntry(
      'GIRASSOL',
      'Flor amarela famosa por seguir a luz',
      'Tem 8 letras, começa com GI e termina com L.',
    ),
    WordEntry(
      'HOSPITAL',
      'Médicos, leitos e urgências fazem parte dele',
      'Tem 8 letras, começa com HO e termina com L.',
    ),
    WordEntry(
      'IMPRENSA',
      'Transforma apuração em circulação pública',
      'Tem 8 letras, começa com IM e termina com A.',
    ),
    WordEntry(
      'INDÚSTRIA',
      'Produção quando deixa de ser artesanal',
      'Tem 9 letras, começa com IN e termina com A.',
    ),
    WordEntry(
      'INQUÉRITO',
      'Perguntas formais atrás de uma versão dos fatos',
      'Tem 9 letras, começa com IN e termina com O.',
    ),
    WordEntry(
      'INSTITUTO',
      'Organização dedicada a uma causa ou estudo',
      'Tem 9 letras, começa com IN e termina com O.',
    ),
    WordEntry(
      'INTERVALO',
      'Espaço de pausa entre duas partes',
      'Tem 9 letras, começa com IN e termina com O.',
    ),
    WordEntry(
      'JORNALISTA',
      'Apura fatos antes de publicar notícia',
      'Tem 10 letras, começa com JO e termina com A.',
    ),
    WordEntry(
      'LABIRINTO',
      'Muitos caminhos confundem a saída',
      'Tem 9 letras, começa com LA e termina com O.',
    ),
    WordEntry(
      'LINGUAGEM',
      'Sistema que transforma pensamento em sinal',
      'Tem 9 letras, começa com LI e termina com M.',
    ),
    WordEntry(
      'LITERATURA',
      'Palavras tratadas como arte',
      'Tem 10 letras, começa com LI e termina com A.',
    ),
    WordEntry(
      'MANCHETE',
      'No jornal, tenta puxar o olhar primeiro',
      'Tem 8 letras, começa com MA e termina com E.',
    ),
    WordEntry(
      'MECÂNICA',
      'O estudo do movimento por dentro das máquinas',
      'Tem 8 letras, começa com ME e termina com A.',
    ),
    WordEntry(
      'MENSAGEM',
      'Informação que precisa chegar a alguém',
      'Tem 8 letras, começa com ME e termina com M.',
    ),
    WordEntry(
      'MINISTRO',
      'Cargo alto entre decisão política e responsabilidade',
      'Tem 8 letras, começa com MI e termina com O.',
    ),
    WordEntry(
      'MUNICÍPIO',
      'Cidade e zona rural podem estar sob essa gestão',
      'Tem 9 letras, começa com MU e termina com O.',
    ),
    WordEntry(
      'NARRADOR',
      'Conta a história sem necessariamente vivê-la',
      'Tem 8 letras, começa com NA e termina com R.',
    ),
    WordEntry(
      'NEGÓCIO',
      'Pode ser acordo, loja ou oportunidade',
      'Tem 7 letras, começa com NE e termina com O.',
    ),
    WordEntry(
      'NOTÍCIA',
      'Fato recente quando ganha interesse público',
      'Tem 7 letras, começa com NO e termina com A.',
    ),
    WordEntry(
      'OPERAÇÃO',
      'Ação coordenada, cálculo ou intervenção',
      'Tem 8 letras, começa com OP e termina com O.',
    ),
    WordEntry(
      'ORÇAMENTO',
      'Plano de dinheiro antes do gasto',
      'Tem 9 letras, começa com OR e termina com O.',
    ),
    WordEntry(
      'PAISAGEM',
      'Montes, céu e construções compõem a vista',
      'Tem 8 letras, começa com PA e termina com M.',
    ),
    WordEntry(
      'PALESTRA',
      'Uma voz conduzindo assunto diante de público',
      'Tem 8 letras, começa com PA e termina com A.',
    ),
    WordEntry(
      'PARÁGRAFO',
      'Ideia que ocupa um bloco no texto',
      'Tem 9 letras, começa com PA e termina com O.',
    ),
    WordEntry(
      'PASSAGEIRO',
      'Viaja, mas não conduz o caminho',
      'Tem 10 letras, começa com PA e termina com O.',
    ),
    WordEntry(
      'PATRIMÔNIO',
      'Valor acumulado em bens, memória ou cultura',
      'Tem 10 letras, começa com PA e termina com O.',
    ),
    WordEntry(
      'PERGUNTA',
      'Abre espaço onde ainda falta resposta',
      'Tem 8 letras, começa com PE e termina com A.',
    ),
    WordEntry(
      'PERSONAGEM',
      'Age ou sofre dentro de uma história',
      'Tem 10 letras, começa com PE e termina com M.',
    ),
    WordEntry(
      'PONTEIRO',
      'Pequena peça que aponta medida',
      'Tem 8 letras, começa com PO e termina com O.',
    ),
    WordEntry(
      'PORTUGUÊS',
      'Idioma que dá forma a estas pistas',
      'Tem 9 letras, começa com PO e termina com S.',
    ),
    WordEntry(
      'PREFEITO',
      'Administra a cidade por mandato',
      'Tem 8 letras, começa com PR e termina com O.',
    ),
    WordEntry(
      'PROFESSOR',
      'Explica conteúdo e acompanha aprendizagem',
      'Tem 9 letras, começa com PR e termina com R.',
    ),
    WordEntry(
      'PROGRAMA',
      'Sequência planejada para acontecer ou rodar',
      'Tem 8 letras, começa com PR e termina com A.',
    ),
    WordEntry(
      'PROMESSA',
      'Trata o futuro como compromisso',
      'Tem 8 letras, começa com PR e termina com A.',
    ),
    WordEntry(
      'PROPÓSITO',
      'Dá razão para continuar uma ação',
      'Tem 9 letras, começa com PR e termina com O.',
    ),
    WordEntry(
      'PROTESTO',
      'Discordância que decidiu aparecer em público',
      'Tem 8 letras, começa com PR e termina com O.',
    ),
    WordEntry(
      'REDAÇÃO',
      'Texto produzido ou sala onde notícia nasce',
      'Tem 7 letras, começa com RE e termina com O.',
    ),
    WordEntry(
      'REFORMA',
      'Mudança feita para consertar ou atualizar',
      'Tem 7 letras, começa com RE e termina com A.',
    ),
    WordEntry(
      'REGISTRO',
      'Guarda uma informação como prova ou memória',
      'Tem 8 letras, começa com RE e termina com O.',
    ),
    WordEntry(
      'REPORTAGEM',
      'Notícia com mais fôlego de apuração',
      'Tem 10 letras, começa com RE e termina com M.',
    ),
    WordEntry(
      'RESERVA',
      'Fica guardada para usar depois',
      'Tem 7 letras, começa com RE e termina com A.',
    ),
    WordEntry(
      'REUNIÃO',
      'Pessoas sentam em volta de uma pauta',
      'Tem 7 letras, começa com RE e termina com O.',
    ),
    WordEntry(
      'SANDUÍCHE',
      'Refeição rápida montada em camadas',
      'Tem 9 letras, começa com SA e termina com E.',
    ),
    WordEntry(
      'SENADOR',
      'Mandato ligado à representação de um estado',
      'Tem 7 letras, começa com SE e termina com R.',
    ),
    WordEntry(
      'SÍMBOLO',
      'Um sinal carrega uma ideia maior que ele',
      'Tem 7 letras, começa com SÍ e termina com O.',
    ),
    WordEntry(
      'TELEFONE',
      'Voz atravessando distância por aparelho',
      'Tem 8 letras, começa com TE e termina com E.',
    ),
    WordEntry(
      'TERRITÓRIO',
      'Área marcada por posse, regra ou disputa',
      'Tem 10 letras, começa com TE e termina com O.',
    ),
    WordEntry(
      'TESTEMUNHA',
      'Quem viu pode ajudar a confirmar o fato',
      'Tem 10 letras, começa com TE e termina com A.',
    ),
    WordEntry(
      'TRANSPORTE',
      'Sistema para levar algo de um ponto a outro',
      'Tem 10 letras, começa com TR e termina com E.',
    ),
    WordEntry(
      'TRIBUNAL',
      'Onde conflito vira julgamento formal',
      'Tem 8 letras, começa com TR e termina com L.',
    ),
    WordEntry(
      'VEREADOR',
      'Discute leis e problemas da cidade',
      'Tem 8 letras, começa com VE e termina com R.',
    ),
    WordEntry(
      'VESTÍGIO',
      'Marca pequena que indica que algo passou',
      'Tem 8 letras, começa com VE e termina com O.',
    ),
    WordEntry(
      'VIOLÊNCIA',
      'Quando a força vira dano',
      'Tem 9 letras, começa com VI e termina com A.',
    ),
    WordEntry(
      'ACADEMIA',
      'Pode moldar corpo ou reunir saber antigo',
      'Tem 8 letras, começa com AC e termina com A.',
    ),
    WordEntry(
      'AEROPORTO',
      'Onde despedidas olham para painéis de horário',
      'Tem 9 letras, começa com AE e termina com O.',
    ),
    WordEntry(
      'ALICERCE',
      'Quase ninguém vê, mas tudo acima depende dele',
      'Tem 8 letras, começa com AL e termina com E.',
    ),
    WordEntry(
      'ALVORADA',
      'Quando a luz ainda não virou dia inteiro',
      'Tem 8 letras, começa com AL e termina com A.',
    ),
    WordEntry(
      'AMPULHETA',
      'O tempo cai em silêncio de um lado para outro',
      'Tem 9 letras, começa com AM e termina com A.',
    ),
    WordEntry(
      'ANDAIME',
      'A obra sobe apoiada em algo provisório',
      'Tem 7 letras, começa com AN e termina com E.',
    ),
    WordEntry(
      'ANESTESIA',
      'Antes do corte, cala o alarme do corpo',
      'Tem 9 letras, começa com AN e termina com A.',
    ),
    WordEntry(
      'AQUÁRIO',
      'Um pedaço de rio preso atrás de vidro',
      'Tem 7 letras, começa com AQ e termina com O.',
    ),
    WordEntry(
      'ARMAZÉM',
      'Antes da vitrine, muita coisa espera ali',
      'Tem 7 letras, começa com AR e termina com M.',
    ),
    WordEntry(
      'ARTESÃO',
      'Sua assinatura costuma ficar no jeito da mão',
      'Tem 7 letras, começa com AR e termina com O.',
    ),
    WordEntry(
      'ASTEROIDE',
      'Pedra sem endereço fixo rondando o espaço',
      'Tem 9 letras, começa com AS e termina com E.',
    ),
    WordEntry(
      'AVENTAL',
      'Recebe respingos para poupar a roupa',
      'Tem 7 letras, começa com AV e termina com L.',
    ),
    WordEntry(
      'BAILARINO',
      'Transforma contagem e música em gesto',
      'Tem 9 letras, começa com BA e termina com O.',
    ),
    WordEntry(
      'BALANÇA',
      'Decide diferenças pequenas com aparente frieza',
      'Tem 7 letras, começa com BA e termina com A.',
    ),
    WordEntry(
      'BARRAGEM',
      'Quando segura demais, o rio muda de destino',
      'Tem 8 letras, começa com BA e termina com M.',
    ),
    WordEntry(
      'BASTIDOR',
      'Atrás da apresentação, muita coisa acontece nele',
      'Tem 8 letras, começa com BA e termina com R.',
    ),
    WordEntry(
      'BORDADO',
      'Linha paciente desenhando onde antes havia tecido',
      'Tem 7 letras, começa com BO e termina com O.',
    ),
    WordEntry(
      'BRACELETE',
      'Círculo de pulso mais decorativo que útil',
      'Tem 9 letras, começa com BR e termina com E.',
    ),
    WordEntry(
      'CAÇAMBA',
      'Engole entulho sem parecer delicada',
      'Tem 7 letras, começa com CA e termina com A.',
    ),
    WordEntry(
      'CAMAREIRO',
      'Trabalha onde hóspede ou artista deixa rastro',
      'Tem 9 letras, começa com CA e termina com O.',
    ),
    WordEntry(
      'CAMINHÃO',
      'Leva longe o que seria pesado demais para poucos',
      'Tem 8 letras, começa com CA e termina com O.',
    ),
    WordEntry(
      'CANDIEIRO',
      'Pequena claridade de tempos sem tomada',
      'Tem 9 letras, começa com CA e termina com O.',
    ),
    WordEntry(
      'CAPACETE',
      'Casca emprestada para proteger pensamento',
      'Tem 8 letras, começa com CA e termina com E.',
    ),
    WordEntry(
      'CARROSSEL',
      'Volta sempre ao começo e ainda diverte',
      'Tem 9 letras, começa com CA e termina com L.',
    ),
    WordEntry(
      'CEMITÉRIO',
      'A cidade silenciosa dos nomes gravados',
      'Tem 9 letras, começa com CE e termina com O.',
    ),
    WordEntry(
      'CHOCALHO',
      'Som que depende de sacudir o pequeno por dentro',
      'Tem 8 letras, começa com CH e termina com O.',
    ),
    WordEntry(
      'CHURRASCO',
      'A brasa faz a reunião demorar mais',
      'Tem 9 letras, começa com CH e termina com O.',
    ),
    WordEntry(
      'CIMENTO',
      'Começa pó, termina compromisso duro',
      'Tem 7 letras, começa com CI e termina com O.',
    ),
    WordEntry(
      'COALIZÃO',
      'União prática mesmo sem amor perfeito',
      'Tem 8 letras, começa com CO e termina com O.',
    ),
    WordEntry(
      'COLHEITA',
      'O campo finalmente responde ao calendário',
      'Tem 8 letras, começa com CO e termina com A.',
    ),
    WordEntry(
      'CONCRETO',
      'Depois que endurece, opinião já não muda fácil',
      'Tem 8 letras, começa com CO e termina com O.',
    ),
    WordEntry(
      'CONFEITO',
      'Pequena alegria colorida sobre outra doçura',
      'Tem 8 letras, começa com CO e termina com O.',
    ),
    WordEntry(
      'CONSERTO',
      'A volta ao funcionamento depois do defeito',
      'Tem 8 letras, começa com CO e termina com O.',
    ),
    WordEntry(
      'COTOVELO',
      'A curva do braço que abre espaço na multidão',
      'Tem 8 letras, começa com CO e termina com O.',
    ),
    WordEntry(
      'DECORAÇÃO',
      'Quando o detalhe muda o clima do lugar',
      'Tem 9 letras, começa com DE e termina com O.',
    ),
    WordEntry(
      'DIAMANTE',
      'Brilho que não se impressiona com pressão',
      'Tem 8 letras, começa com DI e termina com E.',
    ),
    WordEntry(
      'ENCANADOR',
      'Chamado quando a água escolhe caminho errado',
      'Tem 9 letras, começa com EN e termina com R.',
    ),
    WordEntry(
      'ENFERMARIA',
      'Entre o susto e a melhora, costuma haver uma maca',
      'Tem 10 letras, começa com EN e termina com A.',
    ),
    WordEntry(
      'ESCULTURA',
      'Forma que saiu do bloco por insistência',
      'Tem 9 letras, começa com ES e termina com A.',
    ),
    WordEntry(
      'ESPELHO',
      'Responde com imagem, mas nunca com opinião',
      'Tem 7 letras, começa com ES e termina com O.',
    ),
    WordEntry(
      'ESTALEIRO',
      'Onde casco grande nasce antes de tocar água',
      'Tem 9 letras, começa com ES e termina com O.',
    ),
    WordEntry(
      'FANTOCHE',
      'Só ganha voz quando alguém se esconde atrás',
      'Tem 8 letras, começa com FA e termina com E.',
    ),
    WordEntry(
      'FARINHA',
      'Quase invisível no bolo, indispensável na massa',
      'Tem 7 letras, começa com FA e termina com A.',
    ),
    WordEntry(
      'FAZENDA',
      'Terra grande onde trabalho acompanha estação',
      'Tem 7 letras, começa com FA e termina com A.',
    ),
    WordEntry(
      'FECHADURA',
      'Pequeno guardião que reconhece dentes de metal',
      'Tem 9 letras, começa com FE e termina com A.',
    ),
    WordEntry(
      'FERRUGEM',
      'O tempo deixando cor no metal descuidado',
      'Tem 8 letras, começa com FE e termina com M.',
    ),
    WordEntry(
      'FOGUEIRA',
      'Luz no chão que chama roda e conversa',
      'Tem 8 letras, começa com FO e termina com A.',
    ),
    WordEntry(
      'GARIMPO',
      'Esperança cavada em busca de brilho escondido',
      'Tem 7 letras, começa com GA e termina com O.',
    ),
    WordEntry(
      'GRAVADOR',
      'Guarda som para o ouvido de depois',
      'Tem 8 letras, começa com GR e termina com R.',
    ),
    WordEntry(
      'HARMONIA',
      'Diferenças convivendo sem perder afinação',
      'Tem 8 letras, começa com HA e termina com A.',
    ),
    WordEntry(
      'HEMISFÉRIO',
      'Metade que ainda sugere um todo redondo',
      'Tem 10 letras, começa com HE e termina com O.',
    ),
    WordEntry(
      'HORIZONTE',
      'Promessa distante que recua quando se caminha',
      'Tem 9 letras, começa com HO e termina com E.',
    ),
    WordEntry(
      'ILUSTRAÇÃO',
      'Quando o texto ganha companhia visual',
      'Tem 10 letras, começa com IL e termina com O.',
    ),
    WordEntry(
      'JARDINEIRO',
      'Lida com crescimento sem apressar raiz',
      'Tem 10 letras, começa com JA e termina com O.',
    ),
    WordEntry(
      'LANTERNA',
      'Pequeno sol que cabe na mão',
      'Tem 8 letras, começa com LA e termina com A.',
    ),
    WordEntry(
      'LAVANDERIA',
      'Onde manchas entram esperançosas e saem julgadas',
      'Tem 10 letras, começa com LA e termina com A.',
    ),
    WordEntry(
      'MAQUINISTA',
      'Segue trilhos, mas ainda precisa conduzir',
      'Tem 10 letras, começa com MA e termina com A.',
    ),
    WordEntry(
      'MARATONA',
      'Distância que transforma pressa em erro',
      'Tem 8 letras, começa com MA e termina com A.',
    ),
    WordEntry(
      'MÁSCARA',
      'Rosto emprestado para esconder ou proteger',
      'Tem 7 letras, começa com MÁ e termina com A.',
    ),
    WordEntry(
      'MOSAICO',
      'Muitos pedaços aceitam virar uma imagem',
      'Tem 7 letras, começa com MO e termina com O.',
    ),
    WordEntry(
      'OFICINA',
      'Lugar onde defeito vira tentativa',
      'Tem 7 letras, começa com OF e termina com A.',
    ),
    WordEntry(
      'OXIGÊNIO',
      'Invisível, mas o corpo percebe sua ausência',
      'Tem 8 letras, começa com OX e termina com O.',
    ),
    WordEntry(
      'PASSARELA',
      'Caminho estreito feito para atravessar olhares',
      'Tem 9 letras, começa com PA e termina com A.',
    ),
    WordEntry(
      'PEDREIRO',
      'Ergue parede antes que a casa tenha nome',
      'Tem 8 letras, começa com PE e termina com O.',
    ),
    WordEntry(
      'PELÍCULA',
      'Camada fina entre proteção e registro',
      'Tem 8 letras, começa com PE e termina com A.',
    ),
    WordEntry(
      'PENEIRA',
      'Escolhe pelo tamanho sem perguntar o nome',
      'Tem 7 letras, começa com PE e termina com A.',
    ),
    WordEntry(
      'PINGENTE',
      'Pequeno detalhe que vive pendurado',
      'Tem 8 letras, começa com PI e termina com E.',
    ),
    WordEntry(
      'PIRÂMIDE',
      'Quanto mais sobe, menos espaço deixa',
      'Tem 8 letras, começa com PI e termina com E.',
    ),
    WordEntry(
      'PLANÍCIE',
      'Paisagem onde o alto quase não interrompe',
      'Tem 8 letras, começa com PL e termina com E.',
    ),
    WordEntry(
      'RECREIO',
      'A escola respira alto por alguns minutos',
      'Tem 7 letras, começa com RE e termina com O.',
    ),
    WordEntry(
      'ROMANCE',
      'Pode ocupar páginas ou complicar corações',
      'Tem 7 letras, começa com RO e termina com E.',
    ),
    WordEntry(
      'SAUDADE',
      'Presença feita justamente pela falta',
      'Tem 7 letras, começa com SA e termina com E.',
    ),
    WordEntry(
      'SOLDADO',
      'Disciplina em uniforme diante de ordem maior',
      'Tem 7 letras, começa com SO e termina com O.',
    ),
    WordEntry(
      'SORVETE',
      'Prazer que perde forma se a conversa demora',
      'Tem 7 letras, começa com SO e termina com E.',
    ),
    WordEntry(
      'TALHERES',
      'Pequenas ferramentas da cerimônia diária da mesa',
      'Tem 8 letras, começa com TA e termina com S.',
    ),
    WordEntry(
      'TARTARUGA',
      'Leva a própria proteção em ritmo paciente',
      'Tem 9 letras, começa com TA e termina com A.',
    ),
    WordEntry(
      'TEMPERO',
      'Pouco dele muda o destino do prato',
      'Tem 7 letras, começa com TE e termina com O.',
    ),
    WordEntry(
      'TESOURA',
      'Corte que só funciona quando duas partes concordam',
      'Tem 7 letras, começa com TE e termina com A.',
    ),
    WordEntry(
      'VASSOURA',
      'Antes do chão parecer limpo, ela já trabalhou',
      'Tem 8 letras, começa com VA e termina com A.',
    ),
    WordEntry(
      'VIOLINO',
      'Madeira pequena que pode soar imensa',
      'Tem 7 letras, começa com VI e termina com O.',
    ),
  ],
};

const Map<GameLevel, List<WordEntry>> wordBank = _baseWordBank;
