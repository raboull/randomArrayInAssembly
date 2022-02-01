																		//Defining macros:
						define(v_0_r, x19)								//define a register to hold the address of the first element of the v array
						define(gap_r, w20)								//define a register to hold the valur of gap
						define(i_r, w21)								//define a register to hold the value of i
						define(j_r, w22)								//define a register to hold the value of j
						define(temp_r, w23)								//define a register to hold the value of temp
						define(v_at_i_r, w24)							//define a register to hold the value of v[i]
						define(v_at_j_r, w25)							//define a register to hold the value of v[j]
						define(v_at_jPlusGap_r,w26)						//define a register to hold the value of v[j+gap]

unsorted_message:		.string "Unsorted array:\n" 					//Message before an unsorted array is printed.
sorted_message:			.string "\nSorted array:\n" 					//Message before a sorted array is printed.
element_message:		.string "v[%d] = %d\n"

						fp .req x29										//use register equate to create an alias for the Frame Pointer
						lr .req x30										//use register equate to create an alias for the Link Register

																		//use assembler equates to store sizes of the variable to be used
						SIZE_CONST = 100								//assembler equate to store a constant defining the size of our array
						v_arr_size = SIZE_CONST*4						//assembler equate to store size of an array of integers with SIZE_CONST number of elements
						gap_size = 4									//assembler equate to store size of an integer variable named gap
						i_size = 4										//assembler equate to store size of an integer variable named i
						j_size = 4										//assembler equate to store size of an integer variable named j
						temp_size = 4									//assembler equate to store size of an integer variable named temp
						gap = SIZE_CONST/2								//assembler equate to store the initial value of an integer variable named gap

						alloc = -(16 + v_arr_size + gap_size + i_size + j_size + temp_size)&-16	//compute and store the total size that will be allocated on the stack
						dealloc = -alloc								//stores the memory that will be traversed when we are dealocating all the used variables from the stack

						gap_s = 16										//memory offset from the frame pointer to reach the gap variable
						i_s = 20										//memory offset from the frame pointer to reach the i variable
						j_s = 24										//memory offset from the frame pointer to reach the j variable
						temp_s = 28										//memory offset from the frame pointer to reach the temp variable
						v_s = 32										//memory offset from the frame pointer to reach the first element of the v array

						.balign 4                              			//this makes sure that the following instructions that we write are divisible by 4 to alighn word lengths
						.global main                            		//pseudo op which sets the start label to main. it will make sure that the main label is picked by the linker

main:           		stp     fp, lr, [sp, alloc]!					//stores the contents of the frame record to the stack and allocates memory for our local variables on the stack too
						mov     fp, sp									//updates FP to the current SP

						mov i_r, 0										//initialize the i register to start the i counter from 0
						str i_r, [fp, i_s]								//store the initialized i value into the i variable on the stack
						add v_0_r, fp, v_s								//initialize the v_0 register to hold address of the first array element

fill_rand_loop:															//start of a loop that fills our v array with random positive integers mod 512
						ldr i_r, [fp, i_s]								//load the value of i stored on the stack
						bl rand											//branch to the standard C library rand() function
						and v_at_i_r, w0, 0x1FF							//mask the returned random value to make it mod512 and store it in v[i] register
						str v_at_i_r, [v_0_r, i_r, SXTW 2]				//store the random value in v[i] on the stack

						add i_r, i_r, 1									//increment the i value by 1
						str i_r, [fp, i_s]								//store the updated i value on the stack

fill_rand_test:			cmp i_r, SIZE_CONST								//compare current value or i to SIZE_CONST constant assembler equate
						b.lt fill_rand_loop								//execute the fill_rand_loop one more time if i<SIZE_CONST

print_unsorted_loop:													//here we start a loop to print out an array of unsorted values
						adrp x0, unsorted_message						//set the first argument to address of the unsorter_message string
						add x0, x0, :lo12:unsorted_message				//complete the address location
						bl printf										//branch to the built in printf function

						mov i_r, 0										//reset the i value to zero
						str i_r, [fp, i_s]								//store the updated i value on the stack
						b print_unsorted_test							//branch to this print loop test

