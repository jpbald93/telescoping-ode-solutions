# Telescoping ODE v3 — adversarial audit

## Verdict (MINOR REVISION)

**Final verdict:** the specified v2 mathematical blockers are fixed. The engine, derivative/energy order, modulus argument, eventual constants, and matrix proof are sound; the Lean gate passes twelve theorems. Remaining changes are a reproducible binary64 coefficient leak in the new mpmath matrix-log routine and narrowly overbroad formal-evidence labels. Full findings follow the retained audit-progress notes below.

### Initial provisional note (retained audit trail)
Verification in progress. The full 526-line TeX has been read. The main differentiation, trigonometric-modulus, normalization, and matrix-log corrections are visibly present; independent symbolic/numerical checks and the Lean gate remain to be run. No blocker established at this stage.

First observations: TeX lines 278–291 and 400–407 explicitly preserve order three under analytic differentiation; lines 262–274 replace the invalid modulus-factor proof with the analytic-log argument; lines 216–235 explicitly normalize the leading coefficient and restrict the inequalities to sufficiently large n. The finite-difference prose at lines 191–194 now says “O(u^5)” but needs close checking against the actual truncation used. Final findings and numerical evidence will be appended below.

### Verification update
The supplied driver at 80 digits completed and reproduced its saved output. The requested gate returned **PASS (12 theorems, standard axioms only)**. Independent SymPy polynomial expansion confirms the cancellations, g3–g5, derivative order, and leading-difference factor. Independent mpmath matrix `logm`/`expm`/SVD confirms the claimed limiting constants 0.001175900184726257862… and 0.003527700554178773586… . The old substantive blockers are repaired.

One reproducible new implementation defect is present: `code/verify_ode.py:109` evaluates `((-1)**(k + 1) / k)` in binary64 before multiplying the arbitrary-precision matrix. The published small-n table remains sound to its important digits, but this is not an all-high-precision log series: at n=10^15 the supplied scaled matrix error is 0.0048975800951677 versus 0.00117590018472626 with an exact mpmath coefficient. This warrants a small code correction, not rejection of the theorem. Provisional final verdict: **MINOR REVISION**. Detailed final audit follows.

## Did the v2-audit fixes land?

Line references below are to `v3/telescoping_ode.tex` unless a code/Lean filename is specified. I read all 526 TeX lines, inspected the v2→v3 diff, flattened whitespace before absence searches, ran the supplied driver at both 80 and 200 digits, and wrote independent SymPy/mpmath checks. Numerical values below are fresh computations, not copied from the previous audit.

### 1. False order-drop claim — FIXED

**Text:** lines 278–280 state “∂/∂c log E = 1 + O(n^-3)” and the consequent derivative error; lines 288–291 explicitly say “differentiation preserves the n^-3 order.” The “Differentiation and order” remark at 400–407 repeats the correct result, and the energy proposition at 295–300 now says O(n^-3).

My independent expansion gives

\[
\partial_c\log E_n^{(s)}(c)
=1+0u+0u^2+\frac{c^3(-3+2s\sqrt3)}{18}u^3+O(u^4).
\]

Writing K_s=(-3+2s√3)/72, the signed derivative-error limit is

\[
\lim n^3\{\partial_t E_n^{(s)}(wt)-we^{wt}\}
=w e^{wt}K_s[(wt)^4+4(wt)^3].
\]

For w=.7, t=1, I differentiated the explicit analytic formula and cross-checked with `mp.diff` at 100 digits:

| n | plus-branch signed scaled derivative error | minus-branch signed scaled derivative error |
|---:|---:|---:|
| 200 | 0.0145904763782686691 | −0.202922399925902723 |
| 1,000 | 0.0146364276169692795 | −0.203799271791637932 |
| 5,000 | 0.0146456415621185367 | −0.203975477759490335 |
| 1,000,000 | 0.0146479347605104910 | −0.204019352250239189 |
| analytic limit | **0.0146479462853579958** | **−0.204019572768625383** |

Driver Part 4 reproduces the plus-branch values at its printed precision. Analyticity jointly in c and u, on a slightly larger compact c-neighborhood, justifies differentiating the remainder; this is not an inference from arbitrary pointwise big-O. Differentiating the analytic successive-difference expansion likewise preserves the order-four difference estimate.

