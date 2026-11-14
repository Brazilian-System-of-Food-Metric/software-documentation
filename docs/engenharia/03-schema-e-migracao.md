# DOC-03 — Schema do banco e S2 (controllers + sessão verificada)

**Projeto:** BSFM · PIM 4º semestre
**Data:** 2026-11-13
**Entregas:** schema versionado com migrations e a primeira fatia do backend migrado para controllers
**Verificação:** 53 asserções de schema + 31 asserções HTTP — todas passando

---

## 1. Schema

### 1.1 Onde está

```
REMASTER/backend/BSFM.Dados/
  Entidades/Dominio.cs          → usuário, análises, histórico, água, refeições, hospital, meta, alimento
  Entidades/Seguranca.cs        → sessão, refresh token, auditoria, consentimento LGPD
  BsfmDbContext.cs              → mapeamento, índices e cascatas
  FabricaContexto.cs            → provedor em runtime + parsing de DATABASE_URL
  Migracoes/Postgres/           → migration versionada (autoridade do schema)
  esquema-postgres.sql          → DDL idempotente, 17 KB
```

### 1.2 Tabelas

**Existentes, preservadas sem renomear coluna:**

| Tabela | O que guarda |
|---|---|
| `Usuarios` | identidade, antropometria, IMC/TMB/gasto, 2FA, bloqueio |
| `AnalisesIA` | resultado da IA por alimento |
| `Historicos` | série de peso/altura/IMC |
| `ConsumoAgua` | ml por registro |
| `RefeicoesAgendadas` | prato por dia/tipo |
| `CronogramasSemanais` + `RefeicoesDiarias` | plano alimentar semanal |
| `Hospitais` | estabelecimentos de saúde |

**Novas:**

| Tabela | Papel | Por que |
|---|---|---|
| `Sessoes` | uma linha por login, com `Jti`, expiração e revogação | permite encerrar sessão antes do token expirar |
| `RefreshTokens` | hash SHA-256 do refresh, rotação e cadeia | detecta roubo de token por reuso |
| `Auditoria` | evento + entidade + IP em hash | rastreabilidade sem guardar dado sensível |
| `ConsentimentosLGPD` | finalidade + versão do termo + data | dado de saúde é categoria especial |
| `Metas` | meta calórica/hídrica/peso por usuário | antes era campo solto em `Usuarios` |
| `Alimentos` | base TACO local | análise nutricional sem depender de API externa |

### 1.3 Campos acrescentados em `Usuarios`

`TotpSegredo`, `TotpHabilitado`, `Papel`, `TentativasFalhas`, `BloqueadoAte`, `SenhaAtualizadaEm`, `TokenVerificacaoExpiraEm`, `CriadoEm`, `AtualizadoEm`.

### 1.4 Campos acrescentados em `AnalisesIA`

`Confianca` (0..1), `ModeloVersao`, `ImagemHash`, `Origem` — o que faltava para reprodutibilidade do resultado da IA.

### 1.5 Decisões que mudam comportamento

| Decisão | Efeito | Cuidado |
|---|---|---|
| `IX_Usuarios_Email_Unico` | acaba com cadastro duplicado | **exige deduplicar antes de aplicar** (SQL abaixo) |
| `IX_Hospitais_Cnes_Unico` | importação de SP idempotente | CNES nulo é permitido (NULL não colide) |
| `Sessoes.Id` / `RefreshTokens.Id` em `uuid` | id não previsível | — |
| Cascata em tudo que pertence ao usuário | apagar conta apaga dados (LGPD art. 18) | irreversível |
| `RefreshTokens.TokenHash` guarda SHA-256 | vazamento do banco não entrega sessão | nunca logar o token em claro |

### 1.6 Pré-voo obrigatório antes de aplicar no banco real

E-mails duplicados fazem a migration falhar no índice único. Rode primeiro:

```sql
-- 1. Verificar duplicatas
SELECT lower("Email") AS email, count(*) AS total, array_agg("ID") AS ids
FROM "Usuarios"
GROUP BY lower("Email")
HAVING count(*) > 1;

-- 2. Resolver (exemplo: manter o mais antigo, renomear os demais)
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

### 1.7 Como aplicar

```powershell
# gerar/regerar a migration (Postgres é a autoridade)
$env:BSFM_BD_PROVIDER = "npgsql"
dotnet ef migrations add <Nome> --project BSFM.Dados --output-dir Migracoes/Postgres

