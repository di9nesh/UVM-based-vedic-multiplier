module ved_assertions(ved_if vif);

  // 1-cycle latency: result at cycle N equals a*b from cycle N-1
  property p_correct_1cycle;
    @(posedge vif.clk)
      !$isunknown($past(vif.a)) && !$isunknown($past(vif.b))
      |-> (vif.result == (128'($past(vif.a)) * 128'($past(vif.b))));
  endproperty

  // result should not contain X after first cycle (best-effort check)
  property p_result_known;
    @(posedge vif.clk) $time > 0 |-> !$isunknown(vif.result);
  endproperty

  a_correct_1cycle: assert property(p_correct_1cycle)
    else $error("SVA FAIL: result mismatch (1-cycle latency) at time=%0t", $time);

  a_result_known: assert property(p_result_known)
    else $error("SVA FAIL: result has X at time=%0t", $time);

endmodule
