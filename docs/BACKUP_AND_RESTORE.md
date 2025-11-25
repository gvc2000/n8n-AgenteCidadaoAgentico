# Guia de Backup e Segurança para n8n no Railway

Este guia detalha como salvar seus fluxos de trabalho (workflows) de forma segura e como fazer backup do ambiente n8n rodando no Railway.

## 1. Salvando o Fluxo de Trabalho (Imediato)

A forma mais rápida de garantir que você não perca seu trabalho atual é exportar o fluxo para um arquivo JSON.

1.  No editor do n8n, clique no menu de três pontos (`...`) no canto superior direito do canvas.
2.  Selecione **Export**.
3.  Escolha **Download** (ou "Download to file").
4.  Salve o arquivo `.json` em seu computador (ex: `meu_fluxo_backup_v1.json`).
5.  **Recomendação**: Faça commit deste arquivo no seu repositório Git para ter um histórico de versões.

## 2. Backup Manual com Git (Passo a Passo)

Como você não tem a integração nativa, faremos o processo manual. Este é o método mais robusto e gratuito.

### Passo 1: Preparar o Repositório Local
Você já está na pasta do projeto (`n8n-AgenteCidadaoAgentico`). Vamos criar uma pasta organizada para os backups.

1.  Crie uma pasta chamada `workflows` (se não existir):
    ```bash
    mkdir workflows
    ```

### Passo 2: Exportar e Salvar
1.  No n8n (Railway), exporte seu fluxo como JSON (como explicado no item 1).
2.  Mova o arquivo baixado para a pasta `workflows` que você criou.
3.  **Dica de Ouro**: Dê um nome consistente. Ex: `main_workflow.json`. Se você sempre salvar com o **mesmo nome**, o Git conseguirá mostrar exatamente o que mudou (o "diff") entre as versões.

### Passo 3: Comitar as Mudanças
No seu terminal (dentro da pasta do projeto), execute:

```bash
# 1. Verifique o que mudou
git status

# 2. Adicione o arquivo
git add workflows/main_workflow.json

# 3. Faça o commit com uma mensagem descritiva
git commit -m "Backup: Atualização do fluxo com novos agentes"

# 4. Envie para o GitHub (ou seu remoto)
git push origin main
```

### Dica: Automação via n8n (Opcional)
Você pode criar um **segundo workflow** no n8n que roda todo dia, pega todos os seus workflows via API do n8n e faz um commit no GitHub.
*   Isso exige usar o nó "Git" ou "GitHub" dentro do n8n.
*   Mas o método manual acima é o mais seguro para começar.

## 3. Backup do Ambiente (Railway)

Seu ambiente n8n no Railway é composto por três partes críticas que precisam de backup:

### A. Variáveis de Ambiente (CRÍTICO)
As variáveis definem a configuração e, mais importante, a **Chave de Encriptação**.

*   **O que salvar**: Todo o conteúdo da aba "Variables" no seu serviço n8n no Railway.
*   **Item Vital**: `N8N_ENCRYPTION_KEY`.
    *   ⚠️ **AVISO**: Se você perder esta chave, **NÃO** conseguirá recuperar nenhuma credencial (senhas, chaves de API) salvas no banco de dados, mesmo que tenha o backup do banco.
*   **Como fazer backup**: Copie todas as variáveis e salve em um arquivo seguro (como um gerenciador de senhas ou um arquivo `.env` local criptografado).

### B. Banco de Dados (SQLite)
Pela sua configuração (`railway.env`), você está usando SQLite. O banco de dados é um arquivo (`database.sqlite`) salvo no disco.

*   **Onde fica**: Normalmente em `/home/node/.n8n/database.sqlite`.
*   **Persistência**: No Railway, este arquivo deve estar em um **Volume**. Se você não configurou um volume, os dados serão perdidos a cada deploy/restart.
*   **Como verificar**:
    1.  No Railway, vá no serviço do n8n.
    2.  Vá na aba **Volumes**.
    3.  Verifique se existe um volume montado em `/home/node/.n8n`.
*   **Como fazer backup**:
    *   O Railway faz snapshots automáticos de volumes em alguns planos, mas não confie apenas nisso.
    *   **Método Manual**: Você pode usar o Railway CLI ou um fluxo do próprio n8n para enviar o arquivo `database.sqlite` para um armazenamento externo (ex: S3, Google Drive) periodicamente.

### C. Credenciais
As credenciais ficam salvas no banco de dados (encriptadas).
*   Se você tem o backup do `database.sqlite` **E** a `N8N_ENCRYPTION_KEY`, suas credenciais estão seguras.
*   Se preferir, você pode re-inserir as credenciais manualmente se tiver que subir um novo ambiente, desde que tenha os fluxos (JSON).

## Resumo do Plano de Segurança

1.  **Agora mesmo**: Exporte o JSON do seu fluxo e salve no seu PC.
2.  **Verifique a Chave**: Guarde a `N8N_ENCRYPTION_KEY` em um local seguro (1Password, Bitwarden, etc.).
3.  **Verifique o Volume**: Confirme no Railway se o diretório `/home/node/.n8n` está montado em um Volume persistente.
4.  **Rotina**: Sempre que terminar uma alteração grande, exporte o JSON e faça commit no seu repositório Git.
