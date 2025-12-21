  mov x0 dat
  mov dat x1
  tcp dat -1
+ mov x1 acc
+ mov acc x3
+ tgt x2 dat
+ mov acc x3
+ mov x2 x2
+ sub 1
a:+ jmp 5
b:- mov dat x2
c:  slx x0

