# select target
@ teq 0 0
- teq x2 x1
+ mov dat x0
+ slp 1
+ mov acc x2
  mov x2 acc
  tgt x3 -999
- mov x3 null
+ mov acc x2
a:+ mov x3 dat #x
b:+ mov x3 p1  #y

