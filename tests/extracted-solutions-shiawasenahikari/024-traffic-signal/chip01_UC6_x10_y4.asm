  tcp dat 10
  mov 1 dat
  mov x2 acc
+ mov 10 dat
+ mov x1 acc
- mov 100 dat
- mov x0 acc
  mov dat x3
  sub 1
a:  tcp p0 acc
b:+ mov x3 dat
c:  slp 1
d:- jmp 9

