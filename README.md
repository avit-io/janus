# Janus — un bridge bifronte sopra l'FFI Agda↔Haskell

Giano (Janus) ha due facce. Una guarda il mondo dei **tipi dipendenti** (Agda,
faccia Π): proprietà dimostrate, totalità, dati raffinati. L'altra guarda il
mondo degli **effetti** (Haskell, faccia monadica): `IO`, parzialità, errori
runtime. Janus standardizza il confine fra i due, aggiungendo automazione
(bridge componibili) e sicurezza (validazione con testimone) sopra l'FFI grezzo.

## Moduli

- `Janus/Transport.agda` — **Strato 1**: trasporto totale type-safe.
  Record `Transport A H` (encode/decode) + combinatori componibili
  `_⊗_` (prodotto), `_⊕_` (somma), `listT`, `_∘T_`, `idT`.
- `Janus/Coherence.agda` — la legge `decode ∘ encode ≡ id`, dimostrata
  **chiusa** per tutti i combinatori. È ciò che distingue Janus da un FFI grezzo.
- `Janus/Refine.agda` — **Strato 2**: `Refine A H` *contiene* un `Transport`
  e aggiunge un invariante `P` con `validate : (a : A) → Dec (P a)`.
  `decodeProof` restituisce `Maybe (Σ A P)`: il dato impacchettato con la prova.
- `Janus/FFI.agda` — la direzione Agda→Haskell: `IO` importato,
  `call` (solo trasporto) e `callChecked` (le due facce fuse).
- `Main.agda` — demo eseguibile: Agda chiama una funzione `IO` Haskell, valida
  il ritorno, e produce un testimone di non-negatività.

## Compilare ed eseguire

Richiede Agda 2.6.3 + stdlib 1.7.x + GHC.

```
agda --compile Main.agda
LC_ALL=C.UTF-8 ./Main
```

Output atteso:

```
Janus PoC — callChecked (due facce in una)
42
rifiutato: negativo
fine
```

## Convertire un tuo FFI esistente a Janus

Hai tipicamente un postulato così:

```agda
postulate rawFn : HsIn → IO HsOut
{-# COMPILE GHC rawFn = ... #-}
```

Tre passi:

1. **Tieni il postulato grezzo** invariato — è la "funzione Haskell grezza".
2. **Definisci i bridge.** Per i tipi già condivisi (Int, String, ...) usa
   `idT`. Per i tipi composti, componi: `ta ⊗ tb`, `listT ta`, ecc.
3. **Scegli il livello di garanzia al confine:**
   - solo trasporto type-safe → `call transportIn transportOut rawFn`
   - validazione con prova sul ritorno → `callChecked transportIn refineOut rawFn`
     (definisci `refineOut` con l'invariante `P` e un `validate` decidibile).

La conversione è **additiva**: parti tutto con `call`, e promuovi a
`callChecked` solo i confini dove un invariante conta, senza toccare il resto.

## Debito tecnico noto (è un PoC)

- I bridge **base** non-banali (es. `ℕ ↔ Int` che taglia i negativi) devono
  dimostrare `Coherent` a mano — o, meglio, NON essere `Transport` ma `Refine`.
  La linea di demarcazione è esattamente il punto di design da rispettare.
- `callChecked` valida solo il **ritorno**. Se serve validare anche l'argomento
  in uscita, il passo è simmetrico: un `Refine` anche sull'ingresso.
- Manca la direzione Haskell→Agda (esporre prove ad Haskell via `COMPILE GHC ... as`).
