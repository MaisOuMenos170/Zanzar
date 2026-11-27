# Testes que ficaram para o final

O que a auditoria de 2026-11-26 **não** exercitou no simulador (ver `docs/AUDITORIA-COMPLETA-2026-11-26.md`). Cada item diz o que preparar,
o que fazer e o que deve acontecer. Marque aqui quando passar e anote o que achar.

## Preparação comum

- Backend local: `cd ../ZanzarBackend && npm run dev` (porta 3000) e `ZANZAR_API_BASE_URL = http:/$()/127.0.0.1:3000` em `ZanzarProject/Config.xcconfig` (não commitar).
- O banco do `.env` é o Atlas dev: use uma conta de teste (ex.: `auditor.dois.1126@example.test`) e anote o que criar.
- Simulador: iPhone 17, iOS 27. Comandos úteis (troque `booted` pelo UDID se houver mais de um):
  - posição: `xcrun simctl location booted set -25.4289,-49.2728`
  - permissão: `xcrun simctl privacy booted revoke|grant|reset location dalpra.Zanzar` (também `photos`, `camera`, `notifications`)
  - foto na galeria: `xcrun simctl addmedia booted caminho/da/foto.jpg`
- **Em Debug no simulador o app finge a posição** (`DevLocation.historicCenter`, perto do Al Beek). Para usar a posição real do simulador
  abra o app com o argumento `-ZANZAR_REAL_LOCATION` (XcodeBuildMCP: `launchArgs: ["-ZANZAR_REAL_LOCATION"]`; Xcode: Edit Scheme > Run > Arguments).
  Sem ele, nada de "localização negada", "sem sinal" ou "andar até outro lugar" funciona.

## 1. Extensão de compartilhar ("O Lero" na folha de compartilhar)

Pré-condição: conta logada no app (a extensão lê o token do Keychain compartilhado) e backend no ar.

1. No simulador, abra o app Mapas, escolha um lugar de Curitiba e toque em Compartilhar. Se "O Lero" não aparecer, "Mais" > ative.
2. Esperado: tela "lendo" (mascote sonolento) → lista com o lugar encontrado, mapa e campo de nota → "Enviar" → resultado (a sugestão segue as mesmas regras de moderação do app).
3. Repetir com: um link `maps.apple.com` e um `maps.app.goo.gl`; um endereço em texto; um lugar **fora de Curitiba** (esperado: aviso de fora da área); um texto sem lugar (esperado: "não consegui ler");
   **sem estar logado** (esperado: pedir para abrir o app e entrar); sem rede (esperado: mensagem de erro de busca/envio, não tela travada).
4. O resultado bom fecha sozinho em ~2,4 s; recusa e falha esperam o toque.

## 2. Widget (próxima parada do roteiro)

1. Home Screen do simulador > segurar > "+" > Lero > pequeno e médio.
2. Sem roteiro ativo: esperado o convite para fazer check-in/escolher roteiro. Com roteiro ativo (Roteiros > Iniciar): esperado o nome da próxima parada e a distância.
3. Fazer check-in numa parada (com `-ZANZAR_REAL_LOCATION` e `simctl location set` perto dela): ao voltar ao Home, o widget avança para a próxima parada. Abandonar o roteiro volta ao convite.
4. O toque no widget só abre o app (não há `widgetURL`): não é bug.

## 3. Alerta de proximidade

1. Perfil > Ajustes > ligar "Lugares por perto" e "Meu roteiro"; conceder notificações e localização ("Sempre"/"Ao usar" conforme o prompt do app).
2. Abrir com `-ZANZAR_REAL_LOCATION` e `xcrun simctl location booted set` num ponto longe de qualquer lugar; depois mudar para perto de um lugar **não visitado**.
3. Esperado: notificação local "perto de um lugar" (ou "próxima parada" para o roteiro ativo); tocar nela abre o detalhe do lugar. O app em primeiro plano mostra banner.
4. Limites (ver `ProximityAlertPolicy`): o mesmo lugar só avisa de novo depois de 3 dias; há tetos por janela, sem horário de silêncio fixo. Para repetir o teste, apague o app ou os dados de `proximity` no UserDefaults.
5. Com a permissão negada: esperado o cartão "Abrir ajustes" no Perfil > Ajustes e o explicador (`ProximityPermissionPromptView`) depois do primeiro check-in ou ao iniciar roteiro (até 3 vezes, com 14 dias entre elas).

## 4. Avaliação ("Avalie a experiência")

