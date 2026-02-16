package ved_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // -------------------------
  // Transaction (sequence item)
  // -------------------------
  class ved_txn extends uvm_sequence_item;
    rand bit [63:0] a;
    rand bit [63:0] b;

    // Expected output (computed in scoreboard or precomputed here)
    bit [127:0] exp;

    // Helpful knobs for distribution
    rand int unsigned mode;

    // Modes:
    // 0: fully random
    // 1: corner-ish patterns
    // 2: power-of-two patterns
    constraint c_mode { mode inside {[0:2]}; }

    // operand distributions to hit interesting values often
    constraint c_dist_a {
      if (mode == 0) {
        a dist {
          64'h0000_0000_0000_0000 := 5,
          64'hFFFF_FFFF_FFFF_FFFF := 5,
          64'h0000_0000_0000_0001 := 5,
          64'h8000_0000_0000_0000 := 5,
          [64'h0000_0000_0000_0000 : 64'hFFFF_FFFF_FFFF_FFFF] := 80
        };
      }
    }
    constraint c_dist_b {
      if (mode == 0) {
        b dist {
          64'h0000_0000_0000_0000 := 5,
          64'hFFFF_FFFF_FFFF_FFFF := 5,
          64'h0000_0000_0000_0001 := 5,
          64'h8000_0000_0000_0000 := 5,
          [64'h0000_0000_0000_0000 : 64'hFFFF_FFFF_FFFF_FFFF] := 80
        };
      }
    }

    // Corner-ish patterns
    constraint c_corner {
      if (mode == 1) {
        a inside {
          64'h0,
          64'h1,
          64'hFFFF_FFFF_FFFF_FFFF,
          64'h0000_0000_FFFF_FFFF,
          64'hFFFF_FFFF_0000_0000,
          64'h8000_0000_0000_0000,
          64'h7FFF_FFFF_FFFF_FFFF,
          64'h5555_5555_5555_5555,
          64'hAAAA_AAAA_AAAA_AAAA
        };
        b inside {
          64'h0,
          64'h1,
          64'hFFFF_FFFF_FFFF_FFFF,
          64'h0000_0000_FFFF_FFFF,
          64'hFFFF_FFFF_0000_0000,
          64'h8000_0000_0000_0000,
          64'h7FFF_FFFF_FFFF_FFFF,
          64'h5555_5555_5555_5555,
          64'hAAAA_AAAA_AAAA_AAAA
        };
      }
    }

    // Power-of-two patterns (and near power-of-two)
    constraint c_pow2 {
      if (mode == 2) {
        int unsigned sh1, sh2;
        sh1 inside {[0:63]};
        sh2 inside {[0:63]};
        // Force a,b to be 1<<sh or (1<<sh)-1 sometimes
        a == ( (sh1 % 2)==0 ? (64'h1 << sh1) : ((64'h1 << sh1) - 1) );
        b == ( (sh2 % 2)==0 ? (64'h1 << sh2) : ((64'h1 << sh2) - 1) );
      }
    }

    `uvm_object_utils_begin(ved_txn)
      `uvm_field_int(a, UVM_ALL_ON)
      `uvm_field_int(b, UVM_ALL_ON)
      `uvm_field_int(exp, UVM_ALL_ON | UVM_NOCOMPARE)
      `uvm_field_int(mode, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name="ved_txn");
      super.new(name);
    endfunction
  endclass

  // -------------------------
  // Sequence: constrained random
  // -------------------------
  class ved_rand_seq extends uvm_sequence #(ved_txn);
    rand int unsigned n_items = 1000;

    `uvm_object_utils(ved_rand_seq)
    function new(string name="ved_rand_seq");
      super.new(name);
    endfunction

    task body();
      ved_txn tr;
      repeat (n_items) begin
        tr = ved_txn::type_id::create("tr");
        start_item(tr);
        if (!tr.randomize()) `uvm_fatal("RAND", "Randomize failed")
        finish_item(tr);
      end
    endtask
  endclass

  // -------------------------
  // Sequence: directed corners
  // -------------------------
  class ved_corner_seq extends uvm_sequence #(ved_txn);
    `uvm_object_utils(ved_corner_seq)
    function new(string name="ved_corner_seq");
      super.new(name);
    endfunction

    task body();
      ved_txn tr;

      bit [63:0] vecs[$] = '{
        64'h0,
        64'h1,
        64'h2,
        64'h3,
        64'hFFFF_FFFF_FFFF_FFFF,
        64'h8000_0000_0000_0000,
        64'h7FFF_FFFF_FFFF_FFFF,
        64'h0000_0000_FFFF_FFFF,
        64'hFFFF_FFFF_0000_0000,
        64'h5555_5555_5555_5555,
        64'hAAAA_AAAA_AAAA_AAAA
      };

      foreach (vecs[i]) begin
        foreach (vecs[j]) begin
          tr = ved_txn::type_id::create($sformatf("tr_%0d_%0d", i, j));
          start_item(tr);
          tr.mode = 1;
          tr.a = vecs[i];
          tr.b = vecs[j];
          finish_item(tr);
        end
      end
    endtask
  endclass

  // -------------------------
  // Sequencer
  // -------------------------
  class ved_sequencer extends uvm_sequencer #(ved_txn);
    `uvm_component_utils(ved_sequencer)
    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction
  endclass

  // -------------------------
  // Driver
  // -------------------------
  class ved_driver extends uvm_driver #(ved_txn);
    `uvm_component_utils(ved_driver)

    virtual ved_if vif;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(virtual ved_if)::get(this, "", "vif", vif))
        `uvm_fatal("NOVIF", "Driver: virtual interface not set")
    endfunction

    task run_phase(uvm_phase phase);
      ved_txn tr;

      // Initialize
      vif.drv_cb.a <= '0;
      vif.drv_cb.b <= '0;
      @(posedge vif.clk);

      forever begin
        seq_item_port.get_next_item(tr);

        // Drive operands on posedge (sampled by DUT at same posedge)
        vif.drv_cb.a <= tr.a;
        vif.drv_cb.b <= tr.b;

        // Wait 1 cycle to allow DUT to register result
        @(posedge vif.clk);

        seq_item_port.item_done();
      end
    endtask
  endclass

  // -------------------------
  // Monitor: publishes sampled (a,b,result) each cycle
  // We capture inputs from previous cycle to align with 1-cycle latency.
  // -------------------------
  class ved_mon_item extends uvm_sequence_item;
    bit [63:0]  a_prev;
    bit [63:0]  b_prev;
    bit [127:0] result_now;

    `uvm_object_utils_begin(ved_mon_item)
      `uvm_field_int(a_prev, UVM_ALL_ON)
      `uvm_field_int(b_prev, UVM_ALL_ON)
      `uvm_field_int(result_now, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name="ved_mon_item");
      super.new(name);
    endfunction
  endclass

  class ved_monitor extends uvm_component;
    `uvm_component_utils(ved_monitor)

    virtual ved_if vif;
    uvm_analysis_port #(ved_mon_item) ap;

    function new(string name, uvm_component parent);
      super.new(name, parent);
      ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(virtual ved_if)::get(this, "", "vif", vif))
        `uvm_fatal("NOVIF", "Monitor: virtual interface not set")
    endfunction

    task run_phase(uvm_phase phase);
      bit [63:0] a_d, b_d;
      ved_mon_item mi;

      // Prime delayed inputs
      a_d = '0;
      b_d = '0;
      @(posedge vif.clk);

      forever begin
        @(posedge vif.clk);
        mi = ved_mon_item::type_id::create("mi");
        mi.a_prev     = a_d;
        mi.b_prev     = b_d;
        mi.result_now = vif.mon_cb.result;

        ap.write(mi);

        // update delayed copies with current inputs
        a_d = vif.mon_cb.a;
        b_d = vif.mon_cb.b;
      end
    endtask
  endclass

  // -------------------------
  // Coverage (functional coverage >95% target)
  // Cover operand classes + cross, plus some bit-pattern behavior.
  // -------------------------
  class ved_coverage extends uvm_component;
    `uvm_component_utils(ved_coverage)

    uvm_analysis_imp #(ved_mon_item, ved_coverage) analysis_export;

    // sampled values
    bit [63:0]  a_s;
    bit [63:0]  b_s;
    bit [127:0] p_s;

    // helper classification
    function bit is_pow2(bit [63:0] x);
      return (x != 0) && ((x & (x-1)) == 0);
    endfunction

    covergroup cg @(posedge uvm_root::get().m_uvm_top.clock); // dummy, we sample manually
      option.per_instance = 1;

      // Operand class bins
      cp_a_class: coverpoint a_s {
        bins zero   = {64'h0};
        bins one    = {64'h1};
        bins max    = {64'hFFFF_FFFF_FFFF_FFFF};
        bins msb1   = {64'h8000_0000_0000_0000};
        bins alt1   = {64'h5555_5555_5555_5555};
        bins alt2   = {64'hAAAA_AAAA_AAAA_AAAA};
        bins other  = default;
      }

      cp_b_class: coverpoint b_s {
        bins zero   = {64'h0};
        bins one    = {64'h1};
        bins max    = {64'hFFFF_FFFF_FFFF_FFFF};
        bins msb1   = {64'h8000_0000_0000_0000};
        bins alt1   = {64'h5555_5555_5555_5555};
        bins alt2   = {64'hAAAA_AAAA_AAAA_AAAA};
        bins other  = default;
      }

      // “Magnitude-ish” bins (upper nibble)
      cp_a_hi: coverpoint a_s[63:60] { bins n[] = {[0:15]}; }
      cp_b_hi: coverpoint b_s[63:60] { bins n[] = {[0:15]}; }

      // Product MSBs bins (rough spread)
      cp_p_hi: coverpoint p_s[127:124] { bins n[] = {[0:15]}; }

      // Cross coverage to ensure distributions are exercised
      x_class: cross cp_a_class, cp_b_class;
      x_hi:    cross cp_a_hi, cp_b_hi;

    endgroup

    function new(string name, uvm_component parent);
      super.new(name, parent);
      analysis_export = new("analysis_export", this);
      cg = new();
    endfunction

    // analysis write
    function void write(ved_mon_item t);
      a_s = t.a_prev;
      b_s = t.b_prev;
      p_s = t.result_now;
      cg.sample();
    endfunction

  endclass

  // -------------------------
  // Scoreboard (checks correctness, keeps counters)
  // -------------------------
  class ved_scoreboard extends uvm_component;
    `uvm_component_utils(ved_scoreboard)

    uvm_analysis_imp #(ved_mon_item, ved_scoreboard) analysis_export;

    longint unsigned total;
    longint unsigned pass;
    longint unsigned fail;

    function new(string name, uvm_component parent);
      super.new(name, parent);
      analysis_export = new("analysis_export", this);
      total = 0; pass = 0; fail = 0;
    endfunction

    function void write(ved_mon_item t);
      bit [127:0] exp;
      exp = 128'(t.a_prev) * 128'(t.b_prev);

      total++;

      if (t.result_now !== exp) begin
        fail++;
        `uvm_error("MISMATCH",
          $sformatf("a_prev=%h b_prev=%h exp=%h got=%h",
                    t.a_prev, t.b_prev, exp, t.result_now))
      end
      else begin
        pass++;
      end
    endfunction

    function void report_phase(uvm_phase phase);
      super.report_phase(phase);
      `uvm_info("SCOREBOARD",
        $sformatf("Total=%0d Pass=%0d Fail=%0d", total, pass, fail),
        UVM_LOW)
      if (fail != 0) `uvm_error("SCOREBOARD", "FAILURES DETECTED")
    endfunction

  endclass

  // -------------------------
  // Agent
  // -------------------------
  class ved_agent extends uvm_component;
    `uvm_component_utils(ved_agent)

    ved_sequencer  sqr;
    ved_driver     drv;
    ved_monitor    mon;

    virtual ved_if vif;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      if (!uvm_config_db#(virtual ved_if)::get(this, "", "vif", vif))
        `uvm_fatal("NOVIF", "Agent: virtual interface not set")

      sqr = ved_sequencer::type_id::create("sqr", this);
      drv = ved_driver   ::type_id::create("drv", this);
      mon = ved_monitor  ::type_id::create("mon", this);

      uvm_config_db#(virtual ved_if)::set(this, "drv", "vif", vif);
      uvm_config_db#(virtual ved_if)::set(this, "mon", "vif", vif);
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      drv.seq_item_port.connect(sqr.seq_item_export);
    endfunction

  endclass

  // -------------------------
  // Environment
  // -------------------------
  class ved_env extends uvm_env;
    `uvm_component_utils(ved_env)

    ved_agent      agt;
    ved_scoreboard scb;
    ved_coverage   cov;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      agt = ved_agent     ::type_id::create("agt", this);
      scb = ved_scoreboard::type_id::create("scb", this);
      cov = ved_coverage  ::type_id::create("cov", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      agt.mon.ap.connect(scb.analysis_export);
      agt.mon.ap.connect(cov.analysis_export);
    endfunction
  endclass

  // -------------------------
  // Base test
  // -------------------------
  class ved_base_test extends uvm_test;
    `uvm_component_utils(ved_base_test)

    ved_env env;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      env = ved_env::type_id::create("env", this);
    endfunction

  endclass

endpackage
