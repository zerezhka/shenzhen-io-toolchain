  mov x1 acc
  tcp acc -999
+ mov x1 x3
+ mov acc x3
+ tcp x3 0
+ mov 50 p1#Mute
+ slp 1
+ teq x0 0
+ jmp 7
a:  mov p0 p1#Play
b:  slp 1

