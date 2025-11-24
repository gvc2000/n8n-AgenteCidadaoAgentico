FROM n8nio/n8n:latest

USER root

# Instalar dependências adicionais se necessário
RUN apk add --no-cache curl

# Garantir permissões na pasta de dados
RUN mkdir -p /home/node/.n8n && \
    chown -R root:root /home/node/.n8n && \
    chmod -R 777 /home/node/.n8n

# Definir diretório de trabalho
WORKDIR /home/node

# Expor porta
EXPOSE 5678

# Comando de inicialização
CMD ["n8n", "start"]
