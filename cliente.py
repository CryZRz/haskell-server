import socket
import sys
import threading

def ask(prompt, default):
    value = input(prompt).strip()
    return value if value else default

def listen(conn):
    while True:
        try:
            message = b""
            while not message.endswith(b"\n"):
                chunk = conn.recv(1)
                if not chunk:
                    print("\rConexión cerrada por el servidor.")
                    sys.exit(0)
                message += chunk
            print(f"\r{message.decode().strip()}")
            print("Cliente > ", end="", flush=True)
        except Exception:
            print("\rConexión cerrada por el servidor.")
            sys.exit(0)

host = ask("IP del servidor [127.0.0.1]: ", "127.0.0.1")
port = ask("Puerto del servidor [8000]: ", "8000")
nick = ask("Ingresa tu nombre: ", "Jugador")

conn = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
try:
    conn.connect((host, int(port)))
except OSError as e:
    print("Error de conexión:", e)
    sys.exit(1)

conn.sendall((nick + "\n").encode())

print(f"Conectado a {host}:{port}")
print("Escribe un mensaje y presiona Enter para enviar.\n")

threading.Thread(target=listen, args=(conn,), daemon=True).start()

while True:
    print("Cliente > ", end="", flush=True)
    text = input()
    if text.strip():
        conn.sendall((nick + ": " + text + "\n").encode())