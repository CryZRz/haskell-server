const net = require('net');
const readline = require('readline');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

function ask(question) {
  return new Promise(resolve => rl.question(question, resolve));
}

async function main() {
  const host = (await ask('IP del servidor [127.0.0.1]: ')).trim() || '127.0.0.1';
  const port = parseInt((await ask('Puerto del servidor [8000]: ')).trim(), 10) || 8000;
  const nick = (await ask('Ingresa tu nombre: ')).trim() || 'Jugador';
  rl.close();

  const client = new net.Socket();

  client.on('data', (data) => {
    const msg = data.toString().trim();
    if (msg) {
      process.stdout.write('\r' + msg + '\n');
      process.stdout.write('Cliente > ');
    }
  });

  client.on('error', (err) => {
    console.error('Error de conexión:', err.message);
    process.exit(1);
  });

  client.on('close', () => {
    console.log('\nConexión cerrada.');
    process.exit(0);
  });

  client.connect(port, host, () => {
    client.write(nick + '\n');
    console.log(`Conectado a ${host}:${port}`);
    console.log('Escribe un mensaje y presiona Enter para enviar.\n');

    const chat = readline.createInterface({
      input: process.stdin,
      output: process.stdout,
      prompt: 'Cliente > '
    });

    chat.prompt();

    chat.on('line', (line) => {
      if (line.trim() === '') {
        chat.prompt();
        return;
      }
      client.write(nick + ': ' + line + '\n');
      chat.prompt();
    });

    chat.on('close', () => {
      client.end();
      process.exit(0);
    });
  });
}

main();
