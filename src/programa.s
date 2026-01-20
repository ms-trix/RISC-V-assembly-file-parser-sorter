# programa_v3.s
# RISC-V 32-bit programa BE pseudo-instrukcijų
# Galutinė versija: Parsing, Insertion Sort, Išvestis

.section .rodata
    usage_msg:      .string "Naudojimas: ./programa <failo_pavadinimas>\n"
    usage_len = . - usage_msg

    error_open_msg: .string "Klaida: Nepavyko atidaryti failo.\n"
    error_open_len = . - error_open_msg

    sorted_header:  .string "Surusiuoti skaiciai:\n"
    sorted_len = . - sorted_header

    unique_msg:     .string "\nRasta skirtingu skaitmenu: "
    unique_len = . - unique_msg

    freq_msg:       .string "\nJu pasirodymo daznumas:\n"
    freq_len = . - freq_msg

    nondigit_msg:   .string "\nRasta neskaiciu simboliu: "
    nondigit_len = . - nondigit_msg

    colon_space:    .string ": "
    newline:        .string "\n"

.section .bss
    .align 4
    file_buffer:    .space 4096
    numbers_array:  .space 4000         # max 1000 skaičių
    digit_freq:     .space 40           # 10 skaitmenų * 4
    num_count:      .space 4
    non_digit_count:.space 4
    print_buffer:   .space 20           # buferis skaičiaus spausdinimui

.section .text
.global _start

_start:
    # ============================================================
    # 1. ARGUMENTŲ TIKRINIMAS
    # ============================================================
    
    lw t0, 0(sp)
    addi t1, zero, 2
    bne t0, t1, handle_usage_error

    lw s0, 8(sp)                        # s0 = argv[1]

    # ============================================================
    # 2. INICIALIZACIJA
    # ============================================================
    
    lui t0, %hi(num_count)
    addi t0, t0, %lo(num_count)
    sw zero, 0(t0)
    
    lui t0, %hi(non_digit_count)
    addi t0, t0, %lo(non_digit_count)
    sw zero, 0(t0)
    
    lui t0, %hi(digit_freq)
    addi t0, t0, %lo(digit_freq)
    addi t1, zero, 10
clear_freq:
    sw zero, 0(t0)
    addi t0, t0, 4
    addi t1, t1, -1
    bne t1, zero, clear_freq

    # ============================================================
    # 3. ATIDAROME FAILĄ
    # ============================================================
    
    addi a0, zero, -100
    add a1, zero, s0
    add a2, zero, zero
    add a3, zero, zero
    addi a7, zero, 56
    ecall
    
    blt a0, zero, handle_open_error
    add s1, zero, a0                    # s1 = fd

    # ============================================================
    # 4. PARSING (kaip v2)
    # ============================================================
    
    add s2, zero, zero                  # current number
    add s3, zero, zero                  # is negative
    add s4, zero, zero                  # reading number

read_parse_loop:
    add a0, zero, s1
    lui a1, %hi(file_buffer)
    addi a1, a1, %lo(file_buffer)
    lui a2, 1
    addi a7, zero, 63
    ecall
    
    ble a0, zero, finish_parse
    
    add s5, zero, a0                    # bytes read
    lui s6, %hi(file_buffer)
    addi s6, s6, %lo(file_buffer)
    add s7, zero, zero                  # index

parse_buf:
    bge s7, s5, read_parse_loop
    
    add t0, s6, s7
    lbu t1, 0(t0)
    addi s7, s7, 1
    
    # Ar skaitmuo?
    addi t2, zero, 48
    addi t3, zero, 57
    blt t1, t2, not_dig
    bgt t1, t3, not_dig
    
    # SKAITMUO - atnaujinti dažnumą
    sub t4, t1, t2
    slli t4, t4, 2
    lui t5, %hi(digit_freq)
    addi t5, t5, %lo(digit_freq)
    add t5, t5, t4
    lw t6, 0(t5)
    addi t6, t6, 1
    sw t6, 0(t5)
    
    # Kaupti skaičių: s2 = s2*10 + digit
    addi t4, zero, 10
    add t5, zero, zero
mul10:
    beq t4, zero, mul10_done
    add t5, t5, s2
    addi t4, t4, -1
    jal zero, mul10
mul10_done:
    add s2, zero, t5
    
    sub t4, t1, t2
    add s2, s2, t4
    
    addi s4, zero, 1                    # reading = true
    jal zero, parse_buf

not_dig:
    # Ar minusas?
    addi t2, zero, 45
    bne t1, t2, check_ws
    bne s4, zero, check_ws
    addi s3, zero, 1
    addi s4, zero, 1
    jal zero, parse_buf

