FROM ubuntu:14.04

# Installer script for Pythons 2.7 3.4 3.5 3.6
COPY build_install_pythons.sh /

# Install Pythons 2.7 3.4 3.5 3.6 3.3 2.6 and matching pips
RUN bash -c "source /build_install_pythons.sh && get_pythons_from_deadsnake"

#Install Python 2.7.11 narrow, 3.7, 3.8.0rc1
RUN bash -c "source /build_install_pythons.sh && install_build_dep"
RUN bash -c "source /build_install_pythons.sh && build_2_7_11_narrow"
RUN bash -c "source /build_install_pythons.sh && build_openssl 1.0.2o"
RUN bash -c "source /build_install_pythons.sh && compile_python 3.7.0 --with-openssl=/usr/local/ssl"
RUN bash -c "source /build_install_pythons.sh && compile_python 3.8.0 --with-openssl=/usr/local/ssl 3.8.0rc1"
# Post install and cleanup
RUN bash -c "source /build_install_pythons.sh && install_certificates"
RUN bash -c "source /build_install_pythons.sh && install_build_dep uninstall"

RUN bash -c "rm build_install_pythons.sh"

# Install manylinux1 libraries. See:
# https://www.python.org/dev/peps/pep-0513/#the-manylinux1-policy
# Thanks to @native-api for the report:
# https://github.com/matthew-brett/multibuild/issues/106
RUN apt-get update && \
        apt-get install -y libncurses5 libgcc1 libstdc++6 libc6 libx11-6 libxext6 \
        libxrender1 libice6 libsm6 libgl1-mesa-glx libglib2.0-0

# Script to choose Python version
COPY choose_python.sh /usr/bin/
# Run Python selection on way into image
ENTRYPOINT ["/usr/bin/choose_python.sh"]
