@ teq 0 0
+ mov x1 dat
+ tgt dat -1
+ mov dat x3
+ mov x2 acc
+ not
+ mov dat x3
+ mov acc x2
+ jmp 2
a:  mov x3 dat
b:  teq x2 100
c:+ mov dat x1
d:+ slx x1

