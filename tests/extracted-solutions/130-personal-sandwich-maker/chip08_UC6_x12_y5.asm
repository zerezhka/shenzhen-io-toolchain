# Extracted from: New design 1
# Chip 8: UC6 @ (12, 5)
slx x0
mov x0 acc
slp 2
teq acc 1
+ gen p1 1 0
+ gen p0 1 0
teq acc 2
+ gen p0 1 0
teq acc 3
+ gen p1 1 0
+ gen p0 2 0

