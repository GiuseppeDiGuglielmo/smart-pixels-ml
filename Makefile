help:
	@echo "INFO: make <tab> for targets"
.PHONY: help

jupyter-lab:
	PYTHONPATH=${MGC_HOME}/shared/pkgs/ccs_hls4ml/hls4ml jupyter-lab
.PHONY: jupyter-lab

clean:
	rm -f *_config.yml
	rm -f *_prj.tar.gz
	rm -rf *_prj
	rm -f tb_input_features.dat
	rm -f tb_output_predictions.dat
.PHONY: clean
