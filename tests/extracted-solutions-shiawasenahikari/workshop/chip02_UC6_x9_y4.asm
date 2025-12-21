  slx x2
  mov 0 x1
  mov x2 x0
  tlt x1 p0
+ jmp 3
  mov 0 x1
  mov x2 acc
  mul x0
+ add dat
a:  tlt x1 p0
b:+ mov acc dat
c:+ jmp 7
d:  mov acc x3

