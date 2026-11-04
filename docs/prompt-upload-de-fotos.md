# Prompt: fotos enviadas por usuários, com moderação automática

Cole tudo abaixo da linha numa sessão nova, aberta nas duas pastas (`Zanzar` e `ZanzarBackend`). Os itens marcados **[CONFIRMAR]** são decisões que eu assumi e você pode trocar antes de colar.

---

## Objetivo

Usuários do Lero enviam fotos dos lugares. Antes de aparecer para qualquer pessoa, cada foto passa por moderação automática em camadas e, na dúvida, por revisão humana. O app explica ao usuário, antes do envio, o que acontece com a foto. Entregar de ponta a ponta: permissões, envio, armazenamento, moderação, publicação, denúncia, remoção e testes.

## Contexto

- App iOS SwiftUI (`/Users/dalpra/Zanzar`, leia o `CLAUDE.md`) e backend Node/Express + MongoDB Atlas (`/Users/dalpra/ZanzarBackend`, Railway). Contrato entre os dois em `docs/APP-BACKEND.md`.
- Hoje cada lugar tem `images[]` = `{url, credit{author, license, licenseUrl, sourceUrl}}`, vindo de Commons e Mapillary, hospedado no GitHub via jsDelivr. O app mostra até 5 fotos com crédito (`PlaceDetailPhotoCarousel`, `PlacePhotoCreditView`).
- jsDelivr/GitHub **não serve** para upload de usuário. É preciso um storage de objetos.
- Contexto da pesquisa: `docs/metodos-de-fotos.md` e `docs/pesquisa-fotos.md`. O cartão da Apple (outra PR) é complemento e não muda este trabalho.

## Decisões já tomadas

1. **Quando enviar:** após check-in (foto marcada como "verificada") **e** pela tela do lugar sem check-in (sem a marca). **Sem limite de quantidade** por usuário, por lugar ou por dia (só o limite técnico de taxa contra abuso, na seção F). **Foto idêntica não pode ser enviada**: nem repetida pelo mesmo usuário, nem copiada por outro, em qualquer lugar. Vale para cópia exata (hash) e para a visualmente quase igual (hash perceptual, com limiar que você mede). O app avisa "essa foto já foi enviada" sem dizer de quem.
2. **Moderação:** em camadas, custo zero ou quase zero, sem cartão se possível.
3. **Publicação:** a foto só aparece para os outros depois de aprovada. O autor vê a própria foto como "em análise".
4. **Storage:** recomendo **Supabase Storage** (camada gratuita, sem cartão). Cloudflare R2 é a alternativa, mas pode exigir cartão. **[CONFIRMAR]** Antes de decidir, **verifique os limites atuais nas páginas oficiais** e reporte; não presuma.

## Restrições inegociáveis

- Custo zero ou quase zero. Se algo exigir cartão ou cobrar, pare e pergunte.
- Legal no Brasil: LGPD, direito de imagem, direitos autorais, e diretriz 1.2 da App Store (conteúdo gerado por usuário). **Confira o texto atual da diretriz 1.2 e das diretrizes de privacidade da Apple** antes de implementar, e cite o que achou.
- Não envie mensagem nem contate ninguém em meu nome. Não coloque segredos, tokens ou chaves no repositório. Nunca commitar `Config.xcconfig`.
- Não faça push, abra PR nem toque em produção sem eu pedir. Trabalhe em branch nova a partir de `develop`.
- Siga as convenções do `CLAUDE.md`: MVVM-C, um tipo por arquivo, textos em `Localizable.xcstrings` (en + pt-BR), logs com `AppLog`, nada de `print`, testes em Swift Testing.

## Como quero que você trabalhe

1. **Primeiro, só leia e pergunte.** Mapeie o fluxo atual de check-in, a tela do lugar, o modelo `images[]`, a autenticação e as rotas do backend. Liste o que falta decidir e me pergunte antes de implementar.
2. **Escreva um plano curto** (arquitetura, endpoints, modelo de dados, ordem das entregas) e espere meu OK.
3. **Implemente por etapas pequenas**, cada uma com testes e verificação. Compile e rode os testes do app e do backend a cada etapa.
4. **Separe sempre** no relatório: **verificado** (rodou, abriu, mediu), **inferido** e **não consegui verificar** (e por quê). Não declare pronto o que não testou.

## Escopo

### A. Explicação ao usuário (no app)

- Tela ou folha de explicação mostrada **antes do primeiro envio** e acessível depois (Perfil, Ajuda ou Termos). Deve dizer, em linguagem simples:
  - que a foto passa por análise automática e, às vezes, humana, e só aparece depois de aprovada;
  - quanto tempo costuma levar e que o autor é avisado do resultado;
  - o que não pode: pessoas reconhecíveis em primeiro plano, menores, nudez, violência, marca d'água ou foto de terceiros, foto que não é do lugar;
  - que a localização (EXIF) é removida;
  - **licença que o usuário concede** ao Lero (não exclusiva, para exibir no app, revogável ao apagar a foto) e que o nome do autor aparece como crédito, com opção de **não aparecer** (anônimo);
  - como apagar a foto e como denunciar uma foto.
