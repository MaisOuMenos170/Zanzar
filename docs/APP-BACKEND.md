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
| `SessionRefresher` | `POST /refresh` | só em `origin/develop` (ver abaixo) |
| `ProfileService` | `POST /logout`, `GET /user/:id/profile` | `auth`, `users` |
| `LocationMapService` | `GET /places` | `place.routes` |
| `PlaceSearchService` | `GET /places/search?q=&lat=&lng=&categories=&limit=` (busca por nome, apelido ou endereço em todos os lugares, mais perto primeiro; `q` de 2 a 80 caracteres, `categories` separadas por vírgula, `limit` padrão 20) | `place.routes` (só em `feat/place-search` até o merge) |
| `PlaceDetailService` | `GET /places/:id`, `POST` e `GET /checkIn`, `GET /rating`, `GET /places/:id/photos` | `place`, `checkin`, `rating`, `user-photo-community` |
| `RatingPromptService` | `GET` e `POST /rating` | `rating.routes` |
| `UserPhotosService` | `POST /places/:id/photos` (corpo = JPEG; `?fromCheckIn=&showAuthorName=`), `DELETE /places/:id/photos/:photoId`, `POST /places/:id/photos/:photoId/reports`, `GET` e `POST /user/:id/photo-terms`, `GET /user/:id/photos`, `GET`, `POST` e `DELETE /user/:id/blocks` | `user-photos` (ver `docs/fotos-de-usuario-decisao.md`) |
| `ItineraryService` | `GET /itineraries`, `GET /itineraries/:slug`, `POST /itineraries/:slug/activate`, `POST /itineraries/active/abandon`, `GET /user/:id/itinerary` | `itinerary.routes`, `user.routes` |
| `PlaceSuggestionService` | `GET /place-suggestions/search?q=&lat=&lng=` (busca no OpenStreetMap), `POST /place-suggestions` (`{osmType, osmId, note?}`; o formato antigo `{coordinates, address, note?}` vai sempre para revisão humana), `GET /place-suggestions` | `place-suggestions` (ver abaixo) |

Sem uso no app hoje: `GET /user/:id`, `GET /stamps/:stampId`, `GET /places/photo` (proxy do Google, aposentado), `GET /health` (só o Railway). A collection `sync_mutations` e `modules/sync` não têm rota. A revisão de fotos (`/admin`, `/admin/api/photos`) é usada só pela página da equipe, não pelo app.

Erros das rotas de foto trazem `code` (ex.: `duplicate_photo`, `terms_required`), que o app lê como `APIError.rejected`.

## Sugestão de lugar e moderação

O usuário busca o lugar (o backend consulta o Nominatim, limitado a Curitiba e região, 10 buscas por minuto) e manda só o id do OpenStreetMap. O backend consulta de novo, nunca confia em nome ou coordenada do app, e roda as camadas `area`, `type`, `duplicate` e `context` na hora. Tudo passou: `approved` e o lugar é criado em `places` (`place_id` `osm:<tipo>/<id>`, `source: "community"`, sem fotos). Falha clara (fora da área, tipo não aceito, duplicado): `rejected`. Qualquer dúvida (conta nova com menos de 7 dias, lugar parecido ao lado, erro numa camada) e o que foi digitado à mão: `needs_review`, decidido por uma pessoa na aba "Lugares sugeridos" do `/admin`.

O app mostra o resultado na hora (alerta), em Perfil > Minhas sugestões, e avisa quando uma revisão termina (mesmo mecanismo das fotos, sem push). `decisionReason` chega como código (`duplicate`, `outside_area`, `type_not_accepted`, `not_a_real_place`, `inappropriate`, `accepted_manual`) e o app traduz; códigos que só explicam por que algo ficou em análise (`low_trust`, `possible_duplicate`, `manual_entry`) não são mostrados. Erros trazem `code` (`place_not_found` 404, `osm_unavailable` 503). Limite de 5 sugestões por dia por usuário.
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
