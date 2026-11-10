.section .text.start
.global start

start:
    # Set stack pointer to the top of 256KB RAM (0x00040000)
    # The stack grows downward.
    li sp, 0x00040000
    
    # Call our main function in C
    call main

# If main returns, loop forever
inf_loop:
    j inf_loop
