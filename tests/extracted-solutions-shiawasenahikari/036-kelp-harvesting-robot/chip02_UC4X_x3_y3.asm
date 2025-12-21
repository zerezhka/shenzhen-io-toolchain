@ teq 0 1 #init
- mov -999 x2
- tcp x2 x3
- jmp 2
  slp 1 #newTask
  mov x0 acc
  tcp acc -999
+ mov acc x2
+ mov x0 x2

