# DOC-05 — Camada nutricional: por que o YOLO sai do centro

**Projeto:** BSFM · PIM 4º semestre
**Data:** 2026-11-13
**Decisão:** separar "descobrir o nome do alimento" de "transformar o nome em nutrientes"
**Verificação:** 254 asserções no total, todas passando

---

## 1. O diagnóstico do problema

O sintoma relatado: "o modelo YOLO não reconhece quase nada".

Olhando o código, o problema tem três camadas — e só uma é o modelo:

| Camada | Situação | Consequência |
|---|---|---|
| **Classificador** | YOLOv8 próprio, 452 classes, `.onnx` de 12 MB, threshold **0,16** | Threshold baixíssimo é sintoma de modelo fraco: aceitar 16% de confiança gera falso positivo em quase tudo |
| **Tradução** | dicionário fixo embutido de EN → PT com 452 itens | qualquer classe fora da lista vira string vazia |
| **Nutrição** | `UsdaNutritionService` (base americana, em inglês) | medida caseira brasileira (colher, concha, fatia) não tem correspondência |

Ou seja: mesmo que o classificador acertasse 100%, o caminho seguinte ainda poderia
devolver "sem dados". Melhorar o modelo sozinho não resolveria o produto.

### 1.1 O que o limiar de 0,16 significa

Um detector com `conf >= 0.16` aceita qualquer caixa que ele julgue 16% provável. Em
uma foto de prato, isso produz várias detecções erradas com aparência de acerto. O
app escolhe a primeira e mostra calorias de um alimento que não está na foto. É pior
que não detectar: cria confiança falsa em dado de saúde.

---

## 2. A decisão: duas etapas, provedores trocáveis

```
[ imagem ] --(visão)--> [ nome do alimento ] --(catálogo)--> [ nutrientes ]
[ texto  ] ------------> [ nome do alimento ] --(catálogo)--> [ nutrientes ]
```

A visão é **uma** das formas de chegar ao nome. Texto digitado é outra. O catálogo é
quem produz número — e é isso que o usuário vê.

### 2.1 O que foi construído — `BSFM.Nutricao`

| Arquivo | Papel |
|---|---|
| `CatalogoAlimentos.cs` | 54 alimentos brasileiros comuns, valores por 100 g + carga por CSV |
| `BuscaAlimentos.cs` | normalização (acento, caixa, pontuação), plural, erro de digitação, pontuação |
| `AnalisadorAlimento.cs` | orquestra visão → catálogo → porção |
| `Visao/IVisaoAlimento.cs` | contrato: nome + confiança, ou "não sei" |
| `Visao/VisaoGemini.cs` | visão multimodal via Gemini (nível gratuito), JSON estrito |

### 2.2 Por que visão multimodal em vez de YOLO

Reconhecer comida em foto não é "detectar objeto": é separar "arroz, feijão e bife"
em três itens e nomear cada um em português. Um YOLO com poucas centenas de imagens
não chega lá sem dataset grande e GPU. Um modelo multimodal pré-treinado faz isso
sem treino, no nível gratuito, e devolve o nome — que é exatamente o que o catálogo
precisa como entrada.

O YOLO **não foi descartado**: ele implementa o mesmo `IVisaoAlimento` e pode entrar
como candidato quando for retreinado. Se acertar, ótimo; se não, o sistema continua
funcionando por texto.

### 2.3 Honestidade embutida

Três comportamentos foram desenhados para não mentir:

| Situação | Resposta |
|---|---|
| Provedor de visão sem chave | **503** com `motivo: provedor_de_visao_indisponivel` — nunca 200 com chute |
| Visão acerta nome que o catálogo não tem | **422** com `alimento_fora_do_catalogo` + lista de candidatos |
| Confiança da análise abaixo de 0,45 (foto) | **422** `confianca_insuficiente` |

E a regra mais importante: **o cliente não envia calorias**. Em
`POST /api/eu/analises/do-catalogo` ele manda nome e gramas; o servidor calcula.
O endpoint antigo (que aceita números) continua só para rótulo e ajuste manual.

---

## 3. Busca tolerante — o que faz o catálogo valer

Um catálogo só serve se o usuário conseguir achar o que quer. O engine cobre:

| Entrada | Resultado |
|---|---|
| `Arroz` / `ARROZ` / `arroz, branco.` | `Arroz branco cozido` |
| `feijão` (com acento) | `Feijao carioca cozido` |
| `macas` (plural) | `Maca com casca` |
| `aroz` (erro de digitação) | `Arroz branco cozido` |
| `arroz integral` | `Arroz integral cozido` — não cai no branco |
| `xilofone quantico` | lista vazia ("não identificado") |

