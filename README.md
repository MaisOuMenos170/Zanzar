# Zanzar

App Structure

```swift
ZanzarProject/ZanzarProject/
  App/                          ContentView.swift, MyApp.swift (@main)
  Features/<FeatureName>/
    API/
      <FeatureName>Service.swift     protocol + impl + Request/Response
    Models/
      <FeatureName>.swift            domain model(s) the View/ViewModel use
    Views/
      <FeatureName>View.swift
      Components/                   extracted subviews for this feature only
    ViewModels/
      <FeatureName>ViewModel.swift
  Coordinator/
    AppCoordinator.swift         @Observable, owns the NavigationPath
    Routes.swift                 Route enum
  Extensions/                    cross-feature Swift/SwiftUI extensions
  Utils/
    NetworkClient.swift          the one shared network client
  Resources/
    Assets.xcassets               images, colors, icons
    Localizable.xcstrings         all user-facing strings, en + pt-BR
ZanzarProjectTests/<FeatureName>/
  <FeatureName>ViewModelTests.swift
```

Database
<img width="4394" height="3461" alt="Database" src="https://github.com/user-attachments/assets/a43711c3-a14e-4cfe-bc80-4c60740045f2" />

## Desenvolvimento local — API via Cloudflare Tunnel

Quando você testa o app no **simulador**, o backend em `http://127.0.0.1:3000` funciona direto. No **iPhone físico**, o aparelho não enxerga o `localhost` do Mac — aí entra o [Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/do-more-with-tunnels/trycloudflare/): ele expõe o backend local com uma URL pública temporária (`*.trycloudflare.com`).

O script `scripts/update-api-tunnel-url.sh` grava essa URL no projeto Xcode (configuração **Debug**), para o app saber onde chamar a API.

### Pré-requisitos

| Ferramenta | Para quê |
|---|---|
| [cloudflared](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/) | Criar o túnel `trycloudflare.com` |
| Python 3 | O script usa `python3` para editar o `project.pbxproj` |
| Backend rodando | `ZanzarBackend` em execução (porta `3000` por padrão) |

Instalar o `cloudflared` no macOS (Homebrew):

```bash
brew install cloudflared
```

### Fluxo recomendado (automático)

O repositório `ZanzarBackend` tem um script que sobe o túnel **e** chama o `update-api-tunnel-url.sh` por você:

```bash
# Terminal 1 — backend
cd ../ZanzarBackend
npm install
npm run dev

# Terminal 2 — túnel + atualização da URL no app
cd ../ZanzarBackend
./scripts/dev-tunnel.sh
```

O `dev-tunnel.sh`:

1. Inicia `cloudflared tunnel --url http://127.0.0.1:3000`
2. Lê a URL gerada (ex.: `https://invest-plaza-assessed-lived.trycloudflare.com`)
3. Executa `../Zanzar/scripts/update-api-tunnel-url.sh <url>`
4. Mantém o túnel aberto até você pressionar `Ctrl+C`

### Fluxo manual (só o script do app)

Use quando você já tem a URL do túnel (por exemplo, subiu o `cloudflared` em outro terminal):

```bash
# Terminal 1 — backend
cd ../ZanzarBackend
npm run dev

# Terminal 2 — túnel (anote a URL que aparecer no log)
cloudflared tunnel --url http://127.0.0.1:3000

# Terminal 3 — atualizar o app (a partir da raiz do Zanzar)
./scripts/update-api-tunnel-url.sh https://sua-url-aqui.trycloudflare.com
```

**Exemplo:**

```bash
./scripts/update-api-tunnel-url.sh https://invest-plaza-assessed-lived.trycloudflare.com
```

Saída esperada:

```text
Updated ZANZAR_API_BASE_URL in Config.xcconfig -> https://invest-plaza-assessed-lived.trycloudflare.com
```

### O que o script altera

O script escreve `ZANZAR_API_BASE_URL` em `ZanzarProject/Config.xcconfig` (arquivo local, ignorado pelo git; veja `Config.xcconfig.example`). O `ZanzarProject/Info.plist` expõe esse valor como `ZanzarAPIBaseURL`, e em runtime `APIConfiguration.baseURL` o lê de lá. Chaves customizadas não funcionam via `INFOPLIST_KEY_*`, por isso o `Info.plist` separado.

> Builds **Release** não usam essa URL de túnel. Eles leem `ZanzarProject/Config.Release.xcconfig`, que aponta para `https://zanzarbackend-development.up.railway.app`.

### Depois de rodar o script

1. **Rebuild** o app no Xcode (⌘B) ou rode de novo (⌘R) — o Xcode precisa regenerar o Info.plist com a URL nova.
2. Teste se o túnel responde:

   ```bash
   curl https://sua-url-aqui.trycloudflare.com/health
   ```

3. Abra o app no dispositivo e faça login / signup normalmente.

### Observações importantes

- **URL efêmera** — cada vez que o `cloudflared` reinicia, a URL muda. Rode o script de novo (ou use `dev-tunnel.sh`) sempre que subir um túnel novo.
- **Local** — o valor fica no `Config.xcconfig` (não versionado) e vale para Debug e Release; defina a URL de produção separadamente antes de um build Release.
- **Dois repositórios** — `ZanzarBackend` e `Zanzar` devem estar no mesmo diretório pai (ex.: `~/projetos/ZanzarBackend` e `~/projetos/Zanzar`), pois o `dev-tunnel.sh` resolve o caminho relativo entre eles.
- **Simulador sem túnel** — se `ZANZAR_API_BASE_URL` estiver vazia em Debug, o app usa fallback `http://127.0.0.1:3000` (ver `APIConfiguration.swift`).
