#!/bin/bash

# Function to display an error dialog
show_error_dialog() {
    zenity --error --title="Error" --text="$1" --width=300
}

# Function to display an info dialog
show_info_dialog() {
    zenity --info --title="Information" --text="$1" --width=300
}

# Function to ask the user whether to follow redirects
ask_follow_redirect() {
    zenity --question --title="Redirect" --text="The URL has been redirected. Do you want to follow the redirect?"
    return $?
}

# Function to show a file save dialog and get the output file path
get_output_file() {
    zenity --file-selection --save --confirm-overwrite --title="Save Output File" --filename="output.txt"
}

# Function to curl the URL and extract indexes
extract_indexes() {
    local url="$1"
    curl_output=$(curl -sS -L "$url") || show_error_dialog "Failed to fetch URL: $url"
    indexes=$(echo "$curl_output" | grep -oP 'href="\K[^"]*(?=")')
}

# Main function
main() {
    # Get URL from user
    url=$(zenity --entry --text="Enter the URL:" --title="URL Input")
    [[ -z "$url" ]] && exit 1  # Exit if URL is empty

    # Extract indexes
    extract_indexes "$url"

    # Ask the user whether to follow redirects if redirected
    if echo "$curl_output" | grep -q 'HTTP/[0-9]+\.[0-9]+ [0-9]\+ Redirect'; then
        ask_follow_redirect
        follow_redirect=$?
        if [ $follow_redirect -eq 0 ]; then
            show_info_dialog "Following redirect..."
            # Extract indexes again after following the redirect
            extract_indexes "$url"
        else
            show_error_dialog "Redirect not followed. Output may not be complete."
        fi
    fi

    # Get the output file path
    output_file=$(get_output_file)
    if [ -n "$output_file" ]; then
        # Save positive finds to output file
        echo -e "Positive finds from $url:\n$indexes" > "$output_file"
        show_info_dialog "Indexes saved to $output_file"
    fi
}

# Run the main function
main
