# Acessibilidade dos 80 lugares do catálogo

Auditoria de **25/11/2026** (`ZanzarBackend/data/lugares.json`). Resultado: **10 lugares com recursos confirmados** (aparecem no app com o símbolo de acessibilidade), **10 citados mas sem detalhe** e **60 sem informação**.

## Como ler

| Selo | Significa | No app |
|---|---|---|
| 🟢 | Uma fonte (site do lugar ou notícia da Prefeitura) afirma que o recurso existe | Mostra a seção "Acessibilidade" no detalhe, com a fonte e a data |
| 🟡 | O lugar é citado em guia ou notícia de acessibilidade, mas não achei **o que** ele tem | Não mostra |
| ⚪ | Nenhuma informação encontrada | Não mostra |

**Regra:** lugar sem seção significa "ainda não verificado", **nunca** "não acessível". Eu não marco um lugar como inacessível sem evidência, e uma busca sem resultado não é evidência.

## Limites da auditoria

- Páginas da Prefeitura (curitiba.pr.gov.br) recusaram a leitura automática (403). Os dados 🟢 vêm de **resumos de busca de notícias oficiais**, não de visita nem do guia completo. O **Museu Oscar Niemeyer** é a exceção: li a página de acessibilidade do próprio museu.
- Nenhum item foi conferido no local.
- Restaurantes, bares e cafés (cerca de 40 dos 80) não têm fonte pública que eu tenha achado. Uma fonte estruturada para eles seria o Google Places (`accessibilityOptions`, precisa da chave e tem custo) ou o OpenStreetMap (tag `wheelchair`). O OpenStreetMap não foi consultado: o terminal sem internet e o navegador embutido não conseguiram abrir o serviço.
- Dado de acessibilidade muda. Cada entrada tem a data da conferência e deve ser revista.

## Como atualizar

1. Achar a fonte e confirmar o recurso.
2. Editar `ZanzarBackend/data/place-accessibility.json` (`features`, `source`, `checkedAt`).
3. `npm run seed` (ou `npm run sync:lugares`) grava no banco. O app passa a mostrar sem nova versão.

## Os 80 lugares

