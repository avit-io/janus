module Janus.FS.Raw where

open import Agda.Builtin.IO using (IO)
open import Agda.Builtin.String using (String)
open import Agda.Builtin.Bool using (Bool)
open import Agda.Builtin.Int using (Int)
open import Data.List using (List)

-- ── la buccia IMPURA ──────────────────────────────────────────────────
-- Qui, e SOLO qui, vive Haskell. Il FOREIGN block fa il lavoro che il
-- tipo `IO Bool` non dichiara: cattura le eccezioni e le rende dati.

-- Un tipo-risultato grezzo DEFINITO QUI, così possiamo mapparlo a Either
-- di Haskell (il pragma COMPILE deve stare nello stesso modulo del tipo).
data RawResult (A : Set) : Set where
  rawErr : String → RawResult A
  rawOk  : A → RawResult A

{-# FOREIGN GHC
import qualified System.Directory as D
import qualified Data.Text as T
import qualified Control.Exception as E
import System.IO.Error (isDoesNotExistError, isPermissionError)

data RawResult a = RawErr T.Text | RawOk a

-- esegue un'azione e cattura le eccezioni: QUESTO è ciò che il tipo
-- Haskell `IO a` non dichiara mai. La parzialità resa esplicita.
guarded :: IO a -> IO (RawResult a)
guarded act = E.catch (RawOk <$> act) handler
  where
    handler e
      | isDoesNotExistError e = pure (RawErr (T.pack "ENOENT"))
      | isPermissionError  e  = pure (RawErr (T.pack "EACCES"))
      | otherwise             = pure (RawErr (T.pack (show (e :: E.IOException))))

rawDoesFileExist :: T.Text -> IO Bool
rawDoesFileExist = D.doesFileExist . T.unpack

rawGetFileSize :: T.Text -> IO (RawResult Integer)
rawGetFileSize p = guarded (D.getFileSize (T.unpack p))

rawListDirectory :: T.Text -> IO (RawResult [T.Text])
rawListDirectory p = guarded (fmap (map T.pack) (D.listDirectory (T.unpack p)))
#-}

{-# COMPILE GHC RawResult = data RawResult (RawErr | RawOk) #-}

postulate
  rawDoesFileExist : String → IO Bool
  rawGetFileSize   : String → IO (RawResult Int)
  rawListDirectory : String → IO (RawResult (List String))

{-# COMPILE GHC rawDoesFileExist = rawDoesFileExist #-}
{-# COMPILE GHC rawGetFileSize   = rawGetFileSize   #-}
{-# COMPILE GHC rawListDirectory = rawListDirectory #-}
