  tcp p0 0
+ mov 0 x1  #LCK
+ mov x0 dat#REL
  tcp acc 0
+ mov x2 p1
+ sub 1
+ jmp e
  teq x2 1
+ mov x2 acc
a:+ jmp 5
b:  teq x2 x3
c:- mov 50 p1
d:+ mov dat x3
e:  slp 1

