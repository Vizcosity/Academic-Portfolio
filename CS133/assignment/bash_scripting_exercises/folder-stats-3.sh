#!/bin/bash

# This will be the starting directory from which the script will measure all the sub-dirs etc.
baseDirectory=$1

# Global variable assigned to the arguments used for the debugging function.
globalArg=$@

# The global variables below will be used to count the number of files and directories (hidden or not),
# which will be reported at the end of the script.
hiddenFileCount=0
fileCount=0
hiddenDirCount=0
dirCount=0

declare -A files

# Associative array which will hold permissions information about each file and directory that is discovered.
declare -A permissions

# Validates input to ensure that the argument is a valid, accessible directory and appends a '/' at the end if required.
function validateArguments {
  if [[ "${1: -1}" != "/" ]]
  then
    baseDirectory="$1/"
    validateArguments $baseDirectory
  fi
  item=$(ls $1 -alFp | sed -n 2,1p | awk '{print $1}')
  if [[ "${item:0:1}" != "d"  ]]
  then
    echo "Invalid input. Argument must be a valid, accessible directory. Entered: $1"
    echo $item
    exit 1
  fi
}

# Running the input validation.
validateArguments $1

# Grabs size information about files that are passed as arguments.
function formattedSize {
  fileSize=$(ls -AhlpS $1 | awk '{print $5}')
  debug "[FILESIZE] $1: $fileSize"
  echo $fileSize
}

# Recieves filesize in bytes and formats in more human-readable format.
function formatSize {
  # echo $1
  if (( $1 > 1073741824 ))
  then
    size=$(($1/1073741824))GB
    echo $size
  elif (( $1 > 1048576 ))
  then
    size=$(($1/1048576))MB
    echo $size
  elif (( $1 > 1024 ))
  then
    size=$(($1/1024))KB
    echo $size
  else
    size=$1Bytes
    echo $size
  fi
}

# Grabs the size in bytes of files passed as arguments.
function sizeBytes {
  fileSize=$(ls -AlpS $1 | awk '{print $5}')
  debug "[FILESIZE] $1: $fileSize"
  # fileSize=$(formatSize $fileSize)
  echo $fileSize
}

# Recieves filepaths passed in as arguments and grabs the permissions string for file.
function getPermissions {
  perm=$(ls -l $1 | awk '{print $1}' | sed -n 1,1p)
  # echo "Getting Permissions for $1: $perm"
  echo $perm
}

# Recieves directory path as argument and grabs permissions string for directory.
function getPermissionsDir {
  perm=$(ls -al $1 | awk '{print $1}' | sed -n 2,1p)
  echo $perm
}

# Checks the permissions for directories.
function checkPermissionsDir {
  dirName=$1
  dirPerms=$2

  # echo "PermDirCheck: $1"

  if [[ $2 != "drwxr-xr-x" ]]
  then
    echo "$1 has the wrong permissions: $(getPermissionsDir $1)"
    chmod 755 $1
    echo "Permissions changed to: $(getPermissionsDir $1)"
  fi

}

