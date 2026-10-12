# App Review

Conta de demonstração para a revisão da Apple. A senha não fica neste arquivo.

email: lero-reviewer@maisoumenos170.com

Crie esse usuário na API de produção (`POST /register`) com uma senha de pelo menos 8 caracteres, contendo uma letra e um número. Grave essa senha no secret `APP_REVIEW_PASSWORD` do repositório `MaisOuMenos170/Zanzar`.

O workflow `TestFlight preflight` usa este e-mail e esse secret para entrar em `POST /login` antes de a `main` seguir para o TestFlight.
