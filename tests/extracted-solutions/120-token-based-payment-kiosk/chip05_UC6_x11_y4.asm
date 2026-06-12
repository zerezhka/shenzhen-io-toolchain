# Extracted from: New design 1
# Chip 5: UC6 @ (11, 4)
slx x0
add x0
tlt x1 acc
- teq x1 acc
+ sub x1
+ mov acc x2
+ mov 100 x3
+ mov 0 acc

