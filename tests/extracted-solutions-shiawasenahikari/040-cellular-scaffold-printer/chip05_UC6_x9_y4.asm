# Calculate the
# real-time X
# coordinate
  slx x1
  mov x1 p0
  tgt acc 2
  mov acc x2
  slp 1
- tcp acc 5
- add 1
- jmp 4
+ tcp acc 0
a:+ sub 1
b:+ jmp 4

