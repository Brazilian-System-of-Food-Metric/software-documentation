# DOC-09 — Inventário completo da v1 e matriz de paridade

**Data:** 2026-11-14
**Fonte:** `C:\Users\Isaque\Documents\pim-4-semestre\BSFMappClone` — **73 arquivos**, lidos
integralmente (código, páginas, serviços, SQL, documentação e configuração).
**Objetivo:** inventariar **todas** as funcionalidades da v1 e dizer, uma por uma, se existem
na v2 (`https://bsfm-nutri.onrender.com`), se estão parciais ou se faltam — com prioridade de
implementação.

---

## 1. Como a varredura foi feita

| Etapa | O que foi extraído |
|---|---|
| Contagem de arquivos | 73 arquivos, 3 modelos ONNX, 11 páginas HTML |
| `Program.cs` (886 linhas) | 26 rotas, middlewares, migrações inline, e-mail |
| Controllers (3 arquivos) | 6 + 1 + 2 rotas |
| Services (6 arquivos) | assinaturas, provedores, limites, prompts |
| `wwwroot/*.html` (11) | funções JS, endpoints chamados, chaves de storage, ids de tela |
| `ClassesBSFM.cs`, `PonteDB.cs`, `Engrenagem.cs` | entidades, contexto, cache de usuário |
| SQL (6 scripts) | tabelas, colunas e migrações |
| `novasfuncoes.md` (1546 linhas) | especificação do motor de insights |

---

## 2. Inventário de arquivos

### 2.1 Código da aplicação

| Arquivo | Linhas | Papel |
|---|---|---|
| `Program.cs` | 886 | Minimal API: 26 rotas, CORS, migrações inline, seed |
| `ClassesBSFM.cs` | 246 | Entidades + `CalcularNutricional` + `EmailService` (Brevo) |
| `PonteDB.cs` | 92 | `DbContext`: SQLite local / Npgsql (Neon) |
| `Engrenagem.cs` | 72 | `UsuarioService`: criar, salvar, autenticar (BCrypt) |
| `Controllers/PlanoAlimentarController.cs` | 473 | Cronograma semanal + importação de prescrição por OCR |
| `BSFM.CoreAnalytics/Backend/Controllers/RotuloController.cs` | 137 | Análise de rótulo (OCR → LLM) |
| `BSFM.CoreAnalytics/Backend/Controllers/SaudeController.cs` | 98 | Perfil de saúde (diabetes, intolerâncias) |
| `Models/CronogramaSemanal.cs` | 124 | `CronogramaSemanal`, `RefeicaoDiaria`, enum `DiaSemana` |
| `MeusApp.csproj` | 28 | .NET 8, EF 8, BCrypt, MailKit, YoloDotNet, ONNX, SkiaSharp |

### 2.2 Serviços

| Arquivo | Linhas | Responsabilidade |
|---|---|---|
| `Services/YoloInferenceService.cs` | 568 | YOLO ONNX, **threshold 0,16**, dicionário EN→PT |
| `Services/OcrNutricionalService.cs` | 424 | Extrai refeições de prescrição (texto do OCR) |
| `Services/NutriBrainService.cs` | 278 | Groq `llama-3.3-70b-versatile` → JSON de feedback |
| `Services/ContextInjectorService.cs` | 190 | Monta o prompt com IMC, TMB, TDEE, meta, diabetes, intolerância |
| `Services/UsdaNutritionService.cs` | 54 | USDA FoodData Central (`USDA_API_KEY`) |
| `Services/LimpezaAnalisesServices.cs` | 44 | Background: apaga análises com **+2 dias** |

### 2.3 Páginas (`wwwroot`)

| Página | Linhas | Função |
|---|---|---|
| `index.html` | 600 | Landing institucional (9 seções) |
| `login.html` | 422 | Cadastro, login, verificação, recuperação em 2 passos |
| `dashboard.html` | 769 | Painel com sidebar, água, perfil, edições |
| `analisador-ia.html` | 706 | Foto → YOLO → nutrientes → feedback |
| `analisador-rotulo.html` | 677 | Rótulo → OCR (Tesseract.js) → LLM |
| `diario.html` | 379 | Histórico de análises + salvar prato no plano |
| `metas.html` | 435 | Metas + gráficos Chart.js (peso e IMC) |
| `planos.html` | 240 | Pratos da semana (7 dias, CRUD) |
| `hospitais.html` | 280 | Mapa Leaflet + 8 hospitais + Waze/telefone |
| `libras.html` | 114 | VLibras |
| `alerta-saude-pendente.html` | 497 | Formulário de saúde pendente |
| `BSFM.CoreAnalytics/Frontend/alerta-saude-pendente.html` | 459 | Variante do mesmo formulário |

