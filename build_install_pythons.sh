#!/bin/bash
# Install Pythons and matching pips
set -ex

echo "deb http://ppa.launchpad.net/deadsnakes/ppa/ubuntu bionic main" > /etc/apt/sources.list.d/deadsnakes.list
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 6A755776
apt-get update
apt-get install -y wget
PIP_ROOT_URL="https://bootstrap.pypa.io"
wget $PIP_ROOT_URL/get-pip.py
apt-get install -y python3-distutils
for pyver in 3.5 3.6 3.7 3.8 2.7; do
    pybin=python$pyver
    apt-get install -y ${pybin}-dev
    get_pip_fname="get-pip.py"
    ${pybin} ${get_pip_fname}
done
apt-get install -y python-tk
apt-get install -y python3.5-tk
# this is one package for all versions 3.6+
apt-get install -y python3.6-tk

# Get virtualenv for Python 3.5
pip3.5 install --user virtualenv

BUILD_PKGS="zlib1g-dev libbz2-dev libncurses5-dev libreadline-gplv2-dev \
    libsqlite3-dev libssl-dev libgdbm-dev tcl-dev tk-dev \
    libffi-dev liblzma-dev uuid-dev"
apt-get -y install build-essential $BUILD_PKGS

function compile_python {
    local py_ver="$1"
    local extra_args="$2"
    local froot="Python-${py_ver}"
    local ftgz="${froot}.tgz"
    # Drop any suffix from three-digit version number
    local py_nums=$(echo $py_ver |  awk -F "." '{printf "%d.%d.%d", $1, $2, $3}')
    wget https://www.python.org/ftp/python/${py_nums}/${ftgz}
    tar zxf ${ftgz}
    local py_nodot=$(echo ${py_ver} | awk -F "." '{ print $1$2 }')
    local abi_suff=m
    # Python 3.8 and up no longer uses the PYMALLOC 'm' suffix
    # https://github.com/pypa/wheel/pull/303
    if [ ${py_nodot} -ge "38" ]; then
        abi_suff=""
    fi
    local out_root=/opt/cp${py_nodot}${abi_suff}
    mkdir $out_root
    (cd Python-${py_ver} \
        && ./configure --prefix=$out_root ${extra_args} \
        && make \
        && make install)
    rm -rf ${froot} ${ftgz}
}

# Compile narrow unicode Python
# Compiled Pythons need to be flagged in the choose_python.sh script.
compile_python 2.7.15 "--enable-unicode=ucs2"
# Get pip for narrow unicode Python
/opt/cp27m/bin/python get-pip.py

# Compile Python 3.7.0, pip comes along with.
# Python 3.7 from deadsnakes does not appear to have SSL.
# Compilation needs SSL 1.0.2, not available for Trusty.
function build_openssl {
    local version=$1
    local froot="openssl-${version}"
    local ftgz="${froot}.tar.gz"
    wget https://www.openssl.org/source/${ftgz}
    tar xvf ${ftgz}
    (cd $froot &&
    ./config no-ssl2 no-shared -fPIC --prefix=/usr/local/ssl &&
    make &&
    make install)
    rm -rf ${froot} ${ftgz}
}

# Clean out not-needed packages
apt-get -y remove $BUILD_PKGS
apt-get -y autoremove
apt-get clean

# Remove stray files
rm -f get-pip*.py
