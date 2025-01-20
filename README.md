# Script for FreeNAS/TrueNAS Core & Scale

# NOTE: Versions 3.1 and 3.11 failed during updates.  Use veriosn 3.12.

New in Version 3.12

This script will perform four main functions:
1) Generate a report and send an email on your drive(s) status. 
2) Create a copy of your TrueNAS Config File and attach to the same email. 
3) Create a statistical database and attach to the same email.
4) Test the drives on a routine basis.

In version 3.1 I have removed drive testing from the Multi-report script
and move testing into it's own script.  This makes it easy to remove
when TrueNAS fully supports NVMe SMART testing, and makes it easier
for me up modify/update.

The new drive testing script is called "Drive-Selftest".  It was designed
to schedule both Short and Long drive test scheduling without much effort
form the end user.  This will prove to be very valuable if you have a
large quantity of drives in your system.

Other functions include Updates Notification and is highly customizable.
A User Guide exists (needs a bit of updating).