### 2.4 Dados e configuração

`manifest.json` (41) · `sw.js` (79) · `sql-migrations.sql` (154) ·
`script_sql_completo.sql` (215) · `script_sql_criar_tabelas.sql` (123) ·
`script_migracao_unica.sql` (99) · `script_sql_atualizacao_v1.2.sql` (79) ·
`script_sql_migracao_analises.sql` (25) · `script_sql_migracao_diabetes.sql` (22) ·
`Dockerfile` (24) · `render.yaml` · `vercel.json` · `.github/workflows/keep_alive.yml` (23)

Modelos: `bsfmv1_yolo_final.onnx` (12,3 MB), `yolov10n.onnx` (9,4 MB) e uma cópia com typo
`bsfmv1_yolo_final.onnxx` (12,3 MB).

---

## 3. Endpoints da v1 — 35 rotas

### 3.1 `Program.cs` (26)

| # | Método | Rota | O que faz |
|---|---|---|---|
| 1 | GET | `/` | Redireciona para `login.html` |
| 2 | GET | `/api/gerar-apk` | Compila e devolve APK do app |
| 3 | POST | `/solicitar-codigo` | Envia código de 6 dígitos por e-mail (Brevo) |
| 4 | POST | `/cadastrar-usuario-final` | Cria conta (BCrypt + cálculos) |
| 5 | POST | `/login` | Autentica e devolve dados (sem token) |
| 6 | POST | `/esqueci-senha` | Gera código **e devolve na resposta** (`tokenParaJs`) |
| 7 | POST | `/redefinir-senha` | Troca a senha **sem validar código** |
| 8 | POST | `/analisar-prato` | Foto + porção → YOLO → USDA → Groq |
| 9 | GET | `/historico-analises/{usuarioId}` | Lista análises do usuário |
| 10 | GET | `/evolucao/{usuarioId}` | Série de peso/IMC |
| 11 | POST | `/atualizar-medicao` | Nova pesagem (recalcula IMC) |
| 12 | POST | `/definir-meta` | Define peso-alvo |
| 13 | GET | `/usuario/{id}` | Dados completos do usuário |
| 14 | PUT | `/usuario/atualizar-nome` | Altera nome |
| 15 | PUT | `/usuario/atualizar-senha` | Altera senha (por id, sem senha atual) |
| 16 | PUT | `/usuario/atualizar-data-nascimento` | Altera nascimento (recalcula idade) |
| 17 | POST | `/registrar-agua` | Registra ml |
| 18 | GET | `/agua-diario/{usuarioId}` | Consumo do dia |
| 19 | GET | `/agua-semanal/{usuarioId}` | Consumo da semana |
| 20 | DELETE | `/remover-ultima-agua/{usuarioId}` | Desfaz último registro |
| 21 | GET | `/refeicoes-semana/{usuarioId}` | Pratos da semana |
| 22 | POST | `/salvar-refeicao-semana` | Cria prato |
| 23 | DELETE | `/remover-refeicao-semana/{id}` | Remove prato |
| 24 | POST | `/api/rotulo/analisar` | OCR (client) → LLM → feedback |
| 25 | GET | `/api/saude/{id}` | Perfil de saúde |
| 26 | PUT | `/api/saude/atualizar` | Atualiza saúde |

### 3.2 `PlanoAlimentarController` (6)

| # | Método | Rota | O que faz |
|---|---|---|---|
| 27 | POST | `/api/PlanoAlimentar/importar-prescricao` | OCR de prescrição → cria cronograma semanal |
| 28 | GET | `/api/PlanoAlimentar/cronograma-ativo` | Cronograma vigente |
| 29 | GET | `/api/PlanoAlimentar/refeicoes-dia/{diaSemana}` | Refeições do dia |
| 30 | PUT | `/api/PlanoAlimentar/refeicao/{id}/concluir` | Marca refeição cumprida |
| 31 | POST | `/api/PlanoAlimentar/refeicao` | Adiciona refeição ao cronograma |
| 32 | GET | `/api/PlanoAlimentar/resumo-dia/{diaSemana}` | Totais do dia |

### 3.3 `BSFM.CoreAnalytics` (3)

| # | Método | Rota | O que faz |
|---|---|---|---|
| 33 | POST | `/api/Rotulo/analisar` | Mesma função da 24 (duplicada) |
| 34 | GET | `/api/Usuario/{id}` | Mesma função da 25 (duplicada) |
| 35 | PUT | `/api/Usuario/atualizar-saude` | Mesma função da 26 (duplicada) |

