  mov x1 dat
  tcp -999 dat
- mov x1 acc
- mov 100 p1
- mov dat x0
- mov acc x0
- mov 0 p1
- mov acc x0
- mov x0 acc
a:- tcp 0 acc
b:- teq acc dat
c:- jmp 8
d:+ mov dat x2
e:  slp 1

