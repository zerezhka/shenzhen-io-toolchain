# Simple adder: reads from p0 and p1, writes sum to p2
# Runs until inputs are exhausted (3 iterations)

mov 0 dat    # counter
loop:
mov p0 acc
add p1
mov acc p2
add 1 dat
teq dat 3
+ slx x0     # halt after 3 iterations (wait for XBus that never arrives)
jmp loop

