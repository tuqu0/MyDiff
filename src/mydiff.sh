#!/bin/bash


# ==============================================================================
# Name    : MyDiff
# Version : 0.1 
# Author  : Puydoyeux Vincent
# Date    : 06/12/2012 
# OS      : tested on Linux Fedora 17 and Linux Debian Squeeze
# ===============================================================================


# ================================================================================
# Printing functions
# ================================================================================


# Colors
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
CYAN='\033[36m'
WHITE='\033[37m'

# Display the help menu
function PrintUsage() {
	printf "$GREEN
Usage : ./mydiff.sh -s <src dir> -d <dst dir> [-m <comparison mode] [-c <comparison flags>] [-e <skip items>] [-f <file filter>] [-v <verbose level>] [-S] [-h]

    -h                      = display this help
    -s <src dir>            = source directory
    -d <dst dir>            = destination directory
    -m <comparison mode>    = algorithm used to analysed directories
         iterative
         recursive
         Default : \"recursive\"
    -c <comparison flags>   = properties to compare :
         d = diff
         m = md5
         p = permission (and user/group)
         t = last modification date
         Use a list of flags separated by a space; e.g. : \"d p m\"
         Default : \"d\"
    -e <skip items>         = list of items to skip
         e.g. : -e \"\.txt$ logs\"
    -f <file filter>        = file pattern to find
         e.g. : -f \"*.txt;*.log\"
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
		printf "$msg\n"
	fi
}

# Write a message with a given entity name in a log file.
function LogDiff() {
	local entity=$1

	# First call to the function => insert an header in the log file
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

	echo "[dst][-] $entity" >> $LOG_FILE
}


# ================================================================================
# Comparison functions
# ================================================================================

# Synchronize two entities (the content and attributes synchronized depend of the command line paramters)
function DoSynchronize() {
	local src=$1
	local dst=$2
	local perm=`GetPermissions $src`
	local userOwner=`GetOwnerUser $src`
	local groupOwner=`GetOwnerGroup $src`
	local lastModifiedDate=`GetLastModifiedDate $src`
	local merge=""

	# the source entity is a directory	
	if [ -d $src ]
	then
		# the destination directory does not exist
		if [ ! -d $dst ]
		then
			PrintMsg 3 "$RED[3][Synchronize] Test : Create a new directory"
			PrintMsg 3 "$RED   [Synchronize] Result : Directory $dst has been created"
			mkdir $dst	
		fi
	else # the source entity is a file => merge
		if [ ! -e $dst ]
		then
			PrintMsg 3 "$RED[3][Synchronize] Test : Create a new file"
			PrintMsg 3 "$RED   [Synchronize] Result : $dst has been created"
			touch $dst
		fi
		PrintMsg 3 "$RED[3][Synchronize] Test : Merge file"
		PrintMsg 3 "$RED   [Synchronize] Result : $dst has been merged from $src"
		merge=`echo l | sdiff -o $dst $src $dst`
	fi

	# Apply permissions, user and group owner, last modified date on the destination entity
	PrintMsg 3 "$RED[3][Synchronize] Test : Update file/directory attributes"

	PrintMsg 3 "$RED   [Synchronize] Result : set full access to $dst"
	SetPermissions $dst "777"

	PrintMsg 3 "$RED   [Synchronize] Result : update last modified date on $dst"
	SetLastModifiedDate $dst "$lastModifiedDate"

	PrintMsg 3 "$RED   [Synchronize] Result : update user owner of $dst"
	SetOwnerUser $dst $userOwner

	PrintMsg 3 "$RED   [Synchronize] Result : update group owner of $dst"
	SetOwnerGroup $dst $groupOwner

	PrintMsg 3 "$RED   [Synchronize] Result : update permissions on $dst"
	SetPermissions $dst $perm
}

