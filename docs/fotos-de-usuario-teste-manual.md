# Roteiro de teste manual (iPhone real)

Estes itens o simulador não cobre. Use um iPhone com iOS 26 e um build Debug apontando para um backend de teste. **Não use a base de produção.**

## Preparar

1. No backend de teste, configure:
   - `PHOTO_STORAGE=supabase` e as variáveis `SUPABASE_*`, ou deixe `disk` se o iPhone acessar o computador pelo túnel;
   - `VISION_API_URL`, `VISION_API_KEY` e `VISION_MODEL` do Cloudflare;
   - `ADMIN_USER_IDS` com o id da sua conta de teste.
2. Use duas contas de teste: A envia, B vê e denuncia.

## Câmera e permissões

1. **Primeiro pedido:**
   1. Em um lugar, toque em "Adicionar foto", aceite o termo e depois toque em "Tirar foto".
   2. Confira se o iOS mostra o texto de `NSCameraUsageDescription` em português.
   3. Negue a permissão. O app deve dizer que não tem acesso, oferecer "Abrir Ajustes" e continuar deixando escolher da galeria.
2. **Depois de liberar em Ajustes:** tire uma foto. Ela deve aparecer na prévia.
3. **Câmera bloqueada:** em Ajustes > Tempo de Uso > Restrições de Conteúdo e Privacidade, bloqueie a câmera. O app deve mostrar a mensagem de câmera bloqueada.

## Formatos e metadados

1. Escolha da galeria uma foto **HEIC** recente, com localização ligada na câmera. Ela deve ser enviada.
2. No backend, baixe o arquivo guardado e rode `exiftool` (ou `sips -g all`) nele. **Não pode haver GPS, modelo do aparelho nem data.**
3. Escolha uma captura de tela PNG. Ela deve passar pelo aparelho, mas a análise deve segurá-la ("dados pessoais").
4. Escolha uma foto panorâmica muito grande. Ela deve ser reduzida para 2048 px sem travar o app.

## Editar a foto (cortar, zoom e girar)

Depois de escolher a foto (galeria ou câmera) abre a tela "Ajustar foto", antes das checagens do aparelho.

1. **Cortar:** arraste uma alça do canto e outra da borda. O quadro deve seguir o dedo, sem pular, e não pode sair da foto.
2. **Zoom e mover:** faça a pinça sobre o quadro (pinça para fora deixa o quadro menor) e arraste dentro dele para mover.
3. **Formato:** no menu "Formato" escolha 1:1, 4:5 e 16:9. O quadro deve ficar com essa proporção e centralizado; "Livre" solta a proporção.
4. **Girar:** toque em "Girar" quatro vezes. A foto gira no sentido horário, o quadro volta a cobrir a foto inteira e, na quarta vez, a foto fica como no início.
5. **Restaurar** volta ao começo. **Escolher outra** volta à escolha da foto.
6. **Foto pequena:** escolha uma foto com o lado menor abaixo de 320 px. As alças somem, aparece "Esta foto é pequena demais para cortar" e dá para girar. O envio é recusado como antes.
7. **O corte vale para as checagens:** escolha uma foto de grupo com rostos pequenos ao fundo, corte até um rosto ficar grande e toque em "Usar foto". Deve aparecer "Tem um rosto em primeiro plano".
8. **Editar de novo:** na prévia, toque em "Editar foto". O editor abre com a foto original (sem rostos borrados) e, ao confirmar, as checagens rodam outra vez.
9. **VoiceOver:** o quadro é um elemento ajustável; deslizar para cima e para baixo aproxima e afasta.

## Rostos

1. Tire uma selfie. Deve aparecer "Tem um rosto em primeiro plano".
2. Toque em "Borrar os rostos e enviar assim". Na prévia, todos os rostos devem estar cobertos. Envie.
3. Repita e escolha "Enviar outra foto". O app deve voltar para a escolha da foto.

## Conteúdo sensível (SensitiveContentAnalysis)

1. Em Ajustes > Privacidade e Segurança > Aviso de Conteúdo Sensível, ligue o aviso.
2. Procure se a Apple oferece um perfil ou uma imagem de teste para o Sensitive Content Analysis. Eu não verifiquei se existe. **Não use imagem explícita.** Se der para simular, o app deve dizer que a foto parece ter conteúdo sensível e não enviar nada.
3. Com o aviso desligado, o app segue normalmente, e só a análise do servidor checa a foto.
4. O entitlement `com.apple.developer.sensitivecontentanalysis.client` **ainda não está no projeto**. Sem ele, a checagem não roda. Antes deste teste, ative a capability em Signing & Capabilities.

## Rede e segundo plano

1. Ligue o modo avião e toque em "Enviar foto". O app deve dizer "sem internet", e "Tentar de novo" deve manter a mesma foto.
2. Envie com rede lenta (Ajustes > Desenvolvedor > Network Link Conditioner > 3G) e mande o app para o segundo plano logo depois. Ao voltar, a foto deve ter sido enviada: o app tem cerca de 30 s para terminar.

## Ciclo completo com duas contas

1. A envia a foto. Ela aparece para A no carrossel com "Em análise" e em Perfil > Minhas fotos.
2. B abre o mesmo lugar e não vê a foto.
3. Na página `/admin` do backend, aprove a foto. Ao reabrir o app, A recebe o aviso "foto publicada", e B passa a ver a foto com o crédito de A (ou "de um visitante", se A escolheu ficar anônimo).
4. B toca em ••• > Denunciar, escolhe um motivo e envia. Com 3 contas denunciando, a foto some e volta para `/admin`.
5. B toca em ••• > Bloquear. As fotos de A somem para B. Em Fotos e privacidade, B desbloqueia.
6. A apaga a foto em Minhas fotos. Ela some para B, e os arquivos somem do storage. Confira no painel do Supabase.
7. A tenta enviar a mesma foto de novo e deve ver "Essa foto já foi enviada".
8. A exclui a conta. As fotos dela somem do lugar e do storage.

## Acessibilidade

- Com o VoiceOver, o carrossel lê "Foto de …" e o menu "Opções da foto". O aviso de rosto e os botões do envio devem ser alcançáveis.
- Com texto grande (Ajustes > Acessibilidade > Tamanho do texto no máximo), o termo e a tela de envio devem continuar legíveis.
