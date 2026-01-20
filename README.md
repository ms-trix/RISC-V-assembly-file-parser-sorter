# RISC-V-assembly-file-parser-sorter
RISC-V Assembly program for parsing, sorting numbers from files using Linux syscalls

# RISC-V Number Sorter

A RISC-V 32-bit assembly program that parses integers from text files, sorts them, and provides statistical analysis using direct Linux system calls.

##  Features

- **File parsing**: Reads integers (positive and negative) from text files
- **Insertion sort**: Sorts numbers in ascending order
- **Digit frequency analysis**: Counts occurrences of each digit (0-9)
- **Non-digit tracking**: Counts non-numeric characters
- **Pure assembly**: No C library dependencies - uses only Linux syscalls

##  Technical Details

- **Architecture**: RISC-V 32-bit (RV32I)
- **OS**: Linux
- **Tools**: GNU Assembler (`as`), GNU Linker (`ld`)
- **Calling Convention**: RISC-V ABI compliant
- **System Calls**: Direct `ecall` instructions (no libc)

## 📋 Requirements

- RISC-V toolchain (riscv32-unknown-linux-gnu or riscv64-linux-gnu)
- QEMU user mode emulation (for testing on x86/ARM hosts)
- Linux environment

### Installing Dependencies (Ubuntu/Debian)

```bash
sudo apt-get update
sudo apt-get install gcc-riscv64-linux-gnu
sudo apt-get install qemu-user
```

## 🚀 Building

### Using Makefile

```bash
make
```

### Manual Build

```bash
riscv64-linux-gnu-as -march=rv32i -mabi=ilp32 -o programa.o src/programa.s
riscv64-linux-gnu-ld -m elf32lriscv -o programa programa.o
```

## ▶️ Running

```bash
# Using QEMU
qemu-riscv32 ./programa tests/test_simple.txt

# On actual RISC-V hardware
./programa tests/test_simple.txt
```

## 📊 Example

**Input file** (`test_simple.txt`):
```
42 -17 8
hello 100 world -3
```

**Output**:
```
Surusiuoti skaiciai:
-17
-3
8
42
100

Rasta skirtingu skaitmenu: 7
Ju pasirodymo daznumas:
0: 2
1: 2
2: 1
3: 1
4: 1
7: 1
8: 1

Rasta neskaiciu simboliu: 10
```

## 🧪 Testing

Run all test cases:
```bash
make test
```

Individual tests:
```bash
qemu-riscv32 ./programa tests/test_simple.txt
qemu-riscv32 ./programa tests/test_negative.txt
qemu-riscv32 ./programa tests/test_mixed.txt
```

## 📖 Algorithm Details

### Parsing Algorithm
- Reads file in 4KB chunks
- State machine for number parsing (handles negative numbers)
- Tracks digit frequencies during parsing
- Counts non-digit characters

### Sorting Algorithm
- **Insertion Sort** - O(n²) time complexity
- Chosen for simplicity and educational value
- Efficient for small to medium datasets

See [docs/ALGORITHM.md](docs/ALGORITHM.md) for detailed explanation.

## 🔍 Linux System Calls Used

| Syscall | Number | Purpose |
|---------|--------|---------|
| openat | 56 | Open file |
| read | 63 | Read file contents |
| write | 64 | Write to stdout/stderr |
| close | 57 | Close file |
| exit | 93 | Exit program |

See [docs/SYSCALLS.md](docs/SYSCALLS.md) for implementation details.

##  Code Structure

```
.section .rodata    # Read-only data (strings, constants)
.section .bss       # Uninitialized data (buffers, arrays)
.section .text      # Code section
```

**Main components**:
1. Argument validation
2. Initialization
3. File operations
4. Parsing loop
5. Insertion sort
6. Output formatting
7. Helper functions

##  Academic Project

This program was developed as a university assignment to demonstrate:
- RISC-V assembly programming
- Linux system call interface
- Memory management
- Algorithm implementation
- ABI compliance

**Course**: Computer Architecture / Assembly Programming  


##  Contributing

This is an academic project, but suggestions and improvements are welcome! Please open an issue or submit a pull request.

##  Author

Matas Skrebe - Computer Science Student

## 🔗 Resources

- [RISC-V Specification](https://riscv.org/technical/specifications/)
- [Linux System Call Table (RISC-V)](https://jborza.com/post/2021-05-11-riscv-linux-syscalls/)
- [RISC-V Calling Convention](https://riscv.org/wp-content/uploads/2015/01/riscv-calling.pdf)
