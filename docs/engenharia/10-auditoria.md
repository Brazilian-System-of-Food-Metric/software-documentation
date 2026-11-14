# DOC-10 — Auditoria do REMASTER: paridade v1 → v2, design soft clean e avaliação da documentação

**Projeto:** BSFM · PIM 4º semestre
**Data da auditoria:** 2026-11-14
**Escopo:** `BSFMappClone` (v1), `UpgradeBSFM`, `_repos` e `REMASTER` (v2)
**Método:** leitura integral do código da v2 (front e back), comparação com o
inventário da v1 (DOC-09), build real, suítes de verificação e testes de
interface em navegador via CDP.
**Resultado:** 14 lacunas reais encontradas e corrigidas; 42 itens de paridade
cobertos; 310 asserções de backend e 52 verificações de interface passando.

---

## 1. Resumo executivo

A v2 **não estava** no estado que o DOC-09 declarava. O documento dizia
“47 itens prontos, 0 pendentes”, mas havia funcionalidades sem interface, uma
falha de assinatura que derrubava o diário e um feedback nutricional com meta
fixa em 2.000 kcal, ignorando o perfil do usuário.

O que foi feito nesta rodada:

1. **Corrigidos 4 defeitos que quebravam fluxo real** — login de quem tem 2FA,
   diário com `?limite=60`, “desfazer água” e perfil incompleto após o login.
2. **Completada a paridade com a v1** — nome/senha na interface, edição de
   refeição do plano, pontuação e “pode consumir” na análise, feedback com
   contexto do servidor, termos no cadastro, 8 unidades de saúde com distância,
   seções da landing, exportação e exclusão de conta.
3. **Redesenhado o produto no estilo soft clean** — tema claro por padrão,
   tema escuro equivalente, landing de 11 seções, navegação mobile flutuante,
   cartões em camadas, tipografia e espaçamento revistos.
4. **Preservada e reforçada a segurança** — sessão em `sessionStorage`,
   assinatura HMAC agora cobre a query string, refresh rotativo já existente
   passou a ser usado, 2FA ganhou ativação/desativação e limite de tentativas.
5. **Confirmado o React** — o app instalável é React 18.3.1 + Vite 5, e não
   existe instalador nativo no projeto. Ver seção 6.

O DOC-09 recebeu uma nota de auditoria no topo. A avaliação documento por
documento está na seção 8.

---

## 2. Conferência: o que realmente faltava

Legenda de gravidade: **P0** quebra fluxo · **P1** paridade/segurança · **P2** experiência.

