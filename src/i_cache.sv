
/*
 * VLSI Design - Project 1 Instruction Cache
 * Fall 2025
 * Sivan Auerbach and William Xu
 * i_cache module 
 */

`define TAG 11:8		// position of tag in address
`define INDEX 7:4		// position of index in address
`define OFFSET 3:0		// position of offset in address
`timescale 1ns / 1ps

module i_cache
#(
  // Cache parameters
	parameter DATA_WIDTH = 32, // data length in bits
	parameter ADD_WIDTH = 12, // address length in bits
	parameter NWAYS = 2, 		
	parameter BLOCK_SIZE = 4, // Block size is 4 Bytes = 2^2 offset bits
	parameter OFFSET_WIDTH = 4, // offset bits
	parameter CACHE_LINES = 16, 
	parameter NSETS = 16, // 16/2(ways) = 8 sets = 2^3 -> 3 bits for index width
	parameter INDEX_WIDTH = 4,
	parameter TAG_WIDTH = 4 ) // = 10-INDEX-OFFSET = 10-4-2= 4

(
	input  wire                      clock,
	// CPU signals
	input  wire [ADD_WIDTH-1:0]          cpu_add,    // address form CPU
	input  wire [DATA_WIDTH-1:0]          cpu_data_in,        // data from CPU (if st inst)
	input  wire                      cpu_ren,        // 1 for read (load),
	input  wire                      cpu_wen,        // 1 for write (store)
	output wire                      hit_miss,   // 1 if hit, 0 while handling miss
	output wire [DATA_WIDTH-1:0]          cpu_data_out,          // data from cache to CPU
	// Memory signals
	input  wire [DATA_WIDTH-1:0]          m_data_in,          // data coming from memory
	output wire [DATA_WIDTH-1:0]          m_data_out,      // data from cache to memory
	output wire [ADD_WIDTH-1:0]          m_rd_address, // memory read address
	output wire [ADD_WIDTH-1:0]          m_wr_address, // memory write address
	output wire                      m_ren,      // read enable, 1 if reading from memory
	output wire                      m_wen      // write enable, 1 if writing to memory
);

/*******************************************************************
* Global Parameters and Initializations
*******************************************************************/

// WAY 1 cache data
reg					valid1 [0:NSETS-1];
reg					dirty1 [0:NSETS-1];
reg					lru1   [0:NSETS-1];
reg [TAG_WIDTH-1:0]	tag1   [0:NSETS-1];
reg [DATA_WIDTH-1:0]	mem1   [0:NSETS-1];

// WAY 2 cache data
reg					valid2 [0:NSETS-1];
reg					dirty2 [0:NSETS-1];
reg					lru2   [0:NSETS-1];
reg [TAG_WIDTH-1:0]	tag2   [0:NSETS-1];
reg [DATA_WIDTH-1:0]	mem2   [0:NSETS-1];

