#!/bin/bash
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#                                                                             #
# IRAVATA                                                                     #
#                                                                             #
#                                                                             #
#                                                                             #
#                                                                             #
#                                                                             #
#                                                                             #
#                                                                             #
#                                                                             #
#                                                                             #
#                                                                             #
#                                                                             #
#                                                                             #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
VERSION=1.0
PRGNAME=iravata
#
#
#
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#                                                                             #
# HELPER FUNCTIONS                                                            #
#                                                                             #
#                                                                             #
#                                                                             #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
function git_clone () {

    local git_url=${1}
    local checkout_branch=${2}
    local install_path=${3}

    git clone ${git_url} ${install_path}
    cd ${install_path}
    git checkout ${checkout_branch}
}
function contains () {

    # Credits: stackoverflow
    # Returns 0 if $2 exists in $1
    if [[ $1 =~ (^|[[:space:]])$2($|[[:space:]]) ]]
    then
        return 0
    else
        return 1
    fi
}
function print_version () {

    echo $PRGNAME $VERSION
}
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#                                                                             #
# COMMAND FUNCTIONS                                                           #
#                                                                             #
#                                                                             #
#                                                                             #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
function create_python_env () {

    # PARAM LIST:
    # $1 = path to the installation directory
    local env_name=${1}

    python3 -m venv ${env_name}
    echo Python environment created: ${env_name}
}

function activate_python_env () {

    # PARAM LIST:
    # $1 = path to the installation directory
    local env_path=${1}

    source ${env_path}/bin/activate
    echo Python environment activated: ${env_path}
}

function install_python_dependencies () {

    # PARAM LIST:
    # $1 = list of dependencies
    local python_dependencies=${1}

    pip install ${python_dependencies}
    echo Airavata dependencies installed
}

function download_spack () {

    # PARAM LIST:
    # $1 = url to clone from
    # $2 = where to install spack
    # $3 = git branch to checkout
    local spack_git=${1}
    local spack_path=${2}
    local spack_ver=${3}

    contains "true TRUE True yes YES Yes 0 ok Ok OK please Please PLEASE stp STP Stp" $IRA_SPACK_REINSTALL

    if [[ $? -eq 0  ]]
    then
        echo Force reinstall spack activated
        if [[ -e ${spack_path} ]]
        then
            rm -rf ${spack_path}
            git_clone ${spack_git} ${spack_ver} ${spack_path}
        fi
    else
        if [[ -e ${spack_path} ]]
        then
            echo Spack already installed, bypassing installation
        else
            git_clone ${spack_git} ${spack_ver} ${spack_path}
        fi
    fi
}

function activate_spack () {

    # PARAM LIST:
    # $1 = path to where is spack installed
    local spack_path=${1}

    source ${spack_path}/share/spack/setup-env.sh
    echo Spack is now active: `which spack`
}

function download_airavata () {

    # PARAM LIST:
    # $1 = url to clone from
    # $3 = git branch to checkout
    # $2 = where to install spack
    local git_url=${1}
    local checkout_branch=${2}
    local install_path=${3}

    if [[ -e ${install_path} ]]
    then
        rm -rf ${install_path}
        git_clone ${git_url} ${checkout_branch} ${install_path}
    fi
}
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#                                                                             #
# EXECUTION FUNCTIONS                                                         #
#                                                                             #
#                                                                             #
#                                                                             #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
function execute_pyenv () {

    local python_env_path=$1
    create_python_env $python_env_path
}
function execute_pyact () {

    local python_env_path=$1
    activate_python_environment $python_env_path
}
function execute_pipinst () {

    local python_dependencies=$1
    install_python_dependencies $python_dependencies
}
function execute_spackdl () {

    local spack_git=$1
    local spack_path=$2
    local spack_ver=$3
    download_spack $spack_git $spack_path $spack_ver
}
function execute_spacktivate () {

    local spack_path=$1
    activate_spack $spack_path
}
function execute_airvatadl () {

    local airavata_git=$1
    local airavata_path=$2
    local airavata_ver=$3
    airavata_download $airavata_git $airavata_path $airavata_ver
}
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#                                                                             #
# OPTIONS PARSING                                                             #
#                                                                             #
#                                                                             #
#                                                                             #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
function usage () {

    echo "usage: iravata CMD [OPTIONS]                "
    echo
    echo "COMMANDS:                                   "
    echo "  pyenv       - create python environment   "
    echo "  pyact       - activate python environment "
    echo "  pipinst     - installpython packages      "
    echo "  spackdl     - download spack              "
    echo "  spacktivate - activate spack              "
    echo "  airavatadl  - download airavata           "
    echo
    exit 2
}

