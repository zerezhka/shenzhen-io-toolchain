# Calculate dists
# to given targets
slx x1
mov x1 acc
sub p1  # x-x0
dst 1 0 #|x-x0|
mov acc dat
mov x1 acc
sub p0  # y-y0
dst 1 0 #|y-y0|
tlt acc dat
- mov acc x1
+ mov dat x1

