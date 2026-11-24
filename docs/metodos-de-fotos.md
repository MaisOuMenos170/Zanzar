# Fotos dos lugares: métodos testados numa amostra

Teste feito em 2026-11-03. Complementa [pesquisa-fotos.md](pesquisa-fotos.md), que é a varredura dos 38 lugares por Commons e contato com os donos.

Premissas que você respondeu: entram de 5 a 20 lugares por mês. Dá para gastar de 2 a 8 h por mês. Foto própria só de vez em quando, sem rotina. Conteúdo que a Apple exibe sem a gente guardar vale como complemento.

## Resumo

- **Nenhuma fonte aberta resolve bar, restaurante ou café pequeno.** Commons, Wikidata, Wikipedia, OSM, Flickr CC, Openverse, Panoramax e bancos de imagem deram 0 de 6 na amostra.
- **O que funcionou:**
  1. **Cartão do lugar da Apple** (`mapItemDetailSheet`). Mostrou fotos boas em 4 de 6 lugares, é automático e não custa nada. Mas a foto fica dentro do cartão da Apple. Não vira capa e não é guardada.
  2. **Mapillary, só para prédio, rua e fachada com letreiro.** Para esses tipos ele foi mal avaliado antes: 2 de 2 na amostra. Revisei as 19 fotos já guardadas e 6 mostram o lugar de fato.
- **Para ter capa guardada de estabelecimento, continua sendo preciso a autorização do dono ou foto própria.** Não testei isso porque exige contatar gente, o que você vetou. Os contatos estão em `pesquisa-fotos.md`.

## Amostra

| Tipo | Lugar | Por quê |
|---|---|---|
| Parque público | Bosque Gutierrez | Equipamento municipal |
| Museu | MAI, Museu de Arte Indígena | Museu privado e pequeno |
| Bar pequeno | Bar do Alemão | Largo da Ordem |
| Restaurante de rede | Costelão Água Verde | Tem unidade irmã (Brasília) |
| Prédio | Edifício El Cashbah | Curiosidade arquitetônica |
| Rua | Rua Deputado Chafic Curi | Não tem dono |

## Cobertura medida (foto legal que mostra o próprio lugar)

| Método | Gutierrez | MAI | Alemão | Costelão | Cashbah | Chafic | Total | Esforço |
|---|---|---|---|---|---|---|---|---|
| Commons, categoria e busca (sem repetir a varredura antiga) | não | não | não | não | não | não | **0/6** | min |
| Wikidata P18 e imagem da Wikipedia pt | não | não | não | não | não | não | **0/6** | min |
| Tags do OSM (`image`, `wikimedia_commons`, `panoramax`), 80 m | não | não | não | não | não | não | **0/6** | min |
| Flickr com filtro CC BY / BY-SA / CC0 / PDM | não | não | não | não | não | não | **0/6** | min |
| Openverse (voltou a responder, mas lento e com limite) | erro | não | não | erro | não | não | **0/4 lidos** | alto (timeouts) |
| Panoramax, caixa de ±65 m | não | não | não | não | não | não | **0/6** | min |
| Unsplash / Pexels | não | — | — | — | — | — | **0** | min |
| Apple Look Around | não | não | não | não | não | não | **0/6** | min |
| **Mapillary** (fotos já guardadas) | fraca | — | — | **sim** | **sim** | **sim** | **3/6** | já feito |
| **Cartão do lugar da Apple** (sem guardar) | **sim** | **sim** | **sim** | **sim** | ruim | sem cartão | **4/6** | quase zero |
| Fotos oficiais (Prefeitura / AEN-PR) | ? | — | — | — | — | — | licença não achada | — |

### Verificado (abri a fonte ou a imagem)

