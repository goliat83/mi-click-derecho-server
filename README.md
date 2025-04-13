# Infraestructura Dockerizada para Servidor Ubuntu (AWS us-east-1)

Este proyecto configura una infraestructura completa utilizando Docker y Docker Compose para un servidor Ubuntu en AWS (región us-east-1). Incluye múltiples contenedores (backend, frontend, bases de datos y servicios adicionales) con un proxy inverso Nginx que proporciona HTTPS a través de certificados Let's Encrypt.

#Contenedores y Subdominios
Los siguientes servicios se despliegan en contenedores separados, cada uno accesible mediante un subdominio específico:

- Frontend Web (PHP 8.2 con Apache) – Subdominio: web.miclickderecho.com – Contenedor PHP sirviendo una página de ejemplo (phpinfo()).
- API Backend (FastAPI en Python 3.11) – Subdominio: api.miclickderecho.com – Contenedor Python con FastAPI (ejemplo "Hello World").
- Aplicación Node.js (v20) – Subdominio: node.miclickderecho.com (nota: opcional, aquí se expone en web subruta o ajustar configuración) – Contenedor Node.js con servidor HTTP básico.
- Base de Datos MySQL 8.0 – No expuesta públicamente (solo accesible internamente).
- Base de Datos PostgreSQL 15 – No expuesta públicamente (solo accesible internamente).
- n8n (Automatización de flujos) – Subdominio: n8n.miclickderecho.com – Contenedor oficial de n8n para orquestación.
-Evolution API (WhatsApp API) – Subdominio: ws.miclickderecho.com – Contenedor oficial de Evolution API (integración con WhatsApp).
- OpenWebUI (Frontend tipo ChatGPT) – Subdominio: chats.miclickderecho.com – Contenedor OpenWebUI (interfaz de chat IA auto-hosteada).

Todos los contenedores están orquestados mediante Docker Compose y se configuran para iniciarse automáticamente. 
Nginx actúa como proxy inverso dirigiendo cada subdominio al contenedor correspondiente y gestionando certificados SSL válidos de Let's Encrypt para ofrecer tráfico HTTPS seguro.

mi-click-derecho-server/
├── docker-compose.yml    # Definición de servicios Docker y redes
├── .env                  # Variables de entorno (credenciales y config)
├── nginx/
│   └── default.conf      # Configuración de Nginx (proxy inverso + SSL)
├── fastapi/
│   ├── Dockerfile        # Dockerfile para imagen de FastAPI (Python 3.11)
│   └── main.py           # Aplicación FastAPI de ejemplo ("Hello World")
├── php-apache/
│   └── index.php         # Archivo PHP de ejemplo (phpinfo)
├── node/
│   └── app.js            # Aplicación Node.js de ejemplo ("Hola desde Node.js")
├── mysql/
│   └── init.sql          # Script SQL de inicialización para MySQL
├── postgres/
│   └── init.sql          # Script SQL de inicialización para PostgreSQL
├── install.sh            # Script de instalación automatizada en Ubuntu
└── README.md             # Documentación y pasos de uso

