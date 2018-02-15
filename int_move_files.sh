#/* $Header: int_move_files.sh 1.0 17/12/20 09:00:00 atelford sh$ */
# Script to copy cemli patch files back into International repository and stage
CURRENT_DIR=$(pwd)
TARGET_DIR=/c/"R12 Code Mainline"
export TARGET_DIR
cd $1/xbol
ls -R
if [ -d bin ]
then
 mv bin binary
fi
cp -r * $TARGET_DIR
cd $TARGET_DIR
git add -A
echo "Staged Files"
cd $CURRENT_DIR
pwd
