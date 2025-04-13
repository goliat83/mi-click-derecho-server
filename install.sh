#!/bin/bash
# Script de instalación automático para Ubuntu

# Actualizar e instalar Docker y Docker Compose
sudo apt update -y
sudo apt upgrade -y
sudo apt install -y docker.io docker-compose git certbot

# Clonar el repositorio del proyecto
git clone https://github.com/miclickderecho/mi-click-derecho-server.git
cd mi-click-derecho-server

# Obtener certificados SSL de Let's Encrypt (asegúrese de que los dominios apunten a esta máquina)
sudo certbot certonly --standalone --non-interactive --agree-tos -m "admin@miclickderecho.com" \
    -d web.miclickderecho.com -d api.miclickderecho.com -d n8n.miclickderecho.com -d ws.miclickderecho.com -d chats.miclickderecho.com

# Levantar los servicios Docker
sudo docker-compose up -d