![image](https://github.com/user-attachments/assets/0baa8722-a147-447e-a207-79fa82119625)

Descripción de Componentes
A continuación se detalla el rol de cada componente y cualquier configuración particular:

- Docker Compose (docker-compose.yml): Define todos los servicios. Utiliza las imágenes oficiales de Docker (PHP/Apache, Node, MySQL, PostgreSQL, Nginx, etc.) para garantizar compatibilidad. Los puertos estándar se exponen internamente a Nginx (vía la red de Docker) y solo Nginx expone los puertos 80 y 443 al exterior. Se configuran volúmenes persistentes para MySQL, PostgreSQL, n8n y Evolution API, preservando datos (bases de datos, configuraciones) incluso si los contenedores se recrean. Las variables sensibles (contraseñas, claves) se toman del archivo .env (cargado con env_file en cada servicio). Por ejemplo, MySQL y PostgreSQL utilizan credenciales definidas en .env.

- Archivo de Entorno (.env): Contiene variables como contraseñas de root para MySQL (MYSQL_ROOT_PASSWORD), nombre de base de datos y usuario, credenciales de PostgreSQL (POSTGRES_USER, etc.), y la clave de API para Evolution API (EVOLUTION_API_KEY). Nota: Es importante cambiar estas credenciales en un entorno de producción real. Este archivo es referenciado automáticamente por Docker Compose​
docs.docker.com, evitando hardcodear secretos en el docker-compose.yml.

- Nginx (nginx/default.conf): Configura bloques de servidor para cada subdominio:
-- Escucha en puerto 80 todas las peticiones de los subdominios listados y las redirige a HTTPS, además de servir los desafíos de Let's Encrypt en /.well-known/acme-challenge/ durante la obtención/renovación de certificados.
-- Para cada subdominio en puerto 443, activa SSL con los certificados ubicados en /etc/letsencrypt/live/<subdominio>/ (que serán generados por Certbot). Incluye directivas de seguridad recomendadas (SSL opciones seguras, ssl_dhparam, etc., generalmente provistas por -- Certbot). Cada bloque proxy_pass apunta al contenedor Docker correspondiente (referenciado por nombre de servicio de Compose) en su puerto interno:
  
--- web.miclickderecho.com → proxy_pass al contenedor php-apache (puerto 80 interno).
--- api.miclickderecho.com → proxy_pass al contenedor fastapi (puerto 8000).
--- n8n.miclickderecho.com → proxy_pass al contenedor n8n (puerto 5678).
--- ws.miclickderecho.com → proxy_pass al contenedor evolution-api (puerto 8080).
--- chats.miclickderecho.com → proxy_pass al contenedor openwebui (puerto 8080).

De esta forma, Nginx es el único punto de entrada expuesto (maneja la terminación SSL y el enrutamiento interno), mientras que los servicios internos pueden permanecer aislados.

- FastAPI (fastapi/): Contiene una sencilla aplicación FastAPI (main.py) que expone la ruta raíz / retornando un JSON de saludo. El Dockerfile correspondiente crea una imagen basada en Python 3.11 slim, instala FastAPI y Uvicorn, y define el comando de ejecución --- usando Uvicorn para servir la aplicación en 0.0.0.0:8000. Este contenedor se inicia automáticamente al levantar la infraestructura, y Nginx lo enruta desde el subdominio api.*.

- Aplicación Node.js (node/): Consiste en un script app.js que levanta un servidor HTTP básico en el puerto 3000 y responde con texto plano de saludo. En docker-compose.yml, el servicio usa la imagen oficial node:20 y ejecuta este script. Por simplicidad, este ejemplo usa Node sin framework adicional, simplemente para demostrar conectividad. (Nota: En la configuración Nginx dada, no se incluyó explícitamente un bloque para node.miclickderecho.com. Si se desea exponerlo por un subdominio, se puede agregar un bloque similar. Aquí asumimos que el contenido Node podría integrarse en el frontend principal o ajustarse según necesidad.)

- PHP con Apache (php-apache/): Utiliza la imagen oficial php:8.2-apache, que ya incluye un servidor Apache HTTP con soporte PHP. Se monta el directorio php-apache/ en /var/www/html dentro del contenedor, por lo que el index.php de ejemplo (que llama phpinfo()) estará disponible en la raíz del sitio. Este contenedor escucha en el puerto 80 interno, y Nginx lo proxy a través de web.*.

- Bases de Datos (MySQL y PostgreSQL):
-- MySQL: Usa la imagen oficial mysql:8.0. En el docker-compose.yml se le pasa la contraseña de root, nombre de base de datos inicial, usuario y contraseña (desde .env). También se monta un script de inicialización (mysql/init.sql) en el directorio especial docker-entrypoint-initdb.d para que MySQL cree la base de datos y una tabla de ejemplo en el primer arranque automáticamente. Los datos de MySQL se persisten en el volumen mysql_data para evitar pérdida en recreaciones de contenedor.
-- PostgreSQL: Usa la imagen oficial postgres:15. Igualmente, se configuran las credenciales mediante variables de entorno y se monta postgres/init.sql para crear una tabla de ejemplo al iniciar por primera vez. Sus datos se guardan en el volumen pg_data.
Ninguna de las dos bases de datos expone puertos al exterior, solo pueden ser accedidas por otros contenedores Docker en la misma red (por ejemplo, un futuro backend podría conectarse a mysql en el puerto 3306 o postgres en el 5432 dentro de la red de Docker Compose).

- n8n (Workflow Automation): Usa la imagen oficial n8nio/n8n:latest. Este contenedor permite la automatización de tareas mediante flujos de trabajo visuales. En esta configuración, Nginx redirige el subdominio n8n.* al puerto 5678 del contenedor n8n. Se monta un volumen n8n_data en el home de n8n para persistir los flujos y credenciales creados en la herramienta.

- Evolution API: Usa la imagen atendai/evolution-api:latest​ doc.evolution-api.com, un servicio REST para integrarse con WhatsApp (alternativa al API oficial de WhatsApp Business). Está configurada con la variable AUTHENTICATION_API_KEY (tomada de .env) para proteger las solicitudes. Por defecto expone el puerto 8080 dentro del contenedor​ doc.evolution-api.com, que Nginx mapea al subdominio ws.*. Se utilizan dos volúmenes (evolution_store y evolution_instances) para persistir datos de la API (como sesiones de WhatsApp) más allá del ciclo de vida del contenedor, según recomienda la documentación oficial.

OpenWebUI: Usa la imagen de GitHub Container Registry ghcr.io/open-webui/open-webui:main, la cual despliega una interfaz web similar a ChatGPT que puede conectarse a modelos locales (p.ej., usando Ollama u otros backends). En esta configuración, el contenedor expone su interfaz web en el puerto 8080 (por defecto) y se monta un volumen openwebui_data para persistir datos (como configuraciones, historiales o modelos descargados). El subdominio chats.* en Nginx dirige hacia este servicio. Nota: OpenWebUI es un proyecto que funciona enteramente offline y puede requerir descargar modelos de lenguaje por separado; nuestra infraestructura lo deja listo para acceder a la interfaz, pero la funcionalidad dependerá de la configuración interna de OpenWebUI una vez en funcionamiento.

# Instalación Automatizada
Se incluye un script install.sh que automatiza los pasos de instalación en un servidor Ubuntu recién configurado. El script realiza lo siguiente:

1. Instalación de Docker y Compose: Actualiza paquetes e instala Docker, Docker Compose, Git y Certbot (para SSL) mediante apt. Esto asegura que el sistema tenga Docker corriendo y la herramienta docker-compose disponible para orquestar los servicios.
2. Clonación del repositorio: Descarga (clona) el contenido de este proyecto desde GitHub. (Asume que el repositorio miclickderecho/mi-click-derecho-server existe públicamente. De lo contrario, se puede copiar manualmente el archivo docker-compose.yml y demás al servidor.)
3. Obtención de certificados SSL: Ejecuta Certbot en modo standalone para los dominios/subdominios requeridos. Esta orden solicita certificados para web.miclickderecho.com, api.miclickderecho.com, n8n.miclickderecho.com, ws.miclickderecho.com y chats.miclickderecho.com. Certbot debe ser capaz de verificar cada dominio, por lo que los registros DNS de estos subdominios deben apuntar a la IP pública del servidor antes de correr el script. Se usa --non-interactive y se asume aprobación de términos (EULA) automáticamente; si es la primera vez, Certbot generará los certificados y los almacenará en /etc/letsencrypt/live/....
4. Levantamiento de servicios Docker: Finalmente, el script ejecuta docker-compose up -d para crear y levantar todos los contenedores en segundo plano. Docker Compose descargará las imágenes necesarias (si no se encuentran localmente) y construirá la imagen personalizada para FastAPI, luego iniciará todo según la configuración.


Para ejecutar el script, basta con copiarlo al servidor y ejecutarlo. Ejemplo:
chmod +x install.sh
sudo ./install.sh


# Uso y Verificación de la Instalación
Una vez completada la instalación, todos los servicios deberían estar activos. Se pueden verificar de la siguiente manera:

- Nginx/SSL: Acceder vía navegador a https://web.miclickderecho.com (u otro subdominio configurado) debería cargar sin advertencias de certificado. Al usar http:// debería redirigir automáticamente a https://.
- Frontend PHP: Ir a https://web.miclickderecho.com mostrará la página de phpinfo(), confirmando que PHP/Apache está funcionando correctamente bajo Nginx.
- API FastAPI: Visitar https://api.miclickderecho.com debería retornar un JSON {"message": "¡Hola desde FastAPI!"} proveniente de la aplicación FastAPI de ejemplo. (FastAPI por defecto también sirve documentación interactiva en /docs y /redoc que serían accesibles bajo el mismo dominio).
- Node.js: (Si se configuró un subdominio o ruta para Node) se podría acceder a la respuesta "Hola desde Node.js". En esta configuración de ejemplo, el Node server está corriendo pero no asignado a un bloque de servidor dedicado. Si se desea, se puede integrar en el bloque de web.miclickderecho.com o crear otro bloque.
- n8n: Navegar a https://n8n.miclickderecho.com mostrará la interfaz de n8n, donde podrá iniciar sesión (la primera vez pedirá crear un usuario administrador) y luego crear flujos de trabajo automatizados.
- Evolution API: La API de WhatsApp estará escuchando en https://ws.miclickderecho.com. Para probarla, puede hacerse una solicitud HTTP GET a https://ws.miclickderecho.com/health (o el endpoint correspondiente) usando la herramienta de su preferencia, enviando la cabecera apikey con el valor definido en .env (EVOLUTION_API_KEY). Si la API está corriendo, debe responder con un estado o mensaje indicando que está lista para usar. (Consulte la documentación de Evolution API para más endpoints).
- OpenWebUI: Accediendo a https://chats.miclickderecho.com, debería cargar la interfaz web de OpenWebUI, similar a ChatGPT, donde podrá interactuar con los modelos configurados. De ser la primera ejecución, podría no tener ningún modelo cargado; siga las instrucciones de OpenWebUI para cargar un modelo de lenguaje y comenzar a chatear.

Para comprobar que los contenedores están corriendo, puede usar sudo docker-compose ps dentro del directorio del proyecto, lo que listará todos los servicios con su estado (deberían aparecer como Up). Si algún servicio se cae repetidamente, use docker-compose logs <nombre_servicio> para diagnosticar.

# Notas Finales

- Seguridad: Las contraseñas en .env son de ejemplo. Cámbielas antes de desplegar en producción. Asimismo, el correo admin@miclickderecho.com usado en Certbot debería reemplazarse por uno real del administrador del sistema.
- DNS: Asegúrese de configurar los A/AAAA records de web, api, n8n, ws y chats apuntando al servidor (y esperar la propagación DNS) antes de ejecutar Certbot, o este fallará en la obtención de certificados.
- Ajustes de Recursos: En AWS, use al menos una instancia t2.medium o superior si planea ejecutar todos estos servicios simultáneamente, ya que algunos (especialmente OpenWebUI con IA o las bases de datos) pueden consumir bastante RAM y CPU. En entornos de prueba, un t2.micro podría quedarse corto.
- Extensibilidad: Esta estructura se puede ampliar según las necesidades:
-- Se podría agregar un servicio de Redis o RabbitMQ si la aplicación lo requiere.
-- Para escalabilidad, considerar separar los servicios en múltiples máquinas o usar Docker Swarm/Kubernetes en el futuro.
-- Ajustar las configuraciones de cada servicio (por ejemplo, cambiar los puertos internos, agregar más volúmenes, habilitar autenticación en OpenWebUI, etc.) según los requerimientos.
- Iniciar Todo al Reboot: Docker Compose normalmente reinicia los contenedores a menos que se especifique lo contrario (hemos usado restart: always en varios servicios para garantizar que se relancen). Aun así, puede configurar el servicio Docker para arrancar al inicio del sistema (en Ubuntu esto suele estar habilitado por defecto). Verifique con systemctl enable docker si no lo está.
- Backup: Dado que hay datos persistentes (bases de datos, configuraciones de n8n, etc.), implemente un mecanismo de respaldo periódico. Los volúmenes Docker pueden copiarse o montarse temporalmente para crear backups de la información crítica.

Con esta infraestructura, tendrá un servidor Ubuntu capaz de ejecutar simultáneamente un frontend PHP, un backend FastAPI en Python, procesos Node.js, servicios de automatización y de integración de chat/IA, todo tras un proxy Nginx común con HTTPS. El proyecto está listo para ser descargado, desplegado (vía Docker) y adaptado a los requerimientos específicos de Mi Click Derecho.
