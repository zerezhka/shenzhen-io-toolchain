@ teq 0 0
+ mov x2 acc
+ sub 2
  mov acc x1
  mov x0 dat
  teq x0 dat
+ mov 1 x2
+ jmp e
  teq x1 x3
a:- jmp 6
b:  teq acc p0
c:- sub 1
d:+ mov 0 x2
e:+ slx x2

