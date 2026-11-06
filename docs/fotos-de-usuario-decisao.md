# Fotos de usuário: storage, moderação e regras (etapa 0)

Pesquisa e medições feitas em 2026-11-03, antes de qualquer código. Cada item diz se foi **verificado** (li a página oficial ou rodei e medi), **inferido** ou **não verificado**.

## 1. Regras da Apple que valem para esta feature

Fonte: [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/), lida em 2026-11-03.

- **1.2 Conteúdo gerado por usuário** (verificado, texto atual). O app precisa ter: um método para filtrar material ofensivo antes de ser publicado, um mecanismo para denunciar conteúdo com resposta rápida, a opção de bloquear usuários abusivos e um contato publicado. A Apple também diz que é responsabilidade do desenvolvedor remover o que viola as regras e que pode pedir um plano de melhoria.
- **1.2.1(a) e 4.7.5** (verificado) pedem "verified or declared age" só para apps de criadores e para software dentro do app. Não se aplicam diretamente ao Lero, mas a declaração de idade da seção 3 já atende.
- **5.1.1(iii)** (resumo da página): usar o seletor fora do processo (`PhotosPicker`) em vez de acesso total às fotos. Já está no plano.
- **5.1.1(v)**: a exclusão de conta precisa existir dentro do app. A rota do backend já existe (#39); a foto do usuário entra nela.
- **5.1.2(i)** (resumo da página): enviar dados pessoais para **IA de terceiros** exige aviso claro e **permissão explícita**. Uma foto com pessoas é dado pessoal. **Consequência:** se a moderação usar uma API externa (Cloudflare, Sightengine, Google), o termo precisa de um aceite específico para isso. Modelos rodando no nosso backend não são "terceiros" e evitam essa exigência.

## 2. Classificação etária

Fonte: [Age ratings values and definitions](https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions/). A página foi lida em parte: o questionário completo não carregou, só a tabela.

- Faixas em vigor no iOS 26 em diante: 4+, 9+, 13+, 16+, 18+ (verificado).
- Conteúdo de usuário, mensagens e anúncios, sozinhos: 4+.
- Referências a álcool, tabaco ou drogas: **infrequentes → 13+, frequentes → 18+** (tabela; não confirmado no questionário).
- O Lero lista bares e festas: a resposta honesta é **frequentes**. **Resultado: 18+** (inferido da tabela). Moderar antes de publicar não muda a faixa.
- Brasil: a classificação do Ministério da Justiça (MJSP) é aplicada à parte. Os pictogramas vão de L a 18 e a página não traz os critérios. Confira na App Information depois de salvar o questionário.

**Proposta de idade mínima: 18 anos para usar o app.** Isso combina com a classificação 18+ e evita tratar dados de menores (pela LGPD, exigiria consentimento do responsável).

- **Mecânica:** declaração de data de nascimento no cadastro por e-mail e numa tela única no primeiro acesso de quem já tem conta ou entra com Apple, que não informa a idade.
- **O que guardar:** só `ageDeclaration = { isAdult, declaredAt, method: "self_declared" }`, não a data. É minimização de dados.
- **Menores em primeiro plano:** a checagem continua, porque a foto pode mostrar terceiros.
- **Validação jurídica:** ver a seção 7.

## 3. Storage

| | Supabase Free | Cloudflare R2 | Railway Object Storage | Backblaze B2 |
|---|---|---|---|---|
| Espaço grátis | 1 GB | 10 GB-mês | não há; US$ 0,015/GB-mês | 10 GB |
| Saída de dados | 5 GB/mês | grátis | grátis | grátis até 3× o armazenado (fontes divergem) |
| Cartão | **não informado** na página | provavelmente sim (guias de terceiros; página oficial não diz) | sim (Hobby exige cartão pós-pago) | fontes divergem |
| Pegadinha | **projeto pausa após 1 semana de inatividade**; sem transformação de imagem no Free | | depende do plano Hobby | |
| Fonte | [pricing](https://supabase.com/pricing), [pausa](https://supabase.com/docs/guides/platform/free-project-pausing) | [R2 pricing](https://developers.cloudflare.com/r2/pricing/) (atualizada em 2026-10-30) | [Railway pricing](https://railway.com/pricing) | só fontes de terceiros |

- **Conta de espaço (inferido):** cerca de 400 KB por foto em 2048 px com JPEG 80%, mais uma versão de 1024 px para a lista (cerca de 150 KB). 1 GB cabe umas 1.800 fotos publicadas. O original é apagado depois da decisão.
- **Ponto não verificado:** não achei nos docs do Supabase se um bucket público permite listar arquivos sem chave, nem se as URLs param de funcionar com o projeto pausado.
- **Não consegui verificar:** se Supabase, R2 e B2 pedem cartão no cadastro. Isso só aparece ao criar a conta, e criar conta não posso fazer por você.

**Recomendação:**
- **Se o Railway estiver no Hobby:** usar o Object Storage do próprio Railway. É o mesmo fornecedor e cartão, cerca de US$ 0,02/mês e sem pausa.
- **Se estiver no Free ou Trial:** Supabase, que você abre e confirma se pede cartão. O risco de pausa é atenuado porque o backend chama a API toda semana (inferido; os docs falam em "baixa atividade" sem definir).
- **Nos dois casos:** o código fala com uma interface `PhotoStorage` no padrão S3 (que os quatro aceitam) e tem um adaptador de disco para desenvolvimento e testes. Trocar de provedor vira só configuração.

## 4. Moderação: o que foi medido

**Como medi:** uma amostra de 62 arquivos, montada assim:
- 16 fotos curadas do Mapillary;
- 21 fotos do Wikimedia Commons com licença CC, com créditos em `credits.json`;
- 25 casos sintéticos: borrão, escuro, print de conversa, documento falso, placa Mercosul de exemplo, pichação ofensiva, marca d'água, 7 cópias de foto (exata, recomprimida, reduzida, cortada com mais brilho, espelhada, em PNG, em HEIC), arquivo de texto, PDF, SVG com script, JPEG truncado e uma bomba de descompressão de 30.000 × 30.000 px em 110 KB.

Não usei nenhuma imagem de nudez, de violência real ou de menor em situação sensível. Para esses casos, a única evidência é a taxa de falso positivo nas imagens seguras, e os testes do backend vão usar saída simulada do modelo.

- Máquina: Apple M4 com 24 GB, Node 26, `sharp` 0.35.5 e `@huggingface/transformers` 4.3.1, com modelos quantizados (q8) rodando no próprio processo.
- **Scripts:** `/private/tmp/claude-502/-Users-dalpra-Zanzar/ade6c065-5180-45a2-92fa-e17b633861c9/scratchpad/moderation-bench/` (`bench.mjs`, `face.mjs`, `dupdist.mjs`, `analyze.mjs`). Vão para `ZanzarBackend/scripts/moderation-bench/` na etapa 2.

| Camada | Ferramenta | Resultado na amostra | Custo |
|---|---|---|---|
| Arquivo válido | assinatura do arquivo (magic bytes) + `sharp` com limite de 40 Mpx e decodificação completa | **5/5** arquivos inválidos ou hostis barrados (texto, PDF, SVG, truncado, bomba); 0 falso positivo. **O HEIC também foi barrado**: o `sharp` pré-compilado não decodifica HEVC. Então o app converte para JPEG antes de enviar (já estava no plano) e o servidor aceita só JPEG e PNG | 5 ms |
| Qualidade | brilho médio e variância do Laplaciano (`sharp`) | **4/4** borrões e escuros barrados; 0 falso positivo em 51 fotos boas. Limiar: nitidez abaixo de 40 ou brilho abaixo de 25. A pior foto boa tem nitidez 196 | 15 ms |
| Cópia exata | sha256 | 1/1 | ~0 |
| Cópia quase igual | pHash de 64 bits + espelho | Cópias: distância de 0 a 14. Fotos diferentes: **mínimo 18** em 1.256 pares. Distância ≤ 10 barra (5/7). De 11 a 17 vai para revisão (o corte com mais brilho deu 14; o quadro seguinte do mesmo vídeo, 12). **Margem pequena**: amostra pequena, recalibrar com fotos reais | 2 ms |
| Rosto | UltraFace RFB-320 (ONNX, 1,2 MB, MIT) | **4/5** fotos com rosto ou menores marcadas (regra: rosto ≥ 1% da área ou ≥ 5 rostos). Escapou um retrato de corpo inteiro em plano médio (rosto com 0,17% da área). 1 falso positivo: uma tigela num prato de 342 px | 5 ms, +11 MB |
| Nudez | ViT `AdamCodd/vit-base-nsfw-detector` (Apache-2.0) | Nota máxima em imagens seguras: 0,22. Com limiar 0,5 → 0 falso positivo em 51. **Acerto em nudez real: não medido** | 130 ms, ~250 MB |
| Tipo de foto | CLIP ViT-B/32 em classificação zero-shot (MIT) | Documento 0,99 e print 0,75: **2/2**. Comida 0,95. Selfie e grupo pegos em 3/4. **"É do lugar": fraco**: só 5 de 14 fotos boas passam de 0,5 (as do Mapillary têm cara de "rua"), com 1 falso positivo. Marca d'água 0/2. Placa 0/1. Criança: sinal fraco (0,35) | 17–40 ms, ~460 MB |
| Texto e dados pessoais | Tesseract (por+eng) + regras de padrão | Print e documento lidos por inteiro (telefone, e-mail, CPF). Placa parcial ("BRA2E1", casa com o padrão Mercosul). `@perfil_alheio` lido. **Pichação estilizada: não lida.** Em foto comum o OCR gera muito lixo, então só vale casar padrões, nunca "achou texto" | 110 ms |
| Violência | rótulo do CLIP | **Não medido** (não há imagem segura para testar); usar saída simulada | — |
| Detector de pessoa | YOLOS-tiny | Funciona, mas usou **2,9 GB de RAM** e 930 ms por foto. **Descartado** | — |

**Atenção:** com o Railway no Free (0,5 GB), CLIP e o modelo de nudez **não cabem** no servidor. Ficaram só como referência de medição.

**O que isso quer dizer:**
- As camadas baratas são confiáveis para **barrar**: arquivo inválido, borrão ou escuro, cópia, documento e print, PII lida.
- Para **"é do lugar"**, marca d'água, pichação, menores e violência, os modelos abertos pequenos não bastam para **aprovar sozinhos**. Na dúvida, a foto vai para `needs_review`.
- Com o que há hoje, estimo que **metade ou mais das fotos boas cairia na revisão humana** no começo (inferido da amostra; as fotos do Mapillary são mais difíceis que uma foto tirada de propósito).

### Modelo de visão com linguagem: medido (Mistral Small 3.1)

O mesmo modelo do Cloudflare (`@cf/mistralai/mistral-small-3.1-24b-instruct`) rodou localmente no Ollama (`mistral-small3.1:24b`, q4) com as mesmas 45 fotos válidas e a mesma pergunta em JSON (`ZanzarBackend/src/modules/user-photos/moderation/vision-layer.ts`). Antes testei o `llama3.2-vision:11b`, mas o Ollama 0.40 não carrega mais essa arquitetura.

| Pergunta | Acertos | Falsos alarmes | Escapou |
|---|---|---|---|
| Marca d'água ou crédito alheio | 2/2 | 0 | 0 |
| Texto ofensivo (a pichação que o OCR não leu) | 1/1 | 0 | 0 |
| Dados pessoais (print, documento) | 2/3 | 1 (placa de saída de emergência) | a placa de carro sintética |
| Rosto em primeiro plano | 3/4 | 3 (pilotos de capacete) | o retrato em plano médio |
| Menores | 1/1 | 4 (ruas e parquinho vazios) | 0 |
| "Mostra o lugar" | 14/15 fotos boas | 10 de 15 fotos "sem lugar" passaram como lugar | o bosque |
| Qualidade ruim | 4/4 | 3 | 0 → **ignorado**; a camada própria é melhor |
| Nudez, violência | — | 0 em 45 fotos seguras | não medido |

**Simulação da decisão completa** (qualidade + rosto no servidor + Mistral):

| Tipo de foto | Aprovada sozinha | Revisão humana | Reprovada |
|---|---|---|---|
| Foto boa do lugar (15) | **12** | 3 | 0 |
| Rua ou outro lugar sem o local (15) | 6 | 9 | 0 |
| Pessoa em destaque (4) | 1 | 3 | 0 |
| Menores (1) | 0 | 1 | 0 |
| Borrada ou escura (4) | 0 | 0 | 4 |
| Texto ou dados pessoais (4) | 0 | 4 | 0 |
| Marca d'água (2) | 0 | 2 | 0 |

- Os modelos locais sozinhos aprovavam cerca de 5 de 14 fotos boas. Com o Mistral, 12 de 15.
- Nenhuma foto com dado pessoal, texto ofensivo, marca d'água ou menor foi aprovada sozinha.
- O que escapou: 6 fotos de rua ou parque que não eram do lugar (inofensivas) e 1 retrato de corpo inteiro em plano médio. Para essas, sobram a denúncia e a revisão.
- **Custo no Cloudflare (inferido):** cerca de 1.600 tokens de entrada por foto (contagem do Ollama) e cerca de 150 de saída. Isso dá uns 60 Neurons por foto, então os 10.000 Neurons grátis por dia cobrem cerca de **160 fotos/dia**. Acima disso, cerca de US$ 0,0007 por foto.
- **Formato da requisição:** verificado de ponta a ponta contra o Ollama (endpoint compatível com OpenAI, imagem como `image_url` em data URL). **Não verificado no Cloudflare:** a documentação do modelo não descreve o campo de imagem, e preciso de uma conta para testar.
- Lentidão local (35 s por foto no M4) não importa em produção.

### Outras opções de modelo de visão que não medi

Um modelo como o `llama-3.2-11b-vision` responde em JSON a todas as perguntas: é do lugar, tem marca d'água, texto ofensivo, menores, placa. Isso reduziria muito a revisão humana.

- **[Cloudflare Workers AI](https://developers.cloudflare.com/workers-ai/platform/pricing/)** (verificado): 10.000 Neurons/dia grátis, incluídos no plano Free do Workers. Não usa os dados para treino e não guarda entrada nem saída ([data usage](https://developers.cloudflare.com/workers-ai/platform/data-usage/)). **Mas é IA de terceiros**: exige o aceite da 5.1.2(i) e precisa da sua conta e chave. Não verifiquei se pede cartão.
- **Sightengine Free:** 2.000 operações/mês, no máximo 500/dia, com detectores próprios de nudez e violência. Guarda as imagens? Não diz. Pede cartão? Não diz.
- **Gemini grátis: descartado.** Os termos do plano grátis dizem que o Google usa o conteúdo para melhorar produtos e que revisores humanos podem ler. Também proíbem esse uso para usuários na UE e no Reino Unido e em apps para menores.
- **Hugging Face Inference: descartado.** Usuário grátis não recebe créditos.
- **Google Cloud Vision:** página não carregou. Não verificado.

## 4b. Decisão tomada

- **Storage:** Supabase Free, porque o Railway está no Free ou Trial. O código fala com uma interface `PhotoStorage`; em desenvolvimento grava numa pasta local.
- **No servidor (cabe nos 0,5 GB):**
  - validação do arquivo;
  - qualidade;
  - foto repetida (pHash);
  - rosto (UltraFace);
  - confiança no autor: conta nova sem check-in, fotos já reprovadas ou retiradas.
- **Julgamento:** Mistral Small 3.1 no Cloudflare Workers AI. É IA de terceiros, então o termo pede aceite explícito (5.1.2(i)).
- **Regra da decisão:**
  - aprovada só se todas as camadas passarem;
  - reprovada sem humano só quando a qualidade é ruim;
  - qualquer alerta da IA, camada fora do ar, resposta ilegível ou erro vai para revisão humana.
- **Sem o Cloudflare configurado,** nenhuma foto é aprovada sozinha: todas vão para revisão.

## 5. Custo estimado

Com a decisão da seção 4b (Railway Free ou Trial, Supabase Free, Mistral no Cloudflare):

- **Railway:** as camadas do servidor (sharp e um modelo de 1,2 MB) somam cerca de 11 MB de RAM e 25 ms por foto. Não muda a conta do Railway (inferido da medição local).
- **Cloudflare Workers AI:** cerca de 60 Neurons por foto. Grátis até cerca de 160 fotos/dia; acima disso, cerca de US$ 0,0007 por foto (inferido).
- **Supabase:** grátis até 1 GB (cerca de 1.800 fotos publicadas) e 5 GB de saída por mês.
- **Total estimado: US$ 0/mês** no volume previsto.
- **Riscos de custo:**
  - o Trial do Railway vence em 30 dias, e o Free dá só US$ 1/mês de uso;
  - o projeto Supabase pausa após uma semana sem atividade;
  - ninguém confirmou se Supabase e Cloudflare pedem cartão no cadastro.

Referência, se um dia o plano for Hobby: RAM a US$ 10/GB-mês e vCPU a US$ 20/mês, cobrados por segundo (verificado). Os modelos locais maiores (CLIP e nudez, cerca de 750 MB) custariam cerca de US$ 7,50/mês sempre carregados, ou menos de US$ 0,05/mês carregados só quando há fila.

## 6. SensitiveContentAnalysis (no aparelho)

Verificado nos headers do SDK em `Xcode.app/.../SensitiveContentAnalysis.framework` (a página da Apple não carregou para leitura):

- `SCSensitivityAnalyzer.analysisPolicy` tem três estados: `.disabled` (nada ligado, a análise não roda), `.simpleInterventions` (o usuário ativou "Aviso de Conteúdo Sensível") e `.descriptiveInterventions` (Segurança na Comunicação do Tempo de Uso, para crianças e adolescentes).
- APIs: `analyzeImage(at: URL)` e `analyzeImage(_ cgImage:)` devolvem `SCSensitivityAnalysis.isSensitive`.
- Os tipos `sexuallyExplicit` e `goreOrViolence` só existem a partir do **iOS 27**. O alvo do app é 26, então precisa de `if #available`.
- Entitlement: `com.apple.developer.sensitivecontentanalysis.client` (o nome vem da URL da documentação; **o valor exato não foi verificado**). Precisa estar ativo no App ID.
- **Não verificado:** se a análise funciona no simulador. É item do roteiro no iPhone real.
- **Conclusão:** na maioria dos aparelhos a política é `.disabled`, então essa camada é um bônus e nunca a barreira principal.

## 7. Para revisão jurídica

- Base legal da LGPD para analisar a foto: execução do serviço ou consentimento. E, se a moderação for externa, o consentimento específico da 5.1.2.
- Idade mínima de 18 com autodeclaração: é suficiente para o Lero? E se uma foto aprovada mostrar um menor ao fundo?
- Texto da licença que o usuário concede (não exclusiva, para exibir no app, revogável ao apagar a foto) e direito de imagem de terceiros na foto.
- Prazo de retenção: original apagado depois da decisão; foto reprovada apagada em 30 dias (proposta); registro de auditoria sem a imagem por quanto tempo?
- Como o titular exerce os direitos (contato, prazo de resposta).