For the actual oscillator, I also checked y0=1, v0=.3, w=.7, t=1. The signed n^3 energy errors at n=200,1000,5000 are −0.000531460668914, −0.000530062075810, −0.000529780939781. The O(n^-3) energy assertion is sound. The proof can use C¹ convergence directly; it does not need to treat y_n' as exactly the rotated trigonometric approximant.

**Small wording qualification:** the derivative u coefficient before substitution is c(2b_s+s√3/3−1), not just the parenthesis printed at 285–286. Both are zero for the prescribed parameters, so this omission does not change any result. Formal-label scope is discussed under fix 5.

### 2. False cos-at-π claim — REMOVED

After flattening all TeX whitespace, there is no surviving cosine-at-π/ten-digit claim. The only `\\pi` occurrence is the unrelated matrix-log “2πi” at line 349. The remaining O(n^-6) at 416 is explicitly a possible **future higher-order kernel**, not a claim about this cosine approximant. Lines 197–200 now use only c=0 as the degeneracy example.

Independent guard check: at n=10 the cosine errors are 0.000591538050344647927 (plus) and 0.007554218069420590729 (minus). At n=1,000,000,

- n^3(C_n^+(π)+1) = −0.627884951079322988, with limit −0.627884951083070835;
- n^3(C_n^−(π)+1) = 8.74530920378467416, with limit 8.74530920391660727.

Thus removing, rather than relocating, the false special-point claim was the correct repair.

### 3. Invalid complex-modulus proof — FIXED

Lines 262–268 now use

> “|E_n(ix)|² = exp(2 Re log E_n(ix))”

and obtain 1+2 Re g3(ix)n^-3+O(n^-4). This is valid with the analytic logarithm explicitly defined at 123–127; it does not require the principal logarithm of E_n. The phrase “modulus-$1$ factor” survives only in an explicit **disavowal** at 270–271, not as an asserted equality.

At x=1 my computed n^3(|E_n(ix)|²−1) is:

| n | plus | minus |
|---:|---:|---:|
| 100 | 0.0128909319622525781 | −0.179530919364203548 |
| 10,000 | 0.0128917114536370527 | −0.179558375453620885 |
| 1,000,000 | 0.0128917115315964974 | −0.179558378197996497 |
| 2 Re g3(i) | **0.0128917115316042941** | **−0.179558378198270961** |

The polynomial base identity at 272 is correct and no longer used to discard the complex exponent's non-unit modulus factor.

### 4. Mis-normalized A3 and false finite-n bound — FIXED

Lines 216–220 explicitly distinguish the normalized coefficient \(\tilde A_3=g_3\) from the actual error coefficient \(e^c\tilde A_3\). Lines 221–227 restrict the two inequalities to n≥n0 and use

\[
C_1=|y_0|e^{|a|T}(\sup|\tilde A_3|+1),\qquad C_2=3C_1.
\]

Lines 231–235 expressly disclaim an exact global finite-n constant. Uniform analytic expansions supply remainder bounds that can simultaneously be made ≤1 for the normalized error and ≤3 for the scaled difference by increasing n0. The finitely many branches can share n0 if desired. The factor |y0| factors out, including the trivial y0=0 case. The supremum over the stated real interval also bounds complex c with |c|≤|a|T because g3 is a constant times c^4.

I reran the old positive-base test: a=y0=1, T=.8, s=−1, t=−.8, n=1. The base is 0.0152479138593197554 and the error is 0.235780802594087084. The old C1 was 0.0818410536415194330; the new enlarged C1 is **2.30738198213398704**. This example is no longer a contradiction, both because the statement is eventual and because the enlarged constant already exceeds this particular n=1 error. No new global bound has been smuggled into the corollary.

### 5. Missing Lean coefficient identities — CORE FIX LANDED; narrow two local labels

The actual new statements are nonvacuous polynomial equalities:

- `Basic.lean:84–86`, `u1_coeff_zero`: (α−c²/2)+βc=0, all real s,c, proved by `ring`.
- `Basic.lean:89–92`, `u2_coeff_zero`: (c³/3−cα)+β(α−c²/2)=0 under (s√3)²=3, proved by `linear_combination (-(c^3/36)) * h`.
- `Basic.lean:95–99`, `u3_coeff_eq_g3`: (−α²/2+c²α−c⁴/4)+β(c³/3−cα)=g3 under the same hypothesis, proved by `linear_combination (c^4/72) * h`.

