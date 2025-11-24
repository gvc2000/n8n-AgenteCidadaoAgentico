FROM n8nio/n8n:latest

USER root

# Instalar dependências adicionais
RUN apk add --no-cache curl

# Resetar o entrypoint para evitar conflitos de usuário (o original tenta mudar para 'node')
ENTRYPOINT []

# Definir diretório de trabalho
WORKDIR /home/node

# Forçar o n8n a usar a pasta /home/node/.n8n para dados (mesmo sendo root)
ENV N8N_USER_FOLDER=/home/node

# Garantir que a pasta existe e tem permissões (caso o volume não monte corretamente)
RUN mkdir -p /home/node/.n8n && chmod 777 /home/node/.n8n

# Expor porta
EXPOSE 5678

# Comando de inicialização
CMD ["n8n", "start"]
