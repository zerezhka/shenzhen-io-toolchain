@ teq 0 1
- mov -1 x2
- mov -1 x0
- teq x1 0
- jmp 2
  mov x3 x1
  teq x0 p1
+ jmp d
  teq x1 0
a:- jmp 7
b:  teq x0 -1
c:- jmp b
d:  mov x1 x3
e:  slx x3

