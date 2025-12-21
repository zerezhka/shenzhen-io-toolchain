  mov x0 dat
  tcp -999 dat
- teq dat x2
- dst 1 1
- tlt acc 12
- gen p0 999 p1
+ teq x3 5
- jmp 1
+ mov 0 x3
a:+ tlt acc 10
b:+ mov 100 p1
c:  slp 1
d:- sub 9
e:+ sub acc

