  slx x1
  mov x1 acc
  tcp acc 100
+ mov acc dat
  tcp dat x0
+ mov acc x0
+ jmp 1
- mov acc x2
- slx x1
a:- mov x1 acc
b:- tcp acc 100
c:- jmp 8
d:+ jmp 4
e:  mov acc x3

