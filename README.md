# Multi-Report and Drive-Selftest for TrueNAS 13+ Core/Scale

Bug-Fix - Multi-Report version 3.32

# CHANGE LOG
# V3.32 (19 October 2026)
#
# - Maintenance Release
# - Updated to use the full file path for disklayout_config.json and the related .html files.
# - Fixed the Last Extended Test POH in the SMART Report Section.
# - Updated `dev_args` GREP command to fix reading sdaa, sdab... (Thanks Aleksey K.)
# - Fixed TLER not being set.
# - Changed the Disk Layout tracking to use pcie values, json file update to version "0.4".

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