The parameters and g3 definitions at `Basic.lean:38–44` match the manuscript. My symbolic residuals for the last two formulas are respectively −c³(q²−3)/36 and c⁴(q²−3)/72, q=s√3, so the hypotheses are exactly the intended ones. They hold for s=±1. These are real polynomial identities; use for complex c or a single commuting matrix is the classical polynomial-extension argument, not a separately formalized Lean theorem.

The requested gate returned **PASS (12 theorems, standard axioms only)**. I also ran `lake env lean ExpODE/Basic.lean` directly and separately printed the axioms via `Check.lean`; all twelve reported only propext, Classical.choice, Quot.sound. The abstract at 51–56 and the detailed cancellation proof at 169–172 now accurately distinguish formal polynomial algebra from the classical identification as Taylor coefficients. The explicit exclusion of formal asymptotics at 435–438 and 462–463 is correct.

**Remaining local precision issue, not the old missing-engine-proof blocker:**

1. The trailing “[Lean] (coefficient identities)” at 142 follows the g4 and g5 formulas as well as g3. There is no Lean theorem for g4 or g5. Those formulas are correct (my independent SymPy check and the driver verify them), but specify “[Lean: A1=0, A2=0, A3=g3]” rather than allowing the tag to cover all displayed coefficients.
2. The derivative lemma's “[Lean] (the u¹,u² vanishings)” at 281 is broader than the derivative-specific statements in the file: `deriv_u1_plus/minus` at `Basic.lean:112–116` prove only the elementary u¹ parenthesis is zero. The u² derivative vanishing follows **classically** by differentiating the now-formalized A2 polynomial identity, but there is no theorem stating that differentiated identity or formal differentiation step. Either describe exactly that split or add the tiny derivative-u² identity. This is a scope-label repair; it does not invalidate the derivative conclusion.

### 6. Displayed u² coefficient typo — FIXED

Lines 161–165 now print

\[
A_2=(c^3/3-c\alpha_s)+\beta_s(\alpha_s-c^2/2)
=-c^3/6+\beta_s c^2-\beta_s^2c
=-c^3((s\sqrt3)^2-3)/36.
\]

My independent symbolic residual against this expression is **exactly zero**, before imposing q²=3. Reduction modulo q²−3 gives **zero**. The equality from the first to second form uses A1=0, which is already established. This is the correct coefficient, not a dimensionally mismatched leftover from v2.

### 7. Matrix analytic-log notation/branch — FIXED

Lines 327–331 define H_n as the exponent constructed from the **principal logarithm of the base** and explicitly set M_n=exp(H_n). Lines 338–344 consistently expand H_n−X, not an unjustified principal Log M_n. Lines 347–349 explicitly distinguish the two logarithms.

For sufficiently large n uniformly in compact t, the base is norm-close to I, so its logarithm is a convergent power series in X. Hence H_n, X, and their remainders commute. The polynomial coefficient identities carry over to any X, including non-normal or defective matrices. Therefore exp(H_n)=e^X exp(H_n−X) is exact, with no BCH correction. The Jordan-form alternative at 335 is sufficient; no simultaneous eigenbasis is being assumed for every matrix.

The independent non-normal-matrix numbers under fix 9 support this proof. Its non-normality norm is **1.28548523755746707337**. I find no new branch or commutator problem.

### 8. Finite-difference remainder — CONCLUSION FIXED; prose should be made exact

The old “difference of O(u⁴) is itself O(u⁴)” text is gone. Lines 191–194 now say:

> “a convergent power series whose O(u^5) truncation error has an O(u^5) successive difference.”

That sentence is not false: a tail starting at u⁵ has an O(u⁶) difference, which is also O(u⁵). It is, however, an awkward repair because the preceding displayed expansion has an O(u⁴) tail. Write explicitly that an **analytic O(u⁴) tail has O(u⁵) difference**, or retain the g4u⁴ term and then truncate at O(u⁵).

My independent exact series calculations give

\[
(u/(1+u))^4-u^4=-4u^5+10u^6+O(u^7),
\]
\[
(u/(1+u))^5-u^5=-5u^6+15u^7+O(u^8).
\]

More generally R(u)=u⁴h(u), h analytic, has R'(u)=O(u³); since u/(1+u)−u=O(u²), its difference is O(u⁵). This supplies exactly the remainder in 183–184 and the matrix analogue at 344. There is **no residual mathematical obstruction** here.

Also replace “the base is smooth and positive near u=0” at 192 by “the base is analytic and near 1, avoiding the logarithm cut.” Positivity is only meaningful for real c,u; the theorem includes complex c. The correct near-1 branch condition is already stated at 121–127.

