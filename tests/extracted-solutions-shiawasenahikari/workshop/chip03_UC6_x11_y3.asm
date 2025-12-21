  slx x1
  mov x1 dat
  mov dat acc
  dgt 2
  mov acc x3
  teq x2 1
+ mov dat acc
+ dgt 1
+ mov acc x3
a:+ teq x2 1
b:+ dst 0 dat
c:+ mov acc x3
d:+ mov x2 x1
e:- mov 0 x1

