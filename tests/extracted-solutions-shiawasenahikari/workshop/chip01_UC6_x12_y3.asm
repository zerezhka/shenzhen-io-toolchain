@ mov -999 x0
  tcp x2 -1
+ mov acc x2
+ add 1
+ jmp 2
  mov 1 x1
  mov x0 x3
  tgt x1 acc
- jmp 7
a:  mov -1 x3
b:  slx x2
c:  mov 1 x1
d:  sub acc

