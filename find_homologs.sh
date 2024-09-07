#!/bin/bash
# Make sure there are at least two input arguments - the first should be the input file name and the second should be the output file name
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <query file> <input file> <output file>"
    exit 1
fi

# Rename the objects stored in our arguments to names that make sense
query_file=$1
input_file=$2
output_file=$3

# Make sure the output file is empty before adding contents
: > "$output_file"

# Create temporary files for the header and housing the BLAST output data for line counting
temp_header=$(mktemp)
temp_blastdata=$(mktemp)

# Assuming you have your data in a variable or file
tblastn -query "$1" -subject "$input_file" -task tblastn -outfmt "6 qseqid sseqid pident length qlen sstart send" | awk '{ if ($3 > 30 && ($4 / $5) * 100 > 90) print }' > "$temp_blastdata"

# Calculate column widths based on the content of $temp_blastdata
max_qseqid=$(awk -F'\t' '{print length($1)}' "$temp_blastdata" | sort -nr | head -n1)
max_sseqid=$(awk -F'\t' '{print length($2)}' "$temp_blastdata" | sort -nr | head -n1)
max_pident=$(awk -F'\t' '{print length($3)}' "$temp_blastdata" | sort -nr | head -n1)
max_length=$(awk -F'\t' '{print length($4)}' "$temp_blastdata" | sort -nr | head -n1)
max_qlen=$(awk -F'\t' '{print length($5)}' "$temp_blastdata" | sort -nr | head -n1)
max_sstart=$(awk -F'\t' '{print length($6)}' "$temp_blastdata" | sort -nr | head -n1)
max_send=$(awk -F'\t' '{print length($7)}' "$temp_blastdata" | sort -nr | head -n1)

# Write the header with dynamic widths
printf "%-${max_qseqid}s\t%-${max_sseqid}s\t%-${max_pident}s\t%-${max_length}s\t%-${max_qlen}s\t%-${max_sstart}s\t%-${max_send}s\n" "qseqid" "sseqid" "pident" "length" "qlen" "sstart" "send" > "$temp_header"

# If we have matches, add header and data to the output file
if [ -s "$temp_blastdata" ]; then
    # Add a blank line before the header and data
    printf "\n" >> "$output_file"
    cat "$temp_header" >> "$output_file"
    cat "$temp_blastdata" >> "$output_file"
    printf "\n" >> "$output_file"
fi

# Output the number of matching sequences to stdout
wc -l < "$temp_blastdata"

# Remove temporary files
rm "$temp_header"
rm "$temp_blastdata"
