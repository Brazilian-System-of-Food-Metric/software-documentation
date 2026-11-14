# DOC-06 — Base TACO completa e a decisão pendente do front

**Projeto:** BSFM · PIM 4º semestre
**Data:** 2026-11-13
**Entrega:** catálogo nutricional real (582 alimentos) substituindo a semente de 54
**Verificação:** 266 asserções, todas passando
**Bloqueio identificado:** o front web não pode assinar requisições com segredo global

---

## 1. O que foi importado

Fonte: **TACO 4ª edição (NEPA/UNICAMP)**, normalizada e versionada em
[brolesi/taco](https://github.com/brolesi/taco) — dados públicos, com pipeline
reprodutível e validação por esquema.

| Etapa | Resultado |
|---|---|
| Registros na fonte | 597 |
| Importados | **582** |
| Descartados sem energia | 6 |
| Descartados sem macro completo | 9 |
| Duplicatas removidas | 0 |

Distribuição por grupo:

| Grupo | Itens |
|---|---|
| Carnes e derivados | 123 |
| Verduras, hortaliças e derivados | 99 |
| Frutas e derivados | 96 |
| Cereais e derivados | 63 |
| Pescados e frutos do mar | 50 |
| Alimentos preparados | 32 |
| Leguminosas e derivados | 30 |
| Leite e derivados | 21 |
| Produtos açucarados | 20 |
| Bebidas | 13 |
| Nozes e sementes | 10 |
| Ovos e derivados | 7 |

Arquivo: `BSFM.Nutricao/dados/taco.csv` (69 KB), copiado para o output da API.

### 1.1 Tratamento dos dados

| Caso na fonte | Decisão |
|---|---|
| `Tr` (traço) | convertido para `0` |
| Fibra ausente | `0`, documentado (a TACO deixa de medir em parte dos itens) |
| Linha sem energia ou sem macro completo | descartada — nutriente faltando não vira zero silencioso |
| Descrição com `;` ou `\|` | sanitizada, para não quebrar o formato |

### 1.2 Sinônimos gerados

Para cada item, quatro formas de busca derivadas de `base + preparo + qualificadores`:

```
"Arroz, tipo 1, cozido"
  → Arroz | Arroz cozido | Arroz tipo 1 | Arroz tipo 1 cozido
```

É isso que faz `arroz cozido` encontrar o item sem exigir a descrição completa.

---

## 2. Ranqueamento — o problema real da busca

Com 582 itens, "casou" deixou de bastar: **vinte** variedades de arroz casam com
"arroz". A primeira versão devolvia resultados absurdos:

| Consulta | Antes | Depois |
|---|---|---|
| `arroz` | Arroz, integral, cozido | Arroz, tipo 1, cozido |
| `feijao` | Feijão, broto, cru | Feijão, carioca, cozido |
| `banana` | Banana, doce em barra | Banana, prata, crua |
| `leite` | Leite, condensado | Leite, de vaca, integral |
| `frango` | Frango, coração, grelhado | Frango, peito, sem pele, grelhado |
| `ovo` | Ovo, clara, cozida | Ovo, inteiro, cozido |

Três camadas de desempate, nesta ordem:

1. **Preparo** — cozido (+30), grelhado/assado (+25); broto (−40), seco (−20).
   `cru` só penaliza fora de frutas, hortaliças e ovos, onde é o estado normal.
2. **Processamento** — doce, condensado, em barra, geleia, compota: −25.
3. **Preferência de variante** — tabela explícita `consulta → variante`
   (`leite→vaca`, `banana→prata`, `frango→peito`, `ovo→inteiro`…), +20.
   Parte isolada (clara, gema, coração, fígado): −15.

A tabela é **explícita e auditável** de propósito. Esconder preferência de produto
brasileiro dentro de uma fórmula seria pior: ninguém conseguiria revisar.

> Isso não transforma a busca em adivinhação: a API continua devolvendo até 5
> candidatos com pontuação, e a confirmação é do usuário.

---

## 3. Impacto no app

| Antes | Depois |
|---|---|
| 54 alimentos embutidos no código | 582 em CSV versionado |
| valores de referência aproximados | valores da TACO 4ª edição |
| busca só por nome exato da semente | busca tolerante com sinônimos e desempate |
| catálogo fixo | `BSFM_CATALOGO=<caminho>` troca sem recompilar |

O catálogo sobe com fallback: se o CSV faltar ou tiver menos de 50 itens, a API usa
a semente embutida. O projeto nunca inicia sem catálogo.

---

## 4. Verificação

| Suíte | Asserções | Resultado |
|---|---|---|
| `BSFM.Seguranca.Verificacao` | 47 | 47 PASS |
| `BSFM.Dados.Verificacao` | 53 | 53 PASS |
| `BSFM.Nutricao.Verificacao` | 66 | 66 PASS |
| `smoke-s2.ps1` | 31 | 31 PASS |
| `smoke-s3.ps1` | 38 | 38 PASS |
| `smoke-s4.ps1` | 31 | 31 PASS |
| **Total** | **266** | **266 PASS / 0 FAIL** |

Novos testes entram no lugar de números fixos:

- nome do CSV carregado (`origem = taco`) e contagem > 500;
- **top-1 correto para 8 consultas comuns** (`arroz`, `feijao`, `banana`, `leite`,
  `frango`, `ovo`, `pao de queijo`, `batata`);
- `smoke-s4` deixou de comparar com `128 kcal` fixo e passou a validar faixa plausível;
- `smoke-s3` compara o valor gravado com o retornado pela prévia pública, em vez de
  `192 kcal` cravado — teste que sobrevive a atualização da base.

---

## 5. O bloqueio do front web

Ao planejar a tela, apareceu um problema de arquitetura que precisa de decisão antes
de escrever React.

### 5.1 O problema

`/api/eu/*` exige `X-BSFM-Signature`, um HMAC com segredo **global** do servidor.
No navegador, esse segredo ficaria no bundle — legível por qualquer visitante. Isso
anula a proteção e é pior que não ter: cria a aparência de segurança.

### 5.2 A solução proposta — chave por sessão

Derivar a chave de assinatura do `jti` da sessão:

```
chaveSessao = HMAC-SHA256(segredoMestre, "sessao:" + jti)
```

- o login devolve `chaveAssinatura` **uma vez**, na resposta;
- o cliente guarda **em memória**, nunca em `localStorage`;
- o servidor recalcula a partir do `jti` do token — sem coluna nova no banco;
- revogar a sessão revoga a chave, de graça.

Ganho: o segredo global deixa de circular; cada sessão tem a sua. Se um cliente for
comprometido, o dano fica restrito àquela sessão.

### 5.3 Alternativa mais fraca

Manter a assinatura só para o app mobile (ambiente confiável) e, para o navegador,
usar o token + cookie `SameSite` + CSRF token. É mais simples, mas perde a exigência
literal do PIM de "verificação em hash em cada sessão" no web.

**Recomendação:** chave por sessão. Custa ~1 hora de mudança e mantém a exigência
do trabalho válida também no navegador.

---

## 6. O que vem depois

| # | Item | Depende de |
|---|---|---|
| 1 | Chave de assinatura por sessão | decisão acima |
| 2 | Front React (login, busca, registro, painel) | item 1 |
| 3 | Medidas caseiras (POF: "colher", "concha") | base pronta no mesmo repositório TACO |
| 4 | App mobile React | contrato já estável |

---

## 7. Rastreabilidade

| Fonte | Sustentou |
|---|---|
| `data/processed/taco/taco_composicao.csv` de brolesi/taco | 582 alimentos importados |
| `BSFM.Nutricao.Verificacao` | 66 asserções, incl. top-1 de 8 consultas |
| `smoke-s4.ps1` | 31 asserções HTTP sobre a TACO servida |
| Execução das 6 suítes | 266 PASS / 0 FAIL |
