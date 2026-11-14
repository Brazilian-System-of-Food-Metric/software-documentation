# DOC-01 — Engenharia reversa do site modelo (Google AI Studio · Docs) e mapa de gaps do BSFM

**Projeto:** BSFM — Brazilian System of Food Metric · PIM 4º semestre
**Documento:** 01 de 03 (engenharia reversa)
**Data:** 2026-11-13
**Autor:** análise assistida por REA 6.7.0 (MCP) sobre Chrome 157.0.8103.78
**Status:** varredura 1 concluída — pendente de validação do cliente e da 2ª passada após o redesenho

---

## 1. Escopo, método e evidência

### 1.1 O que foi observado

| Item | Valor |
|---|---|
| Site modelo | `https://aistudio.google.com/docs/get-started` |
| Navegador observado | Chrome 157.0.8103.78 (CDP em `127.0.0.1:9222`) |
| Protocolo | DevTools Protocol 1.3 |
| Viewport da captura | 1034 × 605 px |
| Nós de DOM observados | 23.194 |
| Alvo do projeto | `http://127.0.0.1:8080/index.html` (protótipo `SITE BSFM` servido localmente) |

### 1.2 Ferramentas e Evidence IDs

| Operação REA | Evidence | O que forneceu |
|---|---|---|
| `list_browser_targets` | `ev_16b4005c…` | inventário das abas e do navegador |
| `capture_web_screenshot` (modelo) | `ev_64270734…` | PNG 1034×605, 86.905 bytes, SHA-256 `9ae99285…` |
| `capture_web_screenshot` (BSFM) | `ev_6b4dc731…` | PNG 1034×605, 24.726 bytes |
| `inspect_web_page` (modelo) | `ev_48f0d018…` | DOM completo, links, storage, metadata |
| `analyze_web_bundle` (modelo) | `ev_d75e220b…` | scripts analisados, rotas, endpoints |

### 1.3 Limitações declaradas

- A observação começa **quando o REA anexa**. Rede e console anteriores ao attach não existem no Evidence — não há como afirmar quais chamadas a página fez antes.
- `inspect_web_page` captura **apenas a viewport**. Conteúdo abaixo da dobra não foi observado nesta passada.
- **Não há extração de CSS computado**: o DOM veio com nomes de atributos e comprimentos de texto, não com o texto das folhas de estilo. Cores e tipografia vêm de **amostragem de pixels do PNG**, não de declarações CSS. Isso significa que valores de design são observados, mas os *tokens originais* (nomes de variáveis) permanecem **desconhecidos**.
- 50 URLs do DOM ficaram fora da política de origem (`outside_policy`); 14 scripts de origem não permitida e 88 sem atribuição de origem. O JS do modelo **não** foi integralmente auditado.
- Identidade de artefato indisponível para as observações de navegador (`authority: external-service`).

---

## 2. Inventário técnico do site modelo

### 2.1 Stack — observado

| Fato | Evidência |
|---|---|
| É uma aplicação **Angular** | `<app-root ng-version="…">`, `<router-outlet>`, atributos `_nghost-ng-c…` / `_ngcontent-ng-c…` |
| Componentes próprios com prefixo `ms-` | `<ms-app>`, `<ms-global-banner>` |
| Renderização híbrida (SSR/hidratação) | 20+ `<style>` inline no `<head>` + 16.620 caracteres de estilo embutido no nó de estilo principal — o HTML já vem com o layout pronto antes do JS assumir |
| PWA instalável | `<link rel="manifest">` → `/_/MakerSuite/manifest.json` |
| Fonte de dados versionada por API | `<link rel="alternate">` → `/docs/get-started.md` e `/llms.txt` |
| Moldura isolada de terceiros | `<iframe src="https://aistudio.google.com/app/_/bscframe">` |

### 2.2 O achado mais importante para o seu projeto

O site publica **cada página em Markdown**, além do HTML:

```
https://aistudio.google.com/docs/get-started      →  HTML
https://aistudio.google.com/docs/get-started.md   →  Markdown
https://aistudio.google.com/llms.txt              →  índice para agentes
```

Isso é uma decisão de arquitetura, não um detalhe: o conteúdo existe **uma vez** e é servido em dois formatos. É exatamente a estratégia que o BSFM deveria copiar — um conteúdo, N formatos (web, mobile, PDF do PIM, agente/IA).

### 2.3 Estado no navegador — observado

| Storage | Chave |
|---|---|
| `localStorage` | `aiStudioUserPreference`, `xap-tour`, `xap-tour-expire`, `_gcl_ls` |
| `sessionStorage` | `maker_suite_browser_window_id` |
| Uso total | 0 bytes no momento da captura (perfil recém-criado) |
| Cookies | **desconhecido** — valores redigidos por política, não observados |