| # | Lacuna encontrada | Evidência no código (antes) | Gravidade | Situação |
|---|---|---|---|---|
| 1 | **Login impossível para quem tem 2FA** | `AuthController.Login` exigia `CodigoTotp` se `TotpHabilitado`; `api.login` enviava só e-mail e senha; a tela não tinha campo de código | P0 | Corrigido: campo aparece quando o servidor responde `totp_necessario` |
| 2 | **Diário quebrava com 401** | `SessaoObrigatoriaAttribute` assinava só `Request.Path`; o cliente assinava `/api/eu/analises?limite=60`; a query ficava fora da assinatura | P0 | Corrigido: caminho assinado inclui `QueryString` |
| 3 | **Feedback nutricional sem contexto** | `Diario.jsx` enviava `metaKcal: 2000`, `consumidoKcal: 0`, `diabetes: null` fixos | P1 | Corrigido: `POST /api/eu/analises/avaliar` lê meta, consumo e saúde do banco |
| 4 | **Análise sem pontuação nem “pode consumir”** | `POST /api/eu/analises/do-catalogo` gravava `PodeConsumir = null` e `PontuacaoSaude = 0`; a tela não mostrava anel | P1 | Corrigido: o servidor calcula e grava; a tela mostra anel e selo |
| 5 | **Editar nome e trocar senha sem interface** | Rotas `PUT /api/eu/nome` e `/senha` existiam; `api.js` não tinha métodos e o Perfil não tinha formulários | P1 | Corrigido: formulários no Perfil |
| 6 | **Plano sem edição (CRUD incompleto)** | Só `POST`, `PUT /concluir` e `DELETE`; o DOC-09 chamava de CRUD | P1 | Corrigido: `PUT /api/eu/refeicoes/{id}` + botão de edição |
| 7 | **“Desfazer água” dava erro mesmo funcionando** | `DELETE /agua/ultimo` responde 204; o front lia `r.totalMl` de `null` e caía no `catch` | P2 | Corrigido: recarrega o dia e a semana após remover |
| 8 | **Termos só no Perfil** | Cadastro tinha checkbox sem link nem texto; a v1 abria modal com o contrato | P2 | Corrigido: modal de termos no cadastro e no Perfil |
| 9 | **Landing sem seções da v1 e sem tema** | Faltavam “Por que existe”, roadmap e inclusão; não havia alternância de tema; galeria usava capturas do tema escuro antigo | P2 | Corrigido: 11 seções, tema e capturas novas |
| 10 | **Hospitais menores que a v1** | v2 tinha 5 unidades; a v1 tinha 8; não havia geolocalização nem distância | P2 | Corrigido: 8 unidades, “usar minha localização”, distância e ordenação |
| 11 | **Sem portabilidade/exclusão LGPD** | Termos prometiam exclusão; não havia rota nem tela | P2 | Corrigido: `GET /api/eu/exportar` e `POST /api/eu/conta/excluir` |
| 12 | **2FA sem limite de tentativas** | Falha de TOTP não incrementava `TentativasFalhas`; 6 dígitos podiam ser testados sem bloqueio | P1 | Corrigido: falha de TOTP conta para o bloqueio progressivo |
| 13 | **Perfil incompleto após login** | `aoEntrar` usava o resumo `UsuarioSaida` (sem `criadoEm`, `dataNascimento`, saúde); o Perfil mostrava “desde —” e “e-mail pendente” | P2 | Corrigido: o app busca `/api/eu/perfil` logo após entrar |
| 14 | **Verificação sem reenvio** | Se o usuário fechasse a aba, não havia como pedir outro código | P2 | Corrigido: `POST /api/auth/reenviar-verificacao` e botão |

### 2.1 O que o DOC-09 declarava pronto e não estava

| Item do DOC-09 | O que existia de fato | O que faltava |
|---|---|---|
| “2FA (TOTP) ✅ novo na v2” | Verificação no login | Nenhuma rota/tela para ativar ou desativar; nenhum campo de código no login |
| “Trocar senha ✅ exige senha atual” | Rota no backend | Formulário e método no cliente |
| “Editar nome ✅ `/api/eu/nome`” | Rota no backend | Formulário no Perfil |
| “Feedback restritivo ✅ (regras)” | Motor de regras no backend | O cliente mandava meta/perfil fixos; a análise não pedia feedback |
| “Planos semanais (7 dias × 4 refeições, CRUD)” | Criar, concluir, remover | Editar |
| “Modal de termos” | Texto escondido no Perfil | Modal no cadastro, com link |
| “Anel de pontuação 0–10” | Anel no feedback do diário | Anel na análise e no rótulo; `PodeConsumir` gravado |
| “Todos os 47 itens prontos” | parte dos 47 itens estava completa | 14 lacunas acima, várias delas fora daquela lista de 47 |

---

## 3. Paridade v1 → v2 depois da auditoria

