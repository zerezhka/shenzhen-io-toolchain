@ mov x0 x2
  mov x0 x2
  mov x3 x1
  teq x1 1
+ add 1
+ mov acc p0
  teq x3 13
+ mul -1
+ add 13
a:+ mov acc x0
b:+ slp 12
c:+ mov x2 acc
d:+ mov acc p0
e:+ mov x0 x2

