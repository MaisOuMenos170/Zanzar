# Formato do Relatório

Load this file during Step 4 before writing output.

## Template

```markdown
# Avaliação do Boilerplate — ZanzarProject

**Escopo:** ZanzarProject/
**Área:** {area}
**Data:** {date}
**Modo:** {full | quick — assumptions flagged}

## Visão do produto (contexto)

{What Zanzar is — from user or **Assumption:** ...}

## Mapa da estrutura

{Tree or table: path → role → generic | zanzar-specific}

## Resumo executivo

{2–4 sentences: overall readiness, top blocker, recommended next structural step}

## Achados

### P0 — Crítico
| Local | Problema | Impacto |

### P1 — Alto
| Local | Problema | Impacto |

### P2 — Médio
...

### P3 — Baixo
...

## Prontidão para feature (se aplicável)

**Feature:** {user question}
**Veredito:** {Ready | Blocked | Partial}
**Bloqueios:** ...
**Pré-requisitos estruturais:** ...

## Opções de melhoria

### {Gap title}

**Opção A — Mínima** (Effort: S)
- What: ...
- Why: ...
- Trade-off: ...

**Opção B — Recomendada** (Effort: M)
- What: ...
- Why: ...
- Trade-off: ...

**Opção C — Ideal** (Effort: L) *(omit if no third path)*
- What: ...
- Why: ...
- Trade-off: ...

## Assunções

{List items marked Assumption when vision was inferred}

## Próximo passo sugerido

{Single clearest action — still no file changes in this run}
```

## Style rules

- Cite paths like `ZanzarProject/ZanzarProject/ContentView.swift`
- Cite build settings like `IPHONEOS_DEPLOYMENT_TARGET` (app: 26.0, tests: 17.0)
- Prefer tables for findings; prose for trade-offs
- Write in the user's language (PT-BR or EN)
- Do not include implementation diffs — describe changes in words only
