module ADS127L01 #(

)(
    input wire clk,rst_n,en,
    (*mark_debug="true"*) input wire sck,fsync,din,
    output logic start,pd, // power-down pin
    (*mark_debug="true"*) output logic [23:0] data,
    (*mark_debug="true"*) output logic valid,
    output logic cs_n,dsin,dout
);
    /**
    * async design
    * posedge sck,  receive data from din
    * posedge fsync, data is ready to be latched in 'data'
    * rd is synchrous to clk, last one cycle
    */
    logic [31:0] shift_reg;
    logic [1:0] fsync_dly;
    // drive shift_reg
    always_ff @( posedge sck ) begin
        if(!rst_n)
        begin
            shift_reg <= '0;
        end
        else if(en)
        begin
           shift_reg <= {shift_reg[30:0],din};
        end
    end
    // drive data
    always_ff @( posedge fsync ) begin
       data <= shift_reg[31:8];
    end
    // drive fsync_dly
    always_ff @( posedge clk ) begin
        if(!rst_n)
        begin
            fsync_dly <= '0;
        end
        else if(en)
        begin
            fsync_dly <= {fsync_dly[0],fsync}; 
        end
    end
    // drive valid
    assign valid = ~fsync_dly[1] & fsync_dly[0];
    // set to 0 according to PCB design
    assign start=1'b1;
    assign pd   =1'b1;
    assign cs_n = 1'b0;
    assign dsin = 1'b0;
    assign dout = 1'b0;
endmodule