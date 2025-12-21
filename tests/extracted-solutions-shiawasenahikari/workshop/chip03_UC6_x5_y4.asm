@ mov -5 x3
  tcp p0 0
+ teq dat 1
+ mov 0 dat
- mov 1 dat
  mov x2 acc
  teq dat 0
+ mov 50 acc
  mul 5
a:  mov acc x1
b:  dgt 1
c:  add x1
d:  mov acc p1
e:  slp 1

