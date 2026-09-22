# simpleServer

Servidor de chat por TCP escrito en Haskell. Acepta varios clientes conectados por socket y difunde los mensajes que recibe a todos los demás.

## Requisitos

- GHC / cabal (proyecto cabal)

## Compilar y ejecutar

```bash
cabal build
cabal run
```

El servidor escucha en `0.0.0.0:8000` y admite hasta 7 clientes conectados.

Desde la consola del servidor puedes escribir mensajes con el prefijo `Servidor > ` y se reenvían a todos los clientes.

## Protocolo

- Al conectarse, cada cliente envía su **nombre** en la primera línea antes de escribir mensajes.
- El servidor imprime en su consola `[Server] Nuevo cliente conectado: <nombre> (n/7)`.
- Cada mensaje de chat se envía como `<nombre>: <texto>` y el servidor lo difunde tal cual a los demás clientes (sin agregar la IP).
- Cuando un cliente se desconecta, se imprime `[Server] <nombre> desconectado.`

## Estructura

- `app/Main.hs` — servidor TCP
- `simpleServer.cabal` — configuración del proyecto