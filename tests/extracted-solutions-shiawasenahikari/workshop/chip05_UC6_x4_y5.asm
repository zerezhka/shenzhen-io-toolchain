  slx x0
  mov x0 acc
  mov -9 x3
  mov 999 x2
  teq x3 0
- jmp 4
  mov 0 x2
  mov x3 p0
  mov 999 x1
a:  tgt acc 1
b:+ mov x1 x2
c:+ sub 1
d:+ jmp 8
e:  mov x1 x0

