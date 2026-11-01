function [A,B] = qc_matrices(p)
% State order: [body displacement; body velocity; wheel displacement; wheel velocity].
% Row 2 is body force / ms; row 4 is wheel force / mu. Road height enters row 4.
% State order [zs; vs; zu; vu], displacements from static equilibrium.
A=[0 1 0 0; -p.ks/p.ms -p.cs/p.ms p.ks/p.ms p.cs/p.ms; ...
   0 0 0 1; p.ks/p.mu p.cs/p.mu -(p.ks+p.kt)/p.mu -p.cs/p.mu];
B=[0;0;0;p.kt/p.mu];
end