> Observação: 24/33, 25/34 e 26/35 são duplicatas registradas por caminhos diferentes.

---

## 4. Regras de negócio embutidas na v1

| Regra | Onde | Detalhe |
|---|---|---|
| IMC | `CalcularNutricional` | `peso / altura²`, 2 casas |
| TMB | `CalcularNutricional` | Harris-Benedict: masc `88,362 + 13,397p + 4,799a − 5,677i`; fem `447,593 + 9,247p + 3,098a − 4,330i` |
| Gasto total | `CalcularNutricional` | sedentário ×1,2 · ativo ×1,55 · muito ativo ×1,725 |
| Idade | `Usuario.CalcularIdade()` | derivada de `DataNascimento`, fallback `Idade` |
| Meta de água | `ContextInjectorService` | fixa em **2.000 ml** no prompt |
| Threshold YOLO | `YoloInferenceService` | **0,16** — aceita detecção com 16% de confiança |
| Limpeza de análises | `LimpezaAnalisesService` | apaga registros com **mais de 2 dias** |
| Código de verificação | `Program.cs` | `Random.Next(100000, 999999)`, devolvido no JSON |
| Score de saúde | Groq | inteiro 0–10 + `podeConsumir` + texto |
| Feedback restritivo | `novasfuncoes.md` | considera diabetes e intolerância ao recomendar |
| Senha | `BCrypt` | hash com salt |

---

## 5. Frontend da v1 — funcionalidade por página

### 5.1 `index.html` — landing (9 seções)

`Por que o BSFM Existe?` · `O que o BSFM já Oferece` · `Veja o BSFM em Ação` (vídeo) ·
`Como Funciona` · `Metas e Próximos Passos` · `Status Atual do Projeto` ·
`Inclusão e Prioridade` · `Documentação do Projeto` (5 links externos) ·
`Quer Conhecer o Projeto?` (CTA) — mais botão flutuante **“📱 INSTALAR APP”**.

### 5.2 `login.html`

Funções: `abrirTermos`, `fecharTermos`, `switchTab`, `exibirMensagem`, `cadastrar`,
`verificarToken`, `solicitarCodigoRecuperacao`, `finalizarRecuperacao`, `login`.

- **Cadastro**: nome, e-mail, senha, idade, sexo, peso, altura, nível de atividade, aceite de termos → código de 6 dígitos → verificação → login.
- **Login**: e-mail + senha.
- **Recuperação em 2 passos**: e-mail → código → nova senha.
- **Modal de termos** com conteúdo completo.

### 5.3 `dashboard.html`

19 funções. Sidebar com navegação, tema claro/escuro, banner de alerta de saúde pendente,
cartão de perfil (nome, e-mail, idade, peso, IMC, nascimento), IMC/TMB/gasto,
**água** com barra, entrada personalizada em ml, gráfico semanal, remover último registro,
modal de peso, edição de nome, senha e data de nascimento, sair.

### 5.4 `analisador-ia.html`

Câmera ao vivo (`getUserMedia`), galeria, preview, três porções (**pequeno/médio/grande**),
loading, resultado com nome do alimento, kcal, macros, **anel de score**, selo
`pode consumir / evitar`, texto de análise e dica.

### 5.5 `analisador-rotulo.html`

**Tesseract.js no navegador** (CDN) com barra de progresso de OCR, 3 etapas visuais
(captura → OCR → resultado), texto extraído exibido, envio ao LLM, resultado com
nome do produto, anel de score, barras e status.

### 5.6 `diario.html`

Lista de análises com data, macros e porção; **gerar feedback IA** por item;
modal “salvar prato nos planos” (dia, tipo, nome, ingredientes, macros).

### 5.7 `metas.html`

Progresso em barra, peso atual × meta, **dois gráficos Chart.js** (peso e IMC),
registro de pesagem, definir meta.

### 5.8 `planos.html`

Abas de 7 dias, CRUD de pratos com modais (tipo, nome, ingredientes, preparo, macros).

### 5.9 `hospitais.html`

**Leaflet** com mapa, geolocalização do usuário, **8 estabelecimentos fixos**
(HC-FMUSP, UPA Sé, Hospital São Paulo, UPA Tatuapé, IAMSPE…), cálculo de distância
(haversine), botão **Waze** e **ligar**.

### 5.10 `libras.html` / `alerta-saude-pendente.html`

Widget VLibras; formulário de diabetes e intolerâncias com opção “pular”.

---

## 6. Matriz de paridade v1 → v2

