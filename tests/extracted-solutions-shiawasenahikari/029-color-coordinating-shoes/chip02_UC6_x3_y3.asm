  slp 1 #Stat
  tcp p1 50
+ mov p0 acc
+ sub 30
+ dst 0 8
+ mov acc dat
+ mov dat x3
+ mov x2 acc
+ add 1
a:+ mov dat x3
b:+ mov acc x2
c:- teq dat 0
d:- mov 0 dat
e:- mov 0 x0

