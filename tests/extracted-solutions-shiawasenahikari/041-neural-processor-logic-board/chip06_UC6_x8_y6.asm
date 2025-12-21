# Send LOGOS-data
# packet to left
  mov x3 dat
  tcp dat -999
  mov dat x0#pmp
+ mov dat x1
+ tgt dat -999
+ mul -1
+ add dat
+ mov x3 dat
+ jmp 4
a:- mov acc x1#CRC
b:- sub acc
c:  slp 1

