  mov x0 dat
  mov dat x2
  mov x1 acc
  tgt acc 127
+ sub 256
  mov acc x2
+ add 256
  tgt p0 0
- mul -1
a:  add dat
b:  tgt p1 acc
c:- tgt acc 255
d:+ mov 100 p1
e:  slx x0

