@ mov x2 dat
  add 1
  teq acc dat
+ mov 100 p0
+ mov x2 dat
  slp 1
  tcp x0 p0
+ gen p1 1 0
+ teq acc 49
a:+ mov 1 x3
b:+ gen p1 3 999

