  mov x3 dat
  tcp dat -999
+ teq dat 12
- mov x3 null
+ teq x3 1
- mov x3 null
+ teq x3 89
- mov x3 null
+ teq x3 53
a:- mov x3 null
b:+ mov x3 x2
c:- mov x3 x2
d:  slp 1
e:- slp p0

