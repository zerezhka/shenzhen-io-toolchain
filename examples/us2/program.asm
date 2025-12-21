# Example US2: Simple counter program
# Counts from 0 to 5 and outputs to p0

mov 0 acc
loop:
mov acc p0
add 1
teq acc 5
+ jmp end
jmp loop
end:
mov 0 acc

