#!/usr/bin/env bash
set -e

echo "Compiling..."
vsim -c -do compile_questa.do

echo "Running BASIC..."
vsim -c -do "vsim work.ved_tb_top +UVM_TESTNAME=ved_test_basic; run -all; quit -f"

echo "Running CORNER..."
vsim -c -do "vsim work.ved_tb_top +UVM_TESTNAME=ved_test_corner; run -all; quit -f"

echo "Running RANDOM+COV..."
vsim -c -do "vsim work.ved_tb_top +UVM_TESTNAME=ved_test_random_cov; run -all; quit -f"

echo "Regression done."

