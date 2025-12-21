@ teq 0 0
  mov x0 acc
+ mov x1 dat
  tlt dat acc
+ mov dat x2
+ jmp 3
  mov acc x2
  teq acc 999
+ slx x0

