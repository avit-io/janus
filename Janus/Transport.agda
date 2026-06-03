module Janus.Transport where

open import Data.Product using (_×_; _,_; proj₁; proj₂)
open import Data.Sum using (_⊎_; inj₁; inj₂)
open import Data.List using (List; []; _∷_; map)

-- Strato 1: trasporto totale, round-trip per costruzione.
-- La faccia di Giano "a riposo": nessuna prova, solo conversione.
record Transport (A : Set) (H : Set) : Set where
  field
    encode : A → H
    decode : H → A

open Transport public

-- Identità: quando il tipo Agda È già il tipo Haskell.
idT : ∀ {A : Set} → Transport A A
idT = record { encode = λ x → x ; decode = λ x → x }

-- Composizione di bridge (transitività del trasporto).
_∘T_ : ∀ {A H K : Set} → Transport H K → Transport A H → Transport A K
g ∘T f = record
  { encode = λ a → encode g (encode f a)
  ; decode = λ k → decode f (decode g k) }

-- Prodotto: due bridge → un bridge sulla coppia.
_⊗_ : ∀ {A Hₐ B Hᵦ : Set}
    → Transport A Hₐ → Transport B Hᵦ → Transport (A × B) (Hₐ × Hᵦ)
ta ⊗ tb = record
  { encode = λ p → encode ta (proj₁ p) , encode tb (proj₂ p)
  ; decode = λ q → decode ta (proj₁ q) , decode tb (proj₂ q) }

-- Somma: due bridge → un bridge sull'unione disgiunta.
_⊕_ : ∀ {A Hₐ B Hᵦ : Set}
    → Transport A Hₐ → Transport B Hᵦ → Transport (A ⊎ B) (Hₐ ⊎ Hᵦ)
ta ⊕ tb = record
  { encode = λ { (inj₁ a) → inj₁ (encode ta a)
               ; (inj₂ b) → inj₂ (encode tb b) }
  ; decode = λ { (inj₁ h) → inj₁ (decode ta h)
               ; (inj₂ k) → inj₂ (decode tb k) } }

-- Liste: un bridge → un bridge sulle liste.
listT : ∀ {A H : Set} → Transport A H → Transport (List A) (List H)
listT t = record
  { encode = map (encode t)
  ; decode = map (decode t) }
