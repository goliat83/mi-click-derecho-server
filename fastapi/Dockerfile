# Imagen base de Python 3.11 slim
FROM python:3.11-slim
WORKDIR /app
# Copiamos el código de la aplicación FastAPI
COPY . .
# Instalamos FastAPI y Uvicorn
RUN pip install --no-cache-dir fastapi uvicorn[standard]
# Exponemos el puerto de FastAPI
EXPOSE 8000
# Comando por defecto para lanzar la aplicación
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