1. Fazer check-in num lugar (com `-ZANZAR_REAL_LOCATION`, perto dele).
2. Mover o simulador a mais de 150 m: `xcrun simctl location booted set` para um ponto distante. O app confere a cada 30 s com o app ativo, até 6 h depois do check-in.
3. Esperado: cartão com as 5 carinhas; enviar sem escolher fica desligado; escolher e enviar mostra "Muito bem!". O botão fechar descarta a avaliação pendente (o toque fora não fecha). Enviar duas vezes: o 409 fecha em silêncio.
4. Atalho de foto no cartão abre o envio de foto "do check-in".

## 5. Upload de foto

Existem roteiros prontos: `docs/fotos-de-usuario-teste-e2e.md` e `docs/fotos-de-usuario-teste-manual.md`. Resumo:

1. Pré-condição: backend com as chaves de armazenamento do `.env` e a moderação ligada (sem isso o envio falha no fim); termos aceitos e data de nascimento (18+) informada na primeira vez.
2. Pôr fotos na galeria com `simctl addmedia` (uma comum, uma com rosto, uma repetida, uma pequena demais).
3. Detalhe de um lugar > Adicionar foto > galeria: recortar/girar → análise → (rosto: escolher outra, borrar ou editar) → prévia (nome do autor ligado/desligado) → enviar → "em análise".
4. Esperado nos erros: foto repetida, grande demais, formato não aceito, sem rede (o envio recusa antes), limite de envios, conteúdo sensível. "Tirar foto" no simulador cai no alerta de câmera (sem câmera).
5. Depois: Perfil > Ajustes > Minhas fotos mostra o estado; ao reabrir o app com a revisão feita, aparece o toast (publicada = verde, não aprovada = vermelho). Apagar a foto pede confirmação.

## 6. Roteiro concluído

1. Conta de teste **nova** (o roteiro conta check-ins feitos depois de iniciar).
2. Roteiros > "Bora passear no centro histórico?" (4 paradas fixas: Ruínas de São Francisco → Cavalo Babão → Memorial de Curitiba → Arcádia) > Iniciar. Ou "Visitando parques" (4 check-ins em parques).
3. Para cada parada: `-ZANZAR_REAL_LOCATION` + `xcrun simctl location booted set <lat>,<lng>` da parada (coordenadas no detalhe do lugar ou no `lugares.json` do backend) → check-in.
4. Esperado a cada check-in: alerta de selo (se for selo novo); no último, depois do selo, o alerta de **roteiro concluído**. Perfil: "Roteiros completos" +1; Roteiros: o roteiro some de "em andamento".
5. Abandonar no meio: pede confirmação e volta ao estado sem roteiro.

## 7. Localização negada e sem sinal

Já conferido em 2026-11-26 no simulador: passos 1 a 3 (banner no mapa e aviso no check-in). Falta o 4 (voltar a conceder), o 5 (sem sinal) e o 6 (aparelho de verdade).

1. `xcrun simctl privacy booted revoke location dalpra.Zanzar`; abrir com `-ZANZAR_REAL_LOCATION`.
2. Descobrir: esperado o banner "Acesso à localização negado. Ative nas Configurações para ver lugares próximos." com "Tentar de novo"; mapa sem pins.
3. Detalhe de um lugar > Fazer check-in: esperado o aviso **antes** da confirmação: "Precisa da localização — Ligue a localização para fazer check-in neste lugar."
4. Conceder de novo (`grant`), voltar ao app, "Tentar de novo": os pins voltam.
5. Sem sinal: permissão concedida e `xcrun simctl location booted clear`; esperado, depois de ~10 s, "Não foi possível obter sua localização. Tente novamente." no mapa.
6. Em aparelho de verdade, repetir 2 e 3 desligando Ajustes > Privacidade > Serviços de Localização; e testar "precisão aproximada" (esperado o aviso de localização incerta no check-in).

## 8. Aviso "Avisar quando abrir" (disparo) e GPS impreciso

- **Disparo do aviso:** num lugar fechado, toque em "Avisar quando abrir" e deixe o app em segundo plano até o horário de abertura (para ver rápido, escolha um lugar que abre nos próximos minutos). Esperado: notificação "O {lugar} abriu. Bora?"; tocar abre o detalhe do lugar. Cancelar: tocar em "Aviso agendado" ou sair da conta (cancela todos).
- **GPS impreciso (D2):** em aparelho de verdade, num prédio fechado ou com "Localização precisa" desligada, abrir o mapa: esperado o aviso "Não achei você direito…" sob a busca; ao ir para um lugar aberto e tocar em "Tentar de novo", ele some. No simulador a posição não tem precisão e o aviso não aparece.
- **Fila offline em aparelho:** ligar o modo avião, fazer check-in, "Guardar e enviar depois", desligar o modo avião e abrir o app: esperado o toast de envio e o carimbo/selo no perfil.
