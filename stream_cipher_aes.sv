module stream_cipher_aes (
    input  logic        clk, 
    input  logic        rst_n,
    input  logic        in_valid,
    input  logic        new_msg,
    input  logic [31:0] key,
    input  logic [7:0]  data_in,
    
    output logic        out_ready,
    output logic [7:0]  data_out
);

    logic [31:0] current_cb;
    logic [31:0] counter_reg;
    logic [7:0]  keystream_byte;

    // xtime
    function automatic logic [7:0] xtime(input logic [7:0] d);
        logic [7:0] e;
        begin
            e[7] = d[6];
            e[6] = d[5];
            e[5] = d[4];
            e[4] = d[3] ^ d[7];
            e[3] = d[2] ^ d[7];
            e[2] = d[1];
            e[1] = d[0] ^ d[7];
            e[0] = d[7];
            return e;
        end
    endfunction

    // Galois Multiplication S()
    function automatic logic [7:0] S(input logic [31:0] A);
        logic [7:0] a0, a1, a2, a3, f;
        begin
            a0 = A[31:24];
            a1 = A[23:16];
            a2 = A[15:8];
            a3 = A[7:0];
            f = xtime(a2 ^ a3) ^ a3 ^ a0 ^ a1;
            return f;
        end
    endfunction

    assign current_cb = new_msg ? key : counter_reg;
    assign keystream_byte = S(current_cb);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_reg <= 32'd0;
            data_out    <= 8'd0;
            out_ready   <= 1'b0;
        end else begin
            if (in_valid) begin
                data_out <= data_in ^ keystream_byte;
                counter_reg <= current_cb + 1'b1; 
                out_ready <= 1'b1;
            end else begin
                out_ready <= 1'b0;
            end
        end
    end

endmodule
