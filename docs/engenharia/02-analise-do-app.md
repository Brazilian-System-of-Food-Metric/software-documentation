# DOC-02 — Análise técnica completa do BSFMappClone

**Projeto:** BSFM · PIM 4º semestre
**Alvo:** `C:\Users\Isaque\Documents\pim-4-semestre\BSFMappClone`
**Data:** 2026-11-13
**Método:** leitura estática integral do código-fonte (não houve execução do app nesta passada)
**Complementa:** DOC-01 (engenharia reversa do site modelo)

---

## 1. Inventário

### 1.1 Stack declarada — `MeusApp.csproj`

| Item | Versão |
|---|---|
| Target | `net8.0` |
| EF Core + SQLite + Npgsql | 8.0.11 |
| BCrypt.Net-Next | 4.0.3 |
| MailKit / MimeKit | 4.10.0 |
| YoloDotNet | 2.0.0 |
| ONNX Runtime | 1.19.0 |
| SkiaSharp (native Linux) | 2.88.8 |

Ambiente local: SDK .NET **10.0.201**, runtime ASP.NET Core **10.0.5**. O projeto mira `net8.0`, cujo runtime **não está instalado** — hoje o código não roda nesta máquina sem retarget ou instalação do runtime 8.

### 1.2 Tamanho

| Área | Arquivos | Linhas |
|---|---|---|
| `Program.cs` | 1 | 886 |
| `Controllers/` | 1 | 473 |
| `Services/` | 6 | 1.558 |
| `Models/` | 2 `.cs` + 3 modelos ONNX | 124 |
| `ClassesBSFM.cs` / `PonteDB.cs` / `Engrenagem.cs` | 3 | 276 + 102 + ~90 |
| `wwwroot/` | 11 páginas HTML + PWA | ~300 KB |

Modelos de IA: `bsfmv1_yolo_final.onnx` (12,3 MB), `yolov10n.onnx` (9,4 MB) e uma cópia `bsfmv1_yolo_final.onnxx` (12,3 MB) — extensão com erro de digitação, provavelmente duplicata inútil.

### 1.3 Telas reais

`index` · `login` · `dashboard` · `analisador-ia` · `analisador-rotulo` · `diario` · `metas` · `planos` · `hospitais` · `libras` · `alerta-saude-pendente`

PWA completa (`manifest.json`, `sw.js`, ícones maskable) — o app **já é instalável**, o que reduz o escopo da versão mobile.

---

## 2. Superfície de API

**33 rotas** em `Program.cs` + 1 controller (`PlanoAlimentarController`, 473 linhas) + 2 controllers em `BSFM.CoreAnalytics/Backend/Controllers` (`RotuloController`, `SaudeController`).

| Grupo | Rotas | Autenticação |
|---|---|---|
| Cadastro/Conta | `/solicitar-codigo`, `/cadastrar-usuario-final`, `/login`, `/esqueci-senha`, `/redefinir-senha` | **nenhuma** |
| Perfil | `/usuario/{id}`, `PUT /usuario/atualizar-nome`, `PUT /usuario/atualizar-senha`, `PUT /usuario/atualizar-data-nascimento` | **nenhuma** |
| Análise IA | `/analisar-prato`, `/api/rotulo/analisar`, `/historico-analises/{usuarioId}` | **nenhuma** |
| Progresso | `/evolucao/{usuarioId}`, `/atualizar-medicao`, `/definir-meta` | **nenhuma** |
| Água | `/registrar-agua`, `/agua-diario/{usuarioId}`, `/agua-semanal/{usuarioId}`, `DELETE /remover-ultima-agua/{usuarioId}` | **nenhuma** |
| Refeições | `/refeicoes-semana/{usuarioId}`, `/salvar-refeicao-semana`, `DELETE /remover-refeicao-semana/{id}` | **nenhuma** |
| Saúde | `/api/saude/{id}`, `PUT /api/saude/atualizar` | **nenhuma** |
| Infra | `/`, `/api/gerar-apk` | pública |

**Conclusão objetiva:** a API inteira é anônima. A identidade do usuário viaja como número na URL — quem troca o número lê os dados de outra pessoa.

---

