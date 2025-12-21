@ teq 0 0
+ mov x1 dat
+ mov 0 x1
  mov x1 acc
  tlt acc dat
- mov acc x2
+ mov dat x2
+ mov acc dat
  mov x3 x1
a:  teq x3 10
b:+ mov -999 x0
c:+ slx x1
d:+ mov 0 x3

