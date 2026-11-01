# Why I chose this project

A car suspension is a useful example of an engineering compromise that people can actually feel. A setting that reduces body movement can transmit more acceleration, and a setting that feels softer can allow more suspension movement or wheel-load variation. I wanted to understand those compromises through a model whose equations I could follow from start to finish.

The quarter-car model offered a manageable starting point. It keeps the body mass, wheel assembly, suspension spring, damper and tyre stiffness, so it still captures two interacting motions. At the same time, it avoids the extra geometry and degrees of freedom of a full-vehicle model. That makes it possible to connect a change in the results to a specific force or parameter.

My central question was: **Can a passive spring–damper combination reduce body acceleration without making suspension travel or tyre-load variation unacceptably worse?** I treated this as a comparison problem, not a search for one setting that is best on every road.

The work therefore goes beyond producing a bump-response plot. It compares three road inputs, varies spring stiffness and damping independently, checks the calculations, and records the rule used to choose a design. The final result is modest but useful: on the chosen multisine input, the selected point reduces acceleration RMS by 7.12%, reduces peak travel by 3.68%, and increases tyre-load RMS by 0.49% relative to the baseline.

The most useful lesson is that a result needs its conditions attached. More damping does not improve every metric, and a softer spring does not guarantee less travel on every input. A numerical improvement becomes meaningful only when the road input, measurement window, constraints and comparison baseline are clear.

For automotive engineering, the value of this project is the modelling process: defining assumptions, deriving force balances, implementing them in two environments, checking consistency and explaining a design trade-off. It is a foundation for further work in ride dynamics and simulation, rather than a production suspension design or a claim about any manufacturer's vehicle.
