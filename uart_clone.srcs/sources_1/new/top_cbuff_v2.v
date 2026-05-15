`timescale 1ns / 1ps
`include "../imports/rtl/uart_regs_defs.v"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/15/2026 04:13:35 AM
// Design Name: 
// Module Name: top_cbuff_v2
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


module top_cbuff_v2(
    CLK100MHZ,
    btn,
    led,
    uart_rxd_out,
    uart_txd_in,
    sw
    );
    input CLK100MHZ, uart_txd_in;
    input [0:0] btn;
    input [3:0] sw;

    output uart_rxd_out;
    output [3:0] led;

    wire clk_i = CLK100MHZ, rst_i = btn[0];

    //
    reg [7:0] top_uart_addr_i;
    reg [31:0] top_uart_data_i;
    reg top_uart_we_i;
    reg top_uart_stb_i;

    //
    wire [7:0] uart_loop_addr_i;
    wire [31:0] uart_loop_data_i;
    wire uart_loop_we_i;
    wire uart_loop_stb_i;

    //
    wire is_default_config_ok;
    wire uart_inst_clk_i = clk_i;
    wire uart_inst_rst_i = rst_i;
    // wire uart_inst_intr_o = ;
    wire uart_inst_tx_o = uart_rxd_out;
    wire uart_inst_rx_i = uart_txd_in;
    wire uart_inst_ack_o;
    wire [31:0] uart_inst_data_o;
    wire [7:0] uart_inst_addr_i = is_default_config_ok ? top_uart_addr_i : uart_loop_addr_i;
    wire [31:0] uart_inst_data_i = is_default_config_ok ? top_uart_data_i : uart_loop_data_i;
    wire uart_inst_we_i = is_default_config_ok ? top_uart_we_i : uart_loop_we_i;
    wire uart_inst_stb_i = is_default_config_ok ? top_uart_stb_i : uart_loop_stb_i;
    wire uart_inst_uart_tx_busy_o;

    uart_loop_cbuff uart_loop_cbuff_inst (
        .CLK100MHZ(CLK100MHZ),
        .btn(btn),
        .sw(sw),
        // .led(led),
        .is_default_config_ok_o(is_default_config_ok),
        .uart_pin_ack_o(uart_inst_ack_o),
        .uart_pin_stb_i(uart_loop_stb_i),
        .uart_pin_we_i(uart_loop_we_i),
        .uart_pin_addr_i(uart_loop_addr_i),
        .uart_pin_data_i(uart_loop_data_i),
        .uart_pin_data_o(uart_inst_data_o)
    );

    uart_wb #(
        .UART_DIVISOR_W(10),
        .UART_DIVISOR_DEFAULT(1),
        .UART_STOP_BITS_DEFAULT(0)
    ) uart_inst (
        .clk_i(uart_inst_clk_i), // Connect clock
        .rst_i(uart_inst_rst_i), // Connect reset
        .intr_o(), // Connect interrupt output
        .tx_o(uart_inst_tx_o), // Connect UART TX output
        .rx_i(uart_inst_rx_i), // Connect UART RX input
        .addr_i(uart_inst_addr_i), // Connect Wishbone address input
        .data_o(uart_inst_data_o), // Connect Wishbone data output
        .data_i(uart_inst_data_i), // Connect Wishbone data input
        .we_i(uart_inst_we_i), // Connect Wishbone write enable
        .stb_i(uart_inst_stb_i), // Connect Wishbone strobe
        .ack_o(uart_inst_ack_o),  // Connect Wishbone acknowledge output
        .uart_tx_busy_o(uart_inst_uart_tx_busy_o)
    );

    // get uart status
    reg top_uart_rx_status, top_uart_rx_status_toggle, top_uart_rx_data_ready;

    reg [7:0] top_uart_rx_data;
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            top_uart_addr_i <= `UART_USR;
            top_uart_data_i <= 32'b0;
            top_uart_we_i <= 1'b0;
            top_uart_stb_i <= 1'b1;

            top_uart_rx_status <= 1'b0;
            top_uart_rx_status_toggle <= 1'b0;
            top_uart_rx_data_ready <= 1'b0;
        end
        else if (is_default_config_ok)  begin
            if (uart_inst_ack_o) begin
                if (top_uart_addr_i == `UART_USR && uart_inst_data_o[0]) begin
                    top_uart_addr_i <= `UART_UDR;
                    
                    top_uart_rx_status_toggle <= top_uart_rx_status_toggle + uart_inst_data_o[0];
                    top_uart_rx_status <= uart_inst_data_o[0];
                end
                else if (top_uart_addr_i == `UART_UDR && (~top_uart_we_i) && top_uart_rx_status && ~top_uart_rx_data_ready) begin
                    top_uart_rx_data = uart_inst_data_o[7:0];
                    top_uart_rx_status <= 1'b0;
                    top_uart_addr_i <= `UART_USR;
                    top_uart_rx_data_ready <= 1'b1;
                end
                else if (~top_uart_we_i && top_uart_rx_data_ready) begin
                    top_uart_we_i <= 1'b1;
                    top_uart_rx_data_ready <= 1'b0;
                    top_uart_data_i[7:0] <= top_uart_rx_data;
                    top_uart_addr_i <= `UART_UDR;
                end
                else if (top_uart_we_i) begin
                    top_uart_we_i <= 1'b0;
                    top_uart_addr_i <= `UART_USR;         
                end
            end
        end
    end

    //
    reg [7:0] uart_rx_fifo_wdata_i;
    reg uart_rx_fifo_wr_en_i, uart_rx_fifo_rd_en_i;
    wire uart_rx_fifo_full_o, uart_rx_fifo_empty_o;
    wire [7:0] uart_rx_fifo_rdata_o;

    //
    reg uart_rx_fifo_wr_cplt;

    fifo #(
        .WIDTH(8),
        .DEPTH(16)
        ) uart_rx_fifo (
            .clk_i(clk_i),
            .rst_n_i(~rst_i),
            .wdata_i(uart_rx_fifo_wdata_i),
            .wr_en_i(uart_rx_fifo_wr_en_i),
            .full_o(uart_rx_fifo_full_o),
            .rdata_o(uart_rx_fifo_rdata_o),
            .rd_en_i(uart_rx_fifo_rd_en_i),
            .empty_o(uart_rx_fifo_empty_o)
        );

    // rx ff fifo write control
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            uart_rx_fifo_wdata_i <= 8'b0;
            uart_rx_fifo_wr_en_i <= 1'b0;
            uart_rx_fifo_rd_en_i <= 1'b0;
            uart_rx_fifo_wr_cplt <= 1'b0;
        end
        else if (is_default_config_ok) begin
            if (top_uart_rx_data_ready && ~uart_rx_fifo_wr_cplt) begin
                uart_rx_fifo_wdata_i <= top_uart_rx_data;
                uart_rx_fifo_wr_en_i <= 1'b1;
                uart_rx_fifo_wr_cplt <= 1'b1;
            end
            else if (uart_rx_fifo_wr_cplt) begin
                uart_rx_fifo_wr_en_i <= 1'b0;
                uart_rx_fifo_wr_cplt <= 1'b0;
            end
        end
    end

    reg uart_rx_fifo_wr_cplt_toggle;
    always @(posedge uart_rx_fifo_wr_cplt or posedge rst_i) begin
        if (rst_i) begin
            uart_rx_fifo_wr_cplt_toggle <= 1'b0;
        end
        else begin
            uart_rx_fifo_wr_cplt_toggle <= uart_rx_fifo_wr_cplt_toggle + 1'b1;
        end
    end

    assign led = {uart_rx_fifo_full_o, uart_rx_fifo_wr_cplt_toggle, top_uart_rx_status_toggle, is_default_config_ok};
endmodule
