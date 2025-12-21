# Chip 1: Multiplies input by 2 and sends to next chip
# Reads from p0, writes to p1

loop:
mov p0 acc
add acc
mov acc p1
jmp loop