### 9. High-precision matrix table — SUBSTANTIVE FIX LANDED; one float leak remains

The driver no longer uses NumPy/SciPy doubles for its matrix calculations. Part 3 uses mpmath matrices, `expm`, and a 2-norm via `eigsy` (`verify_ode.py:94–139`). My fresh 80-digit output exactly matches `code/verify_output.txt`; the default 200-digit run prints the same table. Thus the previous visibly roundoff-dominated table is repaired.

Independent 100-digit matrix `logm`/`expm` and SVD results, avoiding the author's custom logarithm series:

| n | n³‖M_n−e^X‖₂ | n⁴‖M_{n+1}−M_n‖₂ |
|---:|---:|---:|
| 50 | 0.00116549883294440982 | 0.00335161942992398126 |
| 100 | 0.00117068130554673281 | 0.00343795860558237373 |
| 200 | 0.00117328617598663095 | 0.00348239318612859335 |
| 400 | 0.00117459203576779132 | 0.00350493635165569459 |
| 1,000 | 0.00117537665014636702 | 0.00351856816430813808 |
| 10,000 | 0.00117584781475783707 | 0.00352678570596801802 |
| predicted limit | **0.00117590018472625786** | **0.00352770055417877359** |

I computed the limits directly from ‖e^XG3(X)‖₂ and three times that norm, not by accepting a short finite-n table as an exact limit. They agree with manuscript 355–356.

**New reproducible implementation defect:** `verify_ode.py:109` uses

```python
L = L + ((-1)**(k + 1) / k) * term
```

Python evaluates the integer division as a binary64 float **before** mpmath multiplication. For example, float(1/3)−(1/3) at arbitrary precision is −1.85037170770859423404×10^-17. This introduces an O(epsilon_float/n²) error in the matrix exponent via the u³ log term. Increasing `mp.dps` does not remove it.

On the paper's own matrix, at 100-digit arithmetic:

| n | supplied n³ matrix error | same algorithm with exact mpmath coefficients |
|---:|---:|---:|
| 400 | 0.00117459203576543762 | 0.00117459203576779132 |
| 10^8 | 0.00117589959194868441 | 0.00117590017948907754 |
| 10^12 | 0.00117002585961625211 | 0.00117590018472573414 |
| 10^15 | 0.00489758009516769787 | 0.00117590018472625734 |

At n=400 the norm of the **scaled matrix discrepancy** is only 2.42071214304×10^-15, so this defect does not refute the existing table's order evidence. At very large n it defeats the advertised arbitrary-precision benefit. Minimal fix:

```python
L += (mpf((-1)**(k + 1)) / k) * term
```

or use `mp.logm(B)`. Regenerate the saved output afterward. The exactly representable 1/2 at line 122 is not the problem, and `1/n` is high precision in this driver because n is passed as `mpf` at 135–136.

### 10. Engine spot-check — SOUND

I expanded a finite polynomial for log(1+cu+αu²), multiplied by u^-1+β, and reduced coefficients modulo q²−3, q=s√3. This independently gives

\[
[g_1,g_2,g_3,g_4,g_5]
=\left[0,0,\frac{c^4(2q-3)}{72},\frac{c^5(39-25q)}{720},\frac{c^6(11q-18)}{270}\right].
\]

The algebraic residual in

\[
-3g_3=\frac{c^4(3-2s\sqrt3)}{24}
\]

is exactly zero. Exponentiation therefore gives the actual leading difference constant \(-3e^c g_3\), with no missing normalization factor.

At c=1 the predicted limits are −0.05256495779114381858 (plus) and 0.73213541490590512742 (minus); my direct n=1,000,000 scaled differences are −0.05256478770570441136 and 0.73213270776444803582, respectively. The supplied Neville extrapolation independently agrees with the predicted constants to its reported roughly 25-digit relative accuracy. The engine remains sound.

## Any NEW problems introduced by v3?

**One substantive implementation issue, minor to repair:** the binary64 coefficient leak in the newly introduced mpmath matrix-log series (`verify_ode.py:109`), quantified above. It affects precision claims and very-large-n use, not the proved matrix theorem or the numerical trend in the published n=50…400 table.

**One new local formal-scope overstatement:** the expanded derivative “[Lean] (the u¹,u² vanishings)” tag at 281 does not distinguish the classical differentiation of the formal A2 identity from a theorem actually present in Lean. Narrow it; the derivative mathematics is correct. The g4/g5 trailing tag is a remaining scope ambiguity, not a newly false formula.