# Print usage if no options given
if [ $# = "0" ] ; then usage ; fi

SUBCOMMAND=$1
case $SUBCOMMAND in
    pyenv)
        # PROCESS OPTIONS
        OPTS=$(getopt -a -n iravata --long path:, -- "$@")
        if [ $? != "0" ]; then usage; fi
        eval set -- "$OPTS"
        while :
        do
            case "$1" in
                --path ) path_arg=1 ; path_val=$2 ; shift 2;;
                --) break ;;
            esac
        done
        # MERGE OPTIONS
        if [ -z $path_val ]; then
            python_env_path=$path_val
        else
            python_env_path=$IRA_PYTHON_ENV_PATH
        fi
        # EXECUTE COMMAND
        execute_pyenv $python_env_path
        ;;
    pyact)
        # PROCESS OPTIONS
        OPTS=$(getopt -a -n iravata --long path:, -- "$@")
        if [ $? != "0" ]; then usage; fi
        eval set -- "$OPTS"
        while :
        do
            case "$1" in
                --path ) path_arg=1 ; path_val=$2 ; shift 2;;
                --) break ;;
            esac
        done
        # MERGE OPTIONS
        if [ -z $path_val ]; then
            python_env_path=$path_val
        else
            python_env_path=$IRA_PYTHON_ENV_PATH
        fi
        # EXECUTE COMMAND
        execute_pyact $path_val
        ;;
    pipinst)
        # PROCESS OPTIONS
        OPTS=$(getopt -a -n iravata --long deps:, -- "$@")
        if [ $? != "0" ]; then usage; fi
        eval set -- "$OPTS"
        while :
        do
            case "$1" in
                --deps  ) deps_arg=1  ; deps_val=$2  ; shift 2;;
                --) break ;;
            esac
        done
        # MERGE OPTIONS
        if [ -z $deps_val ]; then
            python_dependencies=$deps_val
        else
            python_dependencies=$IRA_PYTHON_DEPENDENCIES
        fi
        # EXECUTE COMMAND
        execute_pipinst $python_dependencies
        ;;
    spackdl)
        # PROCESS OPTIONS
        OPTS=$(getopt -a -n iravata --long git:,ver:,path:, -- "$@")
        if [ $? != "0" ]; then usage; fi
        eval set -- "$OPTS"
        while :
        do
            case "$1" in
                --git  ) git_arg=1  ; git_val=$2  ; shift 2;;
                --path ) path_arg=1 ; path_val=$2 ; shift 2;;
                --ver  ) ver_arg=1  ; ver_val=$2  ; shift 2;;
                --) break ;;
            esac
        done
        # MERGE OPTIONS
        if [ -z $git_val ]; then
            spack_git=$git_val
        else
            spack_git=$IRA_SPACK_GIT
        fi
        if [ -z $path_val ]; then
            spack_path=$path_val
        else
            spack_path=$IRA_SPACK_PATH
        fi
        if [ -z $ver_val ]; then
            spack_ver=$ver_val
        else
            spack_ver=$IRA_SPACK_VER
        fi
        # EXECUTE COMMAND
        execute_spackdl $spack_git $spack_path $spack_ver
        ;;
    spacktivate)
        # PROCESS OPTIONS
        OPTS=$(getopt -a -n iravata --long git:,ver:,path:, -- "$@")
        if [ $? != "0" ]; then usage; fi
        eval set -- "$OPTS"
        while :
        do
            case "$1" in
                --path ) path_arg=1 ; path_val=$2 ; shift 2;;
                --) break ;;
            esac
        done
        # MERGE OPTIONS
        if [ -z $path_val ]; then
            spack_path=$path_val
        else
            spack_path=$IRA_SPACK_PATH
        fi
        # EXECUTE COMMAND
        execute_spacktivate $spack_path
        ;;
    airavatadl)
        # PROCESS OPTIONS
        OPTS=$(getopt -a -n iravata --long git:,ver:,path:, -- "$@")
        if [ $? != "0" ]; then usage; fi
        eval set -- "$OPTS"
        while :
        do
            case "$1" in
                --git  ) git_arg=1  ; git_val=$2  ; shift 2;;
                --path ) path_arg=1 ; path_val=$2 ; shift 2;;
                --ver  ) ver_arg=1  ; ver_val=$2  ; shift 2;;
                --) break ;;
            esac
        done
        # MERGE OPTIONS
        if [ -z $git_val ]; then
            airavata_git=$git_val
        else
            airavata_git=$IRA_AIRAVATA_GIT
        fi
        if [ -z $path_val ]; then
            airavata_path=$path_val
        else
            airavata_path=$IRA_AIRAVATA_PATH
        fi
        if [ -z $ver_val ]; then
            airavata_ver=$ver_val
        else
            airavata_ver=$IRA_AIRAVATA_VER
        fi
        # EXECUTE COMMAND
        execute_airvatadl $airavata_git $airavata_path $airavata_ver
        ;;
    *)
        echo unknown command: $1
        usage
        ,,
esac
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#                                                                             #
# TESTING / MANUAL RUNNING                                                    #
#                                                                             #
#                                                                             #
#                                                                             #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# # $1 = path to python environment
# create_python_env $IRA_PYTHON_ENV_PATH
#
# # $1 = path to python environment
# activate_python_env $IRA_PYTHON_ENV_PATH
#
# # $1 = dependencies to install
# install_python_dependencies $IRA_PYTHON_DEPENDENCIES
#
# # $1 = git path (git@github.com:.../...)
# # $2 = spack path
# # $3 = spack release to checkout
# download_spack $IRA_SPACK_GIT $IRA_SPACK_PATH $IRA_SPACK_VER
#
# # $1 = spack path
# activate_spack $IRA_SPACK_PATH
#
# # $1 = git path (git@github.com:.../...)
# # $2 = airavata path
# download_airavata $IRA_AIRAVATA_GIT $IRA_AIRAVATA_PATH $IRA_AIRAVATA_VER
