# Auditoria do app × Figma (página "Handoff") — 2026-11-26

Figma: `Macro Challenge`, página Handoff (`1193:2`), mais as páginas "Fluxo e erros" e "Style Guide".
App: branch `develop`, iPhone 17 (iOS 27.2, 402×874 pt; os frames do Figma são 393×852), backend local apontando para o Atlas.

## Verificado ao vivo e conforme ao Figma

Boas-vindas, Login, Cadastro, Roteiros (home, Todos os lugares, detalhe do roteiro), Detalhe do lugar (inclusive placeholder
sem foto), confirmação e resultado do check-in, Descobrir (pins, clusters, filtro, busca, estado sem resultado, card
"Sugerir um lugar"), Perfil (passaporte, Todos os selos, Todos os check-ins, Lugares salvos, Ajustes, menu de editar),
editor de avatar, toast de erro ("Email ou senha incorretos."), alertas de sair, apagar foto e check-in.

## Corrigido nesta rodada (sem commit)

1. **Lista com falha mostrava estado vazio.** Minhas sugestões, Perfis bloqueados e Minhas fotos mostravam "Nenhuma sugestão
   ainda" / "Você não bloqueou ninguém." depois de um erro de rede. Agora mostram o mesmo estado de erro com "Tentar novamente"
   que Salvos, Check-ins e Roteiros já usavam (`ListLoadFailedView`, novo).
   Validado ao vivo derrubando o backend: as três telas mostram "Não foi possível carregar" + "Tentar novamente", e a
   recuperação carrega a lista (Minhas sugestões voltou com as 2 sugestões). O título genérico é `list.loadFailed.title`
   (o primeiro título reaproveitado dizia "seu perfil"); a mensagem de Minhas fotos não manda mais "puxar para baixo".
2. **Editor de avatar podia sobrescrever o avatar real.** Se a carga falhasse (não 404), o editor abria com o rosto padrão; ao
   salvar, `createAvatar` → 409 → `updateAvatar` gravava o padrão por cima. Agora `save()` tenta carregar de novo e recusa salvar
   se não conseguir. Dois testes novos.
3. **Título do alerta de check-in**: "Fazer Check-in" → "Fazer check-in" (igual ao botão).
4. **Cor dos alertas (item d da tabela abaixo).** As telas abertas pela aba Roteiros agora herdam `.brandBlue600` em vez do
   laranja antigo (`MainTabView.swift`). Validado ao vivo: o alerta de check-in sai com botões azuis e o título "Fazer check-in".
   Efeito colateral possível: controles sem cor explícita nessas telas deixam de ser laranja.

Testes: 819 passando, 0 falhas. `swiftlint` limpo nos arquivos tocados.

## Divergências que dependem de decisão

| # | Figma | App |
|---|---|---|
| a | 3 abas (Descobrir, Check in, Perfil) e botão flutuante "+" no mapa para sugerir | 4 abas; "Sugerir lugar" é uma aba (`role: .search`) visível só no Descobrir |
| b | Aba "Check in", título "Check-in" (o frame mais novo também usa "Roteiros") | Aba e título "Roteiros" |
| c | Subtelas sem barra de abas; Detalhe do lugar com barra | Subtelas com barra; Detalhe do lugar sem barra (`PlaceDetailView.swift:63`) |
| d | Alertas com botão índigo | Telas empilhadas pela aba Roteiros herdam `.tint(Color("TabBarSelected"))` (#FF8D28, laranja): o alerta de check-in sai laranja (`MainTabView.swift:315`). No Perfil já é índigo |
| e | Arte final só para Parques, Restaurante, Museus e Centro | As outras 6 categorias (Bar, Café, Curiosidade, Histórico, Festas, Ponto turístico) usam o selo verde genérico de 21/10 |
| f | Nuvens brancas atrás da personagem na tela inicial (`2702:15779`) | Sem nuvens; não há asset no projeto |
| g | "Minhas fotos" com chips de filtro | Só busca |
| h | Redefinir senha: template em inglês ("SkillSangrah", OTP por telefone) | Fluxo próprio em pt-BR (e-mail + código) |
| i | Login com campo "Nome", sem "Esqueceu a sua senha?" | Sem "Nome", com o link |
| j | Ajustes: "Contato de suporte — Em breve", sem "Abrir ajustes" nem "Política de privacidade" | E-mail de suporte + os dois extras |
| k | Sem frame para a página "Fotos e privacidade" nem para a tela "Buscar lugar" | As duas existem |

Erros de texto no próprio Figma: "Todas as lugares salvos", contador "5 fotos" em Lugares salvos, "0 perfis" (o app mostra "0 perfil"
porque a regra de plural do pt trata 0 como singular).

## Catálogo "Fluxo e erros" (22 casos) × app

O app cobre, com outro texto: credenciais inválidas, muitas tentativas, e-mail já cadastrado, sessão expirada, localização
negada, longe demais, falha do perfil, roteiro indisponível. **Não existe no app**: fila local de check-in offline (E5),
"já fez check-in hoje" (E4), "Avisar quando abrir" (E6), GPS impreciso (D2), aviso ao sair com check-in pendente (G3) e
mascote nos estados de erro e vazio. O texto do catálogo é diferente do texto do app em todos os casos.

## Observações menores

- Nomes longos são cortados nos cards de "Lugares próximos" ("Museu da Fotogra…").
- O toast "Não foi possível carregar os lugares" aparece por cima do Perfil.
- Com o perfil falhando, o Ajustes (e "Sair da conta") fica inacessível.
- Card "Sugerir um lugar": entre o último campo e "Descrição (opcional)" o espaço parece ~6 pt, menos que os 16 pt do resto.
  Pode ser animação em curso na captura; verificar.
- Placeholder do nome: "Ex: Jardim Botânico" (Figma: "Nome").

## Não verificado

Onboarding (passaporte, criar avatar, permissão de notificações) e cadastro completo: exigem criar conta. Redefinir senha
(código por e-mail). Alertas de selo, roteiro concluído e avaliação (exigem check-ins reais e sair do local). Upload e
visualizador de fotos, extensão de compartilhar, widget, prompt de proximidade. Toast "Sugestão enviada!": não enviei para não
criar lugar no banco.

## Ambiente

O Atlas (`:27017`) ficou inacessível a partir de ~15:04 (IP público 200.192.117.11) e o backend passou a responder 500. Voltou
sozinho depois, quando o IP público mudou (104.28.207.239); nenhuma lista de acesso foi alterada.
Efeito colateral nos dados: 1 check-in em "Al Beek" na conta de teste (8 → 9). Backend local parado e `Config.xcconfig`
restaurado ao valor original (que aponta para um túnel Cloudflare que não responde).
