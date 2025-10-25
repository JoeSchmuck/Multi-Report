# Multi-Report and Drive-Selftest for TrueNAS 13+ Core/Scale

Bug-Fix Multi-Report Versions 3.21 to 3.24 and Drive-Selftest Version 1.07
  Yes, a few bugs of course.  Here is what changed for MR:
 - Added SMR Update to the -update_all switch.
 - Added -Check_For_Updates switch.
 - Added Check_For_Updates_Day_of_Week to minimize the number of times a software check occurs.
 - Fixed ReAllocEvent setting, now it works again.
 - Consolidation of multiple v3.22 small changes.
 - Fixed SMR-Check Version Number and removal of temporary smr file.
 - Updated to allow proper use of the truenas_sendmail_support="No" in the config file.
 - Fixed the hard-coding of the fonts, not hard coded now.
 - Fixed Capacity line in code (missing a semicolon).
 - Added Test Type in progress.
 - Fixed Text Section for Sendemail Message if forced to use Sendemail in Core.
 - Fixed the usage of TDR/TDW Column Titles
 - Ignore fdisk partition errors (Zvols) - Thanks to `toomuchdata`
 - Added another NVMe Self-test parameter check.
 - Cleaned up some descriptive verbiage.
 - Fixed "Test_ONLY_NVMe_Drives" in the multi_report_config.txt file.
 - Fixed corrupt statistical data file and added routine to purge the corrupt data.
 - Added recognition of `nvme_total_capacity` SMART value.

  Here is what changed in DS:
  - Optimized the API function.  The function was taking a long time for people with a large number of drives.  Optimizing improved performance by 1987.58% (8 minutes reduced to 24.15 seconds).
  - Fixed SCRUB and RESILVER Time Remaining Count.

==============================================================================

New in Multi-Report Version 3.20

  - Added Drive Location Data - For locating your drive by serial number and your noted location entry.
  - Added Font changing capability.
  - Added Override for drives with SMART DISABLED.
  - Made change to display the "REAL" error data for Seagate "Raw_Read_Rate" and "Seek_Error_Rate", no more manual number conversions.
  - Incorporated Drive-Selftest v1.06 changes into Multi-Report.
  - Updated clearing variables for invalid Media Errors.
  - Updated -dump to include new csv file from Drive-Selftest script.
  - Change to downloading "sendemail.py" vice "multireport_sendemail.py"


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

New in Drive-Selftest Version 1.06

 - Updated Silent to be more effective when enabled.
 - Changed RESILVER and SCRUB to limit SMART tests to only the pools affected.
 - Changed RESILVER and SCRUB to have a 'disable' option and let SMART tests run regardless of RESIVLER or SCRUB in progress.
 - Added drive testing tracking in CSV file.  This will ensure all drives are SMART LONG tested promptly if the script is not run everyday and a drive is missed.
 - Added a "Maximum_Catchup_Drive_Count" variable to limit how many additional drives can be LONG tested if they were missed.

Drive Self-test is a new script specifically to perform the SMART testing.
The SMART testing was removed from Multi-Report placed in this script.
This script has many benefits being a seperate script:
1) Easier to maintain.
2) Run standalone without Multi-Report.
3) Schedules both Short and Long tests to be accomplished Daily, Weekly, and/or Monthly.
4) Can schedule over 1000 drives to be tested (OMG!).
5) Able to test ONLY NVMe while TrueNAS is not able to schedule NVMe SMART tests in the GUI.
