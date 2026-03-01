// Regression test for CGAL convex_hull_3 assertion failure in WebAssembly.
//
// Root cause: WebAssembly does not support fesetround(FE_UPWARD), causing
// CGAL's Interval_nt arithmetic to produce incorrect interval bounds.
// Fix: compile with -DCGAL_ALWAYS_ROUND_TO_NEAREST so CGAL uses
// nextafter() instead of relying on FPU rounding mode.
//
// Without the fix, this triggers:
//   CGAL error: assertion violation!
//   Expression : it != border.end()
//   File       : .../CGAL/convex_hull_3.h
//   Line       : 684

$fn = 64;
hull() {
    cylinder(h = 0.015, d = 1);
    translate([0, 0, 3]) cylinder(h = 0.015, d = 1);
}
