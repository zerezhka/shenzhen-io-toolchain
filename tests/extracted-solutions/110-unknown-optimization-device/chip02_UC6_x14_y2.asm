# 60<x<80
mov 0 p1
end:  slx x1
mov x1 null
mov p0 acc
tlt acc 40
+ jmp kill
tgt acc 79
+ jmp kill
- mov 80 p1
kill:
+ mov 30 p1
slp 1

