help:
	@echo "INFO: make <tab> for targets"
.PHONY: help

#PYTHONPATH ?= /extras2/home/gdg/research/projects/smartpixels/hls4ml_dgburnette
PYTHONPATH ?= "${MGC_HOME}/shared/pkgs/ccs_hls4ml/hls4ml"

jupyter-lab:
	PYTHONPATH=${PYTHONPATH} jupyter-lab
.PHONY: jupyter-lab

backup:
	tar cvfz backup_$$(date +%Y%m%d_%H%M%S).tar.gz npy/ tfrecords/ weights/ qkeras.png comparison_qkeras_hls4m.png *dat
.PHONY: backup

clean:
	rm -f *_config.yml
	rm -f *_prj.tar.gz
	rm -rf *_prj
	rm -f *tb_input_features.dat
	rm -f *tb_output_predictions.dat
	rm -f *debug.hdf5
	rm -f *debug.json
	rm -f *debug.keras
	rm -f *model.png
	rm -f *qkeras.png
	rm -f *animation.gif
	rm -f *comparison_qkeras_hls4ml.jpeg
.PHONY: clean

ultraclean: clean
	rm -rf .ipynb_checkpoints
	rm -rf __pycache__
.PHONY: ultraclean