## 3. Modelo de dados

### 3.1 Tabelas (`script_sql_completo.sql`)

| Tabela | Papel |
|---|---|
| `Usuarios` | identidade + antropometria + IMC/TMB/gasto + `TokenVerificacao`, `EmailVerificado`, `Diabetes`, `Intolerancia`, `PesoMeta`, `DataNascimento` |
| `AnalisesIA` | resultado da IA por alimento (calorias, macros, porção, `PodeConsumir`, `PontuacaoSaude`, textos de feedback) |
| `Historicos` | série de peso/altura/IMC por data |
| `ConsumoAgua` | ml por registro |
| `RefeicoesAgendadas` | prato por dia/tipo com macros |
| `CronogramasSemanais` + `RefeicoesDiarias` | plano alimentar semanal com FK em cascata |
| `Refeicoes`, `Comidas`, `Cronogramas`, `Hospitais` | catálogos e legado |

7 índices, todos por `UsuarioId` ou `CronogramaSemanalId` — adequados para as consultas existentes.

### 3.2 Problemas estruturais

| # | Problema | Impacto |
|---|---|---|
| D1 | `Refeição` e `Comida` são duplicatas (mesmos 8 campos) | ambiguidade de modelo |
| D2 | `Refeição` como identificador C# com acento, remapeado para `Refeicoes` | fragilidade em ferramentas e migrations |
| D3 | `Hospital` com 3 campos (nome, endereço, telefone) | não cobre "todos os hospitais de SP" |
| D4 | `CronogramaAlimentar` guarda refeições/planos como **string** | sem integridade relacional |
| D5 | Escolha SQLite/Postgres em `OnConfiguring` com DDL inline no startup | migrations ad-hoc, `DO $$` só funciona em Postgres |
| D6 | Sem tabela de sessão, refresh token, auditoria ou consentimento LGPD versionado | nada de segurança é persistido |

---

## 4. Achados de segurança

Classificação: **P0 = explorável hoje por qualquer pessoa com o app aberto.**

### P0-1 · Redefinição de senha de qualquer conta — `Program.cs:293-318`

```csharp
string token = new Random().Next(100000, 999999).ToString();
EmailService.EnviarToken(email, token);
return Results.Ok(new { mensagem = "Código enviado com sucesso!", tokenParaJs = token });
```

O servidor devolve o código de verificação **na própria resposta HTTP**. Quem chamar `POST /esqueci-senha` com um e-mail recebe o código sem ter acesso à caixa de entrada.

### P0-2 · `/redefinir-senha` não valida token nenhum — `Program.cs:321-345`

Recebe `{ email, novaSenha }` e grava o hash. Não há token, não há prova de identidade. Combinado com P0-1, o fluxo de recuperação é uma porta aberta.

### P0-3 · IDOR em todas as rotas por id

`/usuario/{id}`, `/historico-analises/{usuarioId}`, `/evolucao/{usuarioId}`, `/agua-diario/{usuarioId}`, `/api/saude/{id}` — qualquer `id` é aceito. Mais grave:

```csharp
app.MapPut("/usuario/atualizar-senha", …)  // troca a senha de QUALQUER id
```

Basta um `PUT` com `{ id: 1, novaSenha: "..." }` para assumir a conta mais antiga do banco.

### P0-4 · Sessão é um JSON no `localStorage`

`wwwroot/login.html:462` grava `usuarioLogado` com os dados do usuário. As 11 páginas leem esse objeto e passam `userLocal.id` nas chamadas. Nada é assinado, nada expira, nada é verificado no servidor. Abrir o DevTools e editar o `id` troca de usuário.

### P0-5 · CORS aberto em API de dados de saúde — `Program.cs:29-32`

`AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod()` permite que qualquer site faça requisições autenticadas pelo navegador do usuário.

### P1 — exploráveis com esforço

