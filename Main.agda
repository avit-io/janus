module Main where

open import Janus.Transport
open import Janus.FFI
open import Janus.Refine
open import Agda.Builtin.IO using (IO)
open import Agda.Builtin.Unit using (⊤; tt)
open import Agda.Builtin.String using (String)
open import Data.Integer using (ℤ; +_; -[1+_]; _≤_) renaming (_≤?_ to _≤?ℤ_)
open import Data.Integer.Properties using ()
open import Data.Nat using (ℕ)
open import Data.Product using (Σ; _,_; proj₁)
open import Data.Maybe using (Maybe; just; nothing)
open import Relation.Nullary using (Dec; yes; no)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

-- ── lato Haskell grezzo ───────────────────────────────────────────────
-- Una "funzione di sistema" che vive nel mondo degli effetti:
-- legge una stringa e prova a parsarla come intero (qui via read).
postulate
  putStrLn   : String → IO ⊤
  showℤ      : ℤ → String
  parseIntIO : String → IO ℤ

{-# FOREIGN GHC import qualified Data.Text as T #-}
{-# FOREIGN GHC import qualified Data.Text.IO as TIO #-}
{-# COMPILE GHC putStrLn = TIO.putStrLn #-}
{-# COMPILE GHC showℤ = T.pack . show #-}
{-# COMPILE GHC parseIntIO = \s -> return (read (T.unpack s) :: Integer) #-}


-- ── faccia di Giano lato trasporto ────────────────────────────────────
-- ℤ è già mappato sul tipo Haskell Integer: trasporto identità.
ℤT : Transport ℤ ℤ
ℤT = idT

-- String → String: anch'essa identità (String è builtin condiviso).
StrT : Transport String String
StrT = idT

-- ── faccia di Giano lato PROVA ────────────────────────────────────────
-- Invariante: "il numero è ≥ 0". Validazione decidibile → testimone.
NonNeg : ℤ → Set
NonNeg z = (+ 0) ≤ z

validateNonNeg : (z : ℤ) → Dec (NonNeg z)
validateNonNeg z = (+ 0) ≤?ℤ z

ℤ⁺ : Refine ℤ ℤ
ℤ⁺ = record { transport = ℤT ; P = NonNeg ; validate = validateNonNeg }

-- ── la chiamata FFI con l'API UNIFICATA ───────────────────────────────
-- callChecked fonde le due facce: spedisce a Haskell via trasporto (StrT)
-- e valida il ritorno via Refine (ℤ⁺) → Maybe (Σ ℤ NonNeg).
checkAndReport : String → IO ⊤
checkAndReport s =
  callChecked StrT ℤ⁺ parseIntIO s >>= λ result →
  putStrLn (report result)
  where
    report : Maybe (Σ ℤ NonNeg) → String
    report (just (z , _)) = showℤ z   -- validato: TESTIMONE di ≥0 in mano
    report nothing        = "rifiutato: negativo"

main : IO ⊤
main =
  putStrLn "Janus PoC — callChecked (due facce in una)" >>= λ _ →
  checkAndReport "42"  >>= λ _ →
  checkAndReport "-7"  >>= λ _ →
  putStrLn "fine"