| # | Recurso da v1 | v2 antes | v2 agora |
|---|---|---|---|
| 1 | Login | ✅ | ✅ com 2FA |
| 2 | Cadastro completo | 🟡 sem nascimento/idade | ✅ nascimento, peso, altura, sexo, atividade, termos |
| 3 | Verificação por código | ✅ | ✅ + reenvio |
| 4 | Recuperação em 2 passos | ✅ | ✅ |
| 5 | Modal de termos | ❌ | ✅ |
| 6 | Editar nome | 🟡 só API | ✅ tela |
| 7 | Editar e-mail | ✅ | ✅ |
| 8 | Editar nascimento | ✅ | ✅ |
| 9 | Trocar senha | 🟡 só API | ✅ tela, derruba outras sessões |
| 10 | 2FA | 🟡 só verificação | ✅ ativação, confirmação, desativação e login |
| 11 | Sessões/dispositivos | ✅ lista | ✅ lista + encerrar + encerrar todas |
| 12 | Painel com sidebar | ✅ 6 abas | ✅ 6 abas + grupos |
| 13 | IMC/TMB/gasto | ✅ | ✅ |
| 14 | Água: barra, valor livre, desfazer, semana | 🟡 desfazer com bug | ✅ |
| 15 | Peso no painel | 🟡 via API | ✅ formulário e série |
| 16 | Banner de saúde pendente | ❌ | ✅ |
| 17 | Tema claro/escuro | ✅ | ✅ (claro por padrão) |
| 18 | Evolução de peso/IMC | ✅ | ✅ |
| 19 | Busca no catálogo | ✅ TACO | ✅ |
| 20 | Foto do prato | ✅ upload/câmera | ✅ + estado do provedor explicado |
| 21 | Rótulo com OCR | ✅ | ✅ + pontuação |
| 22 | Porções | 🟡 gramas | ✅ gramas + atalhos |
| 23 | Anel de score | 🟡 só diário | ✅ análise, rótulo e diário |
| 24 | Feedback restritivo | ❌ fixo | ✅ contexto do servidor |
| 25 | Diário agrupado | ✅ | ✅ |
| 26 | Feedback por item | ✅ | ✅ com meta e saúde reais |
| 27 | Salvar prato no plano | ✅ | ✅ |
| 28 | Metas e histórico | ✅ | ✅ |
| 29 | Gráficos peso e IMC | ✅ | ✅ |
| 30 | Planos 7 dias CRUD | 🟡 sem editar | ✅ criar, editar, concluir, remover |
| 31 | Importar prescrição OCR | ✅ | ✅ |
| 32 | Concluir refeição | ✅ | ✅ |
| 33 | Landing 9 seções | 🟡 7 seções | ✅ 11 seções |
| 34 | Instalar app | ✅ PWA | ✅ PWA + tema |
| 35 | Links de documentação | ✅ | ✅ |
| 36 | Libras/VLibras | ✅ | ✅ |
| 37 | Hospitais com mapa | 🟡 5, sem distância | ✅ 8, geolocalização, distância, Waze |
| 38 | Status do projeto | ✅ | ✅ + roadmap |
| 39 | Inclusão e prioridade | ❌ | ✅ |
| 40 | Keep-alive | ✅ workflow | ✅ (mantido) |
| 41 | Gerar APK | ❌ decisão | ❌ decisão registrada: PWA cobre |
| 42 | Exportar/excluir dados | ❌ | ✅ |

---

## 4. Design: de “v2 escura” para soft clean

### 4.1 O que mudou

| Dimensão | Antes | Agora |
|---|---|---|
| Tema padrão | escuro, quase preto (`#0b120f`) | claro quente (`#f3f5f0`), com tema escuro equivalente |
| Superfícies | 4 tons de verde-escuro, contraste alto | camadas claras + sombras suaves; no escuro, carvão esverdeado |
| Raio | 10–20 px | 10–36 px (cartões 19, blocos 27, hero 36) |
| Sombra | uma sombra forte | três níveis (`xs`, `sm`, `sombra`), quase invisíveis |
| Tipografia | 15 px, títulos 17–30 px | escala com `clamp`, títulos 26–62 px na landing |
| Espaçamento | 14–20 px | base 4/8, seções de 58–84 px |
| Acento | verde neon `#4ade80` | verde sage `#2f9e6e`; no escuro `#57c98f` |
| Navegação | sidebar + barra fixa | sidebar + barra mobile flutuante com sombra |
| Landing | 7 seções, sem tema | 11 seções, tema, mock do app e chips flutuantes |
| Estados vazios | texto simples | ícone, título, explicação e ação |
| Foco | contorno de 2 px | anel de 3 px com `color-mix` |

### 4.2 Estrutura da landing (11 seções)

