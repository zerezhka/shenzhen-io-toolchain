  teq acc dat
- mov 0 x3
+ mov 1 x3
+ slx x0
+ mov x0 acc
+ mul -1
+ mov acc dat
+ mov x1 x3
  mov p0 acc
a:  mul x3
b:  mul x3

