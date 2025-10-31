#!/bin/sh

script=$(basename "$0")
dir_source_script=../scripts/$script

i=0

while [ "$i" -lt 3 ]
do
    [ -f "$dir_source_script" ] && break
    dir_source_script=../$dir_source_script
    i=$((i + 1))
done

if ! [ -f "$dir_source_script" ]
then
    printf "$script: cannot find \"%s\"\n" "$script"
    exit 1
fi

dir_source_script="$(cd "$(dirname "$dir_source_script")" && pwd)/$(basename "$dir_source_script")"
. "$dir_source_script"
