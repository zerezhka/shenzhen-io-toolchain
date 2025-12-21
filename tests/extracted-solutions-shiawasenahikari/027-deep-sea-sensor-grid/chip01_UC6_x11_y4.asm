  slp 1
  mov p1 x0
  mov p0 x0
  teq x2 x3
+ mov x1 acc
+ add x2
+ mov acc x1
+ mov 6 acc
+ mov x0 null
a:+ mov x0 x3
b:+ tcp acc 1
c:+ sub 1
d:+ jmp 9

