# Linux System Calls Reference

## Overview

This program uses direct Linux system calls (syscalls) via the `ecall` instruction. No C library is used.

## RISC-V System Call Convention

### Calling Convention
- **Syscall number**: Register `a7`
- **Arguments**: Registers `a0`, `a1`, `a2`, `a3`, `a4`, `a5`
- **Return value**: Register `a0`
- **Instruction**: `ecall`

### Error Handling
- Success: `a0 >= 0`
- Error: `a0 < 0` (negative errno value)

## System Calls Used

### 1. openat (56)

Opens a file relative to a directory file descriptor.

**Registers:**
```
a7 = 56              # syscall number
a0 = -100            # dirfd (AT_FDCWD = current directory)
a1 = filename_ptr    # pointer to filename string
a2 = 0               # flags (O_RDONLY)
a3 = 0               # mode (not used for O_RDONLY)
```

**Returns:**
- `a0 >= 0`: File descriptor (success)
- `a0 < 0`: Error code

**Assembly Example:**
```assembly
addi a0, zero, -100              # AT_FDCWD
add a1, zero, s0                 # filename pointer
add a2, zero, zero               # O_RDONLY
add a3, zero, zero               # mode
addi a7, zero, 56                # openat syscall
ecall

blt a0, zero, handle_open_error  # check for error
add s1, zero, a0                 # save fd
```

---

### 2. read (63)

Reads data from a file descriptor.

**Registers:**
```
a7 = 63              # syscall number
a0 = fd              # file descriptor
a1 = buffer_ptr      # pointer to buffer
a2 = count           # bytes to read
```

**Returns:**
- `a0 > 0`: Number of bytes read
- `a0 = 0`: End of file (EOF)
- `a0 < 0`: Error code

**Assembly Example:**
```assembly
add a0, zero, s1                 # file descriptor
lui a1, %hi(file_buffer)
addi a1, a1, %lo(file_buffer)   # buffer pointer
lui a2, 1                        # 4096 bytes (4KB)
addi a7, zero, 63                # read syscall
ecall

ble a0, zero, finish_reading     # EOF or error
```

**Buffer Size Choice:**
- 4096 bytes = 4KB = typical page size
- Efficient for filesystem I/O
- Good balance between memory and performance

---

### 3. write (64)

Writes data to a file descriptor.

**Registers:**
```
a7 = 64              # syscall number
a0 = fd              # file descriptor (1=stdout, 2=stderr)
a1 = buffer_ptr      # pointer to data
a2 = count           # bytes to write
```

**Returns:**
- `a0 >= 0`: Number of bytes written
- `a0 < 0`: Error code

**Assembly Example:**
```assembly
addi a0, zero, 1                 # stdout
lui a1, %hi(sorted_header)
addi a1, a1, %lo(sorted_header) # message pointer
addi a2, zero, sorted_len        # length
addi a7, zero, 64                # write syscall
ecall
```

**File Descriptors:**
- `0` = stdin (standard input)
- `1` = stdout (standard output)
- `2` = stderr (standard error)

---

### 4. close (57)

Closes a file descriptor.

**Registers:**
```
a7 = 57              # syscall number
a0 = fd              # file descriptor to close
```

**Returns:**
- `a0 = 0`: Success
- `a0 < 0`: Error code

**Assembly Example:**
```assembly
add a0, zero, s1                 # file descriptor
addi a7, zero, 57                # close syscall
ecall
```

**Why close files?**
- Releases system resources
- Flushes any buffered data
- Good practice (prevents resource leaks)

---

### 5. exit (93)

Terminates the program.

**Registers:**
```
a7 = 93              # syscall number
a0 = exit_code       # 0 = success, 1 = error
```

**Returns:**
- Does not return (terminates process)

**Assembly Example:**
```assembly
# Success exit
add a0, zero, zero               # exit code 0
addi a7, zero, 93                # exit syscall
ecall

# Error exit
addi a0, zero, 1                 # exit code 1
addi a7, zero, 93                # exit syscall
ecall
```

**Exit Codes:**
- `0` = Success
- `1` = General error
- Other codes = Specific error conditions

---

## Complete Syscall Flow Example

```assembly
# 1. Open file
addi a0, zero, -100
add a1, zero, s0                 # filename
add a2, zero, zero
add a3, zero, zero
addi a7, zero, 56
ecall
blt a0, zero, error
add s1, zero, a0                 # save fd

# 2. Read file
loop:
    add a0, zero, s1
    lui a1, %hi(buffer)
    addi a1, a1, %lo(buffer)
    lui a2, 1
    addi a7, zero, 63
    ecall
    ble a0, zero, done
    
    # Process data...
    
    jal zero, loop

done:
# 3. Close file
add a0, zero, s1
addi a7, zero, 57
ecall

# 4. Write output
addi a0, zero, 1
lui a1, %hi(message)
addi a1, a1, %lo(message)
addi a2, zero, msg_len
addi a7, zero, 64
ecall

# 5. Exit
add a0, zero, zero
addi a7, zero, 93
ecall
```

## Error Codes (errno)

Common negative error codes returned in `a0`:

- `-2` (ENOENT): No such file or directory
- `-9` (EBADF): Bad file descriptor
- `-13` (EACCES): Permission denied
- `-14` (EFAULT): Bad address
- `-21` (EISDIR): Is a directory
- `-22` (EINVAL): Invalid argument

**Checking for errors:**
```assembly
ecall
blt a0, zero, handle_error       # if a0 < 0, error occurred
# Success path...

handle_error:
    # a0 contains negative errno
    # Handle error...
```

## References

- [Linux Syscall Reference](https://man7.org/linux/man-pages/man2/syscalls.2.html)
- [RISC-V Linux Syscall Table](https://jborza.com/post/2021-05-11-riscv-linux-syscalls/)
- [RISC-V Calling Convention](https://riscv.org/wp-content/uploads/2015/01/riscv-calling.pdf)

## Debugging Tips

### Using strace

Monitor syscalls during execution:
```bash
qemu-riscv32 -strace ./programa test.txt
```

Output shows each syscall with arguments and return values:
```
56 openat(-100,0x00411234,0,0) = 3
63 read(3,0x00412000,4096) = 42
64 write(1,0x00411300,20) = 20
57 close(3) = 0
93 exit(0) = ?
```

### Common Issues

1. **File not found**: Check `openat` returns negative value
2. **Wrong output**: Verify `write` count parameter
3. **Segfault**: Check buffer addresses are valid
4. **Infinite loop**: Verify `read` EOF detection (`a0 <= 0`)
