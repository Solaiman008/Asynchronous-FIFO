module tb_top;

    parameter int DATA_WIDTH = 32;
    parameter int FIFO_DEPTH = 16;
    parameter int ADDR_SIZE = $clog2(FIFO_DEPTH);

	logic [DATA_WIDTH-1:0] wr_data;
	logic wr_en;
	logic rd_en;
	logic wr_clk;
	logic rd_clk;
	logic arst_n;

	logic [DATA_WIDTH-1:0] rd_data;
	logic full;
	logic empty;


    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) dut(
        .wr_data(wr_data),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .wr_clk(wr_clk),
		.rd_clk(rd_clk),
		.arst_n(arst_n),

        .rd_data(rd_data),
        .full(full),
        .empty(empty)
    );


    initial begin
        wr_clk = 0;

		forever 
            #5 wr_clk = ~wr_clk;
    end

	initial begin
		rd_clk = 0;

		forever
			#10 rd_clk = ~rd_clk;
	end

	initial begin
		arst_n = 0;
		wr_en = 0;
		rd_en = 0;

		#25;
		arst_n = 1;
		
		if(full)
			$display("ERROR. FIFO should not be full after reset");
		else
			$display("FIFO is not full after reset");

		if(empty)
			$display("FIFO is empty after reset");
		else
			$display("ERROR. FIFO should be empty after reset");


		@(negedge wr_clk)
		wr_en = 1;
		wr_data = 32;

		@(negedge wr_clk);
		wr_en = 0;
		wr_data = 'x;

		@(posedge rd_clk);
       
		if(empty)
            $display("FIFO is empty after one cycle of write");
        else
            $display("ERROR. FIFO should be empty after one cycle of write");

		@(posedge rd_clk);
		@(negedge rd_clk);
        if(empty)
            $display("ERROR. FIFO should not be empty after two cycles of write");
        else
            $display("FIFO is not empty after two cycles of write");			
		

		rd_en = 1;
		@(posedge rd_clk);
		@(negedge rd_clk);
        if(empty)
            $display("FIFO is empty after read");
        else
            $display("ERROR. FIFO should be empty after read");
		rd_en = 0;


		@(negedge wr_clk);
		wr_en = 1;
		wr_data = 25;

		@(negedge wr_clk);
		wr_data = 50;

		@(negedge wr_clk);
		wr_en <= 0;
		wr_data <= 'x;

		repeat(2)
			@(posedge rd_clk);

		rd_en = 1;
		@(negedge rd_clk);
		if(rd_data == 25)
			$display("Expected 25, got %d", rd_data);
		else
			$display("ERROR.Expected 25, got %d", rd_data);

        @(negedge rd_clk);
        if(rd_data == 50)
            $display("Expected 50, got %d", rd_data);
        else
            $display("ERROR.Expected 50, got %d", rd_data);
		
		@(negedge rd_clk);
		rd_en = 0;

		$display("\nFULL Check");
		@(negedge wr_clk);
		wr_en = 1;

        for(int i = 0; i <  FIFO_DEPTH; i++) begin
			wr_data = i + 10; 
			@(negedge wr_clk);
        end
   
        wr_en = 0;
		wr_data ='x;

		fork 
            begin
                wait(full);
                $display("Full test passed");
            end
            begin
				repeat(3)
                	@(posedge wr_clk);
                $display("ERROR. Full Test failed");
            end
        join_any

		disable fork;
		
		$display("\nEMPTY FULL FIFO CHECK");

        @(posedge rd_clk);
        rd_en = 1;

        for(int i = 0; i <  FIFO_DEPTH; i++) begin
			@(negedge rd_clk);
        	if(rd_data == i+10)
                $display("Read %d passed", i);
            else
                $display("Read %d failed", i);
        end

		@(negedge rd_clk);
		rd_en = 0;
        fork
            begin
                wait(empty);
                $display("Empty full fifo test passed");
            end
            begin
				repeat(3)
                	@(posedge rd_clk);
                $display("ERROR. Empty full fifo Test failed");
            end
        join_any

		disable fork;

		$display("\nSIMULTANEOUS READ AND WRITE");

		fork
			begin
				@(negedge wr_clk);
				wr_en = 1;

        		for(int i = 0; i <  10*FIFO_DEPTH; i++) begin
					if(full) begin
						$display("FIFO is full. Wait for read.");
						wr_en = 0;
						wr_data = 'x;
						wait(!full);
						@(negedge wr_clk);
						wr_en = 1;
					end

            		wr_data = i + 20;
           			 @(negedge wr_clk);
       			 end

				wr_en = 0;
				wr_data ='x;
			end

			begin

				wait(!empty);
				rd_en = 1;
        		for(int i = 0; i < 10*FIFO_DEPTH; i++) begin
					if(empty) begin
						$display("FIFO is empty. Wait for write.");
						rd_en = 0;
						wait(!empty);
						@(negedge rd_clk);
						rd_en = 1;
					end

            		@(negedge rd_clk);
           			if(rd_data == i+20)
                		$display("Read %d passed", i);
            		else
                		$display("Read %d failed", i);
        		end

        		@(negedge rd_clk);
        		rd_en = 0;
				#30;
			end
		join




		$finish;
	end
	
	initial begin
		$dumpfile("dump.vcd");
		$dumpvars;
	end
endmodule

