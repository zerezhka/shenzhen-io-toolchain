  slx x2
  mov x2 dat
  mov dat acc
  sub p1
  mov acc x1
  teq x0 x2
- dst 2 1
  teq x1 dat
- jmp 6
a:  teq dat 13
b:+ mov -1 acc
c:- tlt acc 100
d:+ mov acc x3
e:  mov acc x2

