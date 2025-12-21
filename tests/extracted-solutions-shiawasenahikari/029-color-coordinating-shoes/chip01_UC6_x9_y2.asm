# Find Max
  slx x3
  mov x3 dat
  mov x0 acc
  tcp acc dat
+ mov acc dat
+ mov x1 x2
  tcp x0 x1
- jmp 3
# Clear
  mov 0 x0
a:  tcp x0 x1
b:- jmp 9

