
---

### Nome escolhido para a ONG: **BSFM | Brazilian System of Food Metric**

---

### 1. Requisitos do Sistema

#### **Requisitos Funcionais (RF)**
*O que o sistema deve fazer.*

| ID | Requisito | Descrição |
| :--- | :--- | :--- |
| **RF01** | Cadastro de Perfil Biométrico | O sistema deve permitir que o usuário cadastre Peso, Altura, Idade, Alergias e Nível de Atividade Física. |
| **RF02** | Cálculo de TMB e Macronutrientes | O sistema deve calcular automaticamente a Taxa Metabólica Basal e sugerir a divisão de macros (Carbos/Proteínas/Gorduras). |
| **RF03** | Reconhecimento de Prato (IA) | Através de uma foto, o sistema deve identificar os alimentos e estimar as quantidades nutricionais (Visão Computacional). |
| **RF04** | Análise de Validade/Frescor | O sistema deve analisar via câmera se frutas/alimentos apresentam padrões de deterioração ou oxidação. |
| **RF05** | Localizador de Emergência Médica | Em caso de sintomas de intoxicação, o sistema deve exibir no mapa as UPAs ou Hospitais mais próximos via Geolocalização. |
| **RF06** | Diário Alimentar e Cronograma | Permitir o registro diário de refeições e gerar planos baseados em diretrizes nutricionais seguras. |
| **RF07** | Acompanhamento de Metas | Gerar gráficos de evolução (perda de peso, ganho de massa, ingestão hídrica) ao longo do tempo. |
| **RF08** | Módulo de LIBRAS | Disponibilizar vídeos/tutoriais em LIBRAS sobre conceitos básicos de alimentação saudável para acessibilidade. |

#### **Requisitos Não Funcionais (RNF)**
*Como o sistema deve ser (qualidades).*

| ID | Requisito | Categoria | Descrição |
| :--- | :--- | :--- | :--- |
| **RNF01** | Responsividade | Usabilidade | A interface deve se adaptar a Desktops, Tablets e Smartphones (Layout "Mobile First"). |
| **RNF02** | Tempo de Resposta da IA | Performance | O processamento da imagem do prato não deve exceder 5 segundos. |
| **RNF03** | Segurança de Dados (LGPD) | Segurança | Dados sensíveis (alergias/saúde) devem ser criptografados conforme a Lei Geral de Proteção de Dados. |
| **RNF04** | Acessibilidade Digital | Acessibilidade | O site deve seguir as diretrizes da WCAG, incluindo suporte para leitores de tela e comandos simples. |
| **RNF05** | Disponibilidade | Confiabilidade | O sistema deve estar disponível 99% do tempo. |

---

### 2. Identificação de Envolvidos (Stakeholders)

*   **Usuários Finais:** Pessoas que buscam melhorar a saúde ou têm restrições alimentares.
*   **Gestores da ONG (Time da Faculdade):** Equipe, responsáveis pelas decisões de negócio e financeiro.
*   **Equipe de Desenvolvimento:** Equipe (Back-end C# / LIBRAS) e demais membros (Front-end / IA).
*   **Profissionais de Saúde (Parceiros):** Nutricionistas e Médicos que validam os cálculos e fontes das dietas.
*   **Desenvolvedores das APIs:** Provedores externos (Google Maps API, Bancos de Dados de Alimentos).
*   **Pessoas Surdas e com Deficiência Auditiva:** O público específico que se beneficiará da integração de LIBRAS.

---

### 3. Definição de Termos e Critérios de Aceite

Nesta seção, definimos as "regras do jogo". De um lado, o **Glossário** para nivelar o conhecimento; de outro, os **Critérios de Aceite de Contrato** (o que o usuário concorda) e os **Critérios de Aceite Técnicos** (o que o sistema deve garantir).

#### **3.1 Glossário (Definição de Termos)**
*   **TMB (Taxa Metabólica Basal):** Valor calórico mínimo para funções vitais em repouso.
*   **Visão Computacional:** Algoritmo que interpreta pixels de fotos para identificar alimentos e estados de conservação.
*   **LGPD (Lei Geral de Proteção de Dados):** Lei brasileira que regula o tratamento de dados pessoais no seu site.
*   **Fórmula de Harris-Benedict:** Método matemático usado pelo sistema para estimar as calorias necessárias.

#### **3.2 Termos de Contrato (Consentimento do Usuário)**
*Para que o cadastro seja finalizado, o usuário deve dar o "check" nestes termos:*

1.  **Termo de Isenção de Responsabilidade Médica:** O usuário aceita que o site é uma **ferramenta de apoio** e não substitui uma consulta presencial com um Nutricionista ou Médico. Em casos de patologias graves, a orientação profissional é soberana.
2.  **Política de Privacidade (LGPD):** O usuário autoriza o armazenamento de seus dados biométricos (Peso, Altura, Alergias) exclusivamente para a personalização das métricas de saúde, garantindo que esses dados não serão vendidos a terceiros.
3.  **Termo de Uso da Visão Computacional:** O usuário está ciente de que as análises de validade e calorias por foto são **estimativas** baseadas em inteligência artificial e podem sofrer variações dependendo da iluminação e qualidade da imagem.
4.  **Consentimento de Geolocalização:** O usuário permite o acesso à localização apenas em casos de acionamento do botão de **Emergência de Intoxicação**, para fins de rota para hospitais próximos.

#### **3.3 Critérios de Aceite Técnicos (Funcionalidade de Cadastro)**
*Para considerar a "Criação de Conta" como **Concluída (Done)** pelo time de desenvolvimento, ela deve cumprir:*

*   **Validação de Biometria:** O sistema não deve permitir o cadastro de idades negativas ou alturas/pesos zerados (Feedback de erro imediato).
*   **Segurança de Senha:** O cadastro só será concluído se a senha tiver no mínimo 8 caracteres, incluindo uma letra maiúscula e um caractere especial.
*   **Fluxo de Boas-Vindas:** Após o aceite dos termos, o sistema deve direcionar o usuário para a tela de "Primeira Meta", confirmando que os dados foram salvos com sucesso no Banco de Dados.
*   **Acessibilidade no Cadastro:** O formulário deve possuir rótulos (Labels) claros para leitores de tela e um ícone de auxílio visual (vídeo em LIBRAS explicativo) para os termos de uso.

---

### C# (Back-end)

1.  **Classe `Usuario`:** Com os atributos do cadastro (Peso, Altura, etc).
2.  **Classe `CalculadoraNutricional`:** Com métodos para TMB.
3.  **Classe `Alimento`:** Como classe pai, e talvez especializações para `AlimentoProcessado` ou `InNatura`.
