# Example: random+coverage test
vsim -c -voptargs=+acc work.ved_tb_top +UVM_TESTNAME=ved_test_random_cov
run -all
quit -f
