# Envio para a App Store: o que foi feito e o que falta

Estado em 2026-11-23 (noite). App "Lero: Descubra lugares" (Apple ID 6821126406, bundle `dalpra.Zanzar`), versão 1.0, "Prepare for Submission". O ASC ainda usa a build 1 e as três carinhas como ícone.

## Feito (branch `chore/app-store-release`)

- Ícone novo exportado do Figma (frame "App Icon", arquivo Macro-Challenge, nó 2512:12620): 1024x1024, RGB, sem alpha. Está em `AppIcon.appiconset/AppIcon.png`. O ícone do ASC só muda com a build nova.
- `PrivacyInfo.xcprivacy` no app, no widget e na extensão de compartilhar. Declara `UserDefaults` (CA92.1 e 1C8F.1, app group), sem rastreamento, e os tipos de dado coletados (e-mail, ID de usuário, localização precisa, fotos, outro conteúdo do usuário), todos para funcionalidade do app e ligados à conta. Sem o arquivo, o upload recebe o aviso ITMS-91053.
- Widget: deployment target 27.2 -> 26.0 (igual ao app). Projeto: 27.0 -> 26.0. Build Release para o simulador passa.
- `scripts/testflight-preflight.sh`: lê `ITSAppUsesNonExemptEncryption` e a permissão de localização do `.pbxproj` (não estão mais no Info.plist) e confere os 3 manifestos. Passa.
- Link da política de privacidade dentro do app (Perfil > Ajustes > Privacidade > Política de privacidade) abre https://lero.social/privacidade. A diretriz 5.1.1 exige o link no app.
- Site (repo `MaisOuMenos170/LeroSite`, PR 4): `/privacidade` (pt/en), `/suporte` (pt/en), FAQ com e-mail, domínio `lero.social` no canonical/og/sitemap/robots. `/termos` segue placeholder.
- `docs/politica-de-privacidade.md` igual ao texto publicado. Os "pontos em aberto" viraram a seção abaixo.
- Testes: 730 testes passam (`xcodebuild test`, iPhone 17 Pro).

## Já preenchido no App Store Connect (2026-11-23)

- Subtítulo "O passaporte de Curitiba"; categoria Viagens e secundária Navegação (Estilo de vida restringe a venda em alguns países).
- Classificação etária respondida: resultado 18+ (álcool "Frequente" e conteúdo gerado por usuário). Se quiserem 13+, mude álcool para "Infrequente" em App Information > Age Ratings.
- App Privacy publicado: e-mail, ID do usuário, ID do dispositivo (push), localização precisa, fotos e outro conteúdo do usuário; todos ligados à conta, sem rastreamento. Política: https://lero.social/privacidade.
- Versão 1.0: Support URL https://lero.social/suporte, Marketing URL https://lero.social, usuário de demonstração teste@teste.com, notas da revisão em inglês.
- Direitos de conteúdo marcados ("contém conteúdo de terceiros e tenho os direitos"). Classificação etária agora 13+ (álcool "Infrequente"; Brasil 12+). Contato da revisão preenchido. Release em "automático após aprovação".
- **Não preenchido:** senha da conta de demonstração, anexo do vídeo (`docs/app-review/lero-checkin-review.mp4`, o navegador embutido não consegue anexar arquivo), seleção da build e envio.

## PRs

- MaisOuMenos170/LeroSite#4 (mesclado): privacidade e suporte no site.
- MaisOuMenos170/Zanzar#112: esta branch para `develop`.

## Screenshots da App Store

