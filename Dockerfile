FROM n8nio/n8n:latest

USER root

# Instalar dependências adicionais
RUN apk add --no-cache curl

# Resetar o entrypoint para evitar conflitos de usuário (o original tenta mudar para 'node')
ENTRYPOINT []

# Definir diretório de trabalho
WORKDIR /home/node

# Expor porta
EXPOSE 5678

# Comando de inicialização
CMD ["n8n", "start"]