1. Hero com mock do app e chips (“IMC 22,4”, “1.850 ml”, “582 alimentos”).
2. **Por que o BSFM existe** — visão, missão e valores (texto da v1).
3. **Um app de nutrição de verdade** — 6 recursos com ícones.
4. **Veja o BSFM em ação** — 4 capturas reais do app novo.
5. **Como funciona** — 4 passos.
6. **Metas e próximos passos** — implementado × roadmap (texto da v1).
7. **Status do projeto** — tabela honesta com estados.
8. **Inclusão e prioridade** — VLibras e acessibilidade.
9. **Aplicativo** — PWA, offline e instalação.
10. **Números** — 582 alimentos, 300+ verificações, 14 tabelas, open source.
11. **Documentação e CTA final**.

### 4.3 Capturas de evidência

- `web/redesign-landing-desktop.png`
- `web/redesign-login-desktop.png`
- `web/redesign-painel-desktop.png`
- `web/redesign-painel-escuro.png`
- `web/redesign-painel-mobile.png`
- `web/redesign-perfil-2fa.png`
- `web/public/demo/{painel,rotulo,metas,perfil}.png` — regeneradas a partir do app novo

### 4.4 Acessibilidade e responsividade

- Foco visível em todos os controles, `aria-label` nos botões de ícone,
  `role="tablist"` nos segmentos, `aria-current` na navegação.
- `prefers-reduced-motion` desliga animações.
- Barra inferior flutuante no mobile; sidebar a partir de 960 px.
- Formulários com `label` associado por `htmlFor`.
- Modal de termos fecha com `Esc`, clique no fundo e botão; trava o scroll.

---

## 5. Segurança: preservada e reforçada

| Controle | Estado |
|---|---|
| Token e chave de assinatura | continuam em `sessionStorage`, nunca `localStorage` |
| Assinatura por requisição | HMAC-SHA256 por sessão (chave derivada do `jti`) |
| Cobertura da assinatura | **corrigida** para incluir método + caminho + query + timestamp + nonce + hash do corpo |
| Expiração do token | 2 h; refresh de 30 dias com rotação e detecção de reuso |
| Uso do refresh no cliente | **novo**: renova uma vez em 401 e repete a requisição |
| Senha | PBKDF2-SHA256 210.000 iterações, com migração de BCrypt legado |
| Bloqueio progressivo | 5 falhas → 15 min; agora **também** em falha de TOTP |
| 2FA | ativação exige senha + código; desativação exige senha + código |
| Consentimento LGPD | registro versionado no cadastro e nas alterações de saúde |
| Auditoria | login, código, saúde, exportação, exclusão, refeição, análise |
| Dados de saúde no feedback | deixaram de ir no corpo do cliente; o servidor lê do banco |
| Pontuação nutricional | calculada e gravada pelo servidor; o cliente não informa a própria nota |
| Exclusão de conta | transação remove análises, água, refeições, metas, histórico, sessões, consentimentos |
| Service worker | nunca cacheia `/api/*`; shell versionado (`bsfm-v3`) |

### 5.1 Limitações de segurança que permanecem (declaradas)

1. **Código de e-mail e TOTP compartilham o mesmo segredo.** Quem tem acesso ao
   e-mail e usa o código em até 30 s pode usá-lo como segundo fator. Separar os
   segredos exige uma coluna nova e migração — não foi feito nesta rodada.
2. **Sem CSP e sem SRI** nos scripts de terceiros (Tesseract.js, Leaflet,
   VLibras). São dependências já existentes; endurecer isso é uma tarefa própria.
3. **Mapa com 8 unidades fixas**, não importadas do DATASUS/CNES. A entidade
   `Hospital` já aceita CNES e coordenadas; falta o pipeline de dados.
4. **Sem rate limit por IP** nas rotas públicas (`/api/nutricao/*`); há limite
   por conta no login, mas não no catálogo.
5. **Sem CI executando os testes de interface**; eles rodam localmente via CDP.
6. **O “hoje” do servidor é UTC.** O diário agora agrupa pelo fuso local do
   navegador, mas `/resumo`, `/agua` e as metas ainda cortam o dia em UTC. Perto
   da meia-noite no horário de Brasília isso pode contar o dia seguinte. Corrigir
   exige uma abstração de fuso (`America/Sao_Paulo`) em todas as consultas de
   data — mudança de maior risco, deliberadamente deixada fora desta rodada.

---

## 6. React e o “instalador”: a confirmação

### 6.1 Sim, o app é React

