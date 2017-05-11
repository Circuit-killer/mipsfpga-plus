`include "mfp_ahb_lite.vh"

module mfp_ahb_ram_slave
# (
    parameter ADDR_WIDTH = 6
)
(
    input         HCLK,
    input         HRESETn,
    input  [31:0] HADDR,
    input  [ 2:0] HBURST,
    input         HMASTLOCK,
    input  [ 3:0] HPROT,
    input         HSEL,
    input  [ 2:0] HSIZE,
    input  [ 1:0] HTRANS,
    input  [31:0] HWDATA,
    input         HWRITE,
    output [31:0] HRDATA,
    output reg    HREADY,
    output        HRESP,
    input         SI_Endian
);
    wire [ ADDR_WIDTH - 1 : 0 ] read_addr;
    wire                        read_enable;
    wire [ ADDR_WIDTH - 1 : 0 ] write_addr;
    wire [              3 : 0 ] write_mask;
    wire                        write_enable;
    wire                        read_after_write;

    assign HRESP  = 1'b0;

    always @ (posedge HCLK)
        HREADY <= !read_after_write;

    mfp_ahb_lite_decoder 
    #(
        .ADDR_WIDTH ( ADDR_WIDTH ),
        .ADDR_START (          2 )
    )
    decoder
    (
        .HCLK               ( HCLK              ),
        .HRESETn            ( HRESETn           ),
        .HADDR              ( HADDR [ ADDR_WIDTH - 1 + 2 : 2] ),
        .HSIZE              ( HSIZE             ),
        .HTRANS             ( HTRANS            ),
        .HWRITE             ( HWRITE            ),
        .HSEL               ( HSEL              ),
        .read_enable        ( read_enable       ),
        .read_addr          ( read_addr         ),
        .write_enable       ( write_enable      ),
        .write_addr         ( write_addr        ),
        .write_mask         ( write_mask        ),
        .read_after_write   ( read_after_write  )
    );

    `ifdef MFP_USE_BYTE_MEMORY
        generate
            genvar i;

            for (i = 0; i <= 3; i = i + 1)
            begin : u
                mfp_dual_port_ram
                # (
                    .ADDR_WIDTH ( ADDR_WIDTH ),
                    .DATA_WIDTH ( 8          )
                )
                ram
                (
                    .clk          ( HCLK                                      ),
                    .read_addr    ( read_addr                                 ),
                    .write_addr   ( write_addr                                ),
                    .write_data   ( HWDATA      [ i * 8 +: 8 ]                ),
                    .write_enable ( write_mask  [ i ] & { 4 { write_enable }} ),
                    .read_data    ( HRDATA      [ i * 8 +: 8 ]                )
                );
            end
        endgenerate
    
    `else
        mfp_dual_port_ram
        #(
            .ADDR_WIDTH ( ADDR_WIDTH ),
            .DATA_WIDTH ( 32         )
        )
        ram
        (
            .clk          ( HCLK            ),
            .read_addr    ( read_addr       ),
            .write_addr   ( write_addr      ),
            .write_data   ( HWDATA          ),
            .write_enable ( write_enable    ),
            .read_data    ( HRDATA          )
        );
    `endif

endmodule