No new mathematical counterexample to the engine, derivative/energy order, trigonometric result, asymptotic corollary, or matrix reduction was found. I do not count a true-but-nonsharp O(u⁵) bound as a false statement. I also do not treat the explicit denial of a modulus-1 factor as a surviving assertion of that factor.

## Engine re-derivation + Lean gate result

**Engine:** independent symbolic derivation confirms zero u¹,u² coefficients; the displayed g3,g4,g5; ∂c log E=1+O(n^-3); and the actual difference coefficient −3e^c g3. Independent high-precision computations confirm real derivatives, oscillator energy, complex modulus/cosine, and the non-normal matrix limits.

**Lean:** the exact user-specified setup and `./gate.sh` produced:

```text
PASS (12 theorems, standard axioms only)
```

I independently elaborated `ExpODE/Basic.lean` and ran `ExpODE/Check.lean`. The latter prints twelve dependencies, all `[propext, Classical.choice, Quot.sound]`. No polynomial claim in the three newly added coefficient theorems was found vacuous or mis-parametrized. The gate is a build/axiom gate, not a formal proof of asymptotic analysis; the main manuscript now says so accurately.

**Reproduction artifacts** saved beside this report:

- `AUDIT_astra_telescoping_ode_v3_independent.py` — independent SymPy/mpmath audit plus isolated supplied-code comparison for the float leak.
- `AUDIT_astra_telescoping_ode_v3_independent.txt` — complete numerical/symbolic results.
- `telescoping_v3_driver_80.txt` and `telescoping_v3_driver_200.txt` — fresh supplied-driver runs.
- `telescoping_v3_lean_basic.txt` — direct Lean elaboration output (empty on success).
- `telescoping_v3_lean_axioms.txt` — independent twelve-theorem axiom printout.

Audited TeX SHA256: `d693c2b9a4bb36fb12fc70d64c310565ad30098b68eebddbd94359350bcdd5b2`.
Audited driver SHA256: `27849a275afa4282a2944679908be3bd967c5a8bcd9b49d9b1e750995e5a97fd`.
Audited `Basic.lean` SHA256: `00d1b9308335c116cfeb40e59c71fdd034bdbe56e4447670827049a039682dba`.

## Blockers / Should-fix / Nits

### Blockers

**None remaining from the specified v2 audit.** The original reason for MAJOR REVISION has been removed: the engine is valid, and the substantively false derivative, cosine, modulus, normalization, finite-n-bound, and missing-engine-algebra claims have been corrected.

### Should-fix before acceptance

1. **Make the matrix-log series genuinely arbitrary precision** by fixing `verify_ode.py:109`; regenerate output. This is a one-line numerical-code correction, supported by an explicit independent counterexample to the precision claim.
2. **Narrow formal-evidence labels** at TeX 142 and 281 to the actual theorems proved. Do not imply g4/g5 or formal differentiation has been kernel-checked. No new asymptotics formalization is required.

### Nits / clarifications

- At 191–194, explicitly say analytic O(u⁴) tails have O(u⁵) successive differences; the changed O(u⁵)-truncation sentence is true but obscures the needed reasoning.
- Replace “positive” by “near 1 and off the branch cut” at 192 for complex c.
- At 285–286, restore the harmless factor c in the pre-cancellation derivative-u¹ coefficient, or call the displayed expression its c-independent factor.

## What I checked and found sound

- All five displayed log-series coefficients and both branch cancellations.
- The order-three derivative and oscillator-energy corrections.
- Removal of the false cosine-at-π/ten-digit claim, verified on whitespace-flattened TeX.
- The new squared-modulus proof, including the analytic-log convention.
- Normalized versus actual leading-error constants and the enlarged eventual inequalities.
- All three new Lean coefficient-identity theorem statements and their kernel-checked proofs.
- The twelve-theorem gate and explicit asymptotics-not-formalized disclaimer.
- The H_n matrix proof, locally valid principal logarithm of the base, commutativity, and norm-uniform expansion on compact time intervals.
- The restored stable matrix trend and both advertised matrix limiting constants, independently recomputed.
- The finite-difference factor −3 and the O(n^-5) remainder justified by analyticity.

**Final recommendation: MINOR REVISION.** The required remaining changes are a small precision fix and evidence-label/prose cleanup, not a reworking of the mathematics.
