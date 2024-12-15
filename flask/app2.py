import os
import pickle
import base64
import MySQLdb
import time
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from flask import Flask, jsonify

app = Flask(__name__)

SCOPES = ['https://www.googleapis.com/auth/gmail.send']

MYSQL_HOST = os.getenv("MYSQL_HOST", "")
MYSQL_PORT = int(os.getenv("MYSQL_PORT", 0))
MYSQL_USER = os.getenv("MYSQL_FLASK_USER", "")
MYSQL_PASSWORD = os.getenv("MYSQL_FLASK_PASSWORD", "")
MYSQL_DATABASE = os.getenv("MYSQL_DATABASE", "")
CREDENTIALS_FILE = os.getenv("FLASK_CREDENTIALS_FILE", "")
DESTINATION_EMAIL = os.getenv("FLASK_DESTINATION_EMAIL", "")

JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY", "")

while True:
    try:
        db = MySQLdb.connect(host=MYSQL_HOST, port=MYSQL_PORT,user=MYSQL_USER, passwd=MYSQL_PASSWORD, db=MYSQL_DATABASE)
        print("Connected to MySQL")
        break
    except MySQLdb.OperationalError as e:
        print("Waiting for MySQL to be ready...", e)
        time.sleep(5)

cursor = db.cursor()

# Función para obtener el último nivel de agua
def get_last_water_level(sensor_id):
    query = "SELECT valor, fecha_hora FROM LECTURA WHERE sensor_id = %s ORDER BY fecha_hora DESC LIMIT 1"
    cursor.execute(query, (sensor_id,))
    result = cursor.fetchone()
    
    if result:
        nivel_agua = result[0]  # valor del nivel de agua
        fecha_hora = result[1]  # fecha y hora de la lectura
        return nivel_agua, fecha_hora
    else:
        return None, None

# Función para enviar el correo
def send_email(subject, body, to_email):
    creds = None
    # El archivo token.pickle almacena el token de acceso de usuario
    # Si no existe, el flujo de autenticación se realizará nuevamente.
    if os.path.exists('token.pickle'):
        with open('token.pickle', 'rb') as token:
            creds = pickle.load(token)

    # Si no tenemos credenciales (o han caducado), autenticamos al usuario
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            flow = InstalledAppFlow.from_client_secrets_file(
                CREDENTIALS_FILE, SCOPES)
            creds = flow.run_local_server(port=0)

        # Guardar el token para la próxima vez
        with open('token.pickle', 'wb') as token:
            pickle.dump(creds, token)

    # Llamar a la API de Gmail
    try:
        service = build('gmail', 'v1', credentials=creds)

        # Crear el mensaje
        message = MIMEMultipart()
        message['to'] = to_email
        message['subject'] = subject
        message.attach(MIMEText(body, 'plain'))

        # Enviar el mensaje a través de la API de Gmail
        raw_message = {'raw': base64.urlsafe_b64encode(message.as_bytes()).decode()}
        message = service.users().messages().send(userId="me", body=raw_message).execute()
        print(f"Correo enviado con éxito a {to_email}")
        return True

    except Exception as error:
        print(f"Ocurrió un error: {error}")
        return False

# Ruta para verificar el nivel de agua y enviar correo si es bajo
@app.route('/check_water_level', methods=['GET'])
def check_water_level():
    sensor_id = 4  # ID del sensor de agua
    nivel_agua, fecha_hora = get_last_water_level(sensor_id)
    
    if nivel_agua is not None:
        print(f"Nivel de agua: {nivel_agua}, Fecha y hora: {fecha_hora}")

        # Verificar si el nivel de agua es bajo
        if nivel_agua <= 10:
            subject = "¡Alerta! Nivel de agua bajo"
            body = f"El nivel de agua ha bajado a {nivel_agua}. ¡Es hora de revisar el sistema de riego!"
            to_email = DESTINATION_EMAIL
            if send_email(subject, body, to_email):
                return jsonify({"message": "Correo enviado con éxito."}), 200
            else:
                return jsonify({"message": "Error al enviar el correo."}), 500
        else:
            return jsonify({"message": "El nivel de agua es adecuado."}), 200
    else:
        return jsonify({"message": "No se encontraron datos para el sensor de agua."}), 404

if __name__ == '__main__':
    app.run(debug=True)