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

target_args=""

for target_list in "${!targets[@]}"; do
   if [ "$target_args" == "" ]; then
      target_args="$target_list"
   else 
      target_args+="|$target_list"
   fi
done

Help()
{
   echo "This script will generate ctags and cscope tag files for various   "
   echo "targets.  The results will be placed in $WORK_DIR/tags/<target>.   "
   echo "After execution the user should set the $TAGS_DIR variable so the  "
   echo ".vimrc file will load the appropriate tags files.                  "
   echo
   echo "Syntax: setup_tags.sh [-t|h]                                       "
   echo "options:                                                           "
   echo "-t $target_args    The target to create tags for.           "
   echo "-h                     Print this help.                         "
   echo

}


if [ $# -le 0 ]; then
   echo "No Args!"
   Help
   exit
fi

while getopts "ht:b:" option; do
   case $option in
      h)  # Display help
         Help
         exit;;
      t)  # Which target
         target=$OPTARG
         found=0
         for target_list in "${!targets[@]}"; do
            if [ "$target" == "$target_list" ]; then
               found=1
               TAG_SUBDIR=$target
               break
            fi
         done

         if [ $found -ne 1 ]; then
            echo "Invalid Target.  Options are $target_args"
            exit
         fi;;

      b) # Which blade type
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

