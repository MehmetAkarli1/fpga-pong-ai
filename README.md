# FPGA Pong Game (with AI opponent)

This is a Pong game I built on an FPGA board using Vivado and Vitis.  
Player 1 is controlled by physical buttons on the board, and Player 2 (the opponent) is controlled by an AI algorithm written in C and running on the soft processor.

## Project Overview

The goal was to create a working version of Pong game using hardware (VHDL) for game logic and software (C) for the AI player.

 The design includes ball and paddle logic, collision detection, and input from physical buttons.
- I created a custom IP in Vivado and wrote all VHDL modules myself.
- In Vitis, I programmed the AI opponent logic that reads the ball position and moves the paddle accordingly.
- The final design was deployed to the RealDigital Urbana FPGA board.

## Folder Structure

fpga-pong-ai/

- README.md
- LICENSE
- Images/
          - Block_design_in_vivado
          - fpga-pong-ai_fpga_board
          - fpga-pong-ai_gif
- Vivado / VHDL, constraints and tcl files)
          - apb_led_ctl folder
          - axi_pwm_driver_1_0 folder
          - hdmi_tx_1.0 folder
          - myip_pong2_1_0 folder
          - design_1_wrapper.xsa
          - UrbanaModified_axi.xdc
- Vitis / C source code and description)
          - fpga_pong_ai.c
          - fpga-pong-ai_code_description
          - constants.c
          - constants.h
          - init.c
          - init.h
- Demo / Video demo link
          - youtube_link.txt

## Tools used

- **Vivado** – for block design, IP integration, and VHDL
- **Vitis** – for programming the AI logic in C
- **FPGA Board** – RealDigital Urbana board

## Demo

Here’s a video of the final game running on the board:  

https://youtube.com/shorts/pQKWcvalr9g?si=gsaH7v9-VDiQo9j6

In the video, you can see Player 1 being controlled with physical buttons, while Player 2 moves on its own based on the AI logic.

## Why I Made This

I wanted to challenge myself and combine what I've learned about embedded systems, FPGA programming, and basic AI behavior. 
It’s also a great way to show how hardware and software can work together on a real platform.

## License

MIT – feel free to explore or build on it.


