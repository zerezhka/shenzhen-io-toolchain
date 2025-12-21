mov p0 acc #x
tlt acc 20
- tgt acc 79
+ mov 30 p1
+ jmp end
- tlt acc 40
+ mov 0 p1
+ jmp end
- tlt acc 60
+ mov acc x3
+ jmp end
- mov acc x2
end:  slp 1
mov 0 p1

