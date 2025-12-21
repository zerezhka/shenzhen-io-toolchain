  mov 50 p1
- slp 1
- sub 1
+ slp 1
+ add 1
  teq dat acc
+ mov 0 x2
+ slx x2
+ mov x2 dat
a:  tcp dat acc
b:- mov 0 p1
c:- slp 1
d:+ mov 100 p1
e:+ slp 1

