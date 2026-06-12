# Extracted from: New design 1
# Chip 4: UC6 @ (5, 4)
teq -1 x0
- jmp end
mov p0 x3 #x
mov p1 x3 #y
teq 100 x2 #a
+ add 1
teq 100 x2 #b
+ add 2
mov acc x3
tgt acc -3 #clr
end: mov 0 acc
- mov x2 null
- mov x2 null
slp 1

