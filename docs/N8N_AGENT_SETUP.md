# Guia de Configuração dos Agentes no n8n

Este guia explica como **converter os nós placeholders em AI Agents** funcionais.

## 📋 Visão Geral

O workflow importado contém 5 nós marcados como `SETUP REQUIRED`. Eles são placeholders (HTTP Requests) que precisam ser substituídos por nós **AI Agent** reais.

**Você deve configurar os nós na seguinte ordem:**
1.  Orquestrador
2.  Agente Legislativo
3.  Agente Político
4.  Agente Fiscal
5.  Sintetizador

---

## 1. Configurar o Orquestrador

O Orquestrador decide qual especialista chamar.

1.  **Deletar** o nó `SETUP REQUIRED: Orquestrador`.
2.  **Adicionar** um novo nó **AI Agent** (`@n8n/n8n-nodes-langchain.agent`).
3.  **Configurar**:
    *   **Model**: Conecte um nó de Chat Model (ex: `OpenAI Chat Model` com `gpt-4o`).
    *   **System Message**:
        ```text
        Você é o Orquestrador do Agente Cidadão. Sua função é analisar a pergunta do usuário e decidir quais agentes especialistas devem ser acionados.

        Agentes disponíveis:
        - legislativo: Para leis, projetos de lei, tramitações.
        - politico: Para perfil de políticos, discursos, ideologia.
        - fiscal: Para gastos, cotas parlamentares, orçamento.

        Responda APENAS um JSON no formato:
        {
          "agentes": ["legislativo", "fiscal"] 
        }
        ```
    *   **Tools**: Não é necessário conectar ferramentas neste nó.
4.  **Conectar** o nó `Supabase: Init Request` ao novo `AI Agent`.
5.  **Conectar** o `AI Agent` ao nó `Router`.

---

## 2. Configurar o Agente Legislativo

Especialista em leis e tramitações.

1.  **Deletar** o nó `SETUP REQUIRED: Agente Legislativo`.
2.  **Adicionar** um novo nó **AI Agent**.
3.  **Configurar**:
    *   **Model**: Conecte o Chat Model.
    *   **System Message**:
        ```text
        Você é um consultor legislativo sênior. Analise o teor das leis, o impacto social e o status atual.
        
        Você tem acesso às ferramentas MCP para buscar dados reais da Câmara.
        ```
    *   **Tools**:
        1.  Conecte um nó **MCP Tool**.
        2.  Configure a conexão no próprio nó:
            *   **Transport Type**: `HTTP with SSE`
            *   **Base URL**: `{{ $env.MCP_API_URL }}/mcp`
        3.  Selecione as ferramentas:
            *   `buscar_proposicoes`
            *   `detalhar_proposicao`
            *   `tramitacoes_proposicao`
            *   `autores_proposicao`
4.  **Conectar** o nó `Log: Leg Start` ao novo `AI Agent`.
5.  **Conectar** o `AI Agent` ao nó `Merge Results`.

---

## 3. Configurar o Agente Político

Especialista em perfil parlamentar.

1.  **Deletar** o nó `SETUP REQUIRED: Agente Politico`.
2.  **Adicionar** um novo nó **AI Agent**.
3.  **Configurar**:
    *   **Model**: Conecte o Chat Model.
    *   **System Message**:
        ```text
        Você é um analista político. Foque nas posições ideológicas, histórico de votação e alianças.
        Você tem acesso às ferramentas MCP para buscar dados reais da Câmara.
        ```
    *   **Tools**: Conecte o nó **MCP Tool** e selecione:
        *   `buscar_deputados`
        *   `detalhar_deputado`
        *   `discursos_deputado`
        *   `orgaos_deputado`
        *   `frentes_deputado`
4.  **Conectar** o nó `Log: Pol Start` ao novo `AI Agent`.
5.  **Conectar** o `AI Agent` ao nó `Merge Results`.

---

## 4. Configurar o Agente Fiscal

Especialista em gastos e orçamento.

1.  **Deletar** o nó `SETUP REQUIRED: Agente Fiscal`.
2.  **Adicionar** um novo nó **AI Agent**.
3.  **Configurar**:
    *   **Model**: Conecte o Chat Model.
    *   **System Message**:
        ```text
        Você é um auditor fiscal. Procure por anomalias, gastos excessivos ou padrões suspeitos.
        Você tem acesso às ferramentas MCP para buscar dados reais da Câmara.
        ```
    *   **Tools**: Conecte o nó **MCP Tool** e selecione:
        *   `despesas_deputado`
        *   `detalhar_deputado`
4.  **Conectar** o nó `Log: Fis Start` ao novo `AI Agent`.
5.  **Conectar** o `AI Agent` ao nó `Merge Results`.

---

## 5. Configurar o Sintetizador

Consolida as respostas para o usuário final.

1.  **Deletar** o nó `SETUP REQUIRED: Sintetizador`.
2.  **Adicionar** um novo nó **AI Agent**.
3.  **Configurar**:
    *   **Model**: Conecte o Chat Model.
    *   **System Message**:
        ```text
        Você é o Sintetizador. Consolide as informações recebidas dos agentes especialistas em uma resposta única, clara e direta para o cidadão.

        IMPORTANTE:
        - Elimine redundâncias entre os agentes
        - Resolva contradições (se houver)
        - Use um tom acessível e objetivo
        - Cite fontes quando relevante (ex: "Segundo dados da Câmara...")
        ```
    *   **Tools**: Não é necessário conectar ferramentas neste nó.
4.  **Conectar** o nó `Merge Results` ao novo `AI Agent`.
5.  **Conectar** o `AI Agent` ao nó `Supabase: Final Update`.

---

## 🧪 Como Testar

Após configurar todos os agentes:

1.  Ative o workflow.
2.  Faça uma requisição POST para o webhook:
    ```bash
    curl -X POST https://seu-n8n.up.railway.app/webhook/chat \
      -H "Content-Type: application/json" \
      -d '{"query": "Quais os gastos do deputado Fulano?"}'
    ```
3.  Acompanhe a execução no n8n para ver os agentes sendo acionados.
