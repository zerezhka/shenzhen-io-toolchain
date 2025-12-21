# Chip 2: Adds 10 to the input and outputs
# Reads from p0, writes to p1

loop:
mov p0 acc
add 10
mov acc p1
jmp loop

