  slx x0
  mov x0 acc
  tgt acc 14
+ mov acc x1
+ jmp b
  mov acc x3
  tgt p0 0
+ mov x0 x2
- mov x2 x0
a:  jmp 1
b:  tgt p0 0
c:+ mov x0 x1
d:- mov x1 x0

