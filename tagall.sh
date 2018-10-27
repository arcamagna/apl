#!/bin/bash

COLOR_RED=$'\e[01;31m'
COLOR_BLUE=$'\e[01;34m'
COLOR_GREEN=$'\e[01;32m'
COLOR_YELLOW=$'\e[01;33m'
COLOR_RESET=$'\e[0m'

help='\n'
help+=$'Usage: '
help+=${COLOR_BLUE}
help+=$'tagall.sh '
help+=${COLOR_RESET}
help+=$'['
help+=${COLOR_BLUE}
help+=$'option'
help+=${COLOR_RESET}
help+=$']\n'
help+=$'\n'
help+=${COLOR_BLUE}
help+=$'option'
help+=${COLOR_RESET}
help+=$' is either the file format e.g. '
help+=${COLOR_BLUE}
help+=$'ogg'
help+=${COLOR_RESET}
help+=$' for batch processing\n'
help+=$'files of a particular type, or a file name if processing a\n'
help+=$'single audio file. (Or '
help+=${COLOR_BLUE}
help+='-h'
help+=${COLOR_RESET}
help+=$' / '
help+=${COLOR_BLUE}
help+='--help'
help+=${COLOR_RESET}
help+=' for help.)\n'
help+=$'When omitted all compatible audio files in the current\n'
help+=$'directory are processed.\n'
help+=$'\n'
help+=$'When batch processing all files will have the same album,\n'
help+=$'artist, date and genre tags. Track and title can be derived\n'
help+=$'from the file name by entering '
help+=${COLOR_BLUE}
help+=$'y'
help+=${COLOR_RESET}
help+=$' when prompted.\n'
help+=$'(Track only works if the filename starts with a number.)\n'
help+=$'Alternatively press '
help+=${COLOR_BLUE}
help+=$'i'
help+=${COLOR_RESET}
help+=$' to enter track and title information for\n'
help+=$'each file.\n'
help+=$'\n'
help+=$'Pressing '
help+=${COLOR_BLUE}
help+=$'ENTER'
help+=${COLOR_RESET}
help+=$' whenever prompted will skip ahead retaining\n'
help+=$'current tag if one exists.\n'
help+=$'\n'
help+=$'Enter '
help+=${COLOR_BLUE}
help+=$'del'
help+=${COLOR_RESET}
help+=$' to delete current tag.\n'

declare -a formats

multiple=true

if [ "$1" ]
then
   if [ "$1" = "--help" ] || [ "$1" = "-h" ]
   then
   echo -e "$help"
   exit
   elif [ -f "$1" ]
   then
      formats="${1##*.}" # use file extension for format if single file specified
      files="$1"
      multiple=false
   else
      formats="$1"
   fi
else
   formats=(ogg flac mp3 m4a aac)
fi

declare -a files

if [ "$multiple" = true ]
then
for i in *
do
   ext=${i##*.}
   if [[ "${formats[@]}" =~ "${ext}" ]]
   then
      files+=("$i")
   fi
done
fi

if [ ${#files[@]} == 0 ]
then
   echo "${COLOR_YELLOW}no files to process${COLOR_RESET}"
exit
fi

source gettags.sh "${files[0]}"

skip=true

function gettrack() {
   if [ "$multiple" = true ]
   then
      echo "track number from filename? (y or ENTER/i/track/del)"
   else
      echo "track number from filename? (y or ENTER/track/del)"
   fi
   if [ "${trackbak}" ]
   then
      if [ "$multiple" = true ]
      then
         echo "${COLOR_BLUE}(multiple files)${COLOR_RESET}"
      else
         echo "${COLOR_BLUE}\""${trackbak}"\"${COLOR_RESET}"
      fi
   else
      if [ -z $1 ]
      then
         echo "${COLOR_YELLOW}track tag not set${COLOR_RESET}"
      fi
   fi
   read track
   if [ -z "$track" ] # user presses ENTER
   then
      track=""
   else
      case $track in
         i|del|y)
            skip=false
            ;;
         *[!0-9]*)
            echo "${COLOR_RED}please enter y, del or a number or ENTER to skip${COLOR_RESET}"
            gettrack true
            ;;
         *)
            if [ $multiple = true ]
            then
               echo "${COLOR_RED}all files will be track $track - are you sure? (y/n)${COLOR_RESET}"
               read sametrack
               if [ $sametrack = "n" ]
               then
                 gettrack true
               fi
            fi
            skip=false
            ;;
      esac
   fi
}

gettrack

if [ "$multiple" = true ]
then
echo "title is filename? (y or ENTER/i/title/del)"
else
echo "title is filename? (y or ENTER/title/del)"
fi
if [ "${titlebak}" ]
then
   if [ "$multiple" = true ]
   then
      echo "${COLOR_BLUE}(multiple files)${COLOR_RESET}"
   else
      echo "${COLOR_BLUE}\""${titlebak}"\"${COLOR_RESET}"
   fi
else
   echo "${COLOR_YELLOW}title tag not set${COLOR_RESET}"
fi
read title
if [ -z "$title" ]
then
   title=""
else
   skip=false
fi

echo "artist? (or ENTER/del)"
if [ "${artistbak}" ]
then
   echo "${COLOR_BLUE}\""${artistbak}"\"${COLOR_RESET}"
else
   echo "${COLOR_YELLOW}artist tag not set${COLOR_RESET}"
fi
read artist
if [ -z "$artist" ]
then
   artist=""
else
   skip=false
fi

echo "album is filename? (y or ENTER/album/del)"
if [ "${albumbak}" ]
then
   echo "${COLOR_BLUE}\""${albumbak}"\"${COLOR_RESET}"
else
   echo "${COLOR_YELLOW}album tag not set${COLOR_RESET}"
fi
read album
if [ -z "$album" ]
then
   album=""
else
   skip=false
fi

echo "year? (or ENTER/del)"
if [ "${datebak}" ]
then
   echo "${COLOR_BLUE}\""${datebak}"\"${COLOR_RESET}"
else
   echo "${COLOR_YELLOW}date tag not set${COLOR_RESET}"
fi
read date
if [ -z "$date" ]
then
   date=""
else
   skip=false
fi

echo "genre? (or ENTER/del)"
if [ "${genrebak}" ]
then
   echo "${COLOR_BLUE}\""${genrebak}"\"${COLOR_RESET}"
else
   echo "${COLOR_YELLOW}genre tag not set${COLOR_RESET}"
fi
read genre
if [ -z "$genre" ]
then
   genre=""
else
   skip=false
fi

function tag {
   /usr/local/bin/dotagging.sh "$1" "$thetitle" "$artist" "$album" "$date" "$genre" "$thetrack"
}

if [ $skip = false ]
then
for i in "${files[@]}"
do
   if [ "$track" = "i" ]
   then
   echo "enter track number for $i"
   read thetrack
   else
   thetrack="$track"
   fi
   if [ "$title" = "i" ]
   then
   echo "enter title for $i"
   read thetitle
   else
   thetitle="$title"
   fi
   tag "$i"
done
else
   echo "${COLOR_BLUE}-- Nothing to do --${COLOR_RESET}"
fi

exit
