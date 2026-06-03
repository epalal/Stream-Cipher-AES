module stream_cipher_aes_tb;

    reg clk = 1'b0; 
    always #5 clk = !clk;
    reg rst_n = 1'b0; 
    initial #14.5 rst_n = 1'b1;

    reg         in_valid = 1'b0;
    reg         new_msg  = 1'b0;
    reg  [31:0] key      = 32'd0;
    reg  [7:0]  data_in  = 8'd0;

    wire        out_ready;
    wire [7:0]  data_out;

    stream_cipher_aes DUT (
        .clk        (clk),
        .rst_n      (rst_n),
        .in_valid   (in_valid),
        .new_msg    (new_msg),
        .key        (key),
        .data_in    (data_in),
        .out_ready  (out_ready),
        .data_out   (data_out)
    );

    reg [31:0] tv_key	[0:0];
    reg [7:0]  tv_ptxt 	[0:63];
    reg [7:0]  tv_ctxt 	[0:63];
    int i; 

    initial begin
        $readmemh("modelsim/tv/key.txt",  tv_key);
        $readmemh("modelsim/tv/ptxt.txt", tv_ptxt);
        $readmemh("modelsim/tv/ctxt.txt", tv_ctxt);

        @(posedge rst_n); 
        @(negedge clk);

        // TEST CASE 1: Simple 64-byte Message
        key = tv_key[0];

        for(i = 0; i < 64; i = i + 1) begin
            data_in  = tv_ptxt[i];
            in_valid = 1'b1;
            if (i == 0) begin
                new_msg = 1'b1;
            end else begin
                new_msg = 1'b0;
            end
            @(negedge clk);
        end
        in_valid = 1'b0; 
        
        // TEST CASE 2: Empty Message
        #50;
        @(negedge clk);
        key = 32'hEEEEFFFF; 
        new_msg = 1'b1;
        @(negedge clk);
        new_msg = 1'b0;

 	// TEST CASE 3: Interrupted Data Stream (Stalling)
        #50;
        @(negedge clk);
        key = 32'hAAAA_BBBB;
        new_msg = 1'b1;
        in_valid = 1'b1;
        data_in = 8'h11;
        
        @(negedge clk);
        new_msg = 1'b0;
        data_in = 8'h22;
        
        // Induce a stall for 3 clock cycles
        @(negedge clk);
        in_valid = 1'b0; 
        data_in = 8'hXX; // Simulate missing data
        
        @(negedge clk);
        @(negedge clk);
        
        // Resume transmission
        @(negedge clk);
        in_valid = 1'b1;
        data_in = 8'h33;
        
        @(negedge clk);
        in_valid = 1'b0;
	#100;
	$stop;
    end

    reg [7:0] c_got [$];
    int byte_count = 0;

    initial begin
        @(posedge rst_n);
        forever begin
            @(posedge clk);
            
            if (out_ready) begin
                c_got.push_back(data_out);
                byte_count = byte_count + 1;
                if (byte_count == 64) begin
                    $display("--- VERIFICATION STARTED ---");
                    for(int j = 0; j < 64; j++) begin
                        if(c_got[j] !== tv_ctxt[j]) begin
                            $display("ERROR at Byte %0d: Expected %02X, Actual %02X", j, tv_ctxt[j], c_got[j]);
                        end else begin
                            $display("Byte %0d: OK", j); 
                        end
                    end
                    $display("--- VERIFICATION FINISHED ---");
               	end
	    end
     	end
    end

endmodule