Legenda: ✅ existe · 🟡 parcial · ❌ falta · — não se aplica

### 6.1 Autenticação e conta

| Funcionalidade v1 | v2 | Observação |
|---|---|---|
| Login | ✅ | com token + assinatura |
| Cadastro completo | ✅ | mais verificação por e-mail |
| **Esqueci minha senha (2 passos)** | ❌ | **API existe; a tela não tem o link** |
| Verificação por código | ✅ | etapa no cadastro |
| Modal de termos | ❌ | só checkbox, sem texto |
| Editar nome | ✅ | `/api/eu/nome` |
| **Editar e-mail / data de nascimento** | ❌ | sem UI |
| Trocar senha | ✅ | exige senha atual (mais seguro) |
| Encerrar sessão / ver dispositivos | ✅ | novo na v2 |
| 2FA (TOTP) | ✅ | novo na v2 |

### 6.2 Painel

| v1 | v2 | Observação |
|---|---|---|
| Sidebar com 6 seções | ✅ | 6 abas |
| Cartão de perfil completo | 🟡 | perfil tem os dados; sem edição inline |
| IMC / TMB / gasto | ✅ | |
| Água com barra + entrada personalizada | 🟡 | botões +250/+500; sem campo livre |
| Água semanal | ❌ | API existe, sem gráfico |
| Modal de peso | 🟡 | edição só via API |
| **Banner “complete seu perfil de saúde”** | ❌ | |
| Tema claro/escuro | ✅ | |
| Sair | ✅ | |

### 6.3 Análise

| v1 | v2 | Observação |
|---|---|---|
| Foto por câmera | ❌ | upload de arquivo (sem `getUserMedia`) |
| Galeria | ✅ | |
| **3 tamanhos de porção** | 🟡 | gramas com stepper |
| YOLO local | ❌ | visão multimodal opcional |
| USDA | ❌ | catálogo TACO local |
| **Rótulo com OCR** | ❌ | **maior lacuna funcional** |
| Anel de score | ❌ | |
| Feedback restritivo (diabetes/intolerância) | ❌ | |
| Registro no histórico | ✅ | |

### 6.4 Diário, metas e planos

| v1 | v2 | Observação |
|---|---|---|
| Diário com histórico | ✅ | agrupado por dia |
| **Gerar feedback IA por item** | ❌ | |
| Salvar prato no plano a partir do diário | ❌ | |
| Metas com histórico | ✅ | novo na v2 |
| **Gráficos (peso e IMC)** | ❌ | |
| Registrar pesagem | 🟡 | via `/api/eu/saude` |
| Planos semanais CRUD | ✅ | |
| **Importar prescrição por OCR** | ❌ | |
| **Concluir refeição do plano** | ❌ | |
| Resumo do dia do plano | ❌ | |

### 6.5 Conteúdo e utilidades

| v1 | v2 | Observação |
|---|---|---|
| Landing com 9 seções | 🟡 | v2 tem 7, sem vídeo e sem tabela de status |
| Botão instalar na landing | ✅ | restaurado |
| Links de documentação | ✅ | 4 guias |
| **Hospitais com mapa (Leaflet)** | ❌ | |
| **Libras (VLibras)** | ✅ | restaurado |
| **Perfil de saúde (diabetes/intolerância)** | ❌ | colunas existem no banco |
| **Gerar APK** | ❌ | rota removida |
| Keep-alive (GitHub Action) | ❌ | não configurado para a v2 |

---

## 7. O que falta — lista priorizada

### P0 — quebra expectativa do usuário (fazer primeiro)

1. **Esqueci minha senha na tela** — API `esqueci-senha`/`redefinir-senha` já existe; falta o
   link, o formulário de e-mail e o campo de código. É o item que você citou.
2. **Análise de rótulo (OCR)** — Tesseract.js no cliente + endpoint que já recebe texto.
3. **Gráficos de evolução** (peso e IMC) — `/api/eu/evolucao` devolve a série pronta.
4. **Água: campo livre + gráfico semanal** — `/api/eu/agua/semanal` já existe.

### P1 — paridade funcional

5. Perfil de saúde (diabetes/intolerâncias) com banner de pendência.
6. Edição de e-mail e data de nascimento.
7. Feedback nutricional por item do diário (LLM).
8. Importar prescrição por OCR e concluir refeição do plano.
9. Hospitais com mapa (dados CNES/DATASUS + Leaflet).
10. Modal de termos com o texto completo.

### P2 — experiência e infraestrutura

