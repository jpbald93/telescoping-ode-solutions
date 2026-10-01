import ExpODE

/-! Satisfiability certificates (outside the library; not imported by it).
For every theorem with hypotheses: a Lean-checked example showing those hypotheses can all be met
simultaneously by concrete values. Theorems whose conclusion is `False` assert that their hypotheses
are jointly impossible; for those we certify that every hypothesis but the last is satisfiable,
so the impossibility is not caused by a trivially inconsistent subset. -/

set_option linter.unusedVariables false
set_option linter.unnecessarySeqFocus false
set_option linter.style.longLine false

-- hypotheses of ExpODE.leadMinus_pos are satisfiable
example : ∃ (c : ℝ) (hc : c ≠ 0), True :=
  ⟨1, by norm_num, trivial⟩

-- hypotheses of ExpODE.diff_cube_factor are satisfiable
example : ∃ (u : ℝ) (hu : 1 + u ≠ 0), True :=
  ⟨1, by norm_num, trivial⟩

-- hypotheses of ExpODE.u2_coeff_zero are satisfiable
example : ∃ (s c : ℝ) (h : (s * Real.sqrt 3)^2 = 3), True :=
  ⟨1, 0, by rw [one_mul, Real.sq_sqrt]; norm_num, trivial⟩

-- hypotheses of ExpODE.u3_coeff_eq_g3 are satisfiable
example : ∃ (s c : ℝ) (h : (s * Real.sqrt 3)^2 = 3), True :=
  ⟨1, 0, by rw [one_mul, Real.sq_sqrt]; norm_num, trivial⟩

-- hypotheses of ExpODE.pyth_expand are satisfiable
example : ∃ (s x u : ℝ) (hs : s^2 = 1), True :=
  ⟨1, 0, 0, by norm_num, trivial⟩