| Item | Valor observado |
|---|---|
| `react` | `^18.3.1` (instalado 18.3.1) |
| `react-dom` | `^18.3.1` |
| `vite` | `^5.4.11` (build 5.4.21) |
| `@vitejs/plugin-react` | `^4.3.4` |
| Entrada | `src/main.jsx` com `createRoot(...).render(<React.StrictMode><App /></React.StrictMode>)` |
| Build | `dist/index.html` + `dist/assets/index-*.js` (279,58 kB / 83,49 kB gzip) |
| Estilo | `dist/assets/index-*.css` (55,13 kB / 10,63 kB gzip) |

### 6.2 Não existe instalador nativo

Não há `.exe`, `.msi`, `.apk` nem projeto Inno Setup/electron-builder no
repositório. A rota `GET /api/gerar-apk` da v1 foi removida por decisão
registrada no DOC-09: o PWA cobre a instalação sem loja.

O que existe é **instalação PWA**:

1. `manifest.webmanifest` (nome, ícones 192/512/maskable, `display: standalone`);
2. `sw.js` (shell offline, `/api/*` fora do cache);
3. `beforeinstallprompt` capturado no `App.jsx`;
4. botão “Instalar” na landing, no login, no painel e no Perfil.

**Portanto:** se por “instalador” você entende o botão “Instalar aplicativo” ou o
app que fica na tela inicial, ele instala exatamente o build React. O navegador
é o instalador; o artefato instalado é a SPA React.

### 6.3 O que foi mantido na configuração React

- `vite.config.js` **não foi alterado** (portas 5173/4173, proxy `/api`).
- Nenhuma dependência nova; nenhuma versão trocada.
- `StrictMode` mantido.
- `main.jsx` continua registrando o service worker apenas em produção.
- O build continua sendo `vite build`; o pacote não ganhou plugin nem loader.

Conclusão: **as mudanças não atrapalham o instalador**. O caminho de build e o
caminho de instalação PWA são os mesmos; só o conteúdo visual e as rotas de API
mudaram. O `sw.js` foi versionado (`bsfm-v1` → `bsfm-v3`) para não servir o
shell antigo em cache.

### 6.4 Se “instalador” for o guia de instalação

O arquivo `_repos/software-documentation/docs/bsfm/instalacao.md` estava
desatualizado: dizia “Frontend: HTML/CSS/JS”, listava `USDA_API_KEY` e
`GROQ_API_KEY` (da v1) e healthcheck em `/health`. Foi corrigido com uma seção
v2 (React + Vite), variáveis reais e `/saude`.

---

## 7. Verificação executada

### 7.1 Build

| Comando | Resultado |
|---|---|
| `dotnet build BSFM.Api.csproj` | sucesso, **0 erros / 0 avisos** |
| `npm run build` (web) | sucesso, 50 módulos, `dist/` gerado |
| `node verificar-redesign.mjs` | **26 PASS / 0 FAIL** |
| `node verificar-2fa-e-planos.mjs` | **10 PASS / 0 FAIL** |
| `node verificar-ativacao-2fa.mjs` | **8 PASS / 0 FAIL** |
| `node verificar-exclusao.mjs` | **8 PASS / 0 FAIL** |

### 7.2 Suítes de backend (todas executadas nesta rodada)

| Suíte | Asserções | Resultado |
|---|---|---|
| `BSFM.Seguranca.Verificacao` | 47 | 47 PASS |
| `BSFM.Dados.Verificacao` | 53 | 53 PASS |
| `BSFM.Nutricao.Verificacao` | 95 | 95 PASS |
| `smoke-s2.ps1` (auth/conta) | 32 | 32 PASS |
| `smoke-s3.ps1` (água/refeições/metas/análises) | 38 | 38 PASS |
| `smoke-s4.ps1` (catálogo/visão) | 31 | 31 PASS |
| `smoke-s5.ps1` (cadastro/verificação) | 14 | 14 PASS |
| **Total** | **310** | **310 PASS** |

Isso confirma o número da seção 10 do DOC-09 (**310**) e desmente o “315” da
seção 8.

### 7.3 O que os testes de interface cobrem