- O aceite fica registrado (usuário, data, versão do texto). Sem aceite não há envio.
- Textos em pt-BR e en, revisados por mim. Marque o que precisa de revisão jurídica.

### B. Permissões e captura (iOS)

- Escolher da galeria com `PhotosPicker` (sem pedir permissão de fotos) e tirar com a câmera (`NSCameraUsageDescription`, texto claro; confira o `Info.plist` e o aviso conhecido de `NSLocationAlwaysAndWhenInUseUsageDescription`).
- Tratar todos os estados: permissão negada, restrita (controle parental), câmera indisponível (simulador), arquivo grande, formato HEIC/PNG/JPEG, sem rede, app em segundo plano durante o envio.
- Reduzir e recomprimir no aparelho (por exemplo lado maior 2048 px, JPEG ~80%), **remover EXIF** (GPS, modelo do aparelho, data) antes de sair do aparelho.
- Pré-checagem no aparelho:
  - **SensitiveContentAnalysis** da Apple. Atenção: ele só analisa se o usuário ativou o aviso de conteúdo sensível no iOS; com a política `.disabled` ele não faz nada. Verifique isso, não conte com ele como única barreira, e confira o entitlement necessário.
  - **Vision**: detectar rosto grande em primeiro plano e, se houver, **perguntar ao usuário**: "Enviar outra foto" ou "Borrar os rostos e enviar assim". Só borra se ele escolher isso (borrar com Vision no aparelho, antes do envio, e conferir o resultado numa prévia). O backend repete a checagem de rosto, porque o aparelho não é confiável.

### C. Backend: envio e armazenamento

- Endpoint autenticado de envio, com URL pré-assinada ou multipart (escolha e justifique). Validar tipo real do arquivo (não confiar na extensão), tamanho máximo, dimensões, quantidade e limite de taxa por usuário.
- Guardar o original **fora** de URL pública e a versão aprovada em local público (ou servida por URL assinada). Nome de arquivo aleatório, nunca o nome do usuário.
- Modelo de dados novo (não misturar com `images[]` curado): coleção de fotos de usuário com `placeId`, `userId`, `status` (`pending`, `approved`, `rejected`, `needs_review`, `removed`), `isVerifiedCheckIn`, `checkInId`, hashes, resultado de cada camada de moderação, motivo, datas, versão do termo aceito, `showAuthorName`.
- Deduplicar por hash (exata e perceptual) para barrar a mesma foto repetida.
- Lugares com `images[]` curado continuam como estão. Definir a regra de **mistura e ordem** no app: fotos curadas primeiro, fotos de usuários depois, verificadas antes das não verificadas. Máximo de 5 continua valendo, a menos que eu mude.

### D. Moderação automática em camadas

Defina, meça e justifique cada camada. Prefira o que roda sem custo; compare, não presuma.

1. **No aparelho** (item B).
2. **No backend, assim que a foto chega:** modelo de visão para (a) nudez e conteúdo sexual, (b) violência e conteúdo gráfico, (c) menores em primeiro plano, (d) rosto grande em primeiro plano, (e) texto ofensivo ou dados pessoais visíveis (placa de carro legível, documento, tela), (f) **a foto mostra o lugar** (fachada, letreiro, ambiente, prato) e não só a rua ou uma selfie, (g) qualidade mínima (não é um borrão).
   - Avalie opções gratuitas ou de custo desprezível (modelo aberto rodando no próprio backend, APIs com camada gratuita sem cartão). **Meça numa amostra de teste** (veja a seção de testes) e me mostre a taxa de acerto e o custo por foto antes de escolher.
3. **Contexto:** o usuário está perto do lugar? (check-in já valida). A conta é nova? Teve fotos reprovadas? Aplicar um nível de confiança por usuário.
4. **Decisão:** `approved` só com todas as camadas acima do limiar; `rejected` para violação clara (com motivo); **qualquer dúvida vai para `needs_review`**. Falha de uma camada (API fora do ar) **nunca** aprova: vai para `needs_review`.
5. **Fila de revisão humana** simples para a equipe do Lero (nós mesmos moderamos, sem terceiros): lista de pendentes com a foto, o lugar e o motivo da dúvida, e botões aprovar, reprovar e remover, protegida por credencial de admin. Pode ser uma página mínima no backend ou um script; proponha.
6. **Reanálise:** possibilidade de reprocessar fotos quando eu mudar os limiares.

### E. Ciclo de vida e transparência