# Compare two entities.  Tests depend on the enabled flags (DIFF, MD5, PERM, LAST DATE MODIFIED)
# If the entity is a directory, only the PERM test is done.
# If one of the tests fails, the function returns an error code.
function DoCompare() {
	local res=1
	local src=$1
	local dst=$2

	# if the destination entity does not exist
	if [ ! -e $dst ]
	then
	 	PrintMsg 2 "$BLUE[2][-][DoCompare] Test   : Existence"
		PrintMsg 2 "$BLUE   [-][DoCompare] Result : $dst doesn't exist"	
		return $res
	fi

	# if the flag COMP_DIFF is enabled and src and dst entities are not directories
	if [ $COMP_DIFF -eq 1 ] && [ ! -d $src ] && [ ! -d $dst ]
	then
		DiffCompare $src $dst
	 	res=$?
		if [ $res -eq 1 ]
		then
			PrintMsg 2 "$BLUE[2][-][DoCompare] Test   : Diff"
			PrintMsg 2 "$BLUE   [-][DoCompare] Result : Differences between $src and $dst"
			return $res
		fi
	fi

	# if the flag COMP_MD5 is enabled and src and dst entities are not directories
	if [ $COMP_MD5 -eq 1 ] && [ ! -d $src ] && [ ! -d $dst ]
	then
		MD5Compare $src $dst
		res=$?
		if [ $res -eq 1 ]
		then
			PrintMsg 2 "$BLUE[2][-][DoCompare] Test   : MD5"
			PrintMsg 2 "$BLUE   [-][DoCompare] Result : Differences between $src and $dst"
			return $res
		fi
	fi

	# if the flag COMP_PERM is enabled or if the src entity is a directory
	if [ $COMP_PERM -eq 1 ] || [ -d $src ]
	then
		PermCompare $src $dst
		res=$?
		if [ $res -eq 1 ]
		then
			PrintMsg 2 "$BLUE[2][-][DoCompare] Test   : Permissions"
			PrintMsg 2 "$BLUE   [-][DoCompare] Result : Differences between $src and $dst"
			return $res
		fi
	fi

	# if the flag COMP_DATE is enabled and src and dst entities are not directories
	if [ $COMP_DATE -eq 1 ] && [ ! -d $src ] && [ ! -d $dst ]
	then
		LastModifiedCompare $src $dst
		res=$?
		if [ $res -eq 1 ]
		then
			PrintMsg 2 "$BLUE[2][-][DoCompare] Test   : Last Modified Date"
			PrintMsg 2 "$BLUE   [-][DoCompare] Result : Differences between $src and $dst"
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
	local diff=`diff $src $dst`
	
	if [ ${#diff} -eq 0 ]
	then
		res=0
	else
		PrintMsg 3 "$RED[3][-][DiffCompare] Test    : Diff " 
		PrintMsg 3 "$RED   [-][DiffCompare] Command : 'diff $src $dst'"
		PrintMsg 3 "$RED   [-][DiffCompare] Result  : $diff"
	fi
	
	return $res
}

# Check if two files have the same MD5 hash
function MD5Compare() {
	local res=1
	local src=$1
	local dst=$2
	local md5src=`md5sum $src | cut -d' ' -f1`
	local md5dst=`md5sum $dst | cut -d' ' -f1`

	if [ $md5src == $md5dst ]
	then
		res=0
	else
		PrintMsg 3 "$RED[3][-][MD5Compare] Test    : MD5"
		PrintMsg 3 "$RED   [-][MD5Compare] Command : 'md5sum $src' and 'md5sum $dst'"
		PrintMsg 3 "$RED   [-][MD5Compare] Result  : $md5src - $md5dst"
	fi

	return $res
}

# Compare the permissions between two files
function PermCompare() {
	local res=1
	local src=$1
	local dst=$2
	local permSrc=`GetPermissions $src`
	local permDst=`GetPermissions $dst`

	if [ $permSrc -eq $permDst ]
	then
		res=0
	else
		PrintMsg 3 "$RED[3][-][PermCompare] Test    : Permissions"
		PrintMsg 3 "$RED   [-][PermCompare] Command : 'stat --format %%a' $src and 'stat --format %%a $dst'"
		PrintMsg 3 "$RED   [-][PermCompare] Result  : $permSrc and $permDst"
	fi

	return $res
}

# Compare the last modified date between two files
function LastModifiedCompare() {
	local res=1
	local src=$1
	local dst=$2
	local dateModifSrc=`GetLastModifiedDate $src`
	local dateModifDst=`GetLastModifiedDate $dst`

	if [ "$dateModifSrc" ==  "$dateModifDst" ]
	then
		res=0
	else
		PrintMsg 3 "$RED[3][-][LastModifiedCompare] Test    : Last Modified Date"
		PrintMsg 3 "$RED   [-][LastModifiedCompare] Command : 'stat --format %%y $src' and 'stat --format %%Y $dst'"
		PrintMsg 3 "$RED   [-][LastModifiedCompare] Result  : $dateModifSrc and $dateModifDst"
	fi

	return $res
}

# ================================================================================
# File/Directory functions
# ================================================================================

# Return the permissions of a file or directory (numeric format)
function GetPermissions() {
	local entity=$1
	local perm=`stat --format %a $entity`

	echo $perm
}

# Set given permissions on a file or directory
function SetPermissions() {
	local entity=$1
	local perm=$2
	local res=`chmod $perm $entity`
	
	return $?
}

# Retrun the user owner of a file or directory
function GetOwnerUser() {
	local entity=$1
	local user=`stat --format %U $entity`

	echo $user
}

# Set a user as the owner of a file or directory
function SetOwnerUser() {
	local entity=$1
	local user=$2
	local res=`chown $user $entity`

	return $?
}

# Return the group owner of a file or directory
function GetOwnerGroup() {
	local entity=$1
	local group=`stat --format %G $entity`

	echo $group
}

# Set a group as the owner of a file or directory
function SetOwnerGroup() {
	local entity=$1
	local group=$2
	local res=`chgrp $group $entity`

	return $?
}

#Return the last modified date of a file or directory
function GetLastModifiedDate() {
	local entity=$1
	local modifiedDate=`stat --format %y $entity`
	
	echo "$modifiedDate"
}

# Set a last modified date for a file or directory
function SetLastModifiedDate() {
	local entity=$1
	local modifiedDate="$2"
	local res=`touch -d "$modifiedDate" $entity`

	return $?
}


# ================================================================================
# Utils functions
# ================================================================================


# Check if the given directory ends with a slash and then remove it
function  RemoveEndSlash() {
	local dir=$1
	
	if [ ${dir#${dir%?}} == '/' ]
	then
		dir=${dir:0:${#dir} - 1}
	fi
	echo $dir
}

# Check if the DIRPATH_SRC and DIRPATH_DST variables are initialized and directories exist
function CheckInitSrcDestVar() {

	if [ "$DIRPATH_SRC" == "" ] || [ "$DIRPATH_DST" == "" ] || [ ! -d $DIRPATH_SRC ] || [ ! -d $DIRPATH_DST ]
	then	
		PrintMsg 3 "$RED[3][CheckInitSrcDestVar] Test    : DIRPATH_SRC and DIRPATH_DST variables initialization" 
		PrintMsg 3 "$RED   [CheckInitSrcDestVar] Result  : DIRPATH_SRC and/or DIRPATH_DST is/are not initialized"
		PrintUsage
    tput sgr0
		exit $ERROR_UNINITIALIZED_VARIABLE
	fi
}

# Return the file extension (ex: '.txt' )
function GetFileExtension() {
	local file=$1

	echo .${file#*.}
}

# Check if the entity extension is in the exclusion list
# Returns 1 if the extension is in the list, else 0
function CheckExtensionExclusions() {
	local src=$1
	local res=0

	if [ "$EXCLUDE_EXT" != "" ]
	then
		for ext in $EXCLUDE_EXT
		do
			# compare the entity extension with each extension in the list
			if [ `GetFileExtension $src_entity` == $ext ]
			then
				PrintMsg 3 "$RED[3][CheckExtensionExclusions] Test : Extensions Exclusion"
				PrintMsg 3 "$RED   [CheckExtensionExclusions] Result : $src will not be checked"
				PrintMsg 3 "$WHITE\n\n*********************************************************\n\n"
				res=1
				return $res
			fi
		done
	fi
	return $res
}

# Check if the entity pathname contains a pattern from the exlusion list
# Returns 0 if a pattern was found, else 1 
function CheckPathnameExclusions() {
	local src=$1
	local res=1
	local tmp=""

	if [ "$EXCLUDE_NAME" != "" ]
	then
		# for each pattern in the exlusion list
		for keyword in $EXCLUDE_NAME
		do
			# grep 'pattern' on the entity pathname
			tmp=`echo $src | grep $keyword`
			res=$?
			if [ $res -eq 0 ]
			then
				PrintMsg 3 "$RED[3][CheckPathnameExclusions] Test : Keyword Pathname Exclusion"
				PrintMsg 3 "$RED   [CheckPathnameExclusions] Result : $src will not be checked"
				PrintMsg 3 "$WHITE\n\n*********************************************************\n\n"
				return $res
			fi
		done
	fi
	return $res
}

# Check if the entity extension is in the filters list
# Returns 1 if the extension is in the list, else 0
function CheckExtensionFilters() {
	local src=$1
	local res=0

	if [ "$FILTER" != "" ]
	then
		for ext in $FILTER
		do
			if [ `GetFileExtension $src` == $ext ]
			then
				res=1
			fi
		done
	fi

	if [ $res -eq 0 ]
	then
		PrintMsg 3 "$RED[3][CheckEntensionFilters] Test : Extension Filters"
		PrintMsg 3 "$RED   [CheckExtensionFilters] Result : $src will not be checked"
		PrintMsg 3 "$WHITE\n\n*********************************************************\n\n"	
	fi

	return $res
}

# Recursive function to explore a given source directory and compare it with a destination directory
# Returns 0 if DIRPATH_SRC and DIRPATH_DST are similar, else 1
function RecursiveDiff() {
	local res=0
	local ret=0
	local extExclusions=0
	local pathnameExclusions=0
	local extFilters=0
	local src=$1
	local dst=$2
	local dst_entity=""

	# for each entity in the src directory
	for src_entity in $src/*
	do
		# deduction of the dst entity from the src entity path
		dst_entity=$dst${src_entity:${#DIRPATH_SRC}:${#src_entity}} 
	
		# case 1 : the entity is a directory (recursive call)
		if [ -d $src_entity ]
		then
			CheckPathnameExclusions $src_entity
			pathnameExclusions=$?
			# if the entity does not contain a pattern from the exclusion list
			if [ $pathnameExclusions -ne 0 ]
			then
				# comparison
				DoCompare $src_entity $dst_entity
				res=$?	
				# if src and dst are differents
				if [ $res -eq 1 ] 
				then
					if [ $SYNCHRONIZE -eq 1 ]
					then
						DoSynchronize $src_entity $dst_entity
					fi
					PrintMsg 1 "$YELLOW[1][-][RecursiveDiff] Test   : Comparison"
					PrintMsg 1 "$YELLOW   [-][RecursiveDiff] Result : Directories $src_entity and $dst_entity are differents"
					PrintMsg 1 "$WHITE\n\n*********************************************************\n\n"
					# log message in a file
					LogDiff $dst_entity
					ret=$ERROR_MISMATCH
				fi
			fi
			# recursive function call from the current sub directory
			RecursiveDiff $src_entity $dst



		# case 2 : the entity is not a directory
		elif [ -e $src_entity ] 
		then
			CheckExtensionExclusions $src_entity
			extExclusions=$?
			CheckPathnameExclusions $src_entity
			pathnameExclusions=$?

			# if the file extension is not in the exclusion list and no pattern
			if [ $extExclusions -eq 0 ] && [ $pathnameExclusions -ne 0 ]
			then
				# if filters have been set
				if [ "$FILTER" != "" ]
				then
					CheckExtensionFilters $src_entity
					extFilters=$?
					# if the entity extension is in the filters list
					if [ $extFilters -eq 1 ]
					then
						# comparison
						DoCompare $src_entity $dst_entity
						res=$?
					fi
				else
					# no filter defined
					DoCompare $src_entity $dst_entity
					res=$?
				fi

				# if src and dst entities are differents
				if [ $res -eq 1 ]
				then
					if [ $SYNCHRONIZE -eq 1 ]
					then
						DoSynchronize $src_entity $dst_entity
					fi
					PrintMsg 1 "$YELLOW[1][-][RecursiveDiff] Test : Comparison"
					PrintMsg 1 "$YELLOW   [-][RecursiveDiff] Result : $src_entity and $dst_entity are differents"
					PrintMsg 1 "$WHITE\n\n*********************************************************\n\n"
					# log message in a file
					LogDiff $dst_entity
				fi
			fi 
		fi
		res=0
	done

	return $ret
}

function IterativeDiff() {
	src=$1
	dst=$2
	
	echo "src : $src"
	echo "dst : $dst"

	# enter in the source directory
	cd $src

	# list all directories in the source directory
	for src_entity in `find . -type d`
	do
		echo "dir : $src_entity"
	done

	for src_entity in `find . -type f`
	do
		echo "file : $src_entity"
	done
}
# ================================================================================
# Beginning of script
# ================================================================================

############################# ARGUMENTS DEFAULT VALUES ###############################


DIRPATH_SRC=""
DIRPATH_DST=""
ANALYSIS_MODE=1
COMP="d"
COMP_DIFF=1
COMP_MD5=0
COMP_PERM=0
COMP_DATE=0
SYNCHRONIZE=0
EXCLUDE=""
EXCLUDE_EXT=""
EXCLUDE_NAME=""
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
ERROR_MISMATCH=3


############################# ARGUMENTS ANALYSIS ###############################


# Options parser and arguments initialization
while getopts "s:d:m:c:e:f:l:v:Sh" opt
do
	case $opt in
	's')	# source directory
		DIRPATH_SRC=`RemoveEndSlash $OPTARG`
		;;

	'd')	# destination directory
		DIRPATH_DST=`RemoveEndSlash $OPTARG`
		;;
  
	'm')	# analysis mode
		case $OPTARG in
		'iterative')
			ANALYSIS_MODE=0
			;;
		'recursive')
			ANALYSIS_MODE=1
			;;
		?)
			PrintMsg 3 "$RED[3][getopts] Test   : Option checking"
			PrintMsg 3 "$RED   [getopts] Result : Option '-m' has an invalid parameter"
			PrintUsage
      tput sgr0
			exit $ERROR_INVALID_OPTION
		esac
		;;

	'c')	# comparison mode
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
				PrintMsg 3 "$RED[3][getopts] Test   : Option checking"
				PrintMsg 3 "$RED   [getopts] Result : Option '-c' has an invalid parameter"
				PrintUsage
        tput sgr0
				exit $ERROR_INVALID_OPTION
			esac
		done
		;;

	'e')	# exclude filters
		EXCLUDE=$OPTARG
		for ext in $(echo $OPTARG | tr " " " ")
		do
			if [ ${ext:0:1} == '\' ] && [ ${ext:${#ext} - 1:${#ext}} == "$" ]
			then
				EXCLUDE_EXT="$EXCLUDE_EXT${ext:1:${#ext} - 2} "
			else
				EXCLUDE_NAME="$EXCLUDE_NAME$ext "
			fi
		done
		;;

	'f')	# include filters
		for ext in $(echo $OPTARG | tr ";" " ")
		do
			ext=$(echo $ext | tr "*" " ")
			ext=${ext[0]}
			FILTER="$FILTER$ext "
	 	done	
		;;

	'l')	# log file name
		LOG_FILE=$OPTARG
		;;

	'v')	# verbose levels
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
			PrintMsg 3 "$RED[3][getopts] Test   : Option Checking"
			PrintMsg 3 "$RED   [getopts] Result : Option '-v' has an invalid verbose level"
			PrintUsage
      tput sgr0
			exit $ERROR_INVALID_OPTION
		esac
		;;

	'S')	# synchronize
		SYNCHRONIZE=1
		;;

	'h')	# help menu
		PrintUsage
    tput sgr0
		exit $SUCCESS
		;;

	?)	# unknown option
		PrintMsg 3 "$RED[3][getopts] Test   : Option Checking"
	 	PrintMsg 3 "$RED   [getopts] Result : Option is not valid"
		PrintUsage
    tput sgr0
		exit $ERROR_INVALID_OPTION
	esac
done


############################# MAIN  ###############################
ret=0

# set shell color background (grey)
tput setaf 0 

# timer initialization
start_time=$(date +%s.%N)

# check DIRPATH_SRC and DIRPATH_DST
CheckInitSrcDestVar

# analysis mode
if [ $ANALYSIS_MODE -eq 1 ]
then
	RecursiveDiff $DIRPATH_SRC $DIRPATH_DST
  PrintMsg 0 "$CYAN # ======================================================== #"
  PrintMsg 0 "$CYAN #                          MyDiff                          #"
  PrintMsg 0 "$CYAN # ======================================================== #\n"
  PrintMsg 0 "$CYAN Mode         : Récursif"
 	ret=$?
else
	IterativeDiff $DIRPATH_SRC $DIRPATH_DST
  PrintMsg 0 "$CYAN # ======================================================= #"
  PrintMsg 0 "$CYAN #                          MyDiff                         #"
  PrintMsg 0 "$CYAN # ======================================================= #\n"
  PrintMsg 0 "$CYAN Mode         : Itératif"
fi

# calculate elapsed time
end_time=$(date +%s.%N)
PrintMsg 0 "$CYAN Elapsed time : $( echo $end_time - $start_time | bc ) seconds\n"

# reset the default color of the terminal
tput sgr0

exit $ret
