# Auditoria completa do app × Figma + caça a bugs — 2026-11-26

Complementa `docs/AUDITORIA-FIGMA-2026-11-26.md` (que cobre o que está conforme ao Figma e as divergências de design a–k).
Aqui: o que foi feito nesta rodada, os bugs encontrados, o que foi corrigido e o que ficou de fora.

Ambiente: `develop` com merge de `origin/develop` (PRs #117 e #118 de acessibilidade), backend em `develop` (#73, #74),
iPhone 17 / iOS 27.2, backend local contra o Atlas dev, conta de teste criada só para isto.
Linha de base: 830 testes do app e 427 do backend, todos passando. Depois das correções: 836 testes do app passando,
`swiftlint` sem violações novas, `scripts/check-app-content.mjs` ok.

## Verificado ao vivo nesta rodada

Busca do mapa (resultado, sem resultado, erro), detalhe do lugar (inclusive a seção nova de acessibilidade), check-in
(confirmação → selo conquistado → botão "Check-in feito"), "longe demais", salvar/remover (toasts), "Adicionar foto" (permissão de
câmera negada → alerta com Ajustes), alertas de apagar conta e sair, sair da conta, login com senha errada, cadastro
(campos inválidos, aceite dos termos, conta criada), onboarding completo (avatar → passaporte → notificações → mapa),
deep links `lero://place/<id>` (válido e inválido), Roteiros e Perfil com o backend desligado, Dynamic Type XXXL em 3 telas,
modo escuro (o app é fixo em claro de propósito, `ContentView.swift`).

## Bugs corrigidos (3 commits em `fix/auditoria-completa`)

| # | Bug | Como se viu | Correção |
|---|---|---|---|
| 1 | **O token de push nunca era registrado.** O único ponto de registro ficava num `onChange(isAuthenticated)` que saía cedo porque o onboarding já estava ativo (login e cadastro chamam `begin()` antes de entrar). | Leitura do código + log do backend: 0 chamadas `device-token` em toda a sessão; depois da correção, `POST /user/:id/device-token 204` ao abrir o app | `ContentView`: `.task(id: showsMainApp)`. Também deixou de pedir permissão sozinho (quem escolheu "Agora não" não recebe o prompt do sistema no próximo lançamento) |
| 2 | Botão "Voltar" no editor de avatar do onboarding levava ao Welcome com sessão ativa; relançar o app pulava avatar, passaporte e notificações | Ao vivo | Botão escondido no onboarding (`AvatarEditorView`). **Não revalidado ao vivo depois da correção** |
| 3 | Botão do alerta "Sessão expirada" dizia **"Marcado"** | Leitura do catálogo | "OK" |
| 4 | Detalhe do lugar com erro: sem "Tentar novamente"; descrição mostrava a chave crua (`Text(a ?? "chave")` não localiza) | Ao vivo (backend desligado + deep link) | Botão de retry, texto via `L10n`; igual no detalhe do roteiro |
| 5 | Erro sem texto (500 vazio, resposta ilegível) mostrava "The operation couldn't be completed. (…APIError error 1.)" em check-in, avaliação e detalhe | Leitura do código | `APIError.displayMessage` + chave `error.generic.message`; 3 testes |
| 6 | Aviso de foto/sugestão **não aprovada** saía com o toast verde de sucesso | Leitura do código | `StatusNotice` carrega o estilo; "não aprovada" usa o toast negativo |
| 7 | `Dictionary(uniqueKeysWithValues:)` nos avisos de revisão derruba o app com id repetido | Leitura do código | `uniquingKeysWith`; teste |
| 8 | Estado dos avisos de revisão ficava no aparelho: a próxima conta era comparada com a anterior | Leitura do código | `clear()` nos dois stores e no `PendingRating` ao sair da conta; 2 testes |
| 9 | Widget com build 1 e app com 7: o Xcode avisava `CFBundleVersion of an app extension must match` e o upload ao App Store seria recusado | Aviso do build | `CURRENT_PROJECT_VERSION = 7` no widget |
| 10 | Dica do passaporte: "Seu passaporte **Zanzar**" (o produto é Lero) | Ao vivo | "Lero" |
| 11 | Cadastro logava o id do usuário (regra do CLAUDE.md) | Leitura do código | Removido |

Suspeitas do levantamento estático que **não se confirmaram**: chaves `placeSuggestion.*Alert.*` e `accessibility.checked`
"sem tradução" (têm en e pt-BR); só `accessibility.checked` diz "Marcado", o que está certo para VoiceOver.

## Encontrado e **não** corrigido

Precisa de decisão de design/produto ou é maior que um conserto:

- **Check-in "longe demais"**: a confirmação aparece antes e só depois vem o aviso, mesmo com a distância ("a 3,5 km") já na tela.
- **Idioma**: o app é sempre pt-BR; os avisos do sistema (permissões) seguem o idioma do aparelho. Em aparelho em inglês mistura os dois.
- **Dynamic Type XXXL**: "Aberto 24 h…" cortado no detalhe; o texto do slot vazio de Roteiros (`CheckInEmptySlot`, `.system(size: 11)`) não cresce.
- **`try?` que escondem falha**: `AllPlacesView` (falha ou localização negada vira "nenhum lugar"), `OnboardingGate` (erro ao buscar avatar = "tem avatar"),
  `MyPhotosViewModel.load` (spinner eterno se não houver id de usuário).
- Cadastro: botão "Criar conta" fica apagado sem dizer por quê com o formulário vazio; o erro de e-mail traz "exemplo@email.com" como link.
- Legenda de foto lida como "Fer14041978,  · CC BY-SA 3.0" (vírgula e espaço duplo quando não há título).
- Divergências de design a–k e os casos do catálogo "Fluxo e erros" que não existem (E4, E5, E6, D2, G3): ver a auditoria anterior.
- Fotos de usuário: estado dos avisos continua sem chave por usuário (só é apagado ao sair da conta).

## Segunda rodada: itens que precisavam de decisão

| Item | O que foi feito |
|---|---|
| Perfil com falha de carga sem "Sair da conta" | O estado de erro ganhou o botão "Sair da conta" (mesmo alerta de confirmação). Conferido ao vivo com o backend desligado: sai e volta ao Welcome |
| Descobrir sem rede | Banner fixo sob a busca com a mensagem e "Tentar de novo" (`MapLoadFailureBanner`); substitui o toast. Conferido ao vivo: fica na tela, e o retry recarrega os pins |
| Dicas (TipKit) | Removidas as 3 do onboarding (repetiam o texto da tela e cobriam o Voltar); as da folha de foto viraram `TipView` em linha (e a de "Tire uma foto" estava presa ao botão errado); a de "Adicionar foto" do detalhe passa a abrir acima, sem cobrir o check-in. Conferido ao vivo: o Salvar do avatar responde ao primeiro toque. **As outras dicas continuam em popover** (descrevem o botão onde estão) e o primeiro toque fora delas só as fecha: é o comportamento do sistema |
| Voltar do passaporte lido como "Tom de pele" | Botão próprio com o rótulo "Voltar". Só compilado; não conferido ao vivo |
| "Parque Barigui" duplicado | São dois place_ids do Google: o do endereço (32 check-ins, 77 mil avaliações) e um `natural_feature` a 455 m (0 check-ins, nenhuma referência em checkins, rating ou itinerários). Removido de `lugares.json`, `apple-place-ids`, `place-images` e `place-accessibility` no backend (branch `fix/parque-barigui-duplicado`, 427 testes passam). **Falta tirar do Atlas e do CacheGoogleMaps**, senão o `sync:lugares` o traz de volta |

## Não verificado

- **Redefinir senha completo**: o backend local não tem `RESEND_API_KEY`, então o passo 1 responde 503; os passos seguintes só pelos testes.
- **Localização negada / sem sinal**: em Debug no simulador a posição é fixa (`DevLocation`), então não há como exercitar; só pelos testes.
- Extensão de compartilhar, widget, notificação de proximidade, alertas de roteiro concluído, avaliação, upload de foto
  (só até a escolha da fonte), iPad e iPhone pequeno.
- Backend: `npm test` e `typecheck` passam; não foi auditado além do contrato usado pelo app.

## Dados criados no Atlas dev

Conta `auditor.lero.1126@example.test` (nome "Auditor Lero"), 1 check-in novo na conta de teste anterior (Museu da Fotografia, 2 → 3).
