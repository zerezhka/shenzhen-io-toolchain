@ slp 14
@ mov 3 acc
  tcp p0 50
- slp 1
+ mov acc x1
+ slp 2
+ add 1
+ teq acc 12
+ slp 999

