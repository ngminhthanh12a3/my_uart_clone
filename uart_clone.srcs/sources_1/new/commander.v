`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/22/2026 02:23:44 AM
// Design Name: 
// Module Name: commander
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


module commander(
    clk_i,
    rst_i,
    exec_trigger_i,
    cmd_i,
    data_len_i,
    data_rd_i,
    //
    tx_mem_rd_e_i,

    //
    data_rd_e_o,
    busy_o,
    ack_data_rd_o,
    //
    tx_mem_empty_o,
    tx_mem_data_o
    );
    input clk_i, rst_i, exec_trigger_i, tx_mem_rd_e_i;
    input [7:0] cmd_i, data_len_i, data_rd_i;

    output reg data_rd_e_o, busy_o, ack_data_rd_o;
    output tx_mem_empty_o;
    output [7:0] tx_mem_data_o;

    // reg [7:0] tx_mem[0:255];

    reg interal_data_rd_ready;
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            data_rd_e_o <= 1'b0;
            busy_o <= 1'b0;
            ack_data_rd_o <= 1'b0;
            interal_data_rd_ready <= 1'b0;
        end
        else if (ack_data_rd_o) begin
            ack_data_rd_o <= 1'b0;
        end
        else if (exec_trigger_i) begin
            if (cmd_i == 1'b0) begin
                if (~busy_o) begin
                    // data_rd_e_o <= 1'b1;
                    busy_o <= 1'b1;
                    interal_data_rd_ready <= 1'b1;
                end
                else if (tx_mem_drive_data_cplt) begin
                    ack_data_rd_o <= 1'b1;
                    busy_o <= 1'b0;
                    interal_data_rd_ready <= 1'b0;
                end
            end
        end
    end

    //
    // reg [7:0] tx_mem_wr_ptr, tx_mem_rd_ptr;
    reg tx_mem_wait_for_data, tx_mem_drive_data_in, tx_mem_drive_data_cplt;
    reg [9:0] tx_mem_data_cnt;

    reg [7:0] tx_fifo_wdata_i;
    // reg tx_fifo_wr_en_i;
    wire tx_fifo_full_o, tx_fifo_empty_o;
    wire [7:0] tx_fifo_rdata_o;
    
    fifo #(
        .WIDTH(8),
        .DEPTH(256)
    ) tx_fifo (
        .clk_i(clk_i),
        .rst_n_i(~rst_i),
        .wdata_i(tx_fifo_wdata_i),
        .wr_en_i(tx_mem_drive_data_in),
        .full_o(tx_fifo_full_o),
        .rdata_o(tx_fifo_rdata_o),
        .rd_en_i(tx_mem_rd_e_i),
        .empty_o(tx_fifo_empty_o)
    );

    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            tx_mem_wait_for_data <= 1'b0;
            tx_mem_drive_data_in <= 1'b0;
            tx_mem_drive_data_cplt <= 1'b0;
            tx_mem_data_cnt <= 10'b0;
            // tx_mem_wr_ptr <= 8'b0;
            tx_fifo_wdata_i <= 8'b0;
            // tx_fifo_wr_en_i <= 1'b0;

        end
        else if (~tx_mem_wait_for_data && exec_trigger_i && ~interal_data_rd_ready) begin
            tx_mem_wait_for_data <= 1'b1;
            tx_mem_drive_data_in <= 1'b0;
            tx_mem_data_cnt <= 10'b0;
            tx_mem_drive_data_cplt <= 1'b0;
        end
        else if (tx_mem_wait_for_data && interal_data_rd_ready) begin
            tx_mem_wait_for_data <= 1'b0;
            tx_mem_drive_data_in <= 1'b1;
        end
        else if (tx_mem_drive_data_in && ~tx_fifo_full_o) begin
            
            if (tx_mem_data_cnt == 10'b0) begin
                tx_fifo_wdata_i <= 8'hab;
                
                tx_mem_data_cnt <= tx_mem_data_cnt + 1'b1;
            end
            else if (tx_mem_data_cnt == 10'b1) begin
                tx_fifo_wdata_i <= 8'hcd;

                tx_mem_data_cnt <= tx_mem_data_cnt + 1'b1;
            end
            else if (cmd_i == 8'b0) begin
                if (tx_mem_data_cnt == 10'd2) begin
                    tx_fifo_wdata_i <= 8'h00;

                    tx_mem_data_cnt <= tx_mem_data_cnt + 1'b1;
                end
                else if (tx_mem_data_cnt == 10'd3) begin
                    tx_fifo_wdata_i <= 8'h01;
                    tx_mem_data_cnt <= tx_mem_data_cnt + 1'b1;
                end
                else if (tx_mem_data_cnt == 10'd4) begin
                    tx_fifo_wdata_i <= 8'h01;
                    tx_mem_data_cnt <= tx_mem_data_cnt + 1'b1;
                end
                else if (tx_mem_data_cnt == 10'd5) begin
                    tx_fifo_wdata_i <= 8'hab;
                    tx_mem_data_cnt <= tx_mem_data_cnt + 1'b1;
                end
                else if (tx_mem_data_cnt == 10'd6) begin
                    tx_fifo_wdata_i <= 8'hcd;
                    tx_mem_data_cnt <= tx_mem_data_cnt + 1'b1;

                end
                else if (tx_mem_data_cnt == 10'd7) begin
                    tx_mem_drive_data_in <= 1'b0;
                    tx_mem_drive_data_cplt <= 1'b1;
                    
                end
            end
        end
    end

    //
    // always @(posedge clk_i or posedge rst_i) begin
    //     if (rst_i) begin
    //         tx_mem_rd_ptr <= 8'b0;
    //     end
    //     else if (tx_mem_rd_e_i && (~interal_data_rd_ready)) begin
    //         tx_mem_rd_ptr <= tx_mem_rd_ptr + 1'b1;
    //     end
    // end

    assign tx_mem_data_o = tx_fifo_rdata_o;
    assign tx_mem_empty_o = tx_fifo_empty_o;
endmodule
