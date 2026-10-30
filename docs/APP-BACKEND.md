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
