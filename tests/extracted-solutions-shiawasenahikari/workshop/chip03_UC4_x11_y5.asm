  mov x0 acc
  tlt acc 128
- mov 100 x1
+ teq acc x1
+ mov 10 x1
  slx x0

