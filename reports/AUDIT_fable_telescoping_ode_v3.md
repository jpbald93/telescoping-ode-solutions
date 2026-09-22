# Telescoping ODE v3 — adversarial audit (Fable)

Auditor: adversarial referee subagent (Fable). Date: 2026-09-22.
Files: `telescoping_ode.tex` (527 lines) + PDF, `code/verify_ode.py` (206 lines),
`code/verify_output.txt`, `lean/ExpODE/Basic.lean` (143), `lean/ExpODE/Check.lean` (19),
`lean/gate.sh` (27). All quantitative claims below re-verified with my own
sympy/mpmath code (independent scripts, not the author's driver), at 90–120 digits.

## Verdict: ACCEPT

Every checked claim is correct. All seven v3 fixes landed and are mathematically
sound; both minor-revision patches are in place; the Lean gate passes (rebuilt
from source after touching the files, not just replaying a cached build); the
driver reruns byte-identically; my independent re-derivations and extrapolations
agree with every printed constant to the digits shown. I found no blockers and
no should-fixes. Two cosmetic nits only.

## Independent engine re-derivation (my numbers)

All symbolic work redone from scratch in sympy (my own script, `/tmp/audit_ode/engine_sym.py`):

- **u¹, u² coefficients of log E_n^(s)(c) − c vanish** for both branches: confirmed
  (`u1=0, u2=0` exactly, both s=±1).
- **g₃ = c⁴(−3+2s√3)/72**: confirmed. **g₄ = c⁵(39−25s√3)/720** and
  **g₅ = c⁶(−18+11s√3)/270** as printed in Theorem 2.5(4) (tex lines 138–142): confirmed
  symbolically for both branches.
- **−3g₃ = c⁴(3−2s√3)/24** (Lemma lem:fd / `lead_eq`): confirmed symbolically.
- **Displayed A₂** (tex lines 161–165): I checked all three printed forms are equal —
  (c³/3 − cα_s) + β_s(α_s − c²/2) = −c³/6 + β_s c² − β_s² c = −c³((s√3)²−3)/36,
  and A₂ = 0 under (s√3)² = 3. All True.
- **Displayed A₃** (tex lines 167–168): (−α²/2 + c²α − c⁴/4) + β(c³/3 − cα) = g₃. True.
- **Pythagorean base**: (1 − s√3x²u²/6)² + (xu)² = 1 + x²(1−s√3/3)u² + x⁴u⁴/12. True.

Numerical (my own Neville/Richardson at 120 dps, n = 10²…10⁸, `/tmp/audit_ode/engine_num.py`):

- **lim n⁴(E_{n+1}−E_n) = c⁴(3−2s√3)/24·e^c**: verified at c ∈ {1, 2, 0.5, −1, −2, 3.7},
  both branches — 12 cases, relative errors 10⁻³⁰…10⁻³⁶. E.g. c=1, s=+1:
  extrapolated −0.0525649577911438186 = target to 18 digits; c=−2, s=−1:
  0.583214015303275723, rel 1.9e−33. (Driver's Part-2 table independently reproduced.)
- **lim n³(log E_n − c) = g₃**: verified at c=1.3, −2, both branches, rel ≤ 4e−33.

## The claimed fixes — did they land and are they correct?

**B1. Differentiation preserves order 3 — LANDED, CORRECT.**
Lemma lem:deriv (tex lines 274–295): ∂_c log E_n = 1 + O(n⁻³). My sympy expansion of
∂_c[M(u)log B(u)]: u⁰=1, u¹=0, u²=0, u³ = c³(−3+2s√3)/18 (s=+1) — both lower
coefficients vanish, both branches. The stated u¹ coefficient 2b_s + s√3/3 − 1
(line 285) is correct and vanishes for s=±1. Numerically (my central difference,
h=10⁻⁵⁰, 120 dps): n³·(d/dt E_n(wt) − w e^{wt}) at w=0.7, t=1 →
0.0146468 (n=10⁴, s=+1) vs my closed-form prediction e^c(w g₃'(c)+w g₃(c)) =
0.0146479; s=−1 → −0.203998 vs −0.204020. Nonzero constants; order 3 preserved.
The remark after Theorem thm:engine (lines 400–408) states preservation
consistently. No "order drop" language anywhere.

**B2. No cosine-at-π / O(N⁻⁶) / "ten digits" claim — CLEAN.**
Flattened-whitespace grep over the whole .tex: no "ten digits", no cos-at-π claim.
The single O(n⁻⁶) occurrence (line 417) is in Discussion as an explicitly *open*
extension ("higher-order kernels with O(n^{-6}) differences … are left open") —
a future-work mention, not a result claim. Fine.

**B3. Pythagorean identity via |E_n(ix)|² = exp(2Re log E_n(ix)) — LANDED, VALID.**
Proof at tex lines 260–273. The route is: |E_n(ix)|² = exp(2Re log E_n) =
exp(2Re g₃(ix)n⁻³ + O(n⁻⁴)) = 1 + 2Re g₃(ix)n⁻³ + O(n⁻⁴), using Thm 2.5(4).
This is valid *because* Definition def:E (lines 117–126) explicitly defines
"log E_n" as the analytic exponent M(u)log B(u) — so exp(2Re log E_n) = |E_n|²
holds by construction (E_n := exp of that exponent), with no modulus-1 complex-power
step; line 270–271 says so explicitly ("This route avoids any claim that a complex
power contributes a modulus-1 factor"). Note Re g₃(ix) needs no Re at all:
g₃(ix) = x⁴(−3+2s√3)/72 is real (i⁴=1), so the identity is clean.
Numerically (mine): n³(|E_n(ix)|²−1) at x=1.1: s=+1 → 0.0188747547 (n=10⁴) vs
target 2g₃ = 0.0188747549; s=−1 → −0.26289142 vs −0.26289142. Confirmed O(n⁻³)
with exactly the predicted constant.

**B4. Corollary cor:const normalisation + asymptotic framing — LANDED, CONSISTENT.**
Lines 215–234: Ã₃ := g₃ is the coefficient of the *normalised* error
e^{−c}(E_n−e^c); the actual-error coefficient is e^c Ã₃ (both statements match my
expansion E_n = e^c(1 + g₃n⁻³ + O(n⁻⁴))). C₁ = |y₀|e^{|a|T}(sup|Ã₃|+1), bounds
stated for n ≥ n₀ with explicit disclaimer ("no unproven finite-n inequality is
asserted", lines 230–234). Internal consistency check (mine, a=1, T=2, y₀=1,
t-grid of 201 points): sup-error ≤ C₁n⁻³ and sup-difference ≤ 3C₁n⁻⁴ hold at every
tested n ∈ {1,2,5,10,50,200} for **both branches** — including n=1, minus branch,
positive base (the v2 failure point): sup err 2.539 ≤ 18.003, sup diff 1.985 ≤ 54.0.
The paper only claims n ≥ n₀ anyway, so the statement is safe with margin.

**B5. Matrix theorem — LANDED, CORRECT, INDEPENDENTLY REPRODUCED.**
Proof (lines 325–351) defines H_n = (nI+b_sX)·Log(I+X/n+s√3X²/(6n²)) and
distinguishes it from the principal log of M_n = exp(H_n) (lines 348–351:
"not necessarily the principal logarithm … differ by 2πi multiples"). Commutativity
(Lemma lem:comm) makes the reduction to the scalar identities exact; the proof
explicitly notes no BCH terms arise (lines 345–346). Correct: everything is a power
series in the single matrix X.
My independent high-precision check (90 dps, my own mat-log/expm code):
- On the paper's A = [[.3,1,.2],[0,−.5,.7],[.1,0,.4]], t=0.8 (‖AᵀA−AAᵀ‖₂ = 1.2855,
  non-normal): n³‖M_n−e^X‖ = 0.0011752 at n=800, trending to my closed-form
  prediction ‖e^X G₃(X)‖ = **0.00117590** — matches the printed ≈0.0011759
  (line 356). n⁴‖M_{n+1}−M_n‖ = 0.0035163 at n=800 → predicted 3×
  = **0.00352770** — matches printed ≈0.0035277 (line 357).
- On MY OWN different non-normal matrix ([[1,2,0],[0,−.3,1],[.5,0,.2]], t=0.6,
  ‖·‖-noncommutativity 4.644): n³ err → 0.010775 vs predicted ‖e^X G₃(X)‖ = 0.010786;
  n⁴ diff → 0.032234 vs 3× = 0.032358. O(n⁻³)/O(n⁻⁴) with the predicted constants
  on a matrix the author never saw. The theorem is right, not just the example.

**B6. Displayed u² coefficient — CORRECT AS PRINTED.**
Lines 161–162 print A₂ = (c³/3 − cα_s) + β_s(α_s − c²/2) = −c³/6 + β_s c² − β_s² c,
and line 165 gives −c³((s√3)²−3)/36. All three verified equal in sympy (see above).
No typo.

**B7. Finite-difference remainder O(u⁵) — LANDED.**
Line 193: "whose O(u^5) truncation error has an O(u^5) successive difference."
Stated as O(u⁵), correctly (the difference of an O(u⁵) analytic remainder is
O(u⁵), which suffices for the O(n⁻⁵) remainder in Lemma lem:fd). The exact rational
identity (u/(1+u))³ − u³ = (−3u⁴−3u⁵−u⁶)/(1+u)³ and the u⁴(−3−3u−u²) factorisation
both verified in sympy.

## The two recent patches (v3 minor-revision items)

**C1. mpf coefficient in mat_log — CONFIRMED, NO LEAK REMAINS.**
verify_ode.py line 109: `L = L + (mpf((-1)**(k + 1)) / k) * term` — the mpf form.
`mpf(±1)/k` is exact-precision division (int divisor promoted), so no binary64
round-off. I scanned the whole file for other float-division leaks: the only other
non-mpf divisions are `1/n` and `(1/2 - s*R3/6)` at line 122, where `n` is already
`mpf` and `s*R3/6` is mpf (so `1/2 - mpf` promotes; `1/2 = 0.5` is exactly
representable in binary64, no precision loss). Symbolic Part 1 uses sympy Rationals.
Clean. Demonstration of the patched vs unpatched difference: at n=400 on the paper's
matrix, max entrywise |L_mpf − L_float-coef| = **3.23e−26** — invisible in the
14-digit printed table but fatal for any 80-digit claim; the patch is substantive,
not cosmetic.

**C2. Narrowed [Lean] labels — CONFIRMED, HONEST.**
- Theorem 2.5(4), line 142: "**[Lean]** (the g₃ identities: u¹,u² vanish, u³=g₃),
  **[num]** (g₄,g₅ and the asymptotics)". Basic.lean indeed proves only
  `u1_coeff_zero`, `u2_coeff_zero`, `u3_coeff_eq_g3` — no g₄/g₅ theorem exists.
  Label matches exactly.
- Derivative lemma, line 281: "**[Lean]** (the u¹ vanishing), **[classical]**
  (the u² vanishing, by differentiating the formalised A₂ identity), **[num]**
  (the O(n⁻³))". Basic.lean has only `deriv_u1_plus`/`deriv_u1_minus` (the u¹
  identity 2b_s + s√3/3 − 1 = 0); no derivative-u² theorem. Label matches exactly.
  (And the [classical] u² claim is true — I verified ∂_c u²-coefficient = 0 in sympy.)

## Lean gate + honesty of the [Lean]/[num]/[classical] labels

- Read Basic.lean in full: 12 audited theorems exactly as listed in Appendix B —
  `lead_eq`, `leadMinus_pos`, `diff_cube_factor`, `diff_cube_lead`, `u1_coeff_zero`,
  `u2_coeff_zero`, `u3_coeff_eq_g3`, `deriv_u1_plus`, `deriv_u1_minus`,
  `pyth_expand`, `g3_one`, `lead_one`. Check.lean does `#print axioms` on all 12.
  Statements match the paper's displayed algebra (I cross-checked each against my
  sympy forms: `u2_coeff_zero` and `u3_coeff_eq_g3` correctly take the hypothesis
  (s√3)² = 3; `pyth_expand` takes s² = 1; `leadMinus_pos` needs c ≠ 0 — all right).
- Ran the gate as instructed (symlinked artin-lean packages):
  **`PASS (12 theorems, standard axioms only)`**, exit 0. Then I touched both .lean
  files to force a genuine rebuild and reran: **PASS again** — the olean cache was
  not doing the work; the proofs actually compile. Gate script (read in full) greps
  for sorry/admit/axiom/native_decide, requires "Build completed successfully",
  requires ≥12 axiom-report lines, and rejects any axiom outside
  propext/Classical.choice/Quot.sound. Sound gate.
- Asymptotics not claimed as Lean-proved: correct throughout — abstract
  (lines 56–59), Basic.lean header docstring, Evidence-tiers paragraph (lines
  436–439), Appendix B (lines 466–468: "The asymptotics … are *not* formalised and
  are tiered [num]"). The Lean file header is unusually candid about what the
  formalisation does and does not cover ("the identification of the expressions as
  *coefficients* uses the classical log series") — the same caveat appears in the
  paper's proof of Thm 2.5. Honest.

## Driver rerun

`python3 verify_ode.py 80` completed in 2.1 s, exit 0, and the output is
**byte-identical** to the shipped `code/verify_output.txt` (`diff` empty). All
Part-2 constants independently reproduced by my own extrapolation (above); Part-3
constants match my prediction ‖e^X G₃(X)‖ to the printed digits; Part-4 trend
matches my independent derivative check.

## Blockers / Should-fix / Nits

**Blockers:** none.

**Should-fix:** none.

**Nits (cosmetic, no action required):**
1. In the Pythagorean proof, "2 Re g₃(ix)" could note that g₃(ix) is already real
   (i⁴ = 1), which would make the displayed constant 2g₃(ix) transparent; harmless
   as written.
2. Definition def:E says "The base carries no factor of c in the exponent" —
   presumably means "the *exponent's* n-part carries no factor of c"; the sentence
   reads slightly off (the base obviously carries c). The following clause
   clarifies, so meaning is recoverable.

## What I checked and found sound

- **Engine algebra** (u¹, u² vanishing; g₃, g₄, g₅; A₂/A₃ displays; −3 factor;
  lead constant; Pythagorean base): all re-derived independently in sympy — sound.
- **Difference constant** −3g₃e^c: 12 (c, s) cases by my own Neville tableau at
  120 dps, incl. negative c and c=3.7 — sound to ≥30 digits.
- **Derivative order preservation** (∂ preserves O(n⁻³)): symbolic + numeric with
  predicted constant matched — sound; paper's framing consistent everywhere.
- **Pythagorean route** via analytic exponent — logically valid (definition makes
  exp(2Re log E_n)=|E_n|² tautological) and numerically confirmed with exact
  predicted constant.
- **Corollary constants** — normalisation correct, asymptotic framing explicit,
  and empirically the bound even holds down to n=1 on both branches.
- **Matrix theorem** — proof structure (analytic log, commutativity, no BCH,
  principal-log caveat) correct; verified on the paper's non-normal matrix AND an
  independent non-normal matrix with closed-form-predicted constants; printed
  constants 0.0011759/0.0035277 confirmed.
- **verify_ode.py** — mpf patch present, no remaining float leaks, output
  reproduces byte-for-byte; leak magnitude demonstrated (3.2e−26 at n=400).
- **Lean** — 12/12 theorems read and matched to paper; gate PASS on a forced clean
  rebuild; standard axioms only; [Lean]/[num]/[classical] tiers accurately narrow.
- **Banned residual claims** (cos π / O(N⁻⁶) result / ten digits) — absent
  (flattened-text search); the one O(n⁻⁶) mention is explicitly open future work.
- **Honesty devices** (Remark rem:sharp on O(·) as bound; Remark rem:complexity
  disclaiming net-work advantage; no uniform-in-time stability claim) — present
  and appropriately hedged.

Recommendation: **ACCEPT** as-is.
