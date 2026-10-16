module async_fifo #(
	parameter int DATA_WIDTH = 32,
	parameter int FIFO_DEPTH = 16
)(
	input logic [DATA_WIDTH-1:0] wr_data,
	input logic wr_en,
	input logic rd_en,
	input logic wr_clk,
	input logic rd_clk,
	input logic arst_n,

	output logic [DATA_WIDTH-1:0] rd_data,
	output logic full,
	output logic empty
);

	localparam int ADDR_SIZE = $clog2(FIFO_DEPTH);

	logic [ADDR_SIZE-1:0] rd_addr, wr_addr;
	logic [ADDR_SIZE:0] rd_ptr, wr_ptr, rd_ptr_sync, wr_ptr_sync;
	logic [DATA_WIDTH-1:0] reg_file[FIFO_DEPTH-1:0];
	logic write;
	logic read;

	always_comb begin
		wr_addr = {wr_ptr[ADDR_SIZE]^wr_ptr[ADDR_SIZE-1], wr_ptr[ADDR_SIZE-2:0]};
		rd_addr = {rd_ptr[ADDR_SIZE]^rd_ptr[ADDR_SIZE-1], rd_ptr[ADDR_SIZE-2:0]};

		if({~wr_ptr[ADDR_SIZE], ~wr_ptr[ADDR_SIZE-1], wr_ptr[ADDR_SIZE-2:0]} == rd_ptr_sync)
			full = 1;
		else
			full = 0;

		if(wr_ptr_sync == rd_ptr)
            empty = 1;
        else
 			empty = 0;

		write = ~full & wr_en;
		read = ~empty & rd_en;

		rd_data = reg_file[rd_addr];
	end

	sync #(
		 .FIFO_DEPTH(FIFO_DEPTH)
	) rd_sync(
		.clk(wr_clk),
		.arstn(arst_n),
		.data_in(rd_ptr),
		.sync_out(rd_ptr_sync));
	
	sync #(
		.FIFO_DEPTH(FIFO_DEPTH)
 	) wr_sync(
 		.clk(rd_clk),
		.arstn(arst_n),
		.data_in(wr_ptr),
		.sync_out(wr_ptr_sync));

	gray_count #(
		.FIFO_DEPTH(FIFO_DEPTH)
	) wr_count(
		.clk(wr_clk),
		.arstn(arst_n),
		.enable(write),
		.ptr(wr_ptr)
	);

	gray_count #(
		.FIFO_DEPTH(FIFO_DEPTH)
	) rd_count(
		.clk(rd_clk),
		.arstn(arst_n),
		.enable(read),
		.ptr(rd_ptr));

	always_ff @(posedge wr_clk) begin
		if(write)
			reg_file[wr_addr] <= wr_data;
	end

endmodule

module sync #(
    parameter int FIFO_DEPTH = 16
)(
	input logic clk,
	input logic arstn,
	input logic [$clog2(FIFO_DEPTH):0] data_in,

	output logic [$clog2(FIFO_DEPTH):0] sync_out
);
	logic [$clog2(FIFO_DEPTH):0] sync_int;
	
	always_ff @(posedge clk, negedge arstn) begin
		if(!arstn) begin
			sync_int <= 0;
			sync_out <= 0;
		end

		else begin
			sync_int <= data_in;
			sync_out <= sync_int;
		end
	end
endmodule

module gray_count #(
	parameter int FIFO_DEPTH = 16
)(
	input logic clk,
	input logic arstn,
	input logic enable,

	output logic [$clog2(FIFO_DEPTH):0] ptr
);
	logic [$clog2(FIFO_DEPTH):0] bin_ptr;

	always_ff @(posedge clk, negedge arstn) begin
		if(!arstn)
			bin_ptr <= 0;
		else if(enable)
			bin_ptr <= bin_ptr + 1;
	end

	assign ptr = bin_ptr ^ (bin_ptr >> 1);
endmodule

