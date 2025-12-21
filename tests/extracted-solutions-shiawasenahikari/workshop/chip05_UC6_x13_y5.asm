  slx x0
  mov x0 acc
  mov x0 dat
  teq dat -999
+ mov acc x2
+ jmp e
  mov dat x2
  mov p0 dat
  tcp acc 1
a:+ mov p1 dat
b:- mov -1 x1
c:- mov x1 dat
d:  mov dat x0
e:  mov dat x2

