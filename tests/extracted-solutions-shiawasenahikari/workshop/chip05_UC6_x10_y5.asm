@ teq 0 1
- slx x1
- mov x1 dat
- mov 25 acc
  mov acc x0
  mul acc
  tgt acc dat
+ mov x0 acc
+ sub 1
a:- mov x0 x2

