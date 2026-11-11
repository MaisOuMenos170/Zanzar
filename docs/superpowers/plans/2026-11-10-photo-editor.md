# Editor de foto antes do envio — plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Depois de escolher uma foto (biblioteca ou câmera) e antes das checagens e do envio, o usuário corta, dá zoom e gira a foto.

**Architecture:** Um tipo puro, `PhotoCropGeometry`, guarda a rotação e o quadro de corte e aplica todas as regras (limites, proporção, mínimo de 320 px). Uma função `@concurrent` em `PhotoPreparer` gira e corta os pixels e entra no protocolo `PhotoProcessing`. `PhotoUploadViewModel` ganha o passo `editing`; as checagens de conteúdo sensível e de rostos passam a rodar sobre a imagem editada. `PhotoEditorView` (SwiftUI puro) desenha o quadro e as alças e só fala com a geometria.

**Tech Stack:** Swift/SwiftUI, `@Observable`, CoreGraphics/ImageIO, Swift Testing. Sem dependências novas.

**Spec:** [docs/superpowers/specs/2026-11-10-photo-editor-design.md](../specs/2026-11-10-photo-editor-design.md)

## Global Constraints

- Alvo iOS 26.0, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`: tipos usados fora da main thread levam `nonisolated` explícito (a geometria, o `PhotoEdit`, as funções de pixel).
- Sem dependências de terceiros.
- Todo texto visível passa por `Localizable.xcstrings` (en + pt-BR); nada de string solta. Logs só com `AppLog`, nunca `print`.
- Um tipo por arquivo; a View só fala com o ViewModel ou com a geometria; o ViewModel só com `PhotoProcessing` e `UserPhotosServicing`.
- O backend recusa foto com o lado menor abaixo de **320 px** (`MIN_SIDE_PIXELS`); o app continua limitando a **2048 px** e reencodando sem metadados.
- Proporções do atalho: livre, 1:1, 4:5, 16:9. Girar é de 90° por vez, no sentido horário. Girar reinicia o quadro para a foto inteira.
- API moderna: `foregroundStyle`, `clipShape(.rect(cornerRadius:))`, `onChange` com 0 ou 2 parâmetros.
- Testes novos em Swift Testing, com fakes em `ZanzarProjectTests/UserPhotos/`.
- Arquivos novos entram sozinhos no projeto (grupos sincronizados do Xcode); não editar o `.pbxproj`.

## Review Focus

1. Foto com lado menor abaixo de 320 px (ou exatamente 320): o corte fica travado, girar funciona, nada divide por zero nem sai do espaço. → Task 1.
2. Proporção travada numa foto em que ela não cabe com o mínimo de 320 px (ex.: 16:9 numa foto 320×2048): o quadro continua dentro da foto e respeita o mínimo, sem inverter. → Task 1.
3. Arrastar uma alça além da borda oposta ou para fora da foto: o retângulo é limitado, nunca fica negativo nem invertido. → Task 1.
4. Corte extremo e arredondamento: o retângulo em pixels é inteiro, está dentro da imagem e tem ao menos 320 px no lado menor. → Tasks 1 e 2.
5. O corte faz um rosto passar a ser destaque: a foto editada cai em `faceWarning`; conteúdo sensível na foto editada vira `failed(.sensitiveContent)`; "Editar" na prévia parte da foto original, não da pixelizada. → Task 3.

---

## Task 1: Geometria de corte e rotação

**Files:**
- Create: `ZanzarProject/ZanzarProject/Features/UserPhotos/Models/PhotoCropGeometry.swift`
- Create: `ZanzarProject/ZanzarProject/Features/UserPhotos/Models/PhotoEdit.swift`
- Test: `ZanzarProject/ZanzarProjectTests/UserPhotos/PhotoCropGeometryTests.swift`

**Interfaces:**
- Produces:
  - `nonisolated struct PhotoEdit: Equatable, Sendable { let quarterTurns: Int; let cropRect: CGRect }` — `quarterTurns` 0...3 no sentido horário; `cropRect` em **pixels da imagem já girada**, origem no canto superior esquerdo, valores inteiros.
  - `nonisolated struct PhotoCropGeometry: Equatable, Sendable`:
    - `enum AspectRatio: CaseIterable, Sendable { case free, square, fourByFive, sixteenByNine }` com `var ratio: CGFloat?` (largura/altura; `nil` para `free`).
    - `enum Handle: Sendable { case topLeft, top, topRight, right, bottomRight, bottom, bottomLeft, left }`
    - `static let minimumSide: CGFloat = 320`
    - `init(sourceSize: CGSize)`
    - `private(set) var quarterTurns: Int`, `private(set) var aspect: AspectRatio`
    - `private(set) var cropRect: CGRect` — **normalizado** (0...1), no espaço da imagem girada, origem no canto superior esquerdo
    - `var rotatedSize: CGSize` — `sourceSize` com largura e altura trocadas quando `quarterTurns` é ímpar
    - `var canCrop: Bool` — falso só quando o corte não pode ficar menor que a foto inteira em nenhum dos dois eixos
    - `var edit: PhotoEdit` — resultado em pixels
    - `mutating func rotate()`, `reset()`, `setAspect(_ aspect: AspectRatio)`, `drag(_ handle: Handle, to point: CGPoint)` (ponto normalizado), `move(by delta: CGSize)` (normalizado), `zoom(by factor: CGFloat)` (`>1` = quadro menor, em torno do centro)

**Regras a implementar (decididas no spec):** o quadro nunca sai de 0...1; o lado menor do corte, em pixels da imagem, nunca fica abaixo de 320 px, por eixo (largura em pixels ≥ min(320, largura da foto) e idem na altura); com proporção travada o quadro mantém a proporção e reduz até caber nos limites e no mínimo; `setAspect` ajusta o quadro atual para a nova proporção mantendo o centro, no maior tamanho que cabe; `rotate()` incrementa `quarterTurns` (módulo 4), reinicia o quadro para 0...1 e mantém a proporção escolhida só como atalho já aplicada à foto inteira (ou seja, reaplica `setAspect`); `reset()` zera rotação, quadro e proporção (`free`).

- [ ] **Step 1: Escrever os testes que falham** em `PhotoCropGeometryTests.swift` (`@Suite("PhotoCropGeometry")`, struct, sem `@MainActor`), com `sourceSize` 2000×1000 salvo quando indicado:
  - `startsWithTheWholePhoto`: `cropRect == CGRect(x: 0, y: 0, width: 1, height: 1)`, `edit == PhotoEdit(quarterTurns: 0, cropRect: CGRect(x: 0, y: 0, width: 2000, height: 1000))`.
  - `rotatingSwapsSizeAndResetsTheFrame`: depois de arrastar `.right` até 0.5 e chamar `rotate()`, `rotatedSize == CGSize(width: 1000, height: 2000)`, `cropRect` é o inteiro, `quarterTurns == 1`; depois de 4 chamadas, `quarterTurns == 0` e `rotatedSize == sourceSize`.
  - `dragCornerResizesFromTheOppositeCorner`: `drag(.bottomRight, to: CGPoint(x: 0.5, y: 0.5))` deixa `cropRect == CGRect(x: 0, y: 0, width: 0.5, height: 0.5)`.
  - `dragIsClampedToThePhoto` (revisão 3): `drag(.topLeft, to: CGPoint(x: -0.4, y: -0.4))` mantém `cropRect.minX == 0` e `minY == 0`; `drag(.right, to: CGPoint(x: 3, y: 0.5))` mantém `maxX == 1`.
  - `dragPastTheOppositeEdgeStopsAtTheMinimum` (revisão 3): `drag(.left, to: CGPoint(x: 1, y: 0.5))` deixa a largura em pixels `>= 320` e a largura normalizada positiva.
  - `neverCropsBelowTheMinimumSide` (revisão 4): depois de `zoom(by: 100)`, `edit.cropRect.width >= 320` e `edit.cropRect.height >= 320`, e os dois valores são inteiros.
  - `smallPhotoCannotBeCropped` (revisão 1): com `sourceSize` 300×200, `canCrop == false`, `zoom(by: 2)` e `drag(.right, to: CGPoint(x: 0.5, y: 0.5))` não mudam `cropRect`, `rotate()` troca `rotatedSize` para 200×300 sem travar. Com 320×2000, `canCrop == true` (só o eixo longo corta) e `drag(.left, to: CGPoint(x: 0.9, y: 0.5))` não muda a largura.
  - `lockedRatioKeepsItsShape`: `setAspect(.square)` em 2000×1000 resulta em quadro com `width * 2000 == height * 1000` (±1 px) e centrado; `zoom(by: 2)` depois mantém a proporção.
  - `lockedRatioThatDoesNotFitStaysInside` (revisão 2): 320×2048 com `setAspect(.sixteenByNine)` mantém o quadro dentro de 0...1 e com largura em pixels `>= 320` (a proporção cede, não o limite).
  - `moveKeepsTheFrameInsideThePhoto`: depois de `zoom(by: 2)`, `move(by: CGSize(width: 5, height: 5))` deixa `maxX == 1` e `maxY == 1` sem mudar o tamanho do quadro.
  - `resetGoesBackToTheStart`: depois de girar, travar proporção e cortar, `reset()` devolve o estado do `init` (`==` ao valor inicial).

- [ ] **Step 2: Rodar e ver falhar**

Run: `export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer && xcodebuild test -project ZanzarProject/ZanzarProject.xcodeproj -scheme ZanzarProject -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:ZanzarProjectTests/PhotoCropGeometryTests`
Expected: erro de compilação, `PhotoCropGeometry` e `PhotoEdit` não existem.

- [ ] **Step 3: Implementar** `PhotoEdit` e `PhotoCropGeometry` com as assinaturas acima. Abordagem: guardar o quadro normalizado e fazer todo limite (0...1 e mínimo por eixo) num único método privado `clamped(_:)` usado por `drag`, `move`, `zoom` e `setAspect`; com proporção travada, calcular o maior retângulo da proporção que cabe em torno do ponto fixo (canto oposto da alça, ou centro no zoom) antes de limitar. `edit.cropRect` = quadro × `rotatedSize`, com origem arredondada para baixo e tamanho arredondado para cima, depois limitado à imagem.

- [ ] **Step 4: Rodar e ver passar** (mesmo comando do Step 2). Expected: PASS, 11 testes.

- [ ] **Step 5: Commit** — `git add` dos três arquivos; mensagem `Feat: geometria de corte e rotação para o editor de foto`.

## Task 2: Girar e cortar os pixels

**Files:**
- Modify: `ZanzarProject/ZanzarProject/Features/UserPhotos/Utils/PhotoPreparer.swift`
- Modify: `ZanzarProject/ZanzarProject/Features/UserPhotos/Utils/PhotoProcessing.swift`
- Modify: `ZanzarProject/ZanzarProjectTests/UserPhotos/FakePhotoProcessing.swift`
- Test: `ZanzarProject/ZanzarProjectTests/UserPhotos/PhotoPreparerEditTests.swift`

**Interfaces:**
- Consumes: `PhotoEdit` (Task 1).
- Produces:
  - `PhotoPreparer.edit(_ image: CGImage, _ edit: PhotoEdit) async -> CGImage?` — `@concurrent static`. Devolve a própria `image` quando `quarterTurns == 0` e o corte é a imagem inteira; `nil` quando o retângulo é vazio ou não cabe na imagem girada.
  - `PhotoProcessing.edit(_ image: CGImage, _ edit: PhotoEdit) async -> CGImage?` e a implementação em `DevicePhotoProcessing`.
  - `FakePhotoProcessing`: `var editResult: CGImage? = FakePhotoProcessing.image`, `private(set) var appliedEdits: [PhotoEdit]`; `edit` registra o pedido e devolve `editResult`.

- [ ] **Step 1: Escrever os testes que falham** em `PhotoPreparerEditTests.swift`, com uma imagem de teste de 4×2 px feita no teste (lado esquerdo vermelho, direito azul; função auxiliar que lê o pixel `(x, y)` de um `CGImage` em RGBA):
  - `identityReturnsTheSameImage`: `edit(image, PhotoEdit(quarterTurns: 0, cropRect: 0,0,4,2))` devolve imagem de 4×2 (mesma instância não é exigida, só o tamanho).
  - `rotatesClockwise`: `quarterTurns: 1`, `cropRect: 0,0,2,4` → imagem 2×4 com o vermelho **em cima** e o azul **embaixo** (pixel `(0,0)` vermelho, `(0,3)` azul).
  - `cropsAfterRotating`: `quarterTurns: 1`, `cropRect: 0,0,2,2` → imagem 2×2 toda vermelha.
  - `halfTurnFlipsBothAxes`: `quarterTurns: 2`, inteiro → pixel `(0,0)` azul, `(3,1)` vermelho.
  - `rejectsAnEmptyOrOutOfBoundsRect` (revisão 4): `cropRect` de largura 0, e `cropRect: 3,0,4,2` (passa da borda) → `nil`.
  - `editedPhotoStillEncodesWithoutMetadata`: `PhotoPreparer.encode` do resultado não satisfaz `containsIdentifyingMetadata`.

- [ ] **Step 2: Rodar e ver falhar** (`-only-testing:ZanzarProjectTests/PhotoPreparerEditTests`). Expected: erro de compilação, `edit` não existe.

- [ ] **Step 3: Implementar** `PhotoPreparer.edit` (desenhar num `CGContext` RGBA do tamanho de saída com a transformação de rotação horária e recortar; ou girar com um contexto do tamanho girado e depois `cropping(to:)`), acrescentar `edit` ao protocolo `PhotoProcessing` e a `DevicePhotoProcessing`, e atualizar o `FakePhotoProcessing`. Manter o espaço de cor da imagem de entrada.

- [ ] **Step 4: Rodar e ver passar** (mesmo comando). Expected: PASS, 6 testes; o restante do alvo ainda compila.

- [ ] **Step 5: Commit** — mensagem `Feat: girar e cortar os pixels da foto antes do envio`.

## Task 3: Passo `editing` no ViewModel

**Files:**
- Modify: `ZanzarProject/ZanzarProject/Features/UserPhotos/ViewModels/PhotoUploadViewModel.swift`
- Modify: `ZanzarProject/ZanzarProjectTests/UserPhotos/PhotoUploadViewModelTests.swift`

**Interfaces:**
- Consumes: `PhotoProcessing.edit(_:_:)`, `PhotoEdit` (Task 2), `FakePhotoProcessing.appliedEdits` / `editResult`.
- Produces em `PhotoUploadViewModel`:
  - novo caso `Step.editing` e novo caso `Step.analyzing` (spinner enquanto edita e checa; a View o trata como `preparing`)
  - `private(set) var original: CGImage?` — a foto decodificada, sem edição, que o editor mostra
  - `func applyEdit(_ edit: PhotoEdit) async` — aplica o corte, roda conteúdo sensível e rostos sobre o resultado, vai a `preview` ou `faceWarning`, ou a `failed(.sensitiveContent)` / `failed(.unreadable)`
  - `func cancelEditing()` — igual a `chooseAnother()`
  - `func editAgain()` — só válido em `preview` e `faceWarning`: volta a `editing` com `original`, descarta `image` e a pixelização
  - `pick(_:)` passa a parar em `.editing` (com `original` preenchido) e **não** roda mais as checagens; `chooseAnother()` também zera `original`; `recover()` continua igual.

- [ ] **Step 1: Escrever os testes que falham** e ajustar os existentes. Nos testes que hoje fazem `pick` e esperam `.preview`/`.faceWarning`/`.failed(.sensitiveContent)`/`.sent` (`sendsPhoto`, `faceWarningThenBlur`, `chooseAnotherAfterFaceWarning`, `smallFacesAreFine`, `sensitiveContentIsRefused`, `analysisOffContinues`, `offlineThenRetry`, `duplicateGoesBackToChoosing`), acrescentar depois de `pick` uma chamada a um helper `pickAndEdit(_ viewModel:)` que faz `pick(Data([1]))`, confirma `.editing` e chama `applyEdit(PhotoEdit(quarterTurns: 0, cropRect: CGRect(x: 0, y: 0, width: 8, height: 6)))`. Os testes de erro de decodificação (`unreadableFiles`) continuam só com `pick`. Novos testes:
  - `pickStopsAtEditing`: `pick` leva a `.editing`, `original != nil`, `image == nil`, e `FakePhotoProcessing.faces(in:)` e o checador de sensível ainda não foram chamados (usar `sensitive: true` e confirmar que o passo **não** é `failed`).
  - `appliesTheEditBeforeTheChecks` (revisão 5): `applyEdit(edit)` registra `processing.appliedEdits == [edit]`, e as checagens rodam depois (com `processing.faces` com rosto grande o resultado é `.faceWarning`; sem rosto, `.preview`).
  - `sensitiveContentIsCheckedOnTheEditedPhoto` (revisão 5): com `sensitive: true`, `applyEdit` resulta em `.failed(.sensitiveContent)` e `image == nil`.
  - `failedEditIsUnreadable`: com `processing.editResult = nil`, `applyEdit` resulta em `.failed(.unreadable)`.
  - `cancelEditingGoesBackToChoosing`: `.choosing`, `original == nil`.
  - `editAgainStartsFromTheOriginal` (revisão 5): depois de `pick`, `applyEdit`, `blurFaces`, `editAgain()` leva a `.editing`, `original` segue o mesmo, `image == nil`, `hasBlurredFaces == false`, `faceCount == 0`; um novo `applyEdit` roda as checagens de novo (`processing.appliedEdits.count == 2`).
  - `editAgainIsIgnoredOutsidePreview`: em `.choosing`, `editAgain()` não muda o passo.

- [ ] **Step 2: Rodar e ver falhar** (`-only-testing:ZanzarProjectTests/PhotoUploadViewModelTests`). Expected: erro de compilação, `applyEdit`, `.editing` etc. não existem.

- [ ] **Step 3: Implementar** as mudanças em `PhotoUploadViewModel`. Mover para `applyEdit` o trecho de `pick` que checa conteúdo sensível e rostos (mesmos logs, `AppLog.userPhotos`); `applyEdit` põe `step = .analyzing` enquanto trabalha. Manter `PhotoPreparer.Failure.tooLarge` → `.tooLarge` em `pick`.

- [ ] **Step 4: Rodar e ver passar** (mesmo comando). Expected: PASS em todos os testes da suíte, os antigos e os 7 novos.

- [ ] **Step 5: Commit** — mensagem `Feat: passo de edição no envio de foto, com as checagens sobre a foto editada`.

## Task 4: Tela do editor e ligação na folha de envio

**Files:**
- Create: `ZanzarProject/ZanzarProject/Features/UserPhotos/Views/PhotoEditorView.swift`
- Create: `ZanzarProject/ZanzarProject/Features/UserPhotos/Views/Components/PhotoCropOverlay.swift`
- Modify: `ZanzarProject/ZanzarProject/Features/UserPhotos/Views/PhotoUploadSheet.swift`
- Modify: `ZanzarProject/ZanzarProject/Resources/Localizable.xcstrings`

**Interfaces:**
- Consumes: `PhotoCropGeometry` e `PhotoEdit` (Task 1); `PhotoUploadViewModel.original`, `applyEdit(_:)`, `cancelEditing()`, `editAgain()`, `Step.editing`, `Step.analyzing` (Task 3).
- Produces:
  - `PhotoEditorView(image: CGImage, onConfirm: (PhotoEdit) -> Void, onCancel: () -> Void)`: dono de um `@State var geometry: PhotoCropGeometry` criado de `image.width/height`.
  - `PhotoCropOverlay(geometry: Binding<PhotoCropGeometry>, imageFrame: CGRect)`: desenha escurecimento fora do quadro, bordas, grade de terços e as oito alças, e traduz arrastes para `geometry.drag/move`; a pinça (`MagnifyGesture`) chama `geometry.zoom(by:)`.

- [ ] **Step 1: Strings.** Acrescentar ao `Localizable.xcstrings` (mesmo formato de `userPhotos.upload.preview.anotherButton.title`: `extractionState` `manual`, `en` e `pt-BR` `translated`) as chaves abaixo, na ordem alfabética do catálogo:

  | Chave | en | pt-BR |
  |---|---|---|
  | `userPhotos.editor.title` | Adjust photo | Ajustar foto |
  | `userPhotos.editor.useButton.title` | Use photo | Usar foto |
  | `userPhotos.editor.cancelButton.title` | Cancel | Cancelar |
  | `userPhotos.editor.rotateButton.label` | Rotate | Girar |
  | `userPhotos.editor.resetButton.label` | Reset | Restaurar |
  | `userPhotos.editor.aspectMenu.label` | Shape | Formato |
  | `userPhotos.editor.aspect.free` | Free | Livre |
  | `userPhotos.editor.aspect.square` | 1:1 | 1:1 |
  | `userPhotos.editor.aspect.fourByFive` | 4:5 | 4:5 |
  | `userPhotos.editor.aspect.sixteenByNine` | 16:9 | 16:9 |
  | `userPhotos.editor.frame.accessibilityLabel` | Crop frame | Quadro de corte |
  | `userPhotos.editor.handle.accessibilityLabel` | Resize crop frame | Redimensionar o quadro de corte |
  | `userPhotos.editor.tooSmall.hint` | This photo is too small to crop. | Esta foto é pequena demais para cortar. |
  | `userPhotos.upload.preview.editButton.title` | Edit photo | Editar foto |

- [ ] **Step 2: Implementar `PhotoCropOverlay`** e **`PhotoEditorView`**. Barra de navegação com Cancelar (`cancellationAction`) e "Usar foto" (`confirmationAction`, chama `onConfirm(geometry.edit)`); barra inferior com girar, menu de formato (`ForEach(PhotoCropGeometry.AspectRatio.allCases)` com `Picker` ou `Menu`) e restaurar. Sem corte possível (`!geometry.canCrop`): esconder alças, desabilitar menu de formato e mostrar `tooSmall.hint`. Alvos de toque das alças de no mínimo 44 pt (área de toque maior que o traço desenhado). Acessibilidade: rótulos nos botões; o quadro com `accessibilityAdjustableAction` (incrementar/decrementar chama `zoom(by:)`) e `accessibilityLabel`. Duas previews SwiftUI (foto horizontal e foto pequena) usando um `CGImage` gerado no código. Imagem na tela via `Image(decorative:scale:)` ajustada ao espaço com `scaledToFit`; calcular `imageFrame` com o mesmo ajuste, depois da rotação (girar a imagem para exibição com `rotationEffect` só se girar o `CGImage` não for barato; caso contrário pedir `PhotoPreparer.edit` com quarto de volta para a pré-visualização).

- [ ] **Step 3: Ligar na `PhotoUploadSheet`.** Em `content`: `case .editing:` mostra `PhotoEditorView(image: original, onConfirm: { edit in Task { await viewModel.applyEdit(edit) } }, onCancel: viewModel.cancelEditing)` (com `if let original`); `case .analyzing:` junta-se a `.checkingTerms, .preparing` no spinner. Na `preview`, entre o botão de enviar e "Escolher outra", um `Button("userPhotos.upload.preview.editButton.title") { viewModel.editAgain() }` com `.buttonStyle(.bordered)`. Em `faceWarning`, o mesmo botão de editar abaixo de "Escolher outra". `interactiveDismissDisabled` passa a valer também em `.analyzing`.

- [ ] **Step 4: Compilar e checar a tela**

Run: `export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer && xcodebuild build -project ZanzarProject/ZanzarProject.xcodeproj -scheme ZanzarProject -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`
Expected: BUILD SUCCEEDED sem warnings novos. Depois, no simulador (XcodeBuildMCP `build_run_sim` e `mcp__Claude_Code_iOS_Simulator__control`): abrir um lugar → enviar foto → escolher da biblioteca; arrastar uma alça, pinçar, girar, trocar o formato, restaurar, "Usar foto" e ver a prévia; "Editar foto" na prévia volta ao editor com a foto original. Capturar uma tela do editor.

- [ ] **Step 5: Commit** — mensagem `Feat: tela de edição de foto (cortar, zoom e girar) no envio`.

## Task 5: Verificação final e documentação de teste

**Files:**
- Modify: `docs/fotos-de-usuario-teste-manual.md`
- Modify: `CLAUDE.md` (só a linha "Estado em …: build OK, N testes passando")

- [ ] **Step 1: Rodar tudo**

Run: `export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer && xcodebuild test -project ZanzarProject/ZanzarProject.xcodeproj -scheme ZanzarProject -destination 'platform=iOS Simulator,name=iPhone 17 Pro'` e `swiftlint lint`
Expected: 0 falhas; contagem de testes = 231 + os novos (11 + 6 + 7); `swiftlint` sem violações novas.

- [ ] **Step 2: Rodar os casos de borda no simulador**: câmera (foto nova → editar → usar); foto com rosto grande cortada até virar destaque (deve cair em `faceWarning`); foto pequena (travada, sem alças); girar quatro vezes; cancelar volta à escolha.

- [ ] **Step 3: Documentar.** Em `docs/fotos-de-usuario-teste-manual.md`, acrescentar os casos acima como roteiro manual do editor. Atualizar em `CLAUDE.md` a linha do estado com a data de hoje e a nova contagem de testes.

- [ ] **Step 4: Commit** — mensagem `Docs: roteiro manual do editor de foto e estado dos testes`. Abrir o PR contra `develop` (a branch parte de `fix/keyboard-focus`, que está um commit à frente de `develop`).

---

## Preparação (antes da Task 1)

Criar a branch `feat/photo-editor` a partir do `HEAD` atual (`fix/keyboard-focus`, um commit à frente de `develop`) e incluir nela, no primeiro commit, o spec e este plano: `git switch -c feat/photo-editor && git add docs/superpowers && git commit -m "Docs: design e plano do editor de foto"`.
