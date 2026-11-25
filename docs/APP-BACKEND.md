# Como o app e o backend se relacionam

Dois repositórios git independentes, lado a lado em `~/`:

- `Zanzar/` é o app iOS (SwiftUI). Branch de trabalho atual: `fix/photos-and-strings`.
- `ZanzarBackend/` é a API (Express + MongoDB Atlas). Branch de trabalho: `develop`.

O app é o único cliente. O backend não serve telas, só JSON (e um proxy de foto do Google Places).

## Conexão

- URL base: `ZANZAR_API_BASE_URL` em `Zanzar/ZanzarProject/Config.xcconfig` (Debug vazio = `http://127.0.0.1:3000`). Release usa `Config.Release.xcconfig`.
- Simulador acessa o backend em `127.0.0.1`. Aparelho físico precisa do túnel: `ZanzarBackend/scripts/dev/dev-tunnel.sh` chama `Zanzar/scripts/update-api-tunnel-url.sh`.
- Auth: `POST /login` e `/register` devolvem access token e refresh token. O app guarda no Keychain e manda `Authorization: Bearer`. Em 401 chama `POST /refresh` e repete a requisição. `POST /logout` invalida a sessão via `tokenVersion`.

## Endpoints usados pelo app

| App (arquivo) | Chamada | Backend |
|---|---|---|
| `SignUpService` | `POST /register` | `auth.routes` |
| `LoginService` | `POST /login` | `auth.routes` |
| `PasswordResetService` | `POST /password/forgot`, `POST /password/verify` (`{email, code}`), `POST /password/reset` | `auth.routes` (ver abaixo) |
| `SessionRefresher` | `POST /refresh` | só em `origin/develop` (ver abaixo) |
| `ProfileService` | `POST /logout`, `GET /user/:id/profile` (`limit` de 1 a 20), `GET /user/:id/check-ins` (`limit` de 1 a 50, cursor `before`/`nextCursor`), `PATCH /user/:id` (troca o `username`: 3 a 30, letras/números/`_`, 409 se em uso), `DELETE /user/:id` | `auth`, `users` |
| `LocationMapService` | `GET /places` | `place.routes` |
| `PlaceSearchService` | `GET /places/search?q=&lat=&lng=&categories=&limit=` (busca por nome, apelido ou endereço em todos os lugares, mais perto primeiro; `q` de 2 a 80 caracteres, `categories` separadas por vírgula, `limit` padrão 20) | `place.routes` (só em `feat/place-search` até o merge) |
| `PlaceDetailService` | `GET /places/:id`, `POST` e `GET /checkIn`, `GET /rating`, `GET /places/:id/photos` | `place`, `checkin`, `rating`, `user-photo-community` |
| `RatingPromptService` | `GET` e `POST /rating` | `rating.routes` |
| `UserPhotosService` | `POST /places/:id/photos` (corpo = JPEG; `?fromCheckIn=&showAuthorName=`), `DELETE /places/:id/photos/:photoId`, `POST /places/:id/photos/:photoId/reports`, `GET` e `POST /user/:id/photo-terms`, `GET /user/:id/photos`, `GET`, `POST` e `DELETE /user/:id/blocks` | `user-photos` (ver `docs/fotos-de-usuario-decisao.md`) |
| `ItineraryService` | `GET /itineraries`, `GET /itineraries/:slug`, `POST /itineraries/:slug/activate`, `POST /itineraries/active/abandon`, `GET /user/:id/itinerary` | `itinerary.routes`, `user.routes` |
| `PlaceSuggestionService` | `POST /place-suggestions` (`{name, coordinates, address, note?}`; responde com o veredito: `approved`, `rejected` ou `needs_review`), `GET /place-suggestions`. A busca é do Apple Maps (MapKit) no app; `GET /place-suggestions/search` e o formato `{osmType, osmId, note?}` não são usados | `place-suggestions` (ver abaixo) |

Sem uso no app hoje: `GET /user/:id`, `GET /stamps/:stampId`, `GET /places/photo` (proxy do Google, aposentado), `GET /health` (só o Railway). A collection `sync_mutations` e `modules/sync` não têm rota. A revisão de fotos (`/admin`, `/admin/api/photos`) é usada só pela página da equipe, não pelo app.

Erros das rotas de foto trazem `code` (ex.: `duplicate_photo`, `terms_required`), que o app lê como `APIError.rejected`.

## Recuperação de senha

`POST /password/forgot` responde 202 sempre e manda um e-mail com um código de 6 dígitos (vale 15 min, 5 tentativas). Não há link nem deep link: a pessoa lê o código no e-mail e digita ou cola no app. O app troca o código (`{email, code}`) por um `resetToken` em `POST /password/verify` e envia a nova senha em `POST /password/reset` (204, o backend revoga todas as sessões). A sequência de telas é e-mail, código (6 caixas), "código verificado", nova senha, sucesso, login. As três rotas estão em `publicPaths` do `URLSessionNetworkClient`: vão sem Bearer e um 401 não vira "sessão expirada".

## Sugestão de lugar e moderação

