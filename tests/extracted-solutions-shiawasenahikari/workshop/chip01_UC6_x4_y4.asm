  slx x0
  mov -99 dat
  dst 1 x0
  dst 0 x0
  tgt acc 4
+ sub 4
+ jmp 5
  teq dat -99
+ mov acc dat
a:+ jmp 3
b:  teq acc 0
c:+ teq dat 4
d:- teq acc 4
e:+ gen p0 1 4

