  mov x0 acc
  teq x2 dat
- teq x3 p1
+ mul -1
  tlt acc 100
+ tgt acc -100
- mov 0 x3
- mov -999 x0
+ mov acc x1
a:+ tcp x3 2
b:+ mov acc x0
c:- mov acc dat
d:  slx x0

