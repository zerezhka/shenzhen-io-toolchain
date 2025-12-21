  tcp x0 2
- mov x0 dat
- mov acc x2
- mov x1 x2
- add 1
- tgt x3 dat
- jmp 4
+ mov 0 x3
  mov x2 x0
a:  tgt x3 dat
b:- jmp 9
c:  slx x0
d:  mov 0 x3