# produzir o DDL idempotente
dotnet ef migrations script --idempotent --output esquema-postgres.sql --project BSFM.Dados

# aplicar no banco (DATABASE_URL do Neon/Railway)
dotnet ef database update --project BSFM.Dados
```

> Observação de ambiente: nesta máquina o `dotnet-ef` global precisa rodar via
> `dotnet <caminho>\dotnet-ef.dll` com `DOTNET_ROLL_FORWARD=LatestMajor`, porque
> a ferramenta é compilada para net8 e só o runtime 10 está instalado.

### 1.8 Postgres vs SQLite

- **Postgres** (`DATABASE_URL` presente): `Database.Migrate()` — migrations versionadas.
- **SQLite** (desenvolvimento): `EnsureCreated()` a partir do modelo, sem migration.

Isso é uma escolha consciente: manter duas famílias de migration para dois
provedores custa mais do que rende. A autoridade do schema é Postgres; SQLite
existe para rodar sem servidor de banco.

---

## 2. S2 — controllers com sessão verificada

### 2.1 Camadas

```
BSFM.Seguranca   → criptografia pura (token, HMAC, PBKDF2, TOTP)     [sem dependências]
BSFM.Dados       → entidades + DbContext + migrations
BSFM.Api         → controllers, filtros, serviços de aplicação
```

Dependência aponta sempre para baixo: `Api → Dados → Seguranca`. Nenhuma camada
de baixo conhece a de cima.

### 2.2 O filtro que substitui o "id na URL"

`[SessaoObrigatoria]` roda antes de qualquer action e verifica, nesta ordem:

1. **Token** — assinatura HS256, algoritmo fixo, expiração.
2. **Sessão viva** — existe em `Sessoes`, não revogada, não expirada, mesmo usuário.
3. **Assinatura da requisição** — HMAC sobre método + rota + timestamp + nonce + hash do corpo.

Só depois disso o controller executa, e a identidade vem de
`HttpContext.Items["usuarioId"]` — nunca de `[FromRoute]` ou do corpo.

### 2.3 Endpoints

| Antes (anônimo) | Agora | Proteção |
|---|---|---|
| `POST /login` (devolvia dados e nenhum token) | `POST /api/auth/login` | emite token + refresh; bloqueia após 5 falhas |
| — | `POST /api/auth/refresh` | rotação + detecção de reuso |
| — | `POST /api/auth/logout` | revoga sessão |
| `POST /esqueci-senha` (**devolvia o código**) | `POST /api/auth/esqueci-senha` | 202 sempre, código só por e-mail |
| `POST /redefinir-senha` (**sem token**) | `POST /api/auth/redefinir-senha` | exige código TOTP válido |
| `GET /usuario/{id}` | `GET /api/eu/perfil` | sessão + assinatura |
| `PUT /usuario/atualizar-nome` | `PUT /api/eu/nome` | sessão + assinatura |
| `PUT /usuario/atualizar-senha` (**qualquer id**) | `PUT /api/eu/senha` | exige senha atual; revoga as outras sessões |
| `GET /api/saude/{id}` | `GET /api/eu/saude` | sessão + assinatura |
| `PUT /api/saude/atualizar` | `PUT /api/eu/saude` | recalcula IMC/TMB no servidor |
| — | `GET /api/eu/saude/historico` | série por usuário |
| — | `GET /api/eu/sessoes` | lista dispositivos, marca o atual |
| — | `DELETE /api/eu/sessoes[/{id}]` | encerra uma ou todas |

### 2.4 Regras de negócio que passaram para o servidor

- **IMC, TMB e gasto** são recalculados a partir do estado final no banco — o cliente não envia mais valor calculado.
- **Toda mudança de peso** gera um ponto em `Historicos`.
- **Aceite de termos** cria registro em `ConsentimentosLGPD` com versão, data, origem e hash de IP.
- **Troca de senha** revoga as outras sessões; redefinição por código revoga todas.
- **Login** zera tentativas, aplica bloqueio de 15 min após 5 falhas e promove hash legado.

### 2.5 Compatibilidade com o banco atual

Hashes antigos são BCrypt (`$2a$…`); os novos são PBKDF2. `ServicoSenha` detecta o
formato, verifica no formato certo e **promove para PBKDF2 no primeiro login bem-sucedido**.
Sem isso, todo usuário existente ficaria trancado para fora após a migração.

---

## 3. Verificação

### 3.1 Schema — `BSFM.Dados.Verificacao`

```
[1] Tabelas criadas ............................ 15 PASS
[2] Índices (20 esperados) ..................... 20 PASS
[3] Chaves estrangeiras com cascata ............  7 PASS
[4] Regras do modelo exercitadas ...............  8 PASS
[5] Hospital com dados geográficos .............  3 PASS
================================================  53 PASS / 0 FAIL
```

Inclui prova de que e-mail duplicado é recusado, CNES duplicado é recusado, e
que apagar o usuário derruba sessões, refresh, análises e consentimentos.

### 3.2 API — `smoke-s2.ps1`

```
[0] Serviço no ar ..............................  1 PASS
[1] Login e emissão de sessão ...................  6 PASS
[2] Rota antiga por id não existe mais .........  1 PASS
[3] Perfil: identidade vem do token ............  4 PASS
[4] Atualização de nome ........................  3 PASS
[5] Dados de saúde .............................  7 PASS
[6] Sessões ....................................  2 PASS
[7] Troca de senha .............................  3 PASS
[8] Logout e refresh ...........................  2 PASS
[9] Bloqueio progressivo por força bruta .......  1 PASS
================================================  31 PASS / 0 FAIL
```

Casos que valem para a banca:

- Conta com 2FA recusa login sem código.
- Hash BCrypt legado autentica e é promovido.
- `GET /api/saude/1` (rota antiga por id) responde 404 — não existe mais.
- Sem assinatura HMAC, mesmo com token válido, a resposta é 401.
- Trocar a senha invalida a senha antiga e o refresh anterior.
- Cinco senhas erradas bloqueiam a conta mesmo com a senha correta em seguida.

### 3.3 Como rodar

```powershell
# schema
cd REMASTER\backend\BSFM.Dados.Verificacao
dotnet run

