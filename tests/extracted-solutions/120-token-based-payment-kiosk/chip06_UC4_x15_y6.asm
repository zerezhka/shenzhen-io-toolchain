# Extracted from: New design 1
# Chip 6: UC4 @ (15, 6)
slx x0
mov x0 null
mov 5 acc
mov 100 p1
ring:  tgt acc 1
+ sub 1
+ slp 1
+ jmp ring
mov 0 p1