| | Lugar | Tipo | Detalhe |
|---|---|---|---|
| 🟢 | Bosque Alemão | parque | caminhos acessíveis — [Prefeitura de Curitiba, Bosque Alemão mais acessível](https://www.curitiba.pr.gov.br/noticias/bosque-alemao-fica-mais-acessivel-apos-obras-da-prefeitura-de-curitiba-casa-encantada-e-reaberta-ao-publico/73440) |
| 🟢 | Jardim Botânico de Curitiba | parque | rampa, banheiro adaptado, caminhos acessíveis — [Prefeitura de Curitiba, melhorias no Jardim Botânico](https://www.curitiba.pr.gov.br/noticias/queridinho-dos-turistas-melhorias-deixam-mais-acessivel-o-jardim-botanico-de-curitiba/69125) |
| 🟢 | Memorial Paranista | museu | rampa, braille — [Prefeitura de Curitiba, capacitação para atender pessoas com deficiência](https://www.curitiba.pr.gov.br/noticias/capacitacao-ajuda-a-melhorar-inclusao-de-pessoas-com-deficiencia/64726) |
| 🟢 | Museu Oscar Niemeyer (MON) | museu | elevador, banheiro adaptado, vagas reservadas, empréstimo de cadeira de rodas, piso tátil, braille, audiodescrição, sala sensorial, cães-guia — [Museu Oscar Niemeyer, página de acessibilidade](https://www.museuoscarniemeyer.org.br/en-us/faq/acessibilidade) |
| 🟢 | Parque Barigui | parque | parquinho inclusivo, rampa — [Prefeitura de Curitiba, parquinho inclusivo no Barigui](https://www.curitiba.pr.gov.br/noticias/barigui-fica-mais-acessivel-com-novo-parquinho-inclusivo-para-criancas/61163) |
| 🟢 | Parque Barigui | parque | parquinho inclusivo, rampa — [Prefeitura de Curitiba, parquinho inclusivo no Barigui](https://www.curitiba.pr.gov.br/noticias/barigui-fica-mais-acessivel-com-novo-parquinho-inclusivo-para-criancas/61163) |
| 🟢 | Parque São Lourenço | parque | parquinho inclusivo — [Prefeitura de Curitiba, Lazer para Todos](https://www.curitiba.pr.gov.br/noticias/lazer-para-todos-reforca-a-inclusao-de-pessoas-com-deficiencia-em-curitiba/65662) |
| 🟢 | Parque Tanguá | parque | banheiro adaptado — [Prefeitura de Curitiba, banheiros do Parque Tanguá](https://www.curitiba.pr.gov.br/noticias/banheiros-publicos-do-parque-tangua-ficam-mais-acessiveis-e-modernos/85346) |
| 🟢 | Passeio Público | parque | parquinho inclusivo — [Prefeitura de Curitiba, playground adaptado no Passeio Público](https://www.curitiba.pr.gov.br/noticias/passeio-publico-recebe-primeiro-parque-de-curitiba-adaptado-para-criancas-com-deficiencia/37655) |
| 🟢 | Represa do Passaúna | parque | rampa — [Prefeitura de Curitiba, obras no Parque Passaúna](https://www.curitiba.pr.gov.br/noticias/obras-no-parque-passauna-melhoram-a-acessibilidade-e-aumentam-a-seguranca/82933) |
| 🟡 | Cine Passeio | café | No guia da Prefeitura (primeira versão). Detalhe não confirmado. |
| 🟡 | MAI - Museu de Arte Indígena | museu | No guia da Prefeitura. Um site de terceiros diz "acessível para cadeira de rodas"; não é fonte oficial. |
| 🟡 | Memorial de Curitiba | museu | A Prefeitura fechou o memorial para obras de acessibilidade e reabriu "mais acessível". Não achei a lista do que foi feito. |
| 🟡 | Museu da Imagem e do Som (MIS) | museu | Teve exposição com audiodescrição. Acesso físico não confirmado. |
| 🟡 | Museu de História Natural Capão da Imbuia | museu | Passeio sensorial com audiodescrição numa edição anterior; equipe capacitada. Acesso físico não confirmado. |
| 🟡 | Museu do Holocausto | museu | Tem Departamento de Acessibilidade com intérprete de Libras (documento do museu). Acesso físico não confirmado. |
| 🟡 | Museu Paranaense (MUPA) | museu | No guia da Prefeitura. O prédio passou por reforma estrutural, mas não achei o que mudou em acesso. |
| 🟡 | Parque General Iberê de Matos (Parque Bacacheri) | parque | Parquinho novo feito "com atenção à acessibilidade" e pista em terreno plano. Detalhe não confirmado. |
| 🟡 | Parque Tingui | parque | No e-book de acessibilidade da Prefeitura (edição mais recente), junto do Memorial Ucraniano. Detalhe não confirmado. |
| 🟡 | Sesc Paço da Liberdade | histórico | No guia de acessibilidade da Prefeitura (primeira versão). Detalhe não confirmado. |
| ⚪ | Al Beek | restaurante | Sem informação. Entra no app só depois de uma fonte confirmar. |
| ⚪ | Arcádia - Sebo & Café - Vinis, Livros, Dvds, Cds | café | Sem informação. Entra no app só depois de uma fonte confirmar. |
| ⚪ | Bar do Alemão | bar | Sem informação. Entra no app só depois de uma fonte confirmar. |
| ⚪ | Bek's Bar | bar | Sem informação. Entra no app só depois de uma fonte confirmar. |
| ⚪ | Bosque de Portugal | parque | Sem informação. Entra no app só depois de uma fonte confirmar. |
| ⚪ | Bosque Gutierrez | parque | Sem informação. Entra no app só depois de uma fonte confirmar. |
| ⚪ | Bosque Papa João Paulo II | parque | Sem informação. Entra no app só depois de uma fonte confirmar. |
| ⚪ | Bosque Zaninelli I UNILIVRE | parque | Sem informação. Entra no app só depois de uma fonte confirmar. |
| ⚪ | Burek Grill | restaurante | Sem informação. Entra no app só depois de uma fonte confirmar. |
| ⚪ | Café Flor de Laranjeira | café | Sem informação. Entra no app só depois de uma fonte confirmar. |
| ⚪ | Cantina e Pizzaria Baviera | restaurante | Sem informação. Entra no app só depois de uma fonte confirmar. |
| ⚪ | Casa das Galinhas | curiosidade | Sem informação. Entra no app só depois de uma fonte confirmar. |
| ⚪ | Casa das Massas Cicinielli | restaurante | Sem informação. Entra no app só depois de uma fonte confirmar. |
| ⚪ | Cavalo Babão | histórico | Sem informação. Entra no app só depois de uma fonte confirmar. |
| ⚪ | Cidadão do Mundo Burgers & Arts - Unidade São Braz | restaurante | Sem informação. Entra no app só depois de uma fonte confirmar. |
| ⚪ | Costelão 24h | restaurante | Sem informação. Entra no app só depois de uma fonte confirmar. |
| ⚪ | Costelão Brasília | restaurante | Sem informação. Entra no app só depois de uma fonte confirmar. |
| ⚪ | Curitiba Sunset | bar | Sem informação. Entra no app só depois de uma fonte confirmar. |
| ⚪ | Dom Giovanni | restaurante | Sem informação. Entra no app só depois de uma fonte confirmar. |
| ⚪ | Expedito Massas - Unidade Seminário | restaurante | Sem informação. Entra no app só depois de uma fonte confirmar. |
| ⚪ | Gambei Curitiba | restaurante | Sem informação. Entra no app só depois de uma fonte confirmar. |
| ⚪ | Hot Dogueria Donas Do Sabor Mercês | restaurante | Sem informação. Entra no app só depois de uma fonte confirmar. |
| ⚪ | Italy Caffé Juvevê | restaurante | Sem informação. Entra no app só depois de uma fonte confirmar. |
| ⚪ | James Bar e Garden | Festa | Sem informação. Entra no app só depois de uma fonte confirmar. |
| ⚪ | Jokers | bar | Sem informação. Entra no app só depois de uma fonte confirmar. |
| ⚪ | Lanches Missal Shawarma | restaurante | Sem informação. Entra no app só depois de uma fonte confirmar. |
| ⚪ | MAC - Museu de Arte Contemporânea do Paraná | museu | Sem informação. Entra no app só depois de uma fonte confirmar. |
| ⚪ | Matias Bar | bar | Sem informação. Entra no app só depois de uma fonte confirmar. |
| ⚪ | Meguro Café メグロカフェ | café | Sem informação. Entra no app só depois de uma fonte confirmar. |
| ⚪ | Mirante Praça Barcelona | ponto turístico | Sem informação. Entra no app só depois de uma fonte confirmar. |
| ⚪ | Mural Poty Lazzarotto: Imagens da Cidade | ponto turístico | Sem informação. Entra no app só depois de uma fonte confirmar. |
| ⚪ | Museu da Fotografia Cidade de Curitiba | museu | Sem informação. Entra no app só depois de uma fonte confirmar. |
| ⚪ | Museu da Vida da Pastoral da Criança | museu | Sem informação. Entra no app só depois de uma fonte confirmar. |
| ⚪ | Museu do Automóvel de Curitiba | museu | Sem informação. Entra no app só depois de uma fonte confirmar. |
| ⚪ | Museu Egípcio e Rosacruz - Tutankhamon | museu | Sem informação. Entra no app só depois de uma fonte confirmar. |
| ⚪ | Museu Ferroviário | museu | Sem informação. Entra no app só depois de uma fonte confirmar. |
| ⚪ | Museu Planeta Água | museu | Sem informação. Entra no app só depois de uma fonte confirmar. |
| ⚪ | Olga Speakeasy | bar | Sem informação. Entra no app só depois de uma fonte confirmar. |
| ⚪ | Pedrão Bar | — | Sem informação. Entra no app só depois de uma fonte confirmar. |
| ⚪ | Portal do Bosque Alemão | ponto turístico | Sem informação. Entra no app só depois de uma fonte confirmar. |
| ⚪ | Praça do Japão | parque | Sem informação. Entra no app só depois de uma fonte confirmar. |
| ⚪ | Prédio feio | curiosidade | Sem informação. Entra no app só depois de uma fonte confirmar. |
| ⚪ | Queroquero Comida e Bar | bar | Sem informação. Entra no app só depois de uma fonte confirmar. |
| ⚪ | Restaurante Fedatto | restaurante | Sem informação. Entra no app só depois de uma fonte confirmar. |
| ⚪ | Restaurante Gato Preto | restaurante | Sem informação. Entra no app só depois de uma fonte confirmar. |
| ⚪ | Restaurante Munhoz da Rocha | restaurante | Sem informação. Entra no app só depois de uma fonte confirmar. |
| ⚪ | Restaurante Tio Mauro | restaurante | Sem informação. Entra no app só depois de uma fonte confirmar. |
| ⚪ | Royalty Café | café | Sem informação. Entra no app só depois de uma fonte confirmar. |
| ⚪ | Rua Ajeitada (R. Chafic Curi) | curiosidade | Sem informação. Entra no app só depois de uma fonte confirmar. |
| ⚪ | Ruínas de São Francisco | histórico | Sem informação. Entra no app só depois de uma fonte confirmar. |
| ⚪ | Schnaps Bar | bar | Sem informação. Entra no app só depois de uma fonte confirmar. |
| ⚪ | Semente de Girassol | restaurante | Sem informação. Entra no app só depois de uma fonte confirmar. |
| ⚪ | Sforno Trattoria e Pizzaria (Caranguejo em Curitiba) | restaurante | Sem informação. Entra no app só depois de uma fonte confirmar. |
| ⚪ | Spaghetto | restaurante | Sem informação. Entra no app só depois de uma fonte confirmar. |
| ⚪ | Taisho Sushi | restaurante | Sem informação. Entra no app só depois de uma fonte confirmar. |
| ⚪ | Trattoria Dallarmi Pizza & Gastronomia | restaurante | Sem informação. Entra no app só depois de uma fonte confirmar. |
| ⚪ | Universidade Tecnológica Federal do Paraná (Campus Curitiba - Sede Centro) | histórico | Sem informação. Entra no app só depois de uma fonte confirmar. |
| ⚪ | Verdant | festa | Sem informação. Entra no app só depois de uma fonte confirmar. |
| ⚪ | É Dino Cultural | bar | Sem informação. Entra no app só depois de uma fonte confirmar. |
| ⚪ | Último estacionamento de cavalo de Curitiba | curiosidade | Sem informação. Entra no app só depois de uma fonte confirmar. |
