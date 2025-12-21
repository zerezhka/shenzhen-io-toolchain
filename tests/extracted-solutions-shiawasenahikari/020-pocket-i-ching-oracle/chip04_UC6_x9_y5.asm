  tcp p1 0
+ mov 999 dat
+ dst 0 x0
+ slp 1
+ dst 1 x0
+ slp 1
+ dst 2 x0
+ tcp dat 200
- mov acc x3
a:- mov dat x2
b:+ mov acc dat
c:  slp 1
d:+ jmp 3

