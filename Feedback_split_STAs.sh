#!/bin/bash

<<com
This script extracts the MU-MIMO feedbacks of the available stations
from the raw pcap captures.

Copyright (C) 2022  Khandaker Foysal Haque
email: haque.k@northeastern.edu

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <https://www.gnu.org/licenses/>.
com

stations=("9C" "25" "89")
rooms=("Classroom" "Kitchen" "Livingroom")
beamf_labels=("A" "B" "C" "D" "E" "F" "G" "H" "I" "J" "K" "L" "M" "N" "O" "P" "Q" "R" "S" "T" "U")

for FOLDERNAME in Data
do
    cd "$FOLDERNAME"
    cd "$1"

    # Ensure the 'Processed' directory and its subdirectories exist
    if [ ! -d 'Processed' ]; then
        mkdir 'Processed'
    fi

    for ROOM in "${rooms[@]}"; do
        if [ ! -d "Processed/$ROOM" ]; then
            mkdir "Processed/$ROOM"
        fi

        # Ensure directories for stations exist within each room
        for STATION in "${stations[@]}"; do
            base_path="Processed/$ROOM/$STATION"
            if [ ! -d "$base_path" ]; then
                mkdir -p "$base_path"
            fi

            # Create subdirectories inside each station's folder
            subdirs=("beamf_angles" "exclusive_beamf_report" "time_vector" "vtilde_matrices" "FeedBack_Pcap")
            for DIR in "${subdirs[@]}"; do
                if [ ! -d "$base_path/$DIR" ]; then
                    mkdir -p "$base_path/$DIR"
                fi
            done

            # Create beamf_angles subdirectories
            for LABEL in "${beamf_labels[@]}"; do
                if [ ! -d "$base_path/beamf_angles/$LABEL" ]; then
                    mkdir -p "$base_path/beamf_angles/$LABEL"
                fi
                if [ ! -d "$base_path/beamf_angles/${LABEL}_batch" ]; then
                    mkdir -p "$base_path/beamf_angles/${LABEL}_batch"
                fi
            done
        done
    done

    # Process pcap files
    cd Raw

    for ROOM in "${rooms[@]}"; do
        # Ensure the room directory exists in Raw
        if [ ! -d "$ROOM" ]; then
            echo "Room $ROOM does not exist in Raw, skipping."
            continue
        fi
        
        echo "moving into $ROOM dir"

        for SUBJECT in "$ROOM"/*; do
            # Check if it's a valid directory for a subject
            if [ -d "$SUBJECT" ]; then
                for FILENAME in "$SUBJECT"/*; do
                    echo "$FILENAME"
                    if [ -f "$FILENAME" ]; then
                        echo "Processing file: $FILENAME"

                        # Extract base filename for output
                        FILENAMEOUTBASE=$(basename "$FILENAME" .pcapng)
                        echo "$FILENAMEOUTBASE"
                    

                        for STATION in "${stations[@]}"; do
                            case $STATION in
                                "89")
                                    ADDR="CC:40:D0:57:EA:89"
                                    ;;
                                "9C")
                                    ADDR="B0:B9:8A:63:55:9C"
                                    ;;
                                "25")
                                    ADDR="38:94:ED:12:3C:25"
                                    ;;
                            esac

                            # Define output file path
                            FILENAMEOUT="../Processed/$ROOM/$STATION/FeedBack_Pcap/${FILENAMEOUTBASE}_${STATION}.pcapng"

                            # Create the output directory if it doesn't exist
                            mkdir -p "$(dirname "$FILENAMEOUT")"

                            # Run tshark command if output file doesn't exist
                            if [ ! -f "$FILENAMEOUT" ]; then
                                echo "Generating: $FILENAMEOUT"
                                tshark -r "$FILENAME" -Y "wlan.vht.mimo_control.feedbacktype==MU && wlan.addr==$ADDR" -w "$FILENAMEOUT"
                            fi
                        done
                    fi
                done
            fi
        done
    done

    cd ../..
done