| # | Achado | Local |
|---|---|---|
| P1-1 | Sem rate limit em `/login` nem em `/esqueci-senha`; `404 "E-mail não encontrado"` permite enumerar contas | `Program.cs:258-302` |
| P1-2 | Senha trafega como `SenhaHash` em texto claro no cadastro | `Program.cs:237` |
| P1-3 | Código de 6 dígitos gerado com `System.Random` (não criptográfico) | `Program.cs:305` |
| P1-4 | Comparação do código acontece no JavaScript do cliente | fluxo de `esqueci-senha` |
| P1-5 | `Accept-Encoding`/HTTPS: servidor sobe em `http://0.0.0.0` fixo, sem redirect nem HSTS | `Program.cs:26` |
| P1-6 | E-mail de login impresso no console a cada tentativa | `Program.cs:254` |
| P1-7 | `BREVO_API_KEY` com fallback `"chave_nao_encontrada"` — falha silenciosa | `ClassesBSFM.cs:177` |
| P1-8 | `EnsureCreated()` a cada boot + DDL inline | `Program.cs:77` |
| P1-9 | Endpoint `/api/gerar-apk` compila APK dentro do servidor web | `Program.cs:190` |

---

## 5. Pipeline de IA — como está

```
foto → YoloInferenceService (YOLOv8 custom, 452 classes, confiança 0.16)
     → tradução EN→PT (dicionário embutido)
     → UsdaNutritionService (macros por 100 g)
     → ContextInjectorService + NutriBrainService (Groq Llama 3: "pode consumir?")
     → AnaliseIA gravada
```

| Observação | Leitura |
|---|---|
| `bsfmv1_yolo_final.onnx` (12,3 MB) treinado no projeto | modelo próprio, cobertura limitada ao dataset |
| Threshold **0.16** | muito baixo: aceita detecção com 16% de confiança — explica falsos positivos |
| `yolov10n.onnx` presente mas não é o modelo principal | peso morto (9,4 MB) |
| Duas cópias do mesmo modelo (`.onnx` e `.onnx` com typo) | +12,3 MB inúteis |
| Feedback nutricional via Groq | depende de chave externa e de rede em tempo de requisição |
| Sem versionamento de modelo nem de dataset | não há como reproduzir um resultado antigo |

**Recomendação:** manter YOLO como detector de região e mover a *classificação* para um modelo pronto de alimentos, com o USDA/Open Food Facts como fonte nutricional e o LLM apenas como camada de explicação. O threshold precisa subir para 0,45–0,55 com fallback explícito ("não identificado") — hoje ele chuta.

---

## 6. O que já foi construído nesta fase

### 6.1 Camada de segurança — `REMASTER/backend/BSFM.Seguranca`

Biblioteca sem dependências externas (só BCL), compilada em `net10.0` e verificada por um harness com **47 asserções, todas passando**.

| Arquivo | Responsabilidade |
|---|---|
| `Base64Url.cs` | codificação única usada por token, nonce e jti |
| `SessaoToken.cs` | JWT HS256: emite e valida com `alg` fixo, comparação em tempo constante, expiração e versão de formato |
| `SenhaHasher.cs` | PBKDF2-SHA256 com 210.000 iterações, salt por senha, formato versionado e `PrecisaRehash` |
| `AssinaturaRequisicao.cs` | HMAC-SHA256 sobre `MÉTODO\nROTA\nTIMESTAMP\nNONCE\nSHA256(corpo)`, janela de 5 min e anti-replay por nonce |
| `Totp.cs` | RFC 6238, 6 dígitos, 30 s, tolerância de ±1 passo |

### 6.2 Prova de funcionamento

```
[1] Token de sessão (JWT HS256) ...................... 15 PASS
[2] Hash de senha (PBKDF2-SHA256) .................... 10 PASS
[3] Assinatura por requisição (HMAC + anti-replay) ... 10 PASS
[4] TOTP (RFC 6238) vetores oficiais ................. 12 PASS
===================================================== 47 PASS / 0 FAIL
```

Casos que importam para a banca:

- Token com `alg: none` é rejeitado.
- Corpo do token adulterado (troca `usuarioId`) é rejeitado pela assinatura.
- Token assinado com outra chave é rejeitado.
- Replay do mesmo nonce é rejeitado; nonce queimado por tentativa forjada **não** bloqueia a requisição legítima.
- Corpo, rota, método ou timestamp alterados invalidam a assinatura.
- TOTP confere contra os quatro vetores oficiais do RFC 6238 (`94287082`, `07081804`, `69279037`, `65353130`).

