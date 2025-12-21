@ mov 100 p1
  mov x2 x2
  mov x2 acc
  mov acc x0
  teq x1 10
+ slx x2
  tcp x1 10
- add 1
- mov acc p0
a:+ sub 1
b:+ mov acc p1
c:  slp 9

