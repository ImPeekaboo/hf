#!/bin/bash

source="anime:other/emoechi"
dest="anime:encoding/x265"
webhooks="https://discord.com/api/webhooks/1120796600676130816/1KJlFD2SFGrAKB2sA9E07nSa5IhGvofZJGvUb_-BF7N1AUXXBJpy6KSw4k7njZNAm0Wv"

clean_lines() {
    echo "$1" | awk '{$1=""; print $0}' | sed 's/^ *//'
}

ls_source=$(rclone ls --config /app/rclone.conf --exclude /temp/** "$source")
ls_dest=$(rclone ls --config /app/rclone.conf "$dest")

clean_ls_source=$(clean_lines "$ls_source")
clean_ls_dest=$(clean_lines "$ls_dest")
remaining=$(echo "$clean_ls_source" | grep -v -F -x -f <(echo "$clean_ls_dest"))

total=$(echo "$remaining" | wc -l)
counter=1

mkdir -p original result
echo "start encoding $total files!"
echo ""

echo "$remaining" | while IFS= read -r filepath; do

    filename=$(basename "$filepath")
    pathonly=$(dirname "$filepath")
    sourcepath="$source/$filepath"
    destpath="$dest/$pathonly"

    rclone copy -v --config /app/rclone.conf --stats 15 --stats-one-line "$sourcepath" original

    if [[ "$filename" == *.mp4 || "$filename" == *.mkv ]]; then
        ffmpeg -hide_banner -nostats -nostdin -i "original/$filename" -c:v libx265 -c:a copy "result/$filename"
        rm "original/$filename"
    else
        mv "original/$filename" "result"
    fi

    rclone copy -v --config /app/rclone.conf --stats 15 --stats-one-line "result/$filename" "$destpath"
    rm "result/$filename"

    curl -H "Content-Type: application/json" -X POST -d "{\"content\":\"### ${counter} of ${total} success!\n>>> \`📄 file: ${filename}\`\n\`📁 path: ${pathonly}\`\n<@253478920626634752>\"}" "$webhooks"

    echo "$counter of $total tasks done!"
    echo ""
    counter=$((counter + 1))

done