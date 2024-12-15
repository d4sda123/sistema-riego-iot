from flask import Flask, request, jsonify
from flask_jwt_extended import JWTManager, create_access_token, jwt_required, get_jwt_identity, unset_jwt_cookies
from flask_mysqldb import MySQL
import bcrypt
import os

# Configuración de la app Flask
app = Flask(__name__)

# Configuración de la base de datos
app.config['MYSQL_HOST'] = os.getenv("MYSQL_HOST", "")
app.config['MYSQL_USER'] = os.getenv("MYSQL_FLASK_USER", "")
app.config['MYSQL_PASSWORD'] = os.getenv("MYSQL_FLASK_PASSWORD", "")
app.config['MYSQL_DB'] = os.getenv("MYSQL_DATABASE", "")

# Configuración de JWT
app.config['JWT_SECRET_KEY'] = os.getenv("JWT_SECRET_KEY", "")

# Inicialización de la base de datos y JWT
mysql = MySQL(app)
jwt = JWTManager(app)

# Ruta para el login
@app.route('/login', methods=['POST'])
def login():
    username = request.json.get('username', None)
    password = request.json.get('password', None)

    if not username or not password:
        return jsonify({"message": "Faltan credenciales"}), 400

    # Consultar el usuario en la base de datos
    cur = mysql.connection.cursor()
    cur.execute('SELECT id, username, password_hash, salt, role_id FROM users WHERE username = %s', (username,))
    user = cur.fetchone()

    if user:
        user_id, db_username, password_hash, salt, role_id = user

        # Verificar contraseña con el hash y el salt
        if bcrypt.checkpw(password.encode('utf-8'), password_hash.encode('utf-8')):
            # Recuperar el rol del usuario
            cur.execute('SELECT name FROM roles WHERE id = %s', (role_id,))
            role = cur.fetchone()[0] if role_id else 'guest'

            # Crear un token JWT
            access_token = create_access_token(identity={'username': db_username, 'id': user_id, 'role': role})
            return jsonify({"message": "Login exitoso", "token": access_token}), 200
        else:
            return jsonify({"message": "Usuario o contraseña incorrectos"}), 401
    else:
        return jsonify({"message": "Usuario o contraseña incorrectos"}), 401

# Ruta protegida con validación de rol
@app.route('/admin', methods=['GET'])
@jwt_required()
def admin_area():
    current_user = get_jwt_identity()
    if current_user['role'] != 'admin':
        return jsonify({"message": "Acceso denegado"}), 403
    return jsonify({"message": "Bienvenido al área de administración"}), 200

# Ruta para registrar un nuevo usuario
@app.route('/register', methods=['POST'])
def register():
    username = request.json.get('username', None)
    email = request.json.get('email', None)
    password = request.json.get('password', None)
    role_id = request.json.get('role_id', None)  # Opcional: Asignar un rol al usuario

    if not username or not password or not email:
        return jsonify({"message": "Faltan credenciales"}), 400

    # Encriptar la contraseña con bcrypt
    hashed_password = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())

    # Insertar el nuevo usuario en la base de datos
    cur = mysql.connection.cursor()
    cur.execute('INSERT INTO users (username, email, password_hash, salt, role_id) VALUES (%s, %s, %s, %s, %s)', 
                (username, email, hashed_password, '', role_id))
    mysql.connection.commit()
    return jsonify({"message": "Usuario registrado exitosamente"}), 201

# Ruta para el logout
@app.route('/logout', methods=['POST'])
@jwt_required()
def logout():
    response = jsonify({"message": "Logout exitoso"})
    unset_jwt_cookies(response)  # Esta función elimina el JWT cookie
    return response, 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
