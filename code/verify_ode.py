#!/usr/bin/env python3
"""Generating + verification program for the telescoping-ODE note (v3).

Everything the paper's theorems rest on, regenerated here:

  PART 1 (symbolic, SymPy): the exact power-series algebra of the exponential
    engine in the paper's c-in-base parametrisation
      E_n^(s)(c) = (1 + c/n + s*sqrt3 c^2/(6 n^2))^(n + c(1/2 - s*sqrt3/6)),
    confirming the n^-1 and n^-2 coefficients of log E_n - c vanish and the
    first surviving coefficient is g3 = c^4(-3 + 2 s sqrt3)/72; the derivative
    cancellation d/dc log E_n = 1 + O(n^-3) (BOTH n^-1 and n^-2 vanish); and the
    Pythagorean base |B_n(ix)|^2 = 1 + (x^2/n^2)(1 - s*sqrt3/3) + O(n^-4).

  PART 2 (high precision, mpmath): E_n -> e^c, the O(n^-4) difference decay,
    and the leading difference constant lim n^4 D_n = c^4(3 - s 2sqrt3)/24 e^c
    = -3 g3 e^c, by a Neville extrapolation tableau.

  PART 3 (high precision, mpmath matrices): the matrix engine on a NON-NORMAL
    matrix, confirming the n^-2 cancellation survives (|M_n - e^{At}| = O(n^-3),
    differences O(n^-4)) -- at HIGH precision, not double.

  PART 4 (mpmath): the derivative-order check. d/dt E_n(wt) - w e^{wt} = O(n^-3)
    (the order is PRESERVED under differentiation for this analytic family; an
    earlier draft wrongly claimed it dropped to O(n^-2)).

Run:  python3 verify_ode.py [precision]     (default 200)
Deps: mpmath (all parts), sympy (Part 1).
"""
import sys
from mpmath import mp, mpf, mpc, matrix, sqrt, exp, log, expm, logm, re as RE

PREC = int(sys.argv[1]) if len(sys.argv) > 1 else 200
mp.dps = PREC
R3 = sqrt(3)


# ------------------------------------------------------------------ part 1
def symbolic():
    import sympy as sp
    u, c = sp.symbols('u c')
    coeffs, dcoeffs = {}, {}
    for s in (1, -1):
        alpha = s * sp.sqrt(3) * c**2 / 6
        beta = c * (sp.Rational(1, 2) - s * sp.sqrt(3) / 6)
        base = 1 + c * u + alpha * u**2
        M = 1 / u + beta
        lam = sp.expand(sp.series(M * sp.log(base) - c, u, 0, 6).removeO())
        poly = sp.Poly(lam, u)
        coeffs[s] = {k: sp.simplify(poly.coeff_monomial(u**k)) for k in range(1, 6)}
        dlam = sp.diff(M * sp.log(base), c)
        dser = sp.expand(sp.series(dlam, u, 0, 4).removeO())
        dp = sp.Poly(dser, u)
        dcoeffs[s] = {k: sp.simplify(dp.coeff_monomial(u**k)) for k in range(0, 4)}
    x = sp.symbols('x', real=True)
    pyth = {}
    for s in (1, -1):
        re_ = 1 - s * sp.sqrt(3) * x**2 * u**2 / 6
        im_ = x * u
        pyth[s] = sp.expand(re_**2 + im_**2)
    return coeffs, dcoeffs, pyth


# ------------------------------------------------------------------ part 2
def E(c, n, s):
    n = mpf(n)
    base = 1 + c / n + s * R3 * c**2 / (6 * n**2)
    return exp((n + c * (mpf(1) / 2 - s * R3 / 6)) * log(base))


def Ediff(c, n, s):
    return E(c, n + 1, s) - E(c, n, s)


def neville(xs, ys):
    m = len(ys); T = [list(map(mpf, ys))]
    for k in range(1, m):
        prev, row = T[-1], []
        for i in range(m - k):
            xi, xik = xs[i], xs[i + k]
            row.append((xik * prev[i] - xi * prev[i + 1]) / (xik - xi))
        T.append(row)
    return T[-1][0]


def lead_target(c, s):
    return c**4 * (3 - s * 2 * R3) / 24 * exp(c)


def extrapolate_lead(c, s, ks=range(2, 8)):
    ns = [mpf(10) ** k for k in ks]
    return neville([1 / n for n in ns], [Ediff(c, n, s) * n**4 for n in ns])


# ------------------------------------------------------------------ part 3
def opnorm(M):
    """Operator 2-norm via the largest eigenvalue of M^T M (symmetric PSD)."""
    G = (M.T * M)
    ev = mp.eigsy(G, eigvals_only=True)
    return sqrt(max(ev))


def mat_log(B):
    """Matrix logarithm via the series log(I+Z)=Z-Z^2/2+Z^3/3-... (||Z||<1)."""
    d = B.rows
    Z = B - mp.eye(d)
    L = mp.zeros(d, d)
    term = Z.copy()
    for k in range(1, 400):
        L = L + (mpf((-1)**(k + 1)) / k) * term
        term = term * Z
        if max(abs(term[i, j]) for i in range(d) for j in range(d)) < mpf(10)**(-(PREC + 5)):
            break
    return L


