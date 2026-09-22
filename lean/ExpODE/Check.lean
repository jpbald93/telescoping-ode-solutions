import ExpODE.Basic

/-! Axiom audit: print the axioms each theorem depends on.
A clean development shows only `[propext, Classical.choice, Quot.sound]`. -/

open ExpODE

#print axioms lead_eq
#print axioms leadMinus_pos
#print axioms diff_cube_factor
#print axioms diff_cube_lead
#print axioms u1_coeff_zero
#print axioms u2_coeff_zero
#print axioms u3_coeff_eq_g3
#print axioms deriv_u1_plus
#print axioms deriv_u1_minus
#print axioms pyth_expand
#print axioms g3_one
#print axioms lead_one
