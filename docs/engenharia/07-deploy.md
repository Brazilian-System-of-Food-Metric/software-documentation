# Deploy no Render

Guia operacional da v2: o que sobe, quais variáveis configurar e como diagnosticar
os erros mais comuns.

---

## 1. Os dois serviços

| Serviço | Runtime | O que roda | Situação |
|---|---|---|---|
| `bsfm-api` | .NET (nativo) | aplicação v1 — Minimal API, YOLO, OCR | intacta |
| `bsfm-v2` | Docker | API .NET 10 + React compilado | nova |

O Blueprint (`render.yaml`) declara os dois. A v1 continua respondendo no endereço
antigo; a v2 sobe em paralelo para migração gradual.

O container da v2 tem três estágios:

1. **web** — `node:22-alpine` compila o React (`vite build`);
2. **build** — `sdk:10.0` publica a API;
3. **final** — `aspnet:10.0` serve a API e o front em `wwwroot`.

Resultado: uma URL, um container, sem CORS entre front e API.

---

## 2. Variáveis de ambiente

### Obrigatórias

| Variável | Como obter | Sintoma se faltar |
|---|---|---|
| `BSFM_JWT_SECRET` | `generateValue: true` no Blueprint | serviço **não sobe** (trava de produção) |
| `BSFM_HMAC_SECRET` | `generateValue: true` no Blueprint | serviço **não sobe** |
| `DATABASE_URL` | mesmo Postgres da v1 (Neon) | cai para SQLite efêmero — dados somem a cada deploy |

> A trava é intencional: os valores padrão do código são públicos. Subir com eles
> permitiria forjar token e assinatura.

### Recomendadas

| Variável | Padrão | Para que serve |
|---|---|---|
| `BREVO_API_KEY` | vazio | envia o código de verificação por e-mail |
| `BSFM_EMAIL_REMETENTE` | `brazilian.sfm@gmail.com` | remetente verificado no Brevo |
| `BSFM_EMAIL_NOME` | `Portal BSFM` | nome que aparece no e-mail |
| `BSFM_GEMINI_API_KEY` | vazio | reconhecimento de alimento por imagem |
| `BSFM_GEMINI_MODEL` | `gemini-2.5-flash` | modelo de visão |
| `BSFM_ORIGENS_PERMITIDAS` | localhost | CORS explícito (lista separada por vírgula) |

---

## 3. Diagnóstico dos erros já vistos

### "Erro ao criar conta"

A v2 não tinha rota de cadastro — qualquer `POST /api/auth/cadastrar` respondia 404.
Corrigido: a rota existe, valida os campos, grava em PBKDF2, registra consentimento
LGPD e devolve 201. O front ganhou a tela **Criar conta**.

Se ainda falhar, verifique no log:

| Mensagem | Causa |
|---|---|
| `email_ja_cadastrado` (409) | conta já existe — use "Entrar" |
| `termos_nao_aceitos` (400) | o checkbox de LGPD não foi marcado |
| `nome_invalido` / `senha_invalida` (400) | menos de 3 caracteres / menos de 8 |
| erro 500 | migrations falharam — veja a seção 4 |

### "O código do Brevo não chega"

Duas causas possíveis, nesta ordem:

1. **`BREVO_API_KEY` ausente** — o app usa o enviador de console e o código vai
   apenas para o log. Procure no log do Render:
   `BREVO_API_KEY ausente: códigos de verificação vão apenas para o console`.
2. **Brevo recusou** — o log traz o status e o corpo da resposta:
   `Brevo recusou o envio para a***@dominio: 401 {"message":"Key not found"}`.
   Causas comuns: chave inválida, remetente não verificado no Brevo.

Quando o envio funciona, o log mostra:
`Código enviado para a***@dominio via Brevo.`

---

## 4. Migrations

A v2 aplica migrations no boot. Elas são **aditivas**: criam `Sessoes`,
`RefreshTokens`, `Auditoria`, `ConsentimentosLGPD`, `Metas` e `Alimentos`. Nenhuma
tabela da v1 é removida.

Se a migration falhar, o serviço **continua no ar** (o Render precisa do healthcheck)
e registra o motivo. O caso mais comum é e-mail duplicado bloqueando
`IX_Usuarios_Email_Unico`:

```sql
-- 1. ver duplicatas
SELECT lower("Email"), count(*) FROM "Usuarios" GROUP BY 1 HAVING count(*) > 1;

-- 2. renomear as repetidas (mantendo a mais antiga)
UPDATE "Usuarios" u
SET "Email" = u."Email" || '.duplicado.' || u."ID"
WHERE u."ID" IN (
  SELECT id FROM (
    SELECT "ID" AS id,
           row_number() OVER (PARTITION BY lower("Email") ORDER BY "ID") AS ordem
    FROM "Usuarios"
  ) t WHERE t.ordem > 1
);
```

Depois, reinicie o serviço.

---

## 5. Validação local antes de subir

```bash
# 1. construir a imagem exatamente como o Render fará
docker build -f v2/Dockerfile -t bsfm-v2:test v2

# 2. rodar com os segredos
docker run -d --name bsfm-v2 -p 5101:10000 \
  -e BSFM_JWT_SECRET="<32+ bytes>" \
  -e BSFM_HMAC_SECRET="<32+ bytes>" \
  bsfm-v2:test

# 3. conferir saúde, front e catálogo
curl http://127.0.0.1:5101/saude
curl http://127.0.0.1:5101/api/nutricao/provedor
```

O `provedor` deve responder `{"catalogo":{"origem":"taco","alimentos":582},...}`.
Se responder `origem: semente`, o CSV não entrou na imagem.

---

## 6. Suítes de verificação

| Suíte | Asserções |
|---|---|
| `BSFM.Seguranca.Verificacao` | 47 |
| `BSFM.Dados.Verificacao` | 53 |
| `BSFM.Nutricao.Verificacao` | 66 |
| `smoke-s2.ps1` (auth, perfil, saúde) | 32 |
| `smoke-s3.ps1` (água, refeições, metas, análises) | 38 |
| `smoke-s4.ps1` (nutrição) | 31 |
| `smoke-s5.ps1` (cadastro e verificação) | 14 |
| **Total** | **281** |
