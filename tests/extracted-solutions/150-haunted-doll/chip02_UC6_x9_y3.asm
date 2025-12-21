@ mov 50 p1
slx x3
mov x3 dat
mov 13 acc
i:teq dat 0
+ mov x0 p1
- mov x2 p1
slp 1
sub 1
tlt acc 0
- jmp i


