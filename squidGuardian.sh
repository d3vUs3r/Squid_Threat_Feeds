#!/bin/bash

# Function to update Squid bad URL list
update_squid_bad_urls() {
    echo "$(date +\%Y-\%m-\%d\ %H:\%M:\%S) Updating squid bad URLs..." >> logs/logfile.log
    local output_file="data/urlhaus_data.csv"
    local extracted_urls_file="extracted_urls.txt"
    local squid_bad_url_file="/etc/squid/bad_url.txt"
    local archive_folder="archive/"
    local temp_file="data/temp.csv"


    # Calculate the hash of the previously downloaded CSV data
    local previous_hash=$(sha256sum "$output_file" 2>/dev/null | cut -d ' ' -f 1)
    
    # Use curl to download the CSV data
    curl -o "$temp_file" "https://urlhaus.abuse.ch/downloads/csv_online/"

    
    # Calculate the hash of the newly downloaded CSV data
    local new_hash=$(sha256sum "$temp_file" | cut -d ' ' -f 1)
    
    # Check if the download was successful and if the data has changed
    if [ $? -eq 0 ]; then
        if [ "$new_hash" != "$previous_hash" ]; then
            echo "Data has changed. Extracting URLs and saving to $extracted_urls_file."

            # Move the previous output file to the archive folder and rename with date and time
            if [ -f "$output_file" ]; then
                archive_filename="$(basename "$output_file").$(date +\%Y-\%m-\%d_\%H-\%M-\%S)"
                mv "$output_file" "$archive_folder/$archive_filename"
                echo "Previous file moved to $archive_folder/$archive_filename."
            fi

            mv "$temp_file" "$output_file"
    
            # Extract URLs and save them to the extracted URLs file
            tail -n +12 "$output_file" | cut -d '"' -f 6 > "$extracted_urls_file"
    
            echo "Extracted URLs saved to $extracted_urls_file."
            
            # new part added to test


            # Replace content within the Squid bad URL section
            awk '/# BeginAbuseFeedBadURLs/ { print; p=1 } p && /# EndbuseFeedBadURLs/ { system("cat '"$extracted_urls_file"'"); p=0 } !p' "$squid_bad_url_file" > temp_file
            mv temp_file "$squid_bad_url_file"
            rm "$extracted_urls_file"
            echo "Extracted URLs added to the Squid bad URL section in $squid_bad_url_file."
        else
            echo "Data has not changed since the last check."
            rm -f "$temp_file"
        fi
    else
        echo "Error downloading the data."
    fi
}



# Function to update bad IP addresses from Feodotracker feed
update_IpFeed_Feodotracker() {
    echo "$(date +\%Y-\%m-\%d\ %H:\%M:\%S) Updating IpFeed Feodotracker..." >> /logs/logfile.log	
    local output_file="data/bad_ips_data.txt"
    local extracted_ips_file="extracted_ips.txt"
    local config_file="/etc/squid/bad_ips.txt"
    local archive_folder="archive/"
    local temp_file="data/temp.txt"


    # Calculate the hash of the previously downloaded text data
    local previous_hash=$(sha256sum "$output_file" 2>/dev/null | cut -d ' ' -f 1)

    # Use curl to download the text data
    curl -o "$temp_file" "https://feodotracker.abuse.ch/downloads/ipblocklist.txt"


    # Calculate the hash of the newly downloaded text data
    local new_hash=$(sha256sum "$temp_file" | cut -d ' ' -f 1)

    # Check if the download was successful and if the data has changed
    if [ $? -eq 0 ]; then
        if [ "$new_hash" != "$previous_hash" ]; then
            echo "Data has changed. Extracting IPs and saving to $extracted_ips_file."

            # Move the previous output file to the archive folder and rename with date and time
            if [ -f "$output_file" ]; then
                archive_filename="$(basename "$output_file").$(date +\%Y-\%m-\%d_\%H-\%M-\%S)"
                mv "$output_file" "$archive_folder/$archive_filename"
                echo "Previous file moved to $archive_folder/$archive_filename."
            fi

            mv "$temp_file" "$output_file"

            # Extract IPs and save them to the extracted IPs file
            grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' "$output_file" > "$extracted_ips_file"
            
            # Replace content within the Squid bad IPs section
	    awk -v extracted="$extracted_ips_file" '
    /^# BeginFeodotrackerBadIPs$/, /^# EndFeodotrackerBadIPs$/ {
        if ($0 == "# BeginFeodotrackerBadIPs") {
            print
            while ((getline ip < extracted) > 0) {
                print ip
            }
        }
        if ($0 == "# EndFeodotrackerBadIPs") {
            print
        }
        next
    }
    { print }
    ' "$config_file" > temp_config_file
	        mv temp_config_file "$config_file"
	        rm "$extracted_ips_file"
           echo "Extracted IP addresses are saved in $extracted_ips_file"
        else
            echo "Data has not changed since the last check."
            rm -f "$temp_file"
        fi
    else
        echo "Error downloading the data."
    fi
}

