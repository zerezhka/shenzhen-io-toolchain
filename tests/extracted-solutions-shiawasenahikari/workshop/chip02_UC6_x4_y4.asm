  slx x0
  mov x0 acc
  tgt acc -1
- mul -1
  mov acc dat
  mov x1 acc
+ mul -1
  mov acc x2
  tcp acc 0
a:- add dat
b:- jmp 8
c:+ sub dat
d:+ jmp 8

