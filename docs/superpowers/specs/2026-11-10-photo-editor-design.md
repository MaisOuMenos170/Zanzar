# Editor de foto antes do envio — design

Data: 2026-11-10. Tamanho: mudança pequena a média (uma tela nova, um tipo de geometria, um passo novo no fluxo).

## Intenção

Quem envia a foto de um lugar (`PhotoUploadSheet`) deve poder ajustá-la antes de enviar: **cortar, dar zoom e girar**. Hoje a foto escolhida (biblioteca ou câmera) vai direto para as checagens no aparelho e para a prévia, e a única saída é escolher outra. Uma foto boa mas mal enquadrada acaba descartada, ou enviada torta.

## Objetivos

- Cortar com um quadro de alças, com atalhos de proporção: livre, 1:1, 4:5, 16:9.
- Zoom por pinça e mover o quadro arrastando.
- Girar 90° por vez, desfazer tudo (voltar ao original) e confirmar ou cancelar.
- Funciona igual para foto da biblioteca e da câmera.

## Não objetivos

- Filtros, brilho, contraste, texto, desenho. Só geometria.
- Editar fotos já enviadas.
- Dependências de terceiros (o projeto não tem nenhuma).

## Anti-objetivos (seria falha mesmo funcionando)

- Contornar as checagens de privacidade: conteúdo sensível e rostos têm de ser medidos na imagem que **realmente vai ser enviada**, não na original.
- Deixar sair uma foto que o backend vai recusar sem avisar (ver restrições).

## Restrições encontradas

- O backend recusa foto cujo **lado menor tem menos de 320 px** (`MIN_SIDE_PIXELS`, `image_too_small`; o app mapeia para `.unreadable`). O corte não pode deixar o lado menor abaixo disso.
- O app já limita a 2048 px de lado maior e reencoda sem metadados (`PhotoPreparer`). Cortar só reduz; nada disso muda.
- `FacePolicy` mede o rosto como fração da área da foto. Um corte aumenta essa fração, então um rosto que não alertava pode passar a alertar. Por isso as checagens rodam depois da edição.
- Texto visível passa por `Localizable.xcstrings` (en + pt-BR) e `L10n`. Logs por `AppLog`. Tipos usados fora da main thread levam `nonisolated`.

## Abordagens consideradas

1. **SwiftUI puro, quadro com alças (escolhida).** A conta de corte e rotação fica num tipo puro e testável; segue o padrão SwiftUI do projeto. Custo: gestos feitos à mão, com limites bem tratados.
2. `UIScrollView` embrulhado: zoom e inércia nativos, mas mistura UIKit, é mais difícil de testar e mais chato com isolamento de ator.
3. Quadro fixo estilo foto de perfil: o mais simples, mas sem corte livre.

O usuário delegou a escolha ("o que for o melhor"); a 1 foi a recomendada.

## Design

**Fluxo.** Novo passo `editing` em `PhotoUploadViewModel.Step`:

```
choosing → preparing (decodifica e reduz a 2048 px) → editing
        → [confirmar] analyzing (conteúdo sensível, rostos) → preview | faceWarning | failed
        → [cancelar] choosing
```

`pick(_:)` passa a parar em `editing` depois de decodificar. A checagem de conteúdo sensível e a de rostos saem de `pick` e vão para um método novo (`applyEdit(_:)`), que recebe a imagem já editada. O ViewModel guarda a imagem decodificada **sem edição** (`original`), para que o usuário possa voltar a editar a partir dela.

**Editar de novo.** A prévia ganha um botão "Editar". Ele volta ao passo `editing` com o `original` (antes de qualquer pixelização) e, ao confirmar, repete as checagens. Decisão minha: sem isso, um corte ruim só se corrige escolhendo outra foto.

**Geometria (tipo puro).** `PhotoCropGeometry` (`nonisolated`, `Sendable`, sem SwiftUI):

- estado: quartos de volta (0 a 3), retângulo de corte normalizado no espaço da imagem já girada, proporção travada opcional;
- operações: arrastar alça (canto ou borda) respeitando a proporção, mover o retângulo, zoom (escala o retângulo em torno do centro), girar 90°, reiniciar;
- invariantes: o retângulo nunca sai da imagem e o lado menor do corte nunca fica abaixo de 320 px de imagem (convertido para fração pela dimensão atual);
- saída: o retângulo em pixels, para `CGImage.cropping(to:)`.

**Pixels.** Girar e cortar acontecem em uma função `@concurrent` ao lado de `PhotoPreparer`, que devolve um `CGImage` novo. Entra no protocolo `PhotoProcessing` (e no `FakePhotoProcessing`) para o ViewModel continuar testável sem imagens.

**Tela.** `PhotoEditorView`, com subviews em `Views/Components/`: a foto ajustada ao espaço, fora do quadro escurecido, alças nos cantos e nas bordas. Barra com girar, proporção (menu), reiniciar. Cancelar e "Usar foto" na barra de navegação. VoiceOver: rótulos nos botões e nas alças, e ações de acessibilidade (ajustável) para mover e dimensionar sem arrastar.

**Zoom e arraste, como decidi.** Com o quadro sobre uma foto fixa: pinça escala o quadro em torno do centro (zoom in = quadro menor), arrastar dentro do quadro o move, as alças o redimensionam. Girar reinicia o quadro para a foto inteira (decisão minha: mapear o quadro pela rotação não vale a complexidade).

**Foto menor que 320 px de lado.** O editor abre, o corte fica travado (não dá para reduzir) e o usuário pode só girar ou usar como está, e o backend recusa como hoje. Decisão minha: a mensagem de "foto pequena demais" não está no escopo.

## Ficam para quem for construir

- Visual exato das alças, do escurecimento e das animações.
- Chaves e textos em `Localizable.xcstrings` (en + pt-BR).
- Tamanho mínimo de toque das alças (44 pt) e comportamento com Dynamic Type.
- Testes: geometria (limites, proporção travada, mínimo de 320 px, rotação) e ViewModel (novo passo, checagens rodam sobre a imagem editada, cancelar, editar de novo), em Swift Testing, com fakes em `TestHelpers/`.

## Verificação

`xcodebuild test` no scheme `ZanzarProject` e `swiftlint lint`. Depois, no simulador: biblioteca e câmera, girar, cortar, foto com rosto cortada até o rosto virar destaque (deve cair em `faceWarning`).
