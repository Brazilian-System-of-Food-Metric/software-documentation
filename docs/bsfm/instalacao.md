# Instalação do BSFM

Este guia mostra como executar o projeto localmente e como fazer deploy em produção.

## Visão Rápida

- **Backend**: .NET 8 (ASP.NET Core)
- **Frontend (v1)**: HTML/CSS/JS servido estaticamente pelo backend
- **Frontend (v2 / REMASTER)**: React 18 + Vite 5 (SPA), build em `v2/web/dist`
- **Banco de dados**: PostgreSQL (produção) / SQLite (desenvolvimento)
- **Deploy**: Render (produção)
- **Documentação**: Vercel (MkDocs)

## v2 (REMASTER) — React + Vite

A versão remasterizada fica em `v2/` e **não** usa HTML/CSS/JS solto no front:

| Camada | Tecnologia |
|---|---|
| Front | React 18.3.1 + Vite 5.4 (`v2/web`) |
| Back | ASP.NET Core + EF Core (`v2/backend`) |
| Dados | TACO local (582 alimentos) + PostgreSQL/SQLite |
| Instalação | PWA (`manifest.webmanifest` + `sw.js`), sem APK |

### Rodar localmente

```bash
# API (porta 5100)
dotnet run --project v2/backend/BSFM.Api

# Front (porta 5173, proxy /api -> 5100)
cd v2/web
npm install
npm run dev
```

### Build de produção

```bash
cd v2/web
npm run build      # gera dist/ com assets hash
```

O backend serve o conteúdo de `wwwroot`; no container, copie `dist/` para
`wwwroot`. O service worker (`public/sw.js`) versiona o shell e nunca cacheia
`/api/*`.

### Variáveis da v2

| Variável | Uso |
|---|---|
| `DATABASE_URL` | Postgres (produção) ou caminho SQLite |
| `BSFM_BD_PROVIDER` | `sqlite` para forçar SQLite |
| `BREVO_API_KEY` | envio de códigos de verificação |
| `BSFM_GEMINI_API_KEY` | reconhecimento por imagem (opcional) |
| `BSFM_ORIGENS_PERMITIDAS` | CORS explícito |

`USDA_API_KEY` e `GROQ_API_KEY` são da v1: a v2 usa o catálogo TACO local e o
motor de regras para o feedback. O healthcheck da v2 é `GET /saude`.

## Pré-requisitos

- .NET SDK 8+
- Git
- PostgreSQL 15+ (ou SQLite para desenvolvimento)
- Visual Studio 2022 ou VS Code

## Instalação Local

### 1. Clonar Repositório

```bash
git clone https://github.com/Brazilian-System-of-Food-Metric/BSFM-APP.git
cd BSFM-APP
```

### 2. Restaurar Dependências

```bash
dotnet restore
```

### 3. Configurar Banco de Dados

#### Opção A - PostgreSQL (Recomendado para produção)
```bash
# Criar container PostgreSQL
docker run -d --name bsfm-postgres \
  -p 5432:5432 \
  -e POSTGRES_DB=bsfm_dev \
  -e POSTGRES_USER=bsfm_user \
  -e POSTGRES_PASSWORD=senha_segura \
  -v bsfm-data:/var/lib/postgresql/data \
  postgres:15-alpine
```

#### Opção B - SQLite (Desenvolvimento rápido)
O projeto já está configurado para usar SQLite como fallback. Basta configurar a variável de ambiente:
```bash
set DATABASE_URL=Data Source=bsfm.db
```

### 4. Configurar Variáveis de Ambiente

Crie um arquivo `.env` na raiz do projeto ou configure no sistema:

```bash
# Banco de dados (PostgreSQL)
DATABASE_URL=Host=localhost;Database=bsfm_dev;Username=bsfm_user;Password=senha_segura

# APIs Externas
USDA_API_KEY=sua-chave-usda-aqui
BREVO_API_KEY=sua-chave-brevo-aqui
GROQ_API_KEY=sua-chave-groq-aqui

# Ambiente
ASPNETCORE_ENVIRONMENT=Development
ASPNETCORE_URLS=http://localhost:5000
```

### 5. Executar a Aplicação

```bash
dotnet run
```

A aplicação estará disponível em: **http://localhost:5000**

Para desenvolvimento com hot reload:
```bash
dotnet watch run
```

## Deploy no Render

### Pré-requisitos para Deploy

1. Conta no [Render](https://render.com)
2. Repositório no GitHub conectado ao Render
3. Banco PostgreSQL (Render oferece PostgreSQL gratuito)

### Passo a Passo

#### 1. Criar Banco PostgreSQL no Render
1. Acesse o Dashboard do Render
2. Clique em **New +** > **PostgreSQL**
3. Configure:
   - **Name**: `bsfm-db`
   - **Database**: `bsfm_prod`
   - **User**: `bsfm_user`
   - **Region**: `São Paulo (South America)`
4. Após criar, copie a **Internal Database URL**

#### 2. Criar Web Service no Render
1. Clique em **New +** > **Web Service**
2. Conecte seu repositório GitHub
3. Configure:
   - **Name**: `bsfm-api`
   - **Runtime**: `Docker` (ou `.NET 8` se disponível)
   - **Build Command**: `dotnet publish -c Release -o output`
   - **Start Command**: `dotnet output/MobileRepositorio.dll`
   - **Plan**: Free

#### 3. Configurar Variáveis de Ambiente no Render

No painel do Web Service, vá em **Environment** e adicione:

| Variável | Valor |
|----------|-------|
| `ASPNETCORE_ENVIRONMENT` | `Production` |
| `DATABASE_URL` | `Host=...;Database=bsfm_prod;Username=bsfm_user;Password=...` |
| `USDA_API_KEY` | Sua chave da API USDA |
| `BREVO_API_KEY` | Sua chave da API Brevo |
| `GROQ_API_KEY` | Sua chave da API Groq |

#### 4. Deploy Automático
- O Render faz deploy automático a cada push na branch principal
- Para deploy manual: clique em **Manual Deploy** > **Deploy latest commit**

### Arquivos de Configuração para Deploy

O projeto inclui:

- **render.yaml**: Configuração Infrastructure as Code para o Render
- **Dockerfile**: Containerização da aplicação
- **Program.cs**: Configurado para ler PORT, DATABASE_URL e outras variáveis

### Health Check

Após o deploy, acesse: `https://seu-app.onrender.com/saude`

Retorno esperado (v2):
```json
{
  "status": "ok",
  "servico": "bsfm-api",
  "versao": "s2"
}
```

> A v1 respondia em `/health`; a v2 padronizou o healthcheck em `/saude`.

## Checklist de Deploy

- [ ] Repositório no GitHub
- [ ] Conta no Render criada
- [ ] Banco PostgreSQL criado no Render
- [ ] Variáveis de ambiente configuradas (incluindo GROQ_API_KEY)
- [ ] Build passando no Render
- [ ] Health check respondendo
- [ ] Funcionalidades testadas em produção

## Solução de Problemas

### Erro de Conexão com Banco
```bash
# Verifique se a DATABASE_URL está correta
# O sistema tenta reconectar automaticamente até 3 vezes
```

### Porta em Uso
```bash
# Mude a porta no Render ou localmente
ASPNETCORE_URLS=http://localhost:5001
```

### Build Falhando
```bash
# Verifique se o .NET SDK 8 está instalado
dotnet --version
# Deve retornar 8.x.x
```

### Groq API não funciona
```bash
# Verifique se a GROQ_API_KEY está configurada
# O serviço funciona sem ela, mas o feedback IA não estará disponível
```