- Landing: renderização, seções da v1, inclusão, roadmap, CTA de instalação.
- Login: formulário, recuperação, tema.
- Painel: saudação, macros, hidratação, navegação.
- Abas: Analisar, Diário, Planos, Metas, Perfil.
- Diário: requisição assinada com query (`?limite=60`) sem 401.
- Perfil: segurança, privacidade, emergências, aplicativo.
- Mobile: barra flutuante.
- Tema escuro.
- Console: nenhuma exceção de runtime.
- 2FA: obrigatório no login e ativação pela tela.
- Planos: criar, editar e remover.
- Exclusão: conta descartável some do banco e a sessão volta para a landing.

Os scripts históricos (`verificar-paridade`, `verificar-perfil`, `verificar-p0`,
`p2`, `p3`, `p4`, `p5`, `p6`, `captura`, `layout`, `metas`, `regressao` e
`tela`) foram ajustados para a nova interface e também passam. Eles continuam
válidos como regressão, mas os quatro scripts novos são a fonte de verdade do
redesenho.

---

## 8. Avaliação da documentação

### 8.1 Veredito por documento

| Documento | O que acerta | Problema | Ação |
|---|---|---|---|
| **DOC-01** engenharia reversa | método, evidências, referência de design system e acessibilidade | é engenharia reversa do **Google AI Studio**, não um requisito do BSFM; propõe tokens `--bsfm-*` que não são os implementados; a “2ª passada” nunca foi feita | usar como referência de método, não como especificação |
| **DOC-02** análise da v1 | inventário técnico correto da v1 em 13/11 | não cobre a v2; números de teste são um retrato daquele dia | histórico |
| **DOC-03** schema e S2 | schema, migrations, 53 asserções | “31 asserções HTTP” envelheceu (S2 atual tem 32); não diz que é um retrato datado | histórico |
| **DOC-04** S3 | justifica as 29 rotas migradas | as 29 rotas não são o total atual (51 métodos na API); “165 asserções” é histórico | histórico |
| **DOC-05** camada nutricional | decisão YOLO → catálogo continua válida | “254 asserções” é um retrato de 13/11 | histórico |
| **DOC-06** TACO | 582 alimentos, fonte e pipeline | “266 asserções” é histórico | histórico |
| **DOC-07** | — | **não existe**; a numeração salta de 06 para 08 | criar um DOC-07 (arquitetura da v2) ou renumerar |
| **DOC-08** paridade | diagnóstico inicial (landing/login ausentes) | **desatualizado**: diz OCR, hospitais e alerta de saúde “pendentes”, mas o DOC-09 os dá como prontos; não menciona 2FA, perfil, planos | marcar como histórico e apontar para DOC-10 |
| **DOC-09** inventário | a melhor base: 35 rotas da v1, regras, páginas, matriz | a seção 10 **superestima** o estado; 315 × 310; “2FA pronto”, “CRUD”, “feedback restritivo” e “editar nome” não tinham interface; “0 pendências” com P2 em aberto | nota de auditoria no topo + DOC-10 |
| **DOC-10** (este) | conferência, correções, verificação e avaliação | é um retrato de 14/11 | manter atualizado a cada rodada |
| `instalacao.md` (`_repos`) | pré-requisitos e deploy da v1 | frontend descrito como HTML/CSS/JS; USDA/GROQ; `/health` | corrigido com seção v2 |

### 8.2 O padrão que causou o problema

O DOC-09 foi escrito como **relatório de intenção**, não como **evidência de
estado**. Vários itens foram marcados como prontos porque a rota existia no
backend, mesmo sem tela, ou porque o build passava — e, como o próprio DOC-09
diz na seção 11, “build verde não prova nada em JSX”.

Recomendação para os próximos documentos:

1. Todo item de paridade deve citar **rota + componente + teste** (ou“sem teste”).
2. Números de teste precisam de **data e comando**, não de um total solto.
3. Documento histórico não deve ser editado para parecer atual: deve ganhar
   uma nota “substituído por”.
4. Uma tabela de status só pode dizer “pronto” se houver verificação executável.

### 8.3 Documentos que faltam

