.section .text.start
.global start

start:
    # Set stack pointer to the top of 32KB RAM (0x00008000)
    # The stack grows downward.
    li sp, 0x00008000
    
    # Call our main function in C
    call main

# If main returns, loop forever
inf_loop:
    j inf_loop
