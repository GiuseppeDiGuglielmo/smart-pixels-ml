# Catapult 2024.2_2 directives.tcl of solution SmtPxl_QMlp_Slim.v1
# (2026-10-26, directives set by hand in the GUI after go assembly).
# Copied from the solution folder; only Catapult's banner was removed.
# The hand-set directives alone are in QMlp_Slim.tcl.
solution new -state initial
solution options defaults
solution options set /ComponentLibs/SearchPath {{$MGC_HOME/shared/pkgs/ccs_hls4ml} /home/giuseppe/research/projects/smartpixels/tsmc28nm_lib} -append
solution options set /OnTheFly/VthAttributeType cell_lib
solution options set /Input/CompilerHome /usr/bin/g++
solution options set /Input/CppStandard c++17
solution options set /Input/TargetPlatform x86_64
solution options set /Input/CompilerFlags -DRANDOM_FRAMES=2
solution options set /Input/SearchPath {{$MGC_HOME/shared/include/nnet_utils}}
solution options set /Flows/SCVerify/INVOKE_ARGS {./firmware/weights ./tb_data/tb_input_features.dat ./tb_data/tb_output_predictions.dat 0.0}
solution file add ./firmware/SmtPxl_QMlp_Slim.cpp -type C++
solution file add ./SmtPxl_QMlp_Slim_test.cpp -type C++ -exclude true
directive set -DESIGN_GOAL area
directive set -SPECULATE true
directive set -MERGEABLE true
directive set -REGISTER_THRESHOLD 256
directive set -LOGIC_OPT false
directive set -FSM_ENCODING none
directive set -FSM_BINARY_ENCODING_THRESHOLD 64
directive set -REG_MAX_FANOUT 0
directive set -NO_X_ASSIGNMENTS true
directive set -SAFE_FSM false
directive set -REGISTER_SHARING_MAX_WIDTH_DIFFERENCE 8
directive set -REGISTER_SHARING_LIMIT 0
directive set -ASSIGN_OVERHEAD 0
directive set -TIMING_CHECKS true
directive set -MUXPATH true
directive set -REALLOC true
directive set -UNROLL no
directive set -IO_MODE super
directive set -CHAN_IO_PROTOCOL use_library
directive set -ARRAY_SIZE 1024
directive set -IDLE_SIGNAL {}
directive set -STALL_FLAG_SV off
directive set -STALL_FLAG false
directive set -TRANSACTION_DONE_SIGNAL true
directive set -DONE_FLAG {}
directive set -READY_FLAG {}
directive set -START_FLAG {}
directive set -TRANSACTION_SYNC ready
directive set -CLOCK_OVERHEAD 20.000000
directive set -ON_THE_FLY_PROTOTYPING false
directive set -OPT_CONST_MULTS use_library
directive set -CHARACTERIZE_ROM false
directive set -PROTOTYPE_ROM true
directive set -ROM_THRESHOLD 64
directive set -CLUSTER_ADDTREE_IN_WIDTH_THRESHOLD 0
directive set -CLUSTER_ADDTREE_IN_COUNT_THRESHOLD 0
directive set -CLUSTER_OPT_CONSTANT_INPUTS true
directive set -CLUSTER_RTL_SYN false
directive set -CLUSTER_FAST_MODE false
directive set -CLUSTER_TYPE combinational
directive set -PIPELINE_RAMP_UP true
go new
directive set -RESET_CLEARS_ALL_REGS no
directive set -MEM_MAP_THRESHOLD 32769
go analyze
solution design set ac::fx_div<8> -inline
solution design set nnet::relu<ac_fixed<16,6,true,AC_TRN,AC_WRAP>,ac_fixed<13,5,false,AC_RND_CONV,AC_SAT>,relu_config10> -inline
solution design set nnet::relu<ac_fixed<16,6,true,AC_TRN,AC_WRAP>,ac_fixed<13,5,false,AC_RND_CONV,AC_SAT>,relu_config11> -inline
solution design set nnet::dense<ac_fixed<16,8,true,AC_TRN,AC_WRAP>,ac_fixed<16,6,true,AC_TRN,AC_WRAP>,config6> -inline
solution design set nnet::dense<ac_fixed<16,8,true,AC_TRN,AC_WRAP>,ac_fixed<16,6,true,AC_TRN,AC_WRAP>,config8> -inline
solution design set nnet::dense<ac_fixed<13,5,false,AC_RND_CONV,AC_SAT>,ac_fixed<16,6,true,AC_TRN,AC_WRAP>,config13> -inline
solution design set nnet::dense<ac_fixed<8,1,true,AC_RND_CONV,AC_SAT_SYM>,ac_fixed<16,6,true,AC_TRN,AC_WRAP>,config17> -inline
solution design set nnet::dense<ac_fixed<8,1,true,AC_RND_CONV,AC_SAT_SYM>,ac_fixed<16,6,true,AC_TRN,AC_WRAP>,config20> -inline
solution design set nnet::dense<ac_fixed<8,1,true,AC_RND_CONV,AC_SAT_SYM>,ac_fixed<10,4,true,AC_TRN,AC_WRAP>,config23> -inline
solution design set nnet::ceillog2 -inline
solution design set nnet::floorlog2 -inline
solution design set nnet::pow2 -inline
solution design set nnet::product::Product::limit -inline
solution design set nnet::product::mult<ac_fixed<16,8,true,AC_TRN,AC_WRAP>,ac_fixed<8,1,true,AC_TRN,AC_WRAP>>::product -inline
solution design set nnet::product::mult<ac_fixed<13,5,false,AC_RND_CONV,AC_SAT>,ac_fixed<8,1,true,AC_TRN,AC_WRAP>>::product -inline
solution design set nnet::product::mult<ac_fixed<8,1,true,AC_RND_CONV,AC_SAT_SYM>,ac_fixed<8,1,true,AC_TRN,AC_WRAP>>::product -inline
solution design set nnet::cast<ac_fixed<16,8,true,AC_TRN,AC_WRAP>,ac_fixed<16,6,true,AC_TRN,AC_WRAP>,config6> -inline
solution design set nnet::cast<ac_fixed<16,8,true,AC_TRN,AC_WRAP>,ac_fixed<16,6,true,AC_TRN,AC_WRAP>,config8> -inline
solution design set nnet::cast<ac_fixed<13,5,false,AC_RND_CONV,AC_SAT>,ac_fixed<16,6,true,AC_TRN,AC_WRAP>,config13> -inline
solution design set nnet::cast<ac_fixed<8,1,true,AC_RND_CONV,AC_SAT_SYM>,ac_fixed<16,6,true,AC_TRN,AC_WRAP>,config17> -inline
solution design set nnet::cast<ac_fixed<8,1,true,AC_RND_CONV,AC_SAT_SYM>,ac_fixed<16,6,true,AC_TRN,AC_WRAP>,config20> -inline
solution design set nnet::cast<ac_fixed<8,1,true,AC_RND_CONV,AC_SAT_SYM>,ac_fixed<10,4,true,AC_TRN,AC_WRAP>,config23> -inline
solution design set nnet::sigmoid_fcn_float -inline
solution design set nnet::exp_fcn_float -inline
solution design set nnet::softplus_fcn_float -inline
solution design set nnet::softsign_fcn_float -inline
solution design set nnet::elu_fcn_float -inline
solution design set nnet::selu_fcn_float -inline
solution design set nnet::hard_tanh<ac_fixed<16,6,true,AC_TRN,AC_WRAP>,ac_fixed<8,1,true,AC_RND_CONV,AC_SAT_SYM>,hard_tanh_config15> -inline
solution design set nnet::hard_tanh<ac_fixed<16,6,true,AC_TRN,AC_WRAP>,ac_fixed<8,1,true,AC_RND_CONV,AC_SAT_SYM>,hard_tanh_config19> -inline
solution design set nnet::hard_tanh<ac_fixed<16,6,true,AC_TRN,AC_WRAP>,ac_fixed<8,1,true,AC_RND_CONV,AC_SAT_SYM>,hard_tanh_config22> -inline
solution design set nnet::dense_latency<ac_fixed<16,8,true,AC_TRN,AC_WRAP>,ac_fixed<16,6,true,AC_TRN,AC_WRAP>,config6> -inline
solution design set nnet::dense_latency<ac_fixed<16,8,true,AC_TRN,AC_WRAP>,ac_fixed<16,6,true,AC_TRN,AC_WRAP>,config8> -inline
solution design set nnet::dense_latency<ac_fixed<13,5,false,AC_RND_CONV,AC_SAT>,ac_fixed<16,6,true,AC_TRN,AC_WRAP>,config13> -inline
solution design set nnet::dense_latency<ac_fixed<8,1,true,AC_RND_CONV,AC_SAT_SYM>,ac_fixed<16,6,true,AC_TRN,AC_WRAP>,config17> -inline
solution design set nnet::dense_latency<ac_fixed<8,1,true,AC_RND_CONV,AC_SAT_SYM>,ac_fixed<16,6,true,AC_TRN,AC_WRAP>,config20> -inline
solution design set nnet::dense_latency<ac_fixed<8,1,true,AC_RND_CONV,AC_SAT_SYM>,ac_fixed<10,4,true,AC_TRN,AC_WRAP>,config23> -inline
solution design set nnet::dense_resource<ac_fixed<16,8,true,AC_TRN,AC_WRAP>,ac_fixed<16,6,true,AC_TRN,AC_WRAP>,config6> -inline
solution design set nnet::dense_resource_rf_leq_nin<ac_fixed<16,8,true,AC_TRN,AC_WRAP>,ac_fixed<16,6,true,AC_TRN,AC_WRAP>,config6> -inline
solution design set nnet::dense_resource_rf_gt_nin_rem0<ac_fixed<16,8,true,AC_TRN,AC_WRAP>,ac_fixed<16,6,true,AC_TRN,AC_WRAP>,config6> -inline
solution design set nnet::dense_resource_rf_gt_nin<ac_fixed<16,8,true,AC_TRN,AC_WRAP>,ac_fixed<16,6,true,AC_TRN,AC_WRAP>,config6> -inline
solution design set nnet::dense_resource<ac_fixed<16,8,true,AC_TRN,AC_WRAP>,ac_fixed<16,6,true,AC_TRN,AC_WRAP>,config8> -inline
solution design set nnet::dense_resource_rf_leq_nin<ac_fixed<16,8,true,AC_TRN,AC_WRAP>,ac_fixed<16,6,true,AC_TRN,AC_WRAP>,config8> -inline
solution design set nnet::dense_resource_rf_gt_nin_rem0<ac_fixed<16,8,true,AC_TRN,AC_WRAP>,ac_fixed<16,6,true,AC_TRN,AC_WRAP>,config8> -inline
solution design set nnet::dense_resource_rf_gt_nin<ac_fixed<16,8,true,AC_TRN,AC_WRAP>,ac_fixed<16,6,true,AC_TRN,AC_WRAP>,config8> -inline
solution design set nnet::dense_resource<ac_fixed<13,5,false,AC_RND_CONV,AC_SAT>,ac_fixed<16,6,true,AC_TRN,AC_WRAP>,config13> -inline
solution design set nnet::dense_resource_rf_leq_nin<ac_fixed<13,5,false,AC_RND_CONV,AC_SAT>,ac_fixed<16,6,true,AC_TRN,AC_WRAP>,config13> -inline
solution design set nnet::dense_resource_rf_gt_nin_rem0<ac_fixed<13,5,false,AC_RND_CONV,AC_SAT>,ac_fixed<16,6,true,AC_TRN,AC_WRAP>,config13> -inline
solution design set nnet::dense_resource_rf_gt_nin<ac_fixed<13,5,false,AC_RND_CONV,AC_SAT>,ac_fixed<16,6,true,AC_TRN,AC_WRAP>,config13> -inline
solution design set nnet::dense_resource<ac_fixed<8,1,true,AC_RND_CONV,AC_SAT_SYM>,ac_fixed<16,6,true,AC_TRN,AC_WRAP>,config17> -inline
solution design set nnet::dense_resource_rf_leq_nin<ac_fixed<8,1,true,AC_RND_CONV,AC_SAT_SYM>,ac_fixed<16,6,true,AC_TRN,AC_WRAP>,config17> -inline
solution design set nnet::dense_resource_rf_gt_nin_rem0<ac_fixed<8,1,true,AC_RND_CONV,AC_SAT_SYM>,ac_fixed<16,6,true,AC_TRN,AC_WRAP>,config17> -inline
solution design set nnet::dense_resource_rf_gt_nin<ac_fixed<8,1,true,AC_RND_CONV,AC_SAT_SYM>,ac_fixed<16,6,true,AC_TRN,AC_WRAP>,config17> -inline
solution design set nnet::dense_resource<ac_fixed<8,1,true,AC_RND_CONV,AC_SAT_SYM>,ac_fixed<16,6,true,AC_TRN,AC_WRAP>,config20> -inline
solution design set nnet::dense_resource_rf_leq_nin<ac_fixed<8,1,true,AC_RND_CONV,AC_SAT_SYM>,ac_fixed<16,6,true,AC_TRN,AC_WRAP>,config20> -inline
solution design set nnet::dense_resource_rf_gt_nin_rem0<ac_fixed<8,1,true,AC_RND_CONV,AC_SAT_SYM>,ac_fixed<16,6,true,AC_TRN,AC_WRAP>,config20> -inline
solution design set nnet::dense_resource_rf_gt_nin<ac_fixed<8,1,true,AC_RND_CONV,AC_SAT_SYM>,ac_fixed<16,6,true,AC_TRN,AC_WRAP>,config20> -inline
solution design set nnet::dense_resource<ac_fixed<8,1,true,AC_RND_CONV,AC_SAT_SYM>,ac_fixed<10,4,true,AC_TRN,AC_WRAP>,config23> -inline
solution design set nnet::dense_resource_rf_leq_nin<ac_fixed<8,1,true,AC_RND_CONV,AC_SAT_SYM>,ac_fixed<10,4,true,AC_TRN,AC_WRAP>,config23> -inline
solution design set nnet::dense_resource_rf_gt_nin_rem0<ac_fixed<8,1,true,AC_RND_CONV,AC_SAT_SYM>,ac_fixed<10,4,true,AC_TRN,AC_WRAP>,config23> -inline
solution design set nnet::dense_resource_rf_gt_nin<ac_fixed<8,1,true,AC_RND_CONV,AC_SAT_SYM>,ac_fixed<10,4,true,AC_TRN,AC_WRAP>,config23> -inline
solution design set nnet::concatenate1d<ac_fixed<13,5,false,AC_RND_CONV,AC_SAT>,ac_fixed<13,5,false,AC_RND_CONV,AC_SAT>,ac_fixed<13,5,false,AC_RND_CONV,AC_SAT>,config12> -inline
solution design set nnet::pooling2d_cl<ac_fixed<2,2,false,AC_TRN,AC_WRAP>,ac_fixed<16,8,true,AC_TRN,AC_WRAP>,config2> -inline
solution design set nnet::pooling2d_cl<ac_fixed<2,2,false,AC_TRN,AC_WRAP>,ac_fixed<16,8,true,AC_TRN,AC_WRAP>,config3> -inline
solution design set nnet::pool_op_limit<config2> -inline
solution design set nnet::pad_val<ac_fixed<2,2,false,AC_TRN,AC_WRAP>,nnet::Average> -inline
solution design set nnet::pool_op<ac_fixed<2,2,false,AC_TRN,AC_WRAP>,16,nnet::Average,ac_fixed<24,10,true,AC_TRN,AC_WRAP>> -inline
solution design set nnet::max<ac_fixed<2,2,false,AC_TRN,AC_WRAP>,16,ac_fixed<24,10,true,AC_TRN,AC_WRAP>> -inline
solution design set nnet::avg<ac_fixed<2,2,false,AC_TRN,AC_WRAP>,16,ac_fixed<24,10,true,AC_TRN,AC_WRAP>> -inline
solution design set nnet::pool_op_limit<config3> -inline
directive set -SCHED_USE_MULTICYCLE true
go compile
solution library add tcbn28hpcplusbwp30p140ssg0p81v125c_ccs_dc -- -rtlsyntool DesignCompiler -vendor tsmc -technology tsmc28nm
solution library add ccs_sample_mem
solution library add ccs_sample_rom
solution library add hls4ml_lib
go libraries
directive set -CLOCKS {clk {-CLOCK_PERIOD 25.0 -CLOCK_EDGE rising -CLOCK_UNCERTAINTY 0.0 -CLOCK_HIGH_TIME 12.5 -RESET_SYNC_NAME rst -RESET_ASYNC_NAME arst_n -RESET_KIND sync -RESET_SYNC_ACTIVE high -RESET_ASYNC_ACTIVE low -ENABLE_ACTIVE high}}
go assembly
directive set /SmtPxl_QMlp_Slim/core/layer2_out:rsc -MAP_TO_MODULE {[Register]}
directive set /SmtPxl_QMlp_Slim/core/layer3_out:rsc -MAP_TO_MODULE {[Register]}
directive set /SmtPxl_QMlp_Slim/core/layer6_out:rsc -MAP_TO_MODULE {[Register]}
directive set /SmtPxl_QMlp_Slim/core/layer8_out:rsc -MAP_TO_MODULE {[Register]}
directive set /SmtPxl_QMlp_Slim/core/layer10_out:rsc -MAP_TO_MODULE {[Register]}
directive set /SmtPxl_QMlp_Slim/core/layer11_out:rsc -MAP_TO_MODULE {[Register]}
directive set /SmtPxl_QMlp_Slim/core/layer12_out:rsc -MAP_TO_MODULE {[Register]}
directive set /SmtPxl_QMlp_Slim/core/layer13_out:rsc -MAP_TO_MODULE {[Register]}
directive set /SmtPxl_QMlp_Slim/core/layer15_out:rsc -MAP_TO_MODULE {[Register]}
directive set /SmtPxl_QMlp_Slim/core/layer17_out:rsc -MAP_TO_MODULE {[Register]}
directive set /SmtPxl_QMlp_Slim/core/layer19_out:rsc -MAP_TO_MODULE {[Register]}
directive set /SmtPxl_QMlp_Slim/core/layer20_out:rsc -MAP_TO_MODULE {[Register]}
directive set /SmtPxl_QMlp_Slim/core/layer22_out:rsc -MAP_TO_MODULE {[Register]}
directive set /SmtPxl_QMlp_Slim/core/nnet::pooling2d_cl<input_t,layer2_t,config2>:for:for:for:pool:rsc -MAP_TO_MODULE {[Register]}
directive set /SmtPxl_QMlp_Slim/core/nnet::pooling2d_cl<input_t,layer3_t,config3>:for:for:for:pool:rsc -MAP_TO_MODULE {[Register]}
directive set /SmtPxl_QMlp_Slim/core/nnet::dense_latency<layer2_t,q_dense_result_t,config6>:acc:rsc -MAP_TO_MODULE {[Register]}
directive set /SmtPxl_QMlp_Slim/core/nnet::dense_latency<layer3_t,q_dense_1_result_t,config8>:acc:rsc -MAP_TO_MODULE {[Register]}
directive set /SmtPxl_QMlp_Slim/core/nnet::dense_latency<concatenate_result_t,q_dense_2_result_t,config13>:acc:rsc -MAP_TO_MODULE {[Register]}
directive set /SmtPxl_QMlp_Slim/core/nnet::dense_latency<layer15_t,dense_1_result_t,config17>:acc:rsc -MAP_TO_MODULE {[Register]}
directive set /SmtPxl_QMlp_Slim/core/nnet::dense_latency<layer19_t,dense_2_result_t,config20>:acc:rsc -MAP_TO_MODULE {[Register]}
directive set /SmtPxl_QMlp_Slim/core/nnet::dense_latency<layer22_t,result_t,config23>:acc:rsc -MAP_TO_MODULE {[Register]}
directive set /SmtPxl_QMlp_Slim/core/main -PIPELINE_INIT_INTERVAL 1
directive set /SmtPxl_QMlp_Slim/core/nnet::pooling2d_cl<input_t,layer2_t,config2>:for -UNROLL yes
directive set /SmtPxl_QMlp_Slim/core/nnet::pooling2d_cl<input_t,layer2_t,config2>:for:for -UNROLL yes
directive set /SmtPxl_QMlp_Slim/core/nnet::pooling2d_cl<input_t,layer2_t,config2>:for:for:for:for:for -UNROLL yes
directive set /SmtPxl_QMlp_Slim/core/nnet::avg<input_t,16,config2::accum_t>:for -UNROLL yes
directive set /SmtPxl_QMlp_Slim/core/nnet::pooling2d_cl<input_t,layer3_t,config3>:for -UNROLL yes
directive set /SmtPxl_QMlp_Slim/core/nnet::pooling2d_cl<input_t,layer3_t,config3>:for:for:for -UNROLL yes
directive set /SmtPxl_QMlp_Slim/core/nnet::pooling2d_cl<input_t,layer3_t,config3>:for:for:for:for -UNROLL yes
directive set /SmtPxl_QMlp_Slim/core/nnet::avg<input_t,16,config2::accum_t>#1:for -UNROLL yes
directive set /SmtPxl_QMlp_Slim/core/Compute -UNROLL yes
directive set /SmtPxl_QMlp_Slim/core/MultAndAccum -UNROLL yes
directive set /SmtPxl_QMlp_Slim/core/Compute#1 -UNROLL yes
directive set /SmtPxl_QMlp_Slim/core/MultAndAccum#1 -UNROLL yes
directive set /SmtPxl_QMlp_Slim/core/nnet::relu<q_dense_result_t,layer10_t,relu_config10>:for -UNROLL yes
directive set /SmtPxl_QMlp_Slim/core/nnet::relu<q_dense_1_result_t,layer11_t,relu_config11>:for -UNROLL yes
directive set /SmtPxl_QMlp_Slim/core/nnet::concatenate1d<layer10_t,layer11_t,concatenate_result_t,config12>:for -UNROLL yes
directive set /SmtPxl_QMlp_Slim/core/nnet::concatenate1d<layer10_t,layer11_t,concatenate_result_t,config12>:for#1 -UNROLL yes
directive set /SmtPxl_QMlp_Slim/core/Compute#2 -UNROLL yes
directive set /SmtPxl_QMlp_Slim/core/MultAndAccum#2 -UNROLL yes
directive set /SmtPxl_QMlp_Slim/core/nnet::hard_tanh<q_dense_2_result_t,layer15_t,hard_tanh_config15>:for -UNROLL yes
directive set /SmtPxl_QMlp_Slim/core/Compute#3 -UNROLL yes
directive set /SmtPxl_QMlp_Slim/core/MultAndAccum#3 -UNROLL yes
directive set /SmtPxl_QMlp_Slim/core/nnet::hard_tanh<dense_1_result_t,layer19_t,hard_tanh_config19>:for -UNROLL yes
directive set /SmtPxl_QMlp_Slim/core/Compute#4 -UNROLL yes
directive set /SmtPxl_QMlp_Slim/core/MultAndAccum#4 -UNROLL yes
directive set /SmtPxl_QMlp_Slim/core/nnet::hard_tanh<dense_2_result_t,layer22_t,hard_tanh_config22>:for -UNROLL yes
directive set /SmtPxl_QMlp_Slim/core/Compute#5 -UNROLL yes
directive set /SmtPxl_QMlp_Slim/core/MultAndAccum#5 -UNROLL yes
go architect
go extract
