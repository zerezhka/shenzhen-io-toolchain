  teq p0 50
- mov p0 x0
+ tgt x1 0
- mov p0 p1
+ mov x1 acc
+ sub 1
+ mov acc x1
+ mov x0 p1
  slp 1
a:+ mov acc x1

