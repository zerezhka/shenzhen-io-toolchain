@ mov x0 acc
  mov acc dat
  tcp p0 x1
+ add 21 #RT
- add 1  #DN
- tcp x1 10
- sub 2  #UP
+ sub 11 #LT
  mov acc x2
a:  tgt x2 0
b:- mov dat acc
c:  mov acc x3
d:+ slp 1
e:- gen p1 1 0

