# Zanzar (app iOS)

App iOS em SwiftUI para descobrir lugares em Curitiba, fazer check-in, ganhar selos e seguir roteiros. O nome que aparece para o usuário nas permissões é "O Lero". O backend fica em `../ZanzarBackend` (repositório git separado). Veja [docs/APP-BACKEND.md](docs/APP-BACKEND.md) para a ligação entre os dois.

## Stack

- Swift/SwiftUI, MVVM-C (`@Observable`, `AppCoordinator` com `NavigationPath`), alvo iOS 26.0, Xcode 27.1.
- Build settings: `SWIFT_VERSION = 5.0`, `SWIFT_APPROACHABLE_CONCURRENCY = YES`, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`. Tipos usados fora da main thread levam `nonisolated` explícito.
- Sem dependências de terceiros (nenhum Swift Package).
- Rede: `URLSessionNetworkClient` (`Features/HTTP`), tokens no Keychain (`Features/Auth`), refresh automático no 401.
- Textos: `Localizable.xcstrings` (en + pt-BR), lidos por `L10n.string(...)`.
- Bundle id: `dalpra.Zanzar`. Scheme único: `ZanzarProject`.

## Estrutura

```
ZanzarProject/ZanzarProject.xcodeproj
ZanzarProject/ZanzarProject/
  App/            MyApp (@main), ContentView, MainTabView
  Coordinator/    AppCoordinator, Routes
  Features/<X>/   API/ (Service + DTOs), Models/, ViewModels/, Views/(Components/)
                  X = Auth, HTTP, Itinerary, LocationMap, Login, PlaceDetail, Profile,
                      RatingPrompt, Shared, SignUp, Welcome
  Utils/          AppLog, AppLanguage, AppNotification, DataFreshness, GooglePlacesConfiguration
  Resources/      Assets.xcassets, Localizable.xcstrings
ZanzarProject/ZanzarProjectTests/<Feature>/   testes (Swift Testing) + TestHelpers/
scripts/          check-app-content.mjs, select-ios-simulator.sh, testflight-preflight.sh, update-api-tunnel-url.sh
docs/             app-review.md
.agents/skills/   skills do projeto (create-feature, swiftui-pro, swift-concurrency, swift-testing-expert...)
```

`stacklit.json`, `DEPENDENCIES.md` e `stacklit.html` na raiz são o mapa gerado por `stacklit init`.

## Compilar e testar

O `xcode-select` desta máquina aponta para as Command Line Tools. Até alguém rodar `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`, use `DEVELOPER_DIR` em comandos de shell. O XcodeBuildMCP funciona sem isso.

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodebuild test -project ZanzarProject/ZanzarProject.xcodeproj -scheme ZanzarProject \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

- Estado em 2026-10-29: build OK, 231 testes passando, 0 falhas.
- API local: copie `ZanzarProject/Config.xcconfig.example` para `Config.xcconfig` (ignorado pelo git) e preencha `ZANZAR_API_BASE_URL`. Vazio no Debug = `http://127.0.0.1:3000`. Release usa `Config.Release.xcconfig`.
- iPhone físico: `scripts/update-api-tunnel-url.sh <url>` com o túnel do backend (README).
- Lint: `swiftlint lint` (CI roda com a config padrão, não há `.swiftlint.yml`). Não há SwiftFormat.

## Convenções

- Uma feature = uma pasta; um tipo por arquivo; Views só falam com o ViewModel, ViewModel só com o `*Servicing` (protocolo) da feature.
- Todo texto visível passa por `L10n`/`Localizable.xcstrings`. Nada de string solta.
- Logs com `AppLog` (nunca `print`); ids de usuário não vão para o log.
- API moderna: `foregroundStyle`, `clipShape(.rect(cornerRadius:))`, `Tab`, `onChange` com 0 ou 2 parâmetros. O código atual está limpo nisso, mantenha.
- DTOs `Decodable` ficam no `API/` da feature e são mapeados para modelos de domínio. Mudou um DTO? Confira `ZanzarBackend/src/schemas/*` e `scripts/contracts/swift-clients.json`.
- Testes novos em Swift Testing, com fakes em `TestHelpers/` (`InMemoryAuthTokenStore`, `TestClock`).
- Nunca commitar `Config.xcconfig`, tokens ou chaves.

## Qual ferramenta usar

| Situação | Ferramenta |
|---|---|
| Entender estrutura / quem chama quem | codebase-memory (`search_graph`, `trace_path`) e `stacklit.json` |
| Compilar, testar, rodar no simulador | XcodeBuildMCP (`session_show_defaults` antes de tudo) |
| Tocar na UI do simulador (tap, screenshot) | `mcp__Claude_Code_iOS_Simulator__control` |
| Criar tela/feature nova | skill `create-feature` |
| Revisar SwiftUI | skill `swiftui-pro` |
| Concorrência, warnings de actor, Swift 6 | skill `swift-concurrency` |
| Escrever/migrar testes | skill `swift-testing-expert` |
| Dúvida de API da Apple por versão | Context7 |
| Crítica de design | `impeccable` (critique) + `design:accessibility-review` |
| Contrato com o backend | `docs/APP-BACKEND.md` e o repo `../ZanzarBackend` |

## Pontos de atenção conhecidos

- Warnings `ActorIsolatedCall` por causa do `L10n` (herda MainActor) chamado de código `nonisolated`; viram erro se migrar para Swift 6.
- `NSLocationAlwaysAndWhenInUseUsageDescription` está vazio no projeto (aviso do Xcode).
- `IPHONEOS_DEPLOYMENT_TARGET`: 27.0 no projeto, 26.0 nos targets. O alvo vence, mas está inconsistente.
- README descreve uma pasta `Extensions/` que não existe.
