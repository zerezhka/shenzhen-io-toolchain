# Extracted from: New design 1
# Chip 5: UC4 @ (12, 6)
start:  slx x0
teq x0 0
+ mov 0 p1
+ mov 100 acc
+ jmp start
mov acc p1
teq acc 0
+ mov 100 acc
- mov 0 acc

