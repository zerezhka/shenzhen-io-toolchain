# Extracted from: New design 1
# Chip 3: UC4 @ (5, 5)
teq p1 100
- jmp e
i:slp 1
teq p0 100
- add 1
- jmp i
mov acc x1
e:mov 0 acc
slp 1

