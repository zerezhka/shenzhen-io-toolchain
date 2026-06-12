# Extracted from: New design 1
# Chip 5: UC6 @ (11, 6)
slx x3
teq x3 100
+ mov x0 acc
teq p1 100
+ tgt acc 0
+ teq p0 100
+ mov acc x2
+ sub 1
slp 1

