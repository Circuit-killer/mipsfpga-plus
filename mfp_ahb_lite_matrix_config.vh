//
//  Memory-mapped I/O addresses
//

`define MFP_SWITCHES_ADDR     32'h1f800000
`define MFP_BUTTONS_ADDR      32'h1f800004
`define MFP_RED_LEDS_ADDR     32'h1f800008
`define MFP_GREEN_LEDS_ADDR   32'h1f80000C

`define MFP_SWITCHES_IONUM    4'h0
`define MFP_BUTTONS_IONUM     4'h1
`define MFP_RED_LEDS_IONUM    4'h2
`define MFP_GREEN_LEDS_IONUM  4'h3

//
// RAM addresses
//

`define MFP_RAM_RESET_ADDR          32'h1fc?????
`define MFP_RAM_ADDR                32'h0???????

`define MFP_RAM_RESET_ADDR_WIDTH    15 
`define MFP_RAM_ADDR_WIDTH          16 

`define MFP_RAM_RESET_ADDR_MATCH    7'h7f
`define MFP_RAM_ADDR_MATCH          1'b0
`define MFP_GPIO_ADDR_MATCH         7'h7e
