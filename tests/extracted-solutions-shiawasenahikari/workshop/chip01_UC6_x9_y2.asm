@ teq 0 1
- slx x2
- mov x2 dat
- mov dat p1
- mov dat acc
  mov acc x3
  mov 0 x1
  mov x0 x3
  teq x1 dat
a:- jmp 8
b:  tgt x3 99
c:+ add 1