O usuário busca o lugar por nome ou endereço no Apple Maps (MapKit, limitado a Curitiba e região, no próprio app) e escolhe um resultado. O que o resultado não tem é pedido na hora: endereço sem nome (por exemplo "Jardim Botânico", que o Apple devolve como endereço) pede o nome; lugar com nome e sem endereço, ou busca sem resultado, pede o endereço (e o nome, na busca sem resultado), que o app resolve no Apple Maps para obter as coordenadas. Toda sugestão sai com coordenadas e vai como `{name, coordinates, address, note?}`. A descrição (`note`) é opcional.

O Apple só indica qual lugar o usuário quer. O backend confere a área (fora de Curitiba e região: recusa na hora), procura o lugar no OpenStreetMap pelo nome, num raio de 500 m da coordenada, e roda as camadas de moderação (`area`, `type`, `duplicate`, `context`) sobre o que o OSM devolveu. Tudo certo: o lugar entra no app sozinho (`approved`, `place_id` `osm:<tipo>/<id>`, com nome, endereço e coordenadas do OSM, não os do Apple). Recusa clara (`duplicate`, `outside_area`, `type_not_accepted`) é `rejected`. Qualquer dúvida cai em `needs_review` e é decidida por uma pessoa na aba "Lugares sugeridos" do `/admin`: o OSM não achou o lugar (`not_confirmed`), o OSM não respondeu (`layer_unavailable`), conta com menos de 7 dias ou autor com 2 sugestões recusadas (`low_trust`), lugar parecido por perto (`possible_duplicate`). O formato antigo `{coordinates, address, note?}` (versões antigas do app, ou nome em branco) continua aceito e sempre vai para revisão.

O app mostra o veredito na hora (alerta ou toast: adicionado, não aprovado ou em análise), em Perfil > Minhas sugestões, e avisa quando uma revisão termina (mesmo mecanismo das fotos, sem push). `decisionReason` chega como código (`duplicate`, `outside_area`, `type_not_accepted`, `not_a_real_place`, `inappropriate`, `accepted_manual`) e o app traduz; códigos que só explicam por que algo ficou em análise (`low_trust`, `possible_duplicate`, `manual_entry`, `not_confirmed`, `layer_unavailable`) não são mostrados. Erros trazem `code` (`place_not_found` 404, `osm_unavailable` 503). Limite de 5 sugestões por dia por usuário.
| `PlaceDetailService` | `GET /places/:id`, `POST` e `GET /checkIn`, `GET /rating` | `place`, `checkin`, `rating` |
| `RatingPromptService` | `GET` e `POST /rating` | `rating.routes` |
| `ItineraryService` | `GET /itineraries`, `GET /itineraries/:slug`, `POST /itineraries/:slug/activate`, `POST /itineraries/active/abandon`, `GET /user/:id/itinerary` | `itinerary.routes`, `user.routes` |

Sem uso no app hoje: `GET /user/:id`, `GET /stamps/:stampId`, `GET /places/photo` (proxy do Google, aposentado), `GET /health` (só o Railway). A collection `sync_mutations` e `modules/sync` não têm rota.

## Fonte da verdade do formato

O formato dos dados é definido pelos schemas Zod em `ZanzarBackend/src/schemas/*`. Os DTOs `Decodable` do app (`Features/*/API/*Service.swift`, `LocationMap.swift`) espelham esses schemas à mão. O arquivo `ZanzarBackend/scripts/contracts/swift-clients.json` mapeia qual schema alimenta qual arquivo Swift, e o workflow `schema-contract.yml` comenta no PR do backend quando um schema muda.

Fotos dos lugares: o backend manda `images: [{ url, credit: { author, license, licenseUrl?, sourceUrl } }]` em `GET /places` e `GET /places/:id`, e `imageUrl` (primeira imagem) em cada check-in recente do perfil. O app só aceita URL `https` e mostra o crédito na tela, porque as licenças (CC BY, CC BY-SA) exigem. O campo `photos` (referências do Google) continua no banco, mas o app não o usa mais.

Valores fechados que precisam ficar iguais nos dois lados:

- Categorias: `restaurant, bar, cafe, museum, park, tourist, historic, curiosity, party` (`ZanzarPlaceCategory` no app, `ZANZAR_CATEGORIES` no backend).
- Impression tags: `delighted, happy, nauseated, sad, sleepy` (`ImpressionTag` e `IMPRESSION_TAGS`).
- Ids de selo: `stamp_<categoria>`. O app mapeia para assets locais.
- Raio de check-in: 150 m, fixo no app (`CheckInPolicy`) e configurável no backend (`CHECKIN_RADIUS_METERS`). Se alguém mudar a variável, o app não acompanha.

## Ao mexer num lado

1. Mudou schema, rota ou enum no backend: atualize o DTO correspondente no app e `swift-clients.json`.
2. Mudou DTO no app: confirme que o backend envia o campo (não confie só no teste do app, os testes usam fixtures).
3. Antes de testar fluxo logado no simulador, suba o backend com `npm run dev` e `PORT=3000`.
4. Mantenha as duas branches alinhadas. Em 2026-10-29 o `develop` local do backend estava 2 commits atrás de `origin/develop`, e o `/refresh` que o app usa só existe lá.
