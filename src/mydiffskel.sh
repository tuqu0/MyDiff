#!/bin/sh

# ================================================================================
# Printing functions
# ================================================================================

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
    -S			   = synchronize dst from src
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
	res=1
	src=$1
	dst=$2

	if [ $COMP_DIFF -eq 1 ]
	then
		DiffCompare $src $dst
	 	res=$?
		if [ $res -eq 1 ]
		then
			return $res
		fi
	fi

	if [ $COMP_MD5 -eq 1 ]
	then
		MD5Compare $src $dst
		res=$?
		if [ $res -eq 1 ]
		then
			return $res
		fi
	fi

	if [ $COMP_PERM -eq 1 ]
	then
		PermCompare $src $dst
		res=$?
		if [ $res -eq 1 ]
		then
			return $res
		fi
	fi

	if [ $COMP_DATE -eq 1 ]
	then
		LastModifiedCompare $src $dst
		res=$?
		if [ $res -eq 1 ]
		then
			return $res
		fi
	fi
	

	return $res
}

function DoSynchronize {
	src=$1
	dst=$2

	# TO DO...

}

# Compare the content between two files by using the "diff" command
function DiffCompare {
	res=1
	src=$1
	dst=$2

	if [ `diff $src` -eq `diff $dst` ]
	then
		res=0
	fi
	return res	
}

# Check if two files have the same MD5 hash.
function MD5Compare {
	res=1
	src=$1
	dst=$2

	if [ `$BINARY_MD5 $src` == `$BINARY_MD5 $dst` ]
	then
		res=0
	fi
	return res
}

# Compare the unix permission format between two files
function PermCompare {
	res=1
	src=$1
	dst=$2

	if [ `stat -c %a $src` -eq `stat -c %a $dst` ]
	then
		res=0
	fi
	return res
}

# Compare the last time modification between two files
function LastModifiedCompare {
	res=1
	src=$1
	dst=$2

	if [ `stat -c %Y $src` -eq `stat -c %Y $dst` ]
	then
		res=0
	fi
	return res
}

# ================================================================================
# Beginning of script
# ================================================================================

############################# ARGUMENTS DEFAULT VALUES ###############################
BINARY_MD5="md5sum"

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

SUCCESS=0
ERROR_INVALID_OPTION=1
ERROR_UNINITIALIZED_VARIABLE=2
############################# ARGUMENTS ANALYSIS ###############################

# Options parser and arguments initialization
while getopts "s:d:c:e:f:v:Sh" opt
do
	case $opt in
	's')
		DIRPATH_SRC=$OPTARG
		;;
	'd')
		DIRPATH_DST=$OPTARG
		;;
	'c')
		for flag in $( echo $OPTARG | tr " " " " ) 
		do
			case $flag in
			'd')
				COMP_DIFF=1
				;;
			'm')
				COMP_MD5=1
				;;
			'p')
				COMP_PERM=1
				;;
			't')
				COMP_DATE=1
				;;
			?)
				PrintUsage
				exit $ERROR_INVALID_OPTION
			esac
		done
		;;
	'e')
		EXCLUDE=$OPTARG
		;;
	'f')
		FILTER=$OPTARG
		;;
	'v')
		case $OPTARG in
		0)
			VERBOSE_LEVEL=$VERBOSE_LEVEL_ERROR
			;;
		1)
			VERBOSE_LEVEL=$VERBOSE_LEVEL_DIFF
			;;
		2)
			VERBOSE_LEVEL=$VERBOSE_LEVEL_DIFF_DETAIL
			;;
		3)
			VERBOSE_LEVEL=$VERBOSE_LEVEL_ALL
			;;
		?)
			PrintUsage
			exit $ERROR_INVALID_OPTION
		esac
		;;
	'S')
		SYNCHRONIZE=1
		;;
	'h')
		PrintUsage
		exit $SUCCESS
		;;
	?)
		PrintUsage
		exit $ERROR_INVALID_OPTION
	esac
done

############################# MAIN  ###############################

# Check if the DIRPATH_SRC and DIRPATH_DST variables are initialized
if [ "$DIRPATH_SRC" == "" ] || [ "$DIRPATH_DST" == "" ]
then	
	PrintUsage
	exit $ERROR_UNINITIALIZED_VARIABLE
fi

# Compare source and destination directories 
cd $DIRPATH_SRC
for dirname in `find . -type d`
do
	echo $dirname	# TO DO...
done

exit
for filename in ...
do
	# TO DO
done