- **Push, exclusão de conta e bloqueio de usuário já estão sendo feitos em outras branches.** Antes de mexer, procure essas branches e PRs (`gh pr list`, `git branch -a`), leia o que existe e **reaproveite**; não duplique. Se ainda não estiver pronto, deixe um ponto de integração claro (protocolo ou gancho) e liste o que depende deles.
- O autor vê o estado da foto ("em análise", "publicada", "não aprovada" com o motivo em linguagem simples) e é avisado quando muda (notificação local ou ao abrir o app; só use push se já existir infraestrutura, e pergunte).
- O autor pode **apagar** a foto a qualquer momento; apagar remove do storage, do cache e da lista pública.
- **Denunciar foto** (qualquer usuário) com motivos, **bloquear usuário**, e **contato do desenvolvedor** visível no app (exigências da diretriz 1.2). Denúncias derrubam a foto para `needs_review` automaticamente a partir de N denúncias.
- **Exclusão de conta** apaga ou anonimiza as fotos do usuário (verifique como o app já trata exclusão de conta).
- Registro de auditoria: quem enviou, quando, o que cada camada decidiu, quem revisou.

### F. Segurança e privacidade

- Autorização em todas as rotas: só o dono apaga a própria foto, só admin modera. Teste tentativas de acesso indevido (IDOR).
- Limite de taxa, tamanho e quantidade; proteção contra arquivo malicioso (imagem que é outro formato, bomba de descompressão).
- URLs do storage sem listagem pública. Nada de dados pessoais em log.
- LGPD: base legal e finalidade descritas no termo; retenção definida (por exemplo, original apagado após a decisão); como o usuário exerce os direitos. Liste o que precisa de validação do advogado.
- Atualizar a **privacidade do App Store Connect** (tipos de dado coletados: fotos, conteúdo do usuário) e as notas para a revisão da Apple, e me avise do que preciso preencher à mão.

## Testes e como saber que funciona

Quero provas, não afirmações.

1. **Amostra de moderação:** monte um conjunto de teste com pelo menos ~40 imagens **legalmente seguras** (fotos nossas, Commons/CC, imagens geradas ou sintéticas para os casos ruins; **não baixe nem gere conteúdo sexual explícito ou de menores**; para esses casos use as imagens de teste públicas e inofensivas que os próprios provedores oferecem, ou simulações como saída mockada do modelo). Cobrir: fachada boa, prato, selfie com rosto grande, foto escura/borrada, foto de rua sem o lugar, captura de tela com texto, foto duplicada, arquivo que não é imagem. Reportar acertos, falsos positivos e falsos negativos por camada.
2. **Backend:** testes automatizados de cada rota (envio, listagem, apagar, denunciar, moderar), de cada transição de `status`, de limite de taxa, de autorização e do caso "camada fora do ar → `needs_review`".
3. **App:** testes de ViewModel (estados de permissão, aceite, envio, erro, retry, "em análise"), do mapeamento do DTO e da regra de mistura e ordem. Rodar a suíte completa e o SwiftLint.
4. **Ponta a ponta no simulador** (XcodeBuildMCP e `mcp__Claude_Code_iOS_Simulator__control`): do check-in até ver a foto "em análise", aprovar pela fila e ver a foto publicada para outro usuário; e o caminho de reprovação e de apagar. Anexar capturas de tela.
5. **Aparelho físico:** liste o que só dá para validar num iPhone real (câmera, HEIC, SensitiveContentAnalysis) para eu testar à mão, com um roteiro passo a passo.
6. **Critérios de aceite:** uma foto nunca fica pública sem `approved`; falha de camada nunca aprova; EXIF nunca sai do aparelho; apagar remove de todos os lugares; sem aceite não há envio; nenhuma chave no repositório.

## Entregáveis

- Plano aprovado, código em branch nova (app e backend, commits pequenos), testes passando.
- `docs/` com: decisão de storage e moderação (com as medições), texto do termo e da explicação para revisão jurídica, roteiro de teste manual e checklist de App Store Connect.
- Relatório final com **verificado / inferido / não consegui verificar**, custo real mensal estimado, riscos legais abertos e o que depende de mim.

## Idade mínima

Ainda não decidida. O app lista bares e festas e passa a ter conteúdo de usuário, o que pesa na classificação etária e na LGPD (dados de menores exigem consentimento do responsável). Antes de implementar:

1. Responda o questionário de classificação etária do App Store Connect com as respostas que valerão após esta feature (álcool, conteúdo gerado por usuário, chat/mensagens se houver) e **me diga a classificação que resulta**. Confira a tabela de faixas vigente na documentação da Apple.
2. Proponha a idade mínima para **enviar fotos** (e para usar o app) e a mecânica no cadastro (data de nascimento ou declaração), com o texto do termo. Se o app já pergunta idade, reaproveite.
3. Se a idade mínima for 18, a análise de "menores em primeiro plano" continua valendo, porque a foto pode mostrar terceiros.

## Respostas já dadas

- Sem limite de quantidade; foto idêntica é proibida.
- Rosto em primeiro plano: o usuário escolhe entre enviar outra foto ou borrar.
- Moderação humana: a equipe do Lero.
- Push, exclusão de conta e bloqueio: em desenvolvimento em outras branches; integrar.
- Idade mínima: a propor (seção acima).
