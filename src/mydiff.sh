#!/bin/sh

# ================================================================================
# Printing functions
# ================================================================================

# Display the help menu
function PrintUsage() {
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
    -l <output file>
	 Default : \"myDiff.log\"
    -v <verbose level>      = verbose level
         0 = display nothing
         1 = display entity name if different
         2 = display differences details
         3 = display all tests
         Default : \"1\"
    -S			   = synchronize dst from src
"
}

# Display errors depending of the defined verbose level
function PrintMsg() {
	local level=$1
	local msg=$2

	if [ $level -le $VERBOSE_LEVEL ]
	then
		echo "$msg"
	fi
}

# Write a message with a given item name in a log file.
function LogDiff() {
	local item=$1
	local res=1

	if [ $LOG_NEW_ENTRY -eq 1 ]
	then
		LOG_NEW_ENTRY=0
		echo "--------------------------------------------------------------" >> $LOG_FILE
		echo -n "Date : " >> $LOG_FILE
		echo `date` >> $LOG_FILE
		echo "Source directory : $DIRPATH_SRC" >> $LOG_FILE
		echo "Destination directory : $DIRPATH_DST" >> $LOG_FILE
		echo "" >> $LOG_FILE
	fi

	if [ -f $LOG_FILE ]
	then
		echo "[dst][-] $item" >> $LOG_FILE
		res=0
	fi

	return $res
}

# ================================================================================
# Comparison functions
# ================================================================================

function DoSynchronize() {
	local src=$1
	local dst=$2

	# TO DO...

}

# Compare two entities. It depend on the enabled flags (DIFF, MD5, PERM, LAST DATE MODIFIED)
# If the entity is a directory, only the PERM test can be done (depending if the flag is enabled)
function DoCompare() {
	local res=1
	local src=$1
	local dst=$2

	if [ ! -e $dst ]
	then
	 	PrintMsg 2 "[2][-] Test   : Existence"
		PrintMsg 2 "   [-] Result : $dst doesn't exist"	
		return $res
	fi

	if [ $COMP_DIFF -eq 1 ] && [ ! -d $src ] && [ ! -d $dst ]
	then
		DiffCompare $src $dst
	 	res=$?
		if [ $res -eq 1 ]
		then
			PrintMsg 2 "[2][-] Test   : Diff"
			PrintMsg 2 "   [-] Result : Differences between $src and $dst"
			return $res
		fi
	fi

	if [ $COMP_MD5 -eq 1 ] && [ ! -d $src ] && [ ! -d $dst ]
	then
		MD5Compare $src $dst
		res=$?
		if [ $res -eq 1 ]
		then
			PrintMsg 2 "[2][-] Test   : MD5"
			PrintMsg 2 "   [-] Result : Differences between $src and $dst"
			return $res
		fi
	fi

	if [ $COMP_PERM -eq 1 ] || [ -d $dst ]
	then
		PermCompare $src $dst
		res=$?
		if [ $res -eq 1 ]
		then
			PrintMsg 2 "[2][-] Test   : Permissions"
			PrintMsg 2 "   [-] Result : Differences between $src and $dst"
			return $res
		fi
	fi

	if [ $COMP_DATE -eq 1 ] && [ ! -d $src ] && [ ! -d $dst ]
	then
		LastModifiedCompare $src $dst
		res=$?
		if [ $res -eq 1 ]
		then
			PrintMsg 2 "[2][-] Test   : Last Modified Date"
			PrintMsg 2 "   [-] Result : Differences between $src and $dst"
			return $res
		fi
	fi
	
	return $res
}

# Compare the content between two files by using the "diff" command
function DiffCompare() {
	local res=1
	local src=$1
	local dst=$2
	local diff=""

	diff=`diff $src $dst`
	if [ $? -eq 0 ]
	then
		res=0
	else
		PrintMsg 3 "[3][-] Test    : Diff"
		PrintMsg 3 "   [-] Command : diff $src $dst"
		PrintMsg 3 "   [-] Output  : $diff"
	fi

	return $res	
}

