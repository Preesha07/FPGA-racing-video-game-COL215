`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/31/2025 02:18:13 PM
// Design Name: 
// Module Name: Display_sprite
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


module Display_sprite #(
        // Size of signal to store  horizontal and vertical pixel coordinate
        parameter pixel_counter_width = 10,
        parameter OFFSET_BG_X = 200,
        parameter OFFSET_BG_Y = 150
    )
    (
        input clk,
        output HS, VS,
        output [11:0] vgaRGB,
        input BTNR,
        input BTNL,
        input BTNC
    );

    localparam bg1_width = 160;
    localparam bg1_height = 240;

    localparam main_car_width = 14;
    localparam main_car_height = 16;


    wire pixel_clock;
    wire [3:0] vgaRed, vgaGreen, vgaBlue;
    wire [pixel_counter_width-1:0] hor_pix, ver_pix;
    reg [11:0] output_color;
    reg [11:0] next_color;
    reg [15:0] bg_rom_addr;
    wire [11:0] bg_color;
    reg [7:0] car_rom_addr;
    wire [11:0] car_color;


    reg bg_on, car_on;
    wire [pixel_counter_width-1:0] car_y;
    reg [pixel_counter_width-1:0] car_x_current;
    reg  [pixel_counter_width-1:0] car_x_next;

    wire [7:0] rand;

    reg [7:0] disp_bg;

    wire frame_done;
    reg frame_del;
    wire frame_clean;

    reg [2:0] current_state;
    reg [2:0] next_state;

    localparam [2:0] START = 0;
    localparam [2:0] RIGHT_CAR = 1;
    localparam [2:0] LEFT_CAR = 2;
    localparam [2:0] COLLIDE = 3;
    localparam [2:0] IDLE = 4;
    reg [36:0] cnt;

    //Main display driver
    VGA_driver #(
        .WIDTH(pixel_counter_width)
    )   display_driver (
        //DO NOT CHANGE, clock from basys 3 board
        .clk(clk),
        .vgaRed(vgaRed), .vgaGreen(vgaGreen), .vgaBlue(vgaBlue),
        //DO NOT CHANGE, VGA signal to basys 3 board
        .HS(HS),
        .VS(VS),
        .vgaRGB(vgaRGB),
        //Output pixel clocks
        .pixel_clock(pixel_clock),
        //Horizontal and Vertical pixel coordinates
        .hor_pix(hor_pix),
        .ver_pix(ver_pix)
    );

    bg_rom bg1_rom (
        .clka(clk),
        .addra(bg_rom_addr),
        .douta(bg_color)
    );

    main_car_rom car1_rom (
        .clka(clk),
        .addra(car_rom_addr),
        .douta(car_color)
    );

    assign car_y = 300;
    
    always @ (posedge clk) begin : CAR_LOCATION
        if (hor_pix >= car_x_current && hor_pix < (car_x_current + main_car_width) && ver_pix >= car_y && ver_pix < (car_y + main_car_height)) begin
            car_rom_addr <= (hor_pix - car_x_current) + (ver_pix - car_y)*main_car_width;
            car_on <= 1;
        end
        else begin
            car_on <= 0;
        end
    end
    
    assign frame_done=((hor_pix==799) && (ver_pix==479));

    always @(posedge clk) begin
        frame_del<=frame_done;
    end

    assign frame_clean= ~frame_del & frame_done;

    reg [6:0] frames30;
    reg signal;//signal to indicate end of 30 frames

    always @(posedge clk) begin
        if(BTNC) begin
            frames30 <= 0;
            disp_bg <= 0;
        end
        else if(current_state != COLLIDE) begin
            if(frames30!=4) begin
                signal <= 0;
                if(frame_clean) begin
                    frames30<=(frames30+1)%5;
                end
            end
            else begin
                if(frame_clean) begin
                    signal <= 1;
                    disp_bg <= (disp_bg+1)%239;
                    frames30 <= 0;
                end
                else begin
                    signal <= 0;
                end
            end
        end
        else begin
            signal <= 0;
        end
    end

//    always @(posedge clk) begin : DISP_BLOCK
//        if(cnt2 != 12'd100000000000) begin
//            cnt2<=cnt2+1;
//        end
//        else begin
//            cnt2<=0;
//            if(disp == 239) begin
//                disp <= 0;
//            end
//            else begin
//                disp <= disp + 1;
//            end
//        end
//    end
    // logic for the choice of car location.

    //
    always @ (posedge clk) begin : BG_LOCATION
        if (hor_pix >= 0 + OFFSET_BG_X && hor_pix < bg1_width + OFFSET_BG_X && ver_pix >= 0 + OFFSET_BG_Y && ver_pix < bg1_height + OFFSET_BG_Y) begin
            bg_rom_addr <= (hor_pix - OFFSET_BG_X) + ((ver_pix - OFFSET_BG_Y - disp_bg) % 240)*bg1_width;
            bg_on <= 1;
        end
        else
            bg_on <= 0;
    end
    //ADDED HEHREHEH
    always @ (posedge clk) begin : MUX_VGA_OUTPUT
        if (car_on) begin
            if (car_color==12'b101000001010) begin
                next_color <= bg_color;
            end
            else begin next_color <= car_color;
            end
        end
        else if (bg_on) begin
            next_color <= bg_color;
        end
        else
            next_color <= 0;
    end

    always @ (posedge pixel_clock) begin
        output_color <= next_color;
    end



//    always @(posedge clk) begin
//        if (RIGHT_CAR) begin
//            if(cnt!=12'd100000000000) begin
//                cnt<=cnt+1;
//            end
//            else begin
//                cnt<=0;
//            end
//        end

//        else if(LEFT_CAR) begin
//            if(cnt!=12'd100000000000) begin
//                cnt<=cnt+1;
//            end
//            else begin
//                cnt<=0;
//            end
//        end

//        else begin
//            cnt <= 0;
//        end
//    end

    //a block for logic of collision of the two cars

    //combinational block
    always @(*) begin
        next_state = current_state;
        car_x_next = car_x_current;
        case (current_state)
            START: begin
                car_x_next = 270;
                if(BTNR) begin
                    next_state = RIGHT_CAR;
                    if(signal) begin
                        car_x_next = car_x_current + 10;//to be changed as per smoothness of movement
                    end
                end
                else if(BTNL) begin
                    next_state = LEFT_CAR;
                    if(signal) begin
                        car_x_next = car_x_current - 10;//to be changed as per smoothness of movement
                    end
                end
            end

            RIGHT_CAR: begin
                if(BTNR) begin
                    next_state = RIGHT_CAR;
                    if(signal)
                        car_x_next = car_x_current + 10;//to be changed as per smoothness of movement
                    if(car_x_next > 304) begin
                        next_state = COLLIDE;
                    end
                end
                else begin
                    next_state = IDLE;
                    car_x_next = car_x_current;
                end
            end

            LEFT_CAR: begin
                if(BTNL) begin
                    next_state = LEFT_CAR;
                    if(signal) begin
                        car_x_next = car_x_current - 10;//to be changed as per smoothness of movement
                    end
                    if(car_x_next < 244) begin
                        next_state = COLLIDE;
                    end
                end
                else begin
                    next_state = IDLE;
                    car_x_next = car_x_current;
                end
            end

            COLLIDE: begin
                if(BTNC) begin
                    next_state = START;
                    car_x_next = 270;
                end
                else begin
                    next_state = current_state;
                end
            end

            IDLE: begin
                if(BTNR) begin
                    next_state = RIGHT_CAR;
                    if(signal) begin
                        car_x_next = car_x_current + 10;//to be changed as per smoothness of movement
                    end
                    if(car_x_next > 304) begin
                        next_state = COLLIDE;
                    end
                end
                else if(BTNL) begin
                    next_state = LEFT_CAR;
                    if(signal) begin
                        car_x_next = car_x_current - 10;//to be changed as per smoothness of movement
                    end
                    if(car_x_next < 244) begin
                        next_state = COLLIDE;
                    end
                end
            end

            default: begin
                next_state = 0;
                car_x_next = 270;
            end
        endcase
    end


    always @(posedge clk) begin
        if(BTNC) begin
            current_state <= 0;
            car_x_current <= 270;
        end
        else begin
            current_state <= next_state;
            car_x_current <= car_x_next;
        end
    end

    assign vgaRed = output_color[11:8];
    assign vgaGreen = output_color[7:4];
    
    endmodule 
