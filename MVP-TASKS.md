# Zanzar — Backlog para fechar 100% do MVP

Backlog derivado do cruzamento entre a seção **`Wireframe MVP`** do Figma
([node 286:2659](https://www.figma.com/design/8hydbYFSjLxZ8DLsNjLRm7/Macro-Challenge?node-id=286-2659&m=dev))
e o código atual dos dois repos: **`Zanzar`** (app iOS/SwiftUI) e **`ZanzarBackend`** (Express + MongoDB).

O Figma tem 30 frames, 3 alerts e um board de assets, organizados num fluxo numerado de 5 passos:
**1 Login · 2 Descobrir · 3 Check in · 4 Perfil · 5 Check-in em local dentro de um roteiro**.

Legenda: ✅ pronto · ⚠️ existe mas incompleto · ❌ não existe

**Última revisão:** 2026-10-07 (auditoria MVP — E5/E6 em `feat/e5-e6-mvp-polish`)  
**Branches analisadas:** `Zanzar` + `ZanzarBackend` → **`feat/e5-e6-mvp-polish`** (PR para `develop` pendente)

---

## 0. Progresso geral

| Métrica | Valor |
| --- | --- |
| Tasks totais | 31 |
| ✅ Concluídas | 29 (E1, E2-01…03, E3, E4, E5, E6-01/02/04/05/06) |
| ⚠️ Parciais | 2 (E2-04 ops Atlas · E6-03 testes integração HTTP/DB) |
| ❌ Pendentes | 0 (escopo de produto MVP) |
| 🔧 Ops / release | E2-04 desativar trigger · merge `feat/e5-e6-mvp-polish` · `GOOGLE_PLACES_API_KEY` + restart backend |

### O que mudou desde a versão inicial do documento

| Repo | Commit / PR | Entrega relevante |
| --- | --- | --- |
| `Zanzar` | [#24](https://github.com/DalPra0/Zanzar/pull/24) profile API integration | Perfil com API real, logout server-side, foto/selo nos cards, navegação para detalhe |
| `Zanzar` | [#23](https://github.com/DalPra0/Zanzar/pull/23) nicknames + seal states | Apelidos de lugar, selos earned/preview no detalhe |
| `Zanzar` | `6f51d6f` | Este documento + asset `carimboRoteiro.svg` (carimbo de roteiro) |
| `ZanzarBackend` | [#16](https://github.com/DalPra0/ZanzarBackend/pull/16) user profile routes | `GET /user/:id/profile`, `POST /logout` |
| `ZanzarBackend` | [#17](https://github.com/DalPra0/ZanzarBackend/pull/17) stamps MVP | `userContext` em places, inferência de categorias, teste de seed |
| `ZanzarBackend` | [#18](https://github.com/MaisOuMenos170/ZanzarBackend/pull/18) itineraries | E1 mergeado: roteiros free/fixed, 5 endpoints, seed |
| `ZanzarBackend` | branch `feat/e2-sync-checkin` (`8ebbfe5`, `e8126e3`) | E2: check-in síncrono, geofence, docs trigger Atlas |
| `Zanzar` | `feat/e3-itinerary` / #26 | E3: aba Check in, roteiros, activate/abandon |
| `Zanzar` | `feat/e4-checkin-alerts` | E4: alerts check-in + `SealEarnedAlertView` |
| `Zanzar` + `ZanzarBackend` | `feat/e5-e6-mvp-polish` | E5: `itinerariesCount`, `impressionTag`, badge no perfil · E6: proxy fotos, senha, Vitest, stubs removidos, suite iOS |

### Caminho crítico (atualizado)

**Telas e fluxos Figma:** ✅ no código local. **Fechar MVP 100%:** (1) ops E2-04 Atlas, (2) merge PR E5/E6, (3) smoke test fotos/perfil/check-in, (4) opcional estrito E6-03 com Mongo em CI.

---

## 1. Estado atual por tela do Figma

| Tela / alert no Figma | Node | Implementação | Status |
| --- | --- | --- | --- |
| `Tela inicial` | 289:2661 | `WelcomeView` | ✅ |
| `Cadastro` + erros inline | 289:2904 / 353:2474 | `SignUpView` + `AuthFormField` + `AuthValidation` | ✅ |
| `Login` + erros inline | 289:2993 / 353:2551 | `LoginView` + `AuthFormField` | ✅ |
| `Maps` (3 variantes) | 290:1838, 880:5973, 880:5834 | `LocationMapView`, 3 estados de pin, clustering | ✅ |
| `Avaliacao` (3 variantes) | 354:3602/3701/3800 | `RatingPromptView`, 5 reações, "Agora não"/"Avaliar" | ✅ |
| `Página de detalhes` base | 292:1924, 871:4088 | `PlaceDetailView` | ✅ |
| `0 check-ins e reações` | 926:3444 | `PlaceDetailReactionsSection` empty state | ✅ |
| `Check-in já feito` | 371:2140 | `PlaceDetailCheckInButton` | ✅ |
| `Perfil` | 290:2306 | `ProfileView` + `ProfileService` (E5) | ✅ `itinerariesCount`, foto via proxy, carinha `impressionTag`, selo |
| Detalhe com **2 selos** (categoria + carimbo) | 871:4388 | `PlaceDetailStatsCard` + `ItineraryStampView` | ✅ |
| Alert `Fazer Check-in` (Cancelar/Confirmar) | 871:5025, 354:4186 | `PlaceDetailView` confirmation alert | ✅ |
| Alert `Eba! Você ganhou um selo!` (Aceitar) | 354:4161 | `SealEarnedAlertView` | ✅ |
| `Check-in vazio` (aba Check in) | 293:3674 | `ItineraryListView` | ✅ |
| `Check-in iniciado` (card `Roteiro atual`) | 348:1852 | `ActiveItineraryProgressCard` | ✅ |
| `Check-in roteiro livre` (sheet) | 331:1552 | `ItineraryDetailView` (free) | ✅ |
| `Check-in roteiro pronto` (sheet) | 332:1878 | `ItineraryDetailView` (fixed) | ✅ |
| Estado `Nenhum roteiro selecionado.` | 331:1552 | `ActiveItineraryProgressCard` empty | ✅ |

### Assets (`pins e selos`, node 860:4084)

| Asset | Status |
| --- | --- |
| 9 categorias × 3 estados de pin (habilitado / já feito / no roteiro atual) | ✅ `LocationPin*.colorset` + `LocationPinView` |
| 9 selos de categoria | ✅ `Assets.xcassets/Seals/PlaceCategorySeal*.imageset` |
| 5 carinhas de reação | ✅ `Assets.xcassets/Carinhas/` |
| **Carimbo de roteiro** | ✅ `ItineraryStampView` nas telas de roteiro + `PlaceDetailStatsCard` |

---

## 2. Gaps estruturais

1. ~~**Roteiros não têm API.**~~ **Resolvido (#18):** módulo `src/modules/itineraries/`, `routeType`, activate/abandon, `GET /user/:id/itinerary`, seed dos 2 templates.
2. ~~**O selo ganho não volta na resposta do check-in.**~~ **Resolvido (E2-01):** `POST /checkIn` aplica efeitos em transação e responde `stampIdGranted`, `isNewStamp`, `itineraryProgress`, `isItineraryCompleted`.
3. ~~**Progresso de rota livre no check-in.**~~ **Resolvido (E2-02):** `applyItineraryProgressFromCheckin` no service; rota free casa por `targetCategory`.
4. ~~**Fotos vêm do Google direto do app.**~~ **Resolvido (E6-01):** `GET /places/photo?ref=` no backend; iOS usa `APIConfiguration.baseURL` sem chave no bundle.
5. ~~**`POST /logout` nunca é chamado.**~~ **Resolvido (#24 + E5-04).**
6. **Testes backend (E6-03).** Vitest + Supertest + mocks (`npm test` verde). **Pendente para aceite estrito:** integração HTTP + MongoDB (geofence 422, selo, progresso roteiro E2E). Ver nota em E6-03.
7. ~~**Perfil parcialmente integrado.**~~ **Resolvido (E5-01, E5-03):** `itinerariesCount`, `impressionTag`, badge no `ProfileCheckInCard`.
8. **Trigger Atlas legado (E2-04).** Se ainda ativo, check-in duplica contadores — desativar manualmente (`ZanzarBackend/scripts/triggers/README.md`).

---

## 3. Tasks

Status por task: ✅ concluída · ⚠️ parcial · ❌ pendente

### E1 — Roteiros: backend

#### E1-01 · Adicionar `routeType` ao template de roteiro — ✅
- **Repo:** `ZanzarBackend`
- **Depende de:** —
- **O que fazer:** em `src/models/itinerary.model.ts` e `src/schemas/itinerary.ts`, adicionar `routeType: "free" | "fixed"`, `targetCount: number` (nº de check-ins para rota livre) e `completedCount: number` (default 0). Tornar `placeIds` obrigatório só quando `routeType === "fixed"`. Em `src/models/user.model.ts`, tornar `itineraryPlaceSchema.placeId` opcional e adicionar `routeType` + `targetCategory` ao `itineraryFields` do embed, para slots de rota livre.
- **Aceite:** `npm run typecheck` passa; `npm run db:validate:dry` imprime o `$jsonSchema` novo; um template `fixed` sem `placeIds` é rejeitado e um `free` sem `placeIds` é aceito.
- **Figma:** 331:1552 (tag `Rota Livre`), 332:1878 (`Rota sugerida`)
- **Implementado:** `src/constants/itinerary-route-type.ts`, validação pre-save, embed do user atualizado.

#### E1-02 · `GET /itineraries` — lista de roteiros — ✅
- **Repo:** `ZanzarBackend`
- **Depende de:** E1-01
- **O que fazer:** novo módulo `src/modules/itineraries/` (routes → controller → service → repository), montado em `src/index.ts` atrás de `validateAuthToken`. Retornar só `isPublished: true`, com `slug`, `name`, `category`, `routeType`, `placesCount` (= `placeIds.length` ou `targetCount`), `completedCount` e `coverImageUrl`.
- **Aceite:** os cards da lista `Roteiros` renderizam "4 lugares" e "40 pessoas completaram" sem nenhuma chamada extra.
- **Figma:** 293:3674 (seção `Roteiros`)

#### E1-03 · `GET /itineraries/:slug` — detalhe do roteiro — ✅
- **Repo:** `ZanzarBackend`
- **Depende de:** E1-02
- **O que fazer:** retornar `description`, `objectives` (as tags verdes `Histórico`/`Museu`/`Café`), `routeType`, `targetCategory` e, para `fixed`, os lugares **na ordem de `placeIds`** com `place_id`, `name` e `geometry.location` (para desenhar a rota no mapa).
- **Aceite:** o sheet de rota fixa consegue desenhar o mapa e listar `Rota sugerida` numerada com uma única chamada; rota livre volta `places: []` e `targetCategory` preenchido.
- **Figma:** 332:1878, 331:1552

#### E1-04 · `POST /itineraries/:slug/activate` — ✅
- **Repo:** `ZanzarBackend`
- **Depende de:** E1-01, E1-03
- **O que fazer:** materializar `users.activeItinerary` a partir do template. Para `fixed`, um slot por `placeId` com `isCompleted: false`. Para `free`, `targetCount` slots sem `placeId`, com `targetCategory`. Recusar com 409 se já existir `activeItinerary`.
- **Aceite:** ativar devolve o progresso inicial; ativar de novo com um roteiro ativo retorna 409; `GET /places` passa a marcar `userContext.isInActiveItinerary` nos lugares do roteiro fixo.
- **Figma:** botão `Começar roteiro` (331:1552, 332:1878)

#### E1-05 · `POST /itineraries/active/abandon` — ✅
- **Repo:** `ZanzarBackend`
- **Depende de:** E1-04
- **O que fazer:** mover `activeItinerary` para `inactiveItineraries` e zerar `activeItinerary`.
- **Aceite:** depois de abandonar, `GET /user/:id/itinerary` volta `null` e a aba Check in mostra `Nenhum roteiro selecionado.`
- **Figma:** 331:1552 (texto `Nenhum roteiro selecionado.` e o X do sheet)

#### E1-06 · `GET /user/:id/itinerary` — roteiro ativo + progresso — ✅
- **Repo:** `ZanzarBackend`
- **Depende de:** E1-04
- **O que fazer:** no `userRouter` (já protegido por `requireOwnership`), retornar o `activeItinerary` com cada slot resolvido: `placeId`, `placeName`, `isCompleted`, `stamp`. Retornar `null` (200) quando não houver roteiro ativo.
- **Aceite:** o card `Roteiro atual` renderiza a trilha com os nós concluídos e pendentes sem chamadas extras.
- **Figma:** 348:1852

#### E1-07 · Seed dos 2 templates do Figma — ✅
- **Repo:** `ZanzarBackend`
- **Depende de:** E1-01
- **O que fazer:** em `scripts/seed/seed-zanzardb.js`, fazer upsert idempotente de `visitando-parques` (`free`, categoria `park`, `targetCount: 4`, `completedCount: 40`) e `centro-historico` (`fixed`, 4 `place_id` reais de Curitiba: Ruínas de São Francisco, Cavalo Babão, Memorial de Curitiba, Arcádia - Sebo e Café; `completedCount: 20`). Documentar em `scripts/seed/README.md`.
- **Aceite:** `npm run seed` duas vezes seguidas não duplica nada e `GET /itineraries` devolve exatamente os 2 roteiros com os textos do Figma.
- **Figma:** 293:3674, 331:1552, 332:1878
- **Implementado:** upsert idempotente em `scripts/seed/seed-zanzardb.js`; README atualizado.

---

### E2 — Check-in síncrono e concessão de selo

#### E2-01 · Portar os efeitos do check-in do trigger para a API — ✅
- **Repo:** `ZanzarBackend`
- **Depende de:** E1-01
- **O que fazer:** mover a lógica de `scripts/triggers/on-checkin-created.js` para o service de check-in, dentro de uma transação: `users.checkInCount +1`, push em `users.stamps`, `places.zanzar.checkInCount +1` e progresso do `activeItinerary`. Manter a idempotência atual. Devolver no 201: `stampIdGranted`, `isNewStamp`, `itineraryProgress` e `isItineraryCompleted`.
- **Aceite:** um `POST /checkIn` já responde com o selo concedido; repetir com o mesmo `clientMutationId` não conta em dobro; roteiro 100% concluído migra para `completedItineraries` e zera `activeItinerary`.
- **Figma:** 354:4161 (alert do selo)
- **Implementado:** `checkin.service.ts` + transação; `checkinResponseSchema`; idempotência via `sync_mutations`.

#### E2-02 · Progresso de rota livre por categoria — ✅
- **Repo:** `ZanzarBackend`
- **Depende de:** E2-01, E1-04
- **O que fazer:** no match de progresso, quando `activeItinerary.routeType === "free"`, preencher o primeiro slot vazio se `place.zanzar.category === targetCategory`, gravando `placeId`, `datetime` e `stamp`. Rota fixa segue casando por `placeId`.
- **Aceite:** 4 check-ins em parques diferentes completam `Visitando parques`; um check-in em restaurante não altera o progresso.
- **Figma:** 331:1552
- **Implementado:** `itinerary-progress.ts` + testes; também em `place.service` (`findActiveItineraryPlaceContext`).

#### E2-03 · Validar geofence e persistir `coordinates` — ✅
- **Repo:** `ZanzarBackend`
- **Depende de:** E2-01
- **O que fazer:** ler `CHECKIN_RADIUS_METERS` (hoje só existe no `.env.example`), comparar `coordinates` do body com `places.geoLocation` e recusar com 422 fora do raio. Persistir `coordinates` e `serverReceivedAt` no `checkin.model.ts` — hoje o Zod aceita e o Mongoose descarta.
- **Aceite:** check-in a 5 km retorna 422; dentro do raio grava os dois campos novos; `coordinates` ausente continua aceito (compatibilidade com o app atual).
- **Figma:** —
- **Implementado:** `utils/geofence.ts`, `config/env.ts`, campos no `checkin.model`; rodar `npm run db:validate` após merge.

#### E2-04 · Aposentar o trigger do Atlas — ⚠️
- **Repo:** `ZanzarBackend`
- **Depende de:** E2-01, E2-02
- **O que fazer:** desativar o trigger no Atlas e marcar `scripts/triggers/on-checkin-created.js` como histórico (ou remover), registrando no README que os efeitos agora são da API.
- **Aceite:** um check-in incrementa `checkInCount` exatamente 1, sem contagem dupla.
- **Figma:** —
- **Feito no repo:** README + `scripts/triggers/README.md` + [`E2-04-OPS-CHECKLIST.md`](ZanzarBackend/scripts/triggers/E2-04-OPS-CHECKLIST.md). **Pendente ops (você):** desativar trigger no Atlas UI e validar +1 em `checkInCount` (MCP não gerencia App Services).

---

### E3 — Roteiros: iOS (aba Check in)

#### E3-01 · Scaffold da feature `Itinerary` e rota de sheet — ✅
- **Repo:** `Zanzar`
- **Depende de:** —
- **O que fazer:** criar `Features/Itinerary/` (`API/`, `Models/`, `ViewModels/`, `Views/`, `Views/Components/`) seguindo o padrão MVVM-C das outras features. Preencher os enums vazios em `Coordinator/Routes.swift` (`Sheet.itineraryDetail(slug:)`) e o factory em `Coordinator/AppCoordinator.swift`, removendo os 4 `TODO`.
- **Aceite:** o projeto compila, o sheet abre e fecha pelo coordinator, e nenhum `TODO` de sheet/cover sobra no `Coordinator/`.
- **Figma:** 331:1552, 332:1878
- **Feito:** `39ecefb` — `Features/Itinerary/`, `Sheet.itineraryDetail(slug:)`, factory no coordinator.

#### E3-02 · `ItineraryService` e models de domínio — ✅
- **Repo:** `Zanzar`
- **Depende de:** E1-02, E1-03, E1-06, E3-01
- **O que fazer:** service sobre `URLSessionNetworkClient` para `GET itineraries`, `GET itineraries/{slug}`, `POST itineraries/{slug}/activate`, `POST itineraries/active/abandon` e `GET user/{id}/itinerary`. Models `Itinerary`, `ItineraryDetail`, `ItineraryRouteType`, `ActiveItinerary`, `ItinerarySlot`. Protocolo `ItineraryServicing` para permitir mock nos testes.
- **Feito:** `39ecefb` — 5 endpoints, models, `ItineraryServiceTests`.

#### E3-03 · `ItineraryListView` — aba Check in — ✅
- **Repo:** `Zanzar`
- **Depende de:** E3-02
- **O que fazer:** substituir `TabPlaceholderView` no case `.checkIn` de `App/MainTabView.swift`. Header "Check in" + subtítulo, seção `Roteiros` com cards (nº de lugares, nº de pessoas que completaram, botão "Ver detalhes") e seção `Lugares próximos` em grid, reaproveitando `PlaceDetailNearbyPlaceCard` e `LocationMapService` para a posição do usuário.
- **Aceite:** a aba renderiza as duas seções com dados reais; tocar num lugar navega para `PlaceDetailView`; "Ver detalhes" abre o sheet do roteiro.
- **Figma:** 293:3674
- **Feito:** `ce6ef2d` — `MainTabView` + seções Roteiros / Lugares próximos.

#### E3-04 · `ActiveItineraryProgressCard` — card `Roteiro atual` — ✅
- **Repo:** `Zanzar`
- **Depende de:** E3-02, E4-02
- **O que fazer:** card no topo da aba com a trilha de nós (concluído = carimbo; pendente = círculo tracejado com "?"), nome do roteiro e "Ver detalhes". Quando não há roteiro ativo, mostrar `Nenhum roteiro selecionado.`
- **Aceite:** o card reflete o progresso do `GET /user/{id}/itinerary` e some ao abandonar o roteiro.
- **Feito:** `ce6ef2d` + `ItineraryStampView` (E4-02 parcial).

#### E3-05 · `ItineraryDetailSheet` — duas variantes — ✅
- **Repo:** `Zanzar`
- **Depende de:** E3-02
- **O que fazer:** sheet com título, tags de objetivos, "N lugares para conhecer" / "N pessoas completaram", descrição e botão `Começar roteiro`. Variante **livre**: grid dos carimbos a conquistar. Variante **fixa**: `Map` com os pins na ordem da rota + bloco `Rota sugerida` numerado. Usar `Button` com label de texto, nunca `onTapGesture`.
- **Aceite:** as duas variantes batem com o Figma e o sheet fecha pelo X sem deixar o coordinator num estado inconsistente.
- **Feito:** `ce6ef2d` — variantes free/fixed, sheet fecha pelo coordinator.

#### E3-06 · Ativar e abandonar roteiro + testes de view model — ✅
- **Repo:** `Zanzar`
- **Depende de:** E3-04, E3-05, E1-04, E1-05
- **O que fazer:** ligar `Começar roteiro` ao activate (fechando o sheet e atualizando o card), expor o abandonar, e cobrir com testes em `ZanzarProjectTests` usando um `MockItineraryService`: lista, ativar com sucesso, 409 de roteiro já ativo, abandonar.
- **Feito:** `ce6ef2d` — activate/abandon, `ItineraryViewModelTests`; pins do mapa recarregam via `AppNotification.activeItineraryDidChange` → `LocationMapViewModel.reloadPlaces()`.
- **Figma:** 331:1552, 332:1878

---

### E4 — Alerts faltantes do fluxo de check-in

#### E4-01 · Alert de confirmação antes do check-in — ✅
- **Repo:** `Zanzar`
- **Depende de:** —
- **O que fazer:** em `PlaceDetailViewModel`, adicionar `showsCheckInConfirmation` e só chamar `performCheckIn()` após confirmar. Alert em `PlaceDetailView` com título `Fazer Check-in`, mensagem citando o nome do lugar em negrito e botões `Cancelar` / `Confirmar`.
- **Aceite:** nenhum check-in é enviado sem confirmação; `Cancelar` não dispara requisição.
- **Figma:** 871:5025, 354:4186
- **Feito:** `feat/e4-checkin-alerts` — `requestCheckIn()` + alert Cancelar/Confirmar.

#### E4-02 · Asset do carimbo de roteiro — ✅
- **Repo:** `Zanzar`
- **Depende de:** —
- **Feito:** `ItineraryStampView` + uso em roteiros e `PlaceDetailStatsCard`.

#### E4-03 · `SealEarnedAlertView` — "Eba! Você ganhou um selo!" — ✅
- **Repo:** `Zanzar`
- **Depende de:** E2-01, E4-01
- **O que fazer:** alert customizado com título, mensagem "Você passou por **X** e encontrou um selo", o selo grande e um único botão `Aceitar`. Disparar quando a resposta do check-in trouxer `stampIdGranted` com `isNewStamp`.
- **Aceite:** check-in num lugar novo mostra o alert com o selo da categoria certa; check-in num lugar cuja categoria já foi carimbada não mostra.
- **Figma:** 354:4161, 871:4765 + 871:5025
- **Feito:** `CheckInResult` + `SealEarnedAlertView` quando `isNewStamp`.

#### E4-04 · Segundo selo no `PlaceDetailStatsCard` — ✅
- **Repo:** `Zanzar`
- **Depende de:** E4-02
- **O que fazer:** quando o lugar está no roteiro ativo (`userContext.isInActiveItinerary`, já devolvido por `GET /places`), mostrar o carimbo do roteiro ao lado do selo de categoria, respeitando os estados earned/preview.
- **Aceite:** o card mostra 1 selo fora de roteiro e 2 dentro, igual ao node 871:4388; Dynamic Type grande não quebra o layout.
- **Figma:** 871:4388
- **Feito:** segundo carimbo quando `isInActiveItinerary`.

---

### E5 — Perfil com dados reais

#### E5-01 · Enriquecer `GET /user/:id/profile` — ✅
- **Repo:** `ZanzarBackend`
- **Depende de:** —
- **O que fazer:** em `src/modules/users/user.service.ts`, incluir em cada `recentCheckIns` o `impressionTag` (join com `rating` por `userId` + `placeId`). Em `user.repository.ts`, trocar `completedItinerariesCount` por `itinerariesCount` que conte `activeItinerary` + `inactiveItineraries` + `completedItineraries`. Atualizar `src/schemas/user.ts`.
- **Aceite:** o payload traz `username`, `checkInCount`, `itinerariesCount`, `stampsCount` e, em cada check-in, `placeName`, `datetime`, `photoReference`, `stamp` e `impressionTag`.
- **Figma:** 290:2306
- **Feito:** `feat/e5-e6-mvp-polish` — join `rating`, agregação `itinerariesCount`.

#### E5-02 · `ProfileService` e `ProfileViewModel` reais — ✅
- **Repo:** `Zanzar`
- **Depende de:** E5-01
- **O que fazer:** ~~criar `Features/Profile/API/ProfileService.swift`~~ **Feito (#24).** Consumir `GET user/{id}/profile?limit=4`, `load()` com loading/erro, mocks removidos.
- **Aceite:** o Perfil mostra o username e os contadores do usuário logado; erro de rede mostra estado de erro; testes com `MockProfileService`.
- **Figma:** 290:2306
- **Feito:** `itineraryCount` mapeia `itinerariesCount` (E5-01).

#### E5-03 · `ProfileCheckInCard` com foto e reação reais — ✅
- **Repo:** `Zanzar`
- **Depende de:** E5-01, E5-02
- **O que fazer:** foto via proxy (`PlaceRemoteImage`), selo de categoria, `impressionTag` decodificado e badge com carinhas de `Assets.xcassets/Carinhas/`.
- **Feito:** `feat/e5-e6-mvp-polish` — `ProfileService`, `ProfileCheckInCard`, `PlaceMediaAccessPolicy` no perfil.
- **Aceite:** cada card mostra foto real, nome, data formatada com `FormatStyle` e a carinha da reação; sem reação, o badge não aparece.
- **Figma:** 290:2306

#### E5-04 · Chamar `POST /logout` no sign-out — ✅
- **Repo:** `Zanzar`
- **Depende de:** —
- **O que fazer:** ~~em `Utils/AuthSession.swift`~~ **Feito (#24)** em `ProfileViewModel.signOut()` → `ProfileService.logout()` antes de `authSession.signOut()`. Falha de rede não bloqueia sign-out local.
- **Aceite:** depois do sign-out, o token antigo recebe 401; offline, o sign-out local ainda funciona.
- **Figma:** 290:2306 (botão de sair)

---

### E6 — Limpeza e qualidade

#### E6-01 · Proxy de fotos no backend — ✅
- **Repo:** `ZanzarBackend` + `Zanzar`
- **Depende de:** —
- **O que fazer:** implementar `GET /places/photo?ref=` (o seed já aponta para esse caminho), com a chave do Google só no servidor e cache de resposta. Migrar `Utils/GooglePlacesConfiguration.swift` para montar a URL do backend e remover a chave do `Config.xcconfig`.
- **Aceite:** as fotos carregam sem chave no bundle do app; `ref` inválido retorna 400.
- **Figma:** todas as telas com foto de lugar

#### E6-02 · Alinhar as regras de senha — ✅
- **Repo:** `ZanzarBackend`
- **Depende de:** —
- **O que fazer:** em `src/constants/auth.ts`, `PASSWORD_MIN_LENGTH = 6` contradiz o comentário ("Mínimo 8 chars") e `PASSWORD_PATTERN` (`.{8,}`). Mensagens em `createUserSchema.ts` e `loginAuthSchema.ts` citam requisitos que a regex não exige. Padronizar em 8 + letra + número. Remover `JWT_ACCESS_TTL_SECONDS` e `JWT_REFRESH_TTL_SECONDS` (nunca usados).
- **Aceite:** senha de 7 caracteres é recusada com a mensagem correta; app e API concordam; não sobra constante de TTL morta.
- **Figma:** 353:2474

#### E6-03 · Suíte de testes do backend — ⚠️
- **Repo:** `ZanzarBackend`
- **Depende de:** E1-04, E2-01, E2-03
- **O que fazer:** configurar Vitest e cobrir: idempotência do check-in, concessão de selo, progresso de rota livre e fixa, ativação com 409, geofence e `requireOwnership`.
- **Feito (MVP):** Vitest + Supertest (`*.vitest.ts`), legado `test:legacy`, CI GitHub Actions. Mocks cobrem profile, photo route, ownership, check-in idempotente, itinerary 409.
- **Gap pós-MVP (aceite estrito):** testes de integração com MongoMemoryServer ou Atlas de teste para geofence 422 e transação de check-in completa.
- **Aceite MVP acordado:** `npm test` verde localmente e no CI; caminhos de erro cobertos via mocks onde integração não existir.
- **Figma:** —

#### E6-04 · Atualizar o README do backend — ✅
- **Repo:** `ZanzarBackend`
- **Depende de:** E1-02, E2-01
- **O que fazer:** README com `src/modules/` real, tabela de endpoints, check-in síncrono, geofence, perfil/logout, proxy de fotos, trigger → API.
- **Aceite:** um dev novo sobe o projeto e entende a API só com o README.
- **Feito:** tabela consolidada de endpoints + remoção de boilerplate obsoleto.

#### E6-05 · Remover os stubs mortos do app — ✅
- **Repo:** `Zanzar`
- **Depende de:** —
- **O que fazer:** apagar `Features/Welcome/API/WelcomeService.swift`, `Features/Welcome/Models/Welcome.swift`, `Features/Login/Models/Login.swift`, `Features/SignUp/Models/SignUp.swift` e o `WelcomeViewModel` não usado — todos só contêm `TODO`.
- **Aceite:** o projeto compila sem eles e nenhum `TODO` de stub sobra nas features de auth.
- **Figma:** —

#### E6-06 · Strings novas no catálogo — ✅
- **Repo:** `Zanzar`
- **Depende de:** E3-05, E4-03
- **O que fazer:** adicionar as chaves de roteiro e dos dois alerts em `Resources/Localizable.xcstrings` com `extractionState: "manual"`. Strings de perfil (`profile.*`) já foram adicionadas em #24.
- **Aceite:** nenhuma string literal hardcoded nas views novas; o catálogo não acusa chaves faltando.
- **Figma:** 293:3674, 331:1552, 332:1878, 354:4161, 871:5025

---

## 4. Ordem sugerida

O caminho crítico é **roteiros**, porque a aba Check in inteira e metade dos alerts dependem dele.

```
E1-01 ──┬── E1-02 ── E1-03 ──┬── E1-04 ── E1-05
        │                     │       └── E1-06
        ├── E1-07             │
        └── E2-01 ──┬── E2-02 ┘
                    ├── E2-03
                    └── E2-04

E3-01 ── E3-02 ──┬── E3-03
                 ├── E3-04 (+ E4-02)
                 └── E3-05 ── E3-06

E4-01 ── E4-03 (+ E2-01)      E4-02 ── E4-04
E5-01 ── E5-03                E5-02 ✅  E5-04 ✅
E6-* em paralelo
```

Sequência prática em 4 ondas:

1. ~~**Backend de roteiros + check-in síncrono**~~ ✅ (E1 + E2-01…E2-03; E2-04 ops Atlas pendente)
2. ~~**iOS de roteiros**~~ ✅ (E3-01…E3-06 em `feat/e3-itinerary`)
3. ~~**Alerts de check-in**~~ ✅ (E4-01…E4-04)
4. ~~**Perfil enriquecido**~~ ✅ (E5-01, E5-03 em `feat/e5-e6-mvp-polish`)
5. ~~**Endurecimento**~~ ⚠️ (E6-* feitos exceto E6-03 integração HTTP/DB e E2-04 Atlas UI)

Itens 2 e 3 podem andar em paralelo. Contratos fechados: E1-02/E1-03/E1-06 + payload E2-01 (`stampIdGranted`, etc.).

### Fora do escopo do MVP

Nenhuma destas aparece no Figma e nenhuma é necessária para fechar as 30 telas: login social (Apple/Google), refresh token, push notifications, recuperação de senha, sync offline em lote (`syncPushBodySchema` sem rota) e realtime.

### Pós-MVP (endurecimento — não bloqueia telas)

| Item | Descrição |
| --- | --- |
| E6-03+ | Testes de integração HTTP + MongoDB (check-in transacional, geofence 422) |
| ~~E6-07~~ | ~~Rate limit em `GET /places/photo`~~ — feito (`placePhotoLimiter`, 120/15 min por IP) |
| E6-08 | App iOS envia `coordinates` no `POST /checkIn` para geofence ativo |
| ~~CI backend~~ | `.github/workflows/ci.yml` (`npm test` + typecheck) |
