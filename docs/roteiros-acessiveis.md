# Roteiros acessíveis de Curitiba (rascunho para validar)

Três roteiros de 4 paradas, pensados para **mobilidade reduzida** (rampa, elevador, banheiro adaptado, piso nivelado, trechos curtos) e **cegos e baixa visão** (miniaturas táteis, piso tátil, experiência sensorial).

Estado: **só desenho**. Nada foi cadastrado no backend (`ZanzarBackend/scripts/seed/seed-zanzardb.js`) nem no app.

## Como ler a confiança de cada parada

| Selo | Significa |
|---|---|
| 🟢 | A Prefeitura divulgou obra ou recurso de acessibilidade naquele lugar (visto em resumo de busca de notícia oficial) |
| 🟡 | O lugar consta no guia/e-book de acessibilidade da Prefeitura, mas não achei o detalhe do que ele tem |
| 🔴 | Não achei informação nenhuma; entra só se o Lucas confirmar |

**Limite importante:** as páginas da Prefeitura (curitiba.pr.gov.br) recusaram a leitura automática (403). Tudo abaixo vem de resumos de busca, não do guia oficial e não de visita. **Nada aqui deve ir para o texto do app antes de conferir no guia oficial ou ligar para o local.**

---

## Roteiro 1 · Curitiba para todos (cartões-postais com miniaturas táteis)

Sugestão de slug: `curitiba-para-todos` · rota fixa · tema: `museums` e `walking` (ou `accessible`, se for criado)

| # | Parada | No catálogo | Selo | O que a fonte diz (a confirmar) |
|---|---|---|---|---|
| 1 | **Jardim Botânico** | Sim | 🟢 | Obra de R$ 3,9 mi para acessibilidade: banheiros adaptados, rampas, calçadas acessíveis, mirante acessível, Centro de Atendimento ao Turista com rampa. Empréstimo gratuito de miniaturas táteis para cegos |
| 2 | **Museu Oscar Niemeyer (MON)** | Sim | 🟡 | No guia da Prefeitura. Uma fonte genérica fala em rampas e elevadores. Miniatura tátil disponível |
| 3 | **Memorial Paranista** | Sim | 🟡 | No guia da Prefeitura (primeira edição). Sem detalhe |
| 4 | **Parque Tanguá** | Sim | 🟢 | Parquinho inclusivo adaptado; banheiros públicos reformados para ficarem mais acessíveis; miniaturas táteis. Dúvida: o mirante no alto pode ter escada |

Alternativa à parada 3 ou 4: **Ópera de Arame** (no guia oficial, mas **não está no catálogo** e a concessionária não publica dados de acessibilidade que eu tenha achado; o acesso é por passarela sobre o lago).

Ordem: do sudeste para o norte, passando pelo Centro Cívico. Distâncias e tempo **a medir no Apple Maps**.

Texto sugerido para o app (pt-BR), a revisar depois da checagem:
- Nome: "Curitiba para todos"
- Descrição: "Quatro cartões-postais de Curitiba para visitar com calma, com opções para quem usa cadeira de rodas e para quem enxerga pouco ou nada."
- Objetivos: Parque, Museu, Memorial, Parque

---

## Roteiro 2 · Centro sem degraus

Sugestão de slug: `centro-sem-degraus` · rota fixa · tema: `center` e `walking`

| # | Parada | No catálogo | Selo | O que a fonte diz (a confirmar) |
|---|---|---|---|---|
| 1 | **Passeio Público** | Sim | 🟢 | Primeiro playground adaptado para crianças com deficiência de Curitiba, com balanço para cadeira de rodas. Piso e rampas do parque: **sem informação** |
| 2 | **Sesc Paço da Liberdade** (Praça Generoso Marques) | Sim | 🟡 | No guia da Prefeitura. A Rua XV (calçadão) também foi incluída no e-book |
| 3 | **Cine Passeio** (R. Riachuelo) | Sim | 🟡 | No guia da Prefeitura (primeira edição) |
| 4 | **Museu Paranaense (MUPA)** (R. Kellers) | Sim | 🟡 | No guia da Prefeitura. O prédio passou por reforma estrutural; **não achei** o que ela mudou em acesso. Abre de terça a domingo, 10h às 17h30 |

Cuidados:
- O **Setor Histórico / Largo da Ordem** tem paralelepípedo e ladeira. Ele consta no e-book, mas é onde mais vale checar o trecho até o MUPA antes de mandar alguém de cadeira de rodas.
- Evitar o **Memorial de Curitiba** neste roteiro até alguém confirmar o acesso.

Texto sugerido (pt-BR):
- Nome: "Centro sem degraus"
- Descrição: "Um passeio curto pelo Centro, com parque, cinema, museu e praça, em lugares que a Prefeitura já mapeou no guia de acessibilidade."
- Objetivos: Parque, Histórico, Cinema, Museu

