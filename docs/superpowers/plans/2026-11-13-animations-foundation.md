# Fundação de Animações Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Criar a linguagem de movimento (`Motion`) e de haptics (`Haptic`) do app e migrar a família do carimbo para ela, sem mudar o visual.

**Architecture:** Dois arquivos novos em `Utils/` com curvas e haptics nomeados. A família do carimbo (`PaperStampPhase` e seus 6 pontos de uso) passa a pedir o tamanho do carimbo e o haptic por nome, em vez de números soltos. As demais telas ficam como estão e migram uma a uma na fase tela a tela.

**Tech Stack:** SwiftUI (iOS 26), Swift Testing. Sem dependências novas. O projeto usa grupos sincronizados do Xcode, então arquivos novos entram sozinhos no target.

**Spec:** `docs/superpowers/specs/2026-11-13-animations-foundation-design.md`

## Global Constraints

- iOS 26.0, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`; tipo novo usado fora da main thread leva `nonisolated`.
- Texto visível por `L10n`; logs por `AppLog`; nunca `print`.
- O carimbo continua sem bounce, partículas ou loop.
- "Reduzir Movimento" continua respeitado em tudo; haptics seguem a configuração do sistema, não a de Reduzir Movimento.
- Esta fase não muda o visual: durações do carimbo 0.35 / 0.45 / 0.62 e intensidades de haptic 0.7 / 0.55 ficam exatamente como hoje.
- Sem dependências novas; nunca commitar `Config.xcconfig`, tokens ou chaves.
- Testes em Swift Testing; a suíte existente (541 testes) precisa continuar verde.

## Review Focus

- Reduzir Movimento ligado: o carimbo assenta direto, sem animar e sem haptic (hoje `onContact` não dispara). Teste no Task 3.
- Durações do carimbo mudaram sem querer na migração: teste que fixa 0.35 / 0.45 / 0.62 no Task 1.
- Haptic migrado com intensidade errada: teste que fixa `carimbo` = rígido 0.7 e `carimboLeve` = rígido 0.55 no Task 2.
- Duas animações de carimbo em sequência (roteiro com vários selos): fila e `pressGeneration` de `ItineraryStampTrack` não podem mudar de comportamento; conferir no simulador no Task 4.

---

### Task 1: `Motion` (curvas e tamanhos de carimbo)

**Files:**
- Create: `ZanzarProject/ZanzarProject/Utils/Motion.swift`
- Test: `ZanzarProject/ZanzarProjectTests/Shared/MotionTests.swift`

**Interfaces:**
- Produces:
  - `enum Motion` com `static let toque: Animation` (easeOut 0.15s), `static let suave: Animation` (`.smooth(duration: 0.25)`), `static let assentar: Animation` (`.smooth(duration: 0.35)`) e `static func carimbo(duration: TimeInterval) -> Animation` (`.easeOut(duration:)`).
  - `Motion.StampSize` (`enum`, casos `.small`, `.medium`, `.large`) com `var duration: TimeInterval` (0.35, 0.45, 0.62).
  - `extension View { func motion<V: Equatable>(_ animation: Animation, value: V) -> some View }`: aplica `.animation(_:value:)`, ou `nil` quando `accessibilityReduceMotion` está ligado (via um `ViewModifier` que lê `@Environment(\.accessibilityReduceMotion)`).

- [ ] **Step 1: Escrever o teste que falha** em `MotionTests.swift`, suíte `MotionTests`: `stampSizeDurationsMatchTheShippedStamps` com `#expect(Motion.StampSize.small.duration == 0.35)`, `.medium == 0.45`, `.large == 0.62`.
- [ ] **Step 2: Rodar e ver falhar** (`Motion` não existe): `xcodebuild test -project ZanzarProject/ZanzarProject.xcodeproj -scheme ZanzarProject -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:ZanzarProjectTests/MotionTests` com `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`. Esperado: erro de compilação.
- [ ] **Step 3: Implementar** `Motion.swift` conforme Interfaces. Os valores vêm do design; o modificador é um `ViewModifier` privado mais a extensão pública.
- [ ] **Step 4: Rodar o teste.** Esperado: PASS.
- [ ] **Step 5: Commit** `feat(motion): add Motion curves and stamp sizes`