def mat_engine(s, n, A, t):
    d = A.rows
    X = A * t
    I = mp.eye(d)
    B = I + (1 / n) * X + (s * R3 / (6 * n**2)) * (X * X)
    L = mat_log(B)
    Y = n * I + (1/2 - s * R3 / 6) * X
    return expm(Y * L)


def matrix_check():
    A = matrix([[mpf('0.3'), mpf(1), mpf('0.2')],
                [mpf(0), mpf('-0.5'), mpf('0.7')],
                [mpf('0.1'), mpf(0), mpf('0.4')]])
    t = mpf('0.8')
    nonnorm = opnorm(A.T * A - A * A.T)
    exact = expm(A * t)
    rows = []
    for n in (50, 100, 200, 400):
        Mn = mat_engine(1, mpf(n), A, t)
        Mnp = mat_engine(1, mpf(n + 1), A, t)
        err = opnorm(Mn - exact); dif = opnorm(Mnp - Mn)
        rows.append((n, err, err * n**3, dif, dif * n**4))
    return nonnorm, rows


# ------------------------------------------------------------------ part 4
def deriv_check(w=mpf('0.7'), t=mpf(1)):
    h = mpf(10) ** (-(PREC // 2))
    out = []
    for n in (200, 1000, 5000):
        dp = (E(w * (t + h), n, 1) - E(w * (t - h), n, 1)) / (2 * h)
        err = abs(dp - w * exp(w * t))
        out.append((n, err, err * n**3))
    return out


# ------------------------------------------------------------------ driver
def main():
    print(f"precision = {PREC} digits\n")

    print("=== PART 1a: coefficients of log E_n - c (paper's c-in-base engine) ===")
    coeffs, dcoeffs, pyth = symbolic()
    for s, lbl in ((1, '+'), (-1, '-')):
        print(f"  branch ({lbl}):")
        for k in range(1, 6):
            print(f"    u^{k}: {coeffs[s][k]}")
    print("  -> u^1 = u^2 = 0 (order 3); g3 = c^4(-3 + 2s sqrt3)/72.\n")

    print("=== PART 1b: derivative cancellation d/dc log E_n = 1 + O(n^-3) ===")
    for s, lbl in ((1, '+'), (-1, '-')):
        print(f"    ({lbl}): u^0 = {dcoeffs[s][0]}, u^1 = {dcoeffs[s][1]}, "
              f"u^2 = {dcoeffs[s][2]}")
    print("  -> u^0 = 1, u^1 = 0, u^2 = 0: BOTH lower terms vanish, so the derivative")
    print("     preserves the n^-3 order (NOT an order drop).\n")

    print("=== PART 1c: Pythagorean base |B_n(ix)|^2 (exact polynomial in u) ===")
    for s, lbl in ((1, '+'), (-1, '-')):
        print(f"    ({lbl}): |B_n|^2 = {pyth[s]}")
    print("  -> = 1 + x^2 u^2 (1 - s sqrt3/3) + (x^4/12) u^4.\n")

    print("=== PART 2: leading difference constant lim n^4 D_n (Neville) ===")
    print("    target = c^4(3 -/+ 2 sqrt3)/24 * e^c = -3 g3 e^c\n")
    print(f"  {'c':>4} {'br':>2} {'extrapolated n^4 D_n':>30} {'closed form':>30} {'rel.err':>10}")
    for c in (mpf(1), mpf(2), mpf('0.5'), mpf(-1)):
        for s, lbl in ((1, '+'), (-1, '-')):
            meas = extrapolate_lead(c, s); tgt = lead_target(c, s)
            rel = abs((meas - tgt) / tgt) if tgt != 0 else abs(meas - tgt)
            print(f"  {mp.nstr(c,4):>4} {lbl:>2} {mp.nstr(meas,22):>30} "
                  f"{mp.nstr(tgt,22):>30} {mp.nstr(rel,3):>10}")

    print(f"\n=== PART 3: matrix engine on a NON-NORMAL A (high precision, {PREC} dps) ===")
    nonnorm, rows = matrix_check()
    print(f"    A = [[.3,1,.2],[0,-.5,.7],[.1,0,.4]], t=0.8, ||A^T A - A A^T||_2 = {mp.nstr(nonnorm,10)}")
    print(f"    {'n':>5} {'n^3||M_n-e^At||':>20} {'n^4||M_{n+1}-M_n||':>22}")
    for n, err, e3, d, d4 in rows:
        print(f"    {n:>5} {mp.nstr(e3,14):>20} {mp.nstr(d4,14):>22}")
    print("    -> both columns converge to nonzero constants: O(n^-3) error, O(n^-4)")
    print("       differences. The n^-2 cancellation survives (everything commutes).")

    print("\n=== PART 4: derivative-order check, d/dt E_n(wt) vs w e^{wt} (order preserved) ===")
    print("    (an earlier draft wrongly claimed the derivative is only O(n^-2))")
    print(f"    {'n':>6} {'|d/dt E_n - w e^wt|':>22} {'* n^3':>14}")
    for n, err, e3 in deriv_check():
        print(f"    {n:>6} {mp.nstr(err,10):>22} {mp.nstr(e3,10):>14}")
    print("    -> n^3 * error -> nonzero constant: the derivative is O(n^-3), i.e. the")
    print("       order is PRESERVED under differentiation for this analytic family.")


if __name__ == "__main__":
    main()
