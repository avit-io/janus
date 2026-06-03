module MainFS where

open import Janus.FS
open import Janus.FS.Types
open import Janus.FFI using (_>>=_; return)
open import Agda.Builtin.IO using (IO)
open import Agda.Builtin.Unit using (⊤)
open import Agda.Builtin.String using (String)
open import Agda.Builtin.Bool using (Bool; true; false)
open import Data.Nat.Show using (show)
open import Data.String using (_++_)
open import Data.List using (List; length)

postulate putStrLn : String → IO ⊤
{-# FOREIGN GHC import qualified Data.Text.IO as TIO #-}
{-# COMPILE GHC putStrLn = TIO.putStrLn #-}

-- usa SOLO la faccia Agda: Path, Result, FileError. Niente Haskell visibile.
report : Result FileError FileSize → String
report (ok n)  = "dimensione (bytes): " ++ show n
report (err _) = "errore tipato al confine"

existMsg : Bool → String
existMsg true  = "/etc/hostname esiste"
existMsg false = "/etc/hostname non esiste"

dirMsg : Result FileError (List Path) → String
dirMsg (ok xs) = "voci in /etc: " ++ show (length xs)
dirMsg (err _) = "errore listando /etc"

main : IO ⊤
main =
  fileExists (mkPath "/etc/hostname") >>= λ b →
  putStrLn (existMsg b) >>= λ _ →
  fileSize (mkPath "/etc/hostname") >>= λ r →
  putStrLn (report r) >>= λ _ →
  listDir (mkPath "/etc") >>= λ d →
  putStrLn (dirMsg d)
