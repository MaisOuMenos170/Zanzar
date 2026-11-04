# Termo das fotos de usuário (para revisão jurídica)

Texto que o app mostra antes do primeiro envio (`PhotoTermsView`) e de novo em Perfil > Fotos e privacidade. Versão **2026-11-03**: as constantes `PhotoTerms.version` (app) e `USER_PHOTO_TERMS_VERSION` (backend) guardam esse valor. Qualquer mudança no texto exige subir as duas, e então todos aceitam de novo.

O texto fica em `Localizable.xcstrings`, nas chaves `userPhotos.terms.*`. Abaixo está a versão em pt-BR; a em inglês tem o mesmo conteúdo.

## Texto atual

> Antes de enviar sua primeira foto, veja como funciona. Você pode reler isto quando quiser em Perfil > Fotos e privacidade.

**Análise antes de publicar**

Toda foto passa por uma análise automática e, na dúvida, por uma pessoa da equipe do Lero. Os outros só a veem depois de aprovada. Até lá, só você vê, marcada como "em análise".

**Quanto tempo leva**

A análise automática leva poucos minutos. Quando uma pessoa precisa olhar, pode levar alguns dias. O app avisa quando sair o resultado.

**O que não pode**

Pessoas reconhecíveis em primeiro plano, crianças e adolescentes, nudez, violência, marca d'água, foto de outra pessoa ou tirada da internet e foto que não mostra o lugar. Não envie a mesma foto duas vezes.

**Localização removida**

Antes de sair do seu celular, a foto é reduzida e perde todos os dados escondidos: localização (GPS), modelo do aparelho e data.

**Análise por IA de terceiro**

A análise automática envia uma cópia reduzida da foto para um modelo de inteligência artificial da Cloudflare, que responde e não guarda a imagem nem a usa para treinar modelos.

**Sua licença e seu crédito**

A foto continua sua. Ao enviar, você dá ao Lero uma licença gratuita e não exclusiva para mostrá-la no app, que termina quando você a apaga. Seu nome de usuário aparece como crédito, a menos que você escolha ficar anônimo.

**Apagar e denunciar**

Apague suas fotos quando quiser em Perfil > Minhas fotos; elas somem do app e dos nossos servidores. Para denunciar a foto de outra pessoa, toque no menu ••• sobre ela.

**Seus dados**

Usamos a foto só para mostrá-la no lugar. Ela fica guardada de forma privada enquanto estiver no app; foto não aprovada é apagada em 30 dias. Para acessar, corrigir ou apagar seus dados, use o contato em Fotos e privacidade.

**Data de nascimento**

É preciso ter 18 anos ou mais para enviar fotos. Usamos a data só para conferir a idade; ela não fica guardada.

Para aceitar, o usuário marca duas opções; o botão "Aceitar e continuar" só funciona com as duas marcadas:

- [ ] Li e aceito como as fotos funcionam
- [ ] Aceito que minhas fotos sejam analisadas pela IA da Cloudflare

Se a pessoa tiver menos de 18 anos, aparece: "Só quem tem 18 anos ou mais pode enviar fotos."

## O que fica registrado

- **No aceite**, em `users.photoTerms` e `users.ageDeclaration`: a versão do texto, a data do aceite, se a pessoa declarou ser maior de idade e quando declarou (sempre `self_declared`). A data de nascimento **não** é guardada.
- **Em cada foto:** a versão do termo aceita (`user_photos.termsVersion`) e se o autor quer aparecer como crédito (`showAuthorName`).
- **Auditoria** (`user_photo_events`): envio, decisão de cada camada, revisão humana, denúncia e remoção, sem a imagem.

## Pontos para o advogado [REVISÃO JURÍDICA]

1. **Base legal (LGPD):**
   - Para exibir a foto, proponho "execução de contrato" (art. 7º, V): é o serviço que o usuário pediu.
   - Para mandar a foto à IA da Cloudflare, proponho "consentimento" (art. 7º, I), pela opção específica de aceite. Isso também atende a diretriz 5.1.2(i) da Apple.
   - Está correto? A Cloudflare fica nos EUA: precisa de cláusula de transferência internacional (art. 33)?
2. **Idade:** 18+ por autodeclaração basta? O app como um todo deveria exigir 18+ (a classificação da App Store deve sair 18+ por causa do álcool)?
3. **Terceiros na foto:** a regra "nada de pessoa reconhecível em primeiro plano" e o borrão no aparelho bastam para o direito de imagem? E pessoas ao fundo?
4. **Licença:** "gratuita, não exclusiva, para mostrar no app, termina quando apaga". Falta algo, como o uso em divulgação? Hoje **não** está incluído, de propósito.
5. **Direitos autorais:** quem envia declara que a foto é sua? Hoje o termo só diz que não pode "foto de outra pessoa ou tirada da internet". Vale pedir uma declaração explícita?
6. **Retenção:**
   - Foto publicada: fica até o autor apagar ou até a conta ser excluída.
   - Foto reprovada: os arquivos são apagados em 30 dias; o hash fica para impedir o reenvio. "Foto não aprovada é apagada em 30 dias" descreve isso bem?
   - Registro de auditoria: fica sem prazo. Proponho 5 anos. Qual prazo vocês recomendam?
7. **Canal do titular:** o e-mail de contato (`ZANZAR_SUPPORT_EMAIL`) ainda não existe. Qual prazo de resposta assumimos?
8. **Política de privacidade e termos de uso do app:** precisam ganhar uma seção sobre fotos e um link para este texto.
