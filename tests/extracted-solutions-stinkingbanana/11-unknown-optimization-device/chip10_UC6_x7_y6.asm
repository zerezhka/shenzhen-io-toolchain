mov 30 acc
tlt p0 20
+ jmp end
tgt p0 79
+ jmp end
tlt p0 40
+ mov 0 acc
+ jmp end
tlt p0 60
+ mov 50 acc
- mov 80 acc
end: mov acc x2
slp 1

