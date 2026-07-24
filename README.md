# Multi-Report and Drive-Selftest for TrueNAS 13+ Core/Scale

Bug-Fix - Multi-Report version 3.29

Bug-Fix - Drive-Selftest Version 1.09

--- View the Change Logs within the scripts for details.

==============================================================================

New in Multi-Report Version 3

This script will perform five main functions:
1) Generate a report and send an email on your drive(s) status. 
2) Create a copy of your TrueNAS Config File and attach to the same email. 
3) Create a statistical database and attach to the same email.
4) Test the drives on a routine basis.
5) Check drives for being SMR or Seagate Drive Flood SCAM by China.

In version 3.1 I have removed drive testing from the Multi-Report script
and move testing into it's own script.  This makes it easy to remove
when TrueNAS fully supports NVMe SMART testing, and makes it easier
for me up modify/update.

The new drive testing script is called "Drive-Selftest".  It was designed
to schedule both Short and Long drive test scheduling without much effort
form the end user.  This will prove to be very valuable if you have a
large quantity of drives in your system.

Other functions include Updates Notification and is highly customizable.
A User Guide exists (needs a bit of updating).

# Drive Self-test for TrueNAS

New in Drive-Selftest Version 1

Drive Self-test is a new script specifically to perform the SMART testing.
The SMART testing was removed from Multi-Report placed in this script.
This script has many benefits being a seperate script:
1) Easier to maintain.
2) Run standalone without Multi-Report.
3) Schedules both Short and Long tests to be accomplished Daily, Weekly, and/or Monthly.
4) Can schedule over 1000 drives to be tested (OMG!).
5) Able to test ONLY NVMe while TrueNAS is not able to schedule NVMe SMART tests in the GUI.

# Quick Start Guide

* If you don't already have one, create a dataset to store your scripts.  The remaining instructions will assume your pool is named `tank`, and the dataset is named `scripts`.
* At the shell, change into that directory: `cd /mnt/tank/scripts`
* Clone this repository: `git clone https://github.com/JoeSchmuck/Multi-Report`
* Change into the new directory: `cd Multi-Report`
* Run the script for the first time, to create a configuration file: `./multi_report.sh -config`  Answer the prompts as appropriate for your system.
* Run the script again: `./multi_report.sh`.  This will install other components including the drive test and mail-sending scripts, and run the first report.  It will likely take several minutes to run, and once it completes, the report will be emailed to you at the address you specified in the last step.
* Set up a cron job to run this script daily.  In the current version of TrueNAS SCALE/Community Edition 25.10, in the web GUI, to go System -> Advanced Settings, and click **Add** on the panel for Cron Jobs.  Enter whatever you like in the "Description" field.  For "Command," enter `cd /mnt/tank/scripts/Multi-Report && ./multi_report.sh`.  In "Run As User," select `root`.  "Schedule" will default to daily at midnight, but you can adjust it if you like.  This script is intended to be run daily, though.  Click **Save** when you're finished.
* Now, test that you've created the cron job correctly.  Click the kebab menu to the right of your newly-created cron job and select "Run now."  If it runs without errors, you're good to go.

## Next Steps
You now have Multi-Report installed and set to run daily, with a basic configuration.  You'll probably want to further customize the configuration, which is found in `multi_report_config.txt`; consult the [User Guide](Multi_Report_User_Guide.pdf) for more information about configuration options.

Your emailed reports include a section labeled **Drive Layout Visualization.**  To customize this to reflect your actual drive layout, visit [https://joeschmuck.github.io/Multi-Report_Hub/](https://joeschmuck.github.io/Multi-Report_Hub/).

# Support
Questions on the use or configuration of this script can be posted to the [Resource thread](https://forums.truenas.com/t/multi-report/1302) on the TrueNAS forum.  You can also raise issues against this repository.
