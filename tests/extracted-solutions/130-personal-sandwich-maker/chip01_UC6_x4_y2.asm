# Extracted from: New design 1
# Chip 1: UC6 @ (4, 2)
slx x0
mov x0 acc
mov acc x3
teq acc 1
+ mov 3 x1
teq acc 2
+ mov 2 x1
teq acc 3
+ mov 4 x1
slp 1
gen p1 1 0

