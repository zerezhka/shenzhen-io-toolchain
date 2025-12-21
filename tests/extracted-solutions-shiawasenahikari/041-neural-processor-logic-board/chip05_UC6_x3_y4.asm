# Receive Packet
  slx x2
  mov x2 x1
  mov x2 acc
  mov acc x3
  teq acc -999
# Verify & Send
+ teq x2 0
+ mov x1 x3#init
+ mov x1 x0
+ mov x3 acc
a:+ tcp acc -999
b:+ mov acc x0
c:+ jmp 8

