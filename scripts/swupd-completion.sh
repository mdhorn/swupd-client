#!/bin/bash
#
#   Software Updater - autocompletion script
#
#      Copyright © 2016 Intel Corporation.
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, version 2 or later of the License.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#   This program creates a _swupd function to be used by completion built-in
#   bash command to complete swup.
#   It reads options and subcommands from swup --help and then it reads
#   options for each subcommand recursively.


SCRIPTNAME="swupd.bash"
COMPLETIONFUNCTION="_swupd"
SWUPDCOMMAND="./swupd"

optionsfromhelp=""
subcommandsfromhelp=()
optionsfromsubcommand=()

#Checks if swupd commad exists in current shell
if [ -e $SWUPDCOMMAND ] ; then
  currenttype=""
  nexttype=""
  array=()
  #reads "swupd --help" line by line
  while read line
  do
  #For each line checks in what section is
  if [[ $line == "Help Options:" ]]; then
    nexttype="options"
  fi
  if [[ $line == "Subcommands:" ]]; then
    nexttype="subcommand"
  fi
  if [[ $line == "" ]]; then
    currenttype=""
  fi
  case $currenttype in
    #In case of subcommand it inserts first word of line in an array
    "subcommand" )
    array=( $line )
    subcommandsfromhelp+=(${array[0]}) ;;
    #In case of options it reads short and long options
    "options" )
    array=( $line )
    optionsfromhelp="${optionsfromhelp} ${array[0]%?} ${array[1]}" ;;
    #For the rest do nothing
    "" ) : ;;
  esac
  if [[ -n $nexttype ]]; then
    currenttype=$nexttype
    nexttype=""
  fi
  done < <($SWUPDCOMMAND --help)
else
  echo "Error: No swupd found"
  exit 1
fi

#Now it is time to read options for each subcommand
for i in "${subcommandsfromhelp[@]}"; do
  substring=""
  currenttype=""
  nexttype=""
  array=()
  #Reads "swupd subcommand --help" line by line
  while read line
  do
  # Check when is inside of help options to start read them
  if [[ $line == "Help Options:" || $line == "Application Options:" ]]; then
    nexttype="options"
  fi
  if [[ $line == "" ]]; then
    currenttype=""
  fi
  case $currenttype in
    #In options, reads both, short and long ways
    "options" )
    array=( $line )
    longopt=${array[1]}
    substring="${substring} ${array[0]%?} ${longopt%=*}" ;;
    #For anithing else do nothing
    "" ) : ;;
  esac
  if [[ -n $nexttype ]]; then
    currenttype=$nexttype
    nexttype=""
  fi
  done < <($SWUPDCOMMAND $i --help)
  #Options are added to an array
  optionsfromsubcommand+=("$substring")
done

#Autocomplete scrit creation
cat > $SCRIPTNAME << EOM
#!/bin/bash
#   Software Updater - autocompletion script
#
#      Copyright © 2016 Intel Corporation.
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, version 2 or later of the License.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#   WARNING: This is an autogenerated script

#declares the completion function
${COMPLETIONFUNCTION}()
{
  local cur prev opts index suboptions mainsubcommands
  local mainopts="$optionsfromhelp"
  COMPREPLY=()
  cur="\${COMP_WORDS[COMP_CWORD]}"
  prev="\${COMP_WORDS[COMP_CWORD-1]}"
  #Adding all options for subcommands in an array
  mainsubcommands+=("${subcommandsfromhelp[@]}")
  suboptions+=("\$mainopts")
EOM
  #This adds options for all subcommands
  for i in ${!optionsfromsubcommand[@]}; do
  echo -e "  suboptions+=(\"${optionsfromsubcommand[$i]}\")" >> $SCRIPTNAME
  echo -e "  mainsubcommands+=(\" \")" >> $SCRIPTNAME
  done

cat >> $SCRIPTNAME << EOM

  #Need to get last subcommand entered by the user
  index=COMP_CWORD-1
  while [[ " swupd \$mainsubcommands " != *" \$prev "* ]]; do
    ((index--))
    prev="\${COMP_WORDS[\$index]}"
  done
  #Now need to calculate the index of the subcommand in order to
  #retreive options
  index=0
  for subc in swupd \${mainsubcommands[0]}
  do
    if [[ \$subc == \$prev ]]; then
      break
    fi
    ((index++))
  done

  #Get all options for last subcommand entered
  opts="\${suboptions[\$index]} \${mainsubcommands[\$index]}"

  COMPREPLY=( \$(compgen -W "\${opts}" -- \${cur}) )

  return 0
}

complete -F ${COMPLETIONFUNCTION} swupd
EOM


