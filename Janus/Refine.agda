module Janus.Refine where

open import Janus.Transport
open import Data.Product using (Σ; _,_; ∃)
open import Data.Maybe using (Maybe; just; nothing)
open import Relation.Nullary using (Dec; yes; no)

-- Strato 2: la faccia Π di Giano "attiva".
-- Refine CONTIENE un Transport (non lo sostituisce): lo strato 1
-- continua a valere, le prove sono additive.
record Refine (A : Set) (H : Set) : Set₁ where
  field
    transport : Transport A H
    P         : A → Set            -- l'invariante che vogliamo al confine
    validate  : (a : A) → Dec (P a) -- Π→runtime: check eseguibile con testimone

  -- decode che, se l'invariante vale, restituisce il dato IMPACCHETTATO
  -- con la sua prova (Σ A P). Altrimenti fallisce esplicitamente.
  decodeProof : H → Maybe (Σ A P)
  decodeProof h with validate (decode transport h)
  ... | yes p = just (decode transport h , p)
  ... | no  _ = nothing

open Refine public
