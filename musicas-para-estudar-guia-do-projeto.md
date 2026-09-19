# MÚSICAS PARA ESTUDAR

## 1. Visão do projeto

**Músicas para Estudar** é um aplicativo Android de concentração que reúne música instrumental, clássica e brasileira para acompanhar leitura, estudos, tarefas e sessões Pomodoro. Em vez de ser apenas mais um player, o produto transforma a música em um recurso de foco: o usuário escolhe um objetivo, inicia uma seleção apropriada e mantém o ritmo da sessão.

O catálogo deve priorizar gravações e obras cuja utilização esteja regularizada. A marcação **“Obras em domínio público”** informa a situação da composição; a equipe ainda deve conferir direitos da gravação específica, intérprete, território e fonte antes de publicar cada faixa.

## 2. Público e proposta de valor

- Estudantes do ensino médio, vestibular/ENEM, graduação e concursos.
- Pessoas que trabalham com leitura, escrita ou tarefas de alta concentração.
- Usuários que desejam uma alternativa calma a aplicativos de música com anúncios e distrações.

**Promessa:** “Seu foco tem trilha sonora.”

## 3. Estrutura do aplicativo

| Área | Papel no produto |
|---|---|
| Início | Sugere uma trilha imediatamente e retoma a última escuta. |
| Explorar | Organiza a descoberta por intenção de estudo, estilo e compositor. |
| Foco | Une player e temporizador Pomodoro em uma experiência sem distração. |
| Biblioteca | Permite buscar compositores, obras, coleções e faixas salvas. |

## 4. Categorias musicais

### Foco profundo

Seleções instrumentais longas, previsíveis e com pouca variação abrupta. Ideal para escrever, programar, resolver exercícios e estudar por blocos extensos.

### Piano para estudar

Nocturnos, prelúdios, impromptus e peças de piano de compositores como Chopin, Schubert, Brahms, Fauré e Satie. A interface pode oferecer intensidade baixa, média ou alta.

### Clássica para leitura

Coleções leves de Mozart, Haydn, Debussy, Ravel, Handel e outras obras instrumentais que acompanham a leitura sem competir com o texto.

### Barroco para concentração

Bach, Vivaldi, Handel, Scarlatti, Corelli e Rameau. A categoria deve mostrar que o repertório é instrumental e separar peças mais agitadas das mais calmas.

### Piano para dormir

Piano lento, dinâmica baixa e transições longas. Deve incluir temporizador de desligamento e evitar picos de volume.

### Brasil instrumental

Espaço para a riqueza musical brasileira: Ernesto Nazareth, Chiquinha Gonzaga, Carlos Gomes, Alberto Nepomuceno, Francisco Braga, Glauco Velásquez, Luciano Gallet, Alexandre Levy, Leopoldo Miguez, Joaquim Callado, Anacleto de Medeiros e Zequinha de Abreu. A curadoria pode ter coleções como **Piano Brasileiro**, **Choro para Ler** e **Clássicos do Brasil**.

### Estudar para o ENEM

Coleções prontas para blocos de 25, 50 e 90 minutos, com comandos simples: começar, pausar e concluir sessão.

## 5. Tela 1 — Início

### Objetivo

Colocar o usuário em uma trilha de foco em poucos segundos.

### Componentes

1. Saudação contextual: `Bom estudo, [nome]`.
2. Card hero `Foco Profundo`, com título, subtítulo e botão de play.
3. Bloco `Escolha seu momento` com atalhos para Piano para Estudar, Clássica para Leitura, Barroco para Concentração e Brasil Instrumental.
4. Área `Continue ouvindo` para retomar a última faixa ou playlist.
5. Navegação inferior: Início, Explorar, Foco e Biblioteca.

### Direção visual

O hero utiliza uma arte abstrata serena — montanhas, lua, piano ou partitura — e nunca um artista famoso. O objetivo é criar calma antes mesmo do play.

## 6. Tela 2 — Explorar

### Objetivo

Fazer o usuário achar a trilha certa para a tarefa e o tempo disponível.

### Componentes

1. Título `Estude do seu jeito`.
2. Filtros em pílulas: Foco, Leitura, Sono e ENEM.
3. Cards de playlists: Pomodoro 25 min, Barroco para Concentração, Piano para Dormir e Brasil Instrumental.
4. Faixa `Compositores em destaque`, com Bach, Chopin, Debussy e Satie.
5. Navegação inferior com Explorar ativo.

### Direção visual

Os cards usam ilustrações e fotos de textura musical, arquitetura, paisagem ou instrumentos. Os títulos devem ter boa leitura sobre superfícies claras; a imagem é apoio, nunca ruído.

## 7. Tela 3 — Player e sessão de foco

### Objetivo

Concentrar tudo que importa em uma única tela: ouvir, controlar a faixa e completar uma sessão.

### Componentes

1. Capa abstrata da obra ou coleção.
2. Título da faixa, compositor e barra de progresso.
3. Controles: voltar, play/pausa, avançar e repetir.
4. Card `Sessão de foco` com círculo de tempo `25:00`.
5. Alternância conceitual entre trabalho e pausa.
6. CTA `Iniciar sessão`.
7. Mensagem discreta: `Sem anúncios durante seu foco.`

