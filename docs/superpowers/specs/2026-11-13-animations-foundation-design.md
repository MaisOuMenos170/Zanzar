# Animações do Lero: fundação e método (design curto)

Branch: `feat/animations` (saindo da `develop`). Data: 2026-11-13.

## Intenção

Deixar o app mais bonito com movimento e haptics, sem virar carnaval. Hoje o app tem boa animação em poucos pontos (o carimbo, os toasts, os contadores) e quase nenhuma no resto. Cada tela escolheu a sua curva (`.default`, `.smooth` com 0.25, 0.3, 0.35 e 0.45, `.spring` com bounces diferentes), então não existe uma linguagem de movimento.

A personalidade escolhida pelo usuário: **o carimbo é a assinatura do app**. Movimento tátil, com peso, de papel e tinta; o resto do app fala uma versão mais discreta da mesma língua. Haptics fazem parte do pacote, não são enfeite.

## Objetivos

- Uma linguagem pequena de movimento e haptics, usada por todas as telas.
- Passar pelo app inteiro, por jornada, decidindo com o usuário os momentos que merecem movimento.
- Telas novas já nascerem na linguagem.

## Não objetivos

- Não redesenhar telas nem mudar fluxos.
- Não animar tudo: ação de alta frequência fica quase invisível; o encanto cresce quanto mais rara a ação.
- Não adicionar dependências (o projeto não tem nenhuma).

## Anti-objetivos (seria fracasso mesmo funcionando)

- Parecer carnaval: bounce exagerado, partículas, loops, tudo se mexendo ao mesmo tempo.
- Movimento que atrasa a tarefa: foco, digitação e navegação repetida continuam imediatos.
- Perder o respeito ao "Reduzir Movimento" (hoje todo o app respeita; isso não pode regredir).
- Vibrar a cada toque: haptic só onde confirma algo que importa.

## Restrições

- SwiftUI, iOS 26, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` (tipos novos usados fora da main thread levam `nonisolated`).
- Texto visível via `L10n`; logs via `AppLog`.
- Animar `transform` e `opacity` (scale, offset, rotation, opacity); evitar animar layout caro.
- Reduzir Movimento troca deslocamento por mudança imediata ou fade curto. Haptics seguem a configuração de haptics do sistema, não a de Reduzir Movimento.
- O carimbo existente (`PaperStampPhase`, `PaperStampPress`) já tem a regra "sem bounce, partículas ou loop". Ela continua valendo.

## Abordagens consideradas

- **A. Fundação primeiro, depois tela a tela.** Escolhida pelo usuário. Consistência desde o começo, ao custo de um passo inicial com pouco para ver.
- B. Tela a tela direto, extraindo curvas no final. Beleza mais cedo, mas repete o problema atual.
- C. Por tipo de momento (entradas, feedbacks, celebrações). Consistente, mas ruim para decidir olhando uma tela de cada vez.

## A fundação (propostas minhas, a confirmar)

**`Utils/Motion.swift`**: curvas com nome, em vez de números soltos nas telas. Proposta inicial de 4:

| Nome | Para quê | Base |
|---|---|---|
| `toque` | resposta a toque (pressionar, selecionar) | curta, ~0.15s, easeOut |
| `suave` | fades e trocas de conteúdo | `.smooth` ~0.25s |
| `assentar` | elementos que chegam e param (cards, sheets, pins) | `.smooth` ~0.35s |
| `carimbo` | o carimbo e celebrações | easeOut atual do carimbo |

Mais um modificador que embute a leitura de `accessibilityReduceMotion`, para trocar o padrão repetido `reduceMotion ? nil : ...` em cada tela por uma chamada só.

**`Utils/Haptic.swift`**: vocabulário sobre `sensoryFeedback`, com nomes que dizem a intenção: `carimbo` (impacto rígido, hoje 0.7), `carimboLeve` (hoje 0.55), `selecao`, `sucesso`, `alerta`, `toqueSuave`.

**Aplicação inicial**: migrar a família do carimbo (check-in, selo, roteiro, passaporte) para os nomes novos, sem mudar o visual. Isso prova a fundação e tira os números soltos. Depois seguimos pelas jornadas.

## Método tela a tela

Ordem proposta por jornada: (1) primeiro uso: Welcome, Login, Cadastro, Passaporte; (2) mapa e Descobrir; (3) detalhe do lugar e check-in; (4) roteiros; (5) perfil; (6) fotos e sugestões.

Em cada tela: eu proponho 2 ou 3 momentos (o que se mexe, por quê, qual curva e qual haptic), o usuário escolhe, eu implemento, e conferimos no simulador. Cada tela vira um passo pequeno e revisável.

## Fica com quem implementa

- Valores exatos de duração e intensidade das curvas e haptics (partindo dos atuais, ajustando no simulador).
- Se o modificador de movimento é `ViewModifier` ou extensão de `View`.
- Testes: os tokens são constantes, então não precisam de teste próprio; a validação é no simulador e a suíte existente (541 testes) precisa continuar verde.