`xap-tour` / `xap-tour-expire` indicam um sistema de **tour de onboarding com expiração** — um padrão que vale replicar no BSFM (primeiro acesso do usuário).

---

## 3. Arquitetura de informação

### 3.1 Estrutura de navegação — observada nos links

```
[Topo]  Google AI Studio          [Docs | API reference]          [Receber chave de API]
   │
   ├── [Banner] "Esta é a nova página inicial da documentação…"        [Dispensar]
   │
   ├── [Sidebar]  [Filtro /]
   │      GET STARTED
   │         Overview · Get started · API keys · Pricing · Coding agent setup · API CLI
   │      MODELS
   │         Latest Gemini models › · All models
   │      (grupos seguintes, mesma página:)
   │         Image generation · Omni · Transcribe · Live API (11 subpáginas)
   │         Embeddings · Decisions API · Text generation · Document processing
   │         Structured output · Function calling · Long context · Long decode
   │         Agents (7 subpáginas) · Tools (10 subpáginas)
   │         Optimization · Batch API · Webhooks · Flex/Priority inference · Caching
   │         Streaming · Background execution · OpenAI compat · Tokens · Prompting
   │         Changelog · Deprecations · Libraries · Rate limits · Billing
   │         Verification · Troubleshooting · API errors · Status
   │
   └── [Conteúdo]  Documentation / Get started   ← breadcrumb
                   H1 "Getting started"
                   [Copiar página]  [Interactions API ›]
                   …seções com âncoras (#get-api-key, #2-install-the-sdk…)
                   [anterior] [próximo]
```

**Contagem observada:** mais de 120 links internos de documentação, em 3 níveis (aba → grupo → página), com âncoras de 4º nível dentro da página.

### 3.2 Padrões de IA que o BSFM deve adotar

| Padrão | Por que importa para o BSFM |
|---|---|
| Aba primária persistente (`Docs` / `API reference`) | Separa "como usar o produto" de "como integrar". No BSFM: `Painel` / `Analisar` / `Meu plano` |
| Sidebar com grupos colapsáveis + filtro | Escala quando o app cresce de 1 para 12 telas |
| Breadcrumb no conteúdo | Orientação sem depender do menu |
| Sumário por âncoras na própria página | Documentação do PIM navegável |
| Navegação anterior/próximo | Percurso guiado — essencial no onboarding nutricional |
| Banner dispensável no topo | Aviso de novidade sem quebrar o layout |

---

## 4. Design system observado

### 4.1 Cores — **amostradas do PNG renderizado**

| Papel | Hex observado | Onde foi medido |
|---|---|---|
| Fundo base | `#191919` | banner, header, sidebar, área de conteúdo (57.803 px dominantes) |
| Superfície elevada 1 | `#1F1F1F` | bloco de código |
| Superfície elevada 2 | `#282828` | bordas/divisores e chips |
| Superfície de destaque (callout) | `#1C2B42` | card "Building with an AI coding agent?" (5.810 px) |
| Texto primário | `#D4D4D4` – `#E3E3E3` | título H1 e corpo |
| Azul de acento (anti-aliased) | `#5898C8` / `#185898` | borda do callout e links |
| Âmbar de aviso | `#D0B078` | ícone/label de aviso |

> **Inferência declarada:** em uma paleta Google Material, `#5898C8` amostrado em borda é o resultado de um azul mais claro (faixa `#A8C7FA` / `#8AB4F8`) sobre `#191919` com anti-aliasing. Trate o hex exato do acento como **a confirmar** na 2ª passada.

### 4.2 Tipografia — parcialmente observada

| Elemento | Observação |
|---|---|
| H1 "Getting started" | ~40 px, peso 400, altura de linha ~1.2, cor clara |
| Corpo | ~16 px, peso 400, altura de linha ~1.6, medida de linha ~68 caracteres |
| Rótulos de grupo da sidebar | ~11–12 px, caixa alta, espaçamento entre letras aumentado, cor apagada |
| Código | monoespaçada, ~13–14 px |
| Família | **Inferência:** Google Sans / Roboto. Não há como confirmar sem CSS computado. |

### 4.3 Forma, espaçamento e elevação

| Token | Valor observado/inferido |
|---|---|
| Base de espaçamento | 8 px (todos os offsets medidos são múltiplos de 8) |
| Raio de botão/aba | pill (raio total) — "Docs" ativo é uma cápsula |
| Raio de item de sidebar ativo | pill (8–10 px) |
| Raio de card/callout | 12 px |
| Raio de bloco de código | 12 px com cabeçalho próprio |
| Elevação | praticamente **sem sombra** — separação por cor de superfície e borda de 1 px |
| Largura da sidebar | ~200 px fixos |

