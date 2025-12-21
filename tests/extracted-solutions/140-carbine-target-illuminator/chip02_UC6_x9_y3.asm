s:slx x0
mov x0 acc
tlt acc 2
- mov 0 x2
+ mov 100 x2
+ mov 0 p0 #laser
+ mov 0 p1 #f-20
+ jmp s
tgt acc 3
+ mov 100 p0#laser
+ mov 0 p1  #f-20
+ jmp s
- mov 50 p0 #laser
- mov 100 p1 #f-20

