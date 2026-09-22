using System.Net.Sockets;
using System.Text;

string Ask(string prompt, string def)
{
    Console.Write(prompt);
    string? line = Console.ReadLine();
    return string.IsNullOrWhiteSpace(line) ? def : line.Trim();
}

string host = Ask("IP del servidor [127.0.0.1]: ", "127.0.0.1");
string port = Ask("Puerto del servidor [8000]: ", "8000");
string nick = Ask("Ingresa tu nombre: ", "Jugador");

try
{
    using var client = new TcpClient();
    await client.ConnectAsync(host, int.Parse(port));

    Console.WriteLine($"Conectado a {host}:{port}");
    Console.WriteLine("Escribe un mensaje y presiona Enter para enviar.\n");

    var stream = client.GetStream();

    await stream.WriteAsync(Encoding.UTF8.GetBytes(nick + "\n"));

    var receptor = Task.Run(async () =>
    {
        var buffer = new byte[1024];
        var sb = new StringBuilder();
        while (true)
        {
            int n = await stream.ReadAsync(buffer);
            if (n == 0)
            {
                Console.WriteLine("\nConexión cerrada.");
                Environment.Exit(0);
            }
            sb.Append(Encoding.UTF8.GetString(buffer, 0, n));
            string text = sb.ToString();
            while (text.Contains('\n'))
            {
                int idx = text.IndexOf('\n');
                Console.Write($"\r{text[..idx].Trim()}\nCliente > ");
                text = text[(idx + 1)..];
            }
            sb.Clear();
            sb.Append(text);
        }
    });

    while (true)
    {
        Console.Write("Cliente > ");
        string? line = Console.ReadLine();
        if (line is null) break;
        if (string.IsNullOrWhiteSpace(line)) continue;
        byte[] data = Encoding.UTF8.GetBytes(nick + ": " + line + "\n");
        await stream.WriteAsync(data);
    }
}
catch (Exception ex)
{
    Console.WriteLine($"Error de conexión: {ex.Message}");
}