Pontuação: 1,0 exato · 0,97 plural · 0,90 prefixo · 0,80 contém · 0,75 todos os termos ·
Jaccard 0,45–0,75 · Levenshtein até 0,70. Mínimo de aceitação: **0,55**.

---

## 4. Catálogo — decisão sobre os dados

54 itens, valores por 100 g, arredondados, de referência TACO. **Não são a planilha
oficial** — são ordem de grandeza correta para o app funcionar offline e para o
cálculo por porção ser verificável.

O harness valida coerência interna: `kcal ≈ 4·P + 4·C + 9·G` com até 25% de desvio.
Isso pega erro de digitação em macro, que é o erro mais comum em base manual.

Para os valores exatos: `CatalogoAlimentos.CarregarCsv(...)` lê
`nome;grupo;kcal;proteina;carbo;gordura;fibra;sinonimos`, ignorando linha inválida
sem derrubar as outras.

**Pendência declarada:** importar a planilha TACO completa (≈600 itens) e carregar
também no banco (`Alimentos`), para permitir edição sem deploy.

---

## 5. Rotas novas

| Rota | Autenticação | Papel |
|---|---|---|
| `GET /api/nutricao/alimentos?q=` | pública | busca no catálogo |
| `POST /api/nutricao/por-nome` | pública | nome + gramas → nutrientes (prévia) |
| `POST /api/nutricao/por-imagem` | pública | imagem (base64) → nome → nutrientes |
| `GET /api/nutricao/provedor` | pública | estado do reconhecimento por imagem |
| `POST /api/eu/analises/do-catalogo` | sessão + assinatura | **grava** com cálculo do servidor |

O fluxo é: descobrir (público) → usuário confirma → gravar (autenticado). Separar
evita que erro de modelo vire histórico do paciente sem confirmação.

---

## 6. Verificação

| Suíte | Asserções | Resultado |
|---|---|---|
| `BSFM.Seguranca.Verificacao` | 47 | 47 PASS |
| `BSFM.Dados.Verificacao` (schema) | 53 | 53 PASS |
| `BSFM.Nutricao.Verificacao` | 54 | 54 PASS |
| `smoke-s2.ps1` (auth, perfil, saúde) | 31 | 31 PASS |
| `smoke-s3.ps1` (água, refeições, metas, análises) | 38 | 38 PASS |
| `smoke-s4.ps1` (nutrição) | 31 | 31 PASS |
| **Total** | **254** | **254 PASS / 0 FAIL** |

Casos que valem para a banca:

- `aroz` (erro de digitação) encontra arroz.
- 150 g de arroz → 192 kcal, calculado no servidor.
- Visão sem chave → 503 com motivo, **não** resultado falso.
- Visão que acerta nome desconhecido → 422, sem nutriente inventado.
- `POST /api/eu/analises/do-catalogo` ignora calorias do cliente.

---

## 7. Como ligar o reconhecimento por imagem

```powershell
$env:BSFM_GEMINI_API_KEY = "<sua-chave>"   # nível gratuito do Google AI Studio
$env:BSFM_GEMINI_MODEL   = "gemini-2.5-flash"  # opcional
cd REMASTER\backend\BSFM.Api; dotnet run
```

Sem a chave, tudo o resto continua funcionando: busca, análise por nome e registro.

---

## 8. O que ainda falta

| # | Item | Observação |
|---|---|---|
| 1 | Importar TACO completa | estrutura pronta (`CarregarCsv`) |
| 2 | Alimentar `Alimentos` no banco | hoje o catálogo é em memória |
| 3 | Retreinar/reaproveitar o YOLO como provedor | implementa `IVisaoAlimento` |
| 4 | Medida caseira ("1 colher", "1 concha") | hoje só gramas |
| 5 | Foto do rótulo (OCR) | `OcrNutricionalService` fica no legado por enquanto |
| 6 | Front React consumindo estas rotas | próximo passo natural |

---

## 9. Rastreabilidade

| Fonte | Sustentou |
|---|---|
| Execução de `BSFM.Nutricao.Verificacao` | 54 asserções de busca, porção, CSV e visão |
| Execução de `smoke-s4.ps1` | 31 asserções HTTP de nutrição |
| Execução de `smoke-s3.ps1` | 38 asserções, incluindo gravação do catálogo |
| Leitura de `YoloInferenceService.cs` e `Program.cs` (DOC-02) | threshold 0,16 e dicionário fixo |