# Checks permissions are correct for files.
function checkPermissions {
  sourceFile=$1
  # echo "Last 2 : ${sourceFile:${#sourceFile}-2}"
  if [[ ${sourceFile:${#sourceFile}-4} == java && $(getPermissions $1) != "-rwxr-xr-x" ]]
  then
    echo "$1 has the wrong permissions: $(getPermissions $1)"
    chmod 755 $1
    echo "Permissions changed to: $(getPermissions $1)"
  elif [[ ${sourceFile:${#sourceFile}-2} == sh && $(getPermissions $1) != "-rwxr-xr-x" ]]
  then
    echo "$1 has the wrong permissions: $(getPermissions $1)"
    chmod 755 $1
    echo "Permissions changed to: $(getPermissions $1)"
  elif [[ ${sourceFile:${#sourceFile}-4} != java && ${sourceFile:${#sourceFile}-2} != sh ]]
  then
    echo "$1 has the wrong permissions: $(getPermissions $1)"
    chmod 644 $1
    echo "Permissions changed to: $(getPermissions $1)"
  fi
}

# Debugging function which listens for '-d' as global argument and prints out debugging information.
function debug {
  for a in $globalArg
  do
    # echo "CHECK $a"
    if [[ $a == "-d" ]]
    then
      echo $1
    fi
  done
}

# Counts the files in a directory passed as an argument.
function countFiles {
  for i in $(ls $1 -Ap | grep -v /)
  do
    if [ "$i" != "fileNames.txt" ] || [ "$i" != "fileSizes.txt" ]
    then
      # echo "Getting Premissions for $1$i"
      permissions[$1$i]=$(getPermissions $1$i)
      files[$i]=$(sizeBytes $1$i)
      if [[ $(echo $i | cut -c 1) == "." ]]
      then
        debug "[HIDDEN FILE] $i"
        hiddenFileCount=$(($hiddenFileCount+1))
      else
        fileCount=$(($fileCount+1))
        debug "[FILE] $i"
      fi
    fi
  done
}

# Counts the directories and subdirectories in the directory passed as an argument.
function countDirectories {
  for i in $(ls $1 -Ap | grep /)
  do
    permissions[$1$i]=$(getPermissionsDir $1$i)
    if [[ $(echo $i | cut -c 1) == "." ]]
    then
      debug "[HIDDEN DIR] $i"
      hiddenDirCount=$(($hiddenDirCount+1))
    else
      debug "[DIR] $i"
      dirCount=$(($dirCount+1))
    fi
  done
}

# The main counting function which passes directories to countfiles and countdirectories functions and allows for a recursive
# search through all of the subsequent subdirectories
function count {
  countDirectories $1
  countFiles $1

  # Run recursively for directories and subdirectories within the baseDirectory which is passed into this function:
  for i in $(ls $1 -Ap | grep /)
  do
    debug "[SEARCHING DIR] $i: Count($1-$i)" # Debugging purposes.
    count $1$i # Previous directories appended to current directory with $1$i
  done
}

# Running the main function.
count $baseDirectory

# Reporting the results to the stdout.
echo "Files found: $fileCount (plus $hiddenFileCount hidden)"
echo "Directories found: $dirCount (plus $hiddenDirCount hidden)"
echo "Total files and directories: $(($dirCount+$hiddenDirCount+$fileCount+$hiddenFileCount))"

# Handling permissions
function permissionHandler {
  permissions=$1
  for a in ${!permissions[@]}
  do

    permissionsList+="\n$a: ${permissions[$a]}" # Formatting string for output.
    currentItemPerms=${permissions[$a]}
    currentItemPath=$a

    if [[ "${currentItemPerms:0:1}" == "d" ]]
    then
      # echo "$a is a directory."
      checkPermissionsDir $a ${permissions[$a]}

      # Update the permissions listing for this item
      permissions[$a]=$(getPermissionsDir $a)
    fi

    if [[ "${currentItemPerms:0:1}" == "-" ]]
    then
      debug "$a is a file."
      # echo -e "Checking permissions for File: $currentItemName \nPerms:$currentItem\nCurrentItem:$currentItem"
      checkPermissions $currentItemPath $currentItemPerms

      # Update the permissions listing for this item
      permissions[$currentItemPath]=$(getPermissions $currentItemPath)
    fi

  done
}

# Running permission handler.
permissionHandler $permissions

# Reporting permissions for basedirectory to stdout.
echo "Permissions for $1: $(getPermissionsDir $1)"

# Formatting permissions for output.
for a in ${!permissions[@]}
do
  formattedPermissionsOutput+="\n$a: ${permissions[$a]}"
done

# Reporting all permissions info to output.
echo -e "$formattedPermissionsOutput" | column -t
