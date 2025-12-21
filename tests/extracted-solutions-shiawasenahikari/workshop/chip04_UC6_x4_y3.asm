  mov x1 dat
  mov dat p1
  mov 0 x0
  mov -1 acc
  add x0
  mov acc x1
  tcp x1 -1
- jmp e
  mov acc x1
a:  mov acc x3
b:+ mov dat x2
c:+ jmp e
d:  mov -1 x2
e:  slx x1

