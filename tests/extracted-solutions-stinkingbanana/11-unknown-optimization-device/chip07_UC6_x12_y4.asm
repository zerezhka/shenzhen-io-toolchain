slx x2
mov x2 dat
tcp dat 33
- mov 30 p1
- jmp end
+ jmp next
mov 80 p1
jmp end
next: teq dat 43
+ mov 50 p1
- mov 0 p1
end:slp 1

