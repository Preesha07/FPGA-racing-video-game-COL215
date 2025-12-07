`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/31/2025 05:12:14 PM
// Design Name: 
// Module Name: car_move_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module car_move_tb(
    );

    parameter interval=153600000;
    reg clk;
    wire HS;
    wire VS;
    wire [11:0] vgaRGB;
    reg BTNC;
    reg BTNR;
    reg BTNL;


    Display_sprite UUT(
    .clk(clk),
    .HS(HS),
    .VS(VS),
    .vgaRGB(vgaRGB),
    .BTNC(BTNC),
    .BTNL(BTNL),
    .BTNR(BTNR)
    );

    initial begin
    clk=0;
    
    BTNC=1;
    #50
    BTNC=0;
    #50
    BTNL=1; //MOVE LEFT
    #interval
    BTNL=0;
    #20
    BTNC=1;
    #10
    BTNC=0;
      #50
    BTNR=1; //MOVE RIGHT
    #interval
    BTNR=0;
      #50
    BTNR=1; //COLLIDE RIGHT
    #(4*interval)
    BTNR=0;
    #50
    BTNC=0;//RESET
    end

    always #5 clk=~clk;


endmodule