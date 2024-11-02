# smart-pixels-ml

## Catapult Codesign

- Use the Python environment that gets created with Catapult AI NN. See also these [instructions](https://github.com/GiuseppeDiGuglielmo/catapult_venvs) to properly setup the Catapult environment. The `ccs_venv` environment may be still missing some packages to properly run the notebooks in this repository. Please, for now, `pip install` what is missing; I will follow up with detailed instructions in the future.
- Remember to export Catapult HLS paths and variables so the `MGC_HOME` variable is defined.
- Run Jupyter Lab.

In summary:
```
source ~/bin/siemens.sh # This may vary according to your setup
source ~/ccs_venv/bin/activate
make jupyter-lab
```
