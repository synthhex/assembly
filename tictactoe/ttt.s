# Copyright (c) 2024 Valerie-June
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy 
# of this software and associated documentation files (the "Software"), to deal 
# in the Software without restriction, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# The Software is not to be used for any academic submissions, assignments, or 
# coursework, unless expressly permitted by the educational institution or instructor.
#
# The Software is provided "as is", without warranty of any kind, express or implied, 
# including but not limited to the warranties of merchantability, fitness for a 
# particular purpose, and noninfringement.

.data
    board_state: .long 0, 0, 0, 0, 0, 0, 0, 0, 0
    moves: .long 0
    score: .long 0, 0
    table: .long 32, 79, 88

.text
    welcome_text: .asciz "Welcome to Tic Tac Toe!\n"
    clear_text: .asciz "\033[2J\033[H"
    empty_text: .asciz "​"
    p1_high: .asciz "Player 1 score: %d\n"
    p2_high: .asciz "Player 2 score: %d\n"
    win_text: .asciz "Player %d wins!\n"
    draw_text: .asciz "The game is a draw!\n"
    again_text: .asciz "Want to play another game? (y/n): "
    move_text: .asciz "Player %d (%c), please enter your move (1-9): "
    invalid_move_text: .asciz "That move is invalid. Choose a free number between 1-9.\n\n"
    input: .asciz "%d"
    input_char: .asciz " %c" # why do i have to do this???????? https://stackoverflow.com/questions/65119466/scanf-seemingly-not-working-after-repeated-calls-intel-x86-64-nasm-assembly
    board: .asciz "%s%s%s%s%s―――――――――――――――――――――――――\n|1      |2      |3      |\n|   %c   |   %c   |   %c   |\n|       |       |       |\n―――――――――――――――――――――――――\n|4      |5      |6      |\n|   %c   |   %c   |   %c   |\n|       |       |       |\n―――――――――――――――――――――――――\n|7      |8      |9      |\n|   %c   |   %c   |   %c   |\n|       |       |       |\n―――――――――――――――――――――――――\n"

.global main

ඞ: .asciz "ඞ" # ඞ

main:
    pushq %rbp
    movq %rsp, %rbp

    call tictactoe

    movq %rbp, %rsp
    popq %rbp
    call exit

tictactoe:
    pushq %rbp
    movq %rsp, %rbp

    game_init:    
        movq $0, %rax
        movq $welcome_text, %rdi
        call printf

    game_loop:
        movq $moves, %r8
        cmpl $9, (%r8) # check if we've reached the end of the game
        je game_draw

        call print_board_and_score
        call get_move
        call check_for_win
        
        movq $moves, %r8
        incl (%r8) # increment moves

        cmpq $0, %rax
        je game_loop
        cmpq $1, %rax
        je game_end_o
        jmp game_end_x
        

    game_end_o:
        movq $score, %r8
        incl (%r8)
        jmp game_end

    game_end_x:
        movq $score, %r8
        incl 4(%r8)
        jmp game_end

    game_draw:
        call print_board_and_score
        movq $0, %rax
        movq $draw_text, %rdi
        call printf
        jmp loop_end

    game_end:        
        pushq %rax # preserve winner
        subq $8, %rsp # stack alignment
        call print_board_and_score
        addq $8, %rsp # stack alignment
        popq %rax # restore winner

        movq $win_text, %rdi
        movq %rax, %rsi
        movq $0, %rax
        call printf

    loop_end:
        movq $moves, %r8
        movl $0, (%r8) # reset moves

        movq $0, %rax
        movq $again_text, %rdi
        call printf

        movq $0, %rax
        movq $input_char, %rdi
        subq $16, %rsp
        leaq 8(%rsp), %rsi
        call scanf
        movq 8(%rsp), %rcx
        addq $16, %rsp

        cmpb $110, %cl # check if input is 'n'
        je loop_exit

        call reset_board
        jmp game_init

    loop_exit:

    movq %rbp, %rsp
    popq %rbp
    ret

reset_board:
    pushq %rbp
    movq %rsp, %rbp

    movq $0, %rax
    reset_loop:
        movq $board_state, %r8
        movl $0, (%r8, %rax, 4)
        incq %rax
        cmpq $9, %rax
        jl reset_loop

    movq %rbp, %rsp
    popq %rbp
    ret

print_board_and_score:
    pushq %rbp
    movq %rsp, %rbp

    movq $0, %rax
    movq $clear_text, %rdi
    call printf

    movq $0, %rax
    movq $p1_high, %rdi
    movq $score, %r8
    movq $0, %rsi
    movl (%r8), %esi
    call printf

    movq $0, %rax
    movq $p2_high, %rdi
    movq $score, %r8
    movq $0, %rsi
    movl 4(%r8), %esi
    call printf

    subq $8, %rsp
    movq $8, %rax
    push_loop:
        movq $board_state, %r8
        cmpl $1, (%r8, %rax, 4)
        je circle
        cmpl $-1, (%r8, %rax, 4)
        je cross
        jmp empty

        circle:
            pushq $79
            jmp push_end
        cross:
            pushq $88
            jmp push_end
        empty:
            pushq $32
            jmp push_end

        push_end:
            decq %rax # increment next board spot
            cmpq $0, %rax
            jge push_loop
    
    movq $0, %rax
    movq $board, %rdi
    movq $empty_text, %rsi
    movq $empty_text, %rdx
    movq $empty_text, %rcx
    movq $empty_text, %r8
    movq $empty_text, %r9
    call printf
    addq $80, %rsp

    movq %rbp, %rsp
    popq %rbp
    ret