check_ws:
    addi t2, zero, 32
    beq t1, t2, is_sep
    addi t2, zero, 9
    beq t1, t2, is_sep
    addi t2, zero, 10
    beq t1, t2, is_sep
    addi t2, zero, 13
    beq t1, t2, is_sep
    
    # Ne-skaitmuo
    lui t2, %hi(non_digit_count)
    addi t2, t2, %lo(non_digit_count)
    lw t3, 0(t2)
    addi t3, t3, 1
    sw t3, 0(t2)
    jal zero, check_save

is_sep:
check_save:
    beq s4, zero, parse_buf
    
    # Išsaugoti skaičių
    beq s3, zero, save_pos
    sub s2, zero, s2
save_pos:
    
    lui t0, %hi(numbers_array)
    addi t0, t0, %lo(numbers_array)
    lui t1, %hi(num_count)
    addi t1, t1, %lo(num_count)
    lw t2, 0(t1)
    slli t3, t2, 2
    add t0, t0, t3
    sw s2, 0(t0)
    addi t2, t2, 1
    sw t2, 0(t1)
    
    add s2, zero, zero
    add s3, zero, zero
    add s4, zero, zero
    jal zero, parse_buf

finish_parse:
    beq s4, zero, parse_done
    
    beq s3, zero, save_last_pos
    sub s2, zero, s2
save_last_pos:
    
    lui t0, %hi(numbers_array)
    addi t0, t0, %lo(numbers_array)
    lui t1, %hi(num_count)
    addi t1, t1, %lo(num_count)
    lw t2, 0(t1)
    slli t3, t2, 2
    add t0, t0, t3
    sw s2, 0(t0)
    addi t2, t2, 1
    sw t2, 0(t1)

parse_done:
    add a0, zero, s1
    addi a7, zero, 57
    ecall

    # ============================================================
    # 5. INSERTION SORT
    # ============================================================
    
    lui s0, %hi(numbers_array)
    addi s0, s0, %lo(numbers_array)    # s0 = array base
    lui t0, %hi(num_count)
    addi t0, t0, %lo(num_count)
    lw s1, 0(t0)                        # s1 = count
    
    addi s2, zero, 1                    # i = 1
sort_outer:
    bge s2, s1, sort_done               # if i >= count, done
    
    # key = array[i]
    slli t0, s2, 2
    add t0, s0, t0
    lw s3, 0(t0)                        # s3 = key
    
    # j = i - 1
    addi s4, s2, -1                     # s4 = j
    
sort_inner:
    blt s4, zero, insert_key            # if j < 0, insert
    
    # if array[j] <= key, insert
    slli t0, s4, 2
    add t0, s0, t0
    lw t1, 0(t0)                        # t1 = array[j]
    ble t1, s3, insert_key
    
    # array[j+1] = array[j]
    addi t2, s4, 1
    slli t2, t2, 2
    add t2, s0, t2
    sw t1, 0(t2)
    
    addi s4, s4, -1
    jal zero, sort_inner

insert_key:
    addi t0, s4, 1
    slli t0, t0, 2
    add t0, s0, t0
    sw s3, 0(t0)
    
    addi s2, s2, 1
    jal zero, sort_outer

sort_done:

    # ============================================================
    # 6. IŠVESTIS - SURŪŠIUOTI SKAIČIAI
    # ============================================================
    
    addi a0, zero, 1
    lui a1, %hi(sorted_header)
    addi a1, a1, %lo(sorted_header)
    addi a2, zero, sorted_len
    addi a7, zero, 64
    ecall
    
    lui s0, %hi(numbers_array)
    addi s0, s0, %lo(numbers_array)
    lui t0, %hi(num_count)
    addi t0, t0, %lo(num_count)
    lw s1, 0(t0)
    add s2, zero, zero                  # index = 0

print_nums:
    bge s2, s1, print_stats
    
    slli t0, s2, 2
    add t0, s0, t0
    lw a0, 0(t0)
    
    addi sp, sp, -8
    sw s0, 0(sp)
    sw s1, 4(sp)
    jal ra, print_int
    lw s0, 0(sp)
    lw s1, 4(sp)
    addi sp, sp, 8
    
    addi s2, s2, 1
    jal zero, print_nums

    # ============================================================
    # 7. STATISTIKA
    # ============================================================

print_stats:
    # Skaičiuojame unikalius
    lui s0, %hi(digit_freq)
    addi s0, s0, %lo(digit_freq)
    add s1, zero, zero                  # unique count
    addi s2, zero, 10                   # loop counter
count_unique:
    beq s2, zero, print_unique
    lw t0, 0(s0)
    beq t0, zero, skip_unique
    addi s1, s1, 1
skip_unique:
    addi s0, s0, 4
    addi s2, s2, -1
    jal zero, count_unique

