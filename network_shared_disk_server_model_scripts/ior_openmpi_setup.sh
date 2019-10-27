


cd /root

# Download  the latest source tar ball from https://download.open-mpi.org/release/open-mpi/v4.0/openmpi-4.0.1.tar.bz2

#Configure and compile as normal user on one of compute node:
curl -O https://download.open-mpi.org/release/open-mpi/v4.0/openmpi-4.0.1.tar.bz2
tar -jxvf openmpi-4.0.1.tar.bz2
cd openmpi-4.0.1
mkdir build
cd build
../configure --prefix=/gpfs/fs1/openmpi-4.0.1
make all -j 8
make check
sudo make install

# Setup the environment variables. Append following lines to ~/.bash_profile


echo 'export MPI_HOME=/gpfs/fs1/openmpi-4.0.1' >> /root/.bash_profile
echo 'export PATH=${MPI_HOME}/bin:$PATH' >> /root/.bash_profile
echo 'export MANPATH=${MPI_HOME}/share/man' >> /root/.bash_profile
echo 'export LD_LIBRARY_PATH=${MPI_HOME}/lib:${MPI_HOME}/lib/openmpi:$LD_LIBRARY_PATH' >> /root/.bash_profile

source /root/.bash_profile


# IOR
#Download the latest official source tar ball file from https://github.com/hpc/ior/releases/download/3.2.1/ior-3.2.1.tar.gz
cd /root
# curl command downloads, but tar to extract fails, hence using wget
wget https://github.com/hpc/ior/releases/download/3.2.1/ior-3.2.1.tar.gz
#Extract and compile the source:
tar -zxvf ior-3.2.1.tar.gz
cd ior-3.2.1
./configure --prefix=/gpfs/fs1/ior-3.2.1
make
make install
cd /root

echo 'IOR START
        fsync=1
        intraTestBarriers=1
        api=POSIX
        reorderTasksRandom=1
        verbose=0
        filePerProc=1
        interTestDelay=30
        blockSize=200g
        testFile = /gpfs/fs1/test
        transferSize=2m
        repetitions=1
        RUN
IOR STOP' > /gpfs/fs1/ior.conf.cn


echo 'ss-compute-1.privateb0.gpfs.oraclevcn.com  slots=24
ss-compute-2.privateb0.gpfs.oraclevcn.com  slots=24
ss-compute-3.privateb0.gpfs.oraclevcn.com  slots=24
ss-compute-4.privateb0.gpfs.oraclevcn.com  slots=24' > /gpfs/fs1/hostsfile.cn

# Includes running on client1 only with 4 process instead of client1 only with 2 process
cd /root
# for i in $(seq 4 4 16); do /gpfs/fs1/openmpi-4.0.1/bin/mpirun --allow-run-as-root -n ${i} -npernode 4 --hostfile /gpfs/fs1/hostsfile.cn  /gpfs/fs1/ior-3.2.1/bin/ior -f /gpfs/fs1/ior.conf.cn && sleep 60;done | tee ior.out.fs2M.run1

# Exclude client1 only run, does client1,2 then client1,2,3 , then client1,2,3,4  each with 4 process
cd /root
# for i in $(seq 8 4 16); do /gpfs/fs1/openmpi-4.0.1/bin/mpirun --allow-run-as-root -n ${i} -npernode 4 --hostfile /gpfs/fs1/hostsfile.cn  /gpfs/fs1/ior-3.2.1/bin/ior -f /gpfs/fs1/ior.conf.cn && sleep 60;done | tee ior.out.fs2M.run2


# NOTE: After you run above mpirun with IOR and it completes execution or if you terminate it with CTRL-C, make sure that IOR is still not running.  Its a known issue, where IOR takes time to terminate and if you re-run the above, then it messes up the results.   Make sure to kill or check its not running on all nodes which were used to run benchmark (ss-compute-1, 2, 3, 4, etc).


