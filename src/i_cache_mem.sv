
/*
 * VLSI Design - Project 1 Instruction Cache
 * Fall 2025
 * Sivan Auerbach and William Xu
 * memory module  
 */

`timescale 1ns / 1ps

module i_cache_mem
#(
  parameter DATA_WIDTH = 32,
  parameter ADD_WIDTH = 12,
  parameter DEPTH = 4096, // = 2^add_width
  parameter MEM_FILE = "",
  parameter INIT = 0
)
(
  input  wire                 clock,
  input  wire [ADD_WIDTH-1:0] rdaddress,
  input  wire [ADD_WIDTH-1:0] wraddress,
  input  wire                 rden,
  input  wire                 wden,
  input  wire [DATA_WIDTH-1:0]     data,
  output reg  [DATA_WIDTH-1:0]     data_out
);

  reg [DATA_WIDTH-1:0] mem [DEPTH-1:0];

  integer file;
  integer scan;
  integer i;

  initial
    begin
      // read file contents if MEM_FILE is given
      if (MEM_FILE != "")
        // If you get error here, check path to MEM_FILE
        $readmemh(MEM_FILE, mem);

      // set all data to 0 if INIT is true
      // if (INIT)
        for (i = 0; i < DEPTH; i = i + 1)
          mem[i] = {DATA_WIDTH{1'b0}};
   end

  always @ (posedge clock)
  begin
    if (wden)
      mem[wraddress] <= data;
  end

  always @ (posedge clock)
  begin
    if (rden)
      data_out <= mem[rdaddress];
  end

endmodule
