module Janus.Coherence where

open import Janus.Transport
open import Relation.Binary.PropositionalEquality
  using (_≡_; refl; cong; cong₂)
open import Data.Product using (_×_; _,_; proj₁; proj₂)
open import Data.Sum using (_⊎_; inj₁; inj₂)
open import Data.List using (List; []; _∷_; map)

-- La proprietà che distingue Janus da un FFI grezzo:
-- decode ∘ encode = identità. Trasportare e tornare non perde nulla.
Coherent : ∀ {A H : Set} → Transport A H → Set
Coherent {A} t = (a : A) → decode t (encode t a) ≡ a

-- L'identità è coerente.
idT-coh : ∀ {A : Set} → Coherent (idT {A})
idT-coh a = refl

-- La coerenza è CHIUSA per composizione.
∘T-coh : ∀ {A H K : Set} (g : Transport H K) (f : Transport A H)
       → Coherent g → Coherent f → Coherent (g ∘T f)
∘T-coh g f cg cf a
  rewrite cg (encode f a) = cf a

-- La coerenza è CHIUSA per prodotto.
⊗-coh : ∀ {A Hₐ B Hᵦ : Set} (ta : Transport A Hₐ) (tb : Transport B Hᵦ)
      → Coherent ta → Coherent tb → Coherent (ta ⊗ tb)
⊗-coh ta tb ca cb (a , b) = cong₂ _,_ (ca a) (cb b)

-- La coerenza è CHIUSA per somma.
⊕-coh : ∀ {A Hₐ B Hᵦ : Set} (ta : Transport A Hₐ) (tb : Transport B Hᵦ)
      → Coherent ta → Coherent tb → Coherent (ta ⊕ tb)
⊕-coh ta tb ca cb (inj₁ a) = cong inj₁ (ca a)
⊕-coh ta tb ca cb (inj₂ b) = cong inj₂ (cb b)

-- La coerenza è CHIUSA per liste.
listT-coh : ∀ {A H : Set} (t : Transport A H)
          → Coherent t → Coherent (listT t)
listT-coh t c []       = refl
listT-coh t c (x ∷ xs) = cong₂ _∷_ (c x) (listT-coh t c xs)
