  slp 1
  tcp x3 1
- jmp 1
  mov 0 x1
  mov 0 dat
+ mov x3 dat
  mov x1 acc
  teq x0 dat
- jmp 7
a:  mov acc x1
b:  teq dat 0
c:- mov 0 x0
d:+ mov x3 x0
e:  mov dat x2

