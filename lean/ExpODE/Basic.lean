import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Tactic

/-!
# Exact algebra underlying the telescoping-ODE engine

This file kernel-checks the *exact algebraic identities* on which the paper's
theorems rest. The paper's substantive results (convergence, the `O(n^-4)`
telescoping decay, uniform error bounds) are **asymptotic** statements on
compact sets; those are confirmed by high-precision computation and are labelled
`[num]` in the manuscript, **not** claimed as formalised here. What *is*
formalised is the algebra that determines the parameters and the leading
coefficients — precisely the place a coefficient error would hide.

Paper's parametrisation (the base carries a factor of `c`):

  E_n^(s)(c) = (1 + c/n + s√3 c²/(6 n²))^(n + c(1/2 − s√3/6)),   s = ±1.

Writing `u = 1/n`, `α = s√3 c²/6`, `β = c(1/2 − s√3/6)`, the exponent is
`M(u) = u⁻¹ + β` and `log E_n = M(u)·log(1 + c u + α u²)`. Expanding
`log(1+z) = z − z²/2 + z³/3 − …` (the classical Taylor series of the logarithm)
and collecting powers of `u`, the `u¹` and `u²` coefficients of `log E_n − c`
are the polynomial expressions in `α, β, c` below, and the `u³` coefficient is
`g₃`. This file proves those polynomial identities vanish (resp. equal `g₃`);
the identification of the expressions as *coefficients* uses the classical log
series.
-/

namespace ExpODE

noncomputable section
open Real

/-! ## Engine parameters and the leading coefficient -/

/-- `α = s√3 c²/6` (the `u²` coefficient of the base). -/
def alpha (s c : ℝ) : ℝ := s * Real.sqrt 3 * c^2 / 6

/-- `β = c(1/2 − s√3/6)` (the constant part of the exponent). -/
def betaC (s c : ℝ) : ℝ := c * (1/2 - s * Real.sqrt 3 / 6)

/-- The first surviving log-series coefficient `g₃ = c⁴(−3 + 2s√3)/72`. -/
def g3 (s c : ℝ) : ℝ := c^4 * (-3 + 2 * s * Real.sqrt 3) / 72

/-- Leading difference constant (÷ e^c): `c⁴(3 − 2s√3)/24`. -/
def lead (s c : ℝ) : ℝ := c^4 * (3 - 2 * s * Real.sqrt 3) / 24

/-- `−3 g₃ = lead` (both branches), via `−3·(−3+2s√3)/72 = (3−2s√3)/24`. -/
theorem lead_eq (s c : ℝ) : -3 * g3 s c = lead s c := by
  unfold g3 lead; ring

/-- The `s = −1` branch has `3 + 2√3 > 0`, so its leading constant is strictly
positive for `c ≠ 0`. (The `s = +1` branch has `3 − 2√3 < 0`, i.e. the two
branches carry opposite signs for `c > 0`.) -/
theorem leadMinus_pos {c : ℝ} (hc : c ≠ 0) : 0 < lead (-1) c := by
  unfold lead
  have h4 : 0 < c^4 := by positivity
  have hs : 0 ≤ Real.sqrt 3 := Real.sqrt_nonneg 3
  have : 0 < 3 - 2 * (-1) * Real.sqrt 3 := by linarith
  positivity

/-! ## Finite-difference factor: the `−3` (not `−4`) -/

/-- Exact rational identity `(u/(1+u))³ − u³ = (−3u⁴ − 3u⁵ − u⁶)/(1+u)³`. -/
theorem diff_cube_factor (u : ℝ) (hu : 1 + u ≠ 0) :
    (u / (1 + u))^3 - u^3 = (-3*u^4 - 3*u^5 - u^6) / (1 + u)^3 := by
  have h3 : (1 + u)^3 ≠ 0 := pow_ne_zero 3 hu
  field_simp
  ring

/-- The numerator factors as `u⁴(−3 − 3u − u²)`; leading coefficient `−3`. -/
theorem diff_cube_lead (u : ℝ) :
    -3*u^4 - 3*u^5 - u^6 = u^4 * (-3 - 3*u - u^2) := by ring

/-! ## The log-series coefficient identities (vanishing of `u¹`, `u²`; value of `g₃`)

