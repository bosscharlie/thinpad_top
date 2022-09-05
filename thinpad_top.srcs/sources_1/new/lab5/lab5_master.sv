module lab5_master #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
) (
    input wire clk_i,
    input wire rst_i,

    // TODO: 添加需要的控制信号，例如按键开关？
    input  wire [31:0] dip_sw,     // 32 位拨码开关，拨到“ON”时为 1

    // wishbone master
    output reg wb_cyc_o,
    output reg wb_stb_o,
    input wire wb_ack_i,
    output reg [ADDR_WIDTH-1:0] wb_adr_o,
    output reg [DATA_WIDTH-1:0] wb_dat_o, //TODO
    input wire [DATA_WIDTH-1:0] wb_dat_i,
    output reg [DATA_WIDTH/8-1:0] wb_sel_o,
    output reg wb_we_o
);

  // TODO: 实现实验 5 的内存+串口 Master

  typedef enum logic[3:0] {  
    STATE_IDLE,
    READ_WAIT_ACTION,
    READ_WAIT_CHECK,
    READ_DATA_ACTION,
    READ_DATA_DONE,
    WRITE_SRAM_ACTION,
    WRITE_SRAM_DONE,
    WRITE_WAIT_ACTION,
    WRITE_WATI_CHECK,
    WRITE_DATA_ACTION,
    WRITE_DATA_DONE,
    STATE_DONE
  }state_t;

  state_t state;
  logic mem_addr[31:0];
  logic cnt[3:0];
  logic wb_ack_o_reg;
  logic[31:0] data;
  typedef enum logic[1:0] {  
    MEM,
    UART_STATUS,
    UART_REG
  } mem_type_t;
  mem_type_t mem_type;

  assign wb_cyc_o = wb_stb_o;

  always_comb begin
    wb_adr_o_reg = mem_addr;
    case(mem_type)
      MEM:begin
        wb_adr_o_reg = mem_addr;
      end
      UART_STATUS:begin
        wb_adr_o_reg = 32'h1000_0005;
      end
      UART_REG:begin
        wb_adr_o_reg = 32'h1000_0000;
      end
    endcase
  end

  always_ff @ (posedge clk_i)begin
    if(rst_i)begin
      state <= STATE_IDLE
      mem_addr <= dip_sw;
      cnt <= 4'b0;
    end else begin
      case(state)
        STATE_IDLE: begin
          if(cnt == 4'd10)begin
            state <= STATE_DONE;
          end else begin
            state <= READ_WAIT_ACTION;
            wb_stb_o <= 1'b1;
            wb_we_o <= 1'b0;
            mem_type <= UART_STATUS;
          end
        end

        READ_WAIT_ACTION: begin
          if(wb_ack_i)begin
            data <= wb_dat_i;
            state <= READ_WAIT_CHECK; 
            wb_stb_o <= 1'b0;
          end else begin
            state <= READ_WAIT_ACTION;
          end
        end

        READ_WAIT_CHECK: begin
          if(data)begin
            mem_type <= UART_REG;
            wb_stb_o <= 1'b1;
            state <= READ_DATA_ACTION;
          end else begin
            state <= READ_WAIT_ACTION;
            wb_stb_o <= 1'b1;
            wb_we_o <= 1'b0;
            mem_type <= UART_STATUS;
          end
        end

        READ_DATA_ACTION: begin
          if(wb_ack_i) begin
            data <= wb_dat_i;
            wb_stb_o <= 1'b0;
            state <= READ_DATA_DONE;
          end else begin
            state <= READ_DATA_ACTION;
          end
        end

        READ_DATA_DONE: begin
          mem_type <= mem_addr;
          wb_stb_o <= 1'b1;
          wb_we_o <= 1'b1;
          state <= WRITE_SRAM_ACTION;
        end

        WRITE_SRAM_ACTION: begin
          if(wb_ack_i) begin
            data <= wb_dat_i;
            wb_stb_o <= 1'b0;
            state <= WRITE_SRAM_DONE;
          end else begin
            state <= WRITE_SRAM_ACTION;
          end
        end

        WRITE_SRAM_DONE: begin
          mem_type <= UART_STATUS;
          wb_stb_o <= 1'b1;
          wb_we_o <= 1'b0;
          state <= WRITE_WAIT_ACTION;
        end

        WRITE_WAIT_ACTION: begin
          if(wb_ack_i)begin
            data <= wb_dat_i;
            state <= WRITE_WAIT_CHECK; 
            wb_stb_o <= 1'b0;
          end else begin
            state <= WRITE_WAIT_ACTION;
          end
        end

        WRITE_WATI_CHECK: begin
          if(data)begin
            mem_type <= UART_REG;
            wb_stb_o <= 1'b1;
            wb_we_o <= 1'b1;
            state <= WRITE_DATA_ACTION;
          end else begin
            state <= WRITE_WAIT_ACTION;
            wb_stb_o <= 1'b1;
            wb_we_o <= 1'b0;
            mem_type <= UART_STATUS;
          end
        end

        WRITE_DATA_ACTION: begin

          state <= WRITE_DATA_DONE;
        end

        WRITE_DATA_DONE: begin
          state <= STATE_IDLE;
          cnt <= cnt+4'b1;
        end

        STATE_DONE: begin
          state <= STATE_DONE;
        end
      endcase
    end
  end
endmodule
