# Guia Completo: n8n (Railway) + Supabase

Este guia descreve o passo a passo para configurar um ambiente de automação robusto utilizando **n8n** hospedado no **Railway** e integrado ao **Supabase** como banco de dados e backend.

---

## 1. Configuração do Supabase (Banco de Dados)

O Supabase servirá como a memória e o sistema de logs dos nossos agentes.

### 1.1. Criar Tabelas
1.  Acesse o [SQL Editor](https://supabase.com/dashboard/project/_/sql) do seu projeto Supabase.
2.  Execute o seguinte script para criar as tabelas necessárias:

```sql
-- Tabela de Requisições (Estado global da conversa)
CREATE TABLE IF NOT EXISTS requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    user_query TEXT NOT NULL,
    status TEXT DEFAULT 'pending', -- pending, orchestrating, processing, synthesizing, completed, error
    final_response TEXT,
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Tabela de Logs dos Agentes (Feedback em tempo real)
CREATE TABLE IF NOT EXISTS agent_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    request_id UUID REFERENCES requests(id) ON DELETE CASCADE,
    agent_name TEXT NOT NULL, -- ex: 'Orquestrador', 'Legislativo'
    message TEXT NOT NULL,
    status TEXT DEFAULT 'info', -- info, success, warning, error
    details JSONB DEFAULT '{}'::jsonb
);

-- Habilitar Realtime (Importante para o Frontend receber atualizações)
ALTER PUBLICATION supabase_realtime ADD TABLE requests;
ALTER PUBLICATION supabase_realtime ADD TABLE agent_logs;
```

### 1.2. Obter Credenciais
Vá em **Project Settings > API** e anote:
*   **Project URL** (`https://xyz.supabase.co`)
*   **anon public key**
*   **service_role key** (Use esta com cuidado no n8n para ter acesso total de escrita)

---

## 2. Deploy do n8n no Railway

O Railway é a plataforma onde nosso servidor n8n irá rodar. Para evitar problemas de permissão com volumes, usaremos um `Dockerfile` customizado que roda como root.

### 2.1. Criar Novo Projeto via GitHub
1.  Faça o push deste repositório para o seu GitHub.
2.  Acesse [railway.app](https://railway.app) e faça login.
3.  Clique em **New Project** > **Deploy from GitHub repo**.
4.  Selecione o seu repositório `AgenteCidadaoMCP`.
5.  **IMPORTANTE**: O Railway tentará fazer deploy da raiz. Precisamos configurar para usar a pasta `n8n`.
    *   Clique no card do serviço que foi criado.
    *   Vá em **Settings**.
    *   Em **Root Directory**, altere para `/n8n`.
    *   O Railway fará um novo build automaticamente usando o `Dockerfile` desta pasta.

### 2.2. Configurar Variáveis de Ambiente
1.  Clique no serviço `n8n` recém-criado.
2.  Vá na aba **Variables**.
3.  Adicione as seguintes variáveis (use o arquivo `railway.env.example` como referência):

| Variável | Valor Exemplo | Descrição |
| :--- | :--- | :--- |
| `N8N_BASIC_AUTH_ACTIVE` | `true` | Ativa autenticação básica |
| `N8N_BASIC_AUTH_USER` | `admin` | Seu usuário de login |
| `N8N_BASIC_AUTH_PASSWORD` | `senha_forte` | Sua senha de login |
| `WEBHOOK_URL` | `https://seu-app.up.railway.app` | **CRÍTICO**: URL pública do seu app (veja passo 2.3) |
| `N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS` | `true` | Segurança |
| `GENERIC_TIMEZONE` | `America/Sao_Paulo` | Fuso horário |

### 2.3. Gerar Domínio Público
1.  Vá na aba **Settings** do serviço.
2.  Em **Networking**, clique em **Generate Domain**.
3.  Copie o domínio gerado (ex: `web-production-1234.up.railway.app`).
4.  **Volte nas Variáveis** e atualize o valor de `WEBHOOK_URL` com `https://` + seu domínio.
5.  O Railway fará o redeploy automaticamente.

### 2.4. Configurar Persistência (Volume)
Para não perder seus workflows ao reiniciar o servidor:
1.  Vá na aba **Volumes**.
2.  Clique em **Add Volume**.
3.  Mount Path: `/home/node/.n8n`
4.  O Railway fará o redeploy.

---

## 3. Configuração Interna do n8n

Agora que o servidor está rodando, vamos configurá-lo.

1.  Acesse a URL do seu n8n (`https://seu-app.up.railway.app`).
2.  Faça login com o usuário e senha definidos nas variáveis.
3.  Complete o setup inicial (Owner account).

### 3.1. Criar Credenciais
No menu lateral esquerdo, vá em **Credentials** > **Add Credential**:

1.  **Supabase API**:
    *   **URL**: Sua URL do Supabase.
    *   **Service Key**: Sua `service_role` key (recomendado para backend) ou `anon` key.
2.  **OpenAI API** (ou Anthropic):
    *   Insira sua API Key.

### 3.2. Importar Workflow
1.  Baixe o arquivo `workflow_multi_agentes.json` deste diretório.
2.  No n8n, vá em **Workflows** > **Import from File**.
3.  Selecione o arquivo.
4.  **Ative** o workflow (Toggle "Active" no topo direito).

---

## 4. Teste e Validação

Para garantir que tudo está funcionando:

### 4.1. Teste via Curl
Abra seu terminal e envie uma requisição para o webhook de produção:

```bash
curl -X POST https://seu-app.up.railway.app/webhook/chat \
  -H "Content-Type: application/json" \
  -d '{"query": "Qual o gasto do deputado X com passagens?"}'
```

### 4.2. Verificação
1.  Verifique se o comando retornou um JSON de sucesso.
2.  Vá no **Supabase > Table Editor > requests**. Veja se uma nova linha foi criada.
3.  Vá em **agent_logs**. Veja se os logs dos agentes ("Orquestrador", etc.) estão aparecendo.

---

## Solução de Problemas Comuns

*   **Erro 502/503 no Railway**: O n8n pode demorar um pouco para iniciar. Verifique os logs na aba "Deployments" > "View Logs".
*   **Webhook URL mismatch**: Se o n8n reclamar da URL, verifique se a variável `WEBHOOK_URL` está exatamente igual ao domínio gerado, incluindo `https://`.
*   **Dados sumindo**: Verifique se o Volume foi montado corretamente em `/home/node/.n8n`.

---

## Integração MCP

Para detalhes sobre como integrar o n8n com o servidor MCP (Model Context Protocol), consulte o guia dedicado:

[Guia de Integração MCP](./MCP_INTEGRATION.md)

