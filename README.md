# Squid_Threat_Feeds

This is a Bash script designed to update and manage the Squid proxy server's bad URL list and bad IP address list from external sources. The script provides functions to update Squid's configuration files based on the latest data from abuse.ch feeds and Feodotracker IP blocklist.

## Features

- Updates Squid bad URL list from the URLhaus feed.
- Updates Squid bad IP address list from the Feodotracker feed.
- Automatically archives and renames the previous data files.
- Schedules updates using cron for convenience.

## Usage

1. Clone this repository:

```sh
git clone https://github.com/squid-security-update-script.git
```

2. Navigate to the repository's directory:
``` cd squid-security-update-script ```

- To set up Squid and its configuration:
  ```
  ./squid_security_update.sh run_setup
  ```
- To manually update Squid bad URLs and IPs:
  ```
  ./squid_security_update.sh run_tasks
  ```
- To run scheduled tasks (recommended):
    ```
  ./squid_security_update.sh schedule_tasks
  ```
```Note:```  Make sure to modify the script according to your system's paths and requirements before executing it.

##Configuration

Before running the script, ensure that the following are correctly configured:

    Paths to log files and archive folders.
    URLs for the bad URL and bad IP address data sources.
    Squid configuration file paths.

##Schedule Tasks

The script includes an option to schedule tasks using cron. This ensures that the bad URL and bad IP address lists are regularly updated. By default, tasks are scheduled to run every 3 hours. You can modify the cron schedule by editing the script.
