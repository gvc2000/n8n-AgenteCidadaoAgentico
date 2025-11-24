# Integração com n8n MCP Client

Este guia explica como conectar o servidor MCP Câmara BR ao n8n usando o MCP client do n8n.

## 📋 Pré-requisitos

- Servidor MCP Câmara BR deployado (Railway, local, ou outro host)
- n8n instalado e rodando (versão com suporte a MCP)
- URL pública ou acessível do servidor MCP

## 🔧 Configuração do Servidor

O servidor MCP Câmara BR agora implementa o protocolo MCP sobre HTTP com Server-Sent Events (SSE), que é compatível com o MCP client do n8n.

### Endpoints Disponíveis

- **POST /mcp** - Endpoint principal para mensagens JSON-RPC do MCP
- **GET /mcp** - Stream SSE para mensagens do servidor
- **DELETE /mcp** - Encerramento de sessão
- **GET /health** - Health check
- **GET /metrics** - Métricas Prometheus

## 🚀 Deploy no Railway

### 1. Fazer Deploy

Siga as instruções em [DEPLOY_RAILWAY.md](DEPLOY_RAILWAY.md) para fazer deploy no Railway.

Após o deploy, você terá uma URL como:
```
https://seu-projeto.up.railway.app
```

### 2. Verificar Servidor

Teste se o servidor está funcionando:

```bash
# Health check
curl https://seu-projeto.up.railway.app/health

# Informações do servidor
curl https://seu-projeto.up.railway.app/
```

## 🔗 Configuração no n8n

### Opção 1: Usando o MCP Client Node (Recomendado)

1. **Abra o n8n** (`http://localhost:5678` ou sua URL do n8n)

2. **Crie um novo workflow**

3. **Adicione o nó MCP Client**
   - Clique em "+" para adicionar um nó
   - Busque por "MCP" ou "Model Context Protocol"
   - Selecione o nó **MCP Client**

4. **Configure a conexão MCP**

   Nas configurações do nó MCP Client:

   ```
   Transport Type: HTTP with SSE
   Base URL: https://seu-projeto.up.railway.app/mcp
   ```

   Ou para teste local:

   ```
   Transport Type: HTTP with SSE
   Base URL: http://localhost:9090/mcp
   ```

5. **Testar a Conexão**

   O nó MCP Client deve se conectar automaticamente e listar as ferramentas disponíveis.

### Opção 2: Configuração Manual via HTTP Request

Se o nó MCP Client não estiver disponível, você pode usar o nó HTTP Request:

#### 1. Inicializar Sessão MCP

```
Method: POST
URL: https://seu-projeto.up.railway.app/mcp
Headers:
  Content-Type: application/json
  Accept: application/json, text/event-stream
Body:
  {
    "jsonrpc": "2.0",
    "id": 1,
    "method": "initialize",
    "params": {
      "protocolVersion": "2024-11-05",
      "capabilities": {},
      "clientInfo": {
        "name": "n8n",
        "version": "1.0.0"
      }
    }
  }
```

**Resposta:** O servidor retornará um stream SSE com o `Mcp-Session-Id` no header.

#### 2. Listar Ferramentas

```
Method: POST
URL: https://seu-projeto.up.railway.app/mcp
Headers:
  Content-Type: application/json
  Accept: application/json, text/event-stream
  Mcp-Session-Id: <session-id-from-initialize>
Body:
  {
    "jsonrpc": "2.0",
    "id": 2,
    "method": "tools/list"
  }
```

#### 3. Chamar uma Ferramenta

```
Method: POST
URL: https://seu-projeto.up.railway.app/mcp
Headers:
  Content-Type: application/json
  Accept: application/json, text/event-stream
  Mcp-Session-Id: <session-id>
Body:
  {
    "jsonrpc": "2.0",
    "id": 3,
    "method": "tools/call",
    "params": {
      "name": "buscar_deputados",
      "arguments": {
        "uf": "SP",
        "pagina": 1,
        "itens": 10
      }
    }
  }
```