# API
cd REMASTER\backend\BSFM.Api
dotnet run                      # http://127.0.0.1:5100

# testes HTTP (outro terminal)
powershell -File REMASTER\backend\smoke-s2.ps1
```

Credenciais de desenvolvimento: `ana@bsfm.dev` (sem 2FA), `bia@bsfm.dev` (com 2FA),
`carla@bsfm.dev` (hash BCrypt legado) — senha `SenhaForte#2026` para as três.

---

## 4. O que ainda falta (S3+)

| # | Item | Observação |
|---|---|---|
| 1 | Migrar as rotas restantes | água, refeições da semana, análise de prato/rótulo, metas, evolução |
| 2 | Trocar o `Program.cs` legado pelos controllers | o app original continua intacto; esta entrega é paralela |
| 3 | Repositório EF no lugar do in-memory da demo | `BSFM.Api.Seguranca` é prova de contrato, não produção |
| 4 | Seed da base TACO e dos hospitais de SP (CNES) | tabelas prontas, dados ainda não importados |
| 5 | Rate limit por IP no login | hoje o bloqueio é por conta |
| 6 | Verificação de e-mail obrigatória | campo existe, regra ainda não |
| 7 | Front React + app mobile | consomem o contrato acima |
| 8 | Retarget do projeto legado para net10 | hoje mira net8, runtime não instalado |

---

## 5. Riscos assumidos

| Risco | Mitigação |
|---|---|
| Índice único de e-mail falhar no banco real | rodar o pré-voo da seção 1.6 antes |
| Migration Postgres aplicada em SQLite por engano | `BSFM_BD_PROVIDER` decide; SQLite usa `EnsureCreated` |
| Serviço in-memory da demo ser confundido com produção | `BSFM.Api.Seguranca` é rotulado como prova de contrato |
| Duas APIs rodando (demo 5099 e S2 5100) | portas distintas; a demo pode ser apagada quando não for mais útil |

---

## 6. Rastreabilidade

| Fonte | Sustentou |
|---|---|
| `BsfmDbContext.cs` + migration `Inicial` + `esquema-postgres.sql` | 14 tabelas, 20 índices, 7 cascatas |
| Execução de `BSFM.Dados.Verificacao` | 53 asserções de schema |
| Execução de `smoke-s2.ps1` contra `BSFM.Api` | 31 asserções HTTP |
| Leitura de `Program.cs` legado (DOC-02) | mapa antes → depois dos endpoints |
