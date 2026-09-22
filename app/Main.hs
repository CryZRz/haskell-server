{-# LANGUAGE ScopedTypeVariables #-}

import Control.Concurrent (forkIO)
import Control.Concurrent.MVar
import Control.Exception (SomeException, try)
import Control.Monad (forever)
import qualified Data.ByteString.Char8 as C
import Network.Socket
import Network.Socket.ByteString (recv, sendAll)
import System.IO (hFlush, stdout)

maxClients :: Int
maxClients = 7

main :: IO ()
main = runTCPServer "8000"

runTCPServer :: String -> IO ()
runTCPServer port = withSocketsDo $ do
  addr <- resolve
  sock <- socket (addrFamily addr) (addrSocketType addr) (addrProtocol addr)
  setSocketOption sock ReuseAddr 1
  bind sock (addrAddress addr)
  listen sock 5
  putStrLn $ "Servidor Haskell escuchando en 0.0.0.0:" ++ port
  clients <- newMVar []
  _ <- forkIO $ acceptLoop sock clients
  putStrLn "Escribe un mensaje y presiona Enter para enviar a todos los clientes."
  enviarMensajes clients
  where
    resolve = do
      let hints = defaultHints {addrFlags = [AI_PASSIVE], addrSocketType = Stream}
      head <$> getAddrInfo (Just hints) Nothing (Just port)

acceptLoop :: Socket -> MVar [Socket] -> IO ()
acceptLoop sock clients = forever $ do
  (conn, peer) <- accept sock
  clientList <- takeMVar clients
  if length clientList >= maxClients
    then do
      putStrLn $ "\n[Server] Limite de " ++ show maxClients ++ " clientes alcanzado. Rechazando: " ++ show peer
      sendAll conn (C.pack "Servidor lleno. Intenta mas tarde.\n")
      close conn
      putMVar clients clientList
    else do
      putMVar clients (conn : clientList)
      _ <- forkIO $ recibirMensajes conn peer clients
      return ()

recibirMensajes :: Socket -> SockAddr -> MVar [Socket] -> IO ()
recibirMensajes conn peer clients = loop Nothing C.empty
  where
    contenido mNombre = case mNombre of
      Just n  -> C.unpack n
      Nothing -> show peer

    procesar :: Maybe C.ByteString -> C.ByteString -> IO ()
    procesar Nothing nombre = do
      n <- clientCount clients
      putStrLn $ "\n[Server] Nuevo cliente conectado: " ++ C.unpack nombre
        ++ " (" ++ show n ++ "/" ++ show maxClients ++ ")"
    procesar (Just _) linea = do
      putStrLn $ "\n" ++ C.unpack linea
      broadcast clients (Just conn) (linea `C.append` C.pack "\n")

    loop :: Maybe C.ByteString -> C.ByteString -> IO ()
    loop mNombre buf = do
      chunk <- recv conn 1024
      if C.null chunk
        then do
          putStrLn $ "\n[Server] " ++ contenido mNombre ++ " desconectado."
          removeClient conn clients
        else do
          let partes = C.split '\n' (buf `C.append` chunk)
              lineas = init partes
              rest = last partes
          mapM_ (procesar mNombre) lineas
          let mNombre' = case mNombre of
                Just _  -> mNombre
                Nothing -> case lineas of
                  (l : _) | not (C.null l) -> Just l
                  _ -> mNombre
          loop mNombre' rest

removeClient :: Socket -> MVar [Socket] -> IO ()
removeClient conn clients = do
  clientList <- takeMVar clients
  putMVar clients (filter (/= conn) clientList)
  close conn

clientCount :: MVar [Socket] -> IO Int
clientCount clients = do
  clientList <- readMVar clients
  return (length clientList)

broadcast :: MVar [Socket] -> Maybe Socket -> C.ByteString -> IO ()
broadcast clients mSender msg = do
  clientList <- takeMVar clients
  let recipients = maybe clientList (\s -> filter (/= s) clientList) mSender
  results <- mapM (\s -> try (sendAll s msg) :: IO (Either SomeException ())) recipients
  let alive = case mSender of
        Just s  -> s : [x | (x, Right _) <- zip recipients results]
        Nothing -> [x | (x, Right _) <- zip recipients results]
  putMVar clients alive

enviarMensajes :: MVar [Socket] -> IO ()
enviarMensajes clients = forever $ do
  putStr "Servidor > "
  hFlush stdout
  input <- getLine
  clientList <- readMVar clients
  if null clientList
    then putStrLn "[Info] No hay clientes conectados."
    else do
      let msg = "[Servidor]: " ++ input ++ "\n"
      broadcast clients Nothing (C.pack msg)
      putStrLn "[Server] Mensaje enviado a todos los clientes."
