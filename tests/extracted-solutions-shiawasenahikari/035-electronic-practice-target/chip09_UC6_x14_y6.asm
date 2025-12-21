# Control score-2
# LED display
  slx x0
  tcp p0 3
+ add x0
  mov acc x2
+ teq p0 7
+ slp 2
+ mov acc x2
+ slp 2
+ mov acc x2
a:+ slp 2
b:+ mov acc x2
c:+ sub acc

