# DOC-08 — Paridade entre o site original e o novo

**Data:** 2026-11-14
**Método:** inspeção das duas URLs em navegador real (CDP), comparação de estrutura,
capturas de tela e teste automatizado de paridade (`v2/web/verificar-paridade.mjs`).

| Ambiente | URL | Situação |
|---|---|---|
| Original | `https://bsfm-nutri.vercel.app/` | landing + 10 páginas da aplicação v1 |
| Novo | `https://bsfm-nutri.onrender.com/` | SPA React (v2) |

---

## 1. O que a inspeção mostrou

**Original (Vercel)** — 54 KB de HTML, 31 links, 9 seções na landing
(“Por que o BSFM Existe?”, “O que já Oferece”, “Como Funciona”, “Status”,
“Inclusão”, “Documentação”…), botão **“📱 INSTALAR APP”** e `manifest.json?v=3`.
O navegador dispara `beforeinstallprompt` — ou seja, instalável já na landing.

**Novo (Render)** — 1,2 KB de HTML: a SPA abre direto no **login**. Zero links,
zero seções, nenhum botão de instalar antes de autenticar. O PWA estava tecnicamente
pronto (`manifest.webmanifest` e `sw.js` servidos com o tipo correto, service worker
ativo), mas **sem nenhuma chamada para instalar na porta de entrada**.

Conclusão: não era falta de suporte a PWA — era falta de **landing** e de **CTA de
instalação antes do login**.

---

## 2. Comparação tela por tela

| Recurso | Original (v1) | Novo antes | Novo agora |
|---|---|---|---|
| Landing institucional | 9 seções | ausente | **restaurada** (7 seções) |
| Instalar antes do login | botão “INSTALAR APP” | ausente | **restaurada** (hero, menu, tela de login) |
| Documentação (links) | 5 links | ausente | **restaurada** (4 guias) |
| Login | `login.html` | presente | presente |
| Cadastro | `login.html` (aba) | ausente | **restaurada** (com verificação por e-mail) |
| Painel | `dashboard.html` | presente | presente (donut, água, IMC, peso) |
| Análise por foto | `analisador-ia.html` | só busca por nome | **restaurada** (upload → reconhecimento) |
| Análise de rótulo (OCR) | `analisador-rotulo.html` | ausente | **pendente** |
| Diário | `diario.html` | presente | presente (agrupado por dia) |
| Metas | `metas.html` | API sem tela | **restaurada** (formulário + histórico) |
| Planos semanais | `planos.html` | API sem tela | **restaurado** (7 dias × 4 refeições) |
| Hospitais de SP | `hospitais.html` | ausente | **pendente** (tabela existe, dados não) |
| Libras | `libras.html` | ausente | **restaurado** (widget VLibras global) |
| Alerta de saúde | `alerta-saude-pendente.html` | ausente | **pendente** |
| PWA instalável | manifest + sw | pronto, sem CTA | pronto **com CTA** |

---

## 3. O que foi implementado nesta rodada

1. **Landing pública** em `/`, com hero, 6 recursos, 3 passos, números do projeto,
   status, documentação e chamada final. Quem já tem conta vê “Entrar”; quem não tem
   vê “Criar conta grátis”.
2. **Instalação visível antes do login** — no topo da landing, no hero e na tela de
   autenticação. O botão só fica habilitado quando o navegador confirma que o app é
   instalável (`beforeinstallprompt`); em iOS a instrução exibida é “Compartilhar →
   Adicionar à Tela de Início”.
3. **Tela de Metas** — meta calórica, proteica, de água e de peso, com histórico.
4. **Tela de Planos** — semana com dia e tipo de refeição, calorias e remoção.
5. **Análise por foto** — upload com limite de 6 MB, resultado confirmado antes de
   gravar no diário. Sem chave de visão no servidor, a mensagem explica e sugere a
   busca por nome (não finge que analisou).
6. **Libras** — widget oficial do governo no `index.html`, disponível em todas as telas.

---

## 4. Verificação

`v2/web/verificar-paridade.mjs` executa 18 asserções contra a aplicação servida:

```
[1] Landing pública ................ 7 PASS
[2] Navegação para o login ......... 4 PASS
[3] Aplicativo (abas restauradas) .. 7 PASS
==============================================
                     TODAS AS VERIFICAÇÕES PASSARAM
```

Cobre: h1, seções, navegação, links de documentação, botão de instalar, botão de
entrar, manifest, formulário de login, abas de Planos e Metas carregando, e o bloco
de análise por foto.

Rodou duas vezes: no `vite preview` (dev) e **dentro do container de produção**
(`bsfm-v2:root`, porta 5104) — mesmo resultado.

---

## 5. O que continua pendente

| Item | Por que não foi feito agora |
|---|---|
| **OCR de rótulo** | depende de motor de OCR no servidor (Tesseract) — é uma integração à parte, não uma tela |
| **Hospitais de SP** | a tabela `Hospitais` existe e já aceita CNES/coordenadas, mas os dados do DATASUS ainda não foram importados |
| **Alerta de saúde** | depende de regra clínica que não está definida no projeto |
| **Notificações** | requer service worker com push e chaves VAPID |

Nenhum desses é regressão: são funcionalidades que existiam como página estática na v1
e que dependem de dado ou serviço antes de virar tela na v2.
