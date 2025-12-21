  slp 1
  mov x1 dat
  tcp dat x2
- mov x0 acc
+ mov 0 x3
+ tcp dat -1
+ dst x1 dat
+ mov acc x0

