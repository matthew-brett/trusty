#!/bin/bash
# Choose python from PYTHON_VERSION, UNICODE_WIDTH
# Then make a virtualenv from that Python and source it
py_ver=${PYTHON_VERSION:-3.5}
uc_width=${UNICODE_WIDTH:-32}

py_nodot=$(echo ${py_ver} | awk -F "." '{ print $1$2 }')
if [ "$py_ver" == "2.7" ] || [ ${py_nodot} -ge "37" ]; then
    abi_suff=m
    # Python 3.8 and up no longer uses the PYMALLOC 'm' suffix
    # https://github.com/pypa/wheel/pull/303
    if [ ${py_nodot} -ge "38" ]; then
        abi_suff=""
    elif [ "$py_ver" == "2.7" ] && [ "$uc_width" == "32" ]; then
        abi_suff="mu"
    fi
    py_bin=/opt/cp${py_nodot}${abi_suff}/bin/python${py_ver}
else
    py_bin=/usr/bin/python${py_ver}
fi
if [ ! -e ${py_bin} ]; then
    exit 1
fi
/root/.local/bin/virtualenv --python=$py_bin venv
source venv/bin/activate

# Carry on as before
$@
