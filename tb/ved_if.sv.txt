interface ved_if(input bit clk);

  logic [63:0]  a;
  logic [63:0]  b;
  logic [127:0] result;

  // For clean synchronous drive/sample
  clocking drv_cb @(posedge clk);
    output a, b;
  endclocking

  clocking mon_cb @(posedge clk);
    input a, b, result;
  endclocking

endinterface