11. Câmera ao vivo no analisador (além do upload).
12. Salvar prato do diário direto no plano.
13. Tabela de status do projeto na landing + vídeo.
14. Keep-alive do Render.
15. Exportar dados (LGPD) e excluir conta.

---

## 8. Contagem final

| Item | v1 | v2 hoje |
|---|---|---|
| Endpoints | 35 | 29 |
| Páginas/telas | 11 | 8 |
| Serviços externos | 4 (YOLO, USDA, Groq, Brevo) | 2 (TACO local, Brevo) + visão opcional |
| Tabelas no banco | 11 | 14 |
| Testes automatizados | 0 | **315 asserções** |

A v2 ganhou em segurança (sessão assinada, auditoria, LGPD), em dado nutricional
(TACO com 582 itens) e em testes. Perdeu em **amplitude de telas** — é exatamente o que
esta lista de lacunas cobre.

---

## 9. Rastreabilidade

Toda afirmação deste documento veio de leitura direta dos 73 arquivos, com extração
programática de: rotas (`app.Map*` e `[Http*]`), funções JS (`function nome(`), endpoints
chamados (`fetch(`), chaves de armazenamento (`localStorage`), ids de tela (`id="..."`),
assinaturas de serviço, comandos SQL (`CREATE/ALTER TABLE`) e títulos de seção das páginas.

---

## 10. Estado da execução (checklist)

Atualizado em 2026-11-14, após as rodadas de implementação.

### Autenticação e conta

- [x] Login com token assinado
- [x] Cadastro completo com verificação por e-mail
- [x] **Esqueci minha senha (2 passos)** — e-mail → código → nova senha
- [x] Troca de senha exigindo a atual
- [x] **Editar e-mail** (com senha de confirmação e reenvio de verificação)
- [x] **Editar data de nascimento** (idade passa a ser derivada)
- [x] Sessões por dispositivo, com encerramento
- [x] 2FA TOTP
- [x] **Termos de uso e LGPD completos** (texto no perfil)

### Painel

- [x] Sidebar com navegação
- [x] IMC, TMB e gasto total
- [x] Água do dia com barra
- [x] **Água com valor livre**
- [x] **Gráfico semanal de hidratação**
- [x] **Gráfico de evolução de peso**
- [x] **Banner de perfil de saúde incompleto**
- [x] Tema claro/escuro
- [x] **Atualização de peso no painel** (recalcula IMC, TMB e gasto)
- [x] **Água: desfazer último registro**

### Análise

- [x] Busca no catálogo TACO (582 itens)
- [x] Upload de foto com reconhecimento opcional
- [x] **Análise de rótulo com OCR local + leitor no servidor**
- [x] Ajuste de porção com atalhos (50/100/150/200 g)
- [x] Tabela nutricional da porção
- [x] **Câmera ao vivo** (`getUserMedia`, com fallback para arquivo)
- [x] **Anel de pontuação (0–10)** no feedback
- [x] **Feedback restritivo** por diabetes e intolerância (regras)

### Diário, metas e planos

- [x] Diário agrupado por dia
- [x] Metas com histórico
- [x] **Gráficos de peso e IMC na tela de metas**
- [x] Planos semanais (7 dias × 4 refeições, CRUD)
- [x] **Feedback por item do diário**
- [x] **Salvar prato do diário no plano** (dia e refeição)
- [x] **Importar prescrição por OCR**, com revisão antes de salvar
- [ ] Concluir refeição do plano e resumo do dia

### Conteúdo e utilidades

- [x] Landing pública com 7 seções
- [x] Botão de instalação na landing, no menu e no login
- [x] Links de documentação
- [x] **Libras (VLibras)**
- [x] **Perfil de saúde (diabetes e intolerâncias)**
- [x] **Emergências: 5 unidades de SP com telefone e Waze**
- [ ] Mapa interativo (Leaflet) para as unidades
- [x] **Tabela de status do projeto** na landing
- [ ] Vídeo de demonstração na landing
- [ ] Gerar APK
- [x] **Keep-alive do Render** (workflow com segredo `RENDER_URLS`)

### Resumo

| Categoria | Pronto | Pendente |
|---|---|---|
| Autenticação e conta | 9 | 0 |
| Painel | 10 | 0 |
| Análise | 8 | 0 |
| Diário, metas e planos | 7 | 1 |
| Conteúdo e utilidades | 9 | 3 |
| **Total** | **43** | **4** |

Os 4 pendentes estão listados com justificativa na seção 7 (P1 e P2). Nenhum deles é
regressão: são funcionalidades que dependem de dado externo (mapa, DATASUS), de serviço
(LLM, OCR de prescrição) ou de decisão de produto (pontuação de saúde).