  mov 50 p1
  tcp p0 0
+ tgt p0 64
+ mov x2 x3
+ slp 8
+ jmp 2
- tlt p0 51
- mov 100 p1
+ tlt p0 acc
a:- mov p0 acc
b:+ mov p1 acc
c:  slp 1
d:- jmp 7

