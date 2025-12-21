# Calc Ans
  slx x1
  mov x1 acc
  teq dat 0
+ mov x1 x1
+ jmp d
  tcp dat 10
- add x1
- jmp c
+ mul x1
a:+ jmp c
b:  sub x1
c:  mov acc x1#ans
d:  mov x0 dat#sym

