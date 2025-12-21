# Send TELOS-data
# packet to left
  mov x3 dat
  mov dat x1#pmp
  tcp dat -999
+ mov dat x0
+ tgt dat -999
+ mul -1
+ add dat
+ mov x3 dat
+ jmp 4
a:- mov acc x0#CRC
b:- sub acc
c:  slp 1

