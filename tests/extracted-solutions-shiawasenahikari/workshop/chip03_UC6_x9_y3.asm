  mov p0 acc
  mov x1 x3
  mul x2
  mov acc p1
  mov x0 acc
  slp 1
  tcp x0 acc
- mov dat x1
+ mov 1 dat
a:  tcp x0 5
b:+ tcp p0 dat
c:+ mov p0 dat

