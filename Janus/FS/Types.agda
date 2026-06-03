module Janus.FS.Types where

open import Agda.Builtin.String using (String)
open import Data.Nat using (ℕ)

-- ── tipi ONESTI lato Agda ─────────────────────────────────────────────
-- Il chiamante Agda non vede mai `String` grezza né `IO`: vede QUESTI.

-- Un path è un tipo a sé, non un alias di String. Così non puoi passare
-- per sbaglio una stringa qualunque dove serve un percorso, e il wrapper
-- è il solo punto che sa come un Path diventa la FilePath di Haskell.
record Path : Set where
  constructor mkPath
  field unPath : String
open Path public

-- Gli errori che in Haskell sono ECCEZIONI INVISIBILI nel tipo, qui
-- diventano dati di prima classe ed esaustivi. Questa è la traduzione
-- chiave: "IO Bool che può lanciare" → "Result FileError Bool", totale.
data FileError : Set where
  doesNotExist   : FileError
  permission     : FileError
  notARegularFile : FileError
  otherIOError   : String → FileError   -- catch-all onesto, non nascosto

-- Result al posto di Maybe-che-significa-fallimento: l'errore ha NOME.
data Result (E A : Set) : Set where
  ok  : A → Result E A
  err : E → Result E A

-- Metadati raffinati: una dimensione è un ℕ (mai negativa per costruzione),
-- non l'Integer di Haskell che potrebbe in teoria essere < 0.
FileSize : Set
FileSize = ℕ
