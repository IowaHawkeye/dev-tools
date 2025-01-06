#!/bin/bash


if [ -z "$WORK_DIR" ]; then
   echo "$WORK_DIR is not set! It should be set with something like: "
   echo "export WORK_DIR=$HOME/workspace/br/4K_TRUNK"
fi

declare -A targets

targets=(
    ["controller"]="$WORK_DIR/controller4000/aped $WORK_DIR/controller4000/common/ $WORK_DIR/controller4000/utils/ $WORK_DIR/sharedSource4000/ $WORK_DIR/armadaSDK/kernel/linux-3.18.43/include/ $WORK_DIR/armadaSDK/kernel/linux-3.18.43/net/tipc/
"
    ["blade"]="$WORK_DIR/blade4000/<BLADE_DIR>/src/ $WORK_DIR/blade4000/services/ $WORK_DIR/blade4000/common/ $WORK_DIR/armadaSDK/kernel/linux-3.18.43/include/ $WORK_DIR/armadaSDK/kernel/linux-3.18.43/net/tipc/"

)


Help()
{
   echo "This script will generate ctags and cscope tag files for various     "
   echo "targets.  The results will be placed in $WORK_DIR/tags/<target>.     "
   echo "After execution the user should set the \$TAGS_DIR variable to       "
   echo "$WORK_DIR/tags/<target> so the .vimrc file will load the             "
   echo "appropriate tags files.                                              "
   echo
   echo "Syntax: setup_tags.sh [-c|b|h]                                       "
   echo "options:                                                             "
   echo "-b <BLADE>    Create tags for the specific blade (e.g. aci4130-e28-1)"
   echo "-c            Create tags for the controller                         "
   echo "-h            Print this help.                                       "
   echo

}


if [ $# -le 0 ]; then
   echo "No Args!"
   Help
   exit
fi

while getopts "hcb:" option; do
   case $option in
      h)  # Display help
         Help
         exit;;

      c) # Controller
         target="controller"
         TAG_SUBDIR=$target
         ;;
 
      b) # Which blade type
         target="blade"
         blade=$OPTARG
         blade_opts=""
         found=0
         for i in `ls $WORK_DIR/blade4000 | grep aci`; do
            if [ "$blade" == "$i" ]; then
               found=1
               TAG_SUBDIR=$blade
               target_dirs="${targets["blade"]}"
               # Replace any instance of <BLADE_DIR> with the specific blade
               target_dirs=${target_dirs//<BLADE_DIR>/$blade}
               targets["blade"]="$target_dirs"

               break
            fi
            if [ "$blade_opts" == "" ]; then
               blade_opts=$i
            else
               blade_opts+="|$i"
            fi
         done
         if [ $found -eq 0 ]; then
            echo "-b should be one of $blade_opts"
            exit
         fi;;
         
      \?) # Invalid arg
           echo "Invalid arg!"
           Help
           exit;;
   esac
done


# If we got here all is good with args.  Let's do the tag creation.

TAGS_DIR="$WORK_DIR/tags/$TAG_SUBDIR"

echo "Setting up tags directory: $TAGS_DIR"

mkdir -p $TAGS_DIR
rm -rf $TAGS_DIR/*


find ${targets["$target"]} -name '*.c' -o -name '*.h' -o -name '*.cc' -o -name '*.cpp' -o -name '*.c++' -o -name '*.hh' -o -name '*.hpp' -o -name '*.h++' > $TAGS_DIR/tag.files

cd $TAGS_DIR
cscope -q -R -b -i $TAGS_DIR/tag.files
ctags -R --c++-kinds=+pf --fields=+iaS --extra=+qf -L $TAGS_DIR/tag.files

