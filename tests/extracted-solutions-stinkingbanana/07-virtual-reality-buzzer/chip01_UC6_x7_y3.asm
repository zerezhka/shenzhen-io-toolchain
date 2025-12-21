tcp x0 0
+ mov 1 dat
+ jmp next
- jmp next
mov 0 dat
next:
teq dat 1
+ not
- mov 0 dat
- mov 0 acc
mov acc p1
slp 1