### Regras de experiência

- Ao iniciar a sessão, ocultar elementos dispensáveis e manter somente timer, faixa e pausa.
- No fim do ciclo, emitir som sutil e sugerir pausa de cinco minutos.
- Permitir ajuste de duração: 25/5, 50/10 e personalizado.
- A reprodução deve continuar em segundo plano quando o usuário trocar de app.

## 8. Tela 4 — Biblioteca

### Objetivo

Dar profundidade ao catálogo e facilitar a busca por compositor ou obra.

### Componentes

1. Título `Biblioteca de compositores`.
2. Busca: `Buscar compositor ou obra`.
3. Filtros: Clássica, Brasileira e Piano.
4. Lista de itens com compositor, obra, pequena descrição e selo de situação do catálogo.
5. Exemplos de destaque: `J. S. Bach — Goldberg Variations`, `Ernesto Nazareth — Odeon`, `Chiquinha Gonzaga — Ó Abre Alas` e `Erik Satie — Gymnopédies`.
6. Indicador do volume de acervo: `+1.000 faixas para estudar`.

### Direção visual

Retratos ou ilustrações de compositores aparecem pequenos e elegantes. A informação principal é o nome da obra; imagens servem para humanizar a pesquisa sem transformar a tela em uma galeria.

## 9. Identidade visual

### Conceito

A identidade combina três símbolos: **livro aberto**, **nota musical** e **concentração**. A marca deve remeter a conhecimento e tranquilidade, não a uma plataforma de entretenimento barulhenta.

### Assinatura

```text
MÚSICAS PARA
ESTUDAR
```

Tagline: `Seu foco tem trilha sonora.`

### Paleta de cores

| Cor | Hex | Aplicação |
|---|---:|---|
| Azul-noite | `#152238` | Títulos, navegação, player e texto de alta ênfase |
| Marfim | `#F7F3EA` | Fundo editorial e áreas de descanso visual |
| Branco | `#FFFFFF` | Cards, superfícies e variação limpa da marca |
| Lavanda suave | `#B5A8D8` | Estado selecionado, timer e elementos de foco |
| Sálvia | `#91A89B` | Estados positivos, pausas e mensagens calmas |
| Dourado suave | `#D6A54A` | Play, progresso e destaques pontuais |
| Tinta | `#222A35` | Texto secundário de contraste |
| Cinza quente | `#E9E5DC` | Bordas, divisores e fundos de controles |

### Tipografia

- **Títulos e controles:** Manrope, Plus Jakarta Sans ou Sora; peso 600 a 800.
- **Textos longos:** Inter; peso 400 a 600.
- **Títulos de obras, quando necessário:** DM Serif Display ou Lora; uso pontual em capas e áreas editoriais.

### Componentes e microinterações

- Escala de espaçamento: múltiplos de 8 px.
- Cards: raio de 20 a 24 px; bordas em cinza quente, sem sombra pesada.
- Botão de play: circular, dourado suave, 48 a 56 dp.
- CTA de foco: 52 dp de altura, azul-noite, texto branco.
- Timer: anel lavanda com progresso azul-noite; não depender apenas da cor para comunicar estado.
- Navegação inferior: quatro itens, ícones lineares de 2 px e item ativo em lavanda sobre superfície clara.

## 10. Direção de arte

- Misturar capas abstratas de piano, manuscritos, céu noturno, paisagens tranquilas e texturas de papel.
- Preferir luz suave, cores reduzidas e muito espaço em branco.
- Evitar o aspecto de aplicativo de streaming comercial: excesso de capas, cores neon, banners promocionais e chamadas agressivas.
- Não usar imagens de pessoas de fone como recurso visual padrão. O protagonista é o estado mental de concentração.

## 11. Acessibilidade

- Garantir contraste mínimo AA em textos e botões.
- Nunca usar dourado suave para texto pequeno sobre branco.
- Tamanho mínimo: 14 sp em rótulos e 16 sp em conteúdo principal.
- Áreas de toque com ao menos 48 x 48 dp.
- Exibir tempo restante também em números, e não somente pelo anel do timer.
- Oferecer controles de volume e temporizador com leitores de tela bem rotulados.

## 12. Curadoria e governança do acervo

Cada item do catálogo deve manter: compositor, obra, ano de morte do autor, país, fonte, tipo de licença, direitos da gravação, intérprete, território e data de verificação. Composição em domínio público não significa automaticamente que toda gravação seja livre para uso comercial.

Um fluxo recomendado é: pesquisar a obra → validar a situação legal por território → usar gravação licenciada, própria ou realmente liberada → registrar a fonte → publicar com metadados → revisar periodicamente.

## 13. Tom de voz

- Calmo, encorajador e direto.
- Exemplos: `Vamos começar?`, `Seu próximo bloco de foco`, `Acompanhe seu ritmo`, `Pausa concluída. Hora de voltar.`
- Evitar urgência artificial, gamificação infantilizada e excesso de notificações.
