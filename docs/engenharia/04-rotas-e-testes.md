# DOC-04 — S3: rotas restantes migradas, erro padronizado e testes idempotentes

**Projeto:** BSFM · PIM 4º semestre
**Data:** 2026-11-13
**Escopo:** concluir a migração de rotas iniciada no S2 e eliminar o que restava de frágil
**Verificação:** 165 asserções no total (47 + 53 + 31 + 34), todas passando

---

## 1. O que foi migrado

Sete controllers, 29 rotas, todas sob `[SessaoObrigatoria]` — nenhuma aceita identidade vinda da URL.

| Antes (anônimo, por id) | Agora | Regra de negócio adicionada |
|---|---|---|
| `POST /registrar-agua` | `POST /api/eu/agua` | limite de 3 L por registro |
| `GET /agua-diario/{usuarioId}` | `GET /api/eu/agua?data=` | meta derivada do peso se não houver meta |
| `GET /agua-semanal/{usuarioId}` | `GET /api/eu/agua/semanal` | 7 dias, média e dias que bateram a meta |
| `DELETE /remover-ultima-agua/{usuarioId}` | `DELETE /api/eu/agua/ultimo` | só remove o próprio registro |
| `GET /refeicoes-semana/{usuarioId}` | `GET /api/eu/refeicoes` | total calórico da semana |
| `POST /salvar-refeicao-semana` | `POST /api/eu/refeicoes` | dia e tipo em lista fechada, macros validados |
| `DELETE /remover-refeicao-semana/{id}` | `DELETE /api/eu/refeicoes/{id}` | id de outro usuário vira 404 |
| `POST /definir-meta` | `PUT /api/eu/metas` | histórico de metas, uma ativa por vez |
| `GET /historico-analises/{usuarioId}` | `GET /api/eu/analises` | paginação com teto de 200 |
| `POST /analisar-prato` (gravação) | `POST /api/eu/analises` | confiança mínima de 0,45 |
| `GET /evolucao/{usuarioId}` | `GET /api/eu/evolucao` | variação de peso/IMC e distância da meta |

### 1.1 Regras que agora existem e antes não existiam

**Confiança mínima.** O app atual aceita detecção com 16% de confiança. Na API nova,
uma análise de foto com confiança abaixo de **0,45** é recusada com 422 e mensagem
explicando o motivo. Registro manual (`origem: manual`) é aceito — o usuário assumiu
o dado. É a diferença entre "o modelo chutou" e "o sistema decidiu".

**Histórico de metas.** `POST /definir-meta` sobrescrevia `Usuarios.PesoMeta`. Agora cada
definição cria uma linha em `Metas` e desativa a anterior, então dá para reconstruir
quando a meta mudou e por quê. O campo antigo continua espelhado por compatibilidade.

**Meta de água derivada.** Sem meta definida, o alvo é 35 ml/kg com piso de 1,5 L —
calculado no servidor, não no JavaScript.

**Validação de domínio.** Dia da semana e tipo de refeição são listas fechadas; valores
com acento são normalizados antes de comparar; macros acima de 500 g e calorias acima
de 5.000 kcal são recusados.

**Resumo diário.** `GET /api/eu/analises/resumo` devolve totais do dia — a base do
gráfico do painel.

---

## 2. Erro padronizado

`TratamentoErrosMiddleware` responde no formato Problem Details (RFC 9457):

```json
{
  "type": "https://bsfm.dev/erros/erro_interno",
  "title": "Erro interno",
  "status": 500,
  "erro": "erro_interno",
  "traceId": "0HN7..."
}
```

O que mudou na prática:

| Antes | Agora |
|---|---|
| `{ mensagem: "Erro ao conectar com o banco de dados." }` com 500 para tudo | status por tipo (400/403/404/500) e código estável |
| mensagem de exceção do banco ia para o cliente | detalhe técnico só no log, com `traceId` para correlacionar |
| cancelamento do cliente virava erro 500 | `OperationCanceledException` é ignorada |

---

## 3. Testes idempotentes

O primeiro `smoke-s3.ps1` só passava em banco limpo — cada execução acumulava água,
refeições e análises, e as asserções quebravam na segunda rodada. Um teste que exige
"apague o banco antes" esconde regressão.

A correção foi medir **delta** em relação ao estado inicial:

```powershell
$aguaInicial = (Json (Autenticado 'GET' '/api/eu/agua').Corpo).totalMl
# ...
Verificar 'registra 250 ml' (Perto $a1.totalMl ($aguaInicial + 250))
```

Resultado: **34/34 na primeira rodada e 34/34 na segunda, no mesmo banco.**

Também foi corrigido um artefato do PowerShell 5.1: `Json (Comando ...).Corpo` tem
parsing ambíguo e devolvia contagem errada em arrays. A leitura passou a ser explícita
— `@($resposta.Corpo | ConvertFrom-Json)`.

---

## 4. Bateria completa

| Suíte | Asserções | Resultado |
|---|---|---|
| `BSFM.Seguranca.Verificacao` | 47 | 47 PASS |
| `BSFM.Dados.Verificacao` (schema) | 53 | 53 PASS |
| `smoke-s2.ps1` (auth, perfil, saúde) | 31 | 31 PASS |
| `smoke-s3.ps1` (água, refeições, metas, análises, evolução) | 34 | 34 PASS |
| **Total** | **165** | **165 PASS / 0 FAIL** |

```powershell
cd REMASTER\backend\BSFM.Api;                 dotnet run
cd REMASTER\backend\BSFM.Dados.Verificacao;   dotnet run
cd REMASTER\backend\BSFM.Seguranca.Verificacao; dotnet run
powershell -File REMASTER\backend\smoke-s2.ps1
powershell -File REMASTER\backend\smoke-s3.ps1
```

---

## 5. Cobertura de rotas: antes e depois

| Situação | Rotas |
|---|---|
| Legado anônimo (`Program.cs`) | 33 + 3 controllers |
| Migrado e protegido | 29 |
| Restante no legado | análise por imagem (YOLO), rótulo (OCR), PWA, `/api/gerar-apk` |

O que falta é o que depende de infraestrutura de IA — `YoloInferenceService` e
`OcrNutricionalService` continuam no app legado (net8) até a S4. A API nova já tem onde
gravar o resultado com rastreabilidade.

---

## 6. Próximos passos

| # | Item | Por quê |
|---|---|---|
| 1 | Portar YOLO/OCR para o projeto novo | hoje o `.onnx` só roda no legado |
| 2 | Importar TACO e CNES (hospitais de SP) | tabelas prontas, dados ainda não |
| 3 | Front React consumindo este contrato | o front atual lê `localStorage` |
| 4 | App mobile com o mesmo contrato assinado | meta do PIM |
| 5 | Rate limit por IP | hoje o bloqueio é por conta |
| 6 | Verificação de e-mail obrigatória | campo existe, regra não |

---

## 7. Rastreabilidade

| Fonte | Sustentou |
|---|---|
| 7 controllers em `BSFM.Api/Controllers` | 29 rotas, 165 asserções |
| `TratamentoErrosMiddleware.cs` | formato de erro padronizado |
| Execução de `smoke-s3.ps1` duas vezes no mesmo banco | prova de idempotência |
| Execução das 4 suítes | 165 PASS / 0 FAIL |
