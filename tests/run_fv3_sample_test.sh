#!/bin/bash

# A simple driver script designed to run a sample test case
# To replace run_test.sh

set -eux

export UFS_REPO=${PWD}/..
export RUNDIR_ROOT=/work/noaa/marine/Jian.Kuang/dataroot/stmp/jkuang
export TEST_NAME=fv3_ccpp_control
# ? name
export MACHINE_ID=orion.intel

# change to "test_vars.sh"
#source default_vars.sh
source sampletest_vars.sh
source tests/$TEST_NAME

export INPUT_DIR=${CNTL_DIR}
export RUNDIR=${RUNDIR_ROOT}/${TEST_NAME}
export CNTL_DIR=${CNTL_DIR}

export JBNME=$(basename $RUNDIR_ROOT)_${TEST_NAME}

export TEST_LOG=${RUNDIR}/${TEST_NAME}.log

# get rid of it
#source rt_utils.sh
source atparse.bash
#source edit_inputs.sh

#baseline output
RTPWD=/work/noaa/nems/emc.nemspara/RT/NEMSfv3gfs/develop-20201103/INTEL

# go to RUNDIR
mkdir -p ${RUNDIR}
cd $RUNDIR

####################################
# Make configure and run files
####################################

# FV3 executable:
cp ${UFS_REPO}/build_$TEST_NAME/ufs_model fv3.exe

# modulefile for FV3:
cp ${UFS_REPO}/modulefiles/${MACHINE_ID}/fv3 modules.fv3

# module-setup.sh
cp ${UFS_REPO}/NEMS/src/conf/module-setup.sh.inc module-setup.sh

SRCD="${UFS_REPO}"
RUND="${RUNDIR}"

atparse < ${UFS_REPO}/tests/fv3_conf/${FV3_RUN:-fv3_run.IN} > fv3_run

atparse < ${UFS_REPO}/tests/parm/${INPUT_NML:-input.nml.IN} > input.nml

atparse < ${UFS_REPO}/tests/parm/${MODEL_CONFIGURE:-model_configure.IN} > model_configure

atparse < ${UFS_REPO}/tests/parm/${NEMS_CONFIGURE:-nems.configure} > nems.configure

source ./fv3_run

if [[ $DATM = 'true' ]] || [[ $S2S = 'true' ]]; then
  edit_ice_in     < ${UFS_REPO}/tests/parm/ice_in_template > ice_in
  edit_mom_input  < ${UFS_REPO}/tests/parm/${MOM_INPUT:-MOM_input_template_$OCNRES} > INPUT/MOM_input
  edit_diag_table < ${UFS_REPO}/tests/parm/diag_table_template > diag_table
  edit_data_table < ${UFS_REPO}/tests/parm/data_table_template > data_table
  # CMEPS
  cp ${UFS_REPO}/tests/parm/fd_nems.yaml fd_nems.yaml
  cp ${UFS_REPO}/tests/parm/pio_in pio_in
  cp ${UFS_REPO}/tests/parm/med_modelio.nml med_modelio.nml
fi
if [[ $DATM = 'true' ]]; then
  cp ${UFS_REPO}/tests/parm/datm_data_table.IN datm_data_table
fi

atparse < ${UFS_REPO}/tests/parm/${NEMS_CONFIGURE:-nems.configure} > nems.configure

ulimit -s unlimited
mpiexec -n ${TASKS} ./fv3.exe >out 2> >(tee err >&3)

elapsed=$SECONDS
echo "Elapsed time $elapsed seconds. Test ${TEST_NAME}"