# Check if two files have the same MD5 hash.
function MD5Compare() {
	local res=1
	local src=$1
	local dst=$2
	local md5src=`md5sum $src`
	local md5dst=`md5sum $dst`

	if [ $md5src == $md5dst ]
	then
		res=0
	else
		PrintMsg 3 "[3][-] Test    : MD5"
		PrintMsg 3 "   [-] Command : Compare md5sum $src &&  md5sum $dst"
		PrintMsg 3 "   [-] Output  : $md5src - $md5dst"
	fi

	return $res
}

# Compare the unix permission format between two files
function PermCompare() {
	local res=1
	local src=$1
	local dst=$2
	local permSrc=`stat -c %a $src`
	local permDst=`stat -c %a $dst`

	if [ $permSrc -eq $permDst ]
	then
		res=0
	else
		PrintMsg 3 "[3][-] Test    : Permissions"
		PrintMsg 3 "   [-] Command : Compare stat -c %a $src && stat -c %a $dst"
		PrintMsg 3 "   [-] Output  : $permSrc - $permDst"
	fi

	return $res
}

# Compare the last time modification between two files
function LastModifiedCompare() {
	local res=1
	local src=$1
	local dst=$2
	local dateModifSrc=`stat -c %Y $src`
	local dateModifDst=`stat -c %Y $dst`

	if [ $dateModifSrc -eq $dateModifDst ]
	then
		res=0
	else
		PrintMsg 3 "[3][-] Test    : Last Modified Date"
		PrintMsg 3 "   [-] Command : Compare stat -c %Y $src && stat -c %Y $dst"
		PrintMsg 3 "   [-] Output  : $dateModifSrc - $dateModifDst"
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
function CheckInitVariables() {
	local src=$1
	local dst=$2

	if [ "$1" == "" ] || [ "$2" == "" ]
	then	
		PrintMsg 3 "[3][myDiff] Test    : Check Variables Initialization"
		PrintMsg 3 "   [myDiff] Result  : DIRPATH_SRC and/or DIRPATH_DST variables are not initialized"
		PrintUsage
		exit $ERROR_UNINITIALIZED_VARIABLE
	fi
}

# Recursive function to explore a given source directory and compare it with a destination directory
function RecursiveDiff() {
	local res=0
	local src=$1
	local dst=$2
	local dst_item=""

	for src_item in $src/*
	do
		dst_item=$dst${src_item:${#DIRPATH_SRC}:${#src_item}} # deduction of the destination item from the source item

		if [ -d $src_item ]
		then			
			DoCompare $src_item $dst_item
			if [ $? -eq 1 ]
			then
				PrintMsg 1 "[1][-] Test   : Comparison"
				PrintMsg 1 "   [-] Result : Directories $src_item and $dst_item mismatch"
				if [ $VERBOSE_LEVEL -ne 0 ]
				then
					printf '\n\n'
				fi
				LogDiff $dst_item
			fi
			RecursiveDiff $src_item $dst 
		elif [ -e $src_item ]
		then
			DoCompare $src_item $dst_item
			if [ $? -eq 1 ]
			then
				PrintMsg 1 "[1][-] Test   : Comparison"
			        PrintMsg 1 "   [-] Result : $src_item and $dst_item mismatch"
				if [ $VERBOSE_LEVEL -ne 0 ]
				then
					printf '\n\n'	
				fi
				LogDiff $dst_item
			fi
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
LOG_FILE="myDiff.log"
LOG_NEW_ENTRY=1

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
while getopts "s:d:c:e:f:l:v:Sh" opt
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
				PrintMsg 3 "[3][myDiff] Test   : Option checking"
			        PrintMsg 3 "   [myDiff] Result : Option '-c' has an invalid parameter"
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
	'l')	
		LOG_FILE=$OPTARG
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
			PrintMsg 3 "[3][myDiff] Test   : Option Checking"
			PrintMsg 3 "   [myDiff] Result : Option '-v' has an invalid verbose level"
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
		PrintMsg 3 "[3][myDiff] Test   : Option Checking"
	 	PrintMsg 3 "   [myDiff] Result : Option is not valid"
		PrintUsage
		exit $ERROR_INVALID_OPTION
	esac
done

############################# MAIN  ###############################

CheckInitVariables $DIRPATH_SRC $DIRPATH_DST
RecursiveDiff $DIRPATH_SRC $DIRPATH_DST
