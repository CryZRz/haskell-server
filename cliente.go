package main

import (
	"bufio"
	"fmt"
	"net"
	"os"
	"strings"
)

func ask(prompt, def string) string {
	fmt.Printf("%s", prompt)
	line, _ := bufio.NewReader(os.Stdin).ReadString('\n')
	line = strings.TrimSpace(line)
	if line == "" {
		return def
	}
	return line
}

func main() {
	host := ask("IP del servidor [127.0.0.1]: ", "127.0.0.1")
	port := ask("Puerto del servidor [8000]: ", "8000")
	nick := ask("Ingresa tu nombre: ", "Jugador")

	conn, err := net.Dial("tcp", net.JoinHostPort(host, port))
	if err != nil {
		fmt.Println("Error de conexión:", err)
		os.Exit(1)
	}
	defer conn.Close()
	conn.Write([]byte(nick + "\n"))

	fmt.Printf("Conectado a %s:%s\n", host, port)
	fmt.Println("Escribe un mensaje y presiona Enter para enviar.")

	go func() {
		reader := bufio.NewReader(conn)
		for {
			msg, err := reader.ReadString('\n')
			if err != nil {
				fmt.Println("\nConexión cerrada.")
				os.Exit(0)
			}
			fmt.Printf("\r%sCliente > ", msg)
		}
	}()

	scanner := bufio.NewScanner(os.Stdin)
	for {
		fmt.Print("Cliente > ")
		if !scanner.Scan() {
			break
		}
		line := strings.TrimRight(scanner.Text(), "\n")
		if strings.TrimSpace(line) == "" {
			continue
		}
		conn.Write([]byte(nick + ": " + line + "\n"))
	}
}
