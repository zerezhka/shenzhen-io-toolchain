  mov x0 acc
  dgt dat
  mul 10
  mov acc p1
  slp 1
  teq x1 0
+ mov dat acc
+ add 1
+ mov acc dat
a:+ teq dat 3
b:+ mov x2 p1
c:+ slp 1
d:+ jmp b

