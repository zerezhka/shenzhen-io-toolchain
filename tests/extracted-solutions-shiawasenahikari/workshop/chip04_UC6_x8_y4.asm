  mov x1 p0
  mov x1 acc
  mov acc p1
  mov acc x1
  teq x3 777
+ slp 1
+ gen p0 p1 1
+ mov 25 p0
+ mov 50 p1
a:+ slp 1
b:+ gen p0 p1 1
c:+ mov 25 p0
d:+ mov 50 p1
e:  slx x1

