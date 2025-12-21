  tgt x0 p0
+ mov x0 acc
- tcp 0 x1
- mov 1 p0
- mov x1 acc
+ tgt x1 0
- tgt acc 100
- teq acc 11
- slp 1
a:- mov acc x3
b:+ mov x0 x2
c:+ mov x1 x2
d:+ slp 1
e:  slp 1

