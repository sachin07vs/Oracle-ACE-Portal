# Script should always be executed from a bash shell e.g. Source Tree Terminal
#########################################################################
#  file name create_zip_file.sh
#  Author Alan Telford
# Date 04 Nov 2017
# License Creative Commons
#
# Script to extract files from a GIT source branch and create a zip file
# with manifest for OMCS Cemlie patcher/ACE portal for upload
# Parameters
# 1 The branch to create the file from
#########################################################################
##
#function to make directory
make_directory() {

echo "make_directory called with $1"

if [ ! -d "$1" ]
then
  mkdir  -p "$1"
  if [ $? -eq 0 ]
  then
     echo "Created $1"
  else
    echo "encountered and error creating $1"
    return 103
  fi
fi
return 0 

}


#set main variables 
# TARGET is directory the files will be created in
TARGET_DIR="/c/git_output"
SOURCE_BRANCH=$1  #Branch to take code from
COMMENT=$2
REFERENCE_BRANCH=develop # branch to compare to
MANIFEST_FILE=manifest.csv
MODULE=xbol
REPO_HOME="/c/R12 Code Mainline"
SCRIPT_HOME=/c/git_scripts/
# name for achive directory
ARCHIVE=archive
BUILD=build
DATE_TIME=$(date +"%Y%m%d_%H%M%S")
shopt -o nounset


echo "Make sure you have pushed all code to origin"


# manifest file will contain the following comma delimited data 
#file name including patch with unix style slash delimiters e.g /forms/US/AKDATTRS.fmb
#module -- custom application  will default to XBOL for OMCS driven from MODULE variabble
#description (Will contain the first 20 characters of the branch name)
#file type e.g. fmb/rdf
#the deployment path (if required), 
#the language got from the path of the file in the application top (defaults to US)

#SQL Scripts can cover off a wide variety of activities, e.g views synonyms tables etc
#Therefore it is difficult to decide what they do from the context
#so the file type will be derived from a tag in the file header comments section


cd "${REPO_HOME}"
## check for unstaged changes
if ! git diff-files --quiet --ignore-submodules --
then
        echo "You have unstaged changes."
        git diff-files --name-status -r --ignore-submodules --
        exit 102
fi

# check for uncomitted changes
# Disallow uncommitted changes in the index
    if ! git diff-index --cached --quiet HEAD --ignore-submodules --
    then
        echo "Your index contains uncommitted changes."
        git diff-index --cached --name-status -r --ignore-submodules HEAD --
        err=103
    fi

echo "Checking for source branch"
# Check out source branch
git branch --list $SOURCE_BRANCH
if [  $? -eq 0 ]
then
   echo "Branch name $SOURCE_BRANCH found."
else
   echo "Branch name $SOURCE_BRANCH not found."
   echo "Available Branches are"
   git branch
   exit 101
fi

#work out the current branch and check it out
CURRENT_BRANCH=$(git name-rev --name-only HEAD)
if [ $SOURCE_BRANCH != $CURRENT_BRANCH ]
then
## check out the branch
  git checkout $SOURCE_BRANCH
else
  echo "already on $SOURCE_BRANCH"
fi

# check if origin is in line with local copy if not ask user to push code
ORIGIN_DIFF=$(git diff @{upstream})

if [ -n "$ORIGIN_DIFF" ]
then
  echo "Please push you changes to origin before proceeding"
fi
  

#get the common commit point between SOURCE_BRANCH and REFERENCE_BRANCH
LAST_COMMON_COMMIT=$(git merge-base origin/$REFERENCE_BRANCH origin/$SOURCE_BRANCH)

echo "Found last common commit point to $REFERENCE_BRANCH is $LAST_COMMON_COMMIT"


git diff --name-status $LAST_COMMON_COMMIT..$SOURCE_BRANCH

#check if  TARGET directory exists if not error with exit code 100
# remove any spaces from the SOURCE_BRANCH  should not really happen with source tree

SOURCE_BRANCH_NOSPACE=$(echo ${SOURCE_BRANCH// /_/})

# two structures BUILD and ARCHIVE
# Zip files end up in ARCHIVE
# Build get blown away each time the build is done
SOURCE_BRANCH_BUILD="${TARGET_DIR}/$BUILD/${SOURCE_BRANCH_NOSPACE}"
SOURCE_BRANCH_ARCHIVE="${TARGET_DIR}/$ARCHIVE/${SOURCE_BRANCH_NOSPACE}"
echo "Source build branch $SOURCE_BRANCH_BUILD"
echo "Source archive branch $SOURCE_BRANCH_ARCHIVE"

if [ ! -d "$TARGET_DIR" ]
then
  echo "Plaese create target directory $TARGET_DIR"
  exit 100
else
  echo "Creating files in ${SOURCE_BRANCH_DIR}"
fi
# remove any directories under $SOURCE_BRANCH_BUILD
rm -f "$SOURCE_BRANCH_BUILD"/*

make_directory $SOURCE_BRANCH_BUILD
make_directory $SOURCE_BRANCH_ARCHIVE


#Copy Files Across
 

# Find files changed between source and reference branch

#clear down manifest file
rm $SOURCE_BRANCH_ARCHIVE/manifest.txt

# iterate through files
for FILE in $(git diff --name-only $LAST_COMMON_COMMIT..$SOURCE_BRANCH)
do
 
 make_directory "$SOURCE_BRANCH_BUILD"/$(dirname $FILE)
 cp $FILE "$SOURCE_BRANCH_BUILD"/$(dirname $FILE)
 EXTENSION=${FILE#*.}     # Right of .
 echo "File extension is  $EXTENSION"
 case $EXTENSION in
      pkb)
	     EXTENSION=c_pkb
		 echo "changed pkb to c_pkb"
		 ;;
	  pks)
	     EXTENSION=c_pks
		 ;;
 esac
 
 #check if the CEMLI_FILE_TYPE is set in the file
CEMLI_EXTENSION=$(sed -n 's/^.*CEMLI_FILE_TYPE=//p' $FILE)

if [ ! -z $CEMLI_EXTENSION ]
then
  echo "Setting extension to $CEMLI_EXTENSION"
  EXTENSION=$CEMLI_EXTENSION
fi

 
 # trim off the drive name from the path to match the zip file
 FILE_PATH=$(echo "${SOURCE_BRANCH_BUILD}/${FILE}" | cut -c4-) 
 
 # write file details to manifest file TARGET/SOURCE_BRANCH/manifest.csv
 echo "${FILE_PATH},${MODULE},,$EXTENSION,,US" >> $SOURCE_BRANCH_ARCHIVE/manifest.txt

done

#zip the directory and copy it to archive
zip -r ${SOURCE_BRANCH_ARCHIVE}/${DATE_TIME}.zip ${SOURCE_BRANCH_BUILD}/*

exit 0



