# Standby
@ mov -999 acc
  tcp p0 p1
+ sub 999
+ tcp acc -999
- teq acc -999
+ sub acc
# Timing
- slp 2
- add 1
  mov acc x3
a:- tcp p1 100
b:- jmp 7
c:  slp 1