- **DOC-07 / DOC-11 — arquitetura da v2**: camadas, fluxo de sessão, assinatura,
  2FA, schema, deploy, variáveis. Hoje isso está espalhado em DOC-03/04/09.
- **DOC-12 — modelo de ameaças**: STRIDE ou equivalente para sessão, TOTP,
  upload de imagem, OCR, mapa, LGPD.
- **Índice de testes**: um único lugar com os 310 + 52 e o comando de cada um.
- **Runbook de deploy**: não há `Dockerfile` no `REMASTER`; o deploy depende de
  configuração externa. O DOC-09 menciona Docker, mas o arquivo não está lá.

---

## 9. Pendências reais (declaradas)

| Item | Situação | Por quê |
|---|---|---|
| APK nativo | não será gerado | decisão de produto: PWA cobre instalação sem loja e sem SDK de 1,5 GB |
| Vídeo de demonstração | galeria no lugar | `VIDEO_DEMO` vazio; basta colar uma URL |
| Notificações push | pendente | exige VAPID + service worker de push |
| Receitas, wearables e PDF | roadmap | estavam em “próximos passos” na v1 e continuam lá |
| YOLO local | não portado | visão multimodal opcional no servidor; sem chave, a UI explica e usa o catálogo |
| USDA | substituído | TACO local (582 itens) é mais adequado ao público brasileiro |
| Mapa DATASUS | 8 unidades fixas | entidade pronta; falta pipeline CNES |
| CSP/SRI | pendente | terceiros já existentes (Tesseract, Leaflet, VLibras) |
| Rate limit nas rotas públicas | pendente | proteção por conta existe; falta por IP |
| CI dos testes de UI | pendente | scripts prontos, execução manual via Chrome/CDP |
| Dockerfile da v2 | ausente | deploy atual não é reproduzível só pelo repositório |
| Separação dos segredos de e-mail e TOTP | pendente | exige coluna/migração |

---

## 10. Arquivos alterados nesta auditoria

### Front-end (`REMASTER/web`)

| Arquivo | Mudança |
|---|---|
| `src/styles.css` | design system soft clean reescrito (claro/escuro) |
| `src/App.jsx` | casco, tema claro padrão, refresh de perfil, instalação PWA |
| `src/Landing.jsx` | 11 seções, hero com mock, tema, capturas novas |
| `src/Acesso.jsx` | **novo** — login, cadastro, verificação, 2FA, termos |
| `src/Painel.jsx` | **novo** — macros, água, corpo, evolução |
| `src/Analisar.jsx` | **novo** — busca, foto, rótulo e pontuação |
| `src/Diario.jsx` | **novo** — filtros, detalhes, avaliação, plano, remoção |
| `src/Perfil.jsx` | **novo** — conta, segurança, 2FA, sessões, saúde, LGPD, mapa |
| `src/Metas.jsx` | **novo** — metas, histórico e dois gráficos |
| `src/Planos.jsx` | **novo** — 7 dias, CRUD completo, prescrição |
| `src/Termos.jsx` | **novo** — texto e modal |
| `src/ui.jsx` | **novo** — formatadores, donut, anel, vazio, barra |
| `src/Icones.jsx` | **novo** — ícones SVG sem dependência |
| `src/api.js` | refresh, 2FA, avaliação, exportação, exclusão, plano |
| `src/Mapa.jsx` | marcadores, posição do usuário, `fitBounds` seguro |
| `src/Rotulo.jsx` | OCR via `ocr.js`, fibra e pontuação |
| `src/Prescricao.jsx` | revisão e importação por dia |
| `src/Recuperar.jsx` | novo layout e indicador de etapas |
| `index.html` | tema inicial sem flash, `theme-color`, meta iOS |
| `public/manifest.webmanifest` | cores do tema claro |
| `public/sw.js` | versão `bsfm-v3` |
| `public/demo/*.png` | capturas regeneradas |
| `verificar-redesign.mjs` | **novo** — 26 verificações |
| `verificar-2fa-e-planos.mjs` | **novo** — 10 verificações |
| `verificar-ativacao-2fa.mjs` | **novo** — 8 verificações |
| `verificar-exclusao.mjs` | **novo** — 8 verificações |
| `capturar-demos.mjs` | **novo** — gera as capturas da landing |
| `verificar-paridade.mjs`, `verificar-perfil.mjs`, `verificar-p0/p2/p4/p5/p6.mjs`, `verificar-tela.mjs` | seletores atualizados para o novo layout |

