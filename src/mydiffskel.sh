#!/bin/sh

function PrintUsage {
	echo "
Usage : ./mydiff.sh -s <src dir> -d <dst dir> [-c <comparison flags>] [-e <skip items>] [-f <file filter>] [-v <verbose level>] [-S] [-h]

    -h                      = display this help
    -s <src dir>            = source directory
    -d <dst dir>            = destination directory
    -c <comparison flags>   = properties to compare :
         d = diff
         m = md5
         p = permission (and user/group)
         t = last modification date
         Use a list of flags separated by a space; e.g. : \"d p m\"
         Default : \"d\"
    -e <skip items>         = list of items to skip
         e.g. : -e \"\.txt\$ logs\"
    -f <file filter>        = file pattern to find
         e.g. : -f \"*.txt\"
    -v <verbose level>      = verbose level
         0 = display nothing
         1 = display entity name if different
         2 = display differences details
         3 = display all tests
         Default : \"1\"
    -S                      = synchronize dst from src
"
}

function PrintMsg {
	level=$1
	msg=$2
	if [ $level -le $VERBOSE_LEVEL ]
	then
		echo $msg
	fi
}

# ================================================================================
# Comparison functions
# ================================================================================

function DoCompare {
	res=0
	src=$1
	dst=$2

	# TO DO...

	return $res
}

function DoSynchronize {
	src=$1
	dst=$2

	# TO DO...

}

# ================================================================================
# Beginning of script
# ================================================================================

############################# ARGUMENTS DEFAULT VALUES ###############################

DIRPATH_SRC=""
DIRPATH_DST=""
COMP="d"
COMP_DIFF=1
COMP_MD5=0
COMP_PERM=0
COMP_DATE=0
SYNCHRONIZE=0
EXCLUDE=""
FILTER=""

VERBOSE_LEVEL=1
VERBOSE_LEVEL_ERROR=0
VERBOSE_LEVEL_DIFF=1
VERBOSE_LEVEL_DIFF_DETAIL=2
VERBOSE_LEVEL_ALL=3

############################# ARGUMENTS ANALYSIS ###############################

# TO DO...

cd $DIRPATH_SRC
for dirname in `find . -type d`
do
	# TO DO...
done

for filename in ...
do
	# TO DO
done


