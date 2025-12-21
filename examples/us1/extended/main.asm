# Example US1: Extended source with includes, const, alias, and comments
const MAX_VALUE 100
const DELAY 5

alias LED p0
alias SENSOR p1

# Main program
mov acc 0
loop:
  add acc 1
  mov LED acc
  slp DELAY
  tlt acc MAX_VALUE
+ jmp loop

# Include helper functions
include helpers.asm