### Back-end (`REMASTER/backend`)

| Arquivo | Mudança |
|---|---|
| `BSFM.Api/Filtros/SessaoObrigatoriaAttribute.cs` | assinatura inclui query string |
| `BSFM.Api/Controllers/AuthController.cs` | TOTP obrigatório/ inválido, bloqueio, reenvio de verificação |
| `BSFM.Api/Controllers/AnalisesController.cs` | contexto de feedback, avaliação sem gravar, pontuação persistida |
| `BSFM.Api/Controllers/PerfilController.cs` | 2FA, exportação, exclusão de conta |
| `BSFM.Api/Controllers/RefeicoesController.cs` | `PUT /api/eu/refeicoes/{id}` |
| `BSFM.Api/DTOs/Dtos.cs` | avaliação, 2FA, exclusão |
| `BSFM.Api/DTOs/DtosS3.cs` | fibra na entrada de análise |
| `BSFM.Api/Program.cs` | remoção de código morto |

### Documentação

| Arquivo | Mudança |
|---|---|
| `REMASTER/DOC-09-inventario-v1.md` | nota de auditoria no topo |
| `REMASTER/DOC-10-auditoria-e-avaliacao.md` | **novo** (este documento) |
| `REMASTER/README.md` | **novo** — stack, execução, testes e confirmação do PWA |
| `_repos/software-documentation/docs/bsfm/instalacao.md` | seção v2, variáveis e `/saude` |

---

## 11. Como reproduzir

```powershell
# API (SQLite de desenvolvimento, porta 5100)
dotnet run --project C:\Users\Isaque\Documents\pim-4-semestre\REMASTER\backend\BSFM.Api

# Front (build de produção, porta 4173)
cd C:\Users\Isaque\Documents\pim-4-semestre\REMASTER\web
npm install
npm run build
npm run preview

# Chrome com CDP para os testes de interface
& "C:\Program Files\Google\Chrome\Application\chrome.exe" `
  --headless=new --remote-debugging-port=9222 `
  --user-data-dir="$env:TEMP\bsfm-chrome" http://localhost:4173/

# Verificações
node verificar-redesign.mjs
$env:NODE_NO_WARNINGS='1'; node verificar-2fa-e-planos.mjs
$env:NODE_NO_WARNINGS='1'; node verificar-ativacao-2fa.mjs
$env:NODE_NO_WARNINGS='1'; node verificar-exclusao.mjs
```

> Os testes que leem o SQLite usam `node:sqlite` (Node 22+). O aviso
> “ExperimentalWarning” é esperado e não indica falha; use
> `NODE_NO_WARNINGS=1` para silenciá-lo.

---

## 12. Rastreabilidade

| Afirmação | Base |
|---|---|
| “O app é React 18.3.1” | `package.json`, `node_modules/react/package.json`, `main.jsx`, build |
| “Não há instalador nativo” | busca por `.exe/.msi/.apk`, `package.json`, ausência de `gerar-apk` no backend |
| “A assinatura ignorava a query” | código anterior de `SessaoObrigatoriaAttribute` + teste do diário |
| “O feedback usava 2.000 kcal fixas” | código anterior de `Diario.jsx` |
| “A v2 tinha 5 hospitais” | código anterior de `Perfil.jsx`/`HOSPITAIS` |
| “310 asserções passam” | execução das 7 suítes nesta rodada |
| “26 + 10 + 8 + 8 verificações de UI passam” | `verificar-*.mjs` executados com Chrome/CDP |
| “Design mudou” | `styles.css` reescrito + capturas `redesign-*.png` |
| “DOC-09 superestimou” | comparação item a item entre DOC-09 §10 e o código anterior |

**Limite desta auditoria:** não houve teste em dispositivo físico iOS/Android
nem em produção (Render/Neon). O comportamento PWA foi verificado no Chrome
desktop e no viewport mobile emulado. Acessibilidade foi revisada por inspeção
de código e contraste, não por leitor de tela real.