---

## Roteiro 3 · Parques inclusivos

Sugestão de slug: `parques-inclusivos` · rota fixa · tema: `parks` e `walking`

| # | Parada | No catálogo | Selo | O que a fonte diz (a confirmar) |
|---|---|---|---|---|
| 1 | **Parque Barigui** (Av. Cândido Hartmann) | Sim (há **dois** cadastros; usar o da Cândido Hartmann) | 🟢 | Parquinho inclusivo em terreno plano, perto do estacionamento, com acesso por rampa. No e-book. Pista e banheiros adaptados: só fonte genérica, **sem detalhe** |
| 2 | **Bosque Alemão** | Sim | 🟢 | Prefeitura divulgou obras que o deixaram mais acessível; Casa Encantada reaberta |
| 3 | **Parque Tingui** (+ Memorial Ucraniano) | Sim | 🟡 | No e-book (edição mais recente). Rampas e banheiros: **sem detalhe**. Memorial: terça a domingo, 10h às 18h |
| 4 | **Parque Tanguá** | Sim | 🟢 | Parquinho inclusivo; banheiros reformados; miniaturas táteis |

Ordem: arco do noroeste para o norte. Medir no mapa.

Texto sugerido (pt-BR):
- Nome: "Parques inclusivos"
- Descrição: "Quatro parques de Curitiba com brinquedos adaptados, trilhas planas e áreas para ficar com calma."
- Objetivos: Parque, Natureza, Brincar

---

## O que falta antes de cadastrar

1. **Conferir cada parada** no e-book de acessibilidade da Prefeitura (site de turismo de Curitiba) ou por telefone. Em especial: elevador do MON, piso do Passeio Público, acesso do MUPA, mirante do Tanguá.
2. **Medir as distâncias** entre as paradas e fechar a ordem.
3. **Decidir o tema.** Criar `accessible` exige o valor novo em `ITINERARY_THEMES` (backend), em `ItineraryTheme` e `ItineraryThemeFilter` (app) e a chave `categoryFilter.accessible` em pt-BR e en. Sem isso, usar os temas que já existem.
4. **Ópera de Arame** só entra se for cadastrada antes (`data/lugares.json` ou o fluxo de sugestão de lugar).
5. **Cuidado com check-in:** MON e MAC Paraná compartilham a mesma coordenada, então só o MON entra.
6. Passar os textos por tradução en antes de ir para o app.

## Fontes (resumos de busca; páginas oficiais bloquearam leitura automática)

- Prefeitura de Curitiba, [guia de acessibilidade dos atrativos](https://www.curitiba.pr.gov.br/noticias/curitiba-lanca-guia-de-acessibilidade-de-atrativos-turisticos/66458)
- Prefeitura de Curitiba, [e-book com 5 novos locais](https://www.curitiba.pr.gov.br/noticias/curitiba-amplia-a-experiencia-turistica-e-o-e-book-de-acessibilidade-destaca-5-novos-locais/71902)
- Prefeitura de Curitiba, [melhorias no Jardim Botânico](https://www.curitiba.pr.gov.br/noticias/queridinho-dos-turistas-melhorias-deixam-mais-acessivel-o-jardim-botanico-de-curitiba/69125)
- Prefeitura de Curitiba, [miniaturas para cegos](https://www.curitiba.pr.gov.br/noticias/miniaturas-de-atrativos-turisticos-para-cegos-e-pessoas-com-baixa-visao-agrada-o-publico/69279)
- Prefeitura de Curitiba, [parquinho inclusivo no Barigui](https://www.curitiba.pr.gov.br/noticias/barigui-fica-mais-acessivel-com-novo-parquinho-inclusivo-para-criancas/61163)
- Prefeitura de Curitiba, [playground adaptado no Passeio Público](https://www.curitiba.pr.gov.br/noticias/passeio-publico-recebe-primeiro-parque-de-curitiba-adaptado-para-criancas-com-deficiencia/37655)
- Prefeitura de Curitiba, [Bosque Alemão mais acessível](https://www.curitiba.pr.gov.br/noticias/bosque-alemao-fica-mais-acessivel-apos-obras-da-prefeitura-de-curitiba-casa-encantada-e-reaberta-ao-publico/73440)
- Prefeitura de Curitiba, [banheiros do Parque Tanguá](https://www.curitiba.pr.gov.br/noticias/banheiros-publicos-do-parque-tangua-ficam-mais-acessiveis-e-modernos/85346)
- Prefeitura de Curitiba, [página do Parque Tingui](https://www.curitiba.pr.gov.br/conteudo/parque-tingui/321)
