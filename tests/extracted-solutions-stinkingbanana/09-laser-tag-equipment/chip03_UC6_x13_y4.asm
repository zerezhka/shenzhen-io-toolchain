mov x3 dat
mov 0 p1
teq dat 101
+ mov x0 acc
teq dat 1
+ mov x0 acc
teq dat 110
+ sub 1
- jmp end
tlt acc 0
+ mov 0 acc
- mov 100 p1
end: slp 1