### 4.4 Componentes inventariados

1. **Barra superior** — marca à esquerda, seletor de modo no centro (pill), CTA primário à direita.
2. **Banner de aviso dispensável** — ícone + texto + botão "Dispensar".
3. **Sidebar** — campo de filtro com atalho `/`, grupos com rótulo em caixa alta, item ativo em pill, indicador `›` para submenu.
4. **Breadcrumb** — `Documentation / Get started`, com o último item em destaque.
5. **Cabeçalho de conteúdo** — H1 + linha de ações (`Copiar página`, link "Interactions API ›").
6. **Callout informativo** — fundo azulado `#1C2B42`, ícone à esquerda, texto com link inline.
7. **Bloco de código** — cabeçalho com rótulo de linguagem (`Code`), botão de copiar, corpo escuro.
8. **Rodapé** — links legais + `llms.txt` + `.md` + política de documentação.

---

## 5. Segurança e privacidade observadas

| Observação | Leitura |
|---|---|
| Todos os `<script>`/`<link>` carregam `nonce` | **CSP com nonce** ativa; scripts inline só executam com a marca do servidor |
| `crossorigin` em fontes e manifesto | isolamento de origem explícito |
| Nenhum token em URL ou storage | o perfil observado não tinha sessão; **não** é prova de que não exista quando logado |
| Iframe de origem própria (`/app/_/bscframe`) | isolamento de conteúdo de terceiros em moldura separada |
| 88 scripts sem origem atribuída | superfície de terceiros alta — no BSFM isso deve ser **zero** |

**Não observado:** cabeçalhos de resposta (CSP completa, HSTS, X-Frame-Options), cookies, mecanismo de sessão, endpoints de autenticação. O `analyze_web_bundle` só viu 2 scripts (1.140 e 1.445 bytes) porque a página já estava carregada no momento do attach — o bundle real não foi capturado. **Isso precisa de uma 2ª passada com recarga controlada.**

---

## 6. O que o BSFM tem hoje

### 6.1 Inventário real

| Arquivo | Conteúdo |
|---|---|
| `SITE BSFM/index.html` | 236 linhas — abas Cadastro/Login, CSS embutido, `fetch` para `localhost:5000` |
| `SITE BSFM/Program.cs` | 83 linhas — Minimal API, 2 endpoints, CORS aberto |
| `SITE BSFM/ClassesBSFM.cs` | 121 linhas — 5 entidades + cálculos nutricionais |
| `SITE BSFM/PonteDB.cs` | 29 linhas — `DbContext` SQLite |
| `SITE BSFM/Engrenagem.cs` | apoio |

### 6.2 Gaps frente ao modelo

| # | Dimensão | Modelo (aistudio) | BSFM hoje | Prioridade |
|---|---|---|---|---|
| 1 | Navegação | 3 níveis, 120+ páginas, sidebar filtrável | 2 abas na mesma tela | **P0** |
| 2 | Design system | tokens, dark mode, componentes consistentes | CSS solto em um `<style>`, verde `#2ecc71` sobre branco | **P0** |
| 3 | Conteúdo em múltiplos formatos | HTML + `.md` + `llms.txt` | só HTML | **P0** |
| 4 | Autenticação | sessão + CSP com nonce | sem token, senha em texto claro no payload | **P0** |
| 5 | Erros e estados vazios | inline, contextual | `alert()` e `div` colorida | **P1** |
| 6 | Onboarding | tour com expiração (`xap-tour`) | inexistente | **P1** |
| 7 | Acessibilidade | landmarks, `aria-*`, foco visível | sem `label for`, sem `aria`, foco fraco | **P1** |
| 8 | Responsivo | sidebar recolhível | `max-width: 450px` fixo | **P1** |
| 9 | IA de alimentos | — | YOLO de aprendizado, 452 classes, threshold 0.16 | **P1** |
| 10 | Dados de saúde | — | IMC devolvido no login, sem LGPD | **P1** |
| 11 | Hospitais de SP | — | entidade com 3 campos, sem dados | **P2** |
| 12 | Observabilidade | — | nenhum log, nenhuma métrica | **P2** |

---

## 7. Design system proposto para o BSFM

Traduzido do modelo para a identidade nutricional — **não** é cópia: mantém a disciplina de tokens, muda a paleta.

