`timescale 1ns / 1ps


module i_cache_top #(parameter DATA_WIDTH = 32,parameter ADD_WIDTH = 12, parameter MEM_FILE = "")(

    // inputs from testbench:
    input wire  clk,
    input wire  [ADD_WIDTH-1:0] i_cache_addr,
    input wire  [DATA_WIDTH-1:0] i_cache_din,
    input wire         i_cache_rden,
    input wire         i_cache_wren,

    // outputs  to testbench 
    output wire        i_cache_hit_miss,
    output wire [DATA_WIDTH-1:0] cpu_data_out
);

    // Internal wires between cache and memory
    wire [DATA_WIDTH-1:0]   data_in;
    wire [DATA_WIDTH-1:0]   data_out;
    wire [ADD_WIDTH-1:0]    rd_addr;
    wire                    rd_en;
    wire [ADD_WIDTH-1:0]    wr_addr;
    wire                    wr_en;


    // defparam DUT_CACHE.NWAYS = 4;
    // defparam DUT_CACHE.NSETS = 128;
    // defparam DUT_CACHE.BLOCK_SIZE = 32;
    // defparam DUT_CACHE.WIDTH = 32;

    i_cache DUT_CACHE (
        .clock(clk),
        .cpu_add(i_cache_addr),
        .cpu_data_in(i_cache_din),
        .cpu_ren(i_cache_rden),
        .cpu_wen(i_cache_wren),
        .hit_miss(i_cache_hit_miss),
        .cpu_data_out(cpu_data_out),
        .m_data_out(data_in),
        .m_rd_address(rd_addr),
        .m_ren(rd_en),
        .m_wr_address(wr_addr),
        .m_wen(wr_en),
        .m_data_in(data_out)
    );

    defparam DUT_MEM.ADD_WIDTH = ADD_WIDTH;
    defparam DUT_MEM.DATA_WIDTH = DATA_WIDTH;
    defparam DUT_MEM.MEM_FILE = "i_mem_data.txt";

    i_cache_mem DUT_MEM (
        .clock(clk),
        .data(data_in),
        .rdaddress(rd_addr),
        .rden(rd_en),
        .wraddress(wr_addr),
        .wden(wr_en),
        .data_out(data_out)
        );


endmodule