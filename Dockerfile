FROM ubuntu:xenial
ENV OS_VER ubuntu_xenial

MAINTAINER Steven R. Brandt <sbrandt@cct.lsu.edu>

# add build tools and python to the sandbox
# Note: Agave requires openssh-server to be present
RUN apt-get update && \
    apt-get install -y --allow-unauthenticated make build-essential \
                       wget gcc g++ git gfortran git patch flex vim \
                       curl openssh-server python3 python3-pip && \
    apt-get purge

ENV MPICH_VER 3.1.4
RUN curl -kLO http://www.mpich.org/static/downloads/$MPICH_VER/mpich-$MPICH_VER.tar.gz
RUN tar xzf mpich-$MPICH_VER.tar.gz
WORKDIR /mpich-$MPICH_VER
RUN ./configure --prefix=/usr/local/mpich
RUN make install -j 20
ENV PATH /usr/local/mpich/bin:$PATH
ENV LD_LIBRARY_PATH /usr/local/mpich/lib:$LD_LIBRARY_PATH

WORKDIR /
ENV H5_MIN_VER 1.10
ENV H5_MAJ_VER 1.10.5
RUN curl -kLO https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-$H5_MIN_VER/hdf5-$H5_MAJ_VER/src/hdf5-$H5_MAJ_VER.tar.gz
RUN tar xzf hdf5-$H5_MAJ_VER.tar.gz
WORKDIR hdf5-$H5_MAJ_VER
ENV CC /usr/local/mpich/bin/mpicc
ENV CXX /usr/local/mpich/bin/mpicxx
RUN ./configure --enable-fortran --enable-shared --enable-parallel
RUN make install -j 2

ENV FUNWAVE_VER Version_3.4
WORKDIR /model
#RUN git clone https://github.com/fengyanshi/FUNWAVE-TVD
RUN wget https://github.com/fengyanshi/FUNWAVE-TVD/archive/${FUNWAVE_VER}.tar.gz
WORKDIR /model/FUNWAVE-TVD-${FUNWAVE_VER}/src
#RUN git checkout `git rev-list -n 1 --before="${FUNWAVE_VER} 00:00" master`
RUN make 

ENV SWAN_VER 4131
WORKDIR /model
RUN curl -kL http://downloads.sourceforge.net/project/swanmodel/swan/$(echo ${SWAN_VER}|sed 's/../&./')/swan${SWAN_VER}.tar.gz -o swan${SWAN_VER}.tgz
RUN tar xzvf swan${SWAN_VER}.tgz
WORKDIR /model/swan${SWAN_VER}
ENV EXTO o
ENV F90_MPI mpif90
ENV FLAGS90_MSC -ffree-line-length-0
ENV OUT "-o "
ENV F90_SER gfortran
RUN make mpi

ENV OPENFOAM_VER 1806
WORKDIR /model
RUN apt-get install -y libz-dev
COPY openfoam.sh ./
RUN bash ./openfoam.sh

ENV HYPRE_VER 2.11.2
WORKDIR /model
RUN curl -kLO https://computing.llnl.gov/projects/hypre-scalable-linear-solvers-multigrid-methods/download/hypre-${HYPRE_VER}.tar.gz
RUN tar xzf hypre-${HYPRE_VER}.tar.gz
WORKDIR /model/hypre-${HYPRE_VER}/src
RUN ./configure
RUN make

ENV NHWAVE_VER 2019-08-21
WORKDIR /model
RUN git clone https://github.com/JimKirby/NHWAVE
WORKDIR /model/NHWAVE
RUN git checkout `git rev-list -n 1 --before="${NHWAVE_VER} 00:00" master`
WORKDIR /model/NHWAVE/src
COPY Makefile.NHWAVE Makefile
RUN make 

# Some older LSU machines need to accept dsa
RUN echo PubkeyAcceptedKeyTypes +ssh-dss >> /etc/ssh/ssh_config

# A file needs to exist in order to be mounted. For
# ssh to work, we need to have a known hosts file.
RUN touch /etc/ssh/ssh_known_hosts
RUN mkdir -p /work

RUN useradd -m jovyan 
USER jovyan
WORKDIR /home/jovyan
