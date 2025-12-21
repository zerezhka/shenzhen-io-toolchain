  mov x1 acc
  tcp -999 acc
- mov acc x0
- mov dat x0
- mov acc dat
- mov x1 acc
- teq acc x3
+ teq p0 100
+ mov p1 x1
a:  slp 1
b:  mov x2 x3
c:- jmp 7