# check_for_win()
# returns 0 if no win, 1 if O wins, 2 if X wins
check_for_win:
    pushq %rbp
    movq %rsp, %rbp
    
    movq $0, %rcx # loop counter
    check_rows:
        movq $board_state, %r8
        movq %rcx, %rax # %rax <- %rcx
        movq $3, %r9
        mulq %r9 # %rax <- %rax * 3 
        movq $3, %rdx # row sum, mulq messes with %rdx
        addl (%r8, %rax, 4), %edx # add up the row
        incq %rax # %rax <- %rax + 1
        addl (%r8, %rax, 4), %edx # add up the row
        incq %rax # %rax <- %rax + 1
        addl (%r8, %rax, 4), %edx # add up the row
        cmpq $6, %rdx # check if row sum is 3
        je o_win
        cmpq $0, %rdx # check if row sum is -3
        je x_win
        incq %rcx # %rcx <- %rcx + 1
        cmpq $3, %rcx # check if we've checked all rows
        jl check_rows

    movq $0, %rcx # loop counter
    check_columns:
        movq $3, %rdx # column sum
        movq $board_state, %r8
        movq %rcx, %rax # %rax <- %rcx
        addl (%r8, %rax, 4), %edx # add up the column
        addq $3, %rax # %rax <- %rax + 3
        addl (%r8, %rax, 4), %edx # add up the column
        addq $3, %rax # %rax <- %rax + 3
        addl (%r8, %rax, 4), %edx # add up the column
        cmpq $6, %rdx # check if column sum is 3
        je o_win
        cmpq $0, %rdx # check if column sum is -3
        je x_win
        incq %rcx # %rcx <- %rcx + 1
        cmpq $3, %rcx # check if we've checked all columns
        jl check_columns

    check_diagonals:
        movq $3, %rdx # diagonal sum
        movq $board_state, %r8
        movq $0, %rax # %rax <- 0
        addl (%r8, %rax, 4), %edx # add up the diagonal
        addq $4, %rax # %rax <- %rax + 4
        addl (%r8, %rax, 4), %edx # add up the diagonal
        addq $4, %rax # %rax <- %rax + 4
        addl (%r8, %rax, 4), %edx # add up the diagonal
        cmpq $6, %rdx # check if diagonal sum is 3
        je o_win
        cmpq $0, %rdx # check if diagonal sum is -3
        je x_win

        movq $3, %rdx # diagonal sum
        movq $board_state, %r8
        movq $2, %rax # %rax <- 2
        addl (%r8, %rax, 4), %edx # add up the diagonal
        addq $2, %rax # %rax <- %rax + 2
        addl (%r8, %rax, 4), %edx # add up the diagonal
        addq $2, %rax # %rax <- %rax + 2
        addl (%r8, %rax, 4), %edx # add up the diagonal
        cmpq $6, %rdx # check if diagonal sum is 3
        je o_win
        cmpq $0, %rdx # check if diagonal sum is -3
        je x_win

    movq $0, %rax
    jmp check_end

    o_win:
        movq $1, %rax
        jmp check_end

    x_win:
        movq $2, %rax
        jmp check_end

    check_end:

    movq %rbp, %rsp
    popq %rbp
    ret

get_move:
    pushq %rbp
    movq %rsp, %rbp

    pushq %rbx # callee-saved
    subq $8, %rsp # stack alignment

    get_top:

    movq $0, %rax
    movq $move_text, %rdi
    movq $1, %rsi # 0b1
    movq $moves, %r8
    andb (%r8), %sil # moves & 0b1 = whether even (0) or odd move (1)
    incq %rsi # even (1) or odd (2) move 
    
    cmpq $1, %rsi
    je print_o
    jmp print_x

    print_o:
        movq $'O', %rdx
        jmp print_player_end
    
    print_x:
        movq $'X', %rdx
        jmp print_player_end

    print_player_end:

    movq %rsi, %rbx # store move order in %rbx
    call printf

    movq $input, %rdi
    subq $16, %rsp
    leaq 8(%rsp), %rsi
    call scanf
    movq 8(%rsp), %rcx # copy move into rcx
    addq $16, %rsp

    cmpq $1, %rcx
    jl invalid_move
    cmpq $9, %rcx
    jg invalid_move
    decq %rcx # turn from 1-9 to 0-8
    movq $board_state, %r8
    cmpl $0, (%r8, %rcx, 4) # see if spot is free
    jne invalid_move

    store_move:
        movq $moves, %r8
        cmpq $1, %rbx
        je store_o
        jmp store_x

        store_x:
            movq $board_state, %r8
            movl $-1, (%r8, %rcx, 4) # store an X in the board
            jmp end_move

        store_o:
            movq $board_state, %r8
            movl $1, (%r8, %rcx, 4) # store an O in the board
            jmp end_move

    invalid_move:
        movq $0, %rax
        movq $invalid_move_text, %rdi
        call printf
        jmp get_top

    end_move:

    addq $8, %rsp # stack alignment
    popq %rbx # callee-saved

    movq %rbp, %rsp
    popq %rbp
    ret