# Function to empty Feodotracker feed section
empty_IpFeed_Feodotracker_section() {
    local config_file="/etc/squid/bad_ips.txt"

    # Use awk to empty content within the Squid bad IPs section
    awk '
    /^# BeginFeodotrackerBadIPs$/, /^# EndFeodotrackerBadIPs$/ {
        if ($0 == "# BeginFeodotrackerBadIPs") {
            print
            while ((getline) > 0 && $0 != "# EndFeodotrackerBadIPs") {
                # Empty the lines between markers
            }
            print "# EndFeodotrackerBadIPs"
            next
        }
        if ($0 == "# EndFeodotrackerBadIPs") {
            print
        }
        next
    }
    { print }
    ' "$config_file" > temp_config_file
    mv temp_config_file "$config_file"

    echo "Content between markers emptied in $config_file"
}

empty_squid_bad_urls() {
    local squid_bad_url_file="/etc/squid/bad_url.txt"
    
    # Empty content within the Squid bad URL section
       #toDO
}

# Call the function to update Squid bad URLs


run_setup() {
    echo "$(date +\%Y-\%m-\%d\ %H:\%M:\%S) Running squid setup env" >> /path/to/your/logfile.log
    # Configuration lines to be added
    local config_line1="acl blocked_site dstdomain \"/etc/squid/bad_url.txt\""
    local config_line2="http_access deny blocked_site"
    local config_line3="acl block_ips dst \"/etc/squid/bad_ips.txt\""
    local config_line4="http_access deny block_ips"

    # Specify the files to be copied
    local file1="bad_ips.txt.template"
    local file2="bad_url.txt.template"

    # Check if Squid is installed
    if command -v squid; then
        echo "Squid is installed on this system."
    else
        echo "Squid is not installed on this system. Begin installing Squid..."
        # Install Squid here (use the appropriate package manager)
	# Install Squid on CentOS (Red Hat)
        if [ -f "/etc/redhat-release" ]; then
            sudo yum install -y squid
        fi

        # Install Squid on Debian (Ubuntu)
        if [ -f "/etc/debian_version" ]; then
            sudo apt-get update
            sudo apt-get install -y squid
        fi

        echo "Squid has been installed."

    fi

    # Check if the files exist in the Template folder
    if [ -f "Template/$file1" ] && [ -f "Template/$file2" ]; then
        # Copy the files to the current folder
        cp "Template/$file1" /etc/squid/bad_ips.txt
        cp "Template/$file2" /etc/squid/bad_url.txt
        echo "Files copied successfully."
    else
        echo "One or both files do not exist in the Template folder."
    fi

    if [ -f "/etc/squid/squid.conf" ]; then
        # Append configuration lines to the configuration file
	sudo sed -i "/http_access deny all/i $config_line1\n$config_line2\n\n$config_line3\n$config_line4\n\n" /etc/squid/squid.conf
        echo "Configuration lines added to /etc/squid/squid.conf"
        # Restart Squid for changes to take effect
        sudo systemctl restart squid
	 echo "Squid service is restart."
    else
        echo "Squid configuration file not found."
    fi
}

# Install cron if not already installed
install_cron() {
    if command -v cron >/dev/null; then
        echo "cron is already installed."
    else
        # Install cron on CentOS (Red Hat)
        if [ -f "/etc/redhat-release" ]; then
            sudo yum install -y cronie
        fi

        # Install cron on Debian (Ubuntu)
        if [ -f "/etc/debian_version" ]; then
            sudo apt-get update
            sudo apt-get install -y cron
        fi

        echo "cron has been installed."
    fi
}

# Schedule tasks using cron
schedule_tasks() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local script_path="$script_dir/$0"
    local cron_logfile="$script_dir/logs/logfile.log"
    
    echo "$(date +\%Y-\%m-\%d\ %H:\%M:\%S) Scheduling tasks using cron..." >> "$cron_logfile"
    # Add cron job to run the functions every day at a specific time (e.g., 2 AM)
    local cron_job="0 */3 * * * $script_path run_tasks >> $cron_logfile 2>&1"
    (crontab -l ; echo "$cron_job") | crontab -

    echo "Scheduled tasks have been added."
}

# Run scheduled tasks
run_tasks() {
    update_IpFeed_Feodotracker
    update_squid_bad_urls
    echo "Running the task."
}

# Main script using case statement
case "$1" in
    "run_tasks")
        run_tasks
        ;;
    "run_setup")
        run_setup
        ;;
    "schedule_tasks")
        install_cron
        schedule_tasks
        ;;
    *)
        echo "Usage: $0 {run_tasks|run_setup|schedule_tasks}"
        exit 1
        ;;
esac


