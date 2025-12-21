  slp 1
  mov x0 acc
  tcp acc -999
+ mov x3 dat
+ mov dat p0
+ mov acc x2
+ teq x2 0
+ mov dat x1
+ mov x2 acc
a:+ jmp 6
b:- tlt dat 999
c:+ jmp 4
d:- teq acc x3
e:- mov acc x1

