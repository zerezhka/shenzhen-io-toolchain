  slp 1
+ sub acc
  add x3
  mov 0 x1
  mov x2 dat
  tcp dat -1
+ mov dat x0
+ jmp 5
- jmp 1
a:  mov x0 x2
b:  teq x1 8
c:- jmp a
d:+ mov acc x2