Como rodar:

```powershell
cd C:\Users\Isaque\Documents\pim-4-semestre\REMASTER\backend\BSFM.Seguranca.Verificacao
dotnet run
```

---

## 7. Plano de correção — ordem de execução

| Fase | Entrega | Estado |
|---|---|---|
| **S0** | Núcleo criptográfico (token, senha, assinatura, TOTP) | **concluído e verificado** |
| **S1** | `AuthController` + `[SessaoObrigatoria]` aplicado nas 33 rotas; remover `tokenParaJs`; refresh token rotativo | próximo |
| **S2** | Migrar Minimal API → Controllers + Services + DTOs com herança e encapsulamento | a fazer |
| **S3** | EF Core migrations reais; schema com `Sessoes`, `RefreshTokens`, `Auditoria`, `ConsentimentoLGPD` | a fazer |
| **S4** | Rate limit, bloqueio progressivo, verificação de e-mail obrigatória | a fazer |
| **S5** | Front React (web) consumindo a API assinada | a fazer |
| **S6** | App mobile React com o mesmo contrato | a fazer |
| **S7** | Base de hospitais de SP (CNES/DATASUS) com geolocalização | a fazer |
| **S8** | IA de alimentos: modelo pronto + USDA/Open Food Facts | a fazer |
| **S9** | Documentação final do PIM | a fazer |

### 7.1 Contrato da autenticação (S1)

```
POST /api/auth/login
  { email, senha, codigoTotp? }
  → 200 { token, refreshToken, expiraEm, usuario: { id, nome, imc… } }
  → 401 { erro: "credenciais_invalidas" }          (sem revelar qual campo)

POST /api/auth/refresh
  { refreshToken }
  → 200 { token, refreshToken }                     (rotação: o antigo é revogado)

POST /api/auth/logout
  Authorization: Bearer <token> + refreshToken
  → 204

POST /api/auth/esqueci-senha
  { email }
  → 202 { mensagem: "se o e-mail existir, enviamos um código" }  (sempre 202: não enumera)
  ✗ nunca devolve o código

POST /api/auth/redefinir-senha
  { email, codigo, novaSenha }
  → 200 | 400 { erro: "codigo_invalido" }
```

Regra que fecha o buraco atual: **a identidade vem do token, nunca da URL.** `GET /api/eu/perfil` substitui `/usuario/{id}`; `GET /api/eu/historico` substitui `/historico-analises/{usuarioId}`.

### 7.2 Cabeçalhos por requisição (S1)

```
Authorization: Bearer <token>
X-BSFM-Timestamp: 1763078400
X-BSFM-Nonce: 9f2c1a7b8e4d0563
X-BSFM-Signature: <hex do HMAC>
```

O `VerificadorAssinatura` valida os três últimos; o `EmissorSessao` valida o primeiro.

---

## 8. Riscos do processo

| Risco | Mitigação |
|---|---|
| Retarget `net8.0` → `net10.0` pode quebrar `YoloDotNet`/`SkiaSharp` | testar em branch; manter `net8.0` e instalar runtime 8 se falhar |
| `EnsureCreated` + tabelas já existentes no Neon | migrations idempotentes, nunca `EnsureCreated` em produção |
| Dados reais de saúde no banco de teste | nunca copiar o banco de produção para desenvolvimento |
| Reescrever tudo de uma vez | fatiar por controller e manter os endpoints antigos até o front migrar |

---

## 9. Rastreabilidade

| Fonte | O que sustentou |
|---|---|
| Leitura de `Program.cs`, `ClassesBSFM.cs`, `PonteDB.cs`, `MeusApp.csproj`, `script_sql_completo.sql` | inventário, rotas, achados P0/P1 |
| `grep` por `localStorage` nas 11 páginas | P0-4 |
| Leitura de `MeusApp.csproj` + `dotnet --list-runtimes` | incompatibilidade de runtime |
| Execução do harness | 47 asserções de segurança |

Não houve execução do app nem teste dinâmico das rotas nesta passada — os achados P0 são de **leitura de código**, e a exploração não foi tentada.
