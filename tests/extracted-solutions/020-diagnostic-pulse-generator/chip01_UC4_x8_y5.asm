# Extracted from: New design 1
# Chip 1: UC4 @ (8, 5)
teq p0 0
+ mov 0 p1
+ mov 100 acc
+ jmp end
- mov acc p1
- teq acc 0
+ mov 100 acc
- mov 0 acc
end:  slp 1

