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

# This listens for '-d' as an argument and prints debug information for diagnosing problems with the code.
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
    if [[ $(echo $i | cut -c 1) == "." ]]
    then
      debug "[HIDDEN FILE] $i"
      hiddenFileCount=$(($hiddenFileCount+1))
    else
      fileCount=$(($fileCount+1))
      debug "[FILE] $i"
    fi
  done
}

# Counts the directories and subdirectories in the directory passed as an argument.
function countDirectories {
  for i in $(ls $1 -Ap | grep /)
  do
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

  # Run recursively for directories:
  for i in $(ls $1 -Ap | grep /)
  do
    debug "[SEARCHING DIR] $i: Count($1-$i)"
    count $1$i
  done
}

# Running the main function.
count $baseDirectory

# Reporting the results to the stdout.
echo "Files found: $fileCount (plus $hiddenFileCount hidden)"
echo "Directories found: $dirCount (plus $hiddenDirCount hidden)"
echo "Total files and directories: $(($dirCount+$hiddenDirCount+$fileCount+$hiddenFileCount))"
