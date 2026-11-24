# Fotos de usuário: teste de ponta a ponta no simulador

Feito em 2026-11-04 e 2026-11-05, num iPhone 17 Pro do simulador (iOS 26). Nada usou o Atlas nem o Railway:

- **Banco:** MongoDB temporário só nesta máquina, com os 68 lugares do `data/lugares.json`.
- **Backend:** rodando localmente, com as fotos numa pasta (`PHOTO_STORAGE=disk`).
- **Camada de visão:** o mesmo Mistral Small 3.1 do Cloudflare, rodando no Ollama do Mac.
- **Contas:** duas de teste. A envia e revisa (está em `ADMIN_USER_IDS`); B só vê.

As capturas estão em [`capturas-fotos-de-usuario/`](capturas-fotos-de-usuario/).

## O que foi verificado

| # | Passo | Resultado | Captura |
|---|---|---|---|
| 1 | Check-in no Al Beek | Servidor respondeu 201 e o selo apareceu | — |
| 2 | "Adicionar foto" mostra o termo antes do primeiro envio | Textos em pt-BR, data de nascimento e duas opções obrigatórias | 01, 03 |
| 3 | Aceite do termo | Banco guarda a versão `2026-11-03`, a data do aceite e `isAdult: true`. **Não guarda a data de nascimento** | 03 |
| 4 | Perfil ganha a seção Fotos | "Minhas fotos" e "Fotos e privacidade" | 02 |
| 5 | Escolher foto, com o aviso de check-in | "a foto vai aparecer como tirada num check-in" | 04 |
| 6 | "Tirar foto" pede a câmera com o texto novo; negar mostra a explicação e "Abrir Ajustes" | OK | 05, 06 |
| 7 | Galeria abre sem pedir permissão (seletor privado do iOS) | OK | 07 |
| 8 | Prévia de um prato, sem aviso de rosto | OK | 08 |
| 9 | Envio, e a tela mostra "Foto em análise" | 201. O arquivo guardado tem 640×480 e nenhum GPS, modelo ou data (`sips -g all`) | 08, 09 |
| 10 | Moderação automática | As 5 camadas passaram e a foto foi aprovada sozinha, em cerca de 60 s com o Mistral local | — |
| 11 | Carrossel do autor | Foto curada primeiro, depois "✓ Sua foto" | 10 |
| 12 | Selfie com duas pessoas | Aviso "Tem um rosto em primeiro plano" com as duas opções | 11 |
| 13 | "Borrar os rostos" | Os dois rostos pixelados, com aviso para conferir | 12 |
| 14 | Envio anônimo | A IA ainda viu pessoas em destaque e a foto foi para revisão (`needs_review`, `face_prominent`) | — |
| 15 | Página `/admin` | Login da equipe, fila com foto, lugar, autor, motivo e o resultado de cada camada | 13 |
| 16 | Aprovar pela fila | Foto publicada; auditoria `reviewed admin needs_review->approved` | — |
| 17 | Print de documento | Foi para revisão por "dados pessoais"; reprovado pela fila, sem cópia pública | — |
| 18 | Tirar do ar uma foto publicada (reprovar pela fila) | Cópias públicas apagadas; ela some da lista pública | — |
| 19 | Aviso ao voltar ao app | "1 foto sua não foi aprovada. Veja o motivo em Perfil > Minhas fotos." | 14 |
| 20 | Minhas fotos | Situação e motivo em linguagem simples para cada foto | 15 |
| 21 | Apagar a própria foto | Confirmação. O registro e os 2 arquivos somem; evento `deleted_by_author` | — |
| 22 | Conta B vê a foto aprovada da autora | "✓ Foto de autora_teste" com menu ••• | 16, 17 |
| 23 | Denunciar com motivo e "bloquear também" | Denúncia `not_the_place` registrada e bloqueio salvo; a foto da autora some para B | 18, 19 |
| 24 | "Fotos e privacidade" lista a bloqueada; desbloquear | `DELETE …/blocks` 204, lista vazia | 20 |

## Erros que o teste achou e já foram corrigidos

1. **Os textos do termo apareciam como chave** (`userPhotos.terms.review.title`). A chave era montada por interpolação, o que vira chave de formato (`%@`).
2. **Data de nascimento parecia preenchida, mas não contava.** O botão não liberava até a pessoa mexer na data. Agora ela toca em "Informar data de nascimento", e o seletor aparece em roda, na própria tela.
3. **O aviso de rosto não disparava:**
   - O Vision falha no simulador, e o detector agora tenta de novo na CPU.
   - As caixas de rosto do Vision são menores que as do servidor. O limite do aparelho foi medido de novo e passou para 0,5% da área: fotos de lugares deram 0 rostos, e a selfie de duas pessoas deu 0,83%.
4. **"Apagar" e "Bloquear" não faziam nada.** O alerta limpava a foto escolhida antes de o botão rodar. Agora o alerta entrega a foto direto ao botão.
5. **Sem aviso para fotos enviadas na mesma sessão.** O app só avisava sobre fotos que já tinha visto antes. Agora guarda também quando checou pela última vez.

## O que não foi coberto aqui

- **Câmera de verdade e HEIC do iPhone:** ver `fotos-de-usuario-teste-manual.md`.
- **SensitiveContentAnalysis:** precisa do entitlement e de um aparelho com o aviso ligado.
- **Cloudflare e Supabase de verdade:** o caminho testado foi Ollama mais pasta local, porque as contas ainda não existem.
- **Três denúncias tirando a foto do ar:** está nos testes automáticos do backend, não foi feito no app.
- **Exclusão de conta com fotos:** está nos testes automáticos do backend, não foi feito no app.
- **Envio com o app em segundo plano.**
