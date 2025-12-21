  slx x0
  mov 100 acc
  add x0
  tcp p0 50
+ mov acc x2
- teq acc x2
- dst 2 0
  tcp x3 10
- jmp 3
a:  teq p0 0
b:+ tcp acc 89
c:+ mov 100 p1
d:+ slp 6
e:  mov p1 x3

