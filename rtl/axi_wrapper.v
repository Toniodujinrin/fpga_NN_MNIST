module axi_slave_wrapper
#(
  parameter ADDR_WIDTH = 8,
  parameter DATA_WIDTH = 32,
  parameter N_NETWORK_INPUTS = 784,
  parameter N_NEURONS_LAYER_1 = 64,
  parameter N_NEURONS_LAYER_2 = 64,
  parameter N_NEURONS_LAYER_3 = 10
)
(
  input                         clk,
  input                         reset_n,

  input                         aw_valid,
  input      [ADDR_WIDTH-1:0]    aw_data,
  output                        aw_ready,
  input      [2:0]              aw_prot,

  input                         w_valid,
  input      [DATA_WIDTH-1:0]    w_data,
  input      [(DATA_WIDTH/8)-1:0] w_strobe,
  output                        w_ready,

  output reg                    b_valid,
  output reg [1:0]              b_data,
  input                         b_ready,

  input                         ar_valid,
  input      [ADDR_WIDTH-1:0]    ar_data,
  output                        ar_ready,
  input      [2:0]              ar_prot,

  output reg                    r_valid,
  output reg [DATA_WIDTH-1:0]    r_data,
  output reg [1:0]              r_resp,
  input                         r_ready,

  input                         network_idle,
  input                         network_ready,
  input      [15:0]             network_output_data,
  input                         network_output_data_valid,
  output reg                    network_start,
  output reg [15:0]             network_input_data,
  output reg                    network_input_data_valid,

  output reg                    model_write_valid,
  output reg [1:0]              model_layer,
  output reg [5:0]              model_neuron,
  output reg [9:0]              model_index,
  output reg                    model_is_bias,
  output reg [31:0]             model_write_data
);

  localparam [1:0] OKAY   = 2'b00;
  localparam [1:0] SLVERR = 2'b10;

  localparam [ADDR_WIDTH-1:0] REG_CONTROL      = 8'h00;
  localparam [ADDR_WIDTH-1:0] REG_STATUS       = 8'h04;
  localparam [ADDR_WIDTH-1:0] REG_MODEL_TARGET = 8'h08;
  localparam [ADDR_WIDTH-1:0] REG_MODEL_DATA   = 8'h0c;
  localparam [ADDR_WIDTH-1:0] REG_MODEL_COUNT  = 8'h10;
  localparam [ADDR_WIDTH-1:0] REG_MODEL_SIZE   = 8'h14;
  localparam [ADDR_WIDTH-1:0] REG_INPUT_DATA   = 8'h20;
  localparam [ADDR_WIDTH-1:0] REG_OUTPUT_DATA  = 8'h24;
  localparam [ADDR_WIDTH-1:0] REG_INPUT_COUNT  = 8'h28;
  localparam [ADDR_WIDTH-1:0] REG_VERSION      = 8'h2c;

  localparam integer MODEL_PARAMETER_COUNT =
      (N_NETWORK_INPUTS * N_NEURONS_LAYER_1) +
      (N_NEURONS_LAYER_1 * N_NEURONS_LAYER_2) +
      (N_NEURONS_LAYER_2 * N_NEURONS_LAYER_3) +
      N_NEURONS_LAYER_1 + N_NEURONS_LAYER_2 + N_NEURONS_LAYER_3;
  localparam [5:0] LAST_NEURON_LAYER_1 = N_NEURONS_LAYER_1 - 1;
  localparam [5:0] LAST_NEURON_LAYER_2 = N_NEURONS_LAYER_2 - 1;
  localparam [5:0] LAST_NEURON_LAYER_3 = N_NEURONS_LAYER_3 - 1;

  reg                       aw_pending;
  reg [ADDR_WIDTH-1:0]      aw_address;
  reg                       w_pending;
  reg [DATA_WIDTH-1:0]      w_value;
  reg [(DATA_WIDTH/8)-1:0]  w_byte_enable;
  reg                       load_mode;
  reg                       model_valid = 1'b1;
  reg                       result_valid;
  reg                       error_flag;
  reg [15:0]                result_value;
  reg [31:0]                model_count;
  reg [15:0]                input_count;
  reg [31:0]                model_target;

  wire target_is_bias = model_target[31];
  wire [1:0] target_layer = model_target[17:16];
  wire [5:0] target_neuron = model_target[15:10];
  wire [9:0] target_index = model_target[9:0];

  wire target_valid =
      (target_layer == 2'd1 && target_neuron <= LAST_NEURON_LAYER_1 &&
       (target_is_bias ? target_index == 0 : target_index < N_NETWORK_INPUTS)) ||
      (target_layer == 2'd2 && target_neuron <= LAST_NEURON_LAYER_2 &&
       (target_is_bias ? target_index == 0 : target_index < N_NEURONS_LAYER_1)) ||
      (target_layer == 2'd3 && target_neuron <= LAST_NEURON_LAYER_3 &&
       (target_is_bias ? target_index == 0 : target_index < N_NEURONS_LAYER_2));

  assign aw_ready = !aw_pending && !b_valid;
  assign w_ready  = !w_pending && !b_valid;
  assign ar_ready = !r_valid;

  // AW and W are buffered independently, as required by AXI-Lite.
  always @(posedge clk or negedge reset_n)
  begin
    if (!reset_n)
    begin
      aw_pending                  <= 0;
      aw_address                  <= 0;
      w_pending                   <= 0;
      w_value                     <= 0;
      w_byte_enable               <= 0;
      b_valid                     <= 0;
      b_data                      <= OKAY;
      load_mode                   <= 0;
      // Model RAM is not reset. Preserve whether a load completed across reset.
      model_valid                 <= model_valid;
      result_valid                <= 0;
      error_flag                  <= 0;
      result_value                <= 0;
      model_count                 <= 0;
      input_count                 <= 0;
      model_target                <= 0;
      network_start               <= 0;
      network_input_data          <= 0;
      network_input_data_valid    <= 0;
      model_write_valid           <= 0;
      model_layer                 <= 0;
      model_neuron                <= 0;
      model_index                 <= 0;
      model_is_bias               <= 0;
      model_write_data            <= 0;
    end
    else
    begin
      network_start            <= 0;
      network_input_data_valid <= 0;
      model_write_valid        <= 0;

      if (network_output_data_valid)
      begin
        result_value <= network_output_data;
        result_valid <= 1;
      end

      if (b_valid && b_ready)
        b_valid <= 0;

      if (aw_valid && aw_ready)
      begin
        aw_address <= aw_data;
        aw_pending <= 1;
      end

      if (w_valid && w_ready)
      begin
        w_value       <= w_data;
        w_byte_enable <= w_strobe;
        w_pending     <= 1;
      end

      if (aw_pending && w_pending && !b_valid)
      begin
        if (aw_address[1:0] != 2'b00 || w_byte_enable != {(DATA_WIDTH/8){1'b1}})
        begin
          b_data     <= SLVERR;
          b_valid    <= 1;
          aw_pending <= 0;
          w_pending  <= 0;
          error_flag <= 1;
        end
        else
        begin
          case (aw_address)
            REG_CONTROL:
            begin
              b_data <= OKAY;

              if (w_value[1])
              begin
                if (network_idle)
                begin
                  load_mode   <= 1;
                  model_valid <= 0;
                  model_count <= 0;
                  model_target <= 32'h0001_0000;
                  error_flag <= 0;
                end
                else
                begin
                  b_data     <= SLVERR;
                  error_flag <= 1;
                end
              end
              else if (w_value[2])
              begin
                if (load_mode && !error_flag &&
                    model_count == MODEL_PARAMETER_COUNT)
                begin
                  load_mode   <= 0;
                  model_valid <= 1;
                end
                else
                begin
                  b_data     <= SLVERR;
                  error_flag <= 1;
                end
              end
              else if (w_value[0])
              begin
                if (network_idle && model_valid && !load_mode)
                begin
                  network_start <= 1;
                  input_count   <= 0;
                  result_valid  <= 0;
                end
                else
                begin
                  b_data     <= SLVERR;
                  error_flag <= 1;
                end
              end

              if (w_value[3])
                result_valid <= 0;
              if (w_value[4])
                error_flag <= 0;

              b_valid    <= 1;
              aw_pending <= 0;
              w_pending  <= 0;
            end

            REG_MODEL_TARGET:
            begin
              // The target is a read-only cursor advanced by MODEL_DATA writes.
              b_data     <= SLVERR;
              error_flag <= 1;
              b_valid    <= 1;
              aw_pending <= 0;
              w_pending  <= 0;
            end

            REG_MODEL_DATA:
            begin
              if (load_mode && network_idle && target_valid &&
                  model_count < MODEL_PARAMETER_COUNT)
              begin
                model_write_valid <= 1;
                model_layer       <= target_layer;
                model_neuron      <= target_neuron;
                model_index       <= target_index;
                model_is_bias     <= target_is_bias;
                model_write_data  <= w_value;
                model_count       <= model_count + 1;

                if (!target_is_bias)
                begin
                  case (target_layer)
                    2'd1:
                      if (target_index == N_NETWORK_INPUTS-1)
                      begin
                        model_target[9:0] <= 0;
                        if (target_neuron == LAST_NEURON_LAYER_1)
                        begin
                          model_target[17:16] <= 2'd2;
                          model_target[15:10] <= 0;
                        end
                        else
                          model_target[15:10] <= target_neuron + 1'b1;
                      end
                      else
                        model_target[9:0] <= target_index + 1'b1;
                    2'd2:
                      if (target_index == N_NEURONS_LAYER_1-1)
                      begin
                        model_target[9:0] <= 0;
                        if (target_neuron == LAST_NEURON_LAYER_2)
                        begin
                          model_target[17:16] <= 2'd3;
                          model_target[15:10] <= 0;
                        end
                        else
                          model_target[15:10] <= target_neuron + 1'b1;
                      end
                      else
                        model_target[9:0] <= target_index + 1'b1;
                    2'd3:
                      if (target_index == N_NEURONS_LAYER_2-1)
                      begin
                        model_target[31]    <= 1;
                        model_target[17:16] <= 2'd1;
                        model_target[15:10] <= 0;
                        model_target[9:0]   <= 0;
                      end
                      else
                        model_target[9:0] <= target_index + 1'b1;
                    default:
                      model_target <= model_target;
                  endcase
                end
                else if (target_neuron ==
                         (target_layer == 2'd1 ? LAST_NEURON_LAYER_1 :
                          target_layer == 2'd2 ? LAST_NEURON_LAYER_2 :
                                                 LAST_NEURON_LAYER_3))
                begin
                  if (target_layer != 2'd3)
                  begin
                    model_target[17:16] <= target_layer + 1'b1;
                    model_target[15:10] <= 0;
                  end
                end
                else
                  model_target[15:10] <= target_neuron + 1'b1;
                b_data <= OKAY;
              end
              else
              begin
                b_data     <= SLVERR;
                error_flag <= 1;
              end
              b_valid    <= 1;
              aw_pending <= 0;
              w_pending  <= 0;
            end

            REG_INPUT_DATA:
            begin
              if (!load_mode && !network_idle && input_count < N_NETWORK_INPUTS)
              begin
                if (network_ready)
                begin
                  network_input_data       <= w_value[15:0];
                  network_input_data_valid <= 1;
                  input_count              <= input_count + 1'b1;
                  b_data                   <= OKAY;
                  b_valid                  <= 1;
                  aw_pending               <= 0;
                  w_pending                <= 0;
                end
                end
              else
              begin
                b_data     <= SLVERR;
                b_valid    <= 1;
                aw_pending <= 0;
                w_pending  <= 0;
                error_flag <= 1;
              end
            end

            default:
            begin
              b_data     <= SLVERR;
              b_valid    <= 1;
              aw_pending <= 0;
              w_pending  <= 0;
              error_flag <= 1;
            end
          endcase
        end
      end
    end
  end

  always @(posedge clk or negedge reset_n)
  begin
    if (!reset_n)
    begin
      r_valid <= 0;
      r_data  <= 0;
      r_resp  <= OKAY;
    end
    else
    begin
      if (r_valid && r_ready)
        r_valid <= 0;

      if (ar_valid && ar_ready)
      begin
        r_valid <= 1;
        r_resp  <= OKAY;
        case (ar_data)
          REG_CONTROL:      r_data <= 0;
          REG_STATUS:       r_data <= {24'd0, error_flag, result_valid,
                                       model_valid, load_mode, !network_idle,
                                       network_ready, network_idle, 1'b0};
          REG_MODEL_TARGET: r_data <= model_target;
          REG_MODEL_COUNT:  r_data <= model_count;
          REG_MODEL_SIZE:   r_data <= MODEL_PARAMETER_COUNT;
          REG_OUTPUT_DATA:  r_data <= {16'd0, result_value};
          REG_INPUT_COUNT:  r_data <= {16'd0, input_count};
          REG_VERSION:      r_data <= 32'h0001_0000;
          default:
          begin
            r_data <= 0;
            r_resp <= SLVERR;
          end
        endcase
      end
    end
  end

  wire unused_prot = ^{aw_prot, ar_prot};

endmodule