print_unique:
    addi a0, zero, 1
    lui a1, %hi(unique_msg)
    addi a1, a1, %lo(unique_msg)
    addi a2, zero, unique_len
    addi a7, zero, 64
    ecall
    
    add a0, zero, s1
    jal ra, print_int
    
    # Dažnumai
    addi a0, zero, 1
    lui a1, %hi(freq_msg)
    addi a1, a1, %lo(freq_msg)
    addi a2, zero, freq_len
    addi a7, zero, 64
    ecall
    
    lui s0, %hi(digit_freq)
    addi s0, s0, %lo(digit_freq)
    add s1, zero, zero                  # digit = 0
print_freq_loop:
    addi t0, zero, 10
    bge s1, t0, print_nondigit
    
    # Spausdinti "digit: "
    add a0, zero, s1
    jal ra, print_int_no_newline
    
    addi a0, zero, 1
    lui a1, %hi(colon_space)
    addi a1, a1, %lo(colon_space)
    addi a2, zero, 2
    addi a7, zero, 64
    ecall
    
    # Spausdinti dažnumą
    slli t0, s1, 2
    add t0, s0, t0
    lw a0, 0(t0)
    jal ra, print_int
    
    addi s1, s1, 1
    jal zero, print_freq_loop

print_nondigit:
    addi a0, zero, 1
    lui a1, %hi(nondigit_msg)
    addi a1, a1, %lo(nondigit_msg)
    addi a2, zero, nondigit_len
    addi a7, zero, 64
    ecall
    
    lui t0, %hi(non_digit_count)
    addi t0, t0, %lo(non_digit_count)
    lw a0, 0(t0)
    jal ra, print_int

    # Išeiti
    add a0, zero, zero
    addi a7, zero, 93
    ecall

# ============================================================
# HELPER FUNKCIJOS
# ============================================================

# print_int: Spausdina integer su newline
# a0 = skaičius
print_int:
    addi sp, sp, -4
    sw ra, 0(sp)
    
    jal ra, print_int_no_newline
    
    addi a0, zero, 1
    lui a1, %hi(newline)
    addi a1, a1, %lo(newline)
    addi a2, zero, 1
    addi a7, zero, 64
    ecall
    
    lw ra, 0(sp)
    addi sp, sp, 4
    jalr zero, ra, 0

# print_int_no_newline: Spausdina integer be newline
# a0 = skaičius
print_int_no_newline:
    addi sp, sp, -20
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    sw s2, 12(sp)
    sw s3, 16(sp)
    
    add s0, zero, a0                    # s0 = number
    lui s1, %hi(print_buffer)
    addi s1, s1, %lo(print_buffer)     # s1 = buffer
    add s2, zero, zero                  # s2 = length
    add s3, zero, zero                  # s3 = is_negative
    
    # Tikrinti neigiamą
    bge s0, zero, convert_loop
    addi s3, zero, 1
    sub s0, zero, s0
    
convert_loop:
    # digit = num % 10
    addi t0, zero, 10
    add t1, zero, zero                  # quotient
divide_loop:
    blt s0, t0, divide_done
    sub s0, s0, t0
    addi t1, t1, 1
    jal zero, divide_loop
divide_done:
    # s0 = remainder (digit), t1 = quotient
    
    addi t2, s0, 48                     # digit + '0'
    add t3, s1, s2
    sb t2, 0(t3)
    addi s2, s2, 1
    
    add s0, zero, t1
    bne s0, zero, convert_loop
    
    # Pridėti minusą
    beq s3, zero, reverse_buffer
    addi t0, zero, 45
    add t1, s1, s2
    sb t0, 0(t1)
    addi s2, s2, 1
    
reverse_buffer:
    # Apsukti string
    add t0, zero, zero                  # left = 0
    addi t1, s2, -1                     # right = length-1
reverse_loop:
    bge t0, t1, print_buffer_content
    
    add t2, s1, t0
    lbu t3, 0(t2)
    add t4, s1, t1
    lbu t5, 0(t4)
    sb t5, 0(t2)
    sb t3, 0(t4)
    
    addi t0, t0, 1
    addi t1, t1, -1
    jal zero, reverse_loop

print_buffer_content:
    addi a0, zero, 1
    add a1, zero, s1
    add a2, zero, s2
    addi a7, zero, 64
    ecall
    
    lw ra, 0(sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    lw s2, 12(sp)
    lw s3, 16(sp)
    addi sp, sp, 20
    jalr zero, ra, 0

# ============================================================
# KLAIDŲ APDOROJIMAS
# ============================================================

handle_usage_error:
    addi a0, zero, 2
    lui a1, %hi(usage_msg)
    addi a1, a1, %lo(usage_msg)
    addi a2, zero, usage_len
    addi a7, zero, 64
    ecall
    jal zero, exit_error

handle_open_error:
    addi a0, zero, 2
    lui a1, %hi(error_open_msg)
    addi a1, a1, %lo(error_open_msg)
    addi a2, zero, error_open_len
    addi a7, zero, 64
    ecall

exit_error:
    addi a0, zero, 1
    addi a7, zero, 93
    ecall
