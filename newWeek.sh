#!/usr/bin/env bash
function reFormatNum() {
  argLength=${#1}

  if [[ argLength -eq 1 ]]; then
    echo "0${1}"
  else
    echo $1
  fi
}

# Display help messages if help flag passed
if [[ $1 == "-h" ]] || [[ $1 == "--help" ]]; then
  echo "[Week Number]         week number for the desired new week materials"
  echo "[Start Activity]      starting activity to copy"
  echo "[End Activity]        ending activity to copy (inclusive)"
  echo "options:"
  echo "-h, --help            show brief help"
  echo "-c, --commit          commit the changes but do not push"
  echo "-p, --push            push new week and activities to dest origin"
  exit 0
fi

SHOULD_COMMIT=0
SHOULD_PUSH=0

# set SHOULD_COMMIT to 1 if commit flag passed
if [[ $1 == "-c" ]] || [[ $1 == "--commit" ]]; then
  SHOULD_COMMIT=1
  # pop the flag from the arguments list
  shift
fi

# set SHOULD_PUSH and SHOULD_COMMIT to 1 if push flag passed
if [[ $1 == "-p" ]] || [[ $1 == "--push" ]]; then
  SHOULD_PUSH=1
  SHOULD_COMMIT=1
  # pop the flag from the arguments list
  shift
fi

if [[ "$#" -lt 1 ]]; then
  echo "Usage: ./newWeek.sh [options] [Week Number] (Start Activity) (End Activity). Type -h or --help for more information."
else
  # load path vars $pathtoContent and $pathToStudentRepo
  DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
  source "${DIR}/.env"

  # clean and pull latest content from source
  cd $pathToContent
  git checkout .
  git clean -fd
  git pull

  cd $pathToStudentRepo

  weekNum=$(reFormatNum $1)

  newWeekDirName=$(echo ${pathToContent}/01*/${weekNum}* | sed -E 's/^[^0-9].*Content\/([0-9]+.*)/\1/')

  mkdir ${pathToStudentRepo}/${newWeekDirName}
  
  # if specified acitvity/-ies
  if [[ "$#" -gt 1 ]]; then
    mkdir ${pathToStudentRepo}/${newWeekDirName}/01-Activities

    if [[ "$#" -eq 2 ]]; then
      activityNum=$(reFormatNum $2)
      export MSYS_NO_PATHCONV=1
      rsync -r -av --progress --exclude='/*/.local' /cygdrive/${pathToContent}/01*/${weekNum}*/01*/${activityNum}* ${pathToStudentRepo}/${weekNum}*/01* --exclude Solved --exclude Main> /dev/null
      unset MSYS_NO_PATHCONV

      activity=$(echo ${pathToContent}/01*/${weekNum}*/01*/${activityNum}* | sed -E 's/^[^0-9].*Activities\/([0-9]+.*)/\1/')
      destination=$(echo ${pathToStudentRepo}/${weekNum}*/01* | sed -E 's/^.*(UCD.*)/\1/')

      barLength=$((${#activity} + ${#destination} + 4))

      printf '%.0s-' $(seq 1 $barLength)
      printf '\n'
      printf "$activity -> $destination"
      printf '\n'
      printf '%.0s-' $(seq 1 $barLength)
      printf '\n\n'
    else
      for num in $(seq $2 $3); do
        activityNum=$(reFormatNum $num)
        export MSYS_NO_PATHCONV=1
        rsync -av --progress --exclude='/*/.local' /cygdrive/${pathToContent}/01*/${weekNum}*/01*/${activityNum}* ${pathToStudentRepo}/${weekNum}*/01* --exclude Solved --exclude Main > /dev/null
        unset MSYS_NO_PATHCONV

        activity=$(echo ${pathToContent}/01*/${weekNum}*/01*/${activityNum}* | sed -E 's/^[^0-9].*Activities\/([0-9]+.*)/\1/')
        destination=$(echo ${pathToStudentRepo}/${weekNum}*/01* | sed -E 's/^.*(UCD.*)/\1/')

        barLength=$((${#activity} + ${#destination} + 4))

        printf '%.0s-' $(seq 1 $barLength)
        printf '\n'
        printf "$activity -> $destination"
        printf '\n'
        printf '%.0s-' $(seq 1 $barLength)
        printf '\n\n'
      done
    fi
  fi  
  export MSYS_NO_PATHCONV=1
  rsync -av --progress --exclude='/*/.local' /cygdrive/${pathToContent}/01*/${weekNum}* ${pathToStudentRepo} --exclude 01-Activities --exclude Solved --exclude Main > /dev/null
  unset MSYS_NO_PATHCONV

  # commit if SHOULD_COMMIT
  if [[ $SHOULD_COMMIT -eq 1 ]]; then
    git add $1*
    if [[ "$#" -eq 1 ]]; then
      git commit -m "week $1" 
    elif [[ "$#" -eq 2 ]]; then
      git commit -m "week $1, activity $2" 
    else
      git commit -m "week $1, activities $2-$3"
    fi
  fi

  #  push if SHOULD_PUSH
  if [[ $SHOULD_PUSH -eq 1 ]] ; then
    git push
  fi
fi