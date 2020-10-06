module Sound.Osc where

import Prelude

import Control.Monad.Except (runExcept)
import Data.Either (Either(..))
import Data.Function.Uncurried (Fn1, Fn2, Fn3, runFn1, runFn2, runFn3)
import Data.Generic.Rep as Generic
import Effect (Effect)
import Effect.Console (log, logShow)
import Foreign (F, Foreign)
import Simple.JSON as Json
import Simple.JSON.Generics.TaggedSumRep as JsonGeneric

type Address = String
type Port = Int
type Path = String

data OscValue
  = OscString String
  | OscFloat Number
  | OscInt Int
  -- TODO: support Uint8Array for binary data

derive instance genericValue :: Generic.Generic OscValue _
instance readForeignValue :: Json.ReadForeign OscValue where readImpl = JsonGeneric.taggedSumRep
instance writeForeign :: Json.WriteForeign OscValue where
  writeImpl (OscString a) = Json.writeImpl a
  writeImpl (OscFloat a) = Json.writeImpl a
  writeImpl (OscInt a) = Json.writeImpl a
instance showValue :: Show OscValue where
  show (OscString a) = show a
  show (OscFloat a) = show a
  show (OscInt a) = show a


type Message =
  { path :: Path
  , msg :: Array OscValue
  }


foreign import data Client :: Type

foreign import _connect :: Fn2 Address Port (Effect Client)
connect :: Address -> Port -> Effect Client
connect address port = runFn2 _connect address port

-- TODO: actually use Instant?
foreign import _send :: Fn3 Client Number Foreign (Effect Unit)
send :: Client -> Number -> Message -> Effect Unit
send client timestamp message = runFn3 _send client timestamp $ Json.write message

foreign import _closeClient :: Fn1 Client (Effect Unit)
closeClient :: Client -> Effect Unit
closeClient client = runFn1 _closeClient client



foreign import data Server :: Type

foreign import _listen :: Fn2 Address Port (Effect Server)
listen :: Address -> Port -> Effect Server
listen address port = runFn2 _listen address port

foreign import _on :: Fn2 Server (Foreign -> Effect Unit) (Effect Unit)
on :: Server -> (F Message -> Effect Unit) -> Effect Unit
on server handler = on' server $ handler <<< Json.read'

on' :: Server -> (Foreign -> Effect Unit) -> Effect Unit
on' server handler = runFn2 _on server handler

foreign import _closeServer :: Fn1 Server (Effect Unit)
closeServer :: Server -> Effect Unit
closeServer server = runFn1 _closeServer server


-- TODO move to test
main :: Effect Unit
main = do
  server <- listen "0.0.0.0" 3333
  client <- connect "127.0.0.1" 3333

  let callback m = case runExcept m of
        Left errs -> logShow errs
        Right message -> do
          log "GOT MESSAGE!"
          logShow message
          closeServer server
          closeClient client

  on server callback

  let send' msg = send client 0.0 { path: "/path", msg }
  send' [ OscString "test!", OscFloat 4.20, OscInt 23 ]
