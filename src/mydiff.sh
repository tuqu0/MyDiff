#!/bin/sh

# ================================================================================
# Printing functions
# ================================================================================

function PrintUsage () {
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

function PrintMsg () {
	local level=$1
	local msg=$2

	if [ $level -le $VERBOSE_LEVEL ]
	then
		echo $msg
	fi
}

# ================================================================================
# Comparison functions
# ================================================================================

# Compare two entities. It depend on the enabled flags (DIFF, MD5, PERM, LAST DATE MODIFIED)
# If the entity is a directory, only the PERM test can be done (depending if the flag is enabled)
function DoCompare () {
	local res=1
	local src=$1
	local dst=$2

	if [ $COMP_DIFF -eq 1 ] && [ ! -d $src ] && [ ! -d $dst ]
	then
		DiffCompare $src $dst
	 	res=$?
		if [ $res -eq 1 ]
		then
			return $res
		fi
	fi

	if [ $COMP_MD5 -eq 1 ] && [ ! -d $src ] && [ ! -d $dst ]
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

	if [ $COMP_DATE -eq 1 ] && [ ! -d $src ] && [ ! -d $dst ]
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

function DoSynchronize () {
	local src=$1
	local dst=$2

	# TO DO...

}

# Compare the content between two files by using the "diff" command
function DiffCompare () {
	local res=1
	local src=$1
	local dst=$2

	if [ `diff $src` -eq `diff $dst` ]
	then
		res=0
	fi

	return $res	
}

# Check if two files have the same MD5 hash.
function MD5Compare () {
	local res=1
	local src=$1
	local dst=$2

	if [ `md5sum $src` == `md5sum $dst` ]
	then
		res=0
	fi

	return $res
}

# Compare the unix permission format between two files
function PermCompare () {
	local res=1
	local src=$1
	local dst=$2

	if [ `stat -c %a $src` -eq `stat -c %a $dst` ]
	then
		res=0
	fi

	return $res
}

# Compare the last time modification between two files
function LastModifiedCompare () {
	local res=1
	local src=$1
	local dst=$2

	if [ `stat -c %Y $src` -eq `stat -c %Y $dst` ]
	then
		res=0
	fi

	return $res
}

# ================================================================================
# Utils functions
# ================================================================================

# Check if the given directory ends with a slash and remove it
function  RemoveEndSlash() {
	local dir=$1
	
	if [ ${dir#${dir%?}} == '/' ]
	then
		dir=${dir:0:${#dir} - 1}
	fi
	echo $dir
}

# Check if the DIRPATH_SRC and DIRPATH_DST variables are initialized
function CheckInitVariables () {
	local src=$1
	local dst=$2

	if [ "$1" == "" ] || [ "$2" == "" ]
	then	
		PrintUsage
		exit $ERROR_UNINITIALIZED_VARIABLE
	fi
}

# Recursive function to list content of a directory
function RecursiveDiff () {
	local res=0
	local dst_item=""

	for src_item in $1/*
	do
		dst_item=$DIRPATH_DST${src_item:${#DIRPATH_SRC}:${#src_item}}
		if [ -d $src_item ]
		then
			echo "src dir: $src_item"
			echo "dst dir : $dst_item"
			DoCompare $src_item $dst_item
			RecursiveDiff $src_item
		elif [ -f $src_item ]
		then
			echo "src file: $src_item"
			echo "dst file : $dst_item"
			DoCompare $src_item $dst_item
		fi
	done
	return $res
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

SUCCESS=0
ERROR_INVALID_OPTION=1
ERROR_UNINITIALIZED_VARIABLE=2

############################# ARGUMENTS ANALYSIS ###############################

# Options parser and arguments initialization
while getopts "s:d:c:e:f:v:Sh" opt
do
	case $opt in
	's')
		DIRPATH_SRC=`RemoveEndSlash $OPTARG`
		;;
	'd')
		DIRPATH_DST=`RemoveEndSlash $OPTARG`
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

CheckInitVariables $DIRPATH_SRC $DIRPATH_DST
RecursiveDiff $DIRPATH_SRC

