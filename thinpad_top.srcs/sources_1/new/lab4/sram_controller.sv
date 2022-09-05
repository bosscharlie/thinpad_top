module sram_controller #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,

    parameter SRAM_ADDR_WIDTH = 20,
    parameter SRAM_DATA_WIDTH = 32,

    localparam SRAM_BYTES = SRAM_DATA_WIDTH / 8,
    localparam SRAM_BYTE_WIDTH = $clog2(SRAM_BYTES)
) (
    // clk and reset
    input wire clk_i,
    input wire rst_i,

    // wishbone slave interface
    input wire wb_cyc_i,
    input wire wb_stb_i,
    output reg wb_ack_o,
    input wire [ADDR_WIDTH-1:0] wb_adr_i,
    input wire [DATA_WIDTH-1:0] wb_dat_i,
    output reg [DATA_WIDTH-1:0] wb_dat_o,
    input wire [DATA_WIDTH/8-1:0] wb_sel_i,
    input wire wb_we_i,

    // sram interface
    output reg [SRAM_ADDR_WIDTH-1:0] sram_addr,
    inout wire [SRAM_DATA_WIDTH-1:0] sram_data,
    output reg sram_ce_n,
    output reg sram_oe_n,
    output reg sram_we_n,
    output reg [SRAM_BYTES-1:0] sram_be_n
);

  // TODO: 实现 SRAM 控制器
  typedef enum logic [2:0] {
    STATE_IDLE,
    STATE_READ,
    STATE_READ_2,
    STATE_WRITE,
    STATE_WRITE_2,
    STATE_WRITE_3,
    STATE_DONE
  } state_t;

  reg data_z;
  state_t state;
  
  assign sram_data = data_z ? 32'bz : wb_dat_i;
  assign sram_be_n = ~wb_sel_i;

  always_ff @ (posedge clk_i) begin
    if(rst_i)begin
      state <= STATE_IDLE;
      wb_ack_o <= 1'b0;
      wb_dat_o <= 0;
      sram_ce_n <= 1'b1;
      sram_oe_n <= 1'b1;
      sram_we_n <= 1'b1;
      data_z <= 1'b1;
    end else begin
      case(state)
        STATE_IDLE: begin
          if(wb_cyc_i && wb_stb_i) begin
            if(wb_we_i) begin
              state <= STATE_WRITE;
              sram_ce_n <= 1'b0;
              sram_we_n <= 1'b1;
              sram_addr <= wb_adr_i[19:0];//确定地址写什么
              data_z <= 1'b0;
            end else begin
              state <= STATE_READ;
              sram_ce_n <= 1'b0;
              sram_oe_n <= 1'b0;
              sram_addr <= wb_adr_i[19:0];//确定地址写什么
            end
          end
        end
        STATE_READ: begin
          state <= STATE_READ_2;
        end
        STATE_READ_2: begin
          wb_dat_o <= sram_data;
          wb_ack_o <= 1'b1;
          sram_ce_n <= 1'b1;
          sram_oe_n <= 1'b1;
          state <= STATE_DONE;
        end
        STATE_WRITE: begin
          sram_we_n <= 1'b0;
          state <= STATE_WRITE_2;
        end
        STATE_WRITE_2: begin
          sram_we_n <= 1'b1;
          state <= STATE_WRITE_3;
        end
        STATE_WRITE_3: begin
          sram_ce_n <= 1'b1;
          data_z <= 1'b1;
          wb_ack_o <= 1'b1;
          state <= STATE_DONE;
        end
        STATE_DONE: begin
          wb_ack_o <= 1'b0;
          state <= STATE_IDLE;
        end
      endcase
    end
  end


endmodule
