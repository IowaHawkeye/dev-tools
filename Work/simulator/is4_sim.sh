#! /bin/bash

CONTROLLER_DIR=$HOME/workspace/br/4K_TRUNK/controller4000
APED_DIR=$CONTROLLER_DIR/aped
ABED_DIR=$HOME/workspace/br/4K_TRUNK/blade4000/aci4235-e24-1

LAUNCH_CONTAINER=$HOME/workspace/br/4K_TRUNK/sharedSource4000/toolchain/launch4kToolchainContainer.sh
TOOLCHAIN=/opt/poky/1.8.2/environment-setup-i586-poky-linux 

if  docker ps | grep -q 4k_1.9 ; then
      echo "Container already started, continuing..."
      FOUND=1
   else
      echo "Starting docker build container"
      gnome-terminal -- bash -c '$HOME/workspace/br/4K_TRUNK/sharedSource4000/toolchain/launch4kToolchainContainer.sh; exec bash' 
   fi

echo "Building controller sim environment..."

# Start with the controller.  Needs to be done as child so it has its own env
# for the toolchain.
bash -c "source $TOOLCHAIN; cd $APED_DIR; make sim_delete; make ../sim"


#$LAUNCH_CONTAINER

#env -i python3 ~/bin/build_controller.py

python3 ~/bin/build_controller.py

cp ~/bin/is4_sim.xml $CONTROLLER_DIR/sim/etc/aped.d/automation/testscripts/

echo "Building IS4 sim environment...."
bash -c "source $TOOLCHAIN; cd $ABED_DIR; make sim_delete; make $ABED_DIR/sim_0"

python3 ~/bin/build_is4.py


echo "Starting IS4 sim...."
gnome-terminal -- bash -c 'echo Starting IS4 Abed.....; sudo chroot /home/dberger/workspace/br/4K_TRUNK/blade4000/aci4235-e24-1/sim_0 abed -vfsS0 -c ACI-4040-C; exec bash' 

echo "Starting Controller sim..."
gnome-terminal -- bash -c 'echo Starting Controller Aped.....; sudo chroot /home/dberger/workspace/br/4K_TRUNK/controller4000/sim aped -vfst is4_sim.xml; exec bash' 

TIMEOUT=0
FOUND=0

while [ $TIMEOUT -lt 15 ] && [ $FOUND -eq 0 ]; do

   if  sudo netstat -tunlp | grep -q 8888 ; then
      echo "found"
      FOUND=1
   else
      sleep 1
      ((TIMEOUT++))
      echo "CLI unavailable. Retry($TIMEOUT)..."
   fi
done

if [ $TIMEOUT -ge 15 ]; then
   echo "CLI failed to come up. Unable to find port 8888"
else
   gnome-terminal --geometry 120x24 -- bash -c 'echo Starting CLI...; cd /home/dberger/workspace/br/4K_TRUNK/controller4000/pyCLI/; ./startPyCli.sh; exec bash' 
fi

