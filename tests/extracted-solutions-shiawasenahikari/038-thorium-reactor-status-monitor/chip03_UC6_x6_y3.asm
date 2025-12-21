  mov x0 acc
  tgt p1 x0
+ dst 1 1
  mov acc x2
  tgt p0 x0
- dst 1 -2
+ dst 1 2
  mov acc x2
  teq x1 12
a:+ slp x0    #1
b:+ mov x0 x2 #-30