// initialize everything to 0
integer k;
initial
begin
	for(k = 0; k < NSETS; k = k +1)
	begin
		valid1[k] = 0;
		valid2[k] = 0;
		dirty1[k] = 0;
		dirty2[k] = 0;
		lru1[k] = 0;
		lru2[k] = 0;
		tag1[k] = {TAG_WIDTH{1'b0}};
		tag2[k] = {TAG_WIDTH{1'b0}};
	end
end

// internal registers
reg					_hit_miss = 1'b0;
reg [DATA_WIDTH-1:0]		_cpu_data_out = {DATA_WIDTH{1'b0}};
reg [DATA_WIDTH-1:0]		_m_data_out = {DATA_WIDTH{1'b0}};
reg [ADD_WIDTH-1:0]		_m_wr_address = {ADD_WIDTH{1'b0}};
reg					_m_wen = 1'b0;

// output assignments of internal registers
assign hit_miss = _hit_miss;
assign m_ren = !((valid1[cpu_add[`INDEX]] && (tag1[cpu_add[`INDEX]] == cpu_add[`TAG]))
				|| (valid2[cpu_add[`INDEX]] && (tag2[cpu_add[`INDEX]] == cpu_add[`TAG])));
assign m_wen = _m_wen;
assign m_data_out = _m_data_out;
// assign m_rd_address = {cpu_add[`TAG], cpu_add[`INDEX]};
assign m_rd_address = cpu_add;
assign m_wr_address = _m_wr_address;
assign cpu_data_out = _cpu_data_out;

// state parameters
parameter idle = 1'b0;		// receive requests from CPU 
parameter miss = 1'b1;	// miss state: write back dirty block and request memory data

// state register
reg currentState = idle;

/*******************************************************************
* State Machine
*******************************************************************/

always @(posedge clock)
begin
	case (currentState)
		idle: begin
			// reset write enable, if it was turned on
			_m_wen <= 0;
			// set _hit_miss register
			_hit_miss <= ((valid1[cpu_add[`INDEX]] && (tag1[cpu_add[`INDEX]] == cpu_add[`TAG]))
							||  (valid2[cpu_add[`INDEX]] && (tag2[cpu_add[`INDEX]] == cpu_add[`TAG])));

			// do nothing on null request
			if(!(cpu_ren || cpu_wen)) currentState <= idle; // TODO: what if don't want to read or write
			
			// check way 1
			else if(valid1[cpu_add[`INDEX]] && (tag1[cpu_add[`INDEX]] == cpu_add[`TAG]))
			begin
				// read hit
				if(cpu_ren) _cpu_data_out <= mem1[cpu_add[`INDEX]];
				// write hit
				else if (cpu_wen)
				begin
					_cpu_data_out <= {DATA_WIDTH{1'b0}};
					mem1[cpu_add[`INDEX]] <= cpu_data_in;
					dirty1[cpu_add[`INDEX]] <= 1;
				end
				// update LRU data
				lru1[cpu_add[`INDEX]] <= 0;
				lru2[cpu_add[`INDEX]] <= 1;
			end
			
			// check way 2
			else if(valid2[cpu_add[`INDEX]] && (tag2[cpu_add[`INDEX]] == cpu_add[`TAG]))
			begin
				// read hit
				if(cpu_ren) _cpu_data_out <= mem2[cpu_add[`INDEX]];
				// write hit
				else if(cpu_wen)
				begin
					_cpu_data_out <= {DATA_WIDTH{1'b0}};
					mem2[cpu_add[`INDEX]] <= cpu_data_in;
					dirty2[cpu_add[`INDEX]] <= 1;
				end
				// update LRU data
				lru1[cpu_add[`INDEX]] <= 1;
				lru2[cpu_add[`INDEX]] <= 0;
			end
			
			// miss
			else currentState <= miss;
		end
	
		miss: begin
			// one of the ways is invalid -- no need to evict
			if(~valid1[cpu_add[`INDEX]])
			begin
				mem1[cpu_add[`INDEX]] <= m_data_in;
				tag1[cpu_add[`INDEX]] <= cpu_add[`TAG];
				dirty1[cpu_add[`INDEX]] <= 0;
				valid1[cpu_add[`INDEX]] <= 1;
			end
			
			else if(~valid2[cpu_add[`INDEX]])
			begin
				mem2[cpu_add[`INDEX]] <= m_data_in;
				tag2[cpu_add[`INDEX]] <= cpu_add[`TAG];
				dirty2[cpu_add[`INDEX]] <= 0;
				valid2[cpu_add[`INDEX]] <= 1;
			end
			
			// way 1 is LRU
			else if(lru1[cpu_add[`INDEX]] == 1)
			begin
				// dirty block writeback
				if(dirty1[cpu_add[`INDEX]] == 1)
				begin
					_m_wr_address <= {tag1[cpu_add[`INDEX]],cpu_add[`INDEX]}; 
					_m_wen <= 1;
					_m_data_out <= mem1[cpu_add[`INDEX]];
				end
				mem1[cpu_add[`INDEX]] <= m_data_in;
				tag1[cpu_add[`INDEX]] <= cpu_add[`TAG];
				dirty1[cpu_add[`INDEX]] <= 0;
				valid1[cpu_add[`INDEX]] <= 1;
			end
			
			// way 2 is LRU
			else if(lru2[cpu_add[`INDEX]] == 1)
			begin
				// dirty block writeback
				if(dirty2[cpu_add[`INDEX]] == 1)
				begin
					_m_wr_address <= {tag2[cpu_add[`INDEX]],cpu_add[`INDEX]}; 
					_m_wen <= 1;
					_m_data_out <= mem2[cpu_add[`INDEX]];
				end
				mem2[cpu_add[`INDEX]] <= m_data_in;
				tag2[cpu_add[`INDEX]] <= cpu_add[`TAG];
				dirty2[cpu_add[`INDEX]] <= 0;
				valid2[cpu_add[`INDEX]] <= 1;
			end

			currentState <= idle;
		end

		default: currentState <= idle;

	endcase

end

endmodule