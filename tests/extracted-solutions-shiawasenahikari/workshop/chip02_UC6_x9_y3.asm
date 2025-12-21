  mov x0 acc
  tcp acc -999
+ dst 2 0
+ teq acc x1
- teq acc x2
  mov x0 dat
- tcp -999 dat
- mov dat x2
- jmp 6
a:+ tlt -999 dat
b:+ mov dat x3
c:+ jmp 6
d:- gen p1 1 3
e:  slp 1