## 🛠️ Ferramentas Disponíveis

O servidor expõe 55 ferramentas MCP organizadas por categoria:

### Deputados
- `buscar_deputados` - Buscar deputados
- `detalhar_deputado` - Detalhes de um deputado
- `despesas_deputado` - Despesas (cota parlamentar)
- `discursos_deputado` - Discursos
- `eventos_deputado` - Eventos
- E mais...

### Proposições
- `buscar_proposicoes` - Buscar proposições
- `detalhar_proposicao` - Detalhes de uma proposição
- `autores_proposicao` - Autores
- `tramitacoes_proposicao` - Histórico de tramitação
- E mais...

### Votações
- `buscar_votacoes` - Buscar votações
- `detalhar_votacao` - Detalhes de uma votação
- `votos_votacao` - Votos individuais
- `orientacoes_votacao` - Orientações de bancada
- E mais...

### Análises
- `analise_presenca_deputado` - Análise de presença
- `ranking_proposicoes_autor` - Ranking de autores
- `analise_despesas_partido` - Análise de despesas por partido
- `comparativo_votacoes_bancadas` - Comparativo de votações
- `timeline_tramitacao` - Linha do tempo de tramitação
- `exportar_dados` - Exportar dados em diferentes formatos

Para lista completa, acesse: `GET https://seu-projeto.up.railway.app/`

## 📝 Exemplos de Workflows n8n

### Exemplo 1: Buscar Deputados de SP e Enviar Email

```
1. Schedule Trigger (diariamente às 9h)
   ↓
2. MCP Client
   Tool: buscar_deputados
   Arguments: { "uf": "SP", "itens": 50 }
   ↓
3. Function (processar dados)
   ↓
4. Send Email (enviar relatório)
```

### Exemplo 2: Monitorar Votações Importantes

```
1. Webhook Trigger (webhook externo)
   ↓
2. MCP Client
   Tool: buscar_votacoes
   Arguments: {
     "dataInicio": "2025-01-01",
     "dataFim": "2025-12-31",
     "itens": 100
   }
   ↓
3. Filter (votações importantes)
   ↓
4. MCP Client (loop)
   Tool: votos_votacao
   Arguments: { "id": "{{$json.id}}" }
   ↓
5. Slack/Discord (notificar)
```

### Exemplo 3: Análise de Presença de Deputado

```
1. Manual Trigger (ou Schedule)
   ↓
2. Set Variables
   deputadoId: 204554 (exemplo)
   ↓
3. MCP Client
   Tool: analise_presenca_deputado
   Arguments: {
     "id": "{{$node["Set"].json.deputadoId}}",
     "dataInicio": "2025-01-01",
     "dataFim": "2025-12-31"
   }
   ↓
4. MCP Client
   Tool: exportar_dados
   Arguments: {
     "formato": "csv",
     "dados": "{{$json}}"
   }
   ↓
5. Google Sheets (salvar dados)
```

## 🔍 Debugging

### Verificar Logs do Servidor

**No Railway:**
1. Acesse seu projeto no Railway
2. Clique em "Deployments"
3. Selecione o deployment ativo
4. Clique em "View Logs"

**Localmente:**
```bash
npm run start:sse
```

Os logs mostrarão:
- Conexões de clientes
- Inicializações de sessão
- Chamadas de ferramentas
- Erros e warnings

### Health Check

```bash
curl https://seu-projeto.up.railway.app/health
```

Deve retornar:
```json
{
  "status": "healthy",
  "timestamp": "2025-11-16T21:00:00.000Z",
  "uptime": 123.45,
  "memory": {...},
  "activeSessions": 2,
  "toolsAvailable": 55
}
```

### Testar Endpoint MCP Diretamente

```bash
# Inicializar sessão
curl -X POST https://seu-projeto.up.railway.app/mcp \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "initialize",
    "params": {
      "protocolVersion": "2024-11-05",
      "capabilities": {},
      "clientInfo": {"name": "test", "version": "1.0.0"}
    }
  }'
```

