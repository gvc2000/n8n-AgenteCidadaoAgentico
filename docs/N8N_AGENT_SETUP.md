# Guia de Configuração dos Agentes no n8n

Este guia explica como **converter os nós LLM simples em AI Agents** com acesso às ferramentas MCP do servidor Câmara BR.

## 📋 Estado Atual

O workflow `workflow_multi_agentes.json` implementa a arquitetura multi-agentes descrita em `multi_agent_architecture.md`, mas **sem acesso aos dados reais** da Câmara.

Atualmente, cada agente (Legislativo, Político, Fiscal) é um nó `chainOpenAi` que apenas **simula** respostas baseadas no prompt do sistema.

## 🎯 Objetivo

Transformar cada agente em um **AI Agent** que pode:
1. Receber a pergunta do usuário
2. **Decidir quais ferramentas MCP chamar** (ex: `buscar_deputados`, `despesas_deputado`)
3. Executar as ferramentas no servidor MCP
4. Sintetizar os resultados em uma resposta

## 🔧 Passo a Passo

### 1. Configurar Credencial MCP no n8n

Antes de converter os nós, você precisa configurar a conexão com o servidor MCP:

1. No n8n, vá em **Credentials** > **Add Credential**
2. Busque por **"MCP"** ou **"Model Context Protocol"**
3. Configure:
   - **Transport Type**: `HTTP with SSE`
   - **Base URL**: `{{ $env.MCP_API_URL }}/mcp` (ou a URL do seu servidor MCP)
4. Salve a credencial

### 2. Configurar o Agente Legislativo

#### Antes (Placeholder):
O nó atual se chama `SETUP REQUIRED: Agente Legislativo` e é um simples **HTTP Request** que chama o endpoint de saúde do servidor. Isso evita erros de importação com nós obsoletos.

#### Depois (AI Agent):
1. **Deletar** o nó `SETUP REQUIRED: Agente Legislativo`
2. **Adicionar** um novo nó **AI Agent** (`@n8n/n8n-nodes-langchain.agent`)
3. **Configurar**:
   - **Model**: Conecte um nó de Chat Model (ex: `OpenAI Chat Model`)
   - **System Message**:
     ```
     Você é um consultor legislativo sênior. Analise o teor das leis, o impacto social e o status atual.
     
     Você tem acesso às ferramentas MCP para buscar dados reais da Câmara.
     ```
   - **Tools**: Conecte um nó **MCP Tool** e selecione:
     - `buscar_proposicoes`
     - `detalhar_proposicao`
     - `tramitacoes_proposicao`
     - `autores_proposicao`
4. **Conectar** o nó `Log: Leg Start` ao novo `AI Agent`
5. **Conectar** o `AI Agent` ao nó `Merge Results`

### 3. Configurar o Agente Político
Repita o processo acima para o nó `SETUP REQUIRED: Agente Politico`.

**System Message**:
```
Você é um analista político. Foque nas posições ideológicas, histórico de votação e alianças.
Você tem acesso às ferramentas MCP para buscar dados reais da Câmara.
```

**Ferramentas MCP**:
- `buscar_deputados`
- `detalhar_deputado`
- `discursos_deputado`
- `orgaos_deputado`
- `frentes_deputado`

### 4. Configurar o Agente Fiscal
Repita o processo para o nó `SETUP REQUIRED: Agente Fiscal`.

**System Message**:
```
Você é um auditor fiscal. Procure por anomalias, gastos excessivos ou padrões suspeitos.
Você tem acesso às ferramentas MCP para buscar dados reais da Câmara.
```

**Ferramentas MCP**:
- `despesas_deputado`
- `detalhar_deputado`

### 5. Ajustar o Sintetizador (Opcional)

O nó `Sintetizador (LLM)` pode permanecer como está, mas você pode melhorar o prompt:

```
Você é o Sintetizador. Consolide as informações recebidas dos agentes especialistas em uma resposta única, clara e direta para o cidadão.

IMPORTANTE:
- Elimine redundâncias entre os agentes
- Resolva contradições (se houver)
- Use um tom acessível e objetivo
- Cite fontes quando relevante (ex: "Segundo dados da Câmara...")
```

## 🧪 Teste

Após converter os agentes, teste o workflow:

```bash
curl -X POST https://seu-n8n.up.railway.app/webhook/chat \
  -H "Content-Type: application/json" \
  -d '{"query": "Quais foram os gastos do deputado Fulano em 2024?"}'
```

Você deve ver:
1. O **Orquestrador** decidir acionar o agente **Fiscal**
2. O **Agente Fiscal** chamar `buscar_deputados` e `despesas_deputado`
3. O **Sintetizador** consolidar a resposta

## 📊 Monitoramento

Verifique no Supabase:
- Tabela `requests`: Status da requisição
- Tabela `agent_logs`: Logs de cada agente em tempo real

## 🚨 Troubleshooting

### Erro: "Tool not found"
- Verifique se o servidor MCP está rodando
- Confirme que a URL em `MCP_API_URL` está correta
- Teste o endpoint: `curl https://seu-mcp-server.up.railway.app/health`

### Agente não usa as ferramentas
- Revise o **System Message** para ser mais explícito sobre quando usar cada ferramenta
- Adicione exemplos no prompt (few-shot learning)

### Timeout
- Algumas ferramentas da API da Câmara podem demorar
- Aumente o timeout do nó AI Agent se necessário

## 📚 Próximos Passos

1. **Adicionar mais ferramentas** conforme necessário
2. **Criar agentes especializados** (ex: Agente de Votações)
3. **Implementar cache** para perguntas repetidas
4. **Adicionar frontend** que consome o webhook e mostra os logs em tempo real

---

**Última Atualização**: 2025-11-24  
**Versão do Workflow**: 1.0.0
