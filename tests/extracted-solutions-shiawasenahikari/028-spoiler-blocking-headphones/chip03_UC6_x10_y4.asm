@ teq 0 0
+ mov x1 acc
+ mov x1 dat
  teq x2 acc
- mov x2 null
+ teq x2 dat
+ mov 50 p1#Mute
+ slp 1
+ teq x0 0
a:+ jmp 8
b:  teq x3 0
c:+ mov p0 p1#Play
d:+ slp 1

