tgt x1 0 #Target
- mov acc x3 #Scan
- slp 1
- sub x3
- tlt acc 1
+ mov x0 dat
+ tcp dat -999
+ mov dat x2
+ mov x0 x2
+ mov x2 dat
+ tlt dat acc
- tlt acc 1
+ mov dat acc
+ mov x1 p1

