# Algorithm Documentation

## Overview

This document describes the algorithms and implementation details of the RISC-V number sorter program.

## 1. File Parsing Algorithm

### State Machine Design

The parser uses a state machine with three state variables:
- `s2`: Current number being built
- `s3`: Negative flag (1 if current number is negative)
- `s4`: Reading flag (1 if currently parsing a number)

### Character Processing Flow

```
For each character c:
  if c is digit (0-9):
    - Increment digit frequency counter
    - Accumulate into current number: num = num * 10 + digit
    - Set reading flag = true
  
  else if c is '-' and not currently reading:
    - Set negative flag = true
    - Set reading flag = true
  
  else if c is whitespace (space, tab, newline, CR):
    - If reading flag is true:
      - Save number to array (negate if negative flag set)
      - Reset state (num=0, negative=false, reading=false)
  
  else:
    - Increment non-digit counter
    - If reading flag is true:
      - Save number (same as whitespace case)
```

### Multiplication by 10 (Without MUL instruction)

Since we use only RV32I base instructions, multiplication is implemented via addition:

```assembly
# Multiply s2 by 10 using repeated addition
addi t4, zero, 10
add t5, zero, zero
mul10:
    beq t4, zero, mul10_done
    add t5, t5, s2
    addi t4, t4, -1
    jal zero, mul10
mul10_done:
    add s2, zero, t5
```

Time complexity: O(1) since we always loop exactly 10 times.

## 2. Insertion Sort Algorithm

### Why Insertion Sort?

- Simple to implement in assembly
- Good performance for small datasets (< 1000 elements)
- In-place sorting (no extra memory)
- Stable sort (preserves relative order of equal elements)

### Algorithm

```
for i = 1 to n-1:
    key = array[i]
    j = i - 1
    
    while j >= 0 and array[j] > key:
        array[j+1] = array[j]
        j = j - 1
    
    array[j+1] = key
```

### Assembly Implementation

```assembly
sort_outer:
    bge s2, s1, sort_done          # if i >= count, done
    
    # Load key = array[i]
    slli t0, s2, 2                 # t0 = i * 4 (word offset)
    add t0, s0, t0                 # t0 = &array[i]
    lw s3, 0(t0)                   # s3 = key
    
    addi s4, s2, -1                # j = i - 1
    
sort_inner:
    blt s4, zero, insert_key       # if j < 0, insert
    
    slli t0, s4, 2
    add t0, s0, t0
    lw t1, 0(t0)                   # t1 = array[j]
    ble t1, s3, insert_key         # if array[j] <= key, insert
    
    # Shift element right
    addi t2, s4, 1
    slli t2, t2, 2
    add t2, s0, t2
    sw t1, 0(t2)                   # array[j+1] = array[j]
    
    addi s4, s4, -1                # j--
    jal zero, sort_inner

insert_key:
    addi t0, s4, 1
    slli t0, t0, 2
    add t0, s0, t0
    sw s3, 0(t0)                   # array[j+1] = key
    
    addi s2, s2, 1                 # i++
    jal zero, sort_outer
```

### Complexity Analysis

- **Time Complexity**: 
  - Best case: O(n) - already sorted
  - Average case: O(n²)
  - Worst case: O(n²) - reverse sorted
  
- **Space Complexity**: O(1) - sorts in place

- **For 1000 elements**: ~500,000 comparisons worst case

## 3. Integer to String Conversion

### Division by 10 (Without DIV instruction)

Since RV32I doesn't have division, we use repeated subtraction:

```assembly
# Divide s0 by 10
addi t0, zero, 10              # divisor
add t1, zero, zero             # quotient

divide_loop:
    blt s0, t0, divide_done    # if dividend < divisor, done
    sub s0, s0, t0             # dividend -= divisor
    addi t1, t1, 1             # quotient++
    jal zero, divide_loop

divide_done:
    # s0 now contains remainder (digit)
    # t1 contains quotient
```

### Conversion Algorithm

```
1. Handle negative sign (set flag, negate number)
2. Extract digits right-to-left:
   - digit = num % 10
   - store (digit + '0') in buffer
   - num = num / 10
   - repeat until num == 0
3. Add '-' if negative flag set
4. Reverse buffer (digits are backwards)
5. Write buffer to stdout
```

## 4. Digit Frequency Tracking

### Data Structure

Array of 10 integers (one per digit 0-9):
```
digit_freq[0..9] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
```

### Tracking During Parsing

When a digit character is encountered:
```assembly
# digit char is in t1
sub t4, t1, 48                 # convert '0'-'9' to 0-9
slli t4, t4, 2                 # multiply by 4 (word size)
lui t5, %hi(digit_freq)
addi t5, t5, %lo(digit_freq)
add t5, t5, t4                 # t5 = &digit_freq[digit]
lw t6, 0(t5)
addi t6, t6, 1                 # increment counter
sw t6, 0(t5)
```

### Counting Unique Digits

```assembly
add s1, zero, zero             # unique_count = 0
addi s2, zero, 10              # loop 10 times

count_unique:
    beq s2, zero, done
    lw t0, 0(s0)               # load frequency
    beq t0, zero, skip         # if freq == 0, skip
    addi s1, s1, 1             # unique_count++
skip:
    addi s0, s0, 4             # next digit
    addi s2, s2, -1
    jal zero, count_unique
```

Time complexity: O(10) = O(1) - constant time.

## 5. Memory Management

### Memory Layout

```
.section .bss
    file_buffer:    4096 bytes   # Read buffer
    numbers_array:  4000 bytes   # Max 1000 integers
    digit_freq:       40 bytes   # 10 counters
    num_count:         4 bytes   # Number count
    non_digit_count:   4 bytes   # Non-digit count
    print_buffer:     20 bytes   # String conversion
```

Total: ~8 KB of static memory.

### Stack Usage

Minimal stack usage - only for preserving registers across function calls:
- `print_int`: 4 bytes (ra)
- `print_int_no_newline`: 20 bytes (ra + 4 saved registers)

Maximum stack depth: ~24 bytes.

## Performance Characteristics

### Best Case Scenario
- Small file (< 100 numbers)
- Already sorted
- Time: ~O(n) for parsing + O(n) for sorting = O(n)

### Worst Case Scenario
- Large file (1000 numbers)
- Reverse sorted
- Time: O(n) parsing + O(n²) sorting = O(n²)

### Actual Performance
On QEMU with 1000 random numbers: ~0.5 seconds
(Performance depends heavily on host CPU when using QEMU)
