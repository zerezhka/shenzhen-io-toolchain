  mov x2 p1
- mov x0 p1
  teq x3 1
# Wait Start
  slp 1
+ mov p0 acc
  tcp acc 2
+ jmp 4
# Wait End