print_unsorted_val:		ldr i_r, [fp, i_s]								//load value of i stored on the stack
						ldr v_at_i_r, [v_0_r, i_r, SXTW 2]				//load v[j] from the stack, sign extend fist since we are using a word length index register

						adrp x0, element_message						//set the first argument to the address of the element_message string
						add x0, x0, :lo12:element_message				//complete the address location
						mov w1, i_r										//provide the value of i as the second argument to printf
						mov w2, v_at_i_r								//provide the value of v[i] as the third argument to printf
						bl printf										//branch to the built in printf function

						add i_r, i_r, 1									//increment i by a value of 1
						str i_r, [fp, i_s]								//store the update i value on the stack

print_unsorted_test:	cmp i_r, SIZE_CONST								//compare current value of i to SIZE_CONST constant assempler equate
						b.lt print_unsorted_val							//execute the print_unsorted_val loop one more time if i<SIZE_CONST

																		//here the tripple nested loop to sort the array elements begins
first_loop:				str gap_r, [fp, gap_s]							//store the current value of gap on the stack
						mov gap_r, gap									//initialize the value of gap to SIZE_CONST/2
						b first_loop_test								//branch to the first_loop_test label

second_loop:			mov i_r, gap_r									//set i = gap
						b second_loop_test								//branch to the second_loop_test label

third_loop:				sub j_r, i_r, gap_r								//set j = i - gap
						b swap_test										//branch to the swap_test label

swap_items:				ldr v_at_j_r, [v_0_r, j_r, SXTW 2]				//load v[j] from the stack, sign extend first since we are using a word length index register

						add temp_r, j_r, gap_r							//set temp = j + gap
						ldr v_at_jPlusGap_r, [v_0_r, temp_r, SXTW 2]	//load v[j+gap] from the stack, sign extend first since we are using a word lenth index register
						cmp v_at_jPlusGap_r, v_at_j_r					//compare v[j+gap] with v[j]
						b.lt increment_i								//branch to the increment_i label if v[j+gap] < v[j]

																		//exchange out of order items
						mov temp_r, v_at_j_r							//set temp = v[j]
						mov v_at_j_r, v_at_jPlusGap_r					//set v[j] = v[j+gap]
						mov v_at_jPlusGap_r, temp_r						//set v[j+gap] = temp
						str v_at_j_r, [v_0_r, j_r, SXTW 2]				//store v[j] on the stack
						add temp_r, j_r, gap_r							//set temp = j + gap
						str v_at_jPlusGap_r, [v_0_r, temp_r, SXTW 2]	//store v[j+gap] on the stack
						sub j_r, j_r, gap_r								//set j = j-gap

swap_test:				cmp j_r, 0										//compare j with 0
						b.ge swap_items									//branch to the swap_items label if j >= 0

increment_i:			add i_r, i_r, 1									//increment the value of i by 1

second_loop_test:		cmp i_r, SIZE_CONST								//compare i with SIZE_CONST
						b.lt third_loop									//branch to the third_loop label if i < SIZE_CONST
						lsr gap_r, gap_r, 1								//update gap = gap/2

first_loop_test:		cmp gap_r, 0									//compare gap_r value with zero
						b.gt second_loop								//branch to second_loop label if gap > 0

print_sorted_loop:														//here we start a loop to print out an array of sorted values
						adrp x0, sorted_message							//set the first argument to address of the sorted_message string
						add x0, x0, :lo12:sorted_message				//complete the address location
						bl printf										//branch to the built in printf function

						mov i_r, 0										//reset the i_r value to zero
						str i_r, [fp, i_s]								//store the updated i_r value on the stack
						b print_sorted_test								//branch to this print loop test

print_sorted_val:		ldr i_r, [fp, i_s]								//load value of i stored on the stack
						ldr v_at_i_r, [v_0_r, i_r, SXTW 2]				//load value of v[i] currently stored on the stack

						adrp x0, element_message						//set the first argument to address of the element_message string
						add x0, x0, :lo12:element_message				//complete the address location
						mov w1, i_r										//provide the value of i as the second argument to printf
						mov w2, v_at_i_r								//provide the value of v[i] as the third argument to printf
						bl printf										//branch to the built in printf function

						add i_r, i_r, 1									//increment i by a value of 1
						str i_r, [fp, i_s]								//store the updated i value on the stack

print_sorted_test:		cmp i_r, SIZE_CONST								//compare current value of i to SIZE_CONST constant assembler equate
						b.lt print_sorted_val							//execute the print_sorted_val loop one more time if i<SIZE_CONST

done:           		ldp     fp, lr, [sp], dealloc              		//restores the state of the FP and LR registers
						ret                             				//returns control to the calling code (in OS)
