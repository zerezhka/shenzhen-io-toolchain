  slx x2
  mov x2 acc
  mov x0 p0
  mov acc x3
  teq x3 0
+ mov x3 acc
+ jmp 4
- teq x1 4
- jmp 3
a:  teq acc 1
b:- mov acc x2
c:  mov 0 x1

