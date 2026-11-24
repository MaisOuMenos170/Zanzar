# App Store Connect: o que preencher à mão (fotos de usuário)

O app não altera nada no App Store Connect. Esta lista é para você preencher.

## 1. Classificação etária (App Information > Age Rating)

As respostas abaixo valem para depois desta feature. A tabela da Apple foi lida em 2026-11-03; detalhes em `fotos-de-usuario-decisao.md`, seção 2.

| Pergunta | Resposta | Por quê |
|---|---|---|
| Alcohol, Tobacco, or Drug Use or References | **Frequent** | O app lista bares e festas |
| User-Generated Content | **Yes** | Fotos dos usuários, moderadas antes de publicar |
| Messaging and Chat | No | Não há troca de mensagens |
| Advertising | No | |
| Gambling, contests | No | |
| Violence, sexual content, nudity, horror | None | A moderação bloqueia |
| Unrestricted Web Access | No | Os links abrem só a fonte da foto e o e-mail |
| Age Assurance / Parental Controls | Indicar a autodeclaração de 18+ para enviar fotos | |

- **Resultado esperado: 18+.** Com álcool "Infrequent", seria 13+. "Frequent" é a resposta honesta para um app de bares.
- **Brasil:** a classificação do MJSP aparece depois de salvar o questionário. Confira o pictograma.

## 2. Privacidade (App Privacy)

Acrescente estes tipos de dado:

| Tipo | Coletado | Ligado ao usuário | Rastreamento | Finalidade |
|---|---|---|---|---|
| **User Content > Photos or Videos** | Sim | Sim | Não | App Functionality |
| **User Content > Other User Content** (denúncias com texto) | Sim | Sim | Não | App Functionality |
| **Sensitive Info** | Não | | | A idade não é guardada; só "é maior de idade" |

- Confira se "Name" (o nome de usuário mostrado como crédito) já consta como "App Functionality".
- **Política de privacidade:** antes de enviar a versão, acrescente a seção de fotos (ver `fotos-de-usuario-termo.md`).

## 3. Notas para a revisão da Apple (App Review Information > Notes)

Sugestão de texto (em inglês, como a revisão pede):

> Users can upload photos of venues. Every photo is checked on the device (resizing, EXIF/GPS removal, Apple's SensitiveContentAnalysis when enabled, face detection with an option to pixelate) and on our server (file validation, duplicate detection, quality, face detection, and an AI review by Cloudflare Workers AI). A photo is shown to other users only after it is approved; anything uncertain goes to a human review queue operated by our team. Users can report any photo (••• menu on the photo), block its author, delete their own photos (Profile > My photos) and reach us at the contact in Profile > Photos and privacy. Uploading requires accepting the photo terms and declaring an age of 18 or older.
> Demo account: [preencher] — it has one approved and one pending photo at [lugar].

- **Conta de demonstração:** crie uma conta de teste com uma foto aprovada e uma em análise.

## 4. Antes de enviar a versão

- [ ] Preencher `ZANZAR_SUPPORT_EMAIL` em `Config.Release.xcconfig`. A diretriz 1.2 exige contato publicado.
- [ ] Ativar a capability **Sensitive Content Analysis** no App ID e no projeto (entitlement `com.apple.developer.sensitivecontentanalysis.client`). Sem ela, a checagem no aparelho fica desligada.
- [ ] Configurar no Railway `PHOTO_STORAGE`, `SUPABASE_*`, `VISION_*` e `ADMIN_USER_IDS`. Sem a camada de visão, toda foto vai para revisão humana, o que é seguro mas lento.
- [ ] Revisão jurídica do termo (`fotos-de-usuario-termo.md`).
