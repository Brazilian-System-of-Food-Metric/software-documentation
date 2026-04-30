# Glossário do BSFM

Este glossário define os principais termos, conceitos e siglas utilizados no Brazilian System of Food Metric.

---

## Índice Alfabético

**A** • [API](#api) • [ASP.NET Core](#aspnet-core)  
**B** • [BCrypt](#bcrypt) • [BSFM](#bsfm) • [Brevo](#brevo)  
**C** • [Caloria](#caloria) • [Carboidrato](#carboidrato) • [Chart.js](#chartjs) • [CORS](#cors)  
**D** • [Dashboard](#dashboard) • [DTO](#dto)  
**E** • [Entity Framework](#entity-framework) • [Endpoint](#endpoint)  
**I** • [IA](#ia) • [IMC](#imc)  
**J** • [JSON](#json)  
**L** • [Leaflet](#leaflet) • [LGPD](#lgpd)  
**M** • [Macronutriente](#macronutriente) • [MkDocs](#mkdocs)  
**N** • [.NET](#net)  
**O** • [ONNX](#onnx) • [ORM](#orm)  
**P** • [PostgreSQL](#postgresql) • [PWA](#pwa)  
**R** • [Render](#render)  
**S** • [SQLite](#sqlite)  
**T** • [Tailwind CSS](#tailwind-css) • [TDEE](#tdee) • [TMB](#tmb)  
**U** • [USDA](#usda)  
**Y** • [YOLO](#yolo)

---

## Definições

### A

#### **API** (Application Programming Interface)
Conjunto de protocolos e ferramentas para construção de software. A API do BSFM permite integração com outros sistemas através de endpoints RESTful.

#### **ASP.NET Core**
Framework da Microsoft para construção de aplicações web modernas. O BSFM utiliza ASP.NET Core 8.0.

---

### B

#### **BCrypt**
Algoritmo de hash para senhas. Utilizado no BSFM para armazenar senhas de forma segura.

#### **BSFM** (Brazilian System of Food Metric)
Sistema Brasileiro de Métricas Alimentares. Projeto acadêmico de plataforma de nutrição inteligente.

#### **Brevo**
Plataforma de email marketing e transacional. Utilizada no BSFM para envio de códigos de verificação e emails transacionais.

---

### C

#### **Caloria**
Unidade de medida de energia. No contexto nutricional, representa a quantidade de energia fornecida por um alimento.

#### **Carboidrato**
Macronutriente composto por carbono, hidrogênio e oxigênio. Principal fonte de energia do corpo.

#### **Chart.js**
Biblioteca JavaScript para criação de gráficos. Utilizada no BSFM para exibir gráficos de evolução de peso e IMC.

#### **CORS** (Cross-Origin Resource Sharing)
Mecanismo de segurança que permite requisições entre diferentes origens. Configurado no BSFM para permitir acesso de qualquer origem.

---

### D

#### **Dashboard**
Painel de controle que exibe métricas e informações do usuário de forma visual e organizada.

#### **DTO** (Data Transfer Object)
Objeto usado para transferir dados entre camadas da aplicação.

---

### E

#### **Entity Framework Core**
ORM (Object-Relational Mapper) da Microsoft para .NET. Utilizado no BSFM para acesso ao banco de dados.

#### **Endpoint**
URL específica em uma API que aceita requisições e retorna respostas.

---

### I

#### **IA** (Inteligência Artificial)
Sistemas computacionais que simulam inteligência humana. No BSFM, utilizada para reconhecimento de alimentos via YOLO.

#### **IMC** (Índice de Massa Corporal)
Medida que relaciona peso e altura para classificar o estado nutricional. Calculado como peso (kg) ÷ altura² (m).

---

### J

#### **JSON** (JavaScript Object Notation)
Formato leve de intercâmbio de dados. Usado nas APIs do BSFM.

---

### L

#### **Leaflet**
Biblioteca JavaScript de mapas interativos. Utilizada no BSFM para o mapa SOS Saúde.

#### **LGPD** (Lei Geral de Proteção de Dados)
Lei brasileira que regula o tratamento de dados pessoais. O BSFM segue seus princípios no tratamento de dados dos usuários.

---

### M

#### **Macronutriente**
Nutriente necessário em grandes quantidades: proteínas, carboidratos e lipídios.

#### **MkDocs**
Gerador de sites estáticos para documentação. Utilizado para criar a documentação do BSFM.

---

### N

#### **.NET**
Plataforma de desenvolvimento da Microsoft. O BSFM utiliza .NET 8.0.

---

### O

#### **ONNX** (Open Neural Network Exchange)
Formato aberto para representação de modelos de machine learning. Utilizado pelo YOLO no BSFM.

#### **ORM** (Object-Relational Mapper)
Técnica que mapeia objetos para tabelas de banco de dados. O Entity Framework Core é o ORM do BSFM.

---

### P

#### **PostgreSQL**
Sistema de banco de dados relacional open source. Utilizado como banco principal do BSFM em produção.

#### **PWA** (Progressive Web App)
Aplicação web que pode ser instalada como um aplicativo nativo. Planejado para versões futuras do BSFM.

---

### R

#### **Render**
Plataforma de cloud computing. Utilizada para hospedar o BSFM em produção.

---

### S

#### **SQLite**
Sistema de banco de dados relacional leve. Utilizado no BSFM para desenvolvimento local.

---

### T

#### **Tailwind CSS**
Framework CSS utilitário. Utilizado no frontend do BSFM.

#### **TDEE** (Total Daily Energy Expenditure)
Gasto energético total diário. Calculado no BSFM baseado na TMB e nível de atividade.

#### **TMB** (Taxa Metabólica Basal)
Quantidade de calorias que o corpo queima em repouso. Calculada no BSFM usando fórmulas de Mifflin-St Jeor.

---

### U

#### **USDA** (United States Department of Agriculture)
Departamento de Agricultura dos Estados Unidos. Sua API FoodData Central é utilizada pelo BSFM para consultar dados nutricionais.

---

### Y

#### **YOLO** (You Only Look Once)
Algoritmo de detecção de objetos em tempo real. Utilizado no BSFM para reconhecimento de alimentos em imagens.

---

## Como Usar Este Glossário

### Para Novatos
1. Comece pelos termos básicos: [BSFM](#bsfm), [IMC](#imc), [Caloria](#caloria)
2. Explore os [Casos de Uso](../caso-de-uso/) para contexto prático

### Para Desenvolvedores
1. Foque em: [API](#api), [.NET](#net), [Entity Framework](#entity-framework)
2. Consulte a [Referência Técnica](../bsfm/referencia.md)

---

**Última atualização:** Abril 2026  
**Mantido por:** Equipe BSFM - UNIP
