@ mov x1 null
  mov x0 acc
  tcp acc -1
+ mov acc x1
+ slx x1
+ gen p1 x0 x1
+ gen p0 x0 1
- slp 1

