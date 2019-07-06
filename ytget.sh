#!/bin/bash

# ytget - Copyright 2019, Brendon Matheson

# ytget is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License v2 as published by the Free
# Software Foundation.

# ytget is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

# You should have received a copy of the GNU General Public License along with
# ytget.  If not, see http://www.gnu.org/licenses/gpl-2.0.html

videoUrl=$1

# Generate unique key for this retrieve
key=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)

# Get the video's title
echo "Getting video title for $videoUrl"
title=$(youtube-dl --skip-download --get-title --no-warnings $videoUrl | sed 2d)
title=$(echo $title | sed -e "s/[\/'\"]/-/g")	# Make the title filename friendly
echo "Video title $title"

# Get the video stream info
echo "Getting stream info for $videoUrl"
youtube-dl -F $videoUrl > $key"_streams"

# Find the best audio stream
audioId=$(cat $key"_streams" | \
	grep -e "audio only" | \
	awk '{gsub("k", "", $7); print $7 " " $1 }' | \
	sort -n -r | \
	head -n 1 | \
	awk '{ print $2 }')

echo "Selected audio stream $audioId"

# Find the best video stream
videoId=$(cat $key"_streams" | \
	grep -e "video only" | \
	grep -v "vp9" | \
	awk '{gsub("k", "", $5); print $5 " " $1 }' | \
	sort -n -r | \
	head -n 1 | \
	awk '{ print $2 }')

echo "Selected video stream $videoId"

# Retrieve audio stream
echo "Retrieving audio stream"
youtube-dl -f $audioId $videoUrl -o $key"_audio"

# Retrieve video stream
echo "Retrieving video stream"
youtube-dl -f $videoId $videoUrl -o $key"_video"

# Encode to MP4
ffmpeg -i $key"_audio" -i $key"_video" -c:v copy -c:a aac -y "$title.mp4"

# Clean up temp files
rm $key"_streams"
rm $key"_audio"
rm $key"_video"

