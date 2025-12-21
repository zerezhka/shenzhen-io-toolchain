  tcp x1 -2
  mov x3 acc
  sub 2
  mov acc dat
  mov dat x3
  mov x2 acc
+ add x2
+ jmp c
- sub x2
a:- jmp c
b:  mul x2
c:  mov dat x3
d:  mov acc x1
e:  slx x1

