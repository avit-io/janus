module Janus.FS where

open import Janus.FS.Types
open import Janus.FS.Raw
open import Janus.FFI using (_>>=_; return)
open import Agda.Builtin.IO using (IO)
open import Agda.Builtin.String using (String)
open import Agda.Builtin.Bool using (Bool)
open import Data.Integer using (ℤ; ∣_∣)
open import Data.List using (List; map)

-- ── traduzione errori: tag grezzo → FileError strutturato ─────────────
classify : String → FileError
classify s = otherIOError s
-- in un wrapper reale: match sul tag ("ENOENT" → doesNotExist, …);
-- per il PoC manteniamo il messaggio, ma TIPATO dentro FileError.

fromRaw : ∀ {A : Set} → RawResult A → Result FileError A
fromRaw (rawErr tag) = err (classify tag)
fromRaw (rawOk a)    = ok a

-- decode Int(Haskell) → ℕ: una dimensione non può essere negativa nel
-- mondo Agda, quindi prendiamo il valore assoluto. Tipo raffinato.
intToSize : ℤ → FileSize
intToSize = ∣_∣

-- ── la FACCIA AGDA della libreria ─────────────────────────────────────
-- Nessun IO Haskell, nessuna String grezza, nessuna eccezione: solo
-- Path, Result e FileError. Sembra Agda perché È Agda.

fileExists : Path → IO Bool
fileExists p = rawDoesFileExist (unPath p)

fileSize : Path → IO (Result FileError FileSize)
fileSize p =
  rawGetFileSize (unPath p) >>= λ e →
  return (mapSize (fromRaw e))
  where
    mapSize : Result FileError ℤ → Result FileError FileSize
    mapSize (ok i)  = ok (intToSize i)
    mapSize (err x) = err x

listDir : Path → IO (Result FileError (List Path))
listDir p =
  rawListDirectory (unPath p) >>= λ e →
  return (mapList (fromRaw e))
  where
    mapList : Result FileError (List String) → Result FileError (List Path)
    mapList (ok xs) = ok (map mkPath xs)
    mapList (err x) = err x
