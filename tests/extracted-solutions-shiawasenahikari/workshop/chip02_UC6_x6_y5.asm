  mov x0 dat
  mov x0 acc
  add acc
  tgt acc 9
+ sub 9
  add x0
  add dat
  teq x3 0
+ mov acc dat
a:+ jmp 2
b:  dgt 0
c:  teq acc 0
d:- gen p1 1 0
e:  slx x0

