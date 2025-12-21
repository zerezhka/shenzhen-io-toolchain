  mov x0 dat
  tcp dat -999
+ tlt dat 0
- mov dat x3
- jmp 1
+ teq dat -4
- mov dat x2
- mov x2 acc
- mov acc x3
a:- jmp 1
b:+ mov acc x1
c:  slp 1

