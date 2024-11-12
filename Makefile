help:
	@echo "INFO: make <tab> for targets"
.PHONY: help

PYTHONPATH ?= "${MGC_HOME}/shared/pkgs/ccs_hls4ml/hls4ml jupyter-lab"

jupyter-lab:
	PYTHONPATH=${PYTHONPATH} jupyter-lab
	#PYTHONPATH=/home/giuseppe/research/projects/siemens/catapult_compare_releases/hls4ml_dgburnette jupyter-lab
.PHONY: jupyter-lab

backup:
	tar cvfz backup_$$(date +%Y%m%d_%H%M%S).tar.gz npy/ tfrecords/ weights/ qkeras.png comparison_qkeras_hls4m.png *dat
.PHONY: backup

clean:
	rm -f *_config.yml
	rm -f *_prj.tar.gz
	rm -rf *_prj
	rm -f tb_input_features.dat
	rm -f tb_output_predictions.dat
.PHONY: clean

ultraclean: clean
	rm -rf .ipynb_checkpoints
	rm -rf __pycache__
.PHONY: ultraclean
