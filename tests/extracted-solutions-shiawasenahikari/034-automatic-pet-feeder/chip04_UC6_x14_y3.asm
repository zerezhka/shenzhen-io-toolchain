# Feed cat if feed
# signal received
  slx x1
  mov x2 acc
  tcp x1 2
- mov x0 acc
+ mov x3 acc
  tcp x1 50
- mov acc p0
+ mov acc p1
  slp 1
a:  mov p0 p1

