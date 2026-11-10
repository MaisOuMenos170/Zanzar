# Política de privacidade

O **O Lero** é um aplicativo para descobrir lugares em Curitiba, fazer check-in, ganhar selos e seguir roteiros. Ele é mantido por um grupo de cinco estudantes, pessoas físicas, com base em Curitiba/PR ([NOMES DOS RESPONSÁVEIS]). Nós valorizamos a sua privacidade. Esta Política de Privacidade explica quais dados pessoais coletamos, como usamos, com quem compartilhamos e como protegemos esses dados, em conformidade com a Lei Geral de Proteção de Dados (LGPD, Lei nº 13.709/2018).

## 1. Nosso papel no tratamento de dados

Para fins da LGPD, os responsáveis pelo O Lero atuam como **Controladores** de todos os dados tratados no app: somos nós que decidimos quais dados são coletados e para quê. Os serviços que usamos para hospedar e operar o app (listados na seção 4) atuam como **Operadores**, tratando os dados apenas para executar o serviço que contratamos.

## 2. Quais dados coletamos

Coletamos apenas o necessário para o app funcionar.

**Dados da conta:**

- Nome de usuário e e-mail.
- Senha, guardada somente em forma de hash (nunca a senha em si).
- Se você entra com a Apple: o identificador da sua conta Apple e o e-mail que a Apple nos repassa (pode ser o e-mail oculto da Apple). Seu nome é usado apenas para sugerir o nome de usuário na criação da conta e não é guardado.
- Avatar ilustrado que você monta no app (combinação de pele, olhos, cabelo e fundo). Não é uma foto sua.

**Dados de uso do app:**

- Check-ins: lugar, data e hora e a sua localização no momento do check-in (latitude, longitude e precisão).
- Selos conquistados, roteiros ativos e concluídos, lugares salvos.
- Reações (impressões) que você deixa nos lugares.
- Sugestões de novos lugares: localização, endereço e o comentário que você escrever.
- Pessoas que você bloqueou.

**Localização:**

- **Durante o uso** do app: para centralizar o mapa e confirmar que você está perto do lugar no check-in. A localização só é enviada aos nossos servidores no momento do check-in ou de uma sugestão de lugar.
- **Sempre** (opcional, só se você ativar os alertas de proximidade): para avisar quando você passar perto de um lugar ou da próxima parada do seu roteiro. Essa verificação acontece no seu aparelho; sua localização contínua não é enviada aos nossos servidores.

**Fotos que você envia de lugares:**

- A foto, reduzida no seu aparelho e sem os dados escondidos (localização GPS, modelo do aparelho e data). Rostos detectados são borrados antes do envio.
- Dados técnicos da foto para evitar duplicatas e abuso: dimensões e impressões digitais da imagem (hashes).
- Resultado da análise automática e da revisão humana, denúncias recebidas e a escolha de mostrar ou não o seu nome de usuário como crédito.
- Aceite do termo de fotos (versão e data) e a declaração de que você tem 18 anos ou mais. A sua data de nascimento é usada só para conferir a idade e **não é guardada**.

**Dados coletados automaticamente:**

- Registros de acesso aos nossos servidores: endereço IP, data e hora, rota acessada, resultado e tempo da requisição e o identificador da sua conta, quando houver login.

**O que não coletamos:** contatos, data de nascimento, dados de pagamento, identificador de publicidade, dados de saúde e histórico de navegação fora do app. O app não usa ferramentas de analytics nem de publicidade.

## 3. Para que usamos os dados

As informações coletadas são usadas exclusivamente para:

- **Operação do serviço:** criar e manter sua conta, registrar check-ins, conceder selos, acompanhar roteiros e mostrar seus lugares salvos (base legal: execução de contrato, art. 7º, V).
- **Alertas de proximidade:** avisar quando você estiver perto de um lugar, se você ativar (base legal: consentimento, art. 7º, I, dado pela permissão de localização do iOS).
- **Fotos da comunidade:** analisar, publicar e creditar as fotos que você envia (base legal: execução de contrato). O envio de uma cópia reduzida da foto à IA da Cloudflare para análise automática depende do seu consentimento específico, dado no termo de fotos (base legal: consentimento, art. 7º, I).
- **Segurança e prevenção de abuso:** limitar tentativas de acesso, impedir reenvio de fotos reprovadas, tratar denúncias e investigar falhas (base legal: legítimo interesse, art. 7º, IX).
- **Melhoria do produto:** usar contagens agregadas (por exemplo, quantos check-ins ou reações um lugar tem) para melhorar o app. Não traçamos perfis individuais de comportamento.

## 4. Compartilhamento com terceiros

Nós **não vendemos** dados pessoais. O compartilhamento ocorre apenas com serviços de tecnologia (Operadores) necessários para o app funcionar:

- **Railway:** hospedagem do servidor (API) do app.
- **MongoDB Atlas:** banco de dados onde ficam a conta e os dados de uso.
- **Supabase:** armazenamento dos arquivos das fotos enviadas pelos usuários.
- **Cloudflare (Workers AI):** análise automática das fotos por inteligência artificial, somente com o seu consentimento. A Cloudflare recebe uma cópia reduzida da foto, responde e não guarda a imagem nem a usa para treinar modelos.
- **Apple:** login com a Apple e serviços do iOS (localização e notificações), conforme a política de privacidade da própria Apple.

