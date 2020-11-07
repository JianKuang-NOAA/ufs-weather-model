#!/bin/bash

# A simple driver script designed to run a sample test case
# To replace run_test.sh

set -eux

export PATHRT=/work/noaa/marine/Jian.Kuang/ufs-weather-model
export RUNDIR_ROOT=/work/noaa/marine/Jian.Kuang/dataroot/stmp/jkuang
export TEST_NAME=fv3_ccpp_control
# ? name
export MACHINE_ID=orion.intel

# change to "test_vars.sh"
#source default_vars.sh
source sampletest_vars.sh
source tests/$TEST_NAME

export INPUT_DIR=${CNTL_DIR}
export RUNDIR=${RUNDIR_ROOT}/${TEST_NAME}${RT_SUFFIX}
export CNTL_DIR=${CNTL_DIR}${BL_SUFFIX}

export JBNME=$(basename $RUNDIR_ROOT)_${TEST_NR}

export REGRESSIONTEST_LOG=${LOG_DIR}/rt_${TEST_NR}_${TEST_NAME}${RT_SUFFIX}.log

# get rid of it
#source rt_utils.sh
source atparse.bash
#source edit_inputs.sh

# go to RUNDIR

mkdir -p ${RUNDIR}
cd $RUNDIR

####################################
# Make configure and run files
####################################

# FV3 executable:
cp ${PATHRT}/ufs_model .

# modulefile for FV3:
cp ${PATHRT}/modules.fv3_${COMPILE_NR} modules.fv3

# module-setup.sh
cp ${PATHRT}/module-setup.sh.inc module-setup.sh

SRCD="${PATHTR}"
RUND="${RUNDIR}"

atparse < ${PATHRT}/fv3_conf/${FV3_RUN:-fv3_run.IN} > fv3_run

atparse < ${PATHRT}/parm/${INPUT_NML:-input.nml.IN} > input.nml

atparse < ${PATHRT}/parm/${MODEL_CONFIGURE:-model_configure.IN} > model_configure

atparse < ${PATHRT}/parm/${NEMS_CONFIGURE:-nems.configure} > nems.configure

source ./fv3_run

if [[ $DATM = 'true' ]] || [[ $S2S = 'true' ]]; then
  edit_ice_in     < ${PATHRT}/parm/ice_in_template > ice_in
  edit_mom_input  < ${PATHRT}/parm/${MOM_INPUT:-MOM_input_template_$OCNRES} > INPUT/MOM_input
  edit_diag_table < ${PATHRT}/parm/diag_table_template > diag_table
  edit_data_table < ${PATHRT}/parm/data_table_template > data_table
  # CMEPS
  cp ${PATHRT}/parm/fd_nems.yaml fd_nems.yaml
  cp ${PATHRT}/parm/pio_in pio_in
  cp ${PATHRT}/parm/med_modelio.nml med_modelio.nml
fi
if [[ $DATM = 'true' ]]; then
  cp ${PATHRT}/parm/datm_data_table.IN datm_data_table
fi

atparse < ${PATHRT}/parm/${NEMS_CONFIGURE:-nems.configure} > nems.configure

ulimit -s unlimited
mpiexec -n ${TASKS} ./fv3.exe >out 2> >(tee err >&3)

elapsed=$SECONDS
echo "Elapsed time $elapsed seconds. Test ${TEST_NAME}"
