@ mov -60 acc
@ mul x2
@ sub x3
@ add x0
  add 10
@ mul 10
  mov acc p1
  slp 1
  teq acc 140
a:- teq x1 10
b:+ mov p0 p1
c:+ slp 999
d:  teq acc 90
e:+ mov 100 p0