As informações dos lugares (nome, endereço, horários) vêm de fontes públicas, como o Google Places; nenhum dado seu é enviado a essas fontes.

**O que outros usuários veem:** seu avatar ilustrado junto às reações que você deixa nos lugares e nos roteiros que você concluiu; suas fotos depois de aprovadas, com seu nome de usuário como crédito (a menos que você escolha ficar anônimo). Seu e-mail, seus check-ins e sua localização nunca são mostrados a outros usuários.

**Transferência internacional:** alguns desses serviços guardam ou processam dados em servidores fora do Brasil. Nesses casos, a transferência ocorre para cumprir o serviço que você pediu e com fornecedores que adotam medidas de segurança compatíveis com a LGPD (art. 33).

Se passarmos a usar novas ferramentas, elas seguirão esta mesma política de transparência e necessidade, e esta página será atualizada.

## 5. Cookies e tecnologias de rastreamento

O O Lero **não usa cookies, ferramentas de analytics nem rastreamento** entre apps ou sites. Usamos apenas um identificador de sessão (token de acesso), guardado no Keychain do seu iPhone, para manter você conectado com segurança.

## 6. Segurança e retenção de dados

Adotamos medidas técnicas e organizacionais compatíveis com os riscos do tratamento, entre elas:

- Comunicação criptografada (HTTPS) entre o app e os servidores.
- Senhas guardadas só como hash; tokens de sessão no Keychain do aparelho, com possibilidade de revogação.
- Fotos sem metadados de localização, com rostos borrados, guardadas de forma privada até serem aprovadas.
- Limite de tentativas de acesso e registros de acesso sem senhas nem tokens.

**Por quanto tempo guardamos:**

- Dados da conta e de uso: enquanto a sua conta existir.
- Fotos publicadas: até você apagá-las ou excluir sua conta.
- Fotos reprovadas: os arquivos são apagados em 30 dias. As impressões digitais da imagem (hashes) continuam guardadas para impedir o reenvio da mesma foto.
- Registro de auditoria das fotos (envio, análise, denúncias e remoção, sem a imagem): 1 ANO.
- Registros de acesso aos servidores: pelo prazo de retenção do provedor de hospedagem.

Quando você exclui sua conta, apagamos seus dados de conta, check-ins, reações, selos, roteiros, lugares salvos e fotos (inclusive os arquivos). Mantemos apenas o que for necessário para cumprir obrigação legal, para exercício regular de direitos ou o registro de auditoria das fotos descrito acima.

## 7. Direitos dos titulares

Em cumprimento à LGPD, você tem o direito de:

- Confirmar se tratamos seus dados e acessá-los.
- Corrigir dados incompletos, inexatos ou desatualizados.
- Pedir a portabilidade dos seus dados.
- Pedir a exclusão da sua conta e dos seus dados pessoais.
- Revogar o consentimento a qualquer momento, por exemplo para a análise de fotos pela IA da Cloudflare ou para a localização "sempre".
- Obter informações sobre com quem compartilhamos seus dados.

Algumas dessas ações você faz direto no app ou no iPhone:

- Apagar suas fotos: Perfil > Minhas fotos.
- Desbloquear pessoas e reler o termo de fotos: Perfil > Fotos e privacidade.
- Remover a permissão de localização, câmera ou notificações: Ajustes do iOS > O Lero.

O envio de fotos é permitido apenas para pessoas com 18 anos ou mais.

## 8. Contato e solicitações

Para exercer seus direitos, pedir a exclusão da sua conta, exportar seus dados ou tirar dúvidas sobre esta Política de Privacidade, fale com a gente:

E-mail: contato@lero.social

Última atualização: 12 de novembro de 2026.

---

## Pontos em aberto (não publicar esta seção)

1. **Responsáveis:** preencher `[NOMES DOS RESPONSÁVEIS]`. A LGPD aceita pessoa física como controladora, mas o titular precisa saber quem é.
2. **E-mail de contato:** criar a caixa, preencher `[E-MAIL DE CONTATO]` aqui e em `ZANZAR_SUPPORT_EMAIL` (`ZanzarProject/Config.Release.xcconfig`). Definir o `[PRAZO]` de resposta (a LGPD prevê 15 dias para o acesso completo, art. 19, II).
3. **Exclusão de conta no app:** o backend já tem `DELETE /user/:id`, mas o app não tem tela para isso. A Apple exige exclusão dentro do app (diretriz 5.1.1(v)). Quando existir, acrescentar "Perfil > Excluir conta" na seção 7.
4. **Prazo da auditoria das fotos (`user_photo_events`):** hoje sem prazo; proposta de 5 anos (mesmo ponto em `fotos-de-usuario-termo.md`).
5. **Regiões dos servidores:** confirmar a região do cluster do Atlas, do projeto Supabase e do Railway para descrever a transferência internacional com precisão.
6. **Retenção de logs do Railway:** confirmar o prazo no plano contratado.
7. **Revisão jurídica:** bases legais da seção 3 e a cláusula de transferência internacional da Cloudflare (art. 33).
8. **Publicação:** a App Store exige a URL da política. Hospedar o texto (sem esta seção) e linkar no app e no App Store Connect.
