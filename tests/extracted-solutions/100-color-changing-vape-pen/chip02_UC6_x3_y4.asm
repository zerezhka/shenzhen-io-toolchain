# Extracted from: New design 1
# Chip 2: UC6 @ (3, 4)
mov x0 acc 
mov acc x1
mov acc x2
mov acc x3
teq acc -999
- mov acc x1 #r
- mov x0 x3  #g
- mov x0 x2  #b
- mov x0 acc
- mov acc x1
- mov acc x3
- mov acc x2
slp 1

