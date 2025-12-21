mov x0 acc
teq x1 0
- jmp end
teq acc 80
+ mov 30 acc
teq acc 50
+ mov 0 acc
end:  mov acc p1
slp 1

