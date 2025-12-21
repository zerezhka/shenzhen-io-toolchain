mov 2 acc
tlt p0 20
+ mov 1 acc
+ jmp end
tlt p0 40
+ mov 5 acc
+ jmp end
tlt p0 60
+ mov 4 acc
+ jmp end
tlt p0 80
+ mov 3 acc
end: mov acc x2
slp 1

