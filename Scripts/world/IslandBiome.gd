class_name IslandBiome
extends Area2D

# Base class for overworld biome regions.
#
# Each biome is an Area2D whose CollisionPolygon2D children mark out a region of the
# island. Subclasses declare `biome_name`, `biome_priority` and `speed_modifier`;
# PlayerDot keeps a list of every biome it currently overlaps and uses the one with
# the highest `biome_priority` (see PlayerDot.get_highest_priority_biome).
#
# Detection is driven entirely by PlayerDot's PlayerDetectionArea, which listens for
# area_entered / area_exited. Biome areas must NOT connect their own body_entered /
# body_exited signals — that would report from a different overlap volume than the
# detection area and give inconsistent results.
#
# NOTE: `biome_priority` is our own property. Area2D also has a built-in `priority`,
# which only orders physics space overrides (gravity/damping) and has no effect on
# biome ranking. Setting that one by mistake silently does nothing.
