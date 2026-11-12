class_name Inp
extends RefCounted

# One frame of a player's input, packed into an int. Humans, the CPU and test
# scripts all drive fighters through this same format.

const LEFT := 1
const RIGHT := 2
const UP := 4
const DOWN := 8
const P := 16  # punch
const K := 32  # kick
const H := 64  # heavy
const S := 128  # special
