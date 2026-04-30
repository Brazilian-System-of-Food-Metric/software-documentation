---
title: "BSFM - Referência Técnica"
date: "2026"
layout: default
---

# Referência Técnica BSFM

Esta página contém informações técnicas de referência sobre o projeto BSFM.

## Stack Tecnológico

| Camada | Tecnologia | Versão |
|--------|-----------|--------|
| Backend | ASP.NET Core | 8.0 |
| ORM | Entity Framework Core | 8.0 |
| Banco (Produção) | PostgreSQL | 15+ |
| Banco (Dev) | SQLite | 3.x |
| IA | YoloDotNet + ONNX | - |
| Frontend | HTML/CSS/JS + Tailwind | 3.0 |
| Gráficos | Chart.js | 4.x |
| Mapas | Leaflet.js | 1.9 |
| Ícones | Font Awesome | 6.4.0 |
| Deploy | Render | - |
| Documentação | MkDocs + Material | - |

## Endpoints da API

### Autenticação
| Método | Rota | Descrição |
|--------|------|-----------|
| POST | `/solicitar-codigo` | Solicita código de verificação |
| POST | `/cadastrar-usuario-final` | Finaliza cadastro do usuário |
| POST | `/login` | Realiza login |
| POST | `/esqueci-senha` | Solicita redefinição de senha |
| POST | `/redefinir-senha` | Redefine a senha |

### Usuário
| Método | Rota | Descrição |
|--------|------|-----------|
| GET | `/perfil` | Obtém dados do perfil |
| PUT | `/perfil` | Atualiza dados do perfil |
| GET | `/dashboard` | Obtém dados do dashboard |
| GET | `/evolucao` | Obtém dados de evolução (peso/IMC) |

### Análise de Alimentos
| Método | Rota | Descrição |
|--------|------|-----------|
| POST | `/analisar-prato` | Analisa imagem de alimento |
| GET | `/historico-analises/{usuarioId}` | Histórico de análises |

### Refeições e Planos
| Método | Rota | Descrição |
|--------|------|-----------|
| GET | `/refeicoes` | Lista refeições do dia |
| POST | `/refeicoes` | Adiciona refeição |
| GET | `/plano-alimentar` | Obtém plano semanal |
| POST | `/plano-alimentar` | Salva plano semanal |

### Consumo de Água
| Método | Rota | Descrição |
|--------|------|-----------|
| GET | `/consumo-agua` | Obtém consumo de água |
| POST | `/consumo-agua` | Registra consumo de água |

### Hospitais
| Método | Rota | Descrição |
|--------|------|-----------|
| GET | `/hospitais` | Lista hospitais cadastrados |

### Health Check
| Método | Rota | Descrição |
|--------|------|-----------|
| GET | `/health` | Verifica status da aplicação |

## Variáveis de Ambiente

| Variável | Obrigatória | Descrição |
|----------|-------------|-----------|
| `DATABASE_URL` | Sim | Connection string do banco |
| `USDA_API_KEY` | Não | Chave da API USDA |
| `BREVO_API_KEY` | Não | Chave da API Brevo |
| `ASPNETCORE_ENVIRONMENT` | Não | Ambiente (Development/Production) |
| `PORT` | Não | Porta do servidor (Render) |

## Licença

Projeto acadêmico - UNIP - Análise e Desenvolvimento de Sistemas - 3º Semestre - 2026
