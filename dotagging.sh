#!/bin/bash

COLOR_RED=$'\e[01;31m'
COLOR_BLUE=$'\e[01;34m'
COLOR_GREEN=$'\e[01;32m'
COLOR_YELLOW=$'\e[01;33m'
COLOR_RESET=$'\e[0m'

input="$1"

if [ ! -f "$input" ]; then
    echo -e "${COLOR_RED}Please specify audio file as parameter${COLOR_RESET}"
    exit
fi

extension=${1##*.}

case $extension in
    mp3|m4a|flac|wav)
        type=format_tags
        ;;
    ogg)
        type=stream_tags
	metalocation=:s:a:0
        ;;
    *)
    echo "type not supported"
esac

titleisfilename="$2"
artist="$3"
album="$4"
date="$5"
genre="$6"
track="$7"

## -- FFPROBE (read existing tags) -- ##

source gettags.sh "$1"

## -- end FFPROBE -- ##


## -- Check for track number in filename -- ##

str[0]="$input"
patt='([[:digit:]]+)'
for s in "${str[@]}"
do
[[ $s =~ ^$patt ]]
digits=${BASH_REMATCH[1]}
done
if [ "$digits" ]
then
   trackfromfilename="$digits"
   [[ $s =~ $digits(.*) ]]
   filename="${BASH_REMATCH[1]}"
else
   filename="$input"
fi
if [[ $filename == .* ]] #remove dot at start
then
   filename=${filename:1}
fi

## -- end check -- ##


skip=true

filename=$(basename -- "$filename")
filename="${filename%.*}"

function usebackup {
   if [ "$trackbak" ]
   then    #if it has a value show it
      echo "track  = ${COLOR_BLUE}\"${trackbak}\"${COLOR_RESET}" #(unchanged)"
      track="${trackbak}"
   fi
}

if [ "$track" ]
then
   if [ "$track" = "y" ]
   then
      if [ -z "${trackfromfilename}" ]
      then
         echo "${COLOR_RED}filename does not start with number${COLOR_RESET}"
         usebackup
      else
         echo "track  = ${COLOR_GREEN}\"${trackfromfilename}\"${COLOR_RESET}" # (same as filename)"
         track="${trackfromfilename}"
      fi
   elif [ "$track" = "del" ]
   then
      echo "${COLOR_GREEN}track tag deleted${COLOR_RESET}"
      track=""
   else
      case $track in
    	''|*[!0-9]*)
           echo "${COLOR_RED}not a number${COLOR_RESET}"
           usebackup
           ;;
    	*)
           track="${track}"
           echo "track  = ${COLOR_GREEN}\"${track}\"${COLOR_RESET}" # use whatever else was entered as long as its a number
           ;;
      esac
   fi
   skip=false
else       # if nothing entered then keep existing value
   usebackup
fi



## -- TITLE -- ##

titleisfilename=${titleisfilename//'\'/}
if [ "$titleisfilename" = "y" ]
then
echo "title  = ${COLOR_GREEN}\"${filename}\"${COLOR_RESET}" # (same as filename)"
   title="${filename}"
skip=false
elif [ "$titleisfilename" = "del" ]
then
   echo "${COLOR_GREEN}title tag deleted${COLOR_RESET}"
   title=""
skip=false
elif [ -z "$titleisfilename" ]
then #user just presses ENTER
   if [ "$titlebak" ]
   then
      echo "title  = ${COLOR_BLUE}\"${titlebak}\"${COLOR_RESET}" #(unchanged)"
      title="${titlebak}"
   fi
else #use new title
   echo "title  = ${COLOR_GREEN}\"${titleisfilename}\"${COLOR_RESET}"
   title="${titleisfilename}"
skip=false
fi

## -- end TITLE -- ##


## -- ARTIST -- ##

if [ "$artist" ]
then
   if [ "$artist" = "del" ]
   then
      echo "${COLOR_GREEN}artist tag deleted${COLOR_RESET}"
      artist=""
   else
      echo "artist = ${COLOR_GREEN}\"${artist}\"${COLOR_RESET}"
      artist="${artist}"
   fi
   skip=false
else
   if [ "$artistbak" ]
   then
      echo "artist = ${COLOR_BLUE}\"${artistbak}\"${COLOR_RESET}" #(unchanged)"
      artist="${artistbak}"
   fi
fi

## -- end ARTIST -- ##


## -- ALBUM -- ##

if [ "$album" ]
then
   if [ "$album" = "y" ]
   then
      echo "album  = ${COLOR_GREEN}\"${filename}\"${COLOR_RESET}" # (same as filename)"
      album="${filename}"
   elif [ "$album" = "del" ]
   then
      echo "${COLOR_GREEN}album tag deleted${COLOR_RESET}"
      album=""
   else
      echo "album  = ${COLOR_GREEN}\"${album}\"${COLOR_RESET}"
      album="${album}"
   fi
   skip=false
else       #if nothing entered then keep existing value
   if [ "$albumbak" ]
   then    #if it has a value show it
      echo "album  = ${COLOR_BLUE}\"${albumbak}\"${COLOR_RESET}" #(unchanged)"
      album="${albumbak}"
   fi
fi

## -- end ALBUM == ##


## -- DATE -- ##

if [ "$date" ]
then
   if [ "$date" = "del" ]
   then
      echo "${COLOR_GREEN}date tag deleted${COLOR_RESET}"
      date=""
   else
      echo "date   = ${COLOR_GREEN}\"${date}\"${COLOR_RESET}"
      date="${date}"
   fi
   skip=false
else
   if [ "$datebak" ]
   then
      echo "date   = ${COLOR_BLUE}\"${datebak}\"${COLOR_RESET}" #(unchanged)"
      date="${datebak}"
   fi
fi

## -- end DATE -- ##



## -- GENRE -- ##

if [ "$genre" ]
then
   if [ "$genre" = "del" ]
   then
      echo "${COLOR_GREEN}genre tag deleted${COLOR_RESET}"
      genre=""
   else
      echo "genre  = ${COLOR_GREEN}\"${genre}\"${COLOR_RESET}"
      genre="${genre}"
   fi
   skip=false
else
   if [ "$genrebak" ]
   then
      echo "genre  = ${COLOR_BLUE}\"${genrebak}\"${COLOR_RESET}" #(unchanged)"
      genre="${genrebak}"
   fi
fi

## -- end GENRE -- ##

echo -e "\n"

## -- FFMPEG -- ##

codec="-c:a copy"

out="tempaudiofile.$extension"

if [ "$skip" = false ]
then
   titleargs=" -metadata${metalocation} TITLE="
   albumargs=" -metadata${metalocation} ALBUM="
   artistargs=" -metadata${metalocation} ARTIST="
   trackargs=" -metadata${metalocation} TRACK="
   genreargs=" -metadata${metalocation} GENRE="
   dateargs=" -metadata${metalocation} DATE="

   ffmpeg -hide_banner -loglevel panic -i "${input}" ${titleargs}"${title}" ${artistargs}"${artist}" ${albumargs}"${album}" ${trackargs}"${track}" ${dateargs}"${date}" ${genreargs}"${genre}"  ${codec} "${out}"

   RC=$?
   if [ "${RC}" -ne "0" ]
   then
      echo -e "${COLOR_RED} --Bad file!--${COLOR_RESET}\n\n"
      exit
   fi

   while [ ! -f "$out" ]
     do
     printf "."
     sleep 1
   done

   rm "$input"
   mv "$out" "$input"
fi

## -- end FFMPEG -- ##

exit
