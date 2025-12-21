slx x0
mov x0 dat
i:
tcp dat acc
+ mov  1 x2
- mov -1 x2
+ add 1
- sub 1
+ teq acc dat
- teq acc dat
- slp 2
- jmp i
+ slp 2
mov 1 x1

