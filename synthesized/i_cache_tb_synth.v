
/*
 * VLSI Design - Project 1 Instruction Cache
 * Fall 2025
 * Sivan Auerbach and William Xu
 * i_cache testbench 
 */


`timescale 1ns / 1ps

module i_cache_tb #(parameter DATA_WIDTH = 32,parameter ADD_WIDTH = 12)();
  reg clk;

  reg  [ADD_WIDTH-1:0] i_cache_addr = 0;
  reg  [DATA_WIDTH-1:0] i_cache_din = 0;
  reg         i_cache_rden = 0;
  reg         i_cache_wren = 0;
  wire        i_cache_hit_miss;
  wire [DATA_WIDTH-1:0] cpu_data_out;

  //defparam DUT.ADD_WIDTH = ADD_WIDTH;
  //defparam DUT.DATA_WIDTH = DATA_WIDTH;
  //defparam DUT.MEM_FILE = "i_mem_data.txt";

  i_cache_top DUT (
    // inputs from testbench:    
    .clk(clk),
    .i_cache_addr(i_cache_addr),
    .i_cache_din(i_cache_din),
    // outputs  to testbench 
    .i_cache_hit_miss(i_cache_hit_miss),
    .cpu_data_out(cpu_data_out)
  );

  always
    begin

      // basic writeback /////////////////////////////////////////////////////////////////////////////////////////////////////////

      # 30; // This should be a miss

      i_cache_addr <= 12'hABC;
      i_cache_din <= 0;
      i_cache_rden <= 1;
      i_cache_wren <= 0;

      # 30; // This should be a hit

      i_cache_addr <= 12'hABC;
      i_cache_din <= 32'hBADDBEEF;
      i_cache_rden <= 0;
      i_cache_wren <= 1;

      # 30; // This should be a miss

      i_cache_addr <= 12'h1BC;
      i_cache_din <= 0;
      i_cache_rden <= 1;
      i_cache_wren <= 0;

      # 30; // This should be a miss

      i_cache_addr <= 12'h203;
      i_cache_din <= 0;
      i_cache_rden <= 1;
      i_cache_wren <= 0;

      # 30; // This should be a miss (evicted)

      i_cache_addr <= 12'hABC;
      i_cache_din <= 0;
      i_cache_rden <= 1;
      i_cache_wren <= 0;

      # 30; // This should be a hit

      i_cache_addr <= 12'h203;
      i_cache_din <= 0;
      i_cache_rden <= 1;
      i_cache_wren <= 0;

      // repeated writes (w/ offset) /////////////////////////////////////////////////////////////////////////////////////////////////////////

      # 30; // This should be a miss

      i_cache_addr <= 12'h004;
      i_cache_din <= 0;
      i_cache_rden <= 1;
      i_cache_wren <= 0;

      # 30; // This should be a hit

      i_cache_addr <= 12'h004;
      i_cache_din <= 32'hBADDBEEF;
      i_cache_rden <= 0;
      i_cache_wren <= 1;

      # 30; // This should be a hit

      i_cache_addr <= 12'h006;
      i_cache_din <= 32'h000;
      i_cache_rden <= 0;
      i_cache_wren <= 1;

      # 30; // This should be a miss

      i_cache_addr <= 12'h104;
      i_cache_din <= 0;
      i_cache_rden <= 1;
      i_cache_wren <= 0;

      # 30; // This should be a miss

      i_cache_addr <= 12'h204;
      i_cache_din <= 0;
      i_cache_rden <= 1;
      i_cache_wren <= 0;

      # 30; // This should be a miss (evicted)

      i_cache_addr <= 12'h004;
      i_cache_din <= 0;
      i_cache_rden <= 1;
      i_cache_wren <= 0;

      # 30; // This should be a hit

      i_cache_addr <= 12'h204;
      i_cache_din <= 0;
      i_cache_rden <= 1;
      i_cache_wren <= 0;

      // repeated reads (w/ offset) /////////////////////////////////////////////////////////////////////////////////////////////////////////

      # 30; // This should be a miss

      i_cache_addr <= 12'h004;
      i_cache_din <= 0;
      i_cache_rden <= 1;
      i_cache_wren <= 0;

      # 30; // This should be a miss

      i_cache_addr <= 12'h104;
      i_cache_din <= 0;
      i_cache_rden <= 1;
      i_cache_wren <= 0;

      # 30; // This should be a hit

      i_cache_addr <= 12'h005;
      i_cache_din <= 32'hBADDBEEF;
      i_cache_rden <= 1;
      i_cache_wren <= 0;

      # 30; // This should be a hit

      i_cache_addr <= 12'h106;
      i_cache_din <= 32'h000;
      i_cache_rden <= 1;
      i_cache_wren <= 0;

      # 30; // This should be a hit

      i_cache_addr <= 12'h007;
      i_cache_din <= 32'hAAAAAAAA;
      i_cache_rden <= 1;
      i_cache_wren <= 0;

      #50;

      /*
      integer i;
      for (i = 0; i < DUT_MEM.DEPTH; i = i + 1)
      begin
        $display("%b", DUT_MEM.mem[i]);
      end*/

      $finish;
    end

  initial
  begin
    $monitor("time=%3d, addr=%1h, cpu_data_in=%1h, cpu_ren=%1b, cpu_wen=%1b, cpu_data_out=%1h, hit_miss=%1b", $time,i_cache_addr,i_cache_din,i_cache_rden,i_cache_wren,cpu_data_out,i_cache_hit_miss);
    // $monitor("time=%4d | addr=%10d | hm=%b | cpu_data_out=%08x | way1=%08h | way2=%08h | mem1=%08h | lru1=%d | lru2=%d" ,$time,i_cache_addr,i_cache_hit_miss,DUT_CACHE.cpu_data_out,DUT_CACHE.mem1[1],DUT_CACHE.mem2[1],DUT_MEM.mem[1],DUT_CACHE.lru1[1],DUT_CACHE.lru2[1]);
    
    // Simulate with Xcelium:
    $dumpfile("simulation_output.vcd");
    $dumpvars;
  end
 
  always
    begin
      clk = 1'b1;
      #5;
      clk = 1'b0;
      #5;
    end
   
endmodule
