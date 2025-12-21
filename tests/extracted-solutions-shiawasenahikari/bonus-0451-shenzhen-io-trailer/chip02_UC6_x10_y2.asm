@ slp 35
@ mov 12 acc
  tgt p0 dat
- slp 1
+ mov p0 dat
+ mov acc x3
+ slp 2
+ add 1
+ teq acc 15
a:+ slp 999

