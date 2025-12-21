  slx x1
  mov x1 dat
  mov dat acc
  dst 0 1
  tcp dat acc
+ mov acc x3
+ add 1
+ jmp 5
  mul -1
a:  mov x1 dat
b:  tcp dat acc
c:- mov acc x3
d:- sub 1
e:- jmp b

