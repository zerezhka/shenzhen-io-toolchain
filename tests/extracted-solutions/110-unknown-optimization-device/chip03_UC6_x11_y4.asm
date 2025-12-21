# 40<x<60
mov 0 p1
end:  slx x0
mov x0 null
mov p0 acc
tlt acc 40
+ jmp kill
- tgt acc 79
+ jmp kill
- mov 50 p1
kill:
+ mov 0 p1
slp 1

