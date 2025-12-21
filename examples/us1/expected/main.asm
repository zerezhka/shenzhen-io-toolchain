mov acc 0
loop:
add acc 1
mov p0 acc
slp 5
tlt acc 100
jmp loop
helper_func:
mov dat acc