- Figma: arquivo Macro-Challenge, página "App Store" (https://www.figma.com/design/8hydbYFSjLxZ8DLsNjLRm7/Macro-Challenge?node-id=2679-2032). Cinco quadros de 1320x2868 ("App Store 6.9\" — 01 ... 05"). As telas dentro do aparelho são clones dos frames do design (página Handoff), não capturas do app, porque o app ainda está sendo codado. Elas continuam editáveis e vetoriais.
- Ordem (a promessa vem primeiro): 1 "Carimbe Curitiba!" (passaporte com carimbo LERO), 2 "Crie seu personagem" (construtor de avatar), 3 "Faça check-in, ganhe selos" (Jardim Botânico, com foto), 4 "Siga roteiros pela cidade" (Visitando parques), 5 "Conte como foi lá" (avaliação com as carinhas).
- Estilo: uma cor da marca por tela (roxo, laranja, turquesa, rosa, amarelo), títulos grandes SF Pro Rounded Black com no máximo 2 linhas, bandeirinhas da capa no topo e o aparelho grande cortado na base. Boas práticas seguidas: as 3 primeiras decidem a conversão, frase curta legível em miniatura, sistema visual coeso.
- Textos de exemplo trocados nos clones: nome no passaporte ("Ana Souza") e lugares/distâncias da lista de roteiros. A foto do Jardim Botânico é de Halley Pacheco de Oliveira (CC BY-SA 3.0, Wikimedia Commons), com crédito visível.
- Mapas do design (página Handoff) usam Varsóvia como placeholder, por isso nenhuma tela de mapa entrou. Troque o mapa do design por Curitiba se quiserem uma tela de "Descobrir".
- **Para subir no ASC use `docs/app-store-screenshots/pt-BR-1206x2622/`** (1206x2622, RGB, sem alpha). O ASC atual só lista "iPhone with Dynamic Island (medium display)" e aceita 1179x2556 ou 1206x2622 (o campo só aparece em tela larga, na aba "App Previews and Screenshots"). Os PNGs de `docs/app-store-screenshots/pt-BR/` (1320x2868) são o mestre em 6,9". `fontes/` guarda as capturas do app (simulador), que não são usadas nesta versão.
- No ASC: grupo iPhone with Dynamic Island (medium display). O app é só iPhone, então iPad não precisa.
- Referências lidas para decidir o estilo: [Guia 2026 de screenshots](https://dev.to/appscreenshotstudio/app-store-screenshots-that-convert-the-2026-design-guide-1d94), [AppTweak](https://www.apptweak.com/en/aso-blog/how-to-optimize-your-app-screenshots) e [Apple: especificações](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications).

## URLs para o App Store Connect

| Campo | Valor |
|---|---|
| Privacy Policy URL | https://lero.social/privacidade |
| Support URL (hoje está o GitHub) | https://lero.social/suporte |
| Marketing URL | https://lero.social |
| Contato | contato@lero.social |

As três só funcionam depois que o PR 4 do LeroSite for mesclado e o Railway publicar.

## Textos prontos para o ASC

**Subtítulo (30 caracteres):** `O passaporte de Curitiba` (24).

**Categoria:** primária Viagens (Travel), secundária Estilo de vida (Lifestyle).

**Classificação etária** (respostas, tabela da Apple lida em 2026-11-03): User-Generated Content = Sim (fotos moderadas antes de publicar). Álcool/tabaco/drogas = Frequente (lista bares e festas). Mensagens/chat = Não. Redes sociais = Não. Localização compartilhada com outros = Não. Anúncios = Não. Web irrestrita = Não. Apostas, violência, conteúdo sexual = Nenhum. Controles parentais/verificação de idade: o envio de fotos exige autodeclaração de 18+. Resultado esperado 18+. Confira o pictograma do Brasil depois de salvar.

**App Privacy** (todos: coletado, ligado ao usuário, sem rastreamento, finalidade App Functionality): E-mail, ID do usuário, Localização precisa, Fotos ou vídeos, Outro conteúdo do usuário. Conferir se o nome de usuário (crédito da foto) precisa entrar como "Name". Política: https://lero.social/privacidade.

**Direitos de conteúdo:** o app mostra dados de terceiros (OpenStreetMap, Google Places). Responda "Sim, contém conteúdo de terceiros" e confirme que a atribuição do OpenStreetMap está visível. Decisão de vocês.

**Notas para a revisão (inglês):**

> Lero is a place-discovery app for Curitiba, Brazil. Check-ins only work within 150 m of a place, so a reviewer outside Curitiba cannot complete one. The attached screen recording shows the full flow (map, place, check-in near and far away, stamp earned, itinerary, rating). Everything else works from anywhere: sign in, browse the map, open a place, view stamps and itineraries, save places, suggest a place, upload and report photos, block users, and delete the account (Profile > Settings > Delete my account).
> User photos: every photo is checked on the device (resize, EXIF/GPS removal, face detection with blur) and on our server (validation, duplicate detection, AI review by Cloudflare Workers AI). A photo is shown to others only after approval; uncertain ones go to a human queue. Users can report any photo (••• menu), block its author, and delete their own photos. Uploading requires accepting the photo terms and declaring 18+.
> Privacy policy: https://lero.social/privacidade. Support: contato@lero.social.
> Demo account: lero-reviewer@maisoumenos170.com / [senha]

**Contato da revisão:** nome, telefone e e-mail de uma pessoa do time (campos obrigatórios).

**Conta de demonstração:** e-mail em `docs/app-review.md`. Criar na API de produção (`POST /register`, 8+ caracteres, letra e número) e guardar a senha no secret `APP_REVIEW_PASSWORD`. A senha não vai em arquivo.

## Falta (precisa de vocês)

1. Mesclar o PR 4 do LeroSite (publica privacidade e suporte).
2. Gerar a build nova: mesclar `chore/app-store-release` em `develop` e depois `develop` em `main` (o Xcode Cloud carimba o número da build). Hoje `main` está 2 commits à frente de `develop` e `develop` 63 à frente de `main`. A `feat/place-detail-v2` (PR 110) não está no `develop`.
3. No ASC: privacidade, classificação etária, subtítulo, categoria, direitos de conteúdo, contato da revisão, conta de demonstração, notas, vídeo da revisão (anexo), selecionar a build nova, conferir preço Grátis e screenshots 6,9". A página da versão não mostrou a seção de screenshots no navegador embutido: conferir a mão.
4. Gravar o vídeo da revisão (há gravações em `recordings/` e vídeos no site).
5. Decidir o tempo de guarda do registro de auditoria das fotos (hoje 1 ano; havia proposta de 5), as regiões dos servidores (Atlas, Supabase, Railway) e o prazo de logs do Railway. Revisão jurídica das bases legais.
6. Nomes dos responsáveis: a política cita a equipe + ou − 1,70 m (pessoas físicas) sem nomes. A LGPD pede identificar o controlador. Acrescentar os nomes se quiserem.
7. Backend de produção: o Release e os links universais usam `zanzarbackend-development.up.railway.app` (decisão: manter).
8. Opcional: ícone do site (`app-icon-96.webp`) ainda é o das carinhas.

## Auditoria final (2026-11-23, noite)

**Só iPhone, verificado no binário de Release:** app, widget e extensão de compartilhar com `UIDeviceFamily = [1]`; `SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD` e `SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD` = NO no app; no ASC, Mac e Vision Pro desmarcados em Pricing and Availability. iPad ainda pode instalar o app em modo de compatibilidade (regra da Apple). iPhone Duo é iPhone: deixar as screenshots dele vazias.

**Pronto:** ícone novo, privacy manifest (app, widget, share), deployment target 26.0, `ITSAppUsesNonExemptEncryption = NO`, links universais (AASA do backend ok), exclusão de conta no app, política de privacidade no app, versão 1.0, 746 testes, build de Release, App Compliance sem pendência, rascunho de acessibilidade (Larger Text), App Privacy publicado, classificação 13+, direitos de conteúdo, contato da revisão, notas da revisão, URLs de suporte/marketing/privacidade preenchidas, liberação automática.

**Falta (nenhum item é código):**
1. ~~Domínio `lero.social`~~ abre no navegador do Lucas (home, /privacidade e /suporte) em 2026-11-23 19:30.
2. ASC: subir as 5 screenshots (0 de 10 hoje), (senha e vídeo já colocados pelo Lucas), trocar a build 1 pela nova, (preço já está Grátis em todas as regiões; disponibilidade: só Brasil, "Available on App Release").
3. Mesclar #112 e #113 (CI ainda rodando) para o Xcode Cloud gerar a build. O workflow do Xcode Cloud não pôde ser conferido pelo navegador embutido.
4. Opcional: localização em inglês no ASC, descrição mais longa.

## Decisão: versão 1.0 inclui o PR #114 (2026-11-24)

O PR #114 do Tiago (novo visual de roteiros, lugares salvos, esqueletos) entrou na branch de release por merge (`Merge feat/new-itinerary-view`). O CI dele falhava com "unable to type-check this expression in reasonable time" em `PlaceDetailView.swift`; a correção (dividir a cadeia de modificadores do `body` em 3 propriedades) está na branch de release, não na do Tiago. Com o #114 a screenshot 4 (roteiros) passa a bater com o app. Verificado localmente: 800 testes, build de Release e preflight passando.

## Screenshots finais (2026-11-24)

O Lucas montou as telas finais no Figma (frames 1 a 5, nós 2749:10608, 10961, 10962, 10963 e 10964, 1320x2868). **Suba no ASC as de `docs/app-store-screenshots/final-1206x2622/` (1.png a 5.png, 1206x2622, RGB, sem alpha).** Só foram redimensionadas (export 2x do Figma e redução com Lanczos), sem mudar nada do design. As pastas `pt-BR` e `pt-BR-1206x2622` são as versões antigas geradas por mim e não devem ser usadas.
