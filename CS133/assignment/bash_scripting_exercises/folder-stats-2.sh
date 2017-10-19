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

# Array which will hold size information about the files that are found.
declare -A files

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
  echo $fileSize
}

# Prints out debug information if global argument '-d' is found.
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

# Loop through file array and organize into new variable which holds filename and size.
for a in ${!files[@]}
do
  fileSizes=$fileSizes"\n$a: ${files[$a]}"
done

# Sort 5 biggest file sizes and corresponding names into variables.
fileNames=$(echo -e $fileSizes | sort -k 2 -gr | sed -n 1,5p | awk '{print $1}')
filesizeNoNames=$(echo -e $fileSizes | sort -k 2 -gr | sed -n 1,5p | awk '{print $2}')

# Save filesizes and filenames into text files to be read and printed out later.
echo -e "$fileNames" | column -t > fileNames.txt
echo -e "$filesizeNoNames" | column -t > fileSizes.txt

# Reading the text files
readarray -t fileNameArray < fileNames.txt
readarray -t fileSizeArray < fileSizes.txt

# Reporting biggest files to stdout.
echo "The biggest 5 files are:"

# Loopping through each of the files read from the txt files and formatting size while reporting to stdout.
i=0;
for item in "${fileNameArray[@]}"
do
  echo -e "   ${fileNameArray[$i]} $(formatSize ${fileSizeArray[$i]})"
  i=$(($i+1))
done
