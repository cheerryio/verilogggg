`timescale 1ns/10ps

module axi_fifo_intr #(

)(
    input wire prog_empty,prog_empty_mask,
    input wire prog_full,prog_full_mask,
    output logic prog_empty_intr,
    output logic prog_full_intr
);
    assign prog_full_intr=prog_full&prog_full_mask;
    assign prog_empty_intr=prog_empty&prog_empty_mask;
endmodule