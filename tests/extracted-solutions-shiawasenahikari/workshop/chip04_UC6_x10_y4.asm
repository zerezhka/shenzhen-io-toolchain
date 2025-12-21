@ mov x3 p1
  slx x2
  mov x2 dat
  mov p0 acc
  sub x2
  mov acc x1
  mov x0 acc
  tlt acc dat
+ add 1
a:+ mov acc x2
b:- mov dat x2

