`include "mfp_ahb_lite.vh"
`include "mfp_ahb_lite_matrix_config.vh"
`include "mfp_eic_core.vh"

module mfp_ahb_lite_matrix
(
    input         HCLK,
    input         HRESETn,
    input  [31:0] HADDR,
    input  [ 2:0] HBURST,
    input         HMASTLOCK,
    input  [ 3:0] HPROT,
    input  [ 2:0] HSIZE,
    input  [ 1:0] HTRANS,
    input  [31:0] HWDATA,
    input         HWRITE,
    output [31:0] HRDATA,
    output        HREADY,
    output        HRESP,
    input         SI_Endian,

    `ifdef MFP_USE_SDRAM_MEMORY
    output                                  SDRAM_CKE,
    output                                  SDRAM_CSn,
    output                                  SDRAM_RASn,
    output                                  SDRAM_CASn,
    output                                  SDRAM_WEn,
    output [`SDRAM_ADDR_BITS - 1 : 0 ]      SDRAM_ADDR,
    output [`SDRAM_BA_BITS   - 1 : 0 ]      SDRAM_BA,
    inout  [`SDRAM_DQ_BITS   - 1 : 0 ]      SDRAM_DQ,
    output [`SDRAM_DM_BITS   - 1 : 0 ]      SDRAM_DQM,
    `endif

    `ifdef MFP_DEMO_LIGHT_SENSOR
    input  [                       15 : 0 ] IO_LightSensor,
    `endif

    input                                   UART_RX,
    output                                  UART_TX,
    output                                  UART_INT,

    `ifdef MFP_USE_IRQ_EIC
    input  [ `EIC_CHANNELS        - 1 : 0 ] EIC_input,
    output [                       17 : 1 ] EIC_Offset,
    output [                        3 : 0 ] EIC_ShadowSet,
    output [                        7 : 0 ] EIC_Interrupt,
    output [                        5 : 0 ] EIC_Vector,
    output                                  EIC_Present,
    input                                   EIC_IAck,
    input  [                        7 : 0 ] EIC_IPL,
    input  [                        5 : 0 ] EIC_IVN,
    input  [                       17 : 1 ] EIC_ION,
    `endif //MFP_USE_IRQ_EIC

    input  [`MFP_N_SWITCHES          - 1:0] IO_Switches,
    input  [`MFP_N_BUTTONS           - 1:0] IO_Buttons,
    output [`MFP_N_RED_LEDS          - 1:0] IO_RedLEDs,
    output [`MFP_N_GREEN_LEDS        - 1:0] IO_GreenLEDs,
    output [`MFP_7_SEGMENT_HEX_WIDTH - 1:0] IO_7_SegmentHEX
);

    wire [ 4:0] HSEL_req;
    wire [ 4:0] HSEL_data;
    wire [ 4:0] HSEL;

    wire [ 4:0] READY;
    wire [31:0] RDATA [ 4:0 ];
    wire [ 4:0] RESP;

    mfp_ahb_lite_decoder    decoder  (HADDR, HSEL_req);
    mfp_ahb_lite_selector   selector (HCLK, HRESETn, HREADY, HSEL_req, HSEL, HSEL_data);

    //RESET
    mfp_ahb_ram_slave
    # (
        .ADDR_WIDTH ( `MFP_RESET_RAM_ADDR_WIDTH )
    )
    reset_ram
    (
        .HCLK       ( HCLK       ),
        .HRESETn    ( HRESETn    ),
        .HADDR      ( HADDR      ),
        .HBURST     ( HBURST     ),
        .HMASTLOCK  ( HMASTLOCK  ),
        .HPROT      ( HPROT      ),
        .HSEL       ( HSEL [0]   ),
        .HSIZE      ( HSIZE      ),
        .HTRANS     ( HTRANS     ),
        .HWDATA     ( HWDATA     ),
        .HWRITE     ( HWRITE     ),
        .HRDATA     ( RDATA [0]  ),
        .HREADY     ( READY [0]  ),
        .HRESP      ( RESP  [0]  ),
        .SI_Endian  ( SI_Endian  )
    );

    //RAM
    `ifdef MFP_USE_SDRAM_MEMORY
        mfp_ahb_ram_sdram
        #(
            .ADDR_BITS  ( `SDRAM_ADDR_BITS  ),
            .ROW_BITS   ( `SDRAM_ROW_BITS   ),
            .COL_BITS   ( `SDRAM_COL_BITS   ),
            .DQ_BITS    ( `SDRAM_DQ_BITS    ),
            .DM_BITS    ( `SDRAM_DM_BITS    ),
            .BA_BITS    ( `SDRAM_BA_BITS    )
        )
    `elsif MFP_USE_BUSY_MEMORY
        mfp_ahb_ram_busy
        #(
            .ADDR_WIDTH ( `MFP_RAM_ADDR_WIDTH )
        )
    `else
        mfp_ahb_ram_slave
        #(
            .ADDR_WIDTH ( `MFP_RAM_ADDR_WIDTH )
        )
    `endif
    ram
    (
        .HCLK       ( HCLK          ),
        .HRESETn    ( HRESETn       ),
        .HADDR      ( HADDR         ),
        .HBURST     ( HBURST        ),
        .HMASTLOCK  ( HMASTLOCK     ),
        .HPROT      ( HPROT         ),
        .HSEL       ( HSEL [1]      ),
        .HSIZE      ( HSIZE         ),
        .HTRANS     ( HTRANS        ),
        .HWDATA     ( HWDATA        ),
        .HWRITE     ( HWRITE        ),
        .HRDATA     ( RDATA [1]     ),
        .HREADY     ( READY [1]     ),
        .HRESP      ( RESP  [1]     ),
        .SI_Endian  ( SI_Endian     )

        `ifdef MFP_USE_SDRAM_MEMORY
        ,
        .CKE        (   SDRAM_CKE   ),
        .CSn        (   SDRAM_CSn   ),
        .RASn       (   SDRAM_RASn  ),
        .CASn       (   SDRAM_CASn  ),
        .WEn        (   SDRAM_WEn   ),
        .ADDR       (   SDRAM_ADDR  ),
        .BA         (   SDRAM_BA    ),
        .DQ         (   SDRAM_DQ    ),
        .DQM        (   SDRAM_DQM   )
        `endif
    );

    //GPIO
    mfp_ahb_gpio_slave gpio
    (
        .HCLK             ( HCLK            ),
        .HRESETn          ( HRESETn         ),
        .HADDR            ( HADDR           ),
        .HBURST           ( HBURST          ),
        .HMASTLOCK        ( HMASTLOCK       ),
        .HPROT            ( HPROT           ),
        .HSEL             ( HSEL [2]        ),
        .HSIZE            ( HSIZE           ),
        .HTRANS           ( HTRANS          ),
        .HWDATA           ( HWDATA          ),
        .HWRITE           ( HWRITE          ),
        .HRDATA           ( RDATA [2]       ),
        .HREADY           ( READY [2]       ),
        .HRESP            ( RESP  [2]       ),
        .SI_Endian        ( SI_Endian       ),
                                           
        .IO_Switches      ( IO_Switches     ),
        .IO_Buttons       ( IO_Buttons      ),
        .IO_RedLEDs       ( IO_RedLEDs      ),
        .IO_GreenLEDs     ( IO_GreenLEDs    ),
        .IO_7_SegmentHEX  ( IO_7_SegmentHEX )

        `ifdef MFP_DEMO_LIGHT_SENSOR
        ,
        .IO_LightSensor   ( IO_LightSensor  )
        `endif
    );

    //UART
    wire    UART_RTS;
    wire    UART_CTS   = 1'b0;
    wire    UART_DTR;
    wire    UART_DSR   = 1'b0;
    wire    UART_RI    = 1'b0;
    wire    UART_DCD   = 1'b0;
    wire    UART_BAUD;

    mfp_ahb_lite_uart16550  uart
    (
        .HCLK             ( HCLK            ),
        .HRESETn          ( HRESETn         ),
        .HADDR            ( HADDR           ),
        .HBURST           ( HBURST          ),
        .HMASTLOCK        ( HMASTLOCK       ),
        .HPROT            ( HPROT           ),
        .HSEL             ( HSEL [3]        ),
        .HSIZE            ( HSIZE           ),
        .HTRANS           ( HTRANS          ),
        .HWDATA           ( HWDATA          ),
        .HWRITE           ( HWRITE          ),
        .HRDATA           ( RDATA [3]       ),
        .HREADY           ( READY [3]       ),
        .HRESP            ( RESP  [3]       ),
        .SI_Endian        ( SI_Endian       ),

        .UART_SRX         ( UART_RX         ),  // in  UART serial input signal
        .UART_STX         ( UART_TX         ),  // out UART serial output signal

        .UART_RTS         ( UART_RTS        ),  // out UART MODEM Request To Send
        .UART_CTS         ( UART_CTS        ),  // in  UART MODEM Clear To Send
        .UART_DTR         ( UART_DTR        ),  // out UART MODEM Data Terminal Ready
        .UART_DSR         ( UART_DSR        ),  // in  UART MODEM Data Set Ready
        .UART_RI          ( UART_RI         ),  // in  UART MODEM Ring Indicator
        .UART_DCD         ( UART_DCD        ),  // in  UART MODEM Data Carrier Detect
        .UART_BAUD        ( UART_BAUD       ),  // out UART baudrate output
        .UART_INT         ( UART_INT        )   // out UART interrupt
    );

    // EIC
    `ifdef MFP_USE_IRQ_EIC
    mfp_ahb_lite_eic eic
    (
        .HCLK             ( HCLK            ),
        .HRESETn          ( HRESETn         ),
        .HADDR            ( HADDR           ),
        .HBURST           ( HBURST          ),
        .HMASTLOCK        ( HMASTLOCK       ),
        .HPROT            ( HPROT           ),
        .HSEL             ( HSEL [4]        ),
        .HSIZE            ( HSIZE           ),
        .HTRANS           ( HTRANS          ),
        .HWDATA           ( HWDATA          ),
        .HWRITE           ( HWRITE          ),
        .HRDATA           ( RDATA [4]       ),
        .HREADY           ( READY [4]       ),
        .HRESP            ( RESP  [4]       ),
        .SI_Endian        ( SI_Endian       ),

        .EIC_input        ( EIC_input       ),

        .EIC_Offset       ( EIC_Offset      ),
        .EIC_ShadowSet    ( EIC_ShadowSet   ),
        .EIC_Interrupt    ( EIC_Interrupt   ),
        .EIC_Vector       ( EIC_Vector      ),
        .EIC_Present      ( EIC_Present     ),
        .EIC_IAck         ( EIC_IAck        ),
        .EIC_IPL          ( EIC_IPL         ),
        .EIC_IVN          ( EIC_IVN         ),
        .EIC_ION          ( EIC_ION         )
    );
    `else
    assign READY [4] = 1'b1;
    `endif


    assign HREADY = &READY;

    mfp_ahb_lite_response_mux response_mux
    (
        .HSEL     ( HSEL_data ),

        .RDATA_0  ( RDATA[0]  ),
        .RDATA_1  ( RDATA[1]  ),
        .RDATA_2  ( RDATA[2]  ),
        .RDATA_3  ( RDATA[3]  ),
        .RDATA_4  ( RDATA[4]  ),

        .RESP     ( RESP      ),
        .HRDATA   ( HRDATA    ),
        .HRESP    ( HRESP     )
    );

endmodule

//--------------------------------------------------------------------

module mfp_ahb_lite_decoder
(
    input  [31:0] HADDR,
    output [ 4:0] HSEL
);

    // Decode based on most significant bits of the address

    // RAM   4 MB max at 0xbfc00000 (physical: 0x1fc00000 - 0x1fffffff)
    assign HSEL [0] = ( HADDR [28:22] == `MFP_RESET_RAM_ADDR_MATCH );

    // RAM  64 MB max at 0x80000000 (physical: 0x00000000 - 0x03FFFFFF)
    assign HSEL [1] = ( HADDR [28:26] == `MFP_RAM_ADDR_MATCH       );

    // GPIO  4 MB max at 0xbf800000 (physical: 0x1f800000 - 0x1fbfffff)
    assign HSEL [2] = ( HADDR [28:22] == `MFP_GPIO_ADDR_MATCH      );

    // UART  4 KB max at 0xb0401000 (physical: 0x10401000 - 0x10401fff)
    assign HSEL [3] = ( HADDR [28:12] == `MFP_UART_ADDR_MATCH      );

    // EIC   4 KB max at 0xb0402000 (physical: 0x10402000 - 0x10402fff)
    assign HSEL [4] = ( HADDR [28:12] == `MFP_EIC_ADDR_MATCH       );

endmodule

//--------------------------------------------------------------------

module mfp_ahb_lite_response_mux
(
    input      [ 4:0] HSEL,

    // Verilog doesn't allow an I/O port to be a 2D array.
    // We can do it with some macros, but 
   //  it will be too hard to read this code in this case
    input      [31:0] RDATA_0,
    input      [31:0] RDATA_1,
    input      [31:0] RDATA_2,
    input      [31:0] RDATA_3,
    input      [31:0] RDATA_4,

    input      [ 4:0] RESP,

    output reg [31:0] HRDATA,
    output reg        HRESP
);

    always @*
        casez (HSEL)
            5'b????1:   begin HRDATA = RDATA_0; HRESP = RESP[0]; end
            5'b???10:   begin HRDATA = RDATA_1; HRESP = RESP[1]; end
            5'b??100:   begin HRDATA = RDATA_2; HRESP = RESP[2]; end
            5'b?1000:   begin HRDATA = RDATA_3; HRESP = RESP[3]; end
            5'b10000:   begin HRDATA = RDATA_4; HRESP = RESP[4]; end
            default:    begin HRDATA = RDATA_1; HRESP = RESP[1]; end
        endcase

endmodule
//--------------------------------------------------------------------


module mfp_ahb_lite_selector
(
    input             HCLK,
    input             HRESETn,
    input             HREADY,       // means phase change
    input      [ 4:0] HSEL_req,     // current device requested by CPU (addr phase)

    output     [ 4:0] HSEL_addr,    // addr phase HSEL signal
    output reg [ 4:0] HSEL_data     // data phase HSEL signal
);

    always @ (posedge HCLK)
        if(~HRESETn)
            HSEL_data <= 5'b1;
        else 
            if(HREADY) HSEL_data <= HSEL_addr;

    assign HSEL_addr = HREADY ? HSEL_req : HSEL_data;

endmodule