### Task 2: `Haptic` (vocabulário de haptics)

**Files:**
- Create: `ZanzarProject/ZanzarProject/Utils/Haptic.swift`
- Test: `ZanzarProject/ZanzarProjectTests/Shared/HapticTests.swift`

**Interfaces:**
- Produces:
  - `enum Haptic` com casos `carimbo`, `carimboLeve`, `selecao`, `sucesso`, `alerta`, `toqueSuave` e `var feedback: SensoryFeedback`.
  - Mapeamento: `carimbo` = `.impact(flexibility: .rigid, intensity: 0.7)`; `carimboLeve` = `.impact(flexibility: .rigid, intensity: 0.55)`; `selecao` = `.selection`; `sucesso` = `.success`; `alerta` = `.warning`; `toqueSuave` = `.impact(flexibility: .soft, intensity: 0.5)`.
  - `extension View { func haptic<T: Equatable>(_ haptic: Haptic, trigger: T) -> some View }`, que chama `.sensoryFeedback(haptic.feedback, trigger: trigger)`.

- [ ] **Step 1: Escrever o teste que falha** em `HapticTests.swift`: `carimboKeepsShippedIntensity` com `#expect(Haptic.carimbo.feedback == .impact(flexibility: .rigid, intensity: 0.7))` e `carimboLeveKeepsShippedIntensity` com 0.55. Se `SensoryFeedback` não for `Equatable`, pular o teste e deixar a verificação para o build e o Task 4.
- [ ] **Step 2: Rodar e ver falhar** (`-only-testing:ZanzarProjectTests/HapticTests`).
- [ ] **Step 3: Implementar** `Haptic.swift` conforme Interfaces.
- [ ] **Step 4: Rodar o teste.** Esperado: PASS.
- [ ] **Step 5: Commit** `feat(haptics): add Haptic vocabulary`

### Task 3: `PaperStampPhase.play` passa a receber o tamanho do carimbo

**Files:**
- Modify: `Features/Shared/Views/Components/Places/PaperStampPhase.swift`
- Test: `ZanzarProjectTests/Shared/PaperStampPhaseTests.swift`

**Interfaces:**
- Consumes: `Motion.carimbo(duration:)`, `Motion.StampSize` (Task 1).
- Produces: `PaperStampPhase.play(size: Motion.StampSize, reduceMotion: Bool, update:, onContact:, onSettled:)`. O parâmetro `duration: TimeInterval` sai. As duas animações internas usam `Motion.carimbo(duration: size.duration)` e `Motion.carimbo(duration: size.duration * 0.28)`; o `0.28` fica como está.

- [ ] **Step 1: Escrever o teste que falha** `reduceMotionSettlesWithoutContact`: chamar `PaperStampPhase.play(size: .small, reduceMotion: true, update:, onContact:, onSettled:)` e afirmar que a última fase recebida é `.settled`, que `onSettled` rodou uma vez e que `onContact` não rodou (é o caso que impede o haptic com Reduzir Movimento).
- [ ] **Step 2: Rodar e ver falhar** (assinatura `size:` não existe).
- [ ] **Step 3: Alterar a assinatura e as duas animações** em `PaperStampPhase.swift`. Os 4 chamadores ainda não compilam; isso se resolve no Task 4 (fazer os dois juntos antes de rodar a suíte inteira).
- [ ] **Step 4: Commit só depois do Task 4**, junto, porque o projeto não compila entre os dois.

### Task 4: Migrar os 6 usos do carimbo e dos haptics

