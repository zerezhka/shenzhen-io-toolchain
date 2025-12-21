#   snd.hashCode()
# = snd.getPart2()
# / 100 * 2 % 14
  slx x2
  mov x2 dat
  mov dat acc
  dgt 2
  add acc
  mov acc x1
  teq x0 x2
+ teq x0 dat
+ mov 1 x2
a:- mov 0 x2

