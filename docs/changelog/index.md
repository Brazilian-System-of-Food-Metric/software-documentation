# Changelog BSFM

Este documento registra todas as mudanças significativas no **BSFM (Brazilian System of Food Metric)**. Seguimos o padrão [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/) e versionamento [Semantic Versioning](https://semver.org/lang/pt-BR/).

---

## [1.3.0] - 2026-04-29

### 🚀 Atualização Pré-Definitiva - PWA e Correções Finais
**Versão de aprimoramento final antes da entrega acadêmica.**

### Novas Funcionalidades
- **PWA (Progressive Web App)**: Aplicação instalável em dispositivos móveis com manifest.json e service worker
- **Ícone SVG do BSFM**: Logotipo otimizado para PWA com folha verde gradiente
- **Seção "Baixe o App"**: Opção de download na landing page com QR Code e APK

### Melhorias Técnicas
- **Meta tags PWA**: Adicionadas em todas as páginas HTML (index, login, dashboard, diario, analisador-ia, metas, planos, hospitais, libras)
- **Service Worker**: Cache offline com estratégia network-first para melhor performance
- **Documentação MkDocs atualizada**: Conteúdo revisado com informações realistas de protótipo
- **Correção de navegação**: Links rápidos da home page corrigidos para caminhos corretos
- **Paleta de cores ajustada**: Barra de navegação da documentação alterada de vermelho para preto com detalhes em laranja, combinando com o tema escuro

### Correções
- Links quebrados na página inicial da documentação corrigidos
- Conteúdo exagerado substituído por informações transparentes sobre o status de protótipo acadêmico

---

## [1.2.0] - 2026-04-28

### 🎯 Remasterização Final - Versão de Entrega Acadêmica
**Última versão do protótipo para apresentação do PIM do 3º semestre.**

### Novas Funcionalidades
- **Consumo de Água**: Registro e acompanhamento diário/semanal de hidratação
- **Plano de Refeições Semanal**: Agendamento de refeições por dia da semana com receitas
- **Perfil do Usuário**: Edição de nome, senha e data de nascimento
- **Gráficos de Evolução**: Chart.js integrado com dados reais do backend para peso e IMC
- **Analisador IA com Viewfinder**: Interface profissional com efeitos de escaneamento
- **Mapa SOS Saúde**: Leaflet integrado para localização de UPAs e hospitais
- **Central LIBRAS**: Player de vídeo com suporte a PIP

### Melhorias Técnicas
- **Refatoração completa do tema**: Padronização para tema claro (light-mode) em todas as páginas
- **Animações de entrada**: Cards com fade-in-up escalonado no dashboard
- **Métricas animadas**: Valores de IMC, TMB e TDEE com contagem animada
- **Responsividade**: Layout adaptativo mobile-first em todas as páginas
- **CORS configurado**: Política AllowAny para deploy no Render
- **Retry de conexão**: Sistema de tentativas para conexão com PostgreSQL no startup
- **Documentação revisada**: Remoção de informações inventadas, transparência total sobre o status de protótipo

### Infraestrutura
- **Render**: Configuração de deploy via render.yaml e Dockerfile
- **PostgreSQL**: Suporte a Neon/Railway com parsing automático de DATABASE_URL
- **Variáveis de ambiente**: PORT, DATABASE_URL, BREVO_API_KEY, USDA_API_KEY

---

## [1.1.0] - 2026-04-08

### Versão Remasterizada (metodologia SDD)
**Refatoração estrutural e melhoria do processo de desenvolvimento.**

### Novas Funcionalidades
- Organização da documentação por seções e navegação revisada
- Padronização de fluxo de trabalho com metodologia SDD
- Evolução do design system

### Infraestrutura
- Planejamento inicial de deploy no Railway
- Documentação hospedada no Vercel

---

## [1.0.0] - 2026-03-20

### Lançamento da v1
**Primeira versão funcional publicada para validação do projeto.**

### Base entregue
- Primeira experiência de análise de alimentos por IA
- Estrutura inicial de dashboard e autenticação
- Primeira publicação técnica da documentação

---

## [0.9.0] - 2026-03-15

### Beta Interno
**Versão beta para testes internos da equipe.**

### Funcionalidades Implementadas
- **Sistema de login e cadastro** básico
- **Análise de alimentos** com modelo YOLO inicial
- **Dashboard simples** com métricas básicas
- **Integração USDA API** para dados nutricionais

### Melhorias
- Implementação do modelo YOLO para detecção de alimentos
- Implementação de cache para consultas USDA
- Melhoria na interface do analisador de alimentos

---

## [0.8.0] - 2026-02-28

### Alpha Técnico
**Primeira versão funcional do backend.**

### Funcionalidades Implementadas
- **Backend .NET 8.0** com estrutura básica de rotas
- **Modelo YOLO** treinado com dataset inicial
- **Integração USDA API** funcionando
- **Banco de dados SQLite** para desenvolvimento local

---

## Política de Versionamento

### Versões Semânticas
O BSFM segue o versionamento semântico `MAJOR.MINOR.PATCH`:

1. **MAJOR**: Mudanças incompatíveis com versões anteriores
2. **MINOR**: Novas funcionalidades compatíveis com versões anteriores
3. **PATCH**: Correções de bugs compatíveis com versões anteriores

### Categorias de Mudanças
Cada versão é organizada por categorias:

- **Novas Funcionalidades**: Novos recursos implementados
- **Melhorias**: Aprimoramentos em funcionalidades existentes
- **Correções de Bugs**: Resolução de problemas reportados
- **Documentação**: Atualizações na documentação
- **Infraestrutura**: Mudanças em deploy e configurações

---

**Última atualização:** 29 de Abril de 2026  
**Mantido por:** Equipe Técnica BSFM - UNIP
