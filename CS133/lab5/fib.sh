#!/bin/bash

function fib {
  fibNum=$1
  first=0
  sum1=1
  sum2=1
  sumCurrent=1

 if [[ $fibNum > 1 ]]
 then
   for (( i=0; i<$(($fibNum-1)); i++ ))
   do
     # sum1=$sumCurrent
     sumCurrent=$sum1
     sum1=$(($sum1+$sum2))
     sum2=$sumCurrent

     # echo $sumCurrent
   done
 elif [[ $fibNum == 0 ]]
 then
   sum2=0
 else
   sum2=1
 fi
}

function main {

  echo "What fib should I calculate?"
  read n
  fib $n
  echo $sum2
  exit 0

}

main