## 🚨 Troubleshooting

### Erro: "Invalid or missing session ID"

**Causa:** O cliente não está enviando o header `Mcp-Session-Id` ou a sessão expirou.

**Solução:**
1. Certifique-se de que o nó MCP Client está configurado corretamente
2. Verifique se a sessão foi inicializada com o método `initialize`
3. Confirme que o header `Mcp-Session-Id` está sendo enviado nas requisições subsequentes

### Erro: "Not Acceptable: Client must accept both application/json and text/event-stream"

**Causa:** O header `Accept` não está correto.

**Solução:**
Adicione o header:
```
Accept: application/json, text/event-stream
```

### Erro: "Tool not found"

**Causa:** O nome da ferramenta está incorreto.

**Solução:**
1. Liste as ferramentas disponíveis:
   ```bash
   curl https://seu-projeto.up.railway.app/
   ```
2. Use o nome exato da ferramenta (case-sensitive)
3. Exemplo: `buscar_deputados` (não `buscarDeputados` ou `BuscarDeputados`)

### Timeout ou Sem Resposta

**Causa:** Servidor não está acessível ou está sobrecarregado.

**Solução:**
1. Verifique se o servidor está rodando: `curl https://seu-projeto.up.railway.app/health`
2. Verifique os logs no Railway
3. Confirme que a porta 9090 está exposta e acessível
4. Verifique firewalls e configurações de rede

### CORS Errors (em testes de browser)

**Causa:** CORS está habilitado para todos os origins, mas pode haver problemas de configuração.

**Solução:**
O servidor já está configurado com CORS permissivo:
```typescript
app.use(cors({
  origin: '*',
  exposedHeaders: ['Mcp-Session-Id']
}));
```

Se ainda houver problemas, verifique se o n8n está enviando os headers corretos.

## 📊 Métricas e Monitoramento

### Endpoint de Métricas

```bash
# Prometheus format
curl https://seu-projeto.up.railway.app/metrics

# JSON format
curl https://seu-projeto.up.railway.app/metrics/json
```

### Métricas Disponíveis

- **Chamadas de ferramentas:** Contador por ferramenta
- **Latência:** Tempo de execução por ferramenta
- **Erros:** Contador de erros por ferramenta
- **Sessões ativas:** Número de sessões MCP ativas
- **Cache hit ratio:** Taxa de acerto do cache

## 🔐 Segurança (Opcional)

### Adicionar Autenticação Bearer Token

Para ambientes de produção, você pode adicionar autenticação. No Railway, configure:

```
AUTH_TOKEN=seu-token-secreto-aqui
```

Em seguida, atualize o código do servidor para verificar o header `Authorization`.

No n8n, adicione o header nas requisições:
```
Authorization: Bearer seu-token-secreto-aqui
```

## 📚 Recursos Adicionais

- **Documentação MCP:** https://modelcontextprotocol.io
- **Documentação n8n:** https://docs.n8n.io
- **Documentação Railway:** https://docs.railway.app
- **API Câmara:** https://dadosabertos.camara.leg.br/swagger/api.html

## 💡 Dicas

1. **Use cache:** O servidor tem cache multinível. Requisições repetidas são muito mais rápidas.
2. **Paginação:** Use os parâmetros `pagina` e `itens` para controlar o tamanho das respostas.
3. **Filtros:** A maioria das ferramentas aceita múltiplos filtros para refinar os resultados.
4. **Análises:** Use as ferramentas de análise (`analise_*`) para insights agregados.
5. **Exportação:** Use `exportar_dados` para converter resultados em CSV ou Markdown.

## 🆘 Suporte

- **Issues:** https://github.com/gvc2000/AgenteCidadaoMCP/issues
- **Documentação do Projeto:** Ver arquivos .md na raiz do repositório

---

**Última Atualização:** 2025-11-16
**Versão do Servidor:** 1.0.0