- **Look Around:** `MKLookAroundSceneRequest` não devolveu cena em nenhuma das 6 coordenadas, nem pelo `MKMapItem`. Hoje não há Look Around nesses pontos de Curitiba.
- **Cartão da Apple** (abri cada um em maps.apple.com):
  - [Bosque Gutierrez](https://maps.apple.com/place?place-id=I1E1ACF6A2A6B7E0C): mata e cascata. Fotos do Foursquare.
  - [MAI](https://maps.apple.com/place?place-id=I6A30AAC1225686EA): interior do museu (Foursquare) e **fachada com o letreiro MAI** (Tripadvisor).
  - [Bar do Alemão](https://maps.apple.com/place?place-id=I23C23D0B6DC6153F): prato e chope. Foursquare.
  - [Costelão](https://maps.apple.com/place?place-id=ID12B477AB511127E): costela e mesa. Foursquare. **A Apple chama o lugar de "Costelão Havana"**, no mesmo endereço (R. Silveira Neto, 144).
  - [El Cashbah](https://maps.apple.com/place?place-id=IFCF579CF64168DA1): a foto é **um gato**. É o risco do método: a Apple não deixa escolher a foto.
  - Rua Chafic Curi: a Apple não tem cartão de lugar para ela (é só rua).
- **Mapillary:** abri as 31 fotos guardadas em `ZanzarBackend/data/photos/` (19 lugares). Classificação:
  - **Mostram o lugar:** Bek's Bar (letreiro legível), Costelão Água Verde (letreiro), Edifício El Cashbah (o "castelo" inteiro), Lanches Missal Shawarma (letreiro), Taisho Sushi (letreiro), Rua Chafic Curi (é a rua).
  - **Incertas:** Museu do Automóvel (prédio amarelo, sem placa legível), Sforno (placa vermelha ilegível), James Bar (fachada sem letreiro legível), Café Flor de Laranjeira (casa sem placa visível).
  - **Não mostram o lugar:** Al Beek, Bosque Gutierrez (só a borda da mata), Burek Grill (fachada pequena ao fundo), Costelão Brasília (pelo para-brisa), Memorial Paranista, Olga Speakeasy, Restaurante Gato Preto (caçamba na frente), Schnaps Bar, Semente de Girassol.
  - Crédito e licença guardados no manifesto: autor `projevias` ou `marciosampaio` (Mapillary), CC BY-SA 4.0, link da foto. As fotos são de 2019 e 2020, então a fachada pode ter mudado.
- **Flickr:** sem filtro, "Bosque Gutierrez" tem 610 fotos (quase tudo de "The Cities", todos os direitos reservados). Com filtro de licença livre, nada do lugar. As outras 5 buscas deram zero.
- **Openverse:** MAI trouxe 22 fotos de uma cerimônia da ALEP. Cashbah trouxe a Casbah de Argel. Chafic Curi trouxe uma visita escolar da ALEP. Bar do Alemão e Memorial Chico Mendes: 0. Bosque Gutierrez e Costelão estouraram o tempo três vezes.
- **Wikidata:** o Bosque Gutierrez é [Q9662015](https://www.wikidata.org/wiki/Q9662015), sem imagem (P18) e sem categoria na Commons.

### Inferido

- O cartão da Apple é legal de exibir: é a própria Apple mostrando conteúdo que ela licencia, numa tela que o app não pode alterar (a documentação diz que a hierarquia de views é privada). O app só guarda o ID do lugar. Disponível desde o iOS 18; o alvo é iOS 26.
- O cartão funciona para lugares novos sem trabalho manual, porque quase todo estabelecimento aparece na Apple. Resolvi o ID de **53 dos 68** lugares (abaixo).
- O Mapillary desfoca rostos e placas automaticamente, o que reduz o risco de LGPD.

### Não consegui verificar

- **Licença das fotos da Prefeitura de Curitiba e da AEN-PR.** Não achei termo de uso nem Creative Commons nos sites. As matérias creditam como "Foto: Fulano/SMCS" ou "/AEN", mas isso não autoriza reuso.
- **Openverse para Bosque Gutierrez e Costelão** (timeout).
- **Termos atuais do Mapillary para uso comercial** (a seção 12, que já estava pendente).
- **Se o Costelão Água Verde virou "Costelão Havana".** A foto do Mapillary de 2019 mostra "Costelão Água Verde" no letreiro.
- **Portal do dono e foto própria:** o mecanismo não pode ser testado sem contatar ninguém.

## O que foi aplicado

- **`ZanzarBackend/data/apple-place-ids.json`** (novo, não commitado): ID da Apple para cada `place_id`, com o nome que a Apple usa, a distância e o status. São 53 `ok` e 15 `revisar`:
  - **Sem resultado:** Museu Egípcio, Sforno, Arcádia, Portal do Bosque Alemão, Meguro Café, Museu da Vida, Mural Poty.
  - **Resultado errado:** o Jardim Botânico casou com o Mercado Municipal; o MUPA casou com algo fora do Brasil.
  - **Sem cartão de lugar:** Chafic Curi, Bacacheri, Gambei, James Bar, R. Mateus Leme 1224, R. São Francisco 171.
  - Para os que estão em `revisar`, a correção é manual: buscar no Apple Maps e copiar o `place-id` da URL.
- **Nada foi mudado no app, no banco nem no manifesto de fotos.**

## Recomendação

| Ordem | O quê | Custo | Risco legal | Cobre |
|---|---|---|---|---|
| 1 | **Capa de fallback** (degradê por categoria + símbolo + nome). Já estava recomendada | 0 | nenhum | 100% sem foto, hoje |
| 2 | **Botão "Fotos e avaliações" que abre o cartão da Apple** com o `applePlaceId`. No cadastro de um lugar novo, resolver o ID automaticamente (MKLocalSearch por nome + coordenada, aceitando até ~300 m e o nome parecido) | horas de código, 0 por mês | baixo (conteúdo da Apple, sem guardar) | ~78% hoje e quase todo lugar novo |
| 3 | **Mapillary só para prédio, rua, monumento e fachada com letreiro**, com humano aprovando. Tirar ou rebaixar as 9 fotos que não mostram o lugar | 1–2 h por mês | baixo (CC BY-SA, crédito já suportado) | ~1/3 dos lugares sem foto |
| 4 | **Pedido de autorização ao dono**, com o formulário que registra o aceite. É a única fonte de capa boa para bar e restaurante. Você envia: eu não contato ninguém | 2–4 h por mês | baixo com aceite guardado | depende de resposta |
| 5 | **Foto própria oportunista**: uma lista de pendentes agrupada por bairro, para quando alguém passar por lá | tempo livre | baixo | rabo longo |
| 6 | Fotos de check-in, só com moderação e termos | médio | alto sem preparo | depois |

Para a sua carga (5 a 20 lugares por mês, 2 a 8 h), os itens 1 e 2 tiram o problema visível de quase todos os lugares sem trabalho recorrente. O 3 e o 4 cabem nas horas do mês e são os únicos que dão capa guardada.

**Risco do item 2:** a Apple escolhe a foto, e pode ser um gato (caso do El Cashbah). Por isso é complemento, não capa.

## Fontes

- [MKMapItemDetailViewController](https://developer.apple.com/documentation/mapkit/mkmapitemdetailviewcontroller) e [mapItemDetailSheet(item:displaysMap:)](https://developer.apple.com/documentation/swiftui/view/mapitemdetailsheet(item:displaysmap:))
- [Prefeitura: regras para fotógrafos em parques](https://www.curitiba.pr.gov.br/noticias/prefeitura-recebe-profissionais-que-fotografam-atletas-nos-parques-de-curitiba-para-definir-regras/74359)
- [Galeria de imagens da AEN-PR](https://www.parana.pr.gov.br/Galeria-de-Imagens/MIS-Ainda-Estou-Aqui-Como-o-MIS-PR-contribui-para-o-resgate-da-memoria-e) (exemplo de crédito, sem licença declarada)
- [Câmara dos Deputados: uso de fotos](https://www2.camara.leg.br/comunicacao/assessoria-de-imprensa/guia-para-jornalistas/noticias-e-fotografias) (outra instituição, só como comparação)