```css
:root {
  /* Superfícies — base escura do modelo, adaptada */
  --bsfm-bg:            #0F1512;
  --bsfm-surface-1:     #161D19;
  --bsfm-surface-2:     #1E2723;
  --bsfm-surface-3:     #27332D;
  --bsfm-border:        #2E3B35;

  /* Acento nutricional (verde) — substitui o azul do modelo */
  --bsfm-accent:        #4ADE80;
  --bsfm-accent-strong: #22C55E;
  --bsfm-accent-soft:   #123021;

  /* Semânticas */
  --bsfm-warn:          #FBBF24;
  --bsfm-danger:        #F87171;
  --bsfm-info:          #60A5FA;

  /* Texto */
  --bsfm-text:          #E7EFEA;
  --bsfm-text-muted:    #9DB0A6;
  --bsfm-text-inverse:  #0B0F0D;

  /* Forma */
  --bsfm-radius-sm: 8px;
  --bsfm-radius-md: 12px;
  --bsfm-radius-lg: 20px;
  --bsfm-radius-pill: 999px;

  /* Espaçamento — base 8 */
  --bsfm-1: 4px;  --bsfm-2: 8px;  --bsfm-3: 12px; --bsfm-4: 16px;
  --bsfm-6: 24px; --bsfm-8: 32px; --bsfm-12: 48px; --bsfm-16: 64px;

  /* Tipografia */
  --bsfm-font: "Inter", system-ui, sans-serif;
  --bsfm-mono: "JetBrains Mono", ui-monospace, monospace;
  --bsfm-fs-display: 40px; --bsfm-fs-h1: 32px; --bsfm-fs-h2: 24px;
  --bsfm-fs-body: 16px;    --bsfm-fs-sm: 14px; --bsfm-fs-xs: 12px;
  --bsfm-lh-body: 1.6;
}

/* Tema claro — mesmos tokens, valores trocados */
[data-theme="light"] {
  --bsfm-bg: #F6FAF7;      --bsfm-surface-1: #FFFFFF;
  --bsfm-surface-2: #EEF4F0; --bsfm-border: #D8E3DC;
  --bsfm-text: #10201A;    --bsfm-text-muted: #4C6157;
  --bsfm-accent-soft: #DCFCE7;
}
```

**Regras de layout** (herdadas do modelo): sidebar de 240 px em desktop, gaveta em mobile; conteúdo com medida máxima de 68 caracteres; base de 8 px para todo espaçamento; separação por superfície, não por sombra; uma única ação primária por tela.

---

## 8. Mapa de telas do BSFM remasterizado

| # | Tela | Origem no modelo | Componentes |
|---|---|---|---|
| 1 | Entrada (Cadastro/Login) | header + formulário | campo com label flutuante, medidor de força de senha, erro inline |
| 2 | Onboarding (tour) | `xap-tour` | 3 passos, progresso, pular |
| 3 | Painel | navegação em abas | cards de IMC/TMB/gasto, gráfico de evolução |
| 4 | Analisar alimento | callout + bloco de código → câmera | upload/drag, preview, resultado com tabela nutricional |
| 5 | Diário | lista | refeições por dia, totais |
| 6 | Metas | formulário | metas calóricas, progresso |
| 7 | Planos | tabela | plano alimentar semanal |
| 8 | Hospitais SP | sidebar filtrável | busca, mapa, lista com distância |
| 9 | Documentação | docs do modelo | markdown + âncoras + anterior/próximo |

---

## 9. Pendências desta varredura

1. **2ª passada no modelo** com recarga controlada (`capture_browser_scenario` com `Page.reload`) para capturar scripts, endpoints e cabeçalhos — hoje o bundle real ficou invisível.
2. **CSS computado**: preciso de uma execução que leia `getComputedStyle` (hoje o REA é passivo). Alternativa: capturar as folhas de estilo em texto e derivar os tokens reais.
3. **Estado logado do modelo** (API reference), para observar sessão e cookies.
4. **Varredura do BSFM com o app rodando** (C# na :5000 + banco), não só a página estática.
5. **Mobile**: viewport de 390×844 para derivar o comportamento responsivo do modelo.

---

## 10. Rastreabilidade

Toda afirmação deste documento vem de uma destas fontes:

| Tipo | Base |
|---|---|
| **Observado** | Evidence IDs da seção 1.2; cores medidas no PNG; links do DOM; arquivos do projeto lidos |
| **Inferido** | família tipográfica, hex exato do acento, presença de CSP completa, "Material" |
| **Desconhecido** | cookies, cabeçalhos, endpoints reais, texto do CSS, estado logado |

Nenhuma conclusão aqui depende de comparar o modelo com "o que o BSFM deveria ser" por semelhança visual.
