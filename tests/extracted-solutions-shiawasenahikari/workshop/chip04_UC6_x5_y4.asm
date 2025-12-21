  slx x1
  tcp x1 101
- mov acc x0
- jmp 1
  mov x3 acc
  sub 2
  mov acc dat
  mov dat x3
  mov x2 acc
a:+ sub x2
b:+ jmp d
c:  add x2
d:  mov dat x3
e:  mov acc x2

