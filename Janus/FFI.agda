module Janus.FFI where

open import Janus.Transport
open import Janus.Refine
open import Agda.Builtin.IO using (IO)
open import Agda.Builtin.Unit using (⊤)
open import Data.Product using (Σ)
open import Data.Maybe using (Maybe)

-- La faccia monadica di Giano: IO è importato dal mondo Haskell.
postulate
  _>>=_  : ∀ {A B : Set} → IO A → (A → IO B) → IO B
  return : ∀ {A : Set} → A → IO A

{-# COMPILE GHC _>>=_  = \_ _ -> (>>=)  #-}
{-# COMPILE GHC return = \_ -> return #-}

infixl 1 _>>=_

-- Il cuore di Janus, direzione Agda→Haskell:
-- prende una funzione Haskell GREZZA (Hₐ → IO Hᵦ) e i due bridge,
-- e restituisce un'interfaccia PULITA lato Agda (A → IO B).
-- Encode all'andata, decode al ritorno: il confine resta tipato.
call : ∀ {A Hₐ B Hᵦ : Set}
     → Transport A Hₐ → Transport B Hᵦ
     → (Hₐ → IO Hᵦ)
     → (A → IO B)
call ta tb f a = f (encode ta a) >>= λ h → return (decode tb h)

-- Le DUE FACCE di Giano fuse in un'unica chiamata:
--   • argomento in uscita: Transport semplice (Agda → Haskell)
--   • risultato in ingresso: Refine (Haskell → Agda CON validazione)
-- Restituisce Maybe (Σ B P): o il dato impacchettato con la sua prova,
-- o `nothing` se l'effetto Haskell ha violato l'invariante al confine.
-- Questo è il punto di conversione naturale per un FFI esistente:
-- prendi la tua funzione grezza, scegli i bridge, ottieni garanzie.
callChecked : ∀ {A Hₐ B Hᵦ : Set}
            → Transport A Hₐ          -- come spedire A a Haskell
            → (rb : Refine B Hᵦ)      -- come validare il B che torna
            → (Hₐ → IO Hᵦ)            -- la funzione Haskell grezza
            → (A → IO (Maybe (Σ B (Refine.P rb))))
callChecked ta rb f a =
  f (encode ta a) >>= λ h → return (decodeProof rb h)
