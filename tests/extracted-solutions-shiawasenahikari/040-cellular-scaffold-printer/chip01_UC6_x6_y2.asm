# Query the cell
# row to print
  slx x3
  mov x3 acc
  tcp p1 5
- mov p1 x2
- mov 0 x2
- jmp 1
  mov p1 x1
  tgt acc 2
+ sub 3
a:- mov x0 null
b:  mov x0 x2
c:  mov acc x2

