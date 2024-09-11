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

.text
	format_str: .asciz "We should be executing the following code:\n%s\n"
	char_io: .asciz "%c"
	newline: .asciz "\n"
	program: .asciz "+[-->-[>>+>-----<<]<--<---]>-.>>>+.>>..+++[.>]<<<<.+++.------.<<-.>>>>+."

	.equ BRACKET_BYTES, 400000

.global main
.global brainfuck

# Input: a null-terminated string containing Brainfuck code.
brainfuck:
	pushq %rbp
	movq %rsp, %rbp

	movq $program, %rdi

	pushq %rdi # save program body start address
	subq $8, %rsp # stack alignment

	movq $0, %rax
	movq %rdi, %rsi
	movq $format_str, %rdi
	call printf
	movq $0, %rax

	addq $8, %rsp # stack alignment
	popq %rdi # restore program body start address

	store:
		# Store callee-saved registers
		pushq %r12
		pushq %r13
		pushq %r14
		pushq %r15
		pushq %rbx
		pushq %rdi
		pushq %rsi
		subq $8, %rsp

	subq $30000, %rsp # dedicate 30 000 bytes to program memory
	movq %rsp, %r12 # start of program memory stack

	// PSEUDOCODE FOR BRACKET LOADING
	// ==============================
	// const stack = [];
	// const left = [];
	// const right = [];
	// const queue = [];
	// const program = PROGRAM_STRING
	// for (let i = 0, c = 0; i < program.length; ++i) {
	// 	const char = program[i];
	//
	// 	if (char == '[') {
	// 		queue.push(i);
	// 	}
	//
	// 	if (char == ']') {
	// 		const popped = queue.pop();
	// 		right[i] = popped;
	// 		left[popped] = i;
	// 	}
	// }	
	// ==============================

	// ========================================
	// These are glorified look-up tables
	// that can fit up to BRACKET_BYTES / 4 brackets each
	// ========================================

	subq $BRACKET_BYTES, %rsp # dedicate BRACKET_BYTES bytes to left bracket list
	movq %rsp, %r13 # start of left bracket list

	subq $BRACKET_BYTES, %rsp # dedicate BRACKET_BYTES bytes to right bracket list 
	movq %rsp, %r14 # start of right bracket list

	subq $BRACKET_BYTES, %rsp # dedicate BRACKET_BYTES bytes to bracket queue
	movq %rsp, %r15 # start of bracket queue

	movq $-1, %rax # loop counter
	movq $0, %r8 # length of left[]
	movq $0, %r9 # length of right[]
	movq $0, %r10 # length of queue[]
	movq $0, %r11 # queue counter, stores which left bracket index we've reached
	load_brackets:
		incq %rax # increment %rax
		movzb (%rdi, %rax, 1), %rdx # char

		cmpq $91, %rdx # char == '['
		je load_left
		cmpq $93, %rdx # char == ']'
		je load_right
		cmpq $0, %rdx # char == NULL TERMINATOR
		je load_end
		jmp load_brackets

		load_left:
			# We are effectively storing a pair<int, int> in the stack
			movl %eax, (%r15, %r10, 4) # program address of current left bracket
			incq %r10 # increment queue length
			jmp load_brackets

		load_right:
			decq %r10 # pop last queue pair<int, int>
			movq $0, %rcx # reset %rcx
			movl (%r15, %r10, 4), %ecx # popped address
			movl %ecx, (%r14, %rax, 4) # right[i] = popped
			incq %r9 # increment right bracket length
			movq $0, %rcx # reset %rcx
			movl (%r15, %r10, 4), %ecx # popped
			movl %eax, (%r13, %rcx, 4) # left[popped] = i
			incq %r8 # increment left bracket length, which should be equal to right bracket length
			jmp load_brackets

		load_end:
			movq %r14, %rsp # free up the queue from the stack


	movq $-1, %rbx # instruction pointer
	movq $0, %r15 # data pointer
	execute_program:
		movzb (%r12, %r15, 1), %rax # current data byte
		incq %rbx # next instruction
		movzb (%rdi, %rbx, 1), %rdx # char

		cmpq $43, %rdx # char == '+'
		je execute_plus
		cmpq $44, %rdx # char == ','
		je execute_comma
		cmpq $45, %rdx # char == '-'
		je execute_minus
		cmpq $46, %rdx # char == '.'
		je execute_dot
		cmpq $60, %rdx # char == '<'
		je execute_larrow
		cmpq $62, %rdx # char == '>'
		je execute_rarrow
		cmpq $91, %rdx # char == '['
		je execute_left
		cmpq $93, %rdx # char == ']'
		je execute_right
		cmpq $0, %rdx # char == NULL TERMINATOR
		je execute_end
		jmp execute_program

		execute_plus:
			incb (%r12, %r15, 1) # ++*ptr
			jmp execute_program
		
		execute_comma:
			movq $0, %rax # zero vector args
			pushq %rdi
			subq $8, %rsp # stack alignment
			movq $char_io, %rdi # format string
			movq $0, %rsi
			leaq (%rsp), %rsi # memory space
			call scanf
			movq $0, %rcx
			movb (%rsp), %cl # read char
			addq $8, %rsp # stack alignment
			popq %rdi
			movb %cl, (%r12, %r15, 1) # *ptr = getchar()
			jmp execute_program
		
		execute_minus:
			decb (%r12, %r15, 1) # --*ptr
			jmp execute_program

		execute_dot:
			movq $0, %rax # zero vector args
			pushq %rdi
			subq $8, %rsp # stack alignment
			movq $char_io, %rdi # format string
			movq $0, %rcx # reset %rcx
			movb (%r12, %r15, 1), %cl # copy char
			movq %rcx, %rsi # copy char to %rsi
			call printf # printf(*ptr)
			addq $8, %rsp # stack alignment
			popq %rdi
			jmp execute_program

		execute_larrow:
			decq %r15 # --ptr
			jmp execute_program

		execute_rarrow:
			incq %r15 # ++ptr
			jmp execute_program

		execute_left:
			cmpb $0, (%r12, %r15, 1) # check if byte zero
			je execute_left_jump
			jmp execute_left_return

			execute_left_jump:
				movl (%r13, %rbx, 4), %ebx # jump to right bracket
			execute_left_return:
				jmp execute_program

		execute_right:
			cmpb $0, (%r12, %r15, 1) # check if byte zero
			jne execute_right_jump
			jmp execute_right_return

			execute_right_jump:
				movl (%r14, %rbx, 4), %ebx # jump to left bracket
			execute_right_return:
				jmp execute_program

		execute_end:
			movq $0, %rax
			movq $newline, %rdi
			call printf
			movq %r12, %rsp # free up all brackets from the stack
			addq $30000, %rsp # free up all program memory from the stack

	restore:
		# Restore callee-saved registers
		addq $8, %rsp
		popq %r15
		popq %r14
		popq %r13
		popq %r12
		pushq %rsi
		pushq %rdi
		pushq %rbx


	movq %rbp, %rsp
	popq %rbp
	ret

main:
	pushq %rbp
	movq %rsp, %rbp

	movq $program, %rdi
	call brainfuck

	movq %rbp, %rsp
	popq %rbp
	call exit