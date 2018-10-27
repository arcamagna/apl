#!/bin/bash

input="$1"

if [ ! -f "$input" ]; then
    echo "Please specify audio file as parameter"
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

## -- FFPROBE (read existing tags) -- ##

meta=$(ffprobe -v quiet -show_entries "$type"=title,artist,album,track,date,genre -hide_banner -of default=nw=1 "$1")

#echo $meta

if [ "${meta}" ]
then
   declare -A tags

   while read -r line
   do
      i="${line//'TAG:'/}"
      key=${i%%=*}
      key=${key^^}
      val=${i#*=}
      tags[$key]="$val"
   done <<< "$meta"

   albumbak=${tags[ALBUM]}
   artistbak=${tags[ARTIST]}
   titlebak=${tags[TITLE]}
   trackbak=${tags[TRACK]}
   genrebak=${tags[GENRE]}
   datebak=${tags[DATE]}
else
   echo no existing tags
fi

## -- end FFPROBE -- ##

#echo "$meta"

#exit