**Files:**
- Modify: `Features/PlaceDetail/Views/Components/PlaceDetailCheckInButton.swift` (duração 0.35 → `.small`; haptic `carimboLeve`)
- Modify: `Features/PlaceDetail/Views/Components/PlaceDetailStatsCard.swift` (0.35 → `.small`; haptic `carimbo`)
- Modify: `Features/PlaceDetail/Views/Components/SealEarnedAlertView.swift` (0.45 → `.medium`; haptic `carimbo`)
- Modify: `Features/Itinerary/Views/Components/ItineraryStampTrack.swift` (0.45 → `.medium`; haptic `carimbo`)
- Modify: `Features/PlaceDetail/Views/Components/ItineraryCompletedAlertView.swift` (0.62 → `.large`; haptic `carimbo`)
- Modify: `Features/Onboarding/Views/Components/PassportStampAnimationView.swift` (só a chamada `PaperStampPhase.play`: 0.35 → `.small`; os dois `easeOut` da coreografia do passaporte ficam para a rodada da tela)
- Modify: `App/MainTabView.swift:73` (`.animation(reduceMotion ? nil : .smooth(duration: 0.35), ...)` → `.motion(Motion.assentar, value: coordinator.presentedSheet)`; remover o `@Environment` de `reduceMotion` se ficar sem uso)

**Interfaces:**
- Consumes: `PaperStampPhase.play(size:...)` (Task 3), `Haptic` e `.haptic(_:trigger:)` (Task 2), `.motion(_:value:)` (Task 1).

- [ ] **Step 1:** Em cada arquivo, trocar o argumento `duration:` ou a constante `stampDuration` (inclusive as `private let stampDuration` de `PlaceDetailCheckInButton` e `PlaceDetailStatsCard`) por `size:`, e `.sensoryFeedback(.impact(...), trigger: landingCount)` por `.haptic(.carimbo, trigger: landingCount)` (ou `.carimboLeve` no check-in). Deixar `landingCount` e `isVisible` exatamente como estão.
- [ ] **Step 2:** Migrar `MainTabView.swift:73` conforme acima. Nenhum outro `.animation(reduceMotion ? nil : ...)` muda nesta fase.
- [ ] **Step 3: Compilar e rodar a suíte inteira** (comando do CLAUDE.md). Esperado: build OK, 541 testes + os novos passando, 0 falhas.
- [ ] **Step 4: `swiftlint lint`** nos arquivos tocados. Esperado: sem violações novas.
- [ ] **Step 5: Conferir no simulador** (XcodeBuildMCP, `session_show_defaults` antes): fazer um check-in e ver o carimbo e o haptic iguais a antes; abrir um roteiro com vários selos novos (fila de carimbos); rodar o passaporte do primeiro uso; ligar "Reduzir Movimento" e repetir o check-in (carimbo aparece direto, sem animação). Registrar no PR o que foi conferido e o que não deu para conferir (haptic só se sente no iPhone físico).
- [ ] **Step 6: Commit** (Tasks 3 e 4 juntos) `refactor(motion): move stamp family to Motion and Haptic`

## Auto-revisão

- Cobertura do design: `Motion` com 4 curvas e modificador (Task 1), `Haptic` com os 6 nomes (Task 2), migração da família do carimbo sem mudar o visual (Tasks 3 e 4). O método tela a tela e a ordem das jornadas são fase seguinte: cada tela vira seu próprio mini-design e plano.
- Consistência de tipos: `Motion.StampSize` (Task 1) é o que `PaperStampPhase.play(size:)` (Task 3) e os 6 usos (Task 4) consomem; `Haptic.carimbo` / `.carimboLeve` (Task 2) são os usados no Task 4.
- Decisão consciente: `toque`, `suave`, `selecao`, `sucesso`, `alerta` e `toqueSuave` nascem sem uso (exceto `assentar`, usado no `MainTabView`). Entram na primeira tela que precisar, que é quando ganham valor ajustado no simulador.
