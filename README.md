# BSFM - Brazilian System of Food Metric

> **Projeto Acadêmico** - UNIP - Análise e Desenvolvimento de Sistemas - 3º Semestre - 2026

Plataforma de nutrição inteligente com análise de alimentos por IA, dashboard de métricas e plano alimentar personalizado.

## 🚀 Tecnologias

- **Backend:** .NET 8.0 (ASP.NET Core)
- **Frontend:** HTML, CSS, JavaScript (Tailwind CSS)
- **Banco:** PostgreSQL (produção) / SQLite (desenvolvimento)
- **IA:** YOLO Object Detection (ONNX)
- **Deploy:** Render
- **Documentação:** MkDocs (Vercel)

## 📋 Funcionalidades

- ✅ Cadastro e login de usuários
- ✅ Dashboard com métricas (IMC, TMB, TDEE)
- ✅ Análise de alimentos por IA (YOLO + USDA)
- ✅ Diário alimentar
- ✅ Plano de refeições semanal
- ✅ Consumo de água
- ✅ Mapa SOS Saúde (Leaflet)
- ✅ Central LIBRAS
- ✅ Perfil do usuário
- ✅ Gráficos de evolução (Chart.js)

## 🛠️ Como Executar Localmente

```bash
# 1. Clone o repositório
git clone <url-do-repositorio>
cd pim-03semestre-ads

# 2. Restaure as dependências
dotnet restore

# 3. Configure variáveis de ambiente
set USDA_API_KEY=sua_chave_aqui
set BREVO_API_KEY=sua_chave_aqui
set DATABASE_URL=Host=localhost;Database=bsfm_dev;Username=bsfm_user;Password=senha

# 4. Execute
dotnet run
```

## 📚 Documentação

A documentação completa está disponível em:

- [Instalação](docs/bsfm/instalacao.md)
- [Configuração](docs/bsfm/config.md)
- [Guia do Usuário](docs/guia-usuario/introducao.md)
- [Guia do Desenvolvedor](docs/guia-desenvolvedor/index.md)
- [Casos de Uso](docs/caso-de-uso/index.md)
- [Glossário](docs/glossario/index.md)
- [Roadmap](docs/roadmap/index.md)

## 🌐 Deploy

- **Produção:** Render (backend + frontend)
- **Documentação:** Vercel (MkDocs)

## 👥 Equipe

- **Isaque de Medeiros**
- **Yuri**
- **Gustavo**
- **Giovana**

## 📄 Licença

Projeto acadêmico - UNIP 2026
