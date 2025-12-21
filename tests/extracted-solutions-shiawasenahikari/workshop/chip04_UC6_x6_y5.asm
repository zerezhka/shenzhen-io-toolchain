@ tlt p0 28
+ mov 0 p1
+ jmp d
  tlt p0 x0
- tlt p0 x2
+ mov p0 acc
+ sub x1
+ sub x3
+ add 26
a:+ mov acc p1
b:+ mov 0 x1
c:+ mov 0 x3
d:+ slp 1
e:+ tlt p0 28