The `u¹` coefficient of `M(u)·log(1+cu+αu²) − c` is `(α − c²/2) + βc`; the `u²`
coefficient is `(c³/3 − cα) + β(α − c²/2)`; the `u³` coefficient is
`(−α²/2 + c²α − c⁴/4) + β(c³/3 − cα)`. With `α = s√3c²/6`, `β = c(1/2−s√3/6)`
these are `0`, `0`, and `g₃`. -/

/-- The `u¹` coefficient vanishes identically (no side condition). -/
theorem u1_coeff_zero (s c : ℝ) :
    (alpha s c - c^2/2) + betaC s c * c = 0 := by
  unfold alpha betaC; ring

/-- The `u²` coefficient is `−c³((s√3)²−3)/36`, hence vanishes when `(s√3)²=3`. -/
theorem u2_coeff_zero (s c : ℝ) (h : (s * Real.sqrt 3)^2 = 3) :
    (c^3/3 - c * alpha s c) + betaC s c * (alpha s c - c^2/2) = 0 := by
  unfold alpha betaC
  linear_combination (-(c^3/36)) * h

/-- The `u³` coefficient equals `g₃` when `(s√3)²=3`. -/
theorem u3_coeff_eq_g3 (s c : ℝ) (h : (s * Real.sqrt 3)^2 = 3) :
    (-(alpha s c)^2/2 + c^2 * alpha s c - c^4/4) + betaC s c * (c^3/3 - c * alpha s c)
      = g3 s c := by
  unfold alpha betaC g3
  linear_combination (c^4/72) * h

/-! ## Derivative cancellation `∂_c log Eₙ = 1 + O(n^-3)`

The `u¹`-coefficient of `∂_c log Eₙ` is `2 b_s + s√3/3 − 1` with
`b_s = 1/2 − s√3/6`, which vanishes for both branches; the `u²`-coefficient
vanishes likewise. (The derivative is the coefficient of `u¹` in
`∂_c[(u⁻¹+β)·log(1+cu+αu²)]`; we record the elementary vanishing identities.) -/

/-- `b_s = 1/2 − s√3/6` (the `c`-independent part of `β`). -/
def bCoeff (s : ℝ) : ℝ := 1/2 - s * Real.sqrt 3 / 6

/-- The derivative `u¹`-coefficient vanishes: `2 b_s + s√3/3 − 1 = 0`, `s = ±1`. -/
theorem deriv_u1_plus : 2 * bCoeff 1 + (1:ℝ) * Real.sqrt 3 / 3 - 1 = 0 := by
  unfold bCoeff; ring

theorem deriv_u1_minus : 2 * bCoeff (-1) + (-1:ℝ) * Real.sqrt 3 / 3 - 1 = 0 := by
  unfold bCoeff; ring

/-! ## Pythagorean base coefficient

For `c = ix`, `|Bₙ(ix)|² = 1 + x²(1 − s√3/3) u² + (x⁴/12) u⁴` exactly. -/

/-- Exact `u²` coefficient of `|Bₙ(ix)|²`, branch `s`. -/
def pythQuad (s x : ℝ) : ℝ := x^2 * (1 - s * Real.sqrt 3 / 3)

/-- `(1 − s√3 x²u²/6)² + (x u)² = 1 + q_s(x) u² + (x⁴/12) u⁴` under `s²=1`. -/
theorem pyth_expand (s x u : ℝ) (hs : s^2 = 1) :
    (1 - s * Real.sqrt 3 * x^2 * u^2 / 6)^2 + (x*u)^2
      = 1 + pythQuad s x * u^2 + (x^4/12) * u^4 := by
  unfold pythQuad
  have h3 : Real.sqrt 3 ^ 2 = 3 := Real.sq_sqrt (by norm_num)
  linear_combination (x^4 * u^4 / 12) * hs + (s^2 * x^4 * u^4 / 36) * h3

/-! ## Concrete `c = 1` pins -/

theorem g3_one : g3 1 1 = (-3 + 2 * Real.sqrt 3) / 72 := by
  unfold g3; ring

theorem lead_one : lead 1 1 = (3 - 2 * Real.sqrt 3) / 24 := by
  unfold lead; ring

end

end ExpODE
