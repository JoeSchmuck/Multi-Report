#!/bin/bash
# Set the language to English so the date calulations work correctly with zpool status results.
LANG="en_US.UTF-8"

# With version 1.6c and above you may use an external configuration file.
# Use [-help] to read the Help Section.  For a short list of commands use [-h].
# Use [-config] to create a configuration file in the directory this script is run from.

###### ZPool & SMART status report with FreeNAS/TrueNAS config backup
### Original script by joeschmuck, modified by Bidelu0hm, then by melp (me)

### Version: v1.3 TrueNAS Scale (Jeff Alperin 12-6-21)

### Version v1.4, v1.5, v1.6 FreeNAS/TrueNAS (joeschmuck)

### Changelog:
# v1.6f (11 December 2022)
#   - Added custom build for snowlucas2022 and diedrichg.
#   - Adjusted the language to English for the Date calulations.
#   - Added customizable alarm setpoints for up to 24 drives.
#   -- This feature will allow for drives which do not fit the normal parameters.
#   -- and is not intended to individualize each drive, but you could if you wanted.
#   -- And this also will allow the removal of the three custom builds, after
#   -- the experimental phase.
#
#
# v1.6e (11 November 2022)
#   - Fixed gptid not showing in the text section for the cache drive (Scale only affected).
#   - Fixed Zpool "Pool Size" - Wasn't calculating correctly under certain circumstances.
#   - Added Toshiba MG07+ drive Helium value support.
#   - Added Alphabetizing Zpool Names and Device ID's.
#   - Added No HDD Chart Generation if no HDD's are identified (nice for SSD/NVMe Only Systems).
#   - Added Warranty Column to chart (by request and must have a value in the Drive_Warranty variable).
#   - Removed Update option in -config since the sript will automatically update now.
#   - Updated instructions for multiple email addresses.
#   - Updated instructions for "from:" address, some email servers will not accept the default
#   -- value and must be changed to the email address of the account sending the email.
#   - Added the No Text Section Option (enable_text) to remove the Text Section from the email output
#   -- and display the chart only, if the value is not "true".
#   - Added Phison Driven SSD attribute for correct Wear Level value.
#
#   NOTES: If there is an error such as the host aborts a drive test and an error occurs, the script may
#   report a script failure.  I do not desire to account for every possible drive error message.
#   If you take a look at your drive data, you may notice a problem.  Fix the problem and the
#   script should work normally.  If it still does not, then reach out for assistance.
#
#   The multi_report_config file will automatically update previous versions to add new features.
#
# v1.6d-2 (09 October 2022)
#   - Bug fix for NVMe power on hours.
#   --- Unfortunately as the script gets more complex it's very easy to induce a problem.  And since I do not have
#   --- a lot of different hardware, I need the users to contact me and tell me there is an issue so I can fix it.
#   --- It's unfortunate that I've have two bug fixes already but them's the breaks.
#   - Updated to support more drives Min/Max temps and display the non-existant value if nothing is obtained vice "0".
#   
#   The multi_report_config file is compatable with version back to v1.6d.
#
# v1.6d-1 (08 October 2022)
#   - Bug Fix for converting multiple numbers from Octal to Decimal.  The previous process worked "most" of the time
#   -- but we always aim for 100% working.
#   
#   The multi_report_config file is compatable with version back to v1.6d.
#
# v1.6d (05 October 2022)
#   - Thanks goes out to ChrisRJ for offering some great suggestions to enhance and optimize the script.
#   - Updated gptid text and help text areas (clarifying information)
#   - Updated the -dump parameter to -dump [all] and included non-SMART attachments.
#   - Added Automatic UDMA_CRC, MultiZone, and Reallocated Sector Compensation to -config advanced option K.
#   - Fixed Warranty Date always showing as expired.
#   - Added Helium and Raw Read Error Rates to statistical data file.
#   - Added Raw Read Error Rates chart column.
#   - Added compensation for Seagate Seek Error Rates and Raw Read Error Rates.
#   - Added Automatic Configuration File Update feature.
#   - Added selection between ZFS Pool Size or Zpool Pool Size. ZFS is representative of the actual storage capacity
#   -- and updated the Pool Status Report Summary chart.
#   - Added ATA Error Log Silencing (by special request).
#   - Added 0.1 second delay after writing "$logfile" to eliminate intermittent file creation errors.
#   - Fixed Text Report -> Drive Model Number not showing up for some drives.
#   - Added option to email copy of multi_report_config.txt upon any automatic script modification and/or by day.
#   
#   -- Future Work
#   ---- Change all the -config dialog to be consistent.
#   ---- Optimizing Code
#
#   The multi_report_config file will be automatically updated.
#
# v1.6c (28 August 2022)
#   - Supports external configuration file (but not required).
#   - Completely Configurable by running the script -config parameter (this took a lot of work).
#   - Added HDD/SSDmaxtempovrd variables to combat some bogus SSD values.
#   - Added TLER (SCT) support.
#   - Added support for drives which do not support recording over 65536 hours for SMART Tests and rolls over to start at zero again.
#   - Added -dump parameter to create and email all of the drives smartctl outputs as text file email attachments.
#   - Added support for Helium drives.
#
#
# v1.6: (05 August 2022)
#   Thanks to Jeff, Simon, and Sean for providing me more test data than I could shake a stick at and friendly constructive opinions/advice.
#   - Complete rewrite of the script.  More organized and easier for future updates.
#   - Almost completely got rid of using AWK, earlier versions had way too much programming within the AWK structure.
#   - Reads the drives much less often (3 times each I believe).
#   - Added test input file to parse txt files of smartctl -a output. This will allow for a single drive entry and ability
#   -- for myself or any script writer to identify additional parameters for unrecognized drives.
#   -- Usage: program_name.sh [HDD|SSD|NVM] [inputfile.txt]
#   - Added better support for SAS drives.
#   - Fixed NVMe and SAS Power On Hours for statistical data recording, and other things.
#   - Added Critical and Warning Logs to email output with better descriptive data.
#   - Logs (stored in /tmp/) no longer deleted after execution to aid in troubleshooting, but deleted at the start of the script.
#   - Added HELP file, use program_name.sh [-h] [-help]
#   - Added SCT Error Recovery to the Text Report section.
#   - Added Zpool Size, Free Space, and Temp Min/Max.
#   - Added customizable temperature values and customizable Non-Value fields (use to be coded to "N/A").
#   - Added support for SandForce SSD.
#
# v1.5:
#   - Added NVMe support
#   - Added clearer error reporting for Warning and Critical errors.
#   - Known Problems: The NVMe Power On Time has a comma that I can't get rid of, yet. I want to remove the comma when the data is retrieved.
#   -- NVMe's are not all standardized so I expect tweaks as different drive data arrives.
#   -- onHours that includes a comma will not record correctly in the statistical data file.  This is related to the NVMe problem above.
#   -- Zpool Summary does not indicate Scrub Age warning, likely the entire summary has issues. 
#
#
# v1.4d:
#   - Fixed Scrub In Progress nuisance error when a scrub is in progress.
#   - Added offsetting Reallocated Sectors for four drives.  This should be for testing only. Any drives
#   -- with a significant number of bad sectors should be replaced, just my opinion.
#   - Added Drive Warranty Expiration warning messages and ability to disable the Email Subject line warning.
#   -- NOT TESTED ON OTHER THAN U.S. FORMATTED DATE YYYY-MM-DD.
#   - Added HDD and SSD individual temperature settings.
#   - Changed order of polling Temperature data from HDD/SSD.
#
# v1.4c:
#   - Rewrite to create functions and enable easier editing.
#   - Added Custom Reports.
#   - Added disabling the RAW 'smartctl -a' data appended to the end of the email.
#   - Added sorting drives alphabetically vice the default the OS reports them.
#   - Added RED warning in Device for any single failure in the summary (deviceRedFlag switch controlled).
#   - Added some additional SSD definitions.
#   - Fixed sorting last two SMART Tests, now reports them in proper order.
#   - Fixed detecting "SMART Support is: Enabled", for white spaces.
#   - Changed IGNORE DRIVES to a String Format to clean up and simplify programming.
#   - Added MultiZone_Errors support for up to eight drives.
#   - Added sectorWarn variable to complement the sectorCrit variable.
#   - Added ignoreSeekError variable to ignore some of those wild Seek Error Rate values.
#   - Added ignoreUDMA CRC Errors due to the "Known Problem"
#   - Fixed md5/sha256 error on TrueNAS Scale (only used during config backups).
#   - Added selectable config backup periodicity by day vice every run.
#   - Added Exporting statistical data for trend analysis.
#   -- Can be setup to email statistics weekly, monthly, or not at all.
#   -- The -s switch will run Data Collection Only, no email generated.  Note: Do Not run two instances at once, the temp files do not survive.
#   - Fixed the Capacity to remove the brackets "[]", thanks Jeff Alperin.
#   - Fixed Scrub Age failure due to 1 day or longer repair time, now shows anything >24 hours.
#
#   - Known Problem: One user reported UDMA_CRC_Errors is not subtracting correctly, have not been able to personally replicate it.
#   -- This error seems to occur around line #1027
#
# v1.4b:
#   - Added SMART test remaining percentage if Last Test has a SMART Test is in progress.
#   - Fix for empty SMART fields, typically for unsupported SSD's.
#   - Added IGNORE SMART Drive so you can ignore specific drives that may cause you weird readings.
#   --- Updated so blank SSD table header is removed when you ignore all the drives (just crazy talk).
# v1.4a:
#   - Fixed report errors for if a SCRUB is in progress, now shows estimated completion time.
#   - Fixed report error for a Canceled SCRUB.
#   - Fixed FreeBSD/Linux use for SCRUB report (minor oversight).
# v1.4:
#   - Run on CRON JOB using /path/multi_report_v1.4.sh
#   - Fixed for automatic running between FreeBSD and Linux Debian (aka SCALE) as of this date.
#   - All SMART Devices will report.
#   - Added conditional Subject Line (Good/Critical/Warning).
#   - Added Automatic SSD Support.
#   --- Some updates may need to be made to fit some of SSD's. Code in the area of about line 530 will
#   --- need to be adjusted to add new attributes for the desired SSD's fields.
#   - UDMA_CRC_ERROR Override because once a drive encounters this type of error, it cannot be cleared
#   --- so you can offset it now vice having an alarm condition for old UDMA_CRC_Errors.
#   - Added listing NON-SMART Supported Drives.  Use only if useful to you, some drives will
#   --- still output some relevant data, many will not.
# v1.3:
#   - Added scrub duration column
#   - Fixed for FreeNAS 11.1 (thanks reven!)
#   - Fixed fields parsed out of zpool status
#   - Buffered zpool status to reduce calls to script
# v1.2:
#   - Added switch for power-on time format
#   - Slimmed down table columns
#   - Fixed some shellcheck errors & other misc stuff
#   - Added .tar.gz to backup file attached to email
#   - (Still coming) Better SSD SMART support
# v1.1:
#   - Config backup now attached to report email
#   - Added option to turn off config backup
#   - Added option to save backup configs in a specified directory
#   - Power-on hours in SMART summary table now listed as YY-MM-DD-HH
#   - Changed filename of config backup to exclude timestamp (just uses datestamp now)
#   - Config backup and checksum files now zipped (was just .tar before; now .tar.gz)
#   - Fixed degrees symbol in SMART table (rendered weird for a lot of people); replaced with a *
#   - Added switch to enable or disable SSDs in SMART table (SSD reporting still needs work)
#   - Added most recent Extended & Short SMART tests in drive details section (only listed one before, whichever was more recent)
#   - Reformatted user-definable parameters section
#   - Added more general comments to code
# v1.0:
#   - Initial release

######### INSTRUCTIONS ON USE OF THIS SCRIPT
#
# This script will perform three main functions:
# 1: Generate a report and send an email on your drive(s) status.
# 2: Create a copy of your Config File and attach to the same email.
# 3: Create a statistical database and attach to the same email.
#
# In order to configure the script properly read over the User-definable Parameters before making any changes.
# Make changes as indicated by the section instructions.
#
# To run the program from the command line, use ./program_name.sh [-h] for additional help instructions,
# and [-config] to run the configuration routine (highly recommended).
#
# If you create an external configuration file, you never have to edit the script,
# so how many times do I need to say it is highly recommended?  And I may force the
# change to require the external configuration file.
#
# You may need to make the script executable using "chmod +x program_name.sh"
#

###### User-definable Parameters (IF YOU DO NOT WANT TO USE THE EXTERNAL CONFIGURATION FILE) #######
# The sections below configure the script to your needs.  Please follow the instructions as it will matter, you cannot
# just "wing it".  Configurations are exact.  We use basically three different formats, Variables = true/false,
# Variables = NUMBER, and Variables = Comma Separated Variable (CSV) Strings.  Each variable will have a description
# associated with it, read it carefully.
#
# The default configuration will work right out of the box however one item must be changed, your email address.
# I highly recommend to try out the default setup first and then make changes as desired.  The only two changes
# I recommend is of course your email address, the second is the location of the statistical_data_file.cvs.
#
# Pay attention to any changes you make, accidentally deleting a quote will cause the entire script to fail.
# Do not continue editing the script after the User Definable Section unless you know what you are doing.
#
# This script will not harm your drives.  We are mostly only collecting drive data. All file writes are
# to /tmp space.  One exception: statistical_data_file.cvs is stored in /tmp by default however if you desire
# to maintain this data it must be stored in a dataset (user selected).

###### Email Address ######
# Enter your email address to send the report to.  The from address does not need to be changed unless you experience
# an error sending the email.  Some email servers only use the email address associated with the email server.

email="YourEmail@Address.com"
from="TrueNAS@local.com"

###### Custom Hack ######
# Custom Hacks are for users with generally very unsupported drives and the data must be manually manipulated.
# The goal is to not have any script customized so I will look for fixes where I can.
#
# Please look at the new Experimental Custom Drive Settings under -config.
#
# Allowable custom hacks are: mistermanko, snowlucas2022, diedrichg, or none.
custom_hack="none"

### Config File Name and Location ###
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
Config_File_Name="$SCRIPT_DIR/multi_report_config.txt"

###### Zpool Status Summary Table Settings
 
usedWarn=80               # Pool used percentage for CRITICAL color to be used.
scrubAgeWarn=37           # Maximum age (in days) of last pool scrub before CRITICAL color will be used (30 + 7 days for day of week). Default=37.
 
###### Temperature Settings
HDDtempWarn=45            # HDD Drive temp (in C) upper OK limit before a WARNING color/message will be used.
HDDtempCrit=50            # HDD Drive temp (in C) upper OK limit before a CRITICAL color/message will be used.
HDDmaxovrd="true"         # HDD Max Drive Temp Override. This value when "true" will not alarm on any Current Power Cycle Max Temperature Limit.
SSDtempWarn=45            # SSD Drive temp (in C) upper OK limit before a WARNING color/message will be used.
SSDtempCrit=50            # SSD Drive temp (in C) upper OK limit before a CRITICAL color/message will be used.
SSDmaxovrd="true"         # SSD Max Drive Temp Override. This value when "true" will not alarm on any Current Power Cycle Max Temperature Limit.
NVMtempWarn=50            # NVM Drive temp (in C) upper OK limit before a WARNING color/message will be used.
NVMtempCrit=60            # NVM Drive temp (in C) upper OK limit before a CRITICAL color/message will be used.
NVMmaxovrd="true"         # NVM Max Drive Temp Override. This value when "true" will not alarm on any Current Power Cycle Max Temperature Limit.
                          # --- NOTE: NVMe drives currently do not report Min/Max temperatures so this is a future feature.
 
###### SSD/NVMe Specific Settings
 
wearLevelCrit=9           # Wear Level Alarm Setpoint lower OK limit before a WARNING color/message, 9% is the default.
 
###### General Settings
# Output Formats
powerTimeFormat="h"       # Format for power-on hours string, valid options are "ymdh", "ymd", "ym", "y", or "h" (year month day hour).
tempdisplay="*C"          # The format you desire the temperature to be displayed in. Common formats are: "*C", "^C", or "^c". Choose your own.
non_exist_value="---"     # How do you desire non-existent data to be displayed.  The Default is "---", popular options are "N/A" or " ".
pool_capacity="zfs"       # Select "zfs" or "zpool" for Zpool Status Report - Pool Size and Free Space capacities. zfs is default.
 
# Ignore or Activate Alarms
ignoreUDMA="false"        # Set to "true" to ignore all UltraDMA CRC Errors for the summary alarm (Email Header) only, errors will appear in the graphical chart.
ignoreSeekError="true"    # Set to "true" to ignore all Seek Error Rate/Health errors.  Default is true.
ignoreReadError="true"    # Set to "true" to ignore all Seek Error Rate/Health errors.  Default is true.
ignoreMultiZone="false"   # Set to "true" to ignore all MultiZone Errors. Default is false.
disableWarranty="true"    # Set to "true to disable email Subject line alerts for any expired warranty alert. The email body will still report the alert.
 
# Disable or Activate Input/Output File Settings
includeSSD="true"         # Set to "true" will engage SSD Automatic Detection and Reporting, false = Disable SSD Automatic Detection and Reporting.
includeNVM="true"         # Set to "true" will engage NVM Automatic Detection and Reporting, false = Disable NVM Automatic Detection and Reporting.
reportnonSMART="true"     # Will force even non-SMART devices to be reported, "true" = normal operation to report non-SMART devices.
disableRAWdata="false"    # Set to "true" to remove the smartctl -a data and non-smart data appended to the normal report.  Default is false.
ata_auto_enable="false"   # Set to "true" to automatically update Log Error count to only display a log error when a new one occurs.
 
# Media Alarms
sectorsWarn=1             # Number of sectors per drive to allow with errors before WARNING color/message will be used, this value should be less than sectorsCrit.
sectorsCrit=9             # Number of sectors per drive with errors before CRITICAL color/message will be used.
reAllocWarn=0             # Number of Reallocated sector events allowed.  Over this amount is an alarm condition.
multiZoneWarn=0           # Number of MultiZone Errors to allow before a Warning color/message will be used.  Default is 0.
multiZoneCrit=5           # Number of MultiZone Errors to allow before a Warning color/message will be used.  Default is 5.
deviceRedFlag="true"      # Set to "true" to have the Device Column indicate RED for ANY alarm condition.  Default is true.
heliumAlarm="true"        # Set to "true" to set for a critical alarm any He value below "heliumMin" value.  Default is true.
heliumMin=100             # Set to 100 for a zero leak helium result.  An alert will occur below this value.
rawReadWarn=5             # Number of read errors to allow before WARNING color/message will be used, this value should be less than rawReadCrit.
rawReadCrit=100           # Number of read errors to allow before CRITICAL color/message will be used.
seekErrorsWarn=5          # Number of seek errors to allow before WARNING color/message will be used, this value should be less than seekErrorsCrit.
seekErrorsCrit=100        # Number of seek errors to allow before CRITICAL color/message will be used.

# Time-Limited Error Recovery (TLER)
SCT_Drive_Enable="false"  # Set to "true" to send a command to enable SCT on your drives for user defined timeout.
SCT_Warning="TLER_No_Msg" # Set to "all" will generate a Warning Message for all devices not reporting SCT enabled. "TLER" reports only drive which support TLER.
                          # "TLER_No_Msg" will only report for TLER drives and not report a Warning Message if the drive can set TLER on.
SCT_Read_Timeout=70       # Set to the read threshold. Default = 70 = 7.0 seconds.
SCT_Write_Timeout=70      # Set to the write threshold. Default = 70 = 7.0 seconds.
 
# SMART Testing Alarm
testAgeWarn=2             # Maximum age (in days) of last SMART test before CRITICAL color/message will be used.
 
###### Statistical Data File
statistical_data_file="$SCRIPT_DIR/statisticalsmartdata.csv"    # Default location is where the script is located.
expDataEnable="true"      # Set to "true" will save all drive data into a CSV file defined by "statistical_data_file" below.
expDataEmail="true"       # Set to "true" to have an attachment of the file emailed to you. Default is true.
expDataPurge=730          # Set to the number of day you wish to keep in the data.  Older data will be purged. Default is 730 days (2 years). 0=Disable.
expDataEmailSend="Mon"    # Set to the day of the week the statistical report is emailed.  (All, Mon, Tue, Wed, Thu, Fri, Sat, Sun, Month)
 
###### FreeNAS config backup settings
configBackup="true"      # Set to "true" to save config backup (which renders next two options operational); "false" to keep disable config backups.
configSendDay="Mon"      # Set to the day of the week the config is emailed.  (All, Mon, Tue, Wed, Thu, Fri, Sat, Sun, Month)
saveBackup="false"       # Set to "false" to delete FreeNAS config backup after mail is sent; "true" to keep it in dir below.
backupLocation="/tmp/"   # Directory in which to store the backup FreeNAS config files.

###### Attach multi_report_config.txt to Email ######
Config_Email_Enable="true"    # Set to "true" to enable periodic email (which renders next two options operational).
Config_Changed_Email="true"   # If "true" will attach the updated/changed file to the email.
Config_Backup_Day="Mon"       # Set to the day of the week the multi_report_config.txt is emailed.  (All, Mon, Tue, Wed, Thu, Fri, Sat, Sun, Month, Never)

########## REPORT CHART CONFIGURATION ##############
 
###### REPORT HEADER TITLE ######
HDDreportTitle="Spinning Rust Summary Report"     # This is the title of the HDD report, change as you desire.
SSDreportTitle="SSD Summary Report"               # This is the title of the SSD report, change as you desire.
NVMreportTitle="NVMe Summary Report"              # This is the title of the NVMe report, change as you desire.
 
### CUSTOM REPORT CONFIGURATION ###
# By default most items are selected. Change the item to false to have it not displayed in the graph, true to have it displayed.
# NOTE: Alarm setpoints are not affected by these settings, this is only what columns of data are to be displayed on the graph.
# I would recommend that you remove columns of data that you don't really care about to make the graph less busy.
 
# For Zpool Status Summary
Zpool_Pool_Name_Title="Pool Name"
Zpool_Status_Title="Status"
Zpool_Pool_Size_Title="Pool Size"
Zpool_Free_Space_Title="Free Space"
Zpool_Used_Space_Title="Used Space"
Zfs_Pool_Size_Title="^Pool Size"
Zfs_Free_Space_Title="^Free Space"
Zfs_Used_Space_Title="^Used Space"
Zpool_Read_Errors_Title="Read Errors"
Zpool_Write_Errors_Title="Write Errors"
Zpool_Checksum_Errors_Title="Cksum Errors"
Zpool_Scrub_Repaired_Title="Scrub Repaired Bytes"
Zpool_Scrub_Errors_Title="Scrub Errors"
Zpool_Scrub_Age_Title="Last Scrub Age"
Zpool_Scrub_Duration_Title="Last Scrub Duration"
 
# For Hard Drive Section
HDD_Device_ID="true"
HDD_Device_ID_Title="Device ID"
HDD_Serial_Number="true"
HDD_Serial_Number_Title="Serial Number"
HDD_Model_Number="true"
HDD_Model_Number_Title="Model Number"
HDD_Capacity="true"
HDD_Capacity_Title="HDD Capacity"
HDD_Rotational_Rate="true"
HDD_Rotational_Rate_Title="RPM"
HDD_SMART_Status="true"
HDD_SMART_Status_Title="SMART Status"
HDD_Warranty_Title="Warr- anty"
HDD_Warranty="true"
HDD_Raw_Read_Error_Rate="true"
HDD_Raw_Read_Error_Rate_Title="Raw Error Rate"
HDD_Drive_Temp="true"
HDD_Drive_Temp_Title="Curr Temp"
HDD_Drive_Temp_Min="true"
HDD_Drive_Temp_Min_Title="Temp Min"
HDD_Drive_Temp_Max="true"
HDD_Drive_Temp_Max_Title="Temp Max"
HDD_Power_On_Hours="true"
HDD_Power_On_Hours_Title="Power On Time"
HDD_Start_Stop_Count="true"
HDD_Start_Stop_Count_Title="Start Stop Count"
HDD_Load_Cycle="true"
HDD_Load_Cycle_Title="Load Cycle Count"
HDD_Spin_Retry="true"
HDD_Spin_Retry_Title="Spin Retry Count"
HDD_Reallocated_Sectors="true"
HDD_Reallocated_Sectors_Title="Re-alloc Sects"
HDD_Reallocated_Events="true"
HDD_Reallocated_Events_Title="Re-alloc Evnt"
HDD_Pending_Sectors="true"
HDD_Pending_Sectors_Title="Curr Pend Sects"
HDD_Offline_Uncorrectable="true"
HDD_Offline_Uncorrectable_Title="Offl Unc Sects"
HDD_UDMA_CRC_Errors="true"
HDD_UDMA_CRC_Errors_Title="UDMA CRC Error"
HDD_Seek_Error_Rate="true"
HDD_Seek_Error_Rate_Title="Seek Error Rate"
HDD_MultiZone_Errors="true"
HDD_MultiZone_Errors_Title="Multi Zone Error"
HDD_Helium_Level="true"
HDD_Helium_Level_Title="He Level"
HDD_Last_Test_Age="true"
HDD_Last_Test_Age_Title="Last Test Age"
HDD_Last_Test_Type="true"
HDD_Last_Test_Type_Title="Last Test Type"
 
# For Solid State Drive Section
SSD_Device_ID="true"
SSD_Device_ID_Title="Device ID"
SSD_Serial_Number="true"
SSD_Serial_Number_Title="Serial Number"
SSD_Model_Number="true"
SSD_Model_Number_Title="Model Number"
SSD_Capacity="true"
SSD_Capacity_Title="HDD Capacity"
SSD_SMART_Status="true"
SSD_SMART_Status_Title="SMART Status"
SSD_Warranty_Title="Warr- anty"
SSD_Warranty="true"
SSD_Drive_Temp="true"
SSD_Drive_Temp_Title="Curr Temp"
SSD_Drive_Temp_Min="true"
SSD_Drive_Temp_Min_Title="Temp Min"
SSD_Drive_Temp_Max="true"
SSD_Drive_Temp_Max_Title="Temp Max"
SSD_Power_On_Hours="true"
SSD_Power_On_Hours_Title="Power On Time"
SSD_Wear_Level="true"
SSD_Wear_Level_Title="Wear Level"
SSD_Reallocated_Sectors="true"
SSD_Reallocated_Sectors_Title="Re-alloc Sects"
SSD_Reallocated_Events="true"
SSD_Reallocated_Events_Title="Re-alloc Evnt"
SSD_Pending_Sectors="true"
SSD_Pending_Sectors_Title="Curr Pend Sects"
SSD_Offline_Uncorrectable="true"
SSD_Offline_Uncorrectable_Title="Offl Unc Sects"
SSD_UDMA_CRC_Errors="true"
SSD_UDMA_CRC_Errors_Title="UDMA CRC Error"
SSD_Last_Test_Age="true"
SSD_Last_Test_Age_Title="Last Test Age"
SSD_Last_Test_Type="true"
SSD_Last_Test_Type_Title="Last Test Type"
 
# For NVMe Drive Section
NVM_Device_ID="true"
NVM_Device_ID_Title="Device ID"
NVM_Serial_Number="true"
NVM_Serial_Number_Title="Serial Number"
NVM_Model_Number="true"
NVM_Model_Number_Title="Model Number"
NVM_Capacity="true"
NVM_Capacity_Title="HDD Capacity"
NVM_SMART_Status="true"
NVM_SMART_Status_Title="SMART Status"
NVM_Warranty_Title="Warr- anty"
NVM_Warranty="true"
NVM_Critical_Warning="true"
NVM_Critical_Warning_Title="Critical Warning"
NVM_Drive_Temp="true"
NVM_Drive_Temp_Title="Curr Temp"
NVM_Drive_Temp_Min="false"               # I have not found this on an NVMe drive yet, so set to false
NVM_Drive_Temp_Min_Title="Temp Min"
NVM_Drive_Temp_Max="false"               # I have not found this on an NVMe drive yet, so set to false
NVM_Drive_Temp_Max_Title="Temp Max"
NVM_Power_On_Hours="true"
NVM_Power_On_Hours_Title="Power On Time"
NVM_Wear_Level="true"
NVM_Wear_Level_Title="Wear Level"


###### Drive Ignore List
# What does it do:
#  Use this to list any drives to ignore and remove from the report.  This is very useful for ignoring USB Flash Drives
#  or other drives for which good data is not able to be collected (non-standard).
#
# How to use it:
#  We are using a comma delimited file to identify the drive serial numbers.  You MUST use the exact and full serial
#  number smartctl reports, if there is no identical match then it will not match. Additionally you may list drives
#  from other systems and they will not have any effect on a system where the drive does not exist.  This is great
#  to have one configuration file that can be used on several systems.
#
# Live Example: Ignore_Drives="VMWare,1JUMLBD,21HNSAFC21410E"
 
Ignore_Drives="none"

 
###### Drive UDMA_CRC_Error_Count List
# What does it do:
#  If you have a drive which has an UDMA count other than 0 (zero), this setting will offset the
#  value back to zero for the concerns of monitoring future increases of this specific error. Any match will
#  subtract the given value to report a 0 (zero) value and highlight it in yellow to denote it was overridden.
#  The Warning Title will not be flagged if this is zero'd out in this manner.
#  NOTE: UDMA_CRC_Errors are typically permanently stored in the drive and cannot be reset to zero even though
#        they are frequently caused by a data cable communications error.
#
# How to use it:
#  List each drive by serial number and include the current UDMA_CRC_Error_Count value.
#  The format is very specific and will not work if you wing it, use the Live EXAMPLE.
#
#  Set the FLAG in the FLAGS Section ignoreUDMA to false (the default setting).
#
# If the error count exceeds the limit minus the offset then a warning message will be generated.
# On the Status Report the UDMA CRC Errors block will be YELLOW with a value of 0 for an overridden value.
#   -- NOTE: We are using the colon : as the separator between the drive serial number and the value to change.
#
# Format: variable=Drive_Serial_Number:Current_UDMA_Error_Count and add a comma if you have more than one drive.
#
# The below example shows drive WD-WMC4N2578099 has 1 UDMA_CRC_Error, drive S2X1J90CA48799 has 2 errors.
#
# Live Example: "WD-WMC4N2578099:1,S2X1J90CA48799:2,P02618119268:1"
 
CRC_Errors="none"

 
###### Multi_Zone_Errors List
# What does it do:
#   This identifies drives with Multi_Zone_Errors which may be irritating people.
#   Multi_Zone_Errors for some drives, not all drives are pretty much meaningless.
#
# How to use it:
#   Use same format as CRC_Errors (see above).
 
Multi_Zone="none"
 
 
#######  Reallocated Sectors Exceptions
# What does it do:
#  This will offset any Reallocated Sectors count by the value provided.
#
#  I do not recommend using this feature as I'm a believer in if you have over 5 bad sectors, odds are the drive will get worse.
#  I'd recommend replacing the drive before complete failure.  But that is your decision.
#
#  Why is it even an option?
#  I use it for testing purposes only but you may want to use it.
#
# How to use it:
#   Use same format as CRC_Errors (see above).
 
Bad_Sectors="none"

######## ATA Error Log Silencing ##################
# What does it do:
#   This will ignore error log messages equal to or less than the threshold.
# How to use:
#  Same as the CRC_Errors, [drive serial number:error count]

ata_errors="none"

####### Custom Drive Configuration (Experimental)
# Used to define specific alarm values for specific drives by serial number.
# This should only be used for drives where the default alarm settings
# are not proper.  Up to 24 unique drive values may be stored.
#
# Use -config to set these values.

Custom_Drives=""
 
####### Warranty Expiration Date
# What does it do:
# This section is used to add warranty expirations for designated drives and to create an alert when they expire.
# The date format is YYYY-MM-DD.
#
# Below is an example for the format using my own drives, which yes, are expired.
# As previously stated above, drive serial numbers must be an exact match to what smartctl reports to function.
#
# If the drive does not exist, for example my drives are not on your system, then nothing will happen.
#
# How to use it:
#   Use the format ="Drive_Serial_Number:YYYY-MM-DD" and add a comma if you have more than one drive.
 
Drive_Warranty="none"

######## Expired Drive Warranty Setup
expiredWarrantyBoxColor="#000000"   # "#000000" = normal box perimeter color.
WarrantyBoxPixels="1"   # Box line thickness. 1 = normal, 2 = thick, 3 = Very Thick, used for expired drives only.
WarrantyBackgndColor="#f1ffad"  # Hex code or "none" = normal background, Only for expired drives. 


######## Enable-Disable Text Portion ########
enable_text="true"    # This will display the Text Section when = "true" or remove it when not "true".  Default="true"


###### Global table of colors
# The colors selected you can change but you will need to look up the proper HEX code for a color.

okColor="#b5fcb9"       # Hex code for color to use in SMART Status column if drives pass (default is darker light green, #b5fcb9).
warnColor="#f765d0"     # Hex code for WARN color (default is purple, #f765d0).
critColor="#ff0000"     # Hex code for CRITICAL color (default is red, #ff0000).
altColor="#f4f4f4"      # Table background alternates row colors between white and this color (default is light gray, #f4f4f4).
whtColor="#ffffff"      # Hex for White background.
ovrdColor="#ffffe4"     # Hex code for Override Yellow.
blueColor="#87ceeb"     # Hex code for Sky Blue, used for the SCRUB In Progress background.
yellowColor="#f1ffad"   # Hex code for pale yellow.


##########################
##########################
###                    ###
###  STOP EDITING THE  ###
###    SCRIPT HERE     ###
###                    ###
##########################
##########################

###### Auto-generated Parameters
softver=$(uname -s)
host=$(hostname -s)
truenas_ver=$(cat /etc/version)
testdata_path="data"

### temp files have been converted to variable stored, not stored in /tmp/ as a file. ###
logfile="/tmp/smart_report_body.tmp"
logfile_header="/tmp/smart_report_header.tmp"
logfile_warning="/tmp/smart_report_warning_flag.tmp"
logfile_critical="/tmp/smart_report_critical_flag.tmp"
logfile_warranty_temp="/tmp/smart_report_warranty_flag.tmp"
logfile_messages_temp="/tmp/smart_report_messages.tmp"
boundary="gc0p4Jq0M2Yt08jU534c0p"

if [[ $softver != "Linux" ]]; then
programver="Multi-Report v1.6f-beta dtd:2022-12-11 (TrueNAS Core "$(cat /etc/version | cut -d " " -f1 | sed 's/TrueNAS-//')")"
else
programver="Multi-Report v1.6f-beta dtd:2022-12-11 (TrueNAS Scale "$(cat /etc/version)")"
fi

#If the config file format changes, this is the latest working date, anything older must be updated.
valid_config_version_date="2022-12-11"

##########################
##########################
###                    ###
###  PROGRAMING /      ###
###  TROUBLESHOOTING   ###
###       HACKS        ###
###                    ###
##########################
##########################

#Unique progeramming hacks to properly emulate other hardware that is not actually on the system.

VMWareNVME="on"            # Set to "off" normally, "on" to assist in incorrect VMWare reporting.
Silence="on"               # Set to "on" normally, "off" to provide Joe Schmuck troubleshooting feedback while running the script.
Joes_System="true"        # Custom settings for my system.
Sample_Test="false"         # Setup static test values for testing.

##########################
##########################
###                    ###
###  DEFINE FUNCTIONS  ###
###                    ###
##########################
##########################


############## CREATE TESTDATA TEXT FILE ################

create_testdata_text_file () {
echo "Creating testdata variable"
testdata_a="$(ls $testdata_path/*.a)"
testdata_x="$(ls $testdata_path/*.x)"
echo "testdata_a="$testdata_a
echo " "
echo "testdata_x="$testdata_x
}

############## LOAD EXTERNAL CONFIGURATION FILE #############

load_config () {

if test -e "$Config_File_Name"; then
. "$Config_File_Name"

# Lets test if the config file needs to be updated first.
config_version_date="$(cat "$Config_File_Name" | grep "dtd" | cut -d ':' -f 2 | cut -d ' ' -f 1 )"
echo "Configuration File Version Date: "$config_version_date
if [[ $config_version_date < $valid_config_version_date ]]; then echo "Found Old Configuration File"; echo "Automatically updating configuration file..."; update_config_file; echo "Running normal script"; fi
   . "$Config_File_Name"
else
   echo "No Config File Exists"
   echo "Checking for a valid email within the script..."
   if [[ $email == "YourEmail@Address.com" ]]; then
      echo "No Valid Email Address..."
      echo "Recommend running script with the '-config' switch and selecting the N)ew Configuration option."
      echo "... Aborting"
      echo " "
      exit 1
   else
      echo "Valid email within the script = "$email", using script parameters..."
      echo " "
      External_Config="no"
      return
   fi
fi
}

#################### Convert to Decimal ##################

convert_to_decimal () {

if [[ "$1" == "" ]]; then return; fi
Converting_Value=${1#0}
#echo "Step 1 -> Converting "$1" to BASE 10 = "$Converting_Value
Converting_Value="${Converting_Value//,}"
#echo "Step 2 -> Removing commas from "$1" to "$Converting_Value
Return_Value=$Converting_Value
if [[ $1 == "0" ]]; then Return_Value=0; fi
#echo "Return_Value="$Return_Value
}

#################### CHECK OPEN FILE #####################
# Checks if trhe file is open before continuing.
# Passes $1=filename
# Loop for up to 60 seconds waiting for the file to close.

check_open_file () {
for (( y=1; y<=60; y++ ))
do
   check_file=$1
   result=`fuser -f $check_file 2>&1`
   pid=`echo $result | cut -d ':' -f 2`
   if [ -z "$pid" ]; then return; fi
   echo "File $1 Open - Delayed"
   sleep .5
done
}


#################### Force Slight Delay ####################
# I think there is a race condition when writing to $logfile, trying to slow this down.
force_delay () {
sleep .1
}

#################### PURGE EXPORT DATA CSV FILE #######################

purge_exportdata () {
### This routine will purge the "statistical_data_file" of data older then "expDataPurge".

# Delete temp file if it exists
if test -e "/tmp/temp_purge_file.csv"; then
rm "/tmp/temp_purge_file.csv"
# Create the header
#  printf "Date,Time,Device ID,Drive Type,Serial Number,SMART Status,Temp,Power On Hours,Wear Level,Start Stop Count,Load Cycle,Spin Retry,Reallocated Sectors,\
#ReAllocated Sector Events,Pending Sectors,Offline Uncorrectable,UDMA CRC Errors,Seek Error Rate,Multi Zone Errors,Read Error Rate,Helium Level\n" > "/tmp/temp_purge_file.csv"
fi

  if [ $softver != "Linux" ]; then
     expireDate=$(date -v -"$expDataPurge"d +%Y/%m/%d)
  else
     expireDate=$(date -d "$expDataPurge days ago" +%Y/%m/%d) 
  fi

awk -v expireDate="$expireDate" -F, '{ if($1 >= expireDate) print $0;}' "$statistical_data_file" > "/tmp/temp_purge_file.csv"

cp -R "/tmp/temp_purge_file.csv" "$statistical_data_file"
}

###### Purge ada50 and nvme50 from the logs #######

purge_testdata () {
### This routine will purge the "statistical_data_file" of test data matching "ada50" or "nvme50".

# Delete temp file if it exists
if test -e "/tmp/temp_purge_file.csv"; then
rm "/tmp/temp_purge_file.csv"
fi

awk -F, '{ if($3 != "nvme50") print $0;}' "$statistical_data_file" > "/tmp/temp_purge_file1.csv"
awk -F, '{ if($3 != "ada50") print $0;}' "/tmp/temp_purge_file1.csv" > "/tmp/temp_purge_file.csv"

cp -R "/tmp/temp_purge_file.csv" "$statistical_data_file"
}

################## EMAIL EXPORT DATA CVS FILE #########################

email_datafile () {

if [ "$expDataEmail" == "true" ]; then
   Now=$(date +"%a")
   doit="false"
     case $expDataEmailSend in
       All)
         doit="true"
       ;;
       Mon|Tue|Wed|Thu|Fri|Sat|Sun)
         if [[ "$expDataEmailSend" == "$Now" ]]; then doit="true"; fi
       ;;
       Month)
         if [[ $(date +"%d") == "01" ]]; then doit="true"; fi
       ;;
       *)
       ;;
     esac

   if [[ "$doit" == "true" ]]; then
   (
      # Write MIME section header for file attachment (encoded with base64)
      echo "--${boundary}"
      echo "Content-Type: text/csv"
      echo "Content-Transfer-Encoding: base64"
      echo "Content-Disposition: attachment; filename=Statistical_Data.csv"
      base64 "$statistical_data_file"
      if [[ "$dump_all" == "1" || "$dump_all" == "2" ]]; then echo "--${boundary}"; else echo "--${boundary}--"; fi
      ) >> "$logfile"
force_delay
   fi

fi
}


##################### IGNORE DRIVES ROUTINE #################

process_ignore_drives () {
         targument="$(smartctl -i /dev/"${drive}" | grep "Serial Number:" | awk '{print $3}')";

### Process Ignore List ###
         s="0"
         IFS=',' read -ra ADDR <<< "$Ignore_Drives"
           for i in "${ADDR[@]}"; do
             if [[ $i == $targument ]]; then s="1"; continue; fi
           done
         if [[ $s == "0" ]]; then printf "%s " "${drive}"; fi
}

################## SORT DRIVES ROUTINE ########################

sort_drives () {
#echo "Incoming Drive List="$sort_list
sort_list=$(for i in `echo $sort_list`; do
echo "$i"
done | sort -V)
#echo "Outgoing Drive List="$sort_list
}

#################### GET SMART HARD DRIVES ############################

get_smartHDD_listings () {
# variable smartdrives

if [[ "$testfile" != "" ]]; then
echo "HDD TEST FILE ROUTINE"
smartdrives="ada50"
return
fi

if [ $softver != "Linux" ]; then
    smartdrives=$(for drive in $(sysctl -n kern.disks); do
      if [ "$(smartctl -i /dev/"${drive}" | grep "SMART support is:.\s*Enabled")" ] && ! [ "$(smartctl -i /dev/"${drive}" | grep "Solid State Device")" ]; then process_ignore_drives; fi
    done | awk '{for (i=NF; i!=0 ; i--) print $i }' | tr ' ' '\n' | sort | tr '\n' ' ')
else
    smartdrives=$(for drive in $(fdisk -l | grep "Disk /dev/sd" | cut -c 11-13 | tr '\n' ' '); do
        if [ "$(smartctl -i /dev/"${drive}" | grep "SMART support is:.\s*Enabled")" ] && ! [ "$(smartctl -i /dev/"${drive}" | grep "Solid State Device")" ]; then process_ignore_drives; fi
    done | awk '{for (i=NF; i!=0 ; i--) print $i }' | tr ' ' '\n' | sort | tr '\n' ' ')
fi

# Call Sort Routine with the drive string.
if [[ "$smartdrives" != "" ]]; then
sort_list=$smartdrives
sort_drives
smartdrives=$sort_list
fi
}


########################## GET SMART SOLID DISK DRIVES ################################

get_smartSSD_listings () {
# variable smartdrivesSSD

if [[ "$testfile" != "" ]]; then
echo "SSD TEST FILE ROUTINE"
smartdrivesSSD="ada50"
return
fi

  if [ $softver != "Linux" ]; then
   smartdrivesSSD=$(for drive in $(sysctl -n kern.disks); do
        if [ "$(smartctl -i /dev/"${drive}" | grep "SMART support is:.\s*Enabled")" ] && [ "$(smartctl -i /dev/"${drive}" | grep "Solid State Device")" ]; then process_ignore_drives; fi
    done | awk '{for (i=NF; i!=0 ; i--) print $i }' | tr ' ' '\n' | sort | tr '\n' ' ')
  else
   smartdrivesSSD=$(for drive in $(fdisk -l | grep "Disk /dev/sd" | cut -c 11-13 | tr '\n' ' '); do
        if [ "$(smartctl -i /dev/"${drive}" | grep "SMART support is:.\s*Enabled")" ] && [ "$(smartctl -i /dev/"${drive}" | grep "Solid State Device")" ]; then process_ignore_drives; fi
    done | awk '{for (i=NF; i!=0 ; i--) print $i }' | tr ' ' '\n' | sort | tr '\n' ' ')
  fi

# Call Sort Routine with the drive string.
if [[ "$smartdrivesSSD" != "" ]]; then
sort_list=$smartdrivesSSD
sort_drives
smartdrivesSSD=$sort_list
fi
}

########################## GET NVMe DRIVES ################################

get_smartNVM_listings () {
# variable smartdrivesNVM

if [[ "$testfile" != "" ]]; then
echo "NVM TEST FILE ROUTINE"
smartdrivesNVM="nvme50"
return
fi

  if [ $softver != "Linux" ]; then
   smartdrivesNVM=$(for drive in $(sysctl -n kern.disks); do
        if [ "$(smartctl -i /dev/"${drive}" | grep "NVM")" ]; then process_ignore_drives; fi
    done | awk '{for (i=NF; i!=0 ; i--) print $i }' | tr ' ' '\n' | sort | tr '\n' ' ')
  else
smartdrivesNVM=$(for drive in $(fdisk -l | grep "Disk /dev/nvm" | cut -d ':' -f 1 | cut -d '/' -f 3 | tr '\n' ' '); do
         if [ "$(smartctl -i /dev/"${drive}" | grep "NVM")" ]; then process_ignore_drives; fi
    done | awk '{for (i=NF; i!=0 ; i--) print $i }' | tr ' ' '\n' | sort | tr '\n' ' ')
  fi

### Convert nvdx to nvmexx in smartdrivesNVM ###
smartdrivesNVM=$( echo "$smartdrivesNVM" | sed 's/nvd/nvme/g' )

# Call Sort Routine with the drive string.
if [[ "$smartdrivesNVM" != "" ]]; then
sort_list=$smartdrivesNVM
sort_drives
smartdrivesNVM=$sort_list
fi
}


########################## GET OTHER SMART DEVICES ##################################

get_smartOther_listings () {
### Get the non-SSD listing - MUST support SMART
# variable nonsmartdrives
if [[ "$testfile" != "" ]]; then
echo "TEST FILE ROUTINE"
nonsmartdrives="ada50"
return
fi

  if [ $softver != "Linux" ]; then
   nonsmartdrives=$(for drive in $(sysctl -n kern.disks); do
        if [ ! "$(smartctl -i /dev/"${drive}" | grep "SMART support is:.\s*Enabled")" ] && [ ! "$(smartctl -i /dev/"${drive}" | grep "NVM")" ]; then process_ignore_drives; fi
    done | awk '{for (i=NF; i!=0 ; i--) print $i }' | tr ' ' '\n' | sort | tr '\n' ' ')
  else
   nonsmartdrives=$(for drive in $(fdisk -l | grep "Disk /dev/sd" | cut -c 11-13 | tr '\n' ' '); do
        if [ ! "$(smartctl -i /dev/"${drive}" | grep "SMART support is: Enabled")" ]; then process_ignore_drives; fi
    done | awk '{for (i=NF; i!=0 ; i--) print $i }' | tr ' ' '\n' | sort | tr '\n' ' ')
  fi

# Call Sort Routine with the drive string.
if [[ "$nonsmartdrives" != "" ]]; then
sort_list=$nonsmartdrives
sort_drives
nonsmartdrives=$sort_list
fi
}

########################### FORMAT EMAILS STEP 1 ##########################

email_preformat () {
###### Email pre-formatting
### Set some of the email headers before conditional headers

(
    echo "MIME-Version: 1.0"
    echo "Content-Type: multipart/mixed; boundary=${boundary}"
) > "$logfile"
force_delay
}


########################### CONFIGURATION BACKUP ##############################

config_backup () {

###### Config backup (if enabled)
    tarfile="/tmp/config_backup.tar.gz"
    filename="$(date "+FreeNAS_Config_%Y-%m-%d")"
    filename2="Stat_Data"

if [ "$configBackup" == "true" ]; then
 Now=$(date +"%a")
 doit="false"
  case $configSendDay in
    All)
      doit="true"
      ;;
    Mon|Tue|Wed|Thu|Fri|Sat|Sun)
      if [[ "$configSendDay" == "$Now" ]]; then
         doit="true"
      fi
      ;;
    Month)
      if [[ $(date +"%d") == "01" ]]; then
         doit="true"
      fi
      ;;
    *)
      ;;
  esac

  if [[ "$doit" == "true" ]]; then

    # Set up file names, etc for later
    tarfile="/tmp/config_backup.tar.gz"
    filename="$(date "+FreeNAS_Config_%Y-%m-%d")"
    filename2="Stat_Data"
    ### Test config integrity


    if ! [ "$(sqlite3 /data/freenas-v1.db "pragma integrity_check;")" == "ok" ]; then
        # Config integrity check failed, set MIME content type to html and print warning
        (
            echo "--${boundary}"
            echo "Content-Type: text/html"
            echo "<b>Automatic backup of FreeNAS configuration has failed! The configuration file is corrupted!</b>"
            echo "<b>You should correct this problem as soon as possible!</b>"
            echo "<br>"
        ) >> "$logfile"
force_delay

    else
        # Config integrity check passed; copy config db, generate checksums, make .tar.gz archive
        cp /data/freenas-v1.db "/tmp/${filename}.db"

                   if [ $softver != "Linux" ]; then
                      md5 "/tmp/${filename}.db" > /tmp/config_backup.md5
                      sha256 "/tmp/${filename}.db" > /tmp/config_backup.sha256
                   else
                      md5sum "/tmp/${filename}.db" > /tmp/config_backup.md5
                      sha256sum "/tmp/${filename}.db" > /tmp/config_backup.sha256
                   fi

        (
            cd "/tmp/" || exit;
            tar -czf "${tarfile}" "./${filename}.db" ./config_backup.md5 ./config_backup.sha256;
        )
        (
            # Write MIME section header for file attachment (encoded with base64)
            echo "--${boundary}"
            echo "Content-Type: application/tar+gzip"
            echo "Content-Transfer-Encoding: base64"
            echo "Content-Disposition: attachment; filename=${filename}.tar.gz"
            base64 "$tarfile"
            # Write MIME section header for html content to come below
            echo "--${boundary}"
            echo "Content-Type: text/html"
        ) >> "$logfile"
force_delay
        # If logfile saving is enabled, copy .tar.gz file to specified location before it (and everything else) is removed below

                if [ "$saveBackup" == "true" ]; then
                  cp "${tarfile}" "${backupLocation}/${filename}.tar.gz"
                fi
        rm "/tmp/${filename}.db"
        rm /tmp/config_backup.md5
        rm /tmp/config_backup.sha256
        rm "${tarfile}"
    fi
else
    (
        echo "--${boundary}"
        echo "Content-Type: text/html"
    ) >> "$logfile"
force_delay
  fi
else
  # configBackup = false so this is what to do
  # Config backup enabled; set up for html-type content
    (
        echo "--${boundary}"
        echo "Content-Type: text/html"
    ) >> "$logfile"
force_delay
fi
}


################################## GENERATE ZPOOL REPORT ##################################

zpool_report () {
###### Report Summary Section (html tables)
### zpool status summary table

(
  # Write HTML table headers to log file; HTML in an email requires 100% in-line styling (no CSS or <style> section), hence the massive tags
    echo $programver"<br>Report Run "$(date +%d-%b-%Y)" @ "$timestamp
    echo "<br><br>"
    echo "<table style=\"border: 1px solid black; border-collapse: collapse;\">"
    echo "<tr><th colspan=\"12\" style=\"text-align:center; font-size:20px; height:40px; font-family:courier;\"><span style='color:gray;'>*</span>ZPool Status Report Summary</th></tr>"
    echo "<tr>"
    echo "  <th style=\"text-align:center; width:130px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$Zpool_Pool_Name_Title"</th>"
    echo "  <th style=\"text-align:center; width:80px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$Zpool_Status_Title"</th>"
    echo "  <th style=\"text-align:center; width:80px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$Zpool_Pool_Size_Title"</th>"
    echo "  <th style=\"text-align:center; width:80px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$Zpool_Free_Space_Title"</th>"
    echo "  <th style=\"text-align:center; width:80px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$Zpool_Used_Space_Title"</th>"
    echo "  <th style=\"text-align:center; width:80px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$Zpool_Read_Errors_Title"</th>"
    echo "  <th style=\"text-align:center; width:80px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$Zpool_Write_Errors_Title"</th>"
    echo "  <th style=\"text-align:center; width:80px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$Zpool_Checksum_Errors_Title"</th>"
    echo "  <th style=\"text-align:center; width:100px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$Zpool_Scrub_Repaired_Title"</th>"
    echo "  <th style=\"text-align:center; width:80px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$Zpool_Scrub_Errors_Title"</th>"
    echo "  <th style=\"text-align:center; width:80px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$Zpool_Scrub_Age_Title"</th>"
    echo "  <th style=\"text-align:center; width:80px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$Zpool_Scrub_Duration_Title"</th>"
    echo "</tr>"
) >> "$logfile"
force_delay

pools=$(zpool list -H -o name)
sort_list=$pools
sort_drives
pools=$sort_list
poolNum=0
for pool in $pools; do
    # zpool health summary
    status="$(zpool list -H -o health "$pool")"
    # Total all read, write, and checksum errors per pool
    errors="$(zpool status "$pool" | grep -E "(ONLINE|DEGRADED|FAULTED|UNAVAIL|REMOVED)[ \\t]+[0-9]+")"
    readErrors=0
    for err in $(echo "$errors" | awk '{print $3}'); do
        if echo "$err" | grep -E -q "[^0-9]+"; then
            readErrors=1000
            break
        fi
        readErrors=$((readErrors + err))
    done
    writeErrors=0
    for err in $(echo "$errors" | awk '{print $4}'); do
        if echo "$err" | grep -E -q "[^0-9]+"; then
            writeErrors=1000
            break
        fi
        writeErrors=$((writeErrors + err))
    done
    cksumErrors=0
    for err in $(echo "$errors" | awk '{print $5}'); do
        if echo "$err" | grep -E -q "[^0-9]+"; then
            cksumErrors=1000
            break
        fi
        cksumErrors=$((cksumErrors + err))
    done
    # Not sure why this changes values larger than 1000 to ">1K", but I guess it works, so I'm leaving it
    # Answer to question above: Because it formats the value to = ">1K" vice stating very large values to
    # fit into the formatted table.  All we care about is it's way too high.
    if [ "$readErrors" -gt 999 ]; then readErrors=">1K"; fi
    if [ "$writeErrors" -gt 999 ]; then writeErrors=">1K"; fi
    if [ "$cksumErrors" -gt 999 ]; then cksumErrors=">1K"; fi

    # Get ZFS capacity (the real capacity)
    zfs_pool_used="$(zfs list $pool | awk '{print $2}' | sed -e '/USED/d')"
    zfs_pool_avail="$(zfs list $pool | awk '{print $3}' | sed -e '/AVAIL/d')"
#zfs_pool_used="104G"
#zfs_pool_avail="25.7T"
    if [[ $zfs_pool_used == *"T"* ]]; then
       zfs_pool_used1="$(awk -v a="$zfs_pool_used" 'BEGIN { printf a*1000 }' </dev/null)";
    else
       zfs_pool_used1="$(awk -v a="$zfs_pool_used" 'BEGIN { printf a*1 }' </dev/null)";
    fi
    if [[ $zfs_pool_avail == *"T"* ]]; then
       zfs_pool_avail1="$(awk -v a="$zfs_pool_avail" 'BEGIN { printf a*1000 }' </dev/null)";
    else
       zfs_pool_avail1="$(awk -v a="$zfs_pool_avail" 'BEGIN { printf a*1 }' </dev/null)";
    fi

    zfs_pool_size="$(awk -v a="$zfs_pool_used1" -v b="$zfs_pool_avail1" 'BEGIN { printf a+b }' </dev/null)"
#echo "---"
#echo "size="$zfs_pool_size
    zfs_pool_size1="$(awk -v a="$zfs_pool_size" 'BEGIN { printf "%.0f", a }' </dev/null)"

    if [[ $zfs_pool_size1 -gt 1000 ]]; then
       zfs_pool_size="$(awk -v a="$zfs_pool_size" 'BEGIN { printf "%.2f", a/1000 }' </dev/null)T"
    else
       zfs_pool_size="$(awk -v a="$zfs_pool_size" 'BEGIN { printf "%.2f", a }' </dev/null)G"
    fi

    # Get used capacity percentage of the zpool
    used="$(zpool list -H -p -o capacity "$pool")"
    pool_size="$(zpool list -H -o size "$pool")"
    pool_free="$(zpool list -H -o free "$pool")"

    # Gather info from most recent scrub; values set to "$non_exist_value" initially and overwritten when (and if) it gathers scrub info
    scrubRepBytes="$non_exist_value"
    scrubErrors="$non_exist_value"
    scrubAge="$non_exist_value"
    scrubTime="$non_exist_value"
    statusOutput="$(zpool status "$pool")"


### Fix for SCRUB lasting longer than 24 hours.
scrubDays="$(echo "$statusOutput" | grep "scan" | awk '{print $7}')"

if [[ $scrubDays == "days" ]]; then
   scrubextra="$(echo "$statusOutput" | grep "scan" | awk '{print $6}')"


### Fix for SCRUB Cancelled and In-Progress

#Check if scrub in progress
if [ "$(echo "$statusOutput" | grep -w "scan" | awk '{print $4}')" = "progress" ]; then
        scrubAge="In Progress"
        scrubTime="$(echo "Est Comp: ")$(echo "$statusOutput" | grep "done, " | awk '{print $5}')"

# Check if the SCRUB is completed or canceled.

elif [ "$(echo "$statusOutput" | grep "scan" | awk '{print $2}')" = "scrub" ] && [ "$(echo "$statusOutput" | grep "scan" | awk '{print $3}')" = "canceled" ]; then
          scrubAge="Canceled"
       elif [ "$(echo "$statusOutput" | grep "scan" | awk '{print $2}')" = "scrub" ]; then
        scrubRepBytes="$(echo "$statusOutput" | grep "scan" | awk '{print $4}')"
        scrubRepBytes="$(echo "$scrubRepBytes" | rev | cut -c2- | rev)"
        scrubErrors="$(echo "$statusOutput" | grep "scan" | awk '{print $10}')"
        # Convert time/datestamp format presented by zpool status, compare to current date, calculate scrub age

# For FreeBSD
   if [ $softver != "Linux" ]; then
        scrubDate="$(echo "$statusOutput" | grep "scan" | awk '{print $17"-"$14"-"$15"_"$16}')"
        scrubTS="$(date -j -f "%Y-%b-%e_%H:%M:%S" "$scrubDate" "+%s")"
   else
# For Linux
        scrubDate="$(echo "$statusOutput" | grep "scan" | awk '{print $14" "$15" "$17" "$16}')"
        scrubTS="$(date --date="$scrubDate" "+%s")"
   fi
        currentTS="$(date "+%s")"
        scrubAge=$((((currentTS - scrubTS) + 43200) / 86400))

        scrubTimetemp="$(echo "$statusOutput" | grep "scan" | awk '{print $8}')"
        scrubTime="$scrubextra days $scrubTimetemp"

        else
        #No scrub previously performed
        scrubAge="Never Scrubbed"
fi

else

#Check if scrub in progress
if [ "$(echo "$statusOutput" | grep -w "scan" | awk '{print $4}')" = "progress" ]; then
        scrubAge="In Progress"
        scrubTime="$(echo "Est Comp: ")$(echo "$statusOutput" | grep "done, " | awk '{print $5}')"

# Check if the SCRUB is completed or canceled.

elif [ "$(echo "$statusOutput" | grep "scan" | awk '{print $2}')" = "scrub" ] && [ "$(echo "$statusOutput" | grep "scan" | awk '{print $3}')" = "canceled" ]; then
          scrubAge="Canceled"
       elif [ "$(echo "$statusOutput" | grep "scan" | awk '{print $2}')" = "scrub" ]; then
        scrubRepBytes="$(echo "$statusOutput" | grep "scan" | awk '{print $4}')"
        scrubRepBytes="$(echo "$scrubRepBytes" | rev | cut -c2- | rev)"
        scrubErrors="$(echo "$statusOutput" | grep "scan" | awk '{print $8}')"
        # Convert time/datestamp format presented by zpool status, compare to current date, calculate scrub age

# For FreeBSD
   if [ $softver != "Linux" ]; then
        scrubDate="$(echo "$statusOutput" | grep "scan" | awk '{print $15"-"$12"-"$13"_"$14}')"
        scrubTS="$(date -j -f "%Y-%b-%e_%H:%M:%S" "$scrubDate" "+%s")"
   else
# For Linux
        scrubDate="$(echo "$statusOutput" | grep "scan" | awk '{print $12" "$13" "$15" "$14}')"
        scrubTS="$(date --date="$scrubDate" "+%s")"
   fi
        currentTS="$(date "+%s")"
        scrubAge=$((((currentTS - scrubTS) + 43200) / 86400))
        scrubTime="$(echo "$statusOutput" | grep "scan" | awk '{print $6}')"
       else
        #No scrub previously performed
        scrubAge="Never Scrubbed"
fi

fi

    # Set row's background color; alternates between white and $altColor (light gray)
    if [ $((poolNum % 2)) == 1 ]; then bgColor="#ffffff"; else bgColor="$altColor"; fi
    poolNum=$((poolNum + 1))
    # Set up conditions for warning or critical colors to be used in place of standard background colors
    if [ "$status" != "ONLINE" ]; then statusColor="$warnColor"; echo "$pool - Scrub Offline Error<br>" >> "$logfile_critical"; else statusColor="$bgColor"; fi
    if [ "$readErrors" != "0" ]; then readErrorsColor="$warnColor"; echo "$pool - Scrub Read Errors<br>" >> "$logfile_warning"; else readErrorsColor="$bgColor"; fi
    if [ "$writeErrors" != "0" ]; then writeErrorsColor="$warnColor"; echo "$pool - Scrub Write Errors<br>" >> "$logfile_warning"; else writeErrorsColor="$bgColor"; fi
    if [ "$cksumErrors" != "0" ]; then cksumErrorsColor="$warnColor"; echo "$pool - Scrub Cksum Errors<br>" >> "$logfile_warning"; else cksumErrorsColor="$bgColor"; fi
    if [ "$used" -gt "$usedWarn" ]; then usedColor="$warnColor"; echo "$pool - Scrub Used<br>" >> "$logfile_warning"; else usedColor="$bgColor"; fi
    if [ "$scrubRepBytes" != "$non_exist_value" ] && [ "$scrubRepBytes" != "0" ]; then scrubRepBytesColor="$warnColor"; echo "$pool - Scrub Rep Bytes<br>" >> "$logfile_warning"; else scrubRepBytesColor="$bgColor"; fi
    if [ "$scrubErrors" != "$non_exist_value" ] && [ "$scrubErrors" != "0" ]; then scrubErrorsColor="$warnColor"; echo "$pool - Scrub Errors<br>" >> "$logfile_critical"; else scrubErrorsColor="$bgColor"; fi
    if [ "$(echo "$scrubAge" | awk '{print int($1)}')" -gt "$scrubAgeWarn" ]; then scrubAgeColor="$warnColor"; echo "$pool - Scrub Age" >> "$logfile_warning"; else scrubAgeColor="$bgColor"; fi
    if [ "$scrubAge" == "In Progress" ]; then scrubAgeColor="$blueColor"; fi

if [[ $pool_capacity == "zfs" ]]; then
pool_size=$zfs_pool_size
pool_free=$zfs_pool_avail
used=$zfs_pool_used" ("$used"%)"
else
used=$used"%"  
fi
    (
        # Use the information gathered above to write the date to the current table row
        printf "<tr style=\"background-color:%s;\">
            <td style=\"text-align:center; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">%s</td>
            <td style=\"text-align:center; background-color:%s; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">%s</td>
            <td style=\"text-align:center; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">%s</td>
            <td style=\"text-align:center; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">%s</td>
            <td style=\"text-align:center; background-color:%s; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">%s</td>
            <td style=\"text-align:center; background-color:%s; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">%s</td>
            <td style=\"text-align:center; background-color:%s; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">%s</td>
            <td style=\"text-align:center; background-color:%s; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">%s</td>
            <td style=\"text-align:center; background-color:%s; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">%s</td>
            <td style=\"text-align:center; background-color:%s; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">%s</td>
            <td style=\"text-align:center; background-color:%s; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">%s</td>
            <td style=\"text-align:center; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">%s</td>
        </tr>\\n" "$bgColor" "$pool" "$statusColor" "$status" "$pool_size" "$pool_free" "$usedColor" "$used" "$readErrorsColor" "$readErrors" "$writeErrorsColor" "$writeErrors" "$cksumErrorsColor" \
        "$cksumErrors" "$scrubRepBytesColor" "$scrubRepBytes" "$scrubErrorsColor" "$scrubErrors" "$scrubAgeColor" "$scrubAge" "$scrubTime"
    ) >> "$logfile"
force_delay
done

# End of zpool status table
echo "</table>" >> "$logfile"
force_delay
if [[ $pool_capacity == "zfs" ]]; then
echo "<br><span style='color:gray;'>*Data obtained from zpool and zfs commands</span>" >> "$logfile"
force_delay
else
echo "<br><span style='color:gray;'>*Data obtained from zpool command</span>" >> "$logfile"
force_delay
fi
}

######################### GET DRIVE DATA #############################
get_drive_data () {

if [[ "$drive" == "nvme50" || "$drive" == "ada50" ]]; then
   smartdata="$(cat "$testfile")"
   echo "Modified smartdata="
   cat "$testfile"
else
   smartdata="$(smartctl -a /dev/"$drive")"
     if [[ "$dump_all" == "1" || "$dump_all" == "2" ]]; then
        "$(echo "$smartdata" > /tmp/drive_${drive}_a.txt)" 2> /dev/null
        "$(smartctl -x /dev/"$drive" > /tmp/drive_${drive}_x.txt)" 2> /dev/null
        if [[ ! -f "/tmp/drive_${drive}_a.txt" ]]; then echo "sleeping"; sleep 5; fi
     fi
   fi

   if [[ "$1" == "NON" ]]; then return; fi

   re='^[0-9]+$'
   ### For Min/Max Drive Temps
   if [[ "$(smartctl -x /dev/"$drive" | grep "Power Cycle Min/Max Temperature:" | awk '{print $5}' | cut -d '/' -f1)" != "?" ]]; then
      temp_min=$(smartctl -x /dev/"$drive" | grep "Power Cycle Min/Max Temperature:" | awk '{print $5}' | cut -d '/' -f1); else temp_min=$non_exist_value; fi

   if [[ "$(smartctl -x /dev/"$drive" | grep "Power Cycle Min/Max Temperature:" | awk '{print $5}' | cut -d '/' -f2)" != "?" ]]; then
      temp_max=$(smartctl -x /dev/"$drive" | grep "Power Cycle Min/Max Temperature:" | awk '{print $5}' | cut -d '/' -f2); else temp_max=$non_exist_value; fi

   if [[ "$(smartctl -x /dev/"$drive" | grep "Current Temperature:" | awk '{print $3}' | cut -d '/' -f2)" != "?" ]]; then
      temp=$(smartctl -x /dev/"$drive" | grep "Current Temperature:" | awk '{print $3}' | cut -d '/' -f2); else temp=$non_exist_value; fi

   ### NEW CODE TO PULL MIN/MAX TEMPS
   if [[ "$temp_min" == "" ]] && [[ "$temp_max" == "" ]]; then
      if [[ "$(echo "$smartdata" | grep "Temperature" | awk '{print $11}')" == "(Min/Max" ]]; then
         temp_play="$(echo "$smartdata" | grep "Temperature" | awk '{print $12}')"
         temp_min="$(echo "$temp_play" | cut -d '/' -f1)"
         temp_max="$(echo "$temp_play" | cut -d '/' -f2 | cut -d ')' -f1)"
      fi
   fi
   ### SETUP FOR NO VALUE OBTAINED
   tempdisplaymin=$tempdisplay
   tempdisplaymax=$tempdisplay
   if ! [[ $temp_min =~ $re ]]; then temp_min=$non_exist_value; tempdisplaymin=""; fi
   if ! [[ $temp_max =~ $re ]]; then temp_max=$non_exist_value; tempdisplaymax=""; fi

   sas=0
   if [[ "$(echo "$smartdata" | grep "SAS")" ]]; then sas=1; fi

   if [[ "$(echo "$smartdata" | grep "remaining" | awk '{print $1}')" ]]; then
      smarttesting="$(echo "$smartdata" | grep "remaining" | awk '{print $1}' | tr -d '[%]')"; fi

   if [[ "$(echo "$smartdata" | grep "# 1" | awk '{print $5}')" ]]; then
      chkreadfailure="$(echo "$smartdata" | grep "# 1" | awk '{print $5}')"; fi

   if [[ "$sas" == 0 ]]; then
      if [[ "$(echo "$smartdata" | grep "# 1" | awk '{print $9}')" =~ [%]+$ ]]; then
         lastTestHours="$(echo "$smartdata" | grep "# 1" | awk '{print $10}' )"
      else
         if [[ "$(echo "$smartdata" | grep "# 1" | awk '{print $9}')" ]]; then
         lastTestHours="$(echo "$smartdata" | grep "# 1" | awk '{print $9}' )"
      fi
   fi
fi

if [[ "$(echo "$smartdata" | grep "# 1" | awk '{print $3}')" ]]; then
   lastTestType="$(echo "$smartdata" | grep "# 1" | awk '{print $3}')"; fi

if [[ "$(echo "$smartdata" | grep "SMART overall-health" | awk '{print $6}')" ]]; then
   smartStatus="$(echo "$smartdata" | grep "SMART overall-health" | awk '{print $6}')"; fi

if [[ "$(echo "$smartdata" | grep "SMART Health Status" | awk '{print $4}')" ]]; then
   smartStatus="$(echo "$smartdata" | grep "SMART Health Status" | awk '{print $4}' | tr -d '[:space:]')"; fi

if [[ "$(echo "$smartdata" | grep "Serial number:" | awk '{print $3}')" ]]; then
   serial="$(echo "$smartdata" | grep "Serial number:" | awk '{print $3}')"; fi

if [[ "$(echo "$smartdata" | grep "Serial Number" | awk '{print $3}')" ]]; then
   serial="$(echo "$smartdata" | grep "Serial Number" | awk '{print $3}')"; fi

if [[ "$(echo "$smartdata" | grep "Airflow" | awk '{print $10}')" ]]; then
   temp="$(echo "$smartdata" | grep "Airflow" | awk '{print $10 + 0}')"; fi

if [[ "$(echo "$smartdata" | grep "Temperature_Case" | awk '{print $10}')" ]]; then
   temp="$(echo "$smartdata" | grep "Temperature_Case" | awk '{print $10}')"; fi

if [[ "$(echo "$smartdata" | grep "Temperature_Celsius" | awk '{print $10}')" ]]; then
   temp="$(echo "$smartdata" | grep "Temperature_Celsius" | awk '{print $10 + 0}')"; fi

if [[ "$sas" == 0 ]]; then
   if [[ "$(echo "$smartdata" | grep "Temperature:" | awk '{print $2}')" ]]; then
      temp="$(echo "$smartdata" | grep "Temperature:" | awk '{print $2 + 0}')"; fi
fi

if [[ "$(echo "$smartdata" | grep "Power_On_Hours" | awk '{print $10}')" ]]; then
   onHours="$(echo "$smartdata" | grep "Power_On_Hours" | awk '{print $10}' | cut -d 'h' -f1)"; fi

if [[ "$(echo "$smartdata" | grep "Power On Hours" | awk '{print $4}')" ]]; then
   onHours="$(echo "$smartdata" | grep "Power On Hours" | awk '{print $4}')"; fi

if [[ "$(echo "$smartdata" | grep "Start_Stop_Count" | awk '{print $10}')" ]]; then
   startStop="$(echo "$smartdata" | grep "Start_Stop_Count" | awk '{print $10}')"; fi

if [[ "$(echo "$smartdata" | grep "Spin_Retry_Count" | awk '{print $10}')" ]]; then
   spinRetry="$(echo "$smartdata" | grep "Spin_Retry_Count" | awk '{print $10 + 0}')"; fi

if [[ "$(echo "$smartdata" | grep "Reallocated_Sector" | awk '{print $10}')" ]]; then
   reAlloc="$(echo "$smartdata" | grep "Reallocated_Sector" | awk '{print $10}')"; fi

if [[ "$(echo "$smartdata" | grep "Reallocated_Event_Count" | awk '{print $10}')" ]]; then
   reAllocEvent="$(echo "$smartdata" | grep "Reallocated_Event_Count" | awk '{print $10}')"; fi

if [[ "$(echo "$smartdata" | grep "Current_Pending_Sector" | awk '{print $10}')" ]]; then
   pending="$(echo "$smartdata" | grep "Current_Pending_Sector" | awk '{print $10}')"; fi

if [[ "$(echo "$smartdata" | grep "Offline_Uncorrectable" | awk '{print $10}')" ]]; then
   offlineUnc="$(echo "$smartdata" | grep "Offline_Uncorrectable" | awk '{print $10}')"; fi

if [[ "$(echo "$smartdata" | grep "Uncorrectable_Error_Cnt" | awk '{print $10}')" ]]; then
   offlineUnc="$(echo "$smartdata" | grep "Uncorrectable_Error_Cnt" | awk '{print $10}')"; fi

if [[ "$(echo "$smartdata" | grep "UDMA_CRC_Error_Count" | awk '{print $10}')" ]]; then
   crcErrors="$(echo "$smartdata" | grep "UDMA_CRC_Error_Count" | awk '{print $10 + 0}')"; fi

if [[ "$(echo "$smartdata" | grep "CRC_Error_Count" | awk '{print $10}')" ]]; then
   crcErrors="$(echo "$smartdata" | grep "CRC_Error_Count" | awk '{print $10}')"; fi

if [[ "$(echo "$smartdata" | grep "Seek_Error_Rate" | awk '{print $4}')" ]]; then
   seekErrorHealth2="$(echo "$smartdata" | grep "Seek_Error_Rate" | awk '{print $4 + 0}')"; fi

if [[ "$(echo "$smartdata" | grep "Seek_Error_Rate" | awk '{print $10}')" ]]; then
   seekErrorHealth="$(echo "$smartdata" | grep "Seek_Error_Rate" | awk '{print $10 + 0}')"; fi

if [[ "$(echo "$smartdata" | grep "Raw_Read_Error_Rate" | awk '{print $4}')" ]]; then
   rawReadErrorRate2="$(echo "$smartdata" | grep "Raw_Read_Error_Rate" | head -1 | awk '{print $4 + 0}')"; fi

if [[ "$(echo "$smartdata" | grep "Raw_Read_Error_Rate" | awk '{print $10}')" ]]; then
   rawReadErrorRate="$(echo "$smartdata" | grep "Raw_Read_Error_Rate" | head -1 | awk '{print $10 + 0}')"; fi

### Add search for Seagate and mark seagate=1
if [[ "$(echo "$smartdata" | grep -i "Seagate" )" ]]; then seagate=1; else seagate=""; fi

if [[ "$(echo "$smartdata" | grep "Load_Cycle_Count" | awk '{print $10}')" ]]; then
   loadCycle="$(echo "$smartdata" | grep "Load_Cycle_Count" | awk '{print $10}')"; fi

if [[ "$(echo "$smartdata" | grep "Multi_Zone_Error_Rate" | awk '{print $10}')" ]]; then
   multiZone="$(echo "$smartdata" | grep "Multi_Zone_Error_Rate" | awk '{print $10 + 0}')"; fi

if [[ "$(echo "$smartdata" | grep "Phison")" ]]; then
if [[ "$(echo "$smartdata" | grep "SSD_Life_Left" | awk '{print $10}')" ]]; then
   wearLevel="$(echo "$smartdata" | grep "SSD_Life_Left" | awk '{print $10 + 0}')"; fi
fi

if [[ ! "$(echo "$smartdata" | grep "Phison")" ]]; then
   if [[ "$(echo "$smartdata" | grep "SSD_Life_Left" | awk '{print $4}')" ]]; then
      wearLevel="$(echo "$smartdata" | grep "SSD_Life_Left" | awk '{print $4 + 0}')"; fi
fi

if [[ "$(echo "$smartdata" | grep "Wear_Leveling_Count" | awk '{print $4}')" ]]; then
   wearLevel="$(echo "$smartdata" | grep "Wear_Leveling_Count" | awk '{print $4 + 0}')"; fi

if [[ "$(echo "$smartdata" | grep "Percent_Lifetime_Remain" | awk '{print $4}')" ]]; then
   wearLevel="$(echo "$smartdata" | grep "Percent_Lifetime_Remain" | awk '{print $4 + 0}')"; fi

if [[ "$(echo "$smartdata" | grep "Media_Wearout_Indicator" | awk '{print $4}')" ]]; then
   wearLevel="$(echo "$smartdata" | grep "Media_Wearout_Indicator" | awk '{print $4 + 0}')"; fi

if [[ "$(echo "$smartdata" | grep "Percentage Used:" | awk '{print $3}')" ]]; then
   wearLevel="$(echo "$smartdata" | grep "Percentage Used:" | awk '{print $3 + 0}')"
   wearLevel=$(( 100 - $wearLevel ))
fi

if [[ "$(echo "$smartdata" | grep "Percentage used endurance indicator:" | awk '{print $5}')" ]]; then
   wearLevel="$(echo "$smartdata" | grep "Percentage used endurance indicator:" | awk '{print $5}' | cut -d '%' -f1)"
   # Adjusting Wear Level for amount used vice amount remaining #
   wearLevel=$(( 100 - $wearLevel ))
fi

if [[ "$(echo "$smartdata" | grep "Reallocated_NAND_Blk_Cnt" | awk '{print $10}')" ]]; then
   reAlloc="$(echo "$smartdata" | grep "Reallocated_NAND_Blk_Cnt" | awk '{print $10}')"; fi

if [[ "$(echo "$smartdata" | grep "Current Drive Temperature:" | awk '{print $4}')" ]]; then
   temp="$(echo "$smartdata" | grep "Current Drive Temperature:" | awk '{print $4 + 0}')"; fi

if [[ "$(echo "$smartdata" | grep "Accumulated start-stop cycles:" | awk '{print $4}')" ]]; then
   startStop="$(echo "$smartdata" | grep "Accumulated start-stop cycles:" | awk '{print $4 + 0}')"; fi

if [[ "$(echo "$smartdata" | grep "Accumulated load-unload cycles:" | awk '{print $4}')" ]]; then
   loadCycle="$(echo "$smartdata" | grep "Accumulated load-unload cycles:" | awk '{print $4}')"; fi

if [[ "$(echo "$smartdata" | grep "Elements in grown defect list:" | awk '{print $6}')" == '^[0-9]+$' ]]; then
   reAlloc="$(echo "$smartdata" | grep "Elements in grown defect list:" | awk '{print $6}')"; fi

if [[ "$(echo "$smartdata" | grep "Accumulated power on time" | awk '{print $6}' | cut -d ":" -f1)" ]]; then
   onHours="$(echo "$smartdata" | grep "Accumulated power on time" | awk '{print $6}' | cut -d ":" -f1)"; fi

if [[ "$(echo "$smartdata" | grep "Rotation" | awk '{print $3}')" ]]; then
   rotation="$(echo "$smartdata" | grep "Rotation" | awk '{print $3}')"; fi

if [[ "$(echo "$smartdata" | grep "Device Model" | awk '{print $3 " " $4 " " $5 " " $6 " " $7}')" ]]; then
   modelnumber="$(echo "$smartdata" | grep "Device Model" | awk '{print $3 " " $4 " " $5 " " $6 " " $7}')"; fi

if [[ "$(echo "$smartdata" | grep "Model Number:" | awk '{print $3 " " $4 " " $5 " " $6 " " $7}')" ]]; then
   modelnumber="$(echo "$smartdata" | grep "Model Number:" | awk '{print $3 " " $4 " " $5 " " $6 " " $7}')"; fi

if [[ "$(echo "$smartdata" | grep "Product:" | awk '{print $2}')" ]]; then
   modelnumber="$(echo "$smartdata" | grep "Product:" | awk '{print $2}')"; fi

if [[ "$(echo "$smartdata" | grep "User Capacity" | awk '{print $5 $6}')" ]]; then
   capacity="$(echo "$smartdata" | grep "User Capacity" | awk '{print $5 $6}')"; fi

if [[ "$(echo "$smartdata" | grep "Namespace 1 Size" | awk '{print $5 $6}')" ]]; then
   capacity="$(echo "$smartdata" | grep "Namespace 1 Size" | awk '{print $5 $6}')"; fi

if [[ "$(echo "$smartdata" | grep "Critical Warning:" | awk '{print $3}')" ]]; then
   NVMcriticalWarning="$(echo "$smartdata" | grep "Critical Warning:" | awk '{print $3}')"; fi

if [[ "$(echo "$smartdata" | grep "Helium_Level" | awk '{print $10}')" ]]; then
   Helium="$(echo "$smartdata" | grep "Helium_Level" | awk '{print $10 + 0}')"; fi

if [[ "$(echo "$smartdata" | grep "22 Unknown_Attribute" | awk '{print $10}')" ]]; then
   if [[ "$Helium" == "" ]]; then Helium="$(echo "$smartdata" | grep "22 Unknown_Attribute" | awk '{print $10}')"; fi; fi

# Added Helium check for Toshiba MG07+ drives
if [[ "$(echo "$smartdata" | grep "23 Unknown_Attribute" | awk '{print $4}')" ]]; then
   if [[ "$Helium" == "" ]]; then Helium="$(echo "$smartdata" | grep "23 Unknown_Attribute" | awk '{print $4}')"; fi; fi

if [[ "$(echo "$smartdata" | grep "Background" | awk '{print $10}')" ]]; then
   lastTestHours="$(echo "$smartdata" | grep "Background" | awk '{print $10}')"; fi

if [[ "$(echo "$smartdata" | grep "# 1" | awk '{print $7}')" ]]; then
   altlastTestHours="$(echo "$smartdata" | grep "# 1" | awk '{print $7}')"; fi

if [[ "$sas" == 1 ]]; then
   lastTestHours="$(echo "$smartdata" | grep "# 1" | awk '{print $7}')"; fi

if [[ "$(echo "$smartdata" | grep "# 1" | awk '{print $4}')" ]]; then
   altlastTestType="$(echo "$smartdata" | grep "# 1" | awk '{print $4}')"; fi

if [[ "$sas" == 1 ]]; then
   if [[ "$(echo "$smartdata" | grep "# 1" | awk '{print $4}')" ]]; then
   lastTestType="$(echo "$smartdata" | grep "# 1" | awk '{print $4}')"; fi
fi

if [[ ! "$(echo "$smartdata" | grep "SSD")" && ! "$(echo "$smartdata" | grep "NVM")" ]]; then
   Custom_DrivesDrive="HDD"
fi

if [[ "$(echo "$smartdata" | grep "Solid State")" ]]; then
   Custom_DrivesDrive="SSD"
fi

if [[ "$(echo "$smartdata" | grep "NVM")" ]]; then
   Custom_DrivesDrive="NVM"
fi

if [[ $Sample_Test == "true" ]]; then
temp_min=10
temp_max=50
temp=35
spinRetry=2
reAllocEvent=2
pending=5
offlineUnc=3
crcErrors=2
seekErrorHealth=1
seekErrorRate=10
rawReadErrorRate=8
multiZone=2
wearLevel=20
startStop=490
loadCycle=500
reAlloc=5
onHours=50026
Helium=100
lastTestHours=50000
fi


######### Convert variables to Decimal #########

if [[ "$temp_min" != "" ]] && [[ "$temp_min" != "0" ]] && [[ "$temp_min" != "$non_exist_value" ]]; then convert_to_decimal $temp_min; temp_min=$Return_Value; fi
if [[ "$temp_max" != "" ]] && [[ "$temp_max" != "0" ]] && [[ "$temp_max" != "$non_exist_value" ]]; then convert_to_decimal $temp_max; temp_max=$Return_Value; fi
if [[ "$temp" != "" ]] && [[ "$temp" != "0" ]] && [[ "$temp" != "$non_exist_value" ]]; then convert_to_decimal $temp; temp=$Return_Value; fi
if [[ "$spinRetry" != "" ]] && [[ "$spinRetry" != "0" ]]; then convert_to_decimal $spinRetry; spinRetry=$Return_Value; fi
if [[ "$reAllocEvent" != "" ]] && [[ "$reAllocEvent" != "0" ]]; then convert_to_decimal $reAllocEvent; reAllocEvent=$Return_Value; fi
if [[ "$pending" != "" ]] && [[ "$pending" != "0" ]]; then convert_to_decimal $pending; pending=$Return_Value; fi
if [[ "$offlineUnc" != "" ]] && [[ "$offlineUnc" != "0" ]]; then convert_to_decimal $offlineUnc; offlineUnc=$Return_Value; fi
if [[ "$crcErrors" != "" ]] && [[ "$crcErrors" != "0" ]]; then convert_to_decimal $crcErrors; crcErrors=$Return_Value; fi
if [[ "$seekErrorHealth2" != "" ]] && [[ "$seekErrorHealth2" != "0" ]]; then convert_to_decimal $seekErrorHealth2; seekErrorHealth2=$Return_Value; fi
if [[ "$seekErrorHealth" != "" ]] && [[ "$seekErrorHealth" != "0" ]]; then convert_to_decimal $seekErrorHealth; seekErrorHealth=$Return_Value; fi
if [[ "$rawReadErrorRate2" != "" ]] && [[ "$rawReadErrorRate2" != "0" ]]; then convert_to_decimal $rawReadErrorRate2; rawReadErrorRate2=$Return_Value; fi
if [[ "$rawReadErrorRate" != "" ]] && [[ "$rawReadErrorRate" != "0" ]]; then convert_to_decimal $rawReadErrorRate; rawReadErrorRate=$Return_Value; fi
if [[ "$multiZone" != "" ]] && [[ "$multiZone" != "0" ]]; then convert_to_decimal $multiZone; multiZone=$Return_Value; fi
if [[ "$wearLevel" != "" ]] && [[ "$wearLevel" != "0" ]]; then convert_to_decimal $wearLevel; wearLevel=$Return_Value; fi
if [[ "$temp" != "" ]] && [[ "$temp" != "0" ]]; then convert_to_decimal $temp; temp=$Return_Value; fi
if [[ "$startStop" != "" ]] && [[ "$startStop" != "0" ]]; then convert_to_decimal $startStop; startStop=$Return_Value; fi
if [[ "$loadCycle" != "" ]] && [[ "$loadCycle" != "0" ]]; then convert_to_decimal $loadCycle; loadCycle=$Return_Value; fi
if [[ "$reAlloc" != "" ]] && [[ "$reAlloc" != "0" ]]; then convert_to_decimal $reAlloc; reAlloc=$Return_Value; fi
if [[ "$onHours" != "" ]] && [[ "$onHours" != "0" ]]; then convert_to_decimal $onHours; onHours=$Return_Value; fi
if [[ "$Helium" != "" ]] && [[ "$Helium" != "0" ]]; then convert_to_decimal $Helium; Helium=$Return_Value; fi
lastTestHours="$(echo $lastTestHours | tr -d "()%/")"
if [[ "$lastTestHours" != "" ]] && [[ "$lastTestHours" != "0" ]]; then convert_to_decimal $lastTestHours; lastTestHours=$Return_Value; fi
altlastTestHours="$(echo $altlastTestHours | tr -d "()%/")"
if [[ "$altlastTestHours" -gt "0" ]]; then convert_to_decimal $altlastTestHours; altlastTestHours=$Return_Value; fi

# Some drives do not report test age after 65536 hours.
if [[ $onHours -gt "65536" ]] && [[ $lastTestHours -gt "0" && $lastTestHours -lt "65536" ]]; then lastTestHours=$(($lastTestHours + 65536)); fi

######## VMWare Hack to fix NVMe bad variables #####
if [[ "$VMWareNVME" == "on" ]]; then
if [[ "$serial" == "VMWare" ]]; then
onHours="17,200"
wearLevel="98"
temp="38"
temp_min="20"
temp_max="43"
fi
fi

}

########################## GET TIMESTAMP ######################
get_timestamp () {

# I Want Milliseconds Resolution represented for timestamp, FreeBSD does not support it ################################

if [[ $softver != "Linux" ]]; then 
  timestamp=$(date +%T)
else
  timestamp=$(date +"%T.%2N")
fi

datestamp=$(date +%Y/%m/%d)

}

################################## GENERATE TABLE ########################################################
# Call function with generate_table "HDD|SSD|NVM"

generate_table () {

detail_level="$1"

# Lets add up how many columns we will need.
if [[ "$Drive_Warranty" == "none" || "$Drive_Warranty" == "" ]]; then
   HDD_Warranty="false"
   SSD_Warranty="false"
   NVM_Warranty="false"
fi
Columns=0;
if [[ "$1" == "HDD" ]] && [[ "$HDD_Device_ID" == "true" ]]; then ((Columns=Columns+1)); fi;
if [[ "$1" == "HDD" ]] && [[ "$HDD_Serial_Number" == "true" ]]; then ((Columns=Columns+1)); fi;
if [[ "$1" == "HDD" ]] && [[ "$HDD_Model_Number" == "true" ]]; then ((Columns=Columns+1)); fi;
if [[ "$1" == "HDD" ]] && [[ "$HDD_Capacity" == "true" ]]; then ((Columns=Columns+1)); fi;
if [[ "$1" == "HDD" ]] && [[ "$HDD_Rotational_Rate" == "true" ]]; then ((Columns=Columns+1)); fi;
if [[ "$1" == "HDD" ]] && [[ "$HDD_SMART_Status" == "true" ]]; then ((Columns=Columns+1)); fi;
if [[ "$1" == "HDD" ]] && [[ "$HDD_Warranty" == "true" ]]; then ((Columns=Columns+1)); fi;
if [[ "$1" == "HDD" ]] && [[ "$HDD_Drive_Temp" == "true" ]]; then ((Columns=Columns+1)); fi;
if [[ "$1" == "HDD" ]] && [[ "$HDD_Drive_Temp_Min" == "true" ]]; then ((Columns=Columns+1)); fi;
if [[ "$1" == "HDD" ]] && [[ "$HDD_Drive_Temp_Max" == "true" ]]; then ((Columns=Columns+1)); fi;
if [[ "$1" == "HDD" ]] && [[ "$HDD_Power_On_Hours" == "true" ]]; then ((Columns=Columns+1)); fi;
if [[ "$1" == "HDD" ]] && [[ "$HDD_Start_Stop_Count" == "true" ]]; then ((Columns=Columns+1)); fi;
if [[ "$1" == "HDD" ]] && [[ "$HDD_Load_Cycle" == "true" ]]; then ((Columns=Columns+1)); fi;
if [[ "$1" == "HDD" ]] && [[ "$HDD_Spin_Retry" == "true" ]]; then ((Columns=Columns+1)); fi;
if [[ "$1" == "HDD" ]] && [[ "$HDD_Reallocated_Sectors" == "true" ]]; then ((Columns=Columns+1)); fi;
if [[ "$1" == "HDD" ]] && [[ "$HDD_Reallocated_Events" == "true" ]]; then ((Columns=Columns+1)); fi;
if [[ "$1" == "HDD" ]] && [[ "$HDD_Pending_Sectors" == "true" ]]; then ((Columns=Columns+1)); fi;
if [[ "$1" == "HDD" ]] && [[ "$HDD_Offline_Uncorrectable" == "true" ]]; then ((Columns=Columns+1)); fi;
if [[ "$1" == "HDD" ]] && [[ "$HDD_UDMA_CRC_Errors" == "true" ]]; then ((Columns=Columns+1)); fi;
if [[ "$1" == "HDD" ]] && [[ "$HDD_Raw_Read_Error_Rate" == "true" ]]; then ((Columns=Columns+1)); fi;
if [[ "$1" == "HDD" ]] && [[ "$HDD_Seek_Error_Rate" == "true" ]]; then ((Columns=Columns+1)); fi;
if [[ "$1" == "HDD" ]] && [[ "$HDD_MultiZone_Errors" == "true" ]]; then ((Columns=Columns+1)); fi;
if [[ "$1" == "HDD" ]] && [[ "$HDD_Helium_Level" == "true" ]]; then ((Columns=Columns+1)); fi;
if [[ "$1" == "HDD" ]] && [[ "$HDD_Last_Test_Age" == "true" ]]; then ((Columns=Columns+1)); fi;
if [[ "$1" == "HDD" ]] && [[ "$HDD_Last_Test_Type" == "true" ]]; then ((Columns=Columns+1)); fi;

# Count for SSD
if [[ "$1" == "SSD" ]] && [[ "$SSD_Device_ID" == "true" ]]; then ((Columns=Columns+1)); fi;
if [[ "$1" == "SSD" ]] && [[ "$SSD_Serial_Number" == "true" ]]; then ((Columns=Columns+1)); fi;
if [[ "$1" == "SSD" ]] && [[ "$SSD_Model_Number" == "true" ]]; then ((Columns=Columns+1)); fi;
if [[ "$1" == "SSD" ]] && [[ "$SSD_Capacity" == "true" ]]; then ((Columns=Columns+1)); fi;
if [[ "$1" == "SSD" ]] && [[ "$SSD_SMART_Status" == "true" ]]; then ((Columns=Columns+1)); fi;
if [[ "$1" == "SSD" ]] && [[ "$SSD_Warranty" == "true" ]]; then ((Columns=Columns+1)); fi;
if [[ "$1" == "SSD" ]] && [[ "$SSD_Drive_Temp" == "true" ]]; then ((Columns=Columns+1)); fi;
if [[ "$1" == "SSD" ]] && [[ "$SSD_Drive_Temp_Min" == "true" ]]; then ((Columns=Columns+1)); fi;
if [[ "$1" == "SSD" ]] && [[ "$SSD_Drive_Temp_Max" == "true" ]]; then ((Columns=Columns+1)); fi;
if [[ "$1" == "SSD" ]] && [[ "$SSD_Power_On_Hours" == "true" ]]; then ((Columns=Columns+1)); fi;
if [[ "$1" == "SSD" ]] && [[ "$SSD_Wear_Level" == "true" ]]; then ((Columns=Columns+1)); fi;
if [[ "$1" == "SSD" ]] && [[ "$SSD_Reallocated_Sectors" == "true" ]]; then ((Columns=Columns+1)); fi;
if [[ "$1" == "SSD" ]] && [[ "$SSD_Reallocated_Events" == "true" ]]; then ((Columns=Columns+1)); fi;
if [[ "$1" == "SSD" ]] && [[ "$SSD_Pending_Sectors" == "true" ]]; then ((Columns=Columns+1)); fi;
if [[ "$1" == "SSD" ]] && [[ "$SSD_Offline_Uncorrectable" == "true" ]]; then ((Columns=Columns+1)); fi;
if [[ "$1" == "SSD" ]] && [[ "$SSD_UDMA_CRC_Errors" == "true" ]]; then ((Columns=Columns+1)); fi;
if [[ "$1" == "SSD" ]] && [[ "$SSD_Last_Test_Age" == "true" ]]; then ((Columns=Columns+1)); fi;
if [[ "$1" == "SSD" ]] && [[ "$SSD_Last_Test_Type" == "true" ]]; then ((Columns=Columns+1)); fi;

# Count for NVMe
if [[ "$1" == "NVM" ]] && [[ "$NVM_Device_ID" == "true" ]]; then ((Columns=Columns+1)); fi;
if [[ "$1" == "NVM" ]] && [[ "$NVM_Serial_Number" == "true" ]]; then ((Columns=Columns+1)); fi;
if [[ "$1" == "NVM" ]] && [[ "$NVM_Model_Number" == "true" ]]; then ((Columns=Columns+1)); fi;
if [[ "$1" == "NVM" ]] && [[ "$NVM_Capacity" == "true" ]]; then ((Columns=Columns+1)); fi;
if [[ "$1" == "NVM" ]] && [[ "$NVM_SMART_Status" == "true" ]]; then ((Columns=Columns+1)); fi;
if [[ "$1" == "NVM" ]] && [[ "$NVM_Warranty" == "true" ]]; then ((Columns=Columns+1)); fi;
if [[ "$1" == "NVM" ]] && [[ "$NVM_Critical_Warning" == "true" ]]; then ((Columns=Columns+1)); fi;
if [[ "$1" == "NVM" ]] && [[ "$NVM_Drive_Temp" == "true" ]]; then ((Columns=Columns+1)); fi;
if [[ "$1" == "NVM" ]] && [[ "$NVM_Drive_Temp_Min" == "true" ]]; then ((Columns=Columns+1)); fi;
if [[ "$1" == "NVM" ]] && [[ "$NVM_Drive_Temp_Max" == "true" ]]; then ((Columns=Columns+1)); fi;
if [[ "$1" == "NVM" ]] && [[ "$NVM_Power_On_Hours" == "true" ]]; then ((Columns=Columns+1)); fi;
if [[ "$1" == "NVM" ]] && [[ "$NVM_Wear_Level" == "true" ]]; then ((Columns=Columns+1)); fi;

(
    # Write HTML table headers to log file
    echo "<br><br>"
    echo "<table style=\"border: 1px solid black; border-collapse: collapse;\">"
    if [[ "$1" == "HDD" ]]; then echo "<tr><th colspan=\"$Columns\" style=\"text-align:center; font-size:20px; height:40px; font-family:courier;\">"$HDDreportTitle"</th></tr>"; fi
    if [[ "$1" == "SSD" ]]; then echo "<tr><th colspan=\"$Columns\" style=\"text-align:center; font-size:20px; height:40px; font-family:courier;\">"$SSDreportTitle"</th></tr>"; fi
    if [[ "$1" == "NVM" ]]; then echo "<tr><th colspan=\"$Columns\" style=\"text-align:center; font-size:20px; height:40px; font-family:courier;\">"$NVMreportTitle"</th></tr>"; fi
    echo "<tr>"

    if [[ "$1" == "HDD" ]] && [[ "$HDD_Device_ID" == "true" ]]; then echo "  <th style=\"text-align:center; width:100px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$HDD_Device_ID_Title"</th>"; fi
    if [[ "$1" == "SSD" ]] && [[ "$SSD_Device_ID" == "true" ]]; then echo "  <th style=\"text-align:center; width:100px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$SSD_Device_ID_Title"</th>"; fi
    if [[ "$1" == "NVM" ]] && [[ "$NVM_Device_ID" == "true" ]]; then echo "  <th style=\"text-align:center; width:100px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$NVM_Device_ID_Title"</th>"; fi

    if [[ "$1" == "HDD" ]] && [[ "$HDD_Serial_Number" == "true" ]]; then echo "  <th style=\"text-align:center; width:130px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$HDD_Serial_Number_Title"</th>"; fi
    if [[ "$1" == "SSD" ]] && [[ "$SSD_Serial_Number" == "true" ]]; then echo "  <th style=\"text-align:center; width:130px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$SSD_Serial_Number_Title"</th>"; fi
    if [[ "$1" == "NVM" ]] && [[ "$NVM_Serial_Number" == "true" ]]; then echo "  <th style=\"text-align:center; width:130px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$NVM_Serial_Number_Title"</th>"; fi

    if [[ "$1" == "HDD" ]] && [[ "$HDD_Model_Number" == "true" ]]; then echo "  <th style=\"text-align:center; width:100px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$HDD_Model_Number_Title"</th>"; fi
    if [[ "$1" == "SSD" ]] && [[ "$SSD_Model_Number" == "true" ]]; then echo "  <th style=\"text-align:center; width:100px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$SSD_Model_Number_Title"</th>"; fi
    if [[ "$1" == "NVM" ]] && [[ "$NVM_Model_Number" == "true" ]]; then echo "  <th style=\"text-align:center; width:100px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$NVM_Model_Number_Title"</th>"; fi

    if [[ "$1" == "HDD" ]] && [[ "$HDD_Capacity" == "true" ]]; then echo "  <th style=\"text-align:center; width:100px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$HDD_Capacity_Title"</th>"; fi
    if [[ "$1" == "SSD" ]] && [[ "$SSD_Capacity" == "true" ]]; then echo "  <th style=\"text-align:center; width:100px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$SSD_Capacity_Title"</th>"; fi
    if [[ "$1" == "NVM" ]] && [[ "$NVM_Capacity" == "true" ]]; then echo "  <th style=\"text-align:center; width:100px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$NVM_Capacity_Title"</th>"; fi

    if [[ "$1" == "HDD" ]] && [[ "$HDD_Rotational_Rate" == "true" ]]; then echo "  <th style=\"text-align:center; width:100px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$HDD_Rotational_Rate_Title"</th>"; fi

    if [[ "$1" == "HDD" ]] && [[ "$HDD_SMART_Status" == "true" ]]; then echo "  <th style=\"text-align:center; width:80px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$HDD_SMART_Status_Title"</th>"; fi
    if [[ "$1" == "SSD" ]] && [[ "$SSD_SMART_Status" == "true" ]]; then echo "  <th style=\"text-align:center; width:80px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$SSD_SMART_Status_Title"</th>"; fi
    if [[ "$1" == "NVM" ]] && [[ "$NVM_SMART_Status" == "true" ]]; then echo "  <th style=\"text-align:center; width:80px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$NVM_SMART_Status_Title"</th>"; fi

    if [[ "$1" == "HDD" ]] && [[ "$HDD_Warranty" == "true" ]]; then echo "  <th style=\"text-align:center; width:80px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$HDD_Warranty_Title"</th>"; fi
    if [[ "$1" == "SSD" ]] && [[ "$SSD_Warranty" == "true" ]]; then echo "  <th style=\"text-align:center; width:80px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$SSD_Warranty_Title"</th>"; fi
    if [[ "$1" == "NVM" ]] && [[ "$NVM_Warranty" == "true" ]]; then echo "  <th style=\"text-align:center; width:80px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$NVM_Warranty_Title"</th>"; fi

    if [[ "$1" == "NVM" ]] && [[ "$NVM_Critical_Warning" == "true" ]]; then echo "  <th style=\"text-align:center; width:80px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$NVM_Critical_Warning_Title"</th>"; fi

    if [[ "$1" == "HDD" ]] && [[ "$HDD_Drive_Temp" == "true" ]]; then echo "  <th style=\"text-align:center; width:80px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$HDD_Drive_Temp_Title"</th>"; fi
    if [[ "$1" == "SSD" ]] && [[ "$SSD_Drive_Temp" == "true" ]]; then echo "  <th style=\"text-align:center; width:80px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$SSD_Drive_Temp_Title"</th>"; fi
    if [[ "$1" == "NVM" ]] && [[ "$NVM_Drive_Temp" == "true" ]]; then echo "  <th style=\"text-align:center; width:80px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$NVM_Drive_Temp_Title"</th>"; fi

    if [[ "$1" == "HDD" ]] && [[ "$HDD_Drive_Temp_Min" == "true" ]]; then echo "  <th style=\"text-align:center; width:80px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$HDD_Drive_Temp_Min_Title"</th>"; fi
    if [[ "$1" == "SSD" ]] && [[ "$SSD_Drive_Temp_Min" == "true" ]]; then echo "  <th style=\"text-align:center; width:80px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$SSD_Drive_Temp_Min_Title"</th>"; fi
    if [[ "$1" == "NVM" ]] && [[ "$NVM_Drive_Temp_Min" == "true" ]]; then echo "  <th style=\"text-align:center; width:80px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$NVM_Drive_Temp_Min_Title"</th>"; fi

    if [[ "$1" == "HDD" ]] && [[ "$HDD_Drive_Temp_Max" == "true" ]]; then echo "  <th style=\"text-align:center; width:80px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$HDD_Drive_Temp_Max_Title"</th>"; fi
    if [[ "$1" == "SSD" ]] && [[ "$SSD_Drive_Temp_Max" == "true" ]]; then echo "  <th style=\"text-align:center; width:80px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$SSD_Drive_Temp_Max_Title"</th>"; fi
    if [[ "$1" == "NVM" ]] && [[ "$NVM_Drive_Temp_Max" == "true" ]]; then echo "  <th style=\"text-align:center; width:80px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$NVM_Drive_Temp_Max_Title"</th>"; fi

    if [[ "$1" == "HDD" ]] && [[ "$HDD_Power_On_Hours" == "true" ]]; then echo "  <th style=\"text-align:center; width:120px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$HDD_Power_On_Hours_Title"</th>"; fi
    if [[ "$1" == "SSD" ]] && [[ "$SSD_Power_On_Hours" == "true" ]]; then echo "  <th style=\"text-align:center; width:120px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$SSD_Power_On_Hours_Title"</th>"; fi
    if [[ "$1" == "NVM" ]] && [[ "$NVM_Power_On_Hours" == "true" ]]; then echo "  <th style=\"text-align:center; width:120px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$NVM_Power_On_Hours_Title"</th>"; fi

    if [[ "$1" == "SSD" ]] && [[ "$SSD_Wear_Level" == "true" ]]; then echo "  <th style=\"text-align:center; width:100px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$SSD_Wear_Level_Title"</th>"; fi
    if [[ "$1" == "NVM" ]] && [[ "$NVM_Wear_Level" == "true" ]]; then echo "  <th style=\"text-align:center; width:100px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$NVM_Wear_Level_Title"</th>"; fi

    if [[ "$1" == "HDD" ]] && [[ "$HDD_Start_Stop_Count" == "true" ]]; then echo "  <th style=\"text-align:center; width:100px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$HDD_Start_Stop_Count_Title"</th>"; fi
    if [[ "$1" == "HDD" ]] && [[ "$HDD_Load_Cycle" == "true" ]]; then echo "  <th style=\"text-align:center; width:80px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$HDD_Load_Cycle_Title"</th>"; fi
    if [[ "$1" == "HDD" ]] && [[ "$HDD_Spin_Retry" == "true" ]]; then echo "  <th style=\"text-align:center; width:80px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$HDD_Spin_Retry_Title"</th>"; fi

    if [[ "$1" == "HDD" ]] && [[ "$HDD_Reallocated_Sectors" == "true" ]]; then echo "  <th style=\"text-align:center; width:80px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$HDD_Reallocated_Sectors_Title"</th>"; fi
    if [[ "$1" == "SSD" ]] && [[ "$SSD_Reallocated_Sectors" == "true" ]]; then echo "  <th style=\"text-align:center; width:80px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$SSD_Reallocated_Sectors_Title"</th>"; fi

    if [[ "$1" == "HDD" ]] && [[ "$HDD_Reallocated_Events" == "true" ]]; then echo "  <th style=\"text-align:center; width:80px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$HDD_Reallocated_Events_Title"</th>"; fi
    if [[ "$1" == "SSD" ]] && [[ "$SSD_Reallocated_Events" == "true" ]]; then echo "  <th style=\"text-align:center; width:80px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$SSD_Reallocated_Events_Title"</th>"; fi

    if [[ "$1" == "HDD" ]] && [[ "$HDD_Pending_Sectors" == "true" ]]; then echo "  <th style=\"text-align:center; width:80px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$HDD_Pending_Sectors_Title"</th>"; fi
    if [[ "$1" == "SSD" ]] && [[ "$SSD_Pending_Sectors" == "true" ]]; then echo "  <th style=\"text-align:center; width:80px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$SSD_Pending_Sectors_Title"</th>"; fi

    if [[ "$1" == "HDD" ]] && [[ "$HDD_Offline_Uncorrectable" == "true" ]]; then echo "  <th style=\"text-align:center; width:120px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$HDD_Offline_Uncorrectable_Title"</th>"; fi
    if [[ "$1" == "SSD" ]] && [[ "$SSD_Offline_Uncorrectable" == "true" ]]; then echo "  <th style=\"text-align:center; width:120px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$SSD_Offline_Uncorrectable_Title"</th>"; fi

    if [[ "$1" == "HDD" ]] && [[ "$HDD_UDMA_CRC_Errors" == "true" ]]; then echo "  <th style=\"text-align:center; width:80px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$HDD_UDMA_CRC_Errors_Title"</th>"; fi
    if [[ "$1" == "SSD" ]] && [[ "$SSD_UDMA_CRC_Errors" == "true" ]]; then echo "  <th style=\"text-align:center; width:80px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$SSD_UDMA_CRC_Errors_Title"</th>"; fi

    if [[ "$1" == "HDD" ]] && [[ "$HDD_Raw_Read_Error_Rate" == "true" ]]; then echo "  <th style=\"text-align:center; width:80px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$HDD_Raw_Read_Error_Rate_Title"</th>"; fi
    if [[ "$1" == "HDD" ]] && [[ "$HDD_Seek_Error_Rate" == "true" ]]; then echo "  <th style=\"text-align:center; width:80px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$HDD_Seek_Error_Rate_Title"</th>"; fi
    if [[ "$1" == "HDD" ]] && [[ "$HDD_MultiZone_Errors" == "true" ]]; then echo "  <th style=\"text-align:center; width:80px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$HDD_MultiZone_Errors_Title"</th>"; fi
    if [[ "$1" == "HDD" ]] && [[ "$HDD_Helium_Level" == "true" ]]; then echo "  <th style=\"text-align:center; width:80px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$HDD_Helium_Level_Title"</th>"; fi

    if [[ "$1" == "HDD" ]] && [[ "$HDD_Last_Test_Age" == "true" ]]; then echo "  <th style=\"text-align:center; width:100px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$HDD_Last_Test_Age_Title"</th>"; fi
    if [[ "$1" == "SSD" ]] && [[ "$SSD_Last_Test_Age" == "true" ]]; then echo "  <th style=\"text-align:center; width:100px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$SSD_Last_Test_Age_Title"</th>"; fi

    if [[ "$1" == "HDD" ]] && [[ "$HDD_Last_Test_Type" == "true" ]]; then echo "  <th style=\"text-align:center; width:100px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$HDD_Last_Test_Type_Title"</th></tr>"; fi
    if [[ "$1" == "SSD" ]] && [[ "$SSD_Last_Test_Type" == "true" ]]; then echo "  <th style=\"text-align:center; width:100px; height:60px; border:1px solid black; border-collapse:collapse; font-family:courier;\">"$SSD_Last_Test_Type_Title"</th></tr>"; fi
    echo "</tr>"

) >> "$logfile"
force_delay
}

################################## WRITE TABLE #############################################################
# Call function with end_table "HDD|SSD|NVM"

write_table () {
 
(
printf "<tr style=\"background-color:%s;\">\n" $bgColor;
if [[ "$1" == "HDD" ]] && [[ "$HDD_Device_ID" == "true" ]]; then printf "<td style=\"text-align:center; background-color:%s; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">/dev/%s</td>\n" "$deviceStatusColor" "$drive"; fi
if [[ "$1" == "SSD" ]] && [[ "$SSD_Device_ID" == "true" ]]; then printf "<td style=\"text-align:center; background-color:%s; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">/dev/%s</td>\n" "$deviceStatusColor" "$drive"; fi
if [[ "$1" == "NVM" ]] && [[ "$NVM_Device_ID" == "true" ]]; then printf "<td style=\"text-align:center; background-color:%s; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">/dev/%s</td>\n" "$deviceStatusColor" "$drive"; fi

if [[ "$1" == "HDD" ]] && [[ "$HDD_Serial_Number" == "true" ]]; then printf "<td style=\"text-align:center; background-color:%s; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">%s</td>\n" "$bgColor" "$serial"; fi
if [[ "$1" == "SSD" ]] && [[ "$SSD_Serial_Number" == "true" ]]; then printf "<td style=\"text-align:center; background-color:%s; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">%s</td>\n" "$bgColor" "$serial"; fi
if [[ "$1" == "NVM" ]] && [[ "$NVM_Serial_Number" == "true" ]]; then printf "<td style=\"text-align:center; background-color:%s; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">%s</td>\n" "$bgColor" "$serial"; fi

if [[ "$1" == "HDD" ]] && [[ "$HDD_Model_Number" == "true" ]]; then printf "<td style=\"text-align:center; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">%s</td>\n" "$modelnumber"; fi
if [[ "$1" == "SSD" ]] && [[ "$SSD_Model_Number" == "true" ]]; then printf "<td style=\"text-align:center; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">%s</td>\n" "$modelnumber"; fi
if [[ "$1" == "NVM" ]] && [[ "$NVM_Model_Number" == "true" ]]; then printf "<td style=\"text-align:center; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">%s</td>\n" "$modelnumber"; fi

if [[ "$1" == "HDD" ]] && [[ "$HDD_Capacity" == "true" ]]; then printf "<td style=\"text-align:center; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">%s</td>\n" "$capacity"; fi
if [[ "$1" == "SSD" ]] && [[ "$SSD_Capacity" == "true" ]]; then printf "<td style=\"text-align:center; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">%s</td>\n" "$capacity"; fi
if [[ "$1" == "NVM" ]] && [[ "$NVM_Capacity" == "true" ]]; then printf "<td style=\"text-align:center; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">%s</td>\n" "$capacity"; fi

if [[ "$1" == "HDD" ]] && [[ "$HDD_Rotational_Rate" == "true" ]]; then printf "<td style=\"text-align:center; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">%s</td>\n" "$rotation"; fi

if [[ "$1" == "HDD" ]] && [[ "$HDD_SMART_Status" == "true" ]]; then printf "<td style=\"text-align:center; background-color:%s; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">%s</td>\n" "$smartStatusColor" "$smartStatus"; fi
if [[ "$1" == "SSD" ]] && [[ "$SSD_SMART_Status" == "true" ]]; then printf "<td style=\"text-align:center; background-color:%s; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">%s</td>\n" "$smartStatusColor" "$smartStatus"; fi
if [[ "$1" == "NVM" ]] && [[ "$NVM_SMART_Status" == "true" ]]; then printf "<td style=\"text-align:center; background-color:%s; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">%s</td>\n" "$smartStatusColor" "$smartStatus"; fi

if [[ "$1" == "HDD" ]] && [[ "$HDD_Warranty" == "true" ]] && [[ "$WarrantyBoxColor" == "$expiredWarrantyBoxColor" ]]; then printf "<td style=\"text-align:center; background-color:%s; height:25px; border:%spx solid %s; border-collapse:collapse; font-family:courier;\">%s</td>\n" "$WarrantyBackgroundColor" "$WarrantyBoxPixels" "$WarrantyBoxColor" "$WarrantyClock"; fi
if [[ "$1" == "HDD" ]] && [[ "$HDD_Warranty" == "true" ]] && [[ "$WarrantyBoxColor" != "$expiredWarrantyBoxColor" ]]; then printf "<td style=\"text-align:center; background-color:%s; height:25px; border:1px solid %s; border-collapse:collapse; font-family:courier;\">%s</td>\n" "$WarrantyBackgroundColor" "$WarrantyBoxColor" "$WarrantyClock"; fi
if [[ "$1" == "SSD" ]] && [[ "$SSD_Warranty" == "true" ]] && [[ "$WarrantyBoxColor" == "$expiredWarrantyBoxColor" ]]; then printf "<td style=\"text-align:center; background-color:%s; height:25px; border:%spx solid %s; border-collapse:collapse; font-family:courier;\">%s</td>\n" "$WarrantyBackgroundColor" "$WarrantyBoxPixels" "$WarrantyBoxColor" "$WarrantyClock"; fi
if [[ "$1" == "SSD" ]] && [[ "$SSD_Warranty" == "true" ]] && [[ "$WarrantyBoxColor" != "$expiredWarrantyBoxColor" ]]; then printf "<td style=\"text-align:center; background-color:%s; height:25px; border:1px solid %s; border-collapse:collapse; font-family:courier;\">%s</td>\n" "$WarrantyBackgroundColor" "$WarrantyBoxColor" "$WarrantyClock"; fi
if [[ "$1" == "NVM" ]] && [[ "$NVM_Warranty" == "true" ]] && [[ "$WarrantyBoxColor" == "$expiredWarrantyBoxColor" ]]; then printf "<td style=\"text-align:center; background-color:%s; height:25px; border:%spx solid %s; border-collapse:collapse; font-family:courier;\">%s</td>\n" "$WarrantyBackgroundColor" "$WarrantyBoxPixels" "$WarrantyBoxColor" "$WarrantyClock"; fi
if [[ "$1" == "NVM" ]] && [[ "$NVM_Warranty" == "true" ]] && [[ "$WarrantyBoxColor" != "$expiredWarrantyBoxColor" ]]; then printf "<td style=\"text-align:center; background-color:%s; height:25px; border:1px solid %s; border-collapse:collapse; font-family:courier;\">%s</td>\n" "$WarrantyBackgroundColor" "$WarrantyBoxColor" "$WarrantyClock"; fi

if [[ "$1" == "NVM" ]] && [[ "$NVM_Critical_Warning" == "true" ]]; then printf "<td style=\"text-align:center; background-color:%s; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">%s</td>\n" "$NVMcriticalWarningColor" "$NVMcriticalWarning"; fi

if [[ "$1" == "HDD" ]] && [[ "$HDD_Drive_Temp" == "true" ]]; then printf "<td style=\"text-align:center; background-color:%s; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">%s$tempdisplay</td>\n" "$tempColor" "$temp"; fi
if [[ "$1" == "SSD" ]] && [[ "$SSD_Drive_Temp" == "true" ]]; then printf "<td style=\"text-align:center; background-color:%s; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">%s$tempdisplay</td>\n" "$tempColor" "$temp"; fi
if [[ "$1" == "NVM" ]] && [[ "$NVM_Drive_Temp" == "true" ]]; then printf "<td style=\"text-align:center; background-color:%s; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">%s$tempdisplay</td>\n" "$tempColor" "$temp"; fi

if [[ "$1" == "HDD" ]] && [[ "$HDD_Drive_Temp_Min" == "true" ]]; then printf "<td style=\"text-align:center; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">%s$tempdisplaymin</td>\n" "$temp_min"; fi
if [[ "$1" == "SSD" ]] && [[ "$SSD_Drive_Temp_Min" == "true" ]]; then printf "<td style=\"text-align:center; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">%s$tempdisplaymin</td>\n" "$temp_min"; fi
if [[ "$1" == "NVM" ]] && [[ "$NVM_Drive_Temp_Min" == "true" ]]; then printf "<td style=\"text-align:center; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">%s$tempdisplaymin</td>\n" "$temp_min"; fi

if [[ "$1" == "HDD" ]] && [[ "$HDD_Drive_Temp_Max" == "true" ]]; then printf "<td style=\"text-align:center; background-color:%s; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">%s$tempdisplaymax</td>\n" "$temp_maxColor" "$temp_max"; fi
if [[ "$1" == "SSD" ]] && [[ "$SSD_Drive_Temp_Max" == "true" ]]; then printf "<td style=\"text-align:center; background-color:%s; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">%s$tempdisplaymax</td>\n" "$temp_maxColor" "$temp_max"; fi
if [[ "$1" == "NVM" ]] && [[ "$NVM_Drive_Temp_Max" == "true" ]]; then printf "<td style=\"text-align:center; background-color:%s; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">%s$tempdisplaymax</td>\n" "$temp_maxColor" "$temp_max"; fi

if [[ "$1" == "HDD" ]] && [[ "$HDD_Power_On_Hours" == "true" ]]; then printf "<td style=\"text-align:center; background-color:%s; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">%s</td>\n" "$onTimeColor" "$onTime"; fi
if [[ "$1" == "SSD" ]] && [[ "$SSD_Power_On_Hours" == "true" ]]; then printf "<td style=\"text-align:center; background-color:%s; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">%s</td>\n" "$onTimeColor" "$onTime"; fi
if [[ "$1" == "NVM" ]] && [[ "$NVM_Power_On_Hours" == "true" ]]; then printf "<td style=\"text-align:center; background-color:%s; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">%s</td>\n" "$onTimeColor" "$onTime"; fi

if [[ "$1" == "SSD" ]] && [[ "$SSD_Wear_Level" == "true" ]]; then printf "<td style=\"text-align:center; background-color:%s; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">%s</td>\n" "$wearLevelColor" "$wearLevel"; fi
if [[ "$1" == "NVM" ]] && [[ "$NVM_Wear_Level" == "true" ]]; then printf "<td style=\"text-align:center; background-color:%s; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">%s</td>\n" "$wearLevelColor" "$wearLevel"; fi

if [[ "$1" == "HDD" ]] && [[ "$HDD_Start_Stop_Count" == "true" ]]; then printf "<td style=\"text-align:center; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">%s</td>\n" "$startStop"; fi
if [[ "$1" == "HDD" ]] && [[ "$HDD_Load_Cycle" == "true" ]]; then printf "<td style=\"text-align:center; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">%s</td>\n" "$loadCycle"; fi
if [[ "$1" == "HDD" ]] && [[ "$HDD_Spin_Retry" == "true" ]]; then printf "<td style=\"text-align:center; background-color:%s; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">%s</td>\n" "$spinRetryColor" "$spinRetry"; fi

if [[ "$1" == "HDD" ]] && [[ "$HDD_Reallocated_Sectors" == "true" ]]; then printf "<td style=\"text-align:center; background-color:%s; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">%s</td>\n" "$reAllocColor" "$reAlloc"; fi
if [[ "$1" == "SSD" ]] && [[ "$SSD_Reallocated_Sectors" == "true" ]]; then printf "<td style=\"text-align:center; background-color:%s; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">%s</td>\n" "$reAllocColor" "$reAlloc"; fi

if [[ "$1" == "HDD" ]] && [[ "$HDD_Reallocated_Events" == "true" ]]; then printf "<td style=\"text-align:center; background-color:%s; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">%s</td>\n" "$reAllocEventColor" "$reAllocEvent"; fi
if [[ "$1" == "SSD" ]] && [[ "$SSD_Reallocated_Events" == "true" ]]; then printf "<td style=\"text-align:center; background-color:%s; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">%s</td>\n" "$reAllocEventColor" "$reAllocEvent"; fi

if [[ "$1" == "HDD" ]] && [[ "$HDD_Pending_Sectors" == "true" ]]; then printf "<td style=\"text-align:center; background-color:%s; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">%s</td>\n" "$pendingColor" "$pending"; fi
if [[ "$1" == "SSD" ]] && [[ "$SSD_Pending_Sectors" == "true" ]]; then printf "<td style=\"text-align:center; background-color:%s; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">%s</td>\n" "$pendingColor" "$pending"; fi

if [[ "$1" == "HDD" ]] && [[ "$HDD_Offline_Uncorrectable" == "true" ]]; then printf "<td style=\"text-align:center; background-color:%s; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">%s</td>\n" "$offlineUncColor" "$offlineUnc"; fi
if [[ "$1" == "SSD" ]] && [[ "$SSD_Offline_Uncorrectable" == "true" ]]; then printf "<td style=\"text-align:center; background-color:%s; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">%s</td>\n" "$offlineUncColor" "$offlineUnc"; fi

if [[ "$1" == "HDD" ]] && [[ "$HDD_UDMA_CRC_Errors" == "true" ]]; then printf "<td style=\"text-align:center; background-color:%s; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">%s</td>\n" "$crcErrorsColor" "$crcErrors"; fi
if [[ "$1" == "SSD" ]] && [[ "$SSD_UDMA_CRC_Errors" == "true" ]]; then printf "<td style=\"text-align:center; background-color:%s; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">%s</td>\n" "$crcErrorsColor" "$crcErrors"; fi

if [[ "$1" == "HDD" ]] && [[ "$HDD_Raw_Read_Error_Rate" == "true" ]]; then printf "<td style=\"text-align:center; background-color:%s; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">$SER%s</td>\n" "$rawReadErrorRateColor" "$rawReadErrorRate"; fi
if [[ "$1" == "HDD" ]] && [[ "$HDD_Seek_Error_Rate" == "true" ]]; then printf "<td style=\"text-align:center; background-color:%s; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">$SER%s</td>\n" "$seekErrorHealthColor" "$seekErrorHealth"; fi

if [[ "$1" == "HDD" ]] && [[ "$HDD_MultiZone_Errors" == "true" ]]; then printf "<td style=\"text-align:center; background-color:%s; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">%s</td>\n" "$multiZoneColor" "$multiZone"; fi

if [[ "$1" == "HDD" ]] && [[ "$HDD_Helium_Level" == "true" ]]; then printf "<td style=\"text-align:center; background-color:%s; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">%s</td>\n" "$HeliumColor" "$Helium"; fi

if [[ "$1" == "HDD" ]] && [[ "$HDD_Last_Test_Age" == "true" ]]; then printf "<td style=\"text-align:center; background-color:%s; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">%s</td>\n" "$testAgeColor" "$testAge"; fi
if [[ "$1" == "SSD" ]] && [[ "$SSD_Last_Test_Age" == "true" ]]; then printf "<td style=\"text-align:center; background-color:%s; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">%s</td>\n" "$testAgeColor" "$testAge"; fi

if [[ "$1" == "HDD" ]] && [[ "$HDD_Last_Test_Type" == "true" ]]; then printf "<td style=\"text-align:center; background-color:%s; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">%s</td>\n" "$lastTestTypeColor" "$lastTestType"; fi
if [[ "$1" == "SSD" ]] && [[ "$SSD_Last_Test_Type" == "true" ]]; then printf "<td style=\"text-align:center; background-color:%s; height:25px; border:1px solid black; border-collapse:collapse; font-family:courier;\">%s</td>\n" "$lastTestTypeColor" "$lastTestType"; fi

    echo "</tr>"
) | tr -d "[]" >> "$logfile"
force_delay
}

#############################  END THE TABLE ###########################

end_table () {
(
    echo "</tr>"
 echo "</table>"
if [[ "$SER1" == "1" ]]; then echo "<span style='color:gray;'>* = Seek Error Rate is Normalized.  Higher is better.</span>"; fi
    echo "<br>"
) >> "$logfile"
force_delay
}

################################## COMPILE DETAILED REPORT ###############################################

detailed_report () {

###### Detailed Report Section (monospace text)
testfile=$1
 
(
echo "<pre style=\"font-size:20px\">"
echo "<b>Multi-Report Text Section</b>"
echo "<pre style=\"font-size:14px\">"
) >> "$logfile"
force_delay
 
if test -e "$Config_File_Name"; then
   echo "<b>External Configuration File in Use</b><br>" >> "$logfile"
force_delay
else
   echo "<b>No External Configuration File Exists</b><br>" >> "$logfile"
force_delay
fi
 
if [[ $expDataEnable == "true" ]]; then
   if [[ "$(echo $statistical_data_file | grep "/tmp/")" ]]; then
   echo "<b><span style='color:darkred;'>The Statistical Data File is located in the /tmp directory and is not permanent.<br>Recommend changing to a proper dataset.</span></b><br>" >> "$logfile"
   force_delay
   fi

   if [[ $statistical_data_file_created == "1" ]]; then echo "Statistical Data File Created.<br>" >> "$logfile"; force_delay; fi

   if [[ $expDataEmail == "true" ]]; then
      echo "<b>Statistical Export Log Located:<br></b>$statistical_data_file<br><b>Emailed every:</b> $expDataEmailSend<br>" >> "$logfile"
      force_delay
   else
      echo "<b>Statistical Export Log Located at:<br>$statistical_data_file</b><br>" >> "$logfile"
      force_delay
   fi
fi

### Lets write out the error messages if there are any, Critical first followed by Warning

(
if [[ ! $logfile_messages == "" ]]; then
echo "<b>MESSAGES LOG FILE"
echo $logfile_messages
echo "<br>END<br></b>"
fi

if test -e "$logfile_critical"; then
echo "<b>CRITICAL LOG FILE"
cat $logfile_critical
echo "<br>END<br></b>"
fi

if test -e "$logfile_warning"; then
echo "<b>WARNING LOG FILE"
cat $logfile_warning
echo "<br>END<br></b>"
fi

if [[ ! $Ignore_Drives == "none" ]]; then
echo "Ignored Drives = "$Ignore_Drives
echo "<br>END<br>"
fi

if [[ $Fun == "1" ]]; then echo "Have a Happy April Fools Day!"; fi
if [[ ! $logfile_warranty == "" ]]; then 
  echo $logfile_warranty
  echo "</b><br>"
fi
) >> "$logfile"
force_delay


if [[ $disableRAWdata != "true" ]]; then

  ### zpool status for each pool
   for pool in $pools; do
      if [ $softver != "Linux" ]; then
         drives_in_zpool=$(zpool status "$pool" | grep "gptid" | awk '{print $1}')
      else
         drives_in_zpool=$(zpool status -P "$pool" | grep "/dev/disk" | awk -F '[/]' '{print $5}' | cut -d " " -f1)
      fi
   driveit=0
 
    (
      # Create a simple header and drop the output of zpool status -v
        echo "<b>########## ZPool status report for ${pool} ##########</b>"
        zpool status -v "$pool"
        for longpool in $drives_in_zpool; do
          if [ $softver != "Linux" ]; then
             drive_ident=$(glabel status | tail -n +2 | grep "$longpool" | awk '{print $1 " -> " $3}' | cut -d '/' -f2 | cut -d 'p' -f1)
          else
             drive_ident=$longpool" -> "$(/sbin/blkid | grep "$longpool" | cut -d ":" -f1 | cut -d "/" -f3)
          fi
          if [[ $drive_ident != "" ]]; then
          if [[ $driveit == "0" ]]; then echo "<br>Drives for this pool are listed below:"; driveit="1"; fi
          echo $drive_ident
          fi
        done
        echo "<br>"
    ) >> "$logfile"
force_delay
   done

  if [[ $includeSSD == "true" ]] && [[ $includeNVM == "true" ]]; then
     drives="${smartdrives} ${smartdrivesSSD} ${smartdrivesNVM}"
  elif [[ $includeSSD == "true" ]]; then
     drives="${smartdrives} ${smartdrivesSSD}"
  else
     drives="${smartdrives}"
  fi

### SMART status for each drive - SMART Enabled

 write_ata_errors="0"
 
 for drive in $drives; do

if [[ $drive == "ada50" || $drive == "nvme50"  ]] ; then

if [[ "$(cat "$testfile" | grep "Device Model" | awk '{print $3 " " $4 " " $5 " " $6 " " $7}')" ]]; then
   modelnumber="$(cat "$testfile" | grep "Device Model" | awk '{print $3 " " $4 " " $5 " " $6 " " $7}')"; fi

if [[ "$(cat "$testfile" | grep "Model Number:" | awk '{print $3 " " $4 " " $5 " " $6 " " $7}')" ]]; then
   modelnumber="$(cat "$testfile" | grep "Model Number:" | awk '{print $3 " " $4 " " $5 " " $6 " " $7}')"; fi

if [[ "$(cat "$testfile" | grep "Product:" | awk '{print $2}')" ]]; then
   modelnumber="$(cat "$testfile" | grep "Product:" | awk '{print $2}')"; fi

if [[ "$(cat "$testfile" | grep "Model Family" | awk '{print $3}')" ]]; then
   modelnumber="$(cat "$testfile" | grep "Model Family" | awk '{print $3 " " $4 " " $5}')"; fi

    serial="$(cat "$testfile" | grep "Serial Number" | awk '{print $3}')"
    (
    echo "<br><b>########## FULL TESTFILE -- SMART status report for ${drive} drive (${modelnumber}: ${serial}) ##########</b>" 
    cat "$testfile"
    ) >> "$logfile"
force_delay
else
    # Gather brand and serial number of each drive
    smartdata="$(smartctl -a /dev/"$drive")"

    if [[ "$(echo "$smartdata" | grep "Device Model" | awk '{print $3 " " $4 " " $5 " " $6 " " $7}')" ]]; then
       modelnumber="$(echo "$smartdata" | grep "Device Model" | awk '{print $3 " " $4 " " $5 " " $6 " " $7}')"; fi

    if [[ "$(echo "$smartdata" | grep "Model Number:" | awk '{print $3 " " $4 " " $5 " " $6 " " $7}')" ]]; then
       modelnumber="$(echo "$smartdata" | grep "Model Number:" | awk '{print $3 " " $4 " " $5 " " $6 " " $7}')"; fi

    if [[ "$(echo "$smartdata" | grep "Product:" | awk '{print $2}')" ]]; then
       modelnumber="$(echo "$smartdata" | grep "Product:" | awk '{print $2 " " $3 " " $4 " " $5 " " $6}')"; fi

    if [[ "$(echo "$smartdata" | grep "Model Family" | awk '{print $3}')" ]]; then
       modelnumber="$(echo "$smartdata" | grep "Model Family" | awk '{print $3 " " $4 " " $5}')"; fi

    serial="$(echo "$smartdata" | grep "Serial Number" | awk '{print $3}')"
    test_ata_error="$(smartctl -H -A -l error /dev/"$drive" | grep "ATA Error Count" | awk '{print $4}')" 

    modelnumber="$(echo "${modelnumber}" | sed -e 's/\ *$//g')"

    if [[ $serial == "" ]]; then serial="N/A"; fi
    if [[ $modelnumber == "" ]]; then modelnumber="N/A"; fi

    # If no data in ata_errors then lets gather data if needed.
    if [[ $ata_errors == "" ]]; then ata_errors="none"; fi

### ATA ERROR LOG ### Let's find a match to string ata_errors

    IFS=',' read -ra ADDR <<< "$ata_errors"
       for i in "${ADDR[@]}"; do
           ataerrorssn1="$(echo $i | cut -d':' -f 1)"
           ataerrorsdt1="$(echo $i | cut -d':' -f 2)"

           if [[ $ataerrorssn1 == "none" ]]; then
              if [[ ! $test_ata_error == "" ]]; then
                 if [[ $ata_auto_enable == "true" ]]; then
                    temp_ata_errors=$temp_ata_errors$serial:$test_ata_error","
                    write_ata_errors="1"
                 fi
              fi
           fi

           if [[ "$ataerrorssn1" == "$serial" ]]; then
              ataerrors=$ataerrorsdt1

              if [[ $ata_errors == "" ]]; then
                 write_ata_errors="1"
              fi
              temp_ata_errors=$temp_ata_errors$serial:$test_ata_error","

              if [[ $test_ata_error -gt $ataerrors ]]; then
                 write_ata_errors="1"
                 printf "Drive "$serial" ATA Error Count: "$test_ata_error" - Value Increased <br>" >> "$logfile_warning"
              fi
           fi
           continue
       done

    (
     # Create a simple header and drop the output of some basic smartctl commands
        echo "<b>########## SMART status report for ${drive} drive (${modelnumber} : ${serial}) ##########</b>"
     if [[ $test_ata_error -gt "0" ]]; then
        if [[ $test_ata_error -gt $ataerrors ]]; then 
           smartctl -H -A -l error /dev/"$drive"
        else
           smartctl -H -A /dev/"$drive"
           echo "ATA Error Count: "$test_ata_error
           echo " "
        fi
     else
        smartctl -H -A -l error /dev/"$drive"
     fi

     # Create Recent Tests Report
        echo "Num Test_Description  (Most recent Short & Extended Tests - Listed by test number)"
        lasttest1="$(smartctl -x /dev/"$drive" | egrep "# 1")"
        echo $lasttest1
        if [[ $lasttest1 == *"Short offline"* ]]; then lastfind="Extended offline"; fi;
        if [[ $lasttest1 == *"Extended offline"* ]]; then lastfind="Short offline"; fi;
        lasttest2="$(smartctl -x /dev/"$drive" | egrep "$lastfind" | head -1)"
        echo $lasttest2
        echo "<br>"
    ) >> "$logfile"
force_delay
       
 # SCT Error Recovery Control Report
       scterc="$(smartctl -l scterc /dev/"$drive" | tail -3 | head -2)"
    (
      echo "SCT Error Recovery Control: "$scterc
      echo "<br>"
     ) >> "$logfile"
force_delay
fi
 done
fi
}

################################ COMPILE NON-SMART REPORT ##################################

non_smart_report () {

### NON-SMART status report section
# I don't particularly use this but some folks might find it useful.
# To activate it, in the variables set reportnonSMART=true.
# It will list all drives where Non-SMART is true and remove devices starting with "cd", for example "cd0"
 
drives=$nonsmartdrives
if [ $reportnonSMART == "true" ]; then 
for drive in $drives; do
  if [ ! "$(echo "$drive" | grep "cd")" ]; then

  # Gather model number and serial number of each drive
    
    smartdata="$(smartctl -a /dev/"$drive")"

    serial="$(echo "$smartdata" | grep "Serial Number" | awk '{print $3}')"

    if [[ "$(echo "$smartdata" | grep "Device Model" | awk '{print $3 " " $4 " " $5 " " $6 " " $7}')" ]]; then
       modelnumber="$(echo "$smartdata" | grep "Device Model" | awk '{print $3 " " $4 " " $5 " " $6 " " $7}')"; fi

    if [[ "$(echo "$smartdata" | grep "Model Number:" | awk '{print $3 " " $4 " " $5 " " $6 " " $7}')" ]]; then
       modelnumber="$(echo "$smartdata" | grep "Model Number:" | awk '{print $3 " " $4 " " $5 " " $6 " " $7}')"; fi

    if [[ "$(echo "$smartdata" | grep "Product:" | awk '{print $2}')" ]]; then
       modelnumber="$(echo "$smartdata" | grep "Product:" | awk '{print $2 " " $3 " " $4 " " $5 " " $6}')"; fi

    modelnumber="$(echo "${modelnumber}" | sed -e 's/\ *$//g')"

    if [[ $serial == "" ]]; then serial="N/A"; fi
    if [[ $modelnumber == "" ]]; then modelnumber="N/A"; fi

    (
        echo "<br>"
        echo "<b>########## NON-SMART status report for ${drive} drive (${modelnumber} : ${serial}) ##########</b>"
    # And we will dump everything since it's not a standard SMART device.
        echo "<b>SMARTCTL DATA</b>"
        smartctl -a /dev/"$drive"
        echo "<br>"
      if [ $softver == "Linux" ]; then
        echo "<b>FDISK DATA</b>"
        fdisk -l /dev/"$drive"
      fi

    ) >> "$logfile"
force_delay
  fi
done
fi
}

############################## REMOVE UN-NEEDED JUNK AND FINALIZE EMAIL MESSAGE END #####################

remove_junk_report () {
 
### Remove some un-needed junk from the output
sed -i -e '/smartctl/d' "$logfile"
force_delay
sed -i -e '/Copyright/d' "$logfile"
force_delay
sed -i -e '/=== START OF READ/d' "$logfile"
force_delay
sed -i -e '/SMART Attributes Data/d' "$logfile"
force_delay
sed -i -e '/Vendor Specific SMART/d' "$logfile"
force_delay
sed -i -e '/SMART Error Log Version/d' "$logfile"
force_delay

# Attach dump files
if [[ "$dump_all" == "1" || "$dump_all" == "2" ]]; then
   for drive in $smartdrives; do
     dump_drive_data
   done
   for drive in $smartdrivesSSD; do
     dump_drive_data
   done
   for drive in $smartdrivesNVM; do
     dump_drive_data
   done
   for drive in $nonsmartdrives; do
     dump_drive_data
   done
   doit="true"
fi

if [[ "$Config_Email_Enable" == "true" ]]; then

   if [[ "$Attach_Config" == "1" ]]; then doit="true"; fi

   Now=$(date +"%a")
     case $Config_Backup_Day in
       All)
         doit="true"
       ;;
       Mon|Tue|Wed|Thu|Fri|Sat|Sun)
         if [[ "$Config_Backup_Day" == "$Now" ]]; then doit="true"; fi
       ;;
       Month)
         if [[ $(date +"%d") == "01" ]]; then doit="true"; fi
       ;;
       Never)
       ;;
       *)
       ;;
     esac
fi
   if [[ "$doit" == "true" ]]; then
      (
      # Write MIME section header for file attachment (encoded with base64)
      echo "--${boundary}"
      echo "Content-Type: text/html"
      echo "Content-Transfer-Encoding: base64"
      echo "Content-Disposition: attachment; filename=multi_report_config.txt"
      base64 $Config_File_Name
      ) >> "$logfile"
force_delay
   fi
 
### End details section, close MIME section
(
    echo "</pre>"
    echo "--${boundary}--"
)  >> "$logfile"
force_delay
}

############################# COMBINE ALL DATA INTO A FORMAL EMAIL MESSAGE AND SEND IT ############################

create_email () {
### Create New Email Header - Set Subject Line

## Test if there is a Warning Message and Setup Subject Line
if test -e "$logfile_critical"; then
 subject="*CRITICAL ERROR*  SMART Testing Results for ${host}  *CRITICAL ERROR*"
elif test -e "$logfile_warning"; then
 subject="*WARNING*  SMART Testing Results for ${host}  *WARNING*"
elif [[ $disableWarranty == "false" ]]; then
      if [[ ! $logfile_warranty == "" ]]; then
	subject="*Drive Warranty Expired* - SMART Testing Results for ${host}"
	else
	subject="SMART Testing Results for ${host} - All is Good"
	fi
else
 subject="SMART Testing Results for ${host} - All is Good"
fi

### Set email headers ###
(
echo "From: ${from}"
echo "To: ${email}"
echo "Subject: ${subject}"
) > ${logfile_header}

cat $logfile >> $logfile_header
force_delay
### Send report
sendmail -t -oi < "$logfile_header"
}

############################# CRUNCH THE NUMBERS and FORMAT MESSAGES and COLORS ####################################
##### Call with HDD|SSD|NVM ##############
crunch_numbers () {

detail_level=$1

### Lets adjust for all the Media Alarms, Temp Alarms, and Wear Level for the new Custom_Drives
# We need to change the values in the runnign script to use slight different variables
# for example sectorsWarn will now be sectorsWarnx
# Do this for all the pertinent variables and add a section to scan the Custom_Drives variable
# and if a serial number matches, then use the variables there vs the defaults.

### Order of data -- $serial":"$tempwarn":"$tempcrit":"$sectorswarn":"$sectorscrit":"$reallocwarn":"$multizonewarn":"$multizonecrit":"$rawreadwarn":"$rawreadcrit":"$seekerrorswarn":"$seekerrorscrit":"$testage":"$testAgeOvrd":"$heliummin

#echo "Drive S/N:"$serial

IFS=',' read -ra ADDR <<< "$Custom_Drives"
 for i in "${ADDR[@]}"; do
   cdrivesn1="$(echo $i | cut -d':' -f 1)"
   if [[ $cdrivesn1 == $serial ]]; then
 #     echo "S/N Matched"
      if [[ $Custom_DrivesDrive == "HDD" ]]; then
         HDDtempWarnx="$(echo $i | cut -d':' -f 2)"; HDDtempCritx="$(echo $i | cut -d':' -f 3)"
      fi
      if [[ $Custom_DrivesDrive == "SSD" ]]; then
         SSDtempWarnx="$(echo $i | cut -d':' -f 2)"; SSDtempCritx="$(echo $i | cut -d':' -f 3)"
      fi
      if [[ $Custom_DrivesDrive == "NVM" ]]; then
         NVMtempWarnx="$(echo $i | cut -d':' -f 2)"; NVMtempCritx="$(echo $i | cut -d':' -f 3)"
      fi
      sectorsWarnx="$(echo $i | cut -d':' -f 4)"
      sectorsCritx="$(echo $i | cut -d':' -f 5)"
      reAllocWarnx="$(echo $i | cut -d':' -f 6)"
      multiZoneWarnx="$(echo $i | cut -d':' -f 7)"
      multiZoneCritx="$(echo $i | cut -d':' -f 8)"
      rawReadWarnx="$(echo $i | cut -d':' -f 9)"
      rawReadCritx="$(echo $i | cut -d':' -f 10)"
      seekErrorsWarnx="$(echo $i | cut -d':' -f 11)"
      seekErrorsCritx="$(echo $i | cut -d':' -f 12)"
      testAgeWarnx="$(echo $i | cut -d':' -f 13)"
      testAgeOvrd="$(echo $i | cut -d':' -f 14)"
      heliumMinx="$(echo $i | cut -d':' -f 15)"

#echo $HDDtempWarnx
#echo $HDDtempCritx
#echo $sectorsWarnx
#echo $sectorsCritx
#echo $reAllocWarnx
#echo $multiZoneWarnx
#echo $multiZoneCritx
#echo $rawReadWarnx
#echo $rawReadCritx
#echo $seekErrorsWarnx
#echo $seekErrorsCritx
#echo $testAgeWarnx
#echo $testAgeOvrd
#echo $heliumMinx

   else
#echo "No drive found, Using Default Values"
     if [[ $Custom_DrivesDrive == "HDD" ]]; then
         HDDtempWarnx=$HDDtempWarn; HDDtempCritx=$HDDtempCrit
     fi
     if [[ $Custom_DrivesDrive == "SSD" ]]; then
          SSDtempWarnx=$SSDtempWarn; HDDtempCritx=$SSDtempCrit
     fi
     if [[ $Custom_DrivesDrive == "NVM" ]]; then
         NVMtempWarnx=$NVMtempWarn; NVMtempCritx=$NVMtempCrit
     fi 
     sectorsWarnx=$sectorsWarn
     sectorsCritx=$sectorsCrit
     reAllocWarnx=$reAllocWarn
     multiZoneWarnx=$multiZoneWarn
     multiZoneCritx=$multiZoneCrit
     rawReadWarnx=$rawReadWarn
     rawReadCritx=$rawReadCrit
     seekErrorsWarnx=$seekErrorsWarn
     seekErrorsCritx=$seekErrorsCrit
     testAgeWarnx=$testAgeWarn
     testAgeOvrd="0"
     heliumMinx=$heliumMin
   fi
 done
   if [[ $Custom_Drives == "" ]]; then
     #echo "Custom_Drives not defined"
     if [[ $Custom_DrivesDrive == "HDD" ]]; then
         HDDtempWarnx=$HDDtempWarn; HDDtempCritx=$HDDtempCrit
     fi
     if [[ $Custom_DrivesDrive == "SSD" ]]; then
          SSDtempWarnx=$SSDtempWarn; HDDtempCritx=$SSDtempCrit
     fi
     if [[ $Custom_DrivesDrive == "NVM" ]]; then
         NVMtempWarnx=$NVMtempWarn; NVMtempCritx=$NVMtempCrit
     fi 
     sectorsWarnx=$sectorsWarn
     sectorsCritx=$sectorsCrit
     reAllocWarnx=$reAllocWarn
     multiZoneWarnx=$multiZoneWarn
     multiZoneCritx=$multiZoneCrit
     rawReadWarnx=$rawReadWarn
     rawReadCritx=$rawReadCrit
     seekErrorsWarnx=$seekErrorsWarn
     seekErrorsCritx=$seekErrorsCrit
     testAgeWarnx=$testAgeWarn
     heliumMinx=$heliumMin
   fi


### Remove Leading Zeros from all variables
# This is important because double square brackets interpret a leading zero as Octal number
# This only works for positive numbers, not negative.  Thankfully I should not have negative
# numbers in this script.

# Make onHours a base 10 number and remove any commas
onHours=${onHours#0}
onHours="${onHours//,}"

### Convert onHours to onTime
if [[ $onHours -gt "1000000" ]]; then onHours=0; fi
if [[ $lastTestHours != "" ]]; then let testAge=$(((($onHours - $lastTestHours) / 24))); fi

let yrs=$((($onHours / 8760)))
let mos=$(((($onHours % 8760) / 730)))
let dys=$((((($onHours % 8760) % 730) / 24)))
let hrs=$(((($onHours % 8760) % 730) % 24))

if [[ $powerTimeFormat == "ymdh" ]]; then onTime="${yrs}y ${mos}m ${dys}d ${hrs}h";
 elif [[ $powerTimeFormat == "ymd" ]]; then onTime="${yrs}y ${mos}m ${dys}d";
 elif [[ $powerTimeFormat == "ym" ]]; then onTime="${yrs}y ${mos}m";
 elif [[ $powerTimeFormat == "y" ]]; then onTime="${yrs}y";
 elif [[ $powerTimeFormat == "h" ]]; then onTime=$onHours;
 else onTime=$onHours;
fi

##### CUSTOM DRIVE HACK Section #####
# This will set the testAge value to 1 so it passes the math portion of the quality checks.

if [[ $testAgeOvrd == "1" ]]; then testAge=1; fi

if [[ $custom_hack == "mistermanko" ]]; then
    if [[ $serial == "1603F0161945" ]]; then testAge=1; fi
fi
if [[ $custom_hack == "snowlucas2022" ]]; then
    if [[ $serial == "S1D5NSAF483620N" ]]; then testAge=1; fi
fi
if [[ $custom_hack == "diedrichg" ]]; then
    if [[ $serial == "67F40744192400021305" ]]; then testAge=1; fi
fi

### WARRANTY DATE
# Use Format: DriveWarranty="DriveSerialNumber YYYY-MM-DD,"

s="0"
IFS=',' read -ra ADDR <<< "$Drive_Warranty"
 for i in "${ADDR[@]}"; do
   drivesn1="$(echo $i | cut -d':' -f 1)"
   drivedt1="$(echo $i | cut -d':' -f 2)"
   if [[ $drivesn1 == $serial ]]; then
      warrantyyear="$(echo $drivedt1 | cut -d '-' -f1)"
      warrantymonth="$(echo $drivedt1 | cut -d '-' -f2)"
      warrantyday="$(echo $drivedt1 | cut -d '-' -f3)"
      tempnow="$((`date +%s`))"

if [[ $softver != "Linux" ]]; then 
      warrantytemp="$((`date -j -v"$warrantyyear"y -v"$warrantymonth"m -v"$warrantyday"d +%s`))"
else
# Debian Date in seconds
warrantytemp="$((`date -d "$drivedt1" +%s`))"
fi

      warrantytemp="$((("$tempnow" - "$warrantytemp")/3600))"
      let waryrs=$((($warrantytemp / 8760)))
      let warmos=$(((($warrantytemp % 8760) / 730)))
      let wardys=$((((($warrantytemp % 8760) % 730) / 24)))
      let warhrs=$(((($warrantytemp % 8760) % 730) % 24))
      let wardays=$((($warrantytemp / 24)))
      wartemp2=${wardays#-}
      wartemp3=${waryrs#-}

      if [[ $wartemp2 -gt 31 ]]; then
         if [[ $wartemp3 -gt 0 ]]; then wartext="${waryrs#-}y ${warmos#-}m ${wardys#-}d"
         else wartext="${warmos#-}m ${wardys#-}d"
         fi
      else
         wartext="${wardays#-}d"
      fi

         if [[ "$warrantytemp" > 0 ]]; then
            WarrantyClock=$wartext
         else
            WarrantyClock=${wartext#-}
         fi

     if [[ "$datestamp2" > "$drivedt1" ]]; then
        s="1"
        drivesn2=$drivesn1
        drivedt2=$drivedt1
        continue
     fi
   fi
   done
         if [[ "$WarrantyClock" == "" ]]; then
            WarrantyClock=$non_exist_value
         fi
 if [[ $s != "0" ]]; then
onTimeColor=$yellowColor
if [[ $WarrantyBackgndColor != "none" ]]; then WarrantyBackgroundColor=$WarrantyBackgndColor; fi
WarrantyBoxColor=$expiredWarrantyBoxColor
logfile_warranty=$logfile_warranty"Drive "$drivesn2" Warranty Expired on "$drivedt2"<br>"
 fi

### SMART STATUS

if [[ $smartStatus == "" || $smartStatus == "PASSED" || $smartStatus == "OK" ]]; then smartStatusColor=$okColor; else smartStatusColor=$critColor; fi
if [[ $smartStatus == "" || $smartStatus == "PASSED" || $smartStatus == "OK" ]]; then a=1; else printf "Drive "$device " - Check Smart Status<br>" >> "$logfile_critical"; fi
if [[ $smartStatus == "" ]]; then smartStatus = "$non_exist_value"; fi

### BAD SECTORS

s="0"
IFS=',' read -ra ADDR <<< "$Bad_Sectors"
 for i in "${ADDR[@]}"; do
   badsectsn1="$(echo $i | cut -d':' -f 1)"
   badsectdt1="$(echo $i | cut -d':' -f 2)"
   if [[ $badsectsn1 == $serial ]]; then
    s="1"
    badsectsn2=$badsectsn1
    badsectdt2=$badsectdt1
    continue
   fi
   done
 if [[ $s != "0" ]]; then
reAllocColor=$ovrdColor
reAlloc=$(($reAlloc-$badsectdt2))
 fi

####################  TEMPERATURE SECTION ###################
# LETS ZERO OUT BOGUS HIGH TEMPS and LOW TEMPS
if [[ $temp -gt 150 ]]; then temp="$non_exist_value"; fi
if [[ $temp -lt -60 ]]; then temp="$non_exist_value"; fi

### TEMP for HDD
if [[ $detail_level == "HDD" ]]; then
if [[ $temp != "$non_exist_value" ]]; then if [[ $temp -gt $HDDtempCritx ]]; then tempColor=$critColor; else if [[ $temp -gt $HDDtempWarnx ]]; then tempColor=$warnColor; fi; fi; fi
if [[ $temp != "$non_exist_value" ]]; then if [[ $temp -gt $HDDtempCritx ]]; then printf "Drive "$serial" Critical Drive Temp "$temp" - Threshold = "$HDDtempCritx"<br>" >> "$logfile_critical";
else if [[ $temp -gt $HDDtempWarnx ]]; then printf "Drive "$serial" High Drive Temp "$temp" - Threshold set at "$HDDtempWarnx"<br>" >> "$logfile_warning"; fi; fi; fi

if [[ $HDDmaxovrd != "true" ]]; then
if [[ $temp_max != "$non_exist_value" ]]; then if [[ $temp_max -gt $HDDtempCritx ]]; then temp_maxColor=$critColor; else if [[ $temp_max -gt $HDDtempWarnx ]]; then temp_maxColor=$warnColor; fi; fi; fi
if [[ $temp_max != "$non_exist_value" ]]; then if [[ $temp_max -gt $HDDtempCritx ]]; then printf "Drive "$serial" Critical Drive Temp "$temp_max" - Temp Max Threshold = "$HDDtempCritx"<br>" >> "$logfile_critical";
else if [[ $temp_max -gt $HDDtempWarnx ]]; then printf "Drive "$serial" High Drive Temp "$temp_max" - Temp Max Threshold set at "$HDDtempWarnx"<br>" >> "$logfile_warning"; fi; fi; fi
fi
fi

### TEMP for SSD
if [[ $detail_level == "SSD" ]]; then
if [[ $temp != "$non_exist_value" ]]; then if [[ $temp -gt $SSDtempCritx ]]; then tempColor=$critColor; else if [[ $temp -gt $SSDtempWarnx ]]; then tempColor=$warnColor; fi; fi; fi
if [[ $temp != "$non_exist_value" ]]; then if [[ $temp -gt $SSDtempCritx ]]; then printf "Drive "$serial" Critical Drive Temp "$temp" - Threshold = "$SSDtempCritx"<br>" >> "$logfile_critical";
else if [[ $temp -gt $SSDtempWarnx ]]; then printf "Drive "$serial" High Drive Temp "$temp" - Threshold set at "$SSDtempWarnx"<br>" >> "$logfile_warning"; fi; fi; fi

if [[ $SSDmaxovrd != "true" ]]; then
if [[ $temp_max != "$non_exist_value" ]]; then if [[ $temp_max -gt $SSDtempCritx ]]; then temp_maxColor=$critColor; else if [[ $temp_max -gt $SSDtempWarnx ]]; then temp_maxColor=$warnColor; fi; fi; fi
if [[ $temp_max != "$non_exist_value" ]]; then if [[ $temp_max -gt $SSDtempCritx ]]; then printf "Drive "$serial" Critical Drive Temp "$temp_max" - Threshold = "$SSDtempCritx"<br>" >> "$logfile_critical";
else if [[ $temp_max -gt $SSDtempWarnx ]]; then printf "Drive "$serial" High Drive Temp "$temp_max" - Temp Max Threshold set at "$SSDtempWarnx"<br>" >> "$logfile_warning"; fi; fi; fi
fi
fi

### TEMP for NVM
if [[ $detail_level == "NVM" ]]; then
if [[ $temp != "$non_exist_value" ]]; then if [[ $temp -gt $NVMtempCritx ]]; then tempColor=$critColor; else if [[ $temp -gt $NVMtempWarnx ]]; then tempColor=$warnColor; fi; fi; fi
if [[ $temp != "$non_exist_value" ]]; then if [[ $temp -gt $NVMtempCritx ]]; then printf "Drive "$serial" Critical Drive Temp "$temp" - Threshold = "$NVMtempCritx"<br>" >> "$logfile_critical";
else if [[ $temp -gt $NVMtempWarnx ]]; then printf "Drive "$serial" High Drive Temp "$temp" - Threshold set at "$NVMtempWarnx"<br>" >> "$logfile_warning"; fi; fi; fi

### TEMP_MAX for NVM
if [[ $NVMmaxovrd != "true" ]]; then
if [[ $temp_max != "$non_exist_value" ]]; then if [[ $temp_max -gt $NVMtempCritx ]]; then temp_maxColor=$critColor; else if [[ $temp_max -gt $NVMtempWarnx ]]; then temp_maxColor=$warnColor; fi; fi; fi
if [[ $temp_max != "$non_exist_value" ]]; then if [[ $temp_max -gt $NVMtempCritx ]]; then printf "Drive "$serial" Critical Drive Temp "$temp_max" - Threshold = "$NVMtempCritx"<br>" >> "$logfile_critical";
else if [[ $temp_max -gt $NVMtempWarnx ]]; then printf "Drive "$serial" High Drive Temp "$temp_max" - Threshold set at "$NVMtempWarnx"<br>" >> "$logfile_warning"; fi; fi; fi
fi
fi

# NVM CRITICAL WARNING
if [[ $detail_level == "NVM" ]]; then
NVMcriticalWarningColor="$okColor"
if [[ $NVMcriticalWarning != "" ]]; then if [[ $NVMcriticalWarning != "0x00" ]]; then printf "Drive "$serial" NVM Critical Warning "$NVMcriticalWarning"<br>" >> "$logfile_critical"; fi; fi
if [[ $NVMcriticalWarning != "" ]]; then if [[ $NVMcriticalWarning != "0x00" ]]; then NVMcriticalWarningColor=$critColor; fi; fi
if [[ $NVMcriticalWarning != "" ]]; then if [[ $NVMcriticalWarning != "0x00" ]]; then NVMcriticalWarning="CRITICAL FAILURE"; fi; fi
if [[ $NVMcriticalWarning == "0x00" ]]; then NVMcriticalWarning="GOOD"; fi
if [[ $NVMcriticalWarning == "" ]]; then NVMcriticalWarning="$non_exist_value"; fi
fi

if [[ $detail_level == "HDD" ]]; then

#Helium=99
# Helium Critical Warning
if [[ $Helium == "" ]]; then Helium="$non_exist_value"; HeliumColor="$bgColor"; fi
if [[ $Helium == "$heliumMinx" || $Helium == "$non_exist_value" ]]; then
 HeliumColor="$bgColor"
 else
 if [[ $heliumAlarm == "true" ]]; then
   HeliumColor="$critColor"
   printf "Drive "$serial" Helium Critical Warning - Value "$Helium"<br>" >> "$logfile_critical"
 fi
fi
fi

if [[ $rotation == "" ]]; then rotation="$non_exist_value"; fi
if [[ $capacity == "" ]]; then capacity="$non_exist_value"; fi

########### PROCESSING THAT AFFECTS EVERYTHING ##########################################################
### SPINRETRY

if [[ $spinRetry != "" ]]; then if [[ $spinRetry != "0" ]]; then spinRetryColor=$critColor; fi; fi
if [[ $spinRetry != "" ]]; then if [[ $spinRetry != "0" ]]; then printf "Drive "$serial" Spin Retry "$spinRetry" - Threshold = 0 <br>" >> "$logfile_critical"; fi; fi
if [[ $spinRetry == "" ]]; then spinRetry="$non_exist_value"; fi

### REALLOC and REALLOCEVENT
if [[ $reAlloc != "" ]]; then if [[ $(($reAlloc + 0)) -gt $sectorsCritx ]]; then reAllocColor=$critColor; else if [[ $(($reAlloc + 0)) -gt $sectorsWarnx ]]; then reAllocColor=$warnColor; fi; fi; fi
if [[ $reAlloc != "" ]]; then if [[ $(($reAlloc + 0)) -gt $sectorsCritx ]]; then printf "Drive "$serial" Critical Sectors "$reAlloc" - Threshold = "$sectorsCritx"<br>" >> "$logfile_critical";
else if [[ $(($reAlloc + 0)) -gt $sectorsWarnx ]]; then printf "Drive "$serial" Warning Sectors "$reAlloc" - Threshold = "$sectorsWarnx"<br>" >> "$logfile_warning"; fi; fi; fi
if [[ $reAlloc == "" ]]; then reAlloc="$non_exist_value"; fi

if [[ $reAllocEvent != "" ]]; then if [[ $reAllocEvent -gt $reAllocWarnx ]]; then reAllocEventColor=$warnColor; fi; fi
if [[ $reAllocEvent != "" ]]; then if [[ $reAllocEvent -gt $reAllocWarnx ]]; then printf "Drive "$serial" Reallocating Sectors "$reAllocEvent" - Threshold = "$reAllocWarnx"<br>" >> "$logfile_warning"; fi; fi
if [[ $reAllocEvent == "" ]]; then reAllocEvent="$non_exist_value"; fi

### PENDING SECTORS
if [[ $pending != "" ]]; then if [[ $(($pending + 0)) -gt $sectorsCritx ]]; then pendingColor=$critColor; else if [[ $(($pending + 0)) -gt $sectorsWarnx ]]; then pendingColor=$warnColor; fi; fi; fi
if [[ $pending != "" ]]; then if [[ $(($pending + 0)) -gt $sectorsCritx ]]; then printf "Drive "$serial" Sector Errors "$pending" - Threshold = "$sectorsCritx"<br>" >> "$logfile_critical";
else if [[ $(($pending + 0)) -gt $sectorsWarnx ]]; then printf "Drive "$serial" Sector Errors "$pending" - Threshold = "$sectorsWarnx"<br>" >> "$logfile_warning"; fi; fi; fi
if [[ $pending == "" ]]; then pending="$non_exist_value"; fi

### OFFLINE UNCORRECTABLE SECTORS
if [[ $offlineUnc != "" ]]; then if [[ $(($offlineUnc + 0)) > $sectorsCritx ]]; then offlineUncColor=$critColor; else if [[ $offlineUnc != 0 ]]; then offlineUncColor=$warnColor; fi; fi; fi
if [[ $offlineUnc != "" ]]; then if [[ $(($offlineUnc + 0)) > $sectorsCritx ]]; then printf "Drive "$serial" Uncorrectable Errors "$offlineUnc"<br>" >> "$logfile_critical";
else if [[ $offlineUnc -gt $sectorsWarnx ]]; then printf "Drive "$serial" Uncorrectable Errors "$offlineUnc" - Threshold = "$sectorsWarnx"<br>" >> "$logfile_warning";fi; fi; fi
if [[ $offlineUnc == "" ]]; then offlineUnc="$non_exist_value"; fi

### CRC ERRORS
if [[ $crcErrors != "" ]]; then if [[ $crcErrors != "0" ]]; then crcErrorsColor=$critColor; fi; fi
if [[ $crcErrors == "" ]]; then crcErrors="$non_exist_value"; fi

### SMARTTESTING
if [[ $smarttesting -gt 0 ]]; then lastTestType="$smarttesting% Remaining"; fi

### CHKREADFAILURE
if [[ $chkreadfailure == "Completed:" ]]; then lastTestType="Read Failure"; lastTestTypeColor=$critColor; printf "Drive "$serial" Read Failure "$chkreadfailure"<br>" >> "$logfile_critical"; else lastTestTypeColor=$bgColor; fi 
#if [[ $chkreadfailure == "Completed:" ]]; then printf "Drive "$serial" Read Failure "$chkreadfailure"<br>" >> "$logfile_critical"; fi

### SEEK ERRORS
# If seekErrorHealth RAW_VALUE is some crazy number, use the VALUE column data.
# Seek Error Rate fix for Seagate Drives
# We use seekErrorHealth for the Seagate Rate, and seekErrorHealth2 for the Normalized Rate if we must.

if [[ $seekErrorHealth -gt 0 ]]; then

# Lets see if this is a NORMAL drive, not reporting crazy ass numbers.
if [[ $seekErrorHealth -lt $seekErrorsWarnx ]] && [[ $seekErrorHealth -le 4294967295 ]]; then seek="done"; fi

if [[ $seekErrorHealth -gt $seekErrorsWarnx ]] && [[ $seekErrorHealth -lt $seekErrorsCritx ]]; then
   seekErrorHealthColor=$warnColor
   seek="done"
fi
if [[ $seekErrorHealth -gt $seekErrorsCritx ]] && [[ $seekErrorHealth -le 500 ]]; then
   seekErrorHealthColor=$critColor
   seek="done"
fi

# If the count is above the Seagate FFFFFFFF value, subtract it out or if below FFFFFFFF then make value zero

  if [[ $seekErrorHealth -lt 4294967295 ]] && [[ $seek != "done" ]]; then seekErrorHealth=0; fi
  if [[ $seekErrorHealth -ge 4294967295 ]]; then seekErrorHealth=$(($seekErrorHealth / 4294967295)); fi

  if [[ $ignoreSeekError != "true" ]]; then
   if [[ $(($seekErrorHealth + 0)) -gt $seekErrorsCritx ]]; then
     seekErrorHealthColor=$critColor
     printf "Drive "$serial" Seek Errors "$seekErrorHealth" - Threshold = "$seekErrorsCritx"<br>" >> "$logfile_critical"
   else
     if [[ $(($seekErrorHealth + 0)) -gt $seekErrorsWarnx ]]; then
       seekErrorHealthColor=$warnColor
       printf "Drive "$serial" Seek Errors "$seekErrorHealth" - Threshold = "$seekErrorsWarnx"<br>" >> "$logfile_warning"
     fi
   fi
  fi
fi
seek=""

### Raw Read Error Rate
# If seekErrorHealth RAW_VALUE is some crazy number, use the VALUE column data.
# Raw Read Error Rate fix for Seagate Drives
# We use rawReadErrorRate for the Seagate Rate, and rawReadErrorRate2 for the Normalized Rate if we must.

if [[ $rawReadErrorRate -gt 0 ]]; then

# Lets see if this is a NORMAL drive, not reporting crazy ass numbers.
if [[ $rawReadErrorRate -lt $rawReadWarnx ]] && [[ $rawReadErrorRate -le 4294967295 ]]; then seek="done"; fi

if [[ $rawReadErrorRate -gt $rawReadWarnx ]] && [[ $rawReadErrorRate -lt $rawReadCritx ]]; then
   rawReadErrorRateColor=$warnColor
   seek="done"
fi
if [[ $rawReadErrorRate -gt $rawReadCritx ]] && [[ $rawReadErrorRate -le 500 ]]; then
   rawReadErrorRateColor=$critColor
   seek="done"
fi

# If the count is above the Seagate FFFFFFFF value, subtract it out or if below FFFFFFFF then make value zero

  if [[ $rawReadErrorRate -lt 4294967295 ]] && [[ $seek != "done" ]]; then rawReadErrorRate=0; fi
  if [[ $rawReadErrorRate -ge 4294967295 ]]; then rawReadErrorRate=$(($rawReadErrorRate / 4294967295)); fi

  if [[ $ignoreReadError != "true" ]]; then
   if [[ $(($rawReadErrorRate + 0)) -gt $rawReadCritx ]]; then
     rawReadErrorRateColor=$critColor
     printf "Drive "$serial" Raw Read Error Rate "$rawReadErrorRate" - Threshold = "$rawReadCritx"<br>" >> "$logfile_critical"
   else
     if [[ $(($rawReadErrorRate + 0)) -gt $rawReadWarnx ]]; then
       rawReadErrorRateColor=$warnColor
       printf "Drive "$serial" Raw Read Error Rate "$rawReadErrorRate" - Threshold = "$rawReadWarnx"<br>" >> "$logfile_warning"
     fi
   fi
  fi
fi
seek=""

wearLevelColor=$bgColor
if [[ $multiZone == "" ]]; then multiZone="$non_exist_value"; fi
if [[ $wearLevel == "" || $wearLevel == "0" ]]; then wearLevel="$non_exist_value"; else wearLevel=$(($wearLevel + 0)); fi
if [[ $wearLevel != "$non_exist_value" ]]; then if [[ $wearLevel -lt $wearLevelCrit ]]; then wearLevelColor=$warnColor; printf "Drive: "$serial" - Wear Level = "$wearLevel"%%<br>" >> "$logfile_warning"; fi; fi
if [[ $modelnumber == "" ]]; then modelnumber="$non_exist_value"; fi
if [[ $startStop == "" ]]; then startStop="$non_exist_value"; fi
if [[ $loadCycle == "" ]]; then loadCycle="$non_exist_value"; fi
if [[ $seekErrorHealth == "" ]]; then seekErrorHealth="$non_exist_value"; fi
if [[ $rawReadErrorRate == "" ]]; then rawReadErrorRate="$non_exist_value"; fi
if [[ $Helium == "" ]]; then Helium="$non_exist_value"; fi

################################## WRITE STATISTICAL DATA #########################################
### Save Statistical Data before we make any changes to it.

if [[ $expDataEnable == "true" && $writing_data != "1" ]]; then
   writing_data=1
fi

if [[ $expDataEnable == "true" ]]; then printf $datestamp","$timestamp","$drive","$detail_level","$serial","$smartStatus","$temp","$onHours","$wearLevel","$startStop","$loadCycle","$spinRetry","$reAlloc","$reAllocEvent","$pending","$offlineUnc","$crcErrors","$seekErrorHealth","$multiZone","$rawReadErrorRate","$Helium",\n" >> "$statistical_data_file";fi

### Routine to zero out the UDMA CRC Error Count and Highlights it Yellow.

if [[ $External_Config == "no" ]]; then CRC_Errors=$CRC_Errors; Multi_Zone=$Multi_Zone; Bad_Sectors=$Bad_Sectors; Drive_Warranty=$Drive_Warranty; fi

s="0"
IFS=',' read -ra ADDR <<< "$CRC_Errors"
 for i in "${ADDR[@]}"; do
   crc_errsn1="$(echo $i | cut -d':' -f 1)"
   crc_errst1="$(echo $i | cut -d':' -f 2)"
   if [[ $crc_errsn1 == $serial ]]; then
    s="1"
    crc_errsn2=$crc_errsn1
    crc_errst2=$crc_errst1
    continue
   fi
   done
 if [[ $s != "0" ]]; then
crcErrorsColor=$ovrdColor
crcErrors=$(($crcErrors-$crc_errst2))
 fi

s="0"
IFS=',' read -ra ADDR <<< "$Multi_Zone"
 for i in "${ADDR[@]}"; do
   badsectsn1="$(echo $i | cut -d':' -f 1)"
   badsectdt1="$(echo $i | cut -d':' -f 2)"
   if [[ $badsectsn1 == $serial ]]; then
    s="1"
    badsectsn2=$badsectsn1
    badsectdt2=$badsectdt1
    continue
   fi
   done
 if [[ $s != "0" ]]; then
multiZoneColor=$ovrdColor
multiZone=$(($multiZone-$badsectdt2))
 fi

if [[ $Fun == "1" ]]; then deviceStatusColor=$critColor; printf "Drive "$serial" Data Bit Breakdown Occuring - Bits are flying off the media.<br>"  >> "$logfile_warning"; fi
if [[ $ignoreMultiZone != "true" ]]; then if [[ $multiZone != "$non_exist_value" ]]; then if [[ $multiZone -gt $multiZoneWarnx ]]; then multiZoneColor=$warnColor; printf "Drive: "$serial" - MultiZone Errors = "$multiZone"<br>" >> "$logfile_warning"; fi; fi; fi
if [[ $ignoreMultiZone != "true" ]]; then if [[ $multiZone != "$non_exist_value" ]]; then if [[ $multiZone -gt $multiZoneCritx ]]; then multiZoneColor=$critColor; printf "Drive: "$serial" - MultiZone Errors = "$multiZone"<br>" >> "$logfile_critical";fi ;fi ;fi
if [[ $ignoreUDMA != "true" ]]; then if [[ $crcErrors != "$non_exist_value" ]]; then if [[ $crcErrors != "0" ]]; then printf "Drive "$serial" CRC Errors "$crcErrors"<br>" >> "$logfile_critical";fi; fi; fi
if [[ $testAge -gt $testAgeWarnx ]]; then testAgeColor=$warnColor; else testAgeColor=$bgColor; fi
if [[ $testAge -gt $testAgeWarnx ]]; then printf "Drive: "$serial" - Test Age = "$testAge" Days<br>" >> "$logfile_warning"; fi
if [[ $smartStatusColor != $okColor ]]; then if [[ $smartStatusColor != $altColor ]]; then if [[ $deviceRedFlag == "true" ]]; then deviceStatusColor=$critColor;fi; fi; fi
if [[ $tempColor != $bgColor ]]; then if [[ $tempColor != $altColor ]]; then if [[ $deviceRedFlag == "true" ]]; then deviceStatusColor=$critColor;fi; fi; fi
if [[ $temp_maxColor != $bgColor ]]; then if [[ $temp_maxColor != $altColor ]]; then if [[ $deviceRedFlag == "true" ]]; then deviceStatusColor=$critColor;fi; fi; fi
if [[ $spinRetryColor != $bgColor ]]; then if [[ $spinRetryColor != $altColor ]]; then if [[ $deviceRedFlag == "true" ]]; then deviceStatusColor=$critColor; fi; fi; fi
if [[ $reAllocColor != $bgColor ]]; then if [[ $reAllocColor != $altColor ]]; then if [[ $reAllocColor != $ovrdColor ]]; then if [[ $deviceRedFlag == "true" ]]; then deviceStatusColor=$critColor;fi ;fi ;fi ;fi
if [[ $reAllocEventColor != $bgColor ]]; then if [[ $reAllocEventColor != $altColor ]]; then if [[ $deviceRedFlag == "true" ]]; then deviceStatusColor=$critColor; fi; fi; fi
if [[ $pendingColor != $bgColor ]]; then if [[ $pendingColor != $altColor ]]; then if [[ $deviceRedFlag == "true" ]]; then deviceStatusColor=$critColor;fi ;fi; fi
if [[ $offlineUncColor != $bgColor ]]; then if [[ $offlineUncColor != $altColor ]]; then if [[ $deviceRedFlag == "true" ]]; then deviceStatusColor=$critColor;fi ;fi; fi
if [[ $crcErrorsColor != $bgColor ]]; then if [[ $crcColor != $altColor ]]; then if [[ $crcErrorsColor != $ovrdColor ]]; then if [[ $deviceRedFlag == "true" ]]; then deviceStatusColor=$critColor;fi ;fi ;fi ;fi
if [[ $seekErrorHealthColor != $bgColor ]]; then if [[ $seekErrorHealthColor != $altColor ]]; then if [[ $deviceRedFlag == "true" ]]; then deviceStatusColor=$critColor;fi; fi; fi
if [[ $rawReadErrorRateColor != $bgColor ]]; then if [[ $rawReadErrorRateColor != $altColor ]]; then if [[ $deviceRedFlag == "true" ]]; then deviceStatusColor=$critColor;fi; fi; fi
if [[ $testAgeColor != $bgColor ]]; then if [[ $testAgeColor != $altColor ]]; then if [[ $deviceRedFlag == "true" ]]; then deviceStatusColor=$critColor;fi ;fi ;fi
if [[ $lastTestTypeColor != $bgColor ]]; then if [[ $lastTestTypeColor != $altColor ]]; then if [[ $deviceRedFlag == "true" ]]; then deviceStatusColor=$critColor;fi ;fi ;fi
if [[ $multiZoneColor != $bgColor ]]; then if [[ $multiZoneColor != $altColor ]]; then if [[ $multiZoneColor != $ovrdColor ]]; then if [[ $deviceRedFlag == "true" ]]; then deviceStatusColor=$critColor;fi ;fi ;fi ;fi
if [[ $wearLevelColor != $bgColor ]]; then if [[ $wearLevelColor != $altColor ]]; then if [[ $deviceRedFlag == "true" ]]; then deviceStatusColor=$critColor;fi ;fi ;fi

# SCT Error Recovery Control Report

  scterc="$(smartctl -l scterc /dev/"$drive" | tail -3 | head -2)"

if [[ $SCT_Warning == "TLER" ]]; then
   # Warning Level TLER = Ignore Drives that do not report "seconds" or "Disable"
   # Warning Level TLER_No_Msg = same as above but will not report TLER disabled message until after trying to set TLER fails.
    if [[ $scterc =~ "Disabled" ]]; then printf "Drive "$serial" TLER is Disabled<br>" >> "$logfile_warning"; fi
fi

if [[ $SCT_Warning == "TLER_No_Msg" && $SCT_Drive_Enable == "true" ]]; then
     if [[ $scterc =~ "Disabled" ]]; then
     # Now we set the TLER ONLY for Disabled Drives because we do not know how it will affect other drives.
     smartctl -l scterc,"$SCT_Read_Timeout","$SCT_Write_Timeout" /dev/"$drive" > /dev/null 2>&1
     scterc="$(smartctl -l scterc /dev/"$drive" | tail -3 | head -2)"
      if [[ $scterc =~ "seconds" ]]; then logfile_messages=$logfile_messages"$(printf "<b><span style='color:green;'>Drive "$serial" TLER is NOW ENABLED !</span></b><br>")"; fi
      if [[ $scterc =~ "Disabled" ]]; then printf "<b><span style='color:darkred;'>Drive "$serial" TLER is Disabled and failed to set.</span></b><br>" >> "$logfile_warning"; fi
     fi
fi

if [[ $SCT_Warning == "all" ]]; then 
   if [[ $scterc =~ "Disabled" ]]; then
      printf "Drive "$serial" TLER is Disabled<br>" >> "$logfile_warning"
   else
      if [[ ! $scterc =~ "seconds" ]]; then printf "Drive "$serial" TLER is Unsupported<br>" >> "$logfile_warning"; fi
   fi
fi

  if [[ $SCT_Drive_Enable == "true" ]]; then
     if [[ $scterc =~ "Disabled" ]]; then
     # Now we set the TLER ONLY for Disabled Drives because we do not know how it will affect other drives.
     smartctl -l scterc,"$SCT_Read_Timeout","$SCT_Write_Timeout" /dev/"$drive" > /dev/null 2>&1
     scterc="$(smartctl -l scterc /dev/"$drive" | tail -3 | head -2)"
      if [[ $SCT_Warning == "all" || $SCT_Warning == "TLER" ]]; then printf "<b><span style='color:green;'>Drive "$serial" TLER is NOW ENABLED !</span></b><br>" >> "$logfile_warning"; fi
        if [[ $scterc =~ "Disabled" ]]; then
         if [[ $SCT_Warning == "all" || SCT_Warning == "TLER" ]]; then printf "<b><span style='color:darkred;'>Drive "$serial" TLER is Disabled and failed to set.</span></b><br>" >> "$logfile_warning"; fi
        fi
     fi
 fi

# This section will change the testAge value to the non_exist_value for proper display in the chart.  Displaying a bogus "1" is misleading.

if [[ $testAgeOvrd == "1" ]]; then testAge=$non_exist_value; fi

if [[ $custom_hack == "mistermanko" ]]; then
    if [[ $serial == "1603F0161945" ]]; then testAge=$non_exist_value; fi
fi
if [[ $custom_hack == "snowlucas2022" ]]; then
    if [[ $serial == "S1D5NSAF483620N" ]]; then testAge=$non_exist_value; fi
fi
if [[ $custom_hack == "diedrichg" ]]; then
    if [[ $serial == "67F40744192400021305" ]]; then testAge=$non_exist_value; fi
fi

}

################################## UPDATE CONFIG FILE #############################################
update_config_file () {
(
echo "#" $programver
echo "#"
echo "# This file is used exclusively to configure the multi_report version 1.6c or later."
echo "#"
echo "# The configuration file will be created in the same directory as the script."
echo "#"
echo "# The configuration file will override the default values coded into the script."
echo " "
echo "###### Email Address ######"
echo "# Enter your email address to send the report to.  The from address does not need to be changed unless you experience"
echo "# an error sending the email.  Some email servers only use the email address associated with the email server."
echo " "
echo 'email="'$email'"'
echo 'from="'$from'"'
echo " "
echo "###### Custom Hack ######"
echo "# Custom Hacks are for users with generally very unsupported drives and the data must be manually manipulated."
echo "# The goal is to not have any script customized so I will look for fixes where I can."
echo "#"
echo "# Please look at the new Experimental Custom Drive Settings under -config."
echo "#"
echo "# Allowable custom hacks are: mistermanko, snowlucas2022, diedrichg, or none."
echo 'custom_hack="'$custom_hack'"'
echo " "
echo "###### Zpool Status Summary Table Settings"
echo " "
echo "usedWarn=$usedWarn               # Pool used percentage for CRITICAL color to be used."
echo "scrubAgeWarn=$scrubAgeWarn           # Maximum age (in days) of last pool scrub before CRITICAL color will be used (30 + 7 days for day of week). Default=37."
echo " "
echo "###### Temperature Settings"
echo "HDDtempWarn=$HDDtempWarn            # HDD Drive temp (in C) upper OK limit before a WARNING color/message will be used."
echo "HDDtempCrit=$HDDtempCrit            # HDD Drive temp (in C) upper OK limit before a CRITICAL color/message will be used."
echo 'HDDmaxovrd="'$HDDmaxovrd'"         # HDD Max Drive Temp Override. This value when "true" will not alarm on any Current Power Cycle Max Temperature Limit.'
echo "SSDtempWarn=$SSDtempWarn            # SSD Drive temp (in C) upper OK limit before a WARNING color/message will be used."
echo "SSDtempCrit=$SSDtempCrit            # SSD Drive temp (in C) upper OK limit before a CRITICAL color/message will be used."
echo 'SSDmaxovrd="'$SSDmaxovrd'"         # SSD Max Drive Temp Override. This value when "true" will not alarm on any Current Power Cycle Max Temperature Limit.'
echo "NVMtempWarn=$NVMtempWarn            # NVM Drive temp (in C) upper OK limit before a WARNING color/message will be used."
echo "NVMtempCrit=$NVMtempCrit            # NVM Drive temp (in C) upper OK limit before a CRITICAL color/message will be used."
echo 'NVMmaxovrd="true"         # NVM Max Drive Temp Override. This value when "true" will not alarm on any Current Power Cycle Max Temperature Limit.'
echo "                          # --- NOTE: NVMe drives currently do not report Min/Max temperatures so this is a future feature."
echo " "
echo "###### SSD/NVMe Specific Settings"
echo " "
echo "wearLevelCrit=$wearLevelCrit           # Wear Level Alarm Setpoint lower OK limit before a WARNING color/message, 9% is the default."
echo " "
echo "###### General Settings"
echo "# Output Formats"
echo 'powerTimeFormat="'$powerTimeFormat'"       # Format for power-on hours string, valid options are "ymdh", "ymd", "ym", "y", or "h" (year month day hour).'
echo 'tempdisplay="'$tempdisplay'"          # The format you desire the temperature to be displayed in. Common formats are: "*C", "^C", or "^c". Choose your own.'
echo 'non_exist_value="'$non_exist_value'"     # How do you desire non-existent data to be displayed.  The Default is "---", popular options are "N/A" or " ".'
echo 'pool_capacity="'$pool_capacity'"       # Select "zfs" or "zpool" for Zpool Status Report - Pool Size and Free Space capacities. zfs is default.'
echo " "
echo "# Ignore or Activate Alarms"
echo 'ignoreUDMA="'$ignoreUDMA'"        # Set to "true" to ignore all UltraDMA CRC Errors for the summary alarm (Email Header) only, errors will appear in the graphical chart.'
echo 'ignoreSeekError="'$ignoreSeekError'"    # Set to "true" to ignore all Seek Error Rate/Health errors.  Default is true.'
echo 'ignoreReadError="'$ignoreReadError'"    # Set to "true" to ignore all Raw Read Error Rate/Health errors.  Default is true.'
echo 'ignoreMultiZone="'$ignoreMultiZone'"   # Set to "true" to ignore all MultiZone Errors. Default is false.'
echo 'disableWarranty="'$disableWarranty'"    # Set to "true to disable email Subject line alerts for any expired warranty alert. The email body will still report the alert.'
echo 'ata_auto_enable="'$ata_auto_enable'"   # Set to "true" to automatically update Log Error count to only display a log error when a new one occurs.'
echo " "
echo "# Disable or Activate Input/Output File Settings"
echo 'includeSSD="'$includeSSD'"         # Set to "true" will engage SSD Automatic Detection and Reporting, false = Disable SSD Automatic Detection and Reporting.'
echo 'includeNVM="'$includeNVM'"         # Set to "true" will engage NVM Automatic Detection and Reporting, false = Disable NVM Automatic Detection and Reporting.'
echo 'reportnonSMART="'$reportnonSMART'"     # Will force even non-SMART devices to be reported, "true" = normal operation to report non-SMART devices.'
echo 'disableRAWdata="'$disableRAWdata'"    # Set to "true" to remove the 'smartctl -a' data and non-smart data appended to the normal report.  Default is false.'
echo " "
echo "# Media Alarms"
echo "sectorsWarn=$sectorsWarn             # Number of sectors per drive to allow with errors before WARNING color/message will be used, this value should be less than sectorsCrit."
echo "sectorsCrit=$sectorsCrit             # Number of sectors per drive with errors before CRITICAL color/message will be used."
echo "reAllocWarn=$reAllocWarn             # Number of Reallocated sector events allowed.  Over this amount is an alarm condition."
echo "multiZoneWarn=$multiZoneWarn           # Number of MultiZone Errors to allow before a Warning color/message will be used.  Default is 0."
echo "multiZoneCrit=$multiZoneCrit           # Number of MultiZone Errors to allow before a Warning color/message will be used.  Default is 5."
echo 'deviceRedFlag="'$deviceRedFlag'"      # Set to "true" to have the Device Column indicate RED for ANY alarm condition.  Default is true.'
echo 'heliumAlarm="'$heliumAlarm'"        # Set to "true" to set for a critical alarm any He value below "heliumMin" value.  Default is true.'
echo "heliumMin=$heliumMin             # Set to 100 for a zero leak helium result.  An alert will occur below this value."
echo "rawReadWarn=$rawReadWarn             # Number of read errors to allow before WARNING color/message will be used, this value should be less than rawReadCrit."
echo "rawReadCrit=$rawReadCrit           # Number of read errors to allow before CRITICAL color/message will be used."
echo "seekErrorsWarn=$seekErrorsWarn          # Number of seek errors to allow before WARNING color/message will be used, this value should be less than seekErrorsCrit."
echo "seekErrorsCrit=$seekErrorsCrit        # Number of seek errors to allow before CRITICAL color/message will be used."
echo " "
echo "# Time-Limited Error Recovery (TLER)"
echo 'SCT_Drive_Enable="'$SCT_Drive_Enable'"  # Set to "true" to send a command to enable SCT on your drives for user defined timeout if the TLER state is Disabled.'
echo 'SCT_Warning="'$SCT_Warning'" # Set to "all" will generate a Warning Message for all devices not reporting SCT enabled. "TLER" reports only drive which support TLER.'
echo '                          # "TLER_No_Msg" will only report for TLER drives and not report a Warning Message if the drive can set TLER on.'
echo "SCT_Read_Timeout=$SCT_Read_Timeout       # Set to the read threshold. Default = 70 = 7.0 seconds."
echo "SCT_Write_Timeout=$SCT_Write_Timeout      # Set to the write threshold. Default = 70 = 7.0 seconds."
echo " "
echo "# SMART Testing Alarm"
echo "testAgeWarn=$testAgeWarn             # Maximum age (in days) of last SMART test before CRITICAL color/message will be used."
echo " "
echo "###### Statistical Data File"
echo 'statistical_data_file="'$statistical_data_file'"    # Default location is where the script is located.'
echo 'expDataEnable="'$expDataEnable'"      # Set to "true" will save all drive data into a CSV file defined by "statistical_data_file" below.'
echo 'expDataEmail="'$expDataEmail'"       # Set to "true" to have an attachment of the file emailed to you. Default is true.'
echo "expDataPurge=$expDataPurge          # Set to the number of day you wish to keep in the data.  Older data will be purged. Default is 730 days (2 years). 0=Disable."
echo 'expDataEmailSend="'$expDataEmailSend'"    # Set to the day of the week the statistical report is emailed.  (All, Mon, Tue, Wed, Thu, Fri, Sat, Sun, Month)'
echo " "
echo "###### FreeNAS config backup settings"
echo 'configBackup="'$configBackup'"      # Set to "true" to save config backup (which renders next two options operational); "false" to keep disable config backups.'
echo 'configSendDay="'$configSendDay'"      # Set to the day of the week the config is emailed.  (All, Mon, Tue, Wed, Thu, Fri, Sat, Sun, Month)'
echo 'saveBackup="'$saveBackup'"       # Set to "false" to delete FreeNAS config backup after mail is sent; "true" to keep it in dir below.'
echo 'backupLocation="'$backupLocation'"   # Directory in which to store the backup FreeNAS config files.'
echo " "
echo "###### Attach multi_report_config.txt to Email ######"
echo 'Config_Email_Enable="'$Config_Email_Enable'"   # Set to "true" to enable periodic email (which renders next two options operational).'
echo 'Config_Changed_Email="'$Config_Changed_Email'"  # If "true" it will attach the updated/changed file to the email.'
echo 'Config_Backup_Day="'$Config_Backup_Day'"     # Set to the day of the week the multi_report_config.txt is emailed.  (All, Mon, Tue, Wed, Thu, Fri, Sat, Sun, Month, Never)'
echo " "
echo "########## REPORT CHART CONFIGURATION ##############"
echo " "
echo "###### REPORT HEADER TITLE ######"
echo 'HDDreportTitle="'$HDDreportTitle'"     # This is the title of the HDD report, change as you desire.'
echo 'SSDreportTitle="'$SSDreportTitle'"               # This is the title of the SSD report, change as you desire.'
echo 'NVMreportTitle="'$NVMreportTitle'"              # This is the title of the NVMe report, change as you desire.'
echo " "
echo "### CUSTOM REPORT CONFIGURATION ###"
echo "# By default most items are selected. Change the item to "false" to have it not displayed in the graph, "true" to have it displayed."
echo "# NOTE: Alarm setpoints are not affected by these settings, this is only what columns of data are to be displayed on the graph."
echo "# I would recommend that you remove columns of data that you don't really care about to make the graph less busy."
echo " "
echo "# For Zpool Status Summary"
echo 'Zpool_Pool_Name_Title="'$Zpool_Pool_Name_Title'"'
echo 'Zpool_Status_Title="'$Zpool_Status_Title'"'
echo 'Zpool_Pool_Size_Title="'$Zpool_Pool_Size_Title'"'
echo 'Zpool_Free_Space_Title="'$Zpool_Free_Space_Title'"'
echo 'Zpool_Used_Space_Title="'$Zpool_Used_Space_Title'"'
echo 'Zfs_Pool_Size_Title="'$Zfs_Pool_Size_Title'"'
echo 'Zfs_Free_Space_Title="'$Zfs_Free_Space_Title'"'
echo 'Zfs_Used_Space_Title="'$Zfs_Used_Space_Title'"'
echo 'Zpool_Read_Errors_Title="'$Zpool_Read_Errors_Title'"'
echo 'Zpool_Write_Errors_Title="'$Zpool_Write_Errors_Title'"'
echo 'Zpool_Checksum_Errors_Title="'$Zpool_Checksum_Errors_Title'"'
echo 'Zpool_Scrub_Repaired_Title="'$Zpool_Scrub_Repaired_Title'"'
echo 'Zpool_Scrub_Errors_Title="'$Zpool_Scrub_Errors_Title'"'
echo 'Zpool_Scrub_Age_Title="'$Zpool_Scrub_Age_Title'"'
echo 'Zpool_Scrub_Duration_Title="'$Zpool_Scrub_Duration_Title'"'
echo " "
echo "# For Hard Drive Section"
echo 'HDD_Device_ID="'$HDD_Device_ID'"'
echo 'HDD_Device_ID_Title="'$HDD_Device_ID_Title'"'
echo 'HDD_Serial_Number="'$HDD_Serial_Number'"'
echo 'HDD_Serial_Number_Title="'$HDD_Serial_Number_Title'"'
echo 'HDD_Model_Number="'$HDD_Model_Number'"'
echo 'HDD_Model_Number_Title="'$HDD_Model_Number_Title'"'
echo 'HDD_Capacity="'$HDD_Capacity'"'
echo 'HDD_Capacity_Title="'$HDD_Capacity_Title'"'
echo 'HDD_Rotational_Rate="'$HDD_Rotational_Rate'"'
echo 'HDD_Rotational_Rate_Title="'$HDD_Rotational_Rate_Title'"'
echo 'HDD_SMART_Status="'$HDD_SMART_Status'"'
echo 'HDD_SMART_Status_Title="'$HDD_SMART_Status_Title'"'
echo 'HDD_Warranty="'$HDD_Warranty'"'
echo 'HDD_Warranty_Title="'$HDD_Warranty_Title'"'
echo 'HDD_Raw_Read_Error_Rate="'$HDD_Raw_Read_Error_Rate'"'
echo 'HDD_Raw_Read_Error_Rate_Title="'$HDD_Raw_Read_Error_Rate_Title'"'
echo 'HDD_Drive_Temp="'$HDD_Drive_Temp'"'
echo 'HDD_Drive_Temp_Title="'$HDD_Drive_Temp_Title'"'
echo 'HDD_Drive_Temp_Min="'$HDD_Drive_Temp_Min'"'
echo 'HDD_Drive_Temp_Min_Title="'$HDD_Drive_Temp_Min_Title'"'
echo 'HDD_Drive_Temp_Max="'$HDD_Drive_Temp_Max'"'
echo 'HDD_Drive_Temp_Max_Title="'$HDD_Drive_Temp_Max_Title'"'
echo 'HDD_Power_On_Hours="'$HDD_Power_On_Hours'"'
echo 'HDD_Power_On_Hours_Title="'$HDD_Power_On_Hours_Title'"'
echo 'HDD_Start_Stop_Count="'$HDD_Start_Stop_Count'"'
echo 'HDD_Start_Stop_Count_Title="'$HDD_Start_Stop_Count_Title'"'
echo 'HDD_Load_Cycle="'$HDD_Load_Cycle'"'
echo 'HDD_Load_Cycle_Title="'$HDD_Load_Cycle_Title'"'
echo 'HDD_Spin_Retry="'$HDD_Spin_Retry'"'
echo 'HDD_Spin_Retry_Title="'$HDD_Spin_Retry_Title'"'
echo 'HDD_Reallocated_Sectors="'$HDD_Reallocated_Sectors'"'
echo 'HDD_Reallocated_Sectors_Title="'$HDD_Reallocated_Sectors_Title'"'
echo 'HDD_Reallocated_Events="'$HDD_Reallocated_Events'"'
echo 'HDD_Reallocated_Events_Title="'$HDD_Reallocated_Events_Title'"'
echo 'HDD_Pending_Sectors="'$HDD_Pending_Sectors'"'
echo 'HDD_Pending_Sectors_Title="'$HDD_Pending_Sectors_Title'"'
echo 'HDD_Offline_Uncorrectable="'$HDD_Offline_Uncorrectable'"'
echo 'HDD_Offline_Uncorrectable_Title="'$HDD_Offline_Uncorrectable_Title'"'
echo 'HDD_UDMA_CRC_Errors="'$HDD_UDMA_CRC_Errors'"'
echo 'HDD_UDMA_CRC_Errors_Title="'$HDD_UDMA_CRC_Errors_Title'"'
echo 'HDD_Seek_Error_Rate="'$HDD_Seek_Error_Rate'"'
echo 'HDD_Seek_Error_Rate_Title="'$HDD_Seek_Error_Rate_Title'"'
echo 'HDD_MultiZone_Errors="'$HDD_MultiZone_Errors'"'
echo 'HDD_MultiZone_Errors_Title="'$HDD_MultiZone_Errors_Title'"'
echo 'HDD_Helium_Level="'$HDD_Helium_Level'"'
echo 'HDD_Helium_Level_Title="'$HDD_Helium_Level_Title'"'
echo 'HDD_Last_Test_Age="'$HDD_Last_Test_Age'"'
echo 'HDD_Last_Test_Age_Title="'$HDD_Last_Test_Age_Title'"'
echo 'HDD_Last_Test_Type="'$HDD_Last_Test_Type'"'
echo 'HDD_Last_Test_Type_Title="'$HDD_Last_Test_Type_Title'"'
echo " "
echo "# For Solid State Drive Section"
echo 'SSD_Device_ID="'$SSD_Device_ID'"'
echo 'SSD_Device_ID_Title="'$SSD_Device_ID_Title'"'
echo 'SSD_Serial_Number="'$SSD_Serial_Number'"'
echo 'SSD_Serial_Number_Title="'$SSD_Serial_Number_Title'"'
echo 'SSD_Model_Number="'$SSD_Model_Number'"'
echo 'SSD_Model_Number_Title="'$SSD_Model_Number_Title'"'
echo 'SSD_Capacity="'$SSD_Capacity'"'
echo 'SSD_Capacity_Title="'$SSD_Capacity_Title'"'
echo 'SSD_SMART_Status="'$SSD_SMART_Status'"'
echo 'SSD_SMART_Status_Title="'$SSD_SMART_Status_Title'"'
echo 'SSD_Warranty="'$SSD_Warranty'"'
echo 'SSD_Warranty_Title="'$SSD_Warranty_Title'"'
echo 'SSD_Drive_Temp="'$SSD_Drive_Temp'"'
echo 'SSD_Drive_Temp_Title="'$SSD_Drive_Temp_Title'"'
echo 'SSD_Drive_Temp_Min="'$SSD_Drive_Temp_Min'"'
echo 'SSD_Drive_Temp_Min_Title="'$SSD_Drive_Temp_Min_Title'"'
echo 'SSD_Drive_Temp_Max="'$SSD_Drive_Temp_Max'"'
echo 'SSD_Drive_Temp_Max_Title="'$SSD_Drive_Temp_Max_Title'"'
echo 'SSD_Power_On_Hours="'$SSD_Power_On_Hours'"'
echo 'SSD_Power_On_Hours_Title="'$SSD_Power_On_Hours_Title'"'
echo 'SSD_Wear_Level="'$SSD_Wear_Level'"'
echo 'SSD_Wear_Level_Title="'$SSD_Wear_Level_Title'"'
echo 'SSD_Reallocated_Sectors="'$SSD_Reallocated_Sectors'"'
echo 'SSD_Reallocated_Sectors_Title="'$SSD_Reallocated_Sectors_Title'"'
echo 'SSD_Reallocated_Events="'$SSD_Reallocated_Events'"'
echo 'SSD_Reallocated_Events_Title="'$SSD_Reallocated_Events_Title'"'
echo 'SSD_Pending_Sectors="'$SSD_Pending_Sectors'"'
echo 'SSD_Pending_Sectors_Title="'$SSD_Pending_Sectors_Title'"'
echo 'SSD_Offline_Uncorrectable="'$SSD_Offline_Uncorrectable'"'
echo 'SSD_Offline_Uncorrectable_Title="'$SSD_Offline_Uncorrectable_Title'"'
echo 'SSD_UDMA_CRC_Errors="'$SSD_UDMA_CRC_Errors'"'
echo 'SSD_UDMA_CRC_Errors_Title="'$SSD_UDMA_CRC_Errors_Title'"'
echo 'SSD_Last_Test_Age="'$SSD_Last_Test_Age'"'
echo 'SSD_Last_Test_Age_Title="'$SSD_Last_Test_Age_Title'"'
echo 'SSD_Last_Test_Type="'$SSD_Last_Test_Type'"'
echo 'SSD_Last_Test_Type_Title="'$SSD_Last_Test_Type_Title'"'
echo " "
echo "# For NVMe Drive Section"
echo 'NVM_Device_ID="'$NVM_Device_ID'"'
echo 'NVM_Device_ID_Title="'$NVM_Device_ID_Title'"'
echo 'NVM_Serial_Number="'$NVM_Serial_Number'"'
echo 'NVM_Serial_Number_Title="'$NVM_Serial_Number_Title'"'
echo 'NVM_Model_Number="'$NVM_Model_Number'"'
echo 'NVM_Model_Number_Title="'$NVM_Model_Number_Title'"'
echo 'NVM_Capacity="'$NVM_Capacity'"'
echo 'NVM_Capacity_Title="'$NVM_Capacity_Title'"'
echo 'NVM_SMART_Status="'$NVM_SMART_Status'"'
echo 'NVM_SMART_Status_Title="'$NVM_SMART_Status_Title'"'
echo 'NVM_Warranty="'$NVM_Warranty'"'
echo 'NVM_Warranty_Title="'$NVM_Warranty_Title'"'
echo 'NVM_Critical_Warning="'$NVM_Critical_Warning'"'
echo 'NVM_Critical_Warning_Title="'$NVM_Critical_Warning_Title'"'
echo 'NVM_Drive_Temp="'$NVM_Drive_Temp'"'
echo 'NVM_Drive_Temp_Title="'$NVM_Drive_Temp_Title'"'
echo 'NVM_Drive_Temp_Min="'$NVM_Drive_Temp_Min'"               # I have not found this on an NVMe drive yet, so set to false'
echo 'NVM_Drive_Temp_Min_Title="'$NVM_Drive_Temp_Min_Title'"'
echo 'NVM_Drive_Temp_Max="'$NVM_Drive_Temp_Max'"               # I have not found this on an NVMe drive yet, so set to false'
echo 'NVM_Drive_Temp_Max_Title="'$NVM_Drive_Temp_Max_Title'"'
echo 'NVM_Power_On_Hours="'$NVM_Power_On_Hours'"'
echo 'NVM_Power_On_Hours_Title="'$NVM_Power_On_Hours_Title'"'
echo 'NVM_Wear_Level="'$NVM_Wear_Level'"'
echo 'NVM_Wear_Level_Title="'$NVM_Wear_Level_Title'"'
echo " "
echo " "
echo "###### Drive Ignore List"
echo "# What does it do:"
echo "#  Use this to list any drives to ignore and remove from the report.  This is very useful for ignoring USB Flash Drives"
echo '#  or other drives for which good data is not able to be collected (non-standard).'
echo "#"
echo "# How to use it:"
echo "#  We are using a comma delimited file to identify the drive serial numbers.  You MUST use the exact and full serial"
echo "#  number smartctl reports, if there is no identical match then it will not match. Additionally you may list drives"
echo "#  from other systems and they will not have any effect on a system where the drive does not exist.  This is great"
echo "#  to have one configuration file that can be used on several systems."
echo "#"
echo '# Example: "VMWare,1JUMLBD,21HNSAFC21410E"'
if  [[ $Ignore_Drives == "VMWare,1JUMLBD,21HNSAFC21410E" ]]; then Ignore_Drives="none"; fi
echo " "
echo 'Ignore_Drives="'$Ignore_Drives'"'
echo " "
echo "###### Drive UDMA_CRC_Error_Count List"
echo "# What does it do:"
echo '#  If you have a drive which has an UDMA count other than 0 (zero), this setting will offset the'
echo "#  value back to zero for the concerns of monitoring future increases of this specific error. Any match will"
echo '#  subtract the given value to report a 0 (zero) value and highlight it in yellow to denote it was overridden.'
echo "#  The Warning Title will not be flagged if this is zero'd out in this manner."
echo "#  NOTE: UDMA_CRC_Errors are typically permanently stored in the drive and cannot be reset to zero even though"
echo "#        they are frequently caused by a data cable communications error."
echo "#"
echo "# How to use it:"
echo "#  List each drive by serial number and include the current UDMA_CRC_Error_Count value."
echo "#  The format is very specific and will not work if you "wing it", use the Live EXAMPLE."
echo "#"
echo "#  Set the FLAG in the FLAGS Section ignoreUDMA to false."
echo "#"
echo "# If the error count exceeds the limit minus the offset then a warning message will be generated."
echo "# On the Status Report the UDMA CRC Errors block will be YELLOW with a value of "0" for an overridden value."
echo "#   -- NOTE: We are using the colon : as the separator between the drive serial number and the value to change."
echo "#"
echo "# Format: variable="Drive_Serial_Number:Current_UDMA_Error_Count" and add a comma if you have more than one drive."
echo "#"
echo "# The below example shows drive WD-WMC4N2578099 has 1 UDMA_CRC_Error, drive S2X1J90CA48799 has 2 errors."
echo "#"
echo '# Live Example: "WD-WMC4N2578099:1,S2X1J90CA48799:2,P02618119268:1"'
echo " "
# Below line retaned to be able to update from version 1.6c
if [[ ! $CRC_ERRORS == "" ]]; then CRC_Errors=$CRC_ERRORS; fi
echo 'CRC_Errors="'$CRC_Errors'"'
echo " "
echo "###### Multi_Zone_Errors List"
echo "# What does it do:"
echo "#   This identifies drives with Multi_Zone_Errors which may be irritating people."
echo "#   Multi_Zone_Errors "for some drives, not all drives" are pretty much meaningless."
echo "#"
echo "# How to use it:"
echo '#   Use same format as CRC_Errors.'
echo " "
# Below line retaned to be able to update from version 1.6c
if [[ ! $MULTI_Zone == "" ]]; then Multi_Zone=$MULTI_Zone; fi
echo 'Multi_Zone="'$Multi_Zone'"'
echo " "
echo "#######  Reallocated Sectors Exceptions"
echo "# What does it do:"
echo "#  This will offset any Reallocated Sectors count by the value provided."
echo "#"
echo "#  I do not recommend using this feature as I'm a believer in if you have over 5 bad sectors, odds are the drive will get worse."
echo "#  I'd recommend replacing the drive before complete failure.  But that is your decision."
echo "#"
echo "#  Why is it even an option?"
echo "#  I use it for testing purposes only but you may want to use it."
echo "#"
echo "# How to use it:"
echo '#   Use same format as CRC_Errors.'
echo " "
# Below line retaned to be able to update from version 1.6c
if [[ ! $BAD_SECTORS == "" ]]; then Bad_Sectors=$BAD_SECTORS; fi
echo 'Bad_Sectors="'$Bad_Sectors'"'
echo " "
echo "######## ATA Error Log Silencing ##################"
echo "# What does it do:"
echo "#   This will ignore error log messages equal to or less than the threshold."
echo "# How to use:"
echo "#  Same as the CRC_Errors, [drive serial number:error count]"
echo " "
echo 'ata_errors="'$ata_errors'"'
echo " "
echo "####### Custom Drive Configuration (Experimental)"
echo "# Used to define specific alarm values for specific drives by serial number."
echo "# This should only be used for drives where the default alarm settings"
echo "# are not proper.  Up to 24 unique drive values may be stored."
echo "#"
echo "# Use -config to set these values."
echo " "
echo 'Custom_Drives="'$Custom_Drives'"'
echo " "
echo "####### Warranty Expiration Date"
echo "# What does it do:"
echo "# This section is used to add warranty expirations for designated drives and to create an alert when they expire."
echo "# The date format is YYYY-MM-DD."
echo "#"
echo "# Below is an example for the format using my own drives, which yes, are expired."
echo "# As previously stated above, drive serial numbers must be an exact match to what smartctl reports to function."
echo "#"
echo "# If the drive does not exist, for example my drives are not on your system, then nothing will happen."
echo "#"
echo "# How to use it:"
echo '#   Use the format ="Drive_Serial_Number:YYYY-MM-DD" and add a comma if you have more than one drive.'
echo '#  Example: $Drive_Warranty="K1JUMLBD:2020-09-30,K1JRSWLD:2020-09-30,K1JUMW4D:2020-09-30,K1GVD84B:2020-10-12"'
echo " "
# Below line retained to be able to update from version 1.6c
if [[ ! $DRIVE_WARRANTY == "" ]]; then Drive_Warranty=$DRIVE_WARRANTY; fi
if [[ ! $Joes_System == "true" ]] && [[ $Drive_Warranty == "K1JUMLBD:2020-09-30,K1JRSWLD:2020-09-30,K1JUMW4D:2020-09-30,K1GVD84B:2020-10-12" ]]; then Drive_Warranty="none"; fi
echo 'Drive_Warranty="'$Drive_Warranty'"'
echo " "
echo '######## Expired Drive Warranty Setup'
echo 'expiredWarrantyBoxColor="'$expiredWarrantyBoxColor'"   # "black" = normal box perimeter color.'
echo 'WarrantyBoxPixels="'$WarrantyBoxPixels'"   # Box line thickness. 1 = normal, 2 = thick, 3 = Very Thick, used for expired drives only.'
echo 'WarrantyBackgndColor="'$WarrantyBackgndColor'"  # Background color for expired drives. "none" = normal background.'
echo " "
echo '######## Enable-Disable Text Portion ########'
echo 'enable_text="'$enable_text'"    # This will display the Text Section when = "true" or remove it when not "true".  Default="true"'
echo " "
echo "###### Global table of colors"
echo "# The colors selected you can change but you will need to look up the proper HEX code for a color."
echo " "
echo 'okColor="'$okColor'"       # Hex code for color to use in SMART Status column if drives pass (default is darker light green, #b5fcb9).'
echo 'warnColor="'$warnColor'"     # Hex code for WARN color (default is purple, #f765d0).'
echo 'critColor="'$critColor'"     # Hex code for CRITICAL color (default is red, #ff0000).'
echo 'altColor="'$altColor'"      # Table background alternates row colors between white and this color (default is light gray, #f4f4f4).'
echo 'whtColor="'$whtColor'"      # Hex for White background.'
echo 'ovrdColor="'$ovrdColor'"     # Hex code for Override Yellow.'
echo 'blueColor="'$blueColor'"     # Hex code for Sky Blue, used for the SCRUB In Progress background.'
echo 'yellowColor="'$yellowColor'"   # Hex code for pale yellow.'

) > "$Config_File_Name"
if [[ $Config_Changed_Email == "true" ]]; then Attach_Config="1"; fi
}

################################## CLEAN UP TEMPORARY FILES #######################################

cleanup_files () {
### Clean up our temporary files
if test -e "$logfile"; then rm "$logfile"; fi
if test -e "$logfile_header"; then rm "$logfile_header"; fi
if test -e "$logfile_critical"; then rm "$logfile_critical"; fi
if test -e "$logfile_warning"; then rm "$logfile_warning"; fi
if test -e "$logfile_warranty"; then rm "$logfile_warranty"; fi
if test -e "$logfile_messages"; then rm "$logfile_messages"; fi
f=(/tmp/drive_*.txt)
if [[ -f "${f[0]}" ]]; then rm /tmp/drive_*.txt; fi
}

################################# CLEAR VARIABLES ###############################################

clear_variables () {

### Null out variables for get_drive_data function before using them again

altlastTestHours=""
altlastTestType=""
capacity=""
chkreadfailure=""
crcErrors=""
lastTestHours=""
lastTestType=""
loadCycle=""
modelnumber=""
multiZone=""
NVMcriticalWarning=""
offlineUnc=""
onHours=""
pending=""
reAlloc=""
reAllocEvent=""
rotation=""
seekErrorHealth=""
seekErrorHealth2=""
serial=""
smartStatus=""
smarttesting=""
startStop=""
spinRetry=""
temp=""
temp_max=""
temp_min=""
wearLevel=""
onTime=""
testAge=""
SER=""
Helium=""
seagate=""
seekErrorRate=""
rawReadErrorRate=""
rawReadErrorRate2=""
seek=""
test_ata_error=""
WarrantyClock=""
warrantytemp=""


# And Reset bgColors
if [[ "$bgColor" == "$altColor" ]]; then bgColor="#ffffff"; else bgColor="$altColor"; fi
deviceStatusColor=$bgColor
smartStatusColor=$bgColor
tempColor=$bgColor
temp_maxColor=$bgColor
onTimeColor=$bgColor
spinRetryColor=$bgColor
reAllocColor=$bgColor
reAllocEventColor=$bgColor
pendingColor=$bgColor
offlineUncColor=$bgColor
crcErrorsColor=$bgColor
seekErrorHealthColor=$bgColor
rawReadErrorRateColor=$bgColor
multiZoneColor=$bgColor
testAgeColor=$bgColor
lastTestTypeColor=$bgColor
wearLevelColor=$bgColor
NVMcriticalWarningColor=$bgColor
HeliumColor=$bgColor
WarrantyBoxColor="black"
WarrantyBackgroundColor=$bgColor
#WarrantyBoxPixels="1"
}

################# GENERATE CONFIG FILE ##############

generate_config_file () {

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
Config_File_Name="$SCRIPT_DIR/multi_report_config.txt"
for (( z=1; z<=50; z++ ))
do
clear
echo $programver
echo " "
echo "         Configuration File Management"
echo " "
if test -e "$Config_File_Name"; then
   echo " *** WARNING - A CONFIGURATION CURRENTLY FILE EXISTS ***"
fi
echo " "
echo " "
echo "  Select an option and press Enter/Return:"
echo " "
echo "      N)ew configuration file  (creates a new clean configuration external file)"
echo " "
echo "      A)dvanced configuration (must have a configuration file already present)"
echo " "
echo "      H)ow to use this configuration tool (general instructions)"
echo " "
echo "      X) Exit"
echo " "
echo " "
echo "NOTE: In using this configuration script when the value is:"
echo "  Number or Text: the current value will be displayed. You have the option to"
echo "just press Enter/Return to accept the current value or you may enter a"
echo "different value."
echo " "
echo "  true or false: the current value will be displayed. You have the option to"
echo "press Enter/Return to accept the current value or you may press 't' for true"
echo "or 'f' for false."
echo " "
echo " "
echo -n "   Make your selection: "
read -n 1 Keyboard_var
shopt -s nocasematch
case $Keyboard_var in
# First Level Start
    A)
    clear
    echo " "
    echo "            Advanced Configuration Settings"
    echo " "
    echo " Loading Configuration File Data..."
    echo " "
       if [[ ! -f "$Config_File_Name" ]]; then
       echo "You do not have an external configuration file yet."
       echo "Please create an external configuration file."
       echo " "   
       exit 1
       fi
    load_config

    echo "This is not a complete configuration setup, it is just the most common settings"
    echo "that a user would typically require for a normal setup.  You may directly edit"
    echo "the config text file with any text editor to take full advantage of the options."
    echo " "
    echo "The config text file is located here: "$Config_File_Name
    echo " "
     for (( x=1; x<=50; x++ ))
     do
    clear
    echo "            Advanced Configuration Settings"
    echo " "
    echo " "
    echo "   A) Alarm Setpoints (Temp, Zpool, Media, Activate In/Out, Ignore)" 
    echo " "
    echo "   B) Config-Backup (Edit Config-Backup & Multi-Report_Config Settings)"
    echo " "
    echo "   C) Email Address (Edit email address)" 
    echo " "
    echo "   D) HDD Column Selection (Select columns to display/hide)"
    echo " "
    echo "   E) SSD Column Selection (Select columns to display/hide)"
    echo " "
    echo "   F) NVMe Column Selection (Select columns to display/hide)"
    echo " "
    echo "   G) Output Formats (Hours, Temp, Non-Existent, Pool Capacity)"
    echo " "
    echo "   H) Report Header Titles (Edit Header Titles, Add/Remove Text Section)" 
    echo " "
    echo "   I) Statistical Data File Setup"
    echo " "
    echo "   J) TLER / SCT (Setup if TLER is active)"
    echo " "
    echo "   K) Drive Errors and Custom Builds (Ignore Drives, UDMA CRC, MultiZone,"
    echo "            Reallocated Sectors, ATA Errors, Warranty Expiration,"
    echo "            and Person Specific Custom)"
    echo  " "
    echo "   S) Custom Drive Configuration (Experimental)"
    echo " "
    echo "   W) Write Configuration File (Save your changes)"
    echo " "
    echo "   X) Exit - Will not automatically save changes"
    echo " "
    echo -n "   Make your selection: "
    read -n 1 Keyboard_var2
    echo " " 
    shopt -s nocasematch
    case $Keyboard_var2 in
# Second Level Start
         A)

         for (( y=1; y<=50; y++ ))
         do
         clear
         echo "            Alarm Configuration Settings"
         echo " "
         echo " "
         echo "   A) Temperature Settings (Various Temperature Settings)" 
         echo " "
         echo "   B) Zpool Settings (Scrub Age and Pool Avail Alarms)"
         echo " "
         echo "   C) Media Alarm Settings (Sectors and CRC Type Alarms)"
         echo " "
         echo "   D) Activate Input/Output Settings (Enable SSD/NVMe/Non-SMART)" 
         echo " "
         echo "   E) Ignore Alarms (Ignore CRC/MultiZone/Seek Type Errors)"
         echo " "
         echo "   X) Exit - Return to previous menu"
         echo " "
         echo -n "   Make your selection: "
         read -n 1 Keyboard_var3
         echo " " 
         shopt -s nocasematch
         case $Keyboard_var3 in

               A)
               clear 
               echo "Temperature Settings"
               echo " "
               echo "Current value is displayed.  Enter a new value or Return to keep."
               echo " "
               echo -n "HDD Warning Temperature ("$HDDtempWarn") "
               read Keyboard_yn
               if [[ ! $Keyboard_yn == "" ]]; then HDDtempWarn=$Keyboard_yn; fi
               echo "Set Value: ("$HDDtempWarn")"
               echo " "
               echo -n "HDD Critical Temperature ("$HDDtempCrit") "
               read Keyboard_yn
               if [[ ! $Keyboard_yn == "" ]]; then HDDtempCrit=$Keyboard_yn; fi
               echo "Set Value: ("$HDDtempCrit")"
               echo " "
               echo -n "HDD Max Temperature Override for Power Cycle Enabled ("$HDDmaxovrd") "
               read -n 1 Keyboard_yn
               if [[ ! $Keyboard_yn == "" ]]; then
                  if [[ $Keyboard_yn == "t" ]]; then HDDmaxovrd="true"; else HDDmaxovrd="false"; fi
               fi
               echo "Set Value: ("$HDDmaxovrd")"
               echo " "
               echo -n "SSD Warning Temperature ("$SSDtempWarn") "
               read Keyboard_yn
               if [[ ! $Keyboard_yn == "" ]]; then SSDtempWarn=$Keyboard_yn; fi
               echo "Set Value: ("$SSDtempWarn")"
               echo " "
               echo -n "SSD Critical Temperature ("$SSDtempCrit") "
               read Keyboard_yn
               if [[ ! $Keyboard_yn == "" ]]; then SSDtempCrit=$Keyboard_yn; fi
               echo "Set Value: ("$SSDtempCrit")"
               echo " "
               echo "SSD Max Temperature Override for Power Cycle Enabled ("$SSDmaxovrd") "
               echo "This value when "true" will not alarm on any Current Power Cycle Max Temperature Limit."
               read -n 1 Keyboard_yn
               if [[ ! $Keyboard_yn == "" ]]; then
                  if [[ $Keyboard_yn == "t" ]]; then SSDmaxovrd="true"; else SSDmaxovrd="false"; fi
               fi
               echo "Set Value: ("$SSDmaxovrd")"
               echo " "
               echo -n "NVMe Warning Temperature ("$NVMtempWarn") "
               read Keyboard_yn
               if [[ ! $Keyboard_yn == "" ]]; then NVMtempWarn=$Keyboard_yn; fi
               echo "Set Value: ("$NVMtempWarn")"
               echo " "
               echo -n "NVMe Critical Temperature ("$NVMtempCrit") "
               read Keyboard_yn
               if [[ ! $Keyboard_yn == "" ]]; then NVMtempCrit=$Keyboard_yn; fi
               echo "Set Value: ("$NVMtempCrit")"
               echo " "
               echo "returning..."
               sleep 2
               ;;

               B)
               clear
               echo "Zpool Settings"
               echo " "
               echo "Scrub maximum days since last completion ("$scrubAgeWarn") "
               echo "Maximum age (in days) of last pool scrub before CRITICAL color will be used."
               read Keyboard_yn
               if [[ ! $Keyboard_yn == "" ]]; then scrubAgeWarn=$Keyboard_yn; fi
               echo "Set Value: ("$scrubAgeWarn")"
               echo " "
               echo "Pool Space Used Alert ("$usedWarn") "
               echo "Pool used percentage for CRITICAL color to be used."
               read Keyboard_yn
               if [[ ! $Keyboard_yn == "" ]]; then usedWarn=$Keyboard_yn; fi
               echo "Set Value: ("$usedWarn")"
               echo " "
               echo "returning..."
               sleep 2
               ;;

               C)
               clear
               echo "Media Alarm Settings"
               echo " "
               echo -n "SSD/NVMe Wear Level lower limit ("$wearLevelCrit") "
               read Keyboard_yn
               if [[ ! $Keyboard_yn == "" ]]; then wearLevelCrit=$Keyboard_yn; fi
               echo "Set Value: ("$wearLevelCrit")"
               echo " "
               echo -n "Sector Errors Warning ("$sectorsWarn") "
               read Keyboard_yn 
               if [[ ! $Keyboard_yn == "" ]]; then sectorsWarn=$Keyboard_yn; fi
               echo "Set Value: ("$sectorsWarn")"
               echo " "
               echo -n "Sector Errors Critical ("$sectorsCrit") "
               read Keyboard_yn
               if [[ ! $Keyboard_yn == "" ]]; then sectorsCrit=$Keyboard_yn; fi
               echo "Set Value: ("$sectorsCrit")"
               echo " "
               echo -n "Reallocated Sectors Warning ("$reAllocWarn") "
               read Keyboard_yn
               if [[ ! $Keyboard_yn == "" ]]; then reAllocWarn=$Keyboard_yn; fi
               echo "Set Value: ("$reAllocWarn")"
               echo " "
               echo -n "Raw Read Errors Warning ("$rawReadWarn") "
               read Keyboard_yn
               if [[ ! $Keyboard_yn == "" ]]; then rawReadWarn=$Keyboard_yn; fi
               echo "Set Value: ("$rawReadWarn")"
               echo " "
               echo -n "Raw Read Errors Critical ("$rawReadCrit") "
               read Keyboard_yn
               if [[ ! $Keyboard_yn == "" ]]; then rawReadCrit=$Keyboard_yn; fi
               echo "Set Value: ("$rawReadCrit")"
               echo " "
               echo -n "Seek Errors Warning ("$seekErrorsWarn") "
               read Keyboard_yn
               if [[ ! $Keyboard_yn == "" ]]; then seekErrorsWarn=$Keyboard_yn; fi
               echo "Set Value: ("$seekErrorsWarn")"
               echo " "
               echo -n "Seek Errors Critical ("$seekErrorsCrit") "
               read Keyboard_yn
               if [[ ! $Keyboard_yn == "" ]]; then seekErrorsCrit=$Keyboard_yn; fi
               echo "Set Value: ("$seekErrorsCrit")"
               echo " "
               echo -n "MultiZone Errors Warning ("$multiZoneWarn") "
               read Keyboard_yn
               if [[ ! $Keyboard_yn == "" ]]; then multiZoneWarn=$Keyboard_yn; fi
               echo "Set Value: ("$multiZoneWarn")"
               echo " "
               echo -n "MultiZone Errors Critical ("$multiZoneCrit") "
               read Keyboard_yn
               if [[ ! $Keyboard_yn == "" ]]; then multiZoneCrit=$Keyboard_yn; fi
               echo "Set Value: ("$multiZoneCrit")"
               echo " "
               echo -n "Helium Minimum Level ("$heliumMin") "
               read Keyboard_yn
               if [[ ! $Keyboard_yn == "" ]]; then heliumMin=$Keyboard_yn; fi
               echo "Set Value: ("$heliumMin")"
               echo " "
               echo "Helium Critical Alert Message ("$heliumAlarm") "
               echo 'A "true" value will generate an email subjuct line alert for a error.'
               read -n 1 Keyboard_yn
               if [[ ! $Keyboard_yn == "" ]]; then
                  if [[ $Keyboard_yn == "t" ]]; then heliumAlarm="true"; else heliumAlarm="false"; fi
               fi
               echo "Set Value: ("$heliumAlarm")"
               echo " "
               echo -n "S.M.A.R.T. Test Age Warning ("$testAgeWarn") "
               read Keyboard_yn
               if [[ ! $Keyboard_yn == "" ]]; then testAgeWarn=$Keyboard_yn; fi
               echo "Set Value: ("$testAgeWarn")"
               echo " "
               echo -n "Flag Device ID RED on Error ("$deviceRedFlag") "
               read -n 1 Keyboard_yn
               if [[ ! $Keyboard_yn == "" ]]; then
                  if [[ $Keyboard_yn == "t" ]]; then deviceRedFlag="true"; else deviceRedFlag="false"; fi
               fi
               echo "Set Value: ("$deviceRedFlag")"
               echo " "
               echo "returning..."
               sleep 2      
               ;;

               D)
               clear
               echo "Activate/Disable Input/Output Settings"
               echo " "
               echo 'Set to "true" will engage SSD Automatic Detection and Reporting'
               echo -n "Include SSD's in report ("$includeSSD") "
               read -n 1 Keyboard_yn
               if [[ ! $Keyboard_yn == "" ]]; then
                  if [[ $Keyboard_yn == "t" ]]; then includeSSD="true"; else includeSSD="false"; fi
               fi
               echo "Set Value: ("$includeSSD")"
               echo " "
               echo "Set to "true" will engage NVM Automatic Detection and Reporting"
               echo -n "Include NVMe's in report ("$includeNVM") "
               read -n 1 Keyboard_yn
               if [[ ! $Keyboard_yn == "" ]]; then
                  if [[ $Keyboard_yn == "t" ]]; then includeNVM="true"; else includeNVM="false"; fi
               fi
               echo "Set Value: ("$includeNVM")"
               echo " "
               echo "Will force even non-SMART devices to be reported"
               echo -n "Report Non-SMART Devices ("$reportnonSMART") "
               read -n 1 Keyboard_yn
               if [[ ! $Keyboard_yn == "" ]]; then
                  if [[ $Keyboard_yn == "t" ]]; then reportnonSMART="true"; else reportnonSMART="false"; fi
               fi
               echo "Set Value: ("$reportnonSMART")"
               echo " "
               echo 'Set to "true" to remove the smartctl -a data and non-smart data appended to the normal report.'
               echo -n "Remove Non-SMART Data from report ("$disableRAWdata") "
               read -n 1 Keyboard_yn
               if [[ ! $Keyboard_yn == "" ]]; then
                  if [[ $Keyboard_yn == "t" ]]; then disableRAWdata="true"; else disableRAWdata="false"; fi
               fi
               echo "Set Value: ("$disableRAWdata")"
               echo " "
               echo "returning..."
               sleep 2
               ;;

               E)
               clear
               echo "Ignore Alarm Settings"
               echo " "
               echo -n "Ignore UDMA CRC Errors ("$ignoreUDMA") "
               read -n 1 Keyboard_yn
               if [[ ! $Keyboard_yn == "" ]]; then
                  if [[ $Keyboard_yn == "t" ]]; then ignoreUDMA="true"; else ignoreUDMA="false"; fi
               fi
               echo "Set Value: ("$ignoreUDMA")"
               echo " "
               echo -n "Ignore Raw Read Errors ("$ignoreReadError") "
               read -n 1 Keyboard_yn
               if [[ ! $Keyboard_yn == "" ]]; then
                  if [[ $Keyboard_yn == "t" ]]; then ignoreReadError="true"; else ignoreReadError="false"; fi
               fi
               echo "Set Value: ("$ignoreReadError")"
               echo " "
               echo -n "Ignore Seek Errors ("$ignoreSeekError") "
               read -n 1 Keyboard_yn
               if [[ ! $Keyboard_yn == "" ]]; then
                  if [[ $Keyboard_yn == "t" ]]; then ignoreSeekError="true"; else ignoreSeekError="false"; fi
               fi
               echo "Set Value: ("$ignoreSeekError")"
               echo " "
               echo -n "Ignore MultiZone Errors ("$ignoreMultiZone") "
               read -n 1 Keyboard_yn
               if [[ ! $Keyboard_yn == "" ]]; then
                  if [[ $Keyboard_yn == "t" ]]; then ignoreMultiZone="true"; else ignoreMultiZone="false"; fi
               fi
               echo "Set Value: ("$ignoreMultiZone")"
               echo " "
               echo -n "Disable Warranty Email Header Warning ("$disableWarranty") "
               read -n 1 Keyboard_yn
               if [[ ! $Keyboard_yn == "" ]]; then
                  if [[ $Keyboard_yn == "t" ]]; then disableWarranty="true"; else disableWarranty="false"; fi
               fi
               echo "Set Value: ("$disableWarranty")"
               echo " "
               echo -n "ATA Auto Enable ("$ata_auto_enable") "
               read -n 1 Keyboard_yn
               if [[ ! $Keyboard_yn == "" ]]; then
                  if [[ $Keyboard_yn == "t" ]]; then ata_auto_enable="true"; else ata_auto_enable="false"; fi
               fi
               echo "Set Value: ("$ata_auto_enable")"
               echo " "
               echo "returning..."
               sleep 2
               ;;

               X)
              clear
              echo "Returning to the previous menu..."
              sleep 2
              y=100
              ;;


              *)
              echo "Invalid Option"
              sleep 2
              ;;
         esac
         done
         ;;


         B)
         clear
         echo "TrueNAS Configuration Backup Setup"
         echo " "
         echo -n "Save a local copy of the config-backup file (t/f) ("$saveBackup") "
         read -n 1 Keyboard_yn
         if [[ ! $Keyboard_yn == "" ]]; then
            if [[ $Keyboard_yn == "t" ]]; then saveBackup="true"; else saveBackup="false"; fi
         fi
         echo "Set Value: ("$saveBackup")"
         echo " "
         echo "TrueNAS Backup Configuration file location ("$backupLocation")"
         echo -n "Enter new location or press Enter/Return to accept current value:"
         read Keyboard_yn
         if [[ ! $Keyboard_yn == "" ]]; then backupLocation=$Keyboard_yn; fi
         echo "Set Value: ("$backupLocation")"
         echo " "
         echo -n "Configuration Backup Enabled ("$configBackup") "
         read -n 1 Keyboard_yn
         if [[ ! $Keyboard_yn == "" ]]; then
            if [[ $Keyboard_yn == "t" ]]; then configBackup="true"; else configBackup="false"; fi
         fi
         echo "Set Value: ("$configBackup")"
         echo " "
         echo "What day of the week would you like the file attached?"
         echo "Current Value: "$configSendDay
         echo "(All, Mon, Tue, Wed, Thu, Fri, Sat, Sun, Month)"
         echo -n "Enter: "
         read Keyboard_HDD
         if [[ ! $Keyboard_HDD == "" ]]; then configSendDay=$Keyboard_HDD; fi
         echo "Set Value: ("$configSendDay")"
         echo " "
         sleep .5
         clear
         echo '"multi_report_config.txt" Backup Setup'
         echo " "
         echo -n "Enable sending multi_report_config.txt file (will enable next two options if true) (t/f) ("$Config_Email_Enable") "
         read -n 1 Keyboard_yn
         if [[ ! $Keyboard_yn == "" ]]; then
            if [[ $Keyboard_yn == "t" ]]; then Config_Email_Enable="true"; else Config_Email_Enable="false"; fi
         fi
         echo "Set Value: ("$Config_Email_Enable")"
         echo " "
         echo "What day of the week would you like the file attached?"
         echo "Current Value: "$Config_Backup_Day
         echo "(All, Mon, Tue, Wed, Thu, Fri, Sat, Sun, Month, Never)"
         echo -n "Enter: "
         read Keyboard_HDD
         if [[ ! $Keyboard_HDD == "" ]]; then Config_Backup_Day=$Keyboard_HDD; fi
         echo "Set Value: ("$Config_Backup_Day")"
         echo " "
         echo " "
         echo -n "Send email of multi_report_config.txt file for any change (t/f) ("$Config_Changed_Email") "
         read -n 1 Keyboard_yn
         if [[ ! $Keyboard_yn == "" ]]; then
            if [[ $Keyboard_yn == "t" ]]; then Config_Changed_Email="true"; else Config_Changed_Email="false"; fi
         fi
         echo "Set Value: ("$Config_Changed_Email")"
         echo " "


         echo "returning..."
         sleep 2
         ;;


         C)
         clear
         echo "Email Settings"
         echo " "
         echo "Current email address(s): "$email" "
         echo "separate multiple email addresses with a comma "
         echo -n 'Enter nothing to accept the default or change it: '
         read Keyboard_email
         if [[ ! $Keyboard_email == "" ]]; then email=$Keyboard_email; fi
         echo "Set Value: "$email
         echo " "
         echo " "
         echo "Current from address: "$from" "
         echo 'While most people are able to use the default "from" address,'
         echo 'Some email servers will not work unless you use the email address'
         echo 'the email address the server is assocciated with.'
         echo -n 'Enter nothing to accept the default or change it: '
         read Keyboard_email
         if [[ ! $Keyboard_email == "" ]]; then from=$Keyboard_email; fi
         echo "Set Value: "$from
         echo " "
         echo "returning..."
         sleep 2
         ;;


         D)
         clear
         echo "HDD Column Selection"
         echo " "
         echo -n "Device ID ("$HDD_Device_ID") "  
         read -n 1 Keyboard_yn
         if [[ ! $Keyboard_yn == "" ]]; then
            if [[ $Keyboard_yn == "t" ]]; then HDD_Device_ID="true"; else HDD_Device_ID="false"; fi
         fi
         echo "Set Value: ("$HDD_Device_ID")"
         echo " "
         echo -n "Serial Number ("$HDD_Serial_Number") "
         read -n 1 Keyboard_yn
         if [[ ! $Keyboard_yn == "" ]]; then
            if [[ $Keyboard_yn == "t" ]]; then HDD_Serial_Number="true"; else HDD_Serial_Number="false"; fi
         fi
         echo "Set Value: ("$HDD_Serial_Number")"
         echo " "
         echo -n "Model Number ("$HDD_Model_Number") "
         read -n 1 Keyboard_yn
         if [[ ! $Keyboard_yn == "" ]]; then
            if [[ $Keyboard_yn == "t" ]]; then HDD_Model_Number="true"; else HDD_Model_Number="false"; fi
         fi
         echo "Set Value: ("$HDD_Model_Number")"
         echo " "
         echo -n "Capacity ("$HDD_Capacity") "
         read -n 1 Keyboard_yn
         if [[ ! $Keyboard_yn == "" ]]; then
            if [[ $Keyboard_yn == "t" ]]; then HDD_Capacity="true"; else HDD_Capacity="false"; fi
         fi
         echo "Set Value: ("$HDD_Capacity")"
         echo " "
         echo -n "Rotational Rate ("$HDD_Rotational_Rate") "
         read -n 1 Keyboard_yn
         if [[ ! $Keyboard_yn == "" ]]; then
            if [[ $Keyboard_yn == "t" ]]; then HDD_Rotational_Rate="true"; else HDD_Rotational_Rate="false"; fi
         fi
         echo "Set Value: ("$HDD_Rotational_Rate")"
         echo " "
         echo -n "SMART Status ("$HDD_SMART_Status") "
         read -n 1 Keyboard_yn
         if [[ ! $Keyboard_yn == "" ]]; then
            if [[ $Keyboard_yn == "t" ]]; then HDD_SMART_Status="true"; else HDD_SMART_Status="false"; fi
         fi
         echo "Set Value: ("$HDD_SMART_Status")"
         echo " "
         echo -n "Warranty ("$HDD_Warranty") "
         read -n 1 Keyboard_yn
         if [[ ! $Keyboard_yn == "" ]]; then
            if [[ $Keyboard_yn == "t" ]]; then HDD_Warranty="true"; else HDD_Warranty="false"; fi
         fi
         echo "Set Value: ("$HDD_Warranty")"
         echo " "
         echo -n "Drive Temp ("$HDD_Drive_Temp") "
         read -n 1 Keyboard_yn
         if [[ ! $Keyboard_yn == "" ]]; then
            if [[ $Keyboard_yn == "t" ]]; then HDD_Drive_Temp="true"; else HDD_Drive_Temp="false"; fi
         fi
         echo "Set Value: ("$HDD_Drive_Temp")"
         echo " "
         echo -n "Drive Temp Minimum for power cycle ("$HDD_Drive_Temp_Min") "
         read -n 1 Keyboard_yn
         if [[ ! $Keyboard_yn == "" ]]; then
            if [[ $Keyboard_yn == "t" ]]; then HDD_Drive_Temp_Min="true"; else HDD_Drive_Temp_Min="false"; fi
         fi
         echo "Set Value: ("$HDD_Drive_Temp_Min")"
         echo " "
         echo -n "Drive Temp Maximum for power cycle ("$HDD_Drive_Temp_Max") "
         read -n 1 Keyboard_yn
         if [[ ! $Keyboard_yn == "" ]]; then
            if [[ $Keyboard_yn == "t" ]]; then HDD_Drive_Temp_Max="true"; else HDD_Drive_Temp_Max="false"; fi
         fi
         echo "Set Value: ("$HDD_Drive_Temp_Max")"
         echo " "
         echo -n "Power On Hours ("$HDD_Power_On_Hours") "
         read -n 1 Keyboard_yn
         if [[ ! $Keyboard_yn == "" ]]; then
            if [[ $Keyboard_yn == "t" ]]; then HDD_Power_On_Hours="true"; else HDD_Power_On_Hours="false"; fi
         fi
         echo "Set Value: ("$HDD_Power_On_Hours")"
         echo " "
         echo -n "Start / Stop Count ("$HDD_Start_Stop_Count") "
         read -n 1 Keyboard_yn
         if [[ ! $Keyboard_yn == "" ]]; then
            if [[ $Keyboard_yn == "t" ]]; then HDD_Start_Stop_Count="true"; else HDD_Start_Stop_Count="false"; fi
         fi
         echo "Set Value: ("$HDD_Start_Stop_Count")"
         echo " "
         echo -n "Load Cycle Count ("$HDD_Load_Cycle") "
         read -n 1 Keyboard_yn
         if [[ ! $Keyboard_yn == "" ]]; then
            if [[ $Keyboard_yn == "t" ]]; then HDD_Load_Cycle="true"; else HDD_Load_Cycle="false"; fi
         fi
         echo "Set Value: ("$HDD_Load_Cycle")"
         echo " "
         echo -n "Spin Retry Count ("$HDD_Spin_Retry") "
         read -n 1 Keyboard_yn
         if [[ ! $Keyboard_yn == "" ]]; then
            if [[ $Keyboard_yn == "t" ]]; then HDD_Spin_Retry="true"; else HDD_Spin_Retry="false"; fi
         fi
         echo "Set Value: ("$HDD_Spin_Retry")"
         echo " "
         echo -n "Reallocated Sectors ("$HDD_Reallocated_Sectors") "
         read -n 1 Keyboard_yn
         if [[ ! $Keyboard_yn == "" ]]; then
            if [[ $Keyboard_yn == "t" ]]; then HDD_Reallocated_Sectors="true"; else HDD_Reallocated_Sectors="false"; fi
         fi
         echo "Set Value: ("$HDD_Reallocated_Sectors")"
         echo " "
         echo -n "Reallocated Events ("$HDD_Reallocated_Events") "
         read -n 1 Keyboard_yn
         if [[ ! $Keyboard_yn == "" ]]; then
            if [[ $Keyboard_yn == "t" ]]; then HDD_Reallocated_Events="true"; else HDD_Reallocated_Events="false"; fi
         fi
         echo "Set Value: ("$HDD_Reallocated_Events")"
         echo " "
         echo -n "Pending Sectors ("$HDD_Pending_Sectors") "
         read -n 1 Keyboard_yn
         if [[ ! $Keyboard_yn == "" ]]; then
            if [[ $Keyboard_yn == "t" ]]; then HDD_Pending_Sectors="true"; else HDD_Pending_Sectors="false"; fi
         fi
         echo "Set Value: ("$HDD_Pending_Sectors")"
         echo " "
         echo -n "Offline Uncorrectable Errors ("$HDD_Offline_Uncorrectable") "
         read -n 1 Keyboard_yn
         if [[ ! $Keyboard_yn == "" ]]; then
            if [[ $Keyboard_yn == "t" ]]; then HDD_Offline_Uncorrectable="true"; else HDD_Offline_Uncorrectable="false"; fi
         fi
         echo "Set Value: ("$HDD_Offline_Uncorrectable")"
         echo " "
         echo -n "UDMA CRC Errors ("$HDD_UDMA_CRC_Errors") "
         read -n 1 Keyboard_yn
         if [[ ! $Keyboard_yn == "" ]]; then
            if [[ $Keyboard_yn == "t" ]]; then HDD_UDMA_CRC_Errors="true"; else HDD_UDMA_CRC_Errors="false"; fi
         fi
         echo "Set Value: ("$HDD_UDMA_CRC_Errors")"
         echo " "
         echo -n "Raw Read Error Rate ("$HDD_Raw_Read_Error_Rate") "
         read -n 1 Keyboard_yn
         if [[ ! $Keyboard_yn == "" ]]; then
            if [[ $Keyboard_yn == "t" ]]; then HDD_Raw_Read_Error_Rate="true"; else HDD_Raw_Read_Error_Rate="false"; fi
         fi
         echo "Set Value: ("$HDD_Raw_Read_Error_Rate")"
         echo " "
         echo -n "Seek Error Rate ("$HDD_Seek_Error_Rate") "
         read -n 1 Keyboard_yn
         if [[ ! $Keyboard_yn == "" ]]; then
            if [[ $Keyboard_yn == "t" ]]; then HDD_Seek_Error_Rate="true"; else HDD_Seek_Error_Rate="false"; fi
         fi
         echo "Set Value: ("$HDD_Seek_Error_Rate")"
         echo " "
         echo -n "MultiZone Errors ("$HDD_MultiZone_Errors") "
         read -n 1 Keyboard_yn
         if [[ ! $Keyboard_yn == "" ]]; then
            if [[ $Keyboard_yn == "t" ]]; then HDD_MultiZone_Errors="true"; else HDD_MultiZone_Errors="false"; fi
         fi
         echo "Set Value: ("$HDD_MultiZone_Errors")"
         echo " "
         echo -n "Helium Level ("$HDD_Helium_Level") "
         read -n 1 Keyboard_yn
         if [[ ! $Keyboard_yn == "" ]]; then
            if [[ $Keyboard_yn == "t" ]]; then HDD_Helium_Level="true"; else HDD_Helium_Level="false"; fi
         fi
         echo "Set Value: ("$HDD_Helium_Level")"
         echo " "
         echo -n "Last Test Age ("$HDD_Last_Test_Age") "
         read -n 1 Keyboard_yn
         if [[ ! $Keyboard_yn == "" ]]; then
            if [[ $Keyboard_yn == "t" ]]; then HDD_Last_Test_Age="true"; else HDD_Last_Test_Age="false"; fi
         fi
         echo "Set Value: ("$HDD_Last_Test_Age")"
         echo " "
         echo -n "Last Test Type ("$HDD_Last_Test_Type") "
         read -n 1 Keyboard_yn
         if [[ ! $Keyboard_yn == "" ]]; then
            if [[ $Keyboard_yn == "t" ]]; then HDD_Last_Test_Type="true"; else HDD_Last_Test_Type="false"; fi
         fi
         echo "Set Value: ("$HDD_Last_Test_Type")"
         echo " "
         echo " "
         echo "returning..."
         sleep 2
         ;;


         E)
         clear
         echo "SSD Column Selection"
         echo " "
         echo -n "Device ID ("$SSD_Device_ID") "
         read -n 1 Keyboard_yn
         if [[ ! $Keyboard_yn == "" ]]; then
            if [[ $Keyboard_yn == "t" ]]; then SSD_Device_ID="true"; else SSD_Device_ID="false"; fi
         fi
         echo "Set Value: ("$SSD_Device_ID")"
         echo " "
         echo -n "Serial Number ("$SSD_Serial_Number") "
         read -n 1 Keyboard_yn
         if [[ ! $Keyboard_yn == "" ]]; then
            if [[ $Keyboard_yn == "t" ]]; then SSD_Serial_Number="true"; else SSD_Serial_Number="false"; fi
         fi
         echo "Set Value: ("$SSD_Serial_Number")"
         echo " "
         echo -n "Model Number ("$SSD_Model_Number") "
         read -n 1 Keyboard_yn
         if [[ ! $Keyboard_yn == "" ]]; then
            if [[ $Keyboard_yn == "t" ]]; then SSD_Model_Number="true"; else SSD_Model_Number="false"; fi
         fi
         echo "Set Value: ("$SSD_Model_Number")"
         echo " "
         echo -n "Capacity ("$SSD_Capacity") "
         read -n 1 Keyboard_yn
         if [[ ! $Keyboard_yn == "" ]]; then
            if [[ $Keyboard_yn == "t" ]]; then SSD_Capacity="true"; else SSD_Capacity="false"; fi
         fi
         echo "Set Value: ("$SSD_Capacity")"
         echo " "
         echo -n "SMART Status ("$SSD_SMART_Status") "
         read -n 1 Keyboard_yn
         if [[ ! $Keyboard_yn == "" ]]; then
            if [[ $Keyboard_yn == "t" ]]; then SSD_SMART_Status="true"; else SSD_SMART_Status="false"; fi
         fi
         echo "Set Value: ("$SSD_SMART_Status")"
         echo " " 
         echo -n "Drive Temp ("$SSD_Drive_Temp") "
         read -n 1 Keyboard_yn
         if [[ ! $Keyboard_yn == "" ]]; then
            if [[ $Keyboard_yn == "t" ]]; then SSD_Drive_Temp="true"; else SSD_Drive_Temp="false"; fi
         fi
         echo "Set Value: ("$SSD_Drive_Temp")"
         echo " "
         echo -n "Warranty ("$SSD_Warranty") "
         read -n 1 Keyboard_yn
         if [[ ! $Keyboard_yn == "" ]]; then
            if [[ $Keyboard_yn == "t" ]]; then SSD_Warranty="true"; else SSD_Warranty="false"; fi
         fi
         echo "Set Value: ("$SSD_Warranty")"
         echo " "
         echo -n "Drive Temp Minimum for power cycle ("$SSD_Drive_Temp_Min") "
         read -n 1 Keyboard_yn
         if [[ ! $Keyboard_yn == "" ]]; then
            if [[ $Keyboard_yn == "t" ]]; then SSD_Drive_Temp_Min="true"; else SSD_Drive_Temp_Min="false"; fi
         fi
         echo "Set Value: ("$SSD_Drive_Temp_Min")"
         echo " "
         echo -n "Drive Temp Maximum for power cycle ("$SSD_Drive_Temp_Max") "
         read -n 1 Keyboard_yn
         if [[ ! $Keyboard_yn == "" ]]; then
            if [[ $Keyboard_yn == "t" ]]; then SSD_Drive_Temp_Max="true"; else SSD_Drive_Temp_Max="false"; fi
         fi
         echo "Set Value: ("$SSD_Drive_Temp_Max")"
         echo " "
         echo -n "Power On Hours ("$SSD_Power_On_Hours") "
         read -n 1 Keyboard_yn
         if [[ ! $Keyboard_yn == "" ]]; then
            if [[ $Keyboard_yn == "t" ]]; then SSD_Power_On_Hours="true"; else SSD_Power_On_Hours="false"; fi
         fi
         echo "Set Value: ("$SSD_Power_On_Hours")"
         echo " "
         echo -n "Wear Level ("$SSD_Wear_Level") "
        read -n 1 Keyboard_yn
        if [[ ! $Keyboard_yn == "" ]]; then
           if [[ $Keyboard_yn == "t" ]]; then SSD_Wear_Level="true"; else SSD_Wear_Level="false"; fi
        fi
        echo "Set Value: ("$SSD_Wear_Level")"
        echo " "
        echo -n "Reallocated Sectors ("$SSD_Reallocated_Sectors") "
        read -n 1 Keyboard_yn
        if [[ ! $Keyboard_yn == "" ]]; then
           if [[ $Keyboard_yn == "t" ]]; then SSD_Reallocated_Sectors="true"; else SSD_Reallocated_Sectors="false"; fi
        fi
        echo "Set Value: ("$SSD_Reallocated_Sectors")"
        echo " "
        echo -n "Reallocated Events ("$SSD_Reallocated_Events") "
        read -n 1 Keyboard_yn
        if [[ ! $Keyboard_yn == "" ]]; then
           if [[ $Keyboard_yn == "t" ]]; then SSD_Reallocated_Events="true"; else SSD_Reallocated_Events="false"; fi
        fi
        echo "Set Value: ("$SSD_Reallocated_Events")"
        echo " "
        echo -n "Pending Sectors ("$SSD_Pending_Sectors") "
        read -n 1 Keyboard_yn
        if [[ ! $Keyboard_yn == "" ]]; then
           if [[ $Keyboard_yn == "t" ]]; then SSD_Pending_Sectors="true"; else SSD_Pending_Sectors="false"; fi
        fi
        echo "Set Value: ("$SSD_Pending_Sectors")"
        echo " "
        echo -n "Offline Uncorrectable Errors ("$SSD_Offline_Uncorrectable") "
        read -n 1 Keyboard_yn
        if [[ ! $Keyboard_yn == "" ]]; then
           if [[ $Keyboard_yn == "t" ]]; then SSD_Offline_Uncorrectable="true"; else SSD_Offline_Uncorrectable="false"; fi
        fi
        echo "Set Value: ("$SSD_Offline_Uncorrectable")"
        echo " "
        echo -n "UDMA CRC Errors ("$SSD_UDMA_CRC_Errors") "
        read -n 1 Keyboard_yn
        if [[ ! $Keyboard_yn == "" ]]; then
           if [[ $Keyboard_yn == "t" ]]; then SSD_UDMA_CRC_Errors="true"; else SSD_UDMA_CRC_Errors="false"; fi
        fi
        echo "Set Value: ("$SSD_UDMA_CRC_Errors")"
        echo " "
        echo -n "Last Test Age ("$SSD_Last_Test_Age") "
        read -n 1 Keyboard_yn
        if [[ ! $Keyboard_yn == "" ]]; then
           if [[ $Keyboard_yn == "t" ]]; then SSD_Last_Test_Age="true"; else SSD_Last_Test_Age="false"; fi
        fi
        echo "Set Value: ("$SSD_Last_Test_Age")"
        echo " "
        echo -n "Last Test Type ("$SSD_Last_Test_Type") "
        read -n 1 Keyboard_yn
        if [[ ! $Keyboard_yn == "" ]]; then
           if [[ $Keyboard_yn == "t" ]]; then SSD_Last_Test_Type="true"; else SSD_Last_Test_Type="false"; fi
        fi
        echo "Set Value: ("$SSD_Last_Test_Type")"
        echo " "
        echo "returning..."
        sleep 2
        ;;


        F)
        clear
        echo "NVMe Column Selection"
        echo " "
        echo -n "Device ID ("$NVM_Device_ID") "
        read -n 1 Keyboard_yn
        if [[ ! $Keyboard_yn == "" ]]; then
           if [[ $Keyboard_yn == "t" ]]; then NVM_Device_ID="true"; else NVM_Device_ID="false"; fi
        fi
        echo "Set Value: ("$NVM_Device_ID")"
        echo " "
        echo -n "Serial Number ("$NVM_Serial_Number") "
        read -n 1 Keyboard_yn
        if [[ ! $Keyboard_yn == "" ]]; then
           if [[ $Keyboard_yn == "t" ]]; then NVM_Serial_Number="true"; else NVM_Serial_Number="false"; fi
        fi
        echo "Set Value: ("$NVM_Serial_Number")"
        echo " "
        echo -n "Model Number ("$NVM_Model_Number") "
        read -n 1 Keyboard_yn
        if [[ ! $Keyboard_yn == "" ]]; then
           if [[ $Keyboard_yn == "t" ]]; then NVM_Model_Number="true"; else NVM_Model_Number="false"; fi
        fi
        echo "Set Value: ("$NVM_Model_Number")"
        echo " "
        echo -n "Capacity ("$NVM_Capacity") "
        read -n 1 Keyboard_yn
        if [[ ! $Keyboard_yn == "" ]]; then
           if [[ $Keyboard_yn == "t" ]]; then NVM_Capacity="true"; else NVM_Capacity="false"; fi
        fi
        echo "Set Value: ("$NVM_Capacity")"
        echo " "
        echo -n "SMART Status ("$NVM_SMART_Status") "
        read -n 1 Keyboard_yn
        if [[ ! $Keyboard_yn == "" ]]; then
           if [[ $Keyboard_yn == "t" ]]; then NVM_SMART_Status="true"; else NVM_SMART_Status="false"; fi
        fi
        echo "Set Value: ("$NVM_SMART_Status")"
        echo " "
        echo -n "Warranty ("$NVM_Warranty") "
        read -n 1 Keyboard_yn
        if [[ ! $Keyboard_yn == "" ]]; then
           if [[ $Keyboard_yn == "t" ]]; then NVM_Warranty="true"; else NVM_Warranty="false"; fi
        fi
        echo "Set Value: ("$NVM_Warranty")"
        echo " "
        echo -n "Critical Warning Status ("$NVM_Critical_Warning") "
        read -n 1 Keyboard_yn
        if [[ ! $Keyboard_yn == "" ]]; then
           if [[ $Keyboard_yn == "t" ]]; then NVM_Critical_Warning="true"; else NVM_Critical_Warning="false"; fi
        fi
        echo "Set Value: ("$NVM_Critical_Warning")"
        echo " "
        echo -n "Drive Temp ("$NVM_Drive_Temp") "
        read -n 1 Keyboard_yn
        if [[ ! $Keyboard_yn == "" ]]; then
           if [[ $Keyboard_yn == "t" ]]; then NVM_Drive_Temp="true"; else NVM_Drive_Temp="false"; fi
        fi
        echo "Set Value: ("$NVM_Drive_Temp")"
        echo " "
        echo -n "Drive Temp Minimum for power cycle ("$NVM_Drive_Temp_Min") "
        read -n 1 Keyboard_yn
        if [[ ! $Keyboard_yn == "" ]]; then
           if [[ $Keyboard_yn == "t" ]]; then NVM_Drive_Temp_Min="true"; else NVM_Drive_Temp_Min="false"; fi
        fi
        echo "Set Value: ("$NVM_Drive_Temp_Min")"
        echo " "
        echo -n "Drive Temp Maximum for power cycle ("$NVM_Drive_Temp_Max") "
        read -n 1 Keyboard_yn
        if [[ ! $Keyboard_yn == "" ]]; then
           if [[ $Keyboard_yn == "t" ]]; then NVM_Drive_Temp_Max="true"; else NVM_Drive_Temp_Max="false"; fi
        fi
        echo "Set Value: ("$NVM_Drive_Temp_Max")"
        echo " "
        echo -n "Power On Hours ("$NVM_Power_On_Hours") "
        read -n 1 Keyboard_yn
        if [[ ! $Keyboard_yn == "" ]]; then
           if [[ $Keyboard_yn == "t" ]]; then NVM_Power_On_Hours="true"; else NVM_Power_On_Hours="false"; fi
        fi
        echo "Set Value: ("$NVM_Power_On_Hours")"
        echo " "
        echo -n "Wear Level ("$NVM_Wear_Level") "
        read -n 1 Keyboard_yn
        if [[ ! $Keyboard_yn == "" ]]; then
           if [[ $Keyboard_yn == "t" ]]; then NVM_Wear_Level="true"; else NVM_Wear_Level="false"; fi
        fi
        echo "Set Value: ("$NVM_Wear_Level")"
        echo " "
        echo " "
        echo "returning..."
        sleep 2
        ;;


        G)
        clear
        echo "Output Formats"
        echo " "
        echo "Power On Hours Time Format ("$powerTimeFormat") "
        echo -n "valid options are "ymdh", "ymd", "ym", "y", or "h" (year month day hour): "
        read Keyboard_yn
        if [[ ! $Keyboard_yn == "" ]]; then powerTimeFormat=$Keyboard_yn; fi
        echo "Set Value: "$powerTimeFormat
        echo " "
        echo "Temperature Display ("$tempdisplay") "
        echo -n "you may use what you want, Common formats are: *C, ^C, or ^c: "
        read Keyboard_yn
        if [[ ! $Keyboard_yn == "" ]]; then tempdisplay=$Keyboard_yn; fi
        echo "Set Value: "$tempdisplay
        echo " "
        echo "Non-existent Value ("$non_exist_value") "
        echo -n "you may use what you want, Common formats are: ---, N/A, or a space character: "
        read Keyboard_yn
        if [[ ! $Keyboard_yn == "" ]]; then non_exist_value=$Keyboard_yn; fi
        echo "Set Value: "$non_exist_value
        echo " "
        echo "Pool Size and Free Space"
        echo "ZFS is the most accurate and conforms to the GUI values."
        echo "Current Value:  ("$pool_capacity") "
        echo -n "Enter 'zfs' or 'zpool' or Enter/Return for unchanged: "
        read Keyboard_yn
        if [[ ! $Keyboard_yn == "" ]]; then pool_capacity=$Keyboard_yn; fi
        echo "Set Value: "$pool_capacity
        echo " "
        echo "returning..."
        sleep 2
        ;;

        H)
        clear
        echo "Report Header Titles"
        echo " "
        echo 'Current HDD Report Header: "'$HDDreportTitle'" '
        echo -n 'Enter new value or Return to accept current value: '
        read Keyboard_yn
        if [[ ! $Keyboard_yn == "" ]]; then HDDreportTitle=$Keyboard_yn; fi
        echo 'Set Value: "'$HDDreportTitle'"'
        echo " "
        echo 'Current SSD Report Header: "'$SSDreportTitle'" '
        echo -n 'Enter new value or Return to accept current value: '
        read Keyboard_yn
        if [[ ! $Keyboard_yn == "" ]]; then SSDreportTitle=$Keyboard_yn; fi
        echo 'Set Value: "'$SSDreportTitle'"'
        echo " "
        echo 'Current NVM Report Header: "'$NVMreportTitle'" '
        echo -n 'Enter new value or Return to accept current value: '
        read Keyboard_yn
        if [[ ! $Keyboard_yn == "" ]]; then NVMreportTitle=$Keyboard_yn; fi
        echo 'Set Value: "'$NVMreportTitle'"'
        echo " "
        echo "Enable/Disable Text Section"
        echo "This will display (true) or remove (false) the Text Section of the email report."
        echo 'Current value: "'$enable_text'" '
        echo -n 'Enter new value or Return to accept current value: '
        read Keyboard_yn
        if [[ ! $Keyboard_yn == "" ]]; then enable_text=$Keyboard_yn; fi
        echo 'Set Value: "'$enable_text'"'
        echo " "
        echo "returning..."
        sleep 2
        ;;


        I)
        clear
        echo "Statistical Data Setup"
        echo " "
        echo "Statistical file location and name ("$statistical_data_file")"
        echo "Enter new location and file name or press Enter/Return to accecpt current value:"
        read Keyboard_yn
        if [[ ! $Keyboard_yn == "" ]]; then statistical_data_file=$Keyboard_yn; fi
        echo "Set Value: ("$statistical_data_file")"
        echo " "
        echo " "
        echo -n "Statistical Data Recording Enabled ("$expDataEnable") "
        read -n 1 Keyboard_yn
        if [[ ! $Keyboard_yn == "" ]]; then
           if [[ $Keyboard_yn == "t" ]]; then expDataEnable="true"; else expDataEnable="false"; fi
        fi
        echo "Set Value: ("$expDataEnable")"
        echo " "
        echo -n "Statistical Data Email Enabled ("$expDataEmail") "
        read -n 1 Keyboard_yn
        if [[ ! $Keyboard_yn == "" ]]; then
           if [[ $Keyboard_yn == "t" ]]; then expDataEmail="true"; else expDataEmail="false"; fi
        fi
        echo "Set Value: ("$expDataEmail")"
        echo " "
        echo -n "Statistical Data Purge Days ("$expDataPurge") "
        read Keyboard_HDD
        if [[ ! $Keyboard_HDD == "" ]]; then expDataPurge=$Keyboard_HDD; fi
        echo "Set Value: ("$expDataPurge")"
        echo " "
        echo "What day of the week would you like the file attached?"
        echo "Current Value: "$expDataEmailSend
        echo "(All, Mon, Tue, Wed, Thu, Fri, Sat, Sun, Month)"
        echo -n "Enter: "
        read Keyboard_expDataEmailSend
        if [[ ! $Keyboard_expDataEmailSend == "" ]]; then expDataEmailSend=$Keyboard_expDataEmailSend; fi
        echo "Set Value: ("$expDataEmailSend")"
        echo " "
        echo "returning..."
        sleep 2
        ;;


        J)
        clear
        echo "Activate TLER"
        echo " "
        echo " "
        echo "Activate TLER ("$SCT_Drive_Enable") "
        echo "true = This will attempt to turn on TLER if the drive is reporting it is off."
        read -n 1 Keyboard_yn
        if [[ ! $Keyboard_yn == "" ]]; then
           if [[ $Keyboard_yn == "t" ]]; then SCT_Drive_Enable="true"; else SCT_Drive_Enable="false"; fi
        fi
        echo "Set Value: ("$SCT_Drive_Enable")"
        echo " "
        echo "TLER Warning Level: ("$SCT_Warning") "
        echo " 1) TLER_No_Msg = Only generate an error message if TLER cannot be turned on for"
        echo "    a supported drive."
        echo " 2) TLER = Report error messages in WARNING Section and email header."
        echo " 3) all = Report drive which also do not support TLER."
        echo -n "Enter: "
        read Keyboard_SCT_Warning
        if [[ $Keyboard_SCT_Warning == "1" ]]; then SCT_Warning="TLER_No_Msg"; fi
        if [[ $Keyboard_SCT_Warning == "2" ]]; then SCT_Warning="TLER"; fi
        if [[ $Keyboard_SCT_Warning == "3" ]]; then SCT_Warning="all"; fi
        echo "Set Value: ("$SCT_Warning")"
        echo " "
        echo -n "SCT Read Timemout Setting ("$SCT_Read_Timeout") "
        read Keyboard_yn
        if [[ ! $Keyboard_yn == "" ]]; then SCT_Read_Timeout=$Keyboard_yn; fi
        echo "Set Value: ("$SCT_Read_Timeout")"
        echo " "
        echo -n "SCT Write Timemout Setting ("$SCT_Write_Timeout") "
        read Keyboard_yn
        if [[ ! $Keyboard_yn == "" ]]; then SCT_Write_Timeout=$Keyboard_yn; fi
        echo "Set Value: ("$SCT_Write_Timeout")"
        echo " "
        echo "returning..."
        sleep 2
        ;;

        K)
        clear
        echo "Drive Errors and Custom Builds"
        echo " "
        echo "Collecting data, Please wait..."
        # Lets go ahead and grab all the drive data we will need for the entire K section.
        get_smartHDD_listings
        get_smartSSD_listings
        get_smartNVM_listings
        smartdrivesall="$smartdrives $smartdrivesSSD $smartdrivesNVM"
        echo " "
        echo "NOTE: Enter a single letter 'd' will delete the data and move to the next section."
        echo " "
        echo "Ignore Drives - Enter drive serial numbers, multiple drives separated by a comma."
        echo "Current: "$Ignore_Drives
        echo " "
        echo "Enter/Return to accept the current value(s) or press 'e' to Edit"
        read Keyboard_yn
        if [[ ! $Keyboard_yn == "" ]]; then Ignore_Drives=$Keyboard_yn; fi
        if [[ $Keyboard_yn == "d" ]]; then Ignore_Drives="none"; fi
        if [[ $Keyboard_yn == "e" ]]; then
        # Let's list each drive and ask to keep or reject
           for drive in $smartdrivesall; do
              clear_variables
              get_drive_data
              echo " "
              echo "Do you want to ignore this drive (y/n): Drive ID: "$drive" Serial Number: "$serial
              read Keyboard_yn
              if [[ $Keyboard_yn == "y" ]]; then ignoredriveslist=$ignoredriveslist$serial","; fi
           done
           if [[ ! $ignoredriveslist == "" ]]; then Ignore_Drives="$(echo "$ignoredriveslist" | sed 's/.$//')"; else Ignore_Drives="none"; fi
        fi
        echo "Set Value: "$Ignore_Drives
        echo " "
        echo " "
        echo "AUTOMATIC DRIVE COMPENSATION - UDMA_CRC, MultiZone, and Reallocated Sectors"
        echo " "
        echo "You have the option to automatically setup offset values for UDMA_CRC,"
        echo "MultiZone, and Bad Sectors."
        echo "This will scan your drives and for any non-zero value the offset will"
        echo "automatically be added."
        echo " "
        echo "Enter 'y' for yes or 'n' for no to manually set the values, Return for no change."
        read Keyboard_yn

        if [[ $Keyboard_yn == "y" ]]; then
           autoselect=1
           echo "Automatic Configuration selected..."
           echo " "
           for drive in $smartdrivesall; do
              clear_variables
              get_drive_data
              if [[ ! $crcErrors == "0" ]] && [[ ! $crcErrors == "" ]]; then listofdrivescrc="$listofdrivescrc$serial":"$crcErrors,"; fi
              if [[ ! $multiZone == "0" ]] && [[ ! $multiZone == "" ]]; then listofdrivesmulti="$listofdrivesmulti$serial":"$multiZone,"; fi
              if [[ ! $reAlloc == "0" ]] && [[ ! $reAlloc == "" ]]; then listofdrivesbad="$listofdrivesbad$serial":"$reAlloc,"; fi
           done
           echo "Scanning Results:"
           if [[ ! $listofdrivescrc == "" ]]; then CRC_Errors="$(echo "$listofdrivescrc" | sed 's/.$//')"; echo "UDMA_CRC Errors detected"; else CRC_Errors=""; echo "No UDMA_CRC Errors"; fi
           if [[ ! $listofdrivesmulti == "" ]]; then Multi_Zone="$(echo "$listofdrivesmulti" | sed 's/.$//')"; echo "MultiZone Errors Detected"; else Multi_Zone=""; echo "No MultiZone Errors"; fi
           if [[ ! $listofdrivesbad == "" ]]; then Bad_Sectors="$(echo "$listofdrivesbad" | sed 's/.$//')"; echo "Bad Sectors Detected"; else Bad_Sectors=""; echo "No Reallocated Sectors"; fi
           echo " "
           echo "Values Set:"
           echo "CRC_Errors: "$CRC_Errors
           echo "Multi_Zone_Errors: "$Multi_Zone
           echo "Reallocated_Sectors: "$Bad_Sectors
           echo " "
        fi
        if [[ ! $autoselect == "1" ]] && [[ $Keyboard_yn == "n" ]]; then
           echo "Offset UDMA CRC Errors"
           echo "Press 'd' to delete, 'e' to edit, or Enter/Return to accept."
           echo "Current List: "$CRC_Errors
           read Keyboard_yn
           if [[ ! $Keyboard_yn == "" ]]; then CRC_Errors=$Keyboard_yn; fi
           if [[ $Keyboard_yn == "d" ]]; then CRC_Errors=""; Keyboard_yn=""; fi
           if [[ $Keyboard_yn == "e" ]]; then
           # Let's list each drive and ask to keep or reject
              drive_select=""
              for drive in $smartdrivesall; do
                 clear_variables
                 get_drive_data
                 echo " "
                 echo "Do you want to add this drive (y/n): Drive ID: "$drive" Serial Number: "$serial
                 read Keyboard_yn
                 if [[ $Keyboard_yn == "y" ]]; then drive_select=$drive_select$serial":"
                 echo "Enter the sector count offset you desire: "
                 read Keyboard_yn
                 drive_select=$drive_select$Keyboard_yn","
                 echo "drive_select="$drive_select
                 fi
              done
              if [[ ! $drive_select == "" ]]; then CRC_Errors="$(echo "$drive_select" | sed 's/.$//')"; else CRC_Errors="none"; fi
           fi
           echo "Set Value: "$CRC_Errors
           echo " "
           echo "Offset MultiZone Errors"
           echo "Press 'd' to delete, 'e' to edit, or Enter/Return to accept."
           echo "Current: "$Multi_Zone
           read Keyboard_yn
           if [[ ! $Keyboard_yn == "" ]]; then Multi_Zone=$Keyboard_yn; fi
           if [[ $Keyboard_yn == "d" ]]; then Multi_Zone=""; fi
           if [[ $Keyboard_yn == "e" ]]; then
           # Let's list each drive and ask to keep or reject
              drive_select=""
              for drive in $smartdrivesall; do
                 clear_variables
                 get_drive_data
                 echo " "
                 echo "Do you want to add this drive (y/n): Drive ID: "$drive" Serial Number: "$serial
                 read Keyboard_yn
                 if [[ $Keyboard_yn == "y" ]]; then drive_select=$drive_select$serial":"
                 echo "Enter the Multi_Zone count offset you desire: "
                 read Keyboard_yn
                 drive_select=$drive_select$Keyboard_yn","
                 echo "drive_select="$drive_select
                 fi
              done
              if [[ ! $drive_select == "" ]]; then Multi_Zone="$(echo "$drive_select" | sed 's/.$//')"; else Multi_Zone="none"; fi
           fi
           echo "Set Value: "$Multi_Zone
           echo " "
           echo "Offset Bad Sector Errors"
           echo "Press 'd' to delete, 'e' to edit, or Enter/Return to accept."
           echo "Current: "$Bad_Sectors
           read Keyboard_yn
           if [[ ! $Keyboard_yn == "" ]]; then Bad_Sectors=$Keyboard_yn; fi
           if [[ $Keyboard_yn == "d" ]]; then Bad_Sectors=""; fi
           if [[ $Keyboard_yn == "e" ]]; then
           # Let's list each drive and ask to keep or reject
              drive_select=""
              for drive in $smartdrivesall; do
                 clear_variables
                 get_drive_data
                 echo " "
                 echo "Do you want to add this drive (y/n): Drive ID: "$drive" Serial Number: "$serial
                 read Keyboard_yn
                 if [[ $Keyboard_yn == "y" ]]; then drive_select=$drive_select$serial":"
                 echo "Enter the Bad Sector count offset you desire: "
                 read Keyboard_yn
                 drive_select=$drive_select$Keyboard_yn","
                 echo "drive_select="$drive_select
                 fi
              done
              if [[ ! $drive_select == "" ]]; then Bad_Sectors="$(echo "$drive_select" | sed 's/.$//')"; else Bad_Sectors="none"; fi
           fi
           echo "Set Value: "$Bad_Sectors
        fi
        echo " "
        echo "Automatic ATA Error Count Updates - This will automatically have the script"
        echo "update the multi_report_config.txt file with the current Error Log count."
        echo "This migth be desirable if you have a drive that keeps throwing minor errors."
        echo "Enter/Return to keep current value, 't' (enable), or 'f' (disable) this feature." 
        echo "Current: "$ata_auto_enable
        read Keyboard_yn
        if [[ ! $Keyboard_yn == "" ]]; then if [[ $Keyboard_yn == "t" ]]; then ata_auto_enable="true"; else ata_auto_enable="false"; fi; fi
        echo "Set Value: "$ata_auto_enable
        echo " "
        echo "ATA Error Count - This will ignore any drive with an error count less than"
        echo "the number provided.  When the drive errors exceed this value then the"
        echo "Error Log will be present again."
        echo "Enter 'd' to delete, 'e' to edit, or Enter/Return for no change."
        echo "Current: "$ata_errors
        read Keyboard_yn
        if [[ ! $Keyboard_yn == "" ]]; then ata_errors=$Keyboard_yn; fi
        if [[ $Keyboard_yn == "d" ]]; then ata_errors=""; fi
        if [[ $Keyboard_yn == "e" ]]; then
           ata_errors=""
           for drive in $smartdrivesall; do
              clear_variables
              get_drive_data
              echo " "
              echo "Do you want to add this drive (y/n): Drive ID: "$drive" Serial Number: "$serial
              read Keyboard_yn
              if [[ $Keyboard_yn == "y" ]]; then
                 echo "Enter the Error Log threshold: "
                 read Keyboard_yn
                 ata_errors=$ata_errors$serial":"$Keyboard_yn","
              fi
              echo "ata_errors="$ata_errors
              done
              if [[ ! $ata_errors == "" ]]; then ata_errors="$(echo "$ata_errors" | sed 's/.$//')"; else ata_errors="none"; fi
         fi
        echo "Set Value: "$ata_errors
        echo " "
        echo "Drive Warranty Expiration Date Warning - This will provide a yellow background"
        echo "and a text message when the warranty date occurs."
        echo "The format is: drive_serial_number:yyyy-mm-dd and separated by a comma for"
        echo "multiple drives. Enter 'd' to delete, 'e' to edit, or Enter/Return for no change."
        echo "Current: "$Drive_Warranty
        read Keyboard_yn
        if [[ ! $Keyboard_yn == "" ]]; then Drive_Warranty=$Keyboard_yn; fi
        if [[ $Keyboard_yn == "j" ]]; then Drive_Warranty="K1JUMLBD:2020-09-30,K1JRSWLD:2020-09-30,K1JUMW4D:2020-09-30,K1GVD84B:2020-10-12"; fi
        if [[ $Keyboard_yn == "d" ]]; then Drive_Warranty=""; fi
        if [[ $Keyboard_yn == "e" ]]; then
           for drive in $smartdrivesall; do
              clear_variables
              get_drive_data
              echo " "
              echo "Do you want to add this drive (y/n): Drive ID: "$drive" Serial Number: "$serial
              read -s -n 1 Keyboard_yn
              if [[ $Keyboard_yn == "y" ]]; then
                 echo "Enter the date the drive expires in the following format: yyyy-mm-dd"
                 read Keyboard_yn
                 warrantydrivelist=$warrantydrivelist$serial":"$Keyboard_yn","
              fi
              echo "warrantydrivelist= "$warrantydrivelist
              done
              if [[ ! $warrantydrivelist == "" ]]; then Drive_Warranty="$(echo "$warrantydrivelist" | sed 's/.$//')"; else Drive_Warranty=""; fi
         fi
        echo "Set Value: "$Drive_Warranty
        echo " "
        echo "Drive Warranty Expiration Chart Box Pixel Thickness"
        echo "Enter/Return = no change, or enter 1, 2, or 3"
        echo "Current: "$WarrantyBoxPixels
        read -s -n 1 Keyboard_yn
        if [[ ! $Keyboard_yn == "" ]]; then WarrantyBoxPixels=$Keyboard_yn; fi
        echo "Set Value: "$WarrantyBoxPixels
        echo " "
        echo "Drive Warranty Expiration Chart Box Pixel Color"
        echo "Enter/Return = no change, or enter Hex Color Code (Google it)"
        echo "Examples: black=#000000, red=#FF0000, lightblue=#add8e6"
        echo "Current: "$expiredWarrantyBoxColor
        read Keyboard_yn
        if [[ ! $Keyboard_yn == "" ]]; then expiredWarrantyBoxColor=$Keyboard_yn; fi
        echo "Set Value: "$expiredWarrantyBoxColor
        echo " "
        echo "Drive Warranty Expiration Chart Box Background Color"
        echo "Enter/Return = no change, or enter Hex Color Code (Google it)"
        echo "Examples: black=#000000, red=#FF0000, lightblue=#add8e6"
        echo 'You may also enter "none" to use the default background.'
        echo "Current: "$WarrantyBackgndColor
        read Keyboard_yn
        if [[ ! $Keyboard_yn == "" ]]; then WarrantyBackgndColor=$Keyboard_yn; fi
        echo "Set Value: "$WarrantyBackgndColor
        echo " "
        echo " "
        echo "Custom Hacks ("$custom_hack") "
        echo "Available: mistermanko, snowlucas2022, diedrichg, or none."
        echo 'Enter "d" to delete or enter "none"' 
        read Keyboard_yn
        if [[ ! $Keyboard_yn == "" ]]; then custom_hack=$Keyboard_yn; fi
        if [[ $Keyboard_yn == "d" ]]; then custom_hack="none"; fi
        echo "Set Value: "$custom_hack
        echo " "
        echo "returning..."
        sleep 2
        ;; 

        S)
        clear
        echo "Custom Drive Configuration Mode (Experimental)"
        echo " "
        echo "This series of questions will allow you to cutomize"
        echo "each alarm setting for each individual drive on your system."
        echo " "
        echo "In the following screens we will step through each drive"
        echo "and ask if you want to customize the values for the drive."
        echo " "
        echo "It is recommended that this be used only for drives which"
        echo "have specific alarm thresholds where the normal thresholds"
        echo "would be highly undesirable."
        echo " "
        echo "If you choose to customize a drive you will be presented with"
        echo "the Drive ID, Drive Serial Number, and the default alarm setting"
        echo "to which you will be able to change as desired."
        echo " "
        echo 'One additional setpoint is to disable "Last Test Age" which is the'
        echo "only reason I have custom builds, this should eliminate that."
        echo " "
        echo "Up to 24 drives worth of custom alarm data can be stored."
        echo "The intent is not to customize each drive, just the ones"
        echo "that need it, but you could do every drive if you really"
        echo "wanted to."
        echo " "
        echo "Follow the prompts."
        echo " "
        echo " "
        echo "Press any key to continue"
        read -s -n 1 key
        clear
# Now lets list each drive, one by one and make some changes.
        echo "Collecting data, Please wait..."
        # Lets go ahead and grab all the drive data we will need for the entire section.
        get_smartHDD_listings
        get_smartSSD_listings
        get_smartNVM_listings
        smartdrivesall="$smartdrives $smartdrivesSSD $smartdrivesNVM"
# So we have all the drives listed now.
# We will step through each drive and then compare the S/N's to Custom_Drives, if there
# is a match then we display the values.  If no match then display default values.
        if [[ $Custom_Drives != "" ]]; then
           echo "Would you like to delete all Custom Configuration Data (y/n)?"
           read -s -n 1 Keyboard_yn
           if [[ $Keyboard_yn == "y" ]]; then
              echo " "
              Custom_Drives=""
              echo "Data Deleted"
              echo " "
           fi
        fi
           echo "Would you like to exit (y/n)?"
           read -s -n 1 Keyboard_exit
           echo " "
           if [[ $Keyboard_exit == "y" ]]; then
              continue
           fi
           sleep .5
           clear
           echo "Collecting Data..."
           echo " "
           for drive in $smartdrivesall; do
              clear_variables
              get_drive_data
              echo "Drive ID: "$drive
              echo "Drive Serial Number: "$serial
              echo " "

# Check to see if the drive is listed in the Custom_Drives file, if yes then list the alarm setpoints.
# If the drive is not listed then ask to add it tot he list.  Next list the set/default setpoint values.
              if [[ "$(echo $Custom_Drives | grep $serial)" ]]; then
                 echo "The drive serial number "$serial" is already listed."
                 echo " "
                 echo "Options are: Delete the entry for this drive, then you may"
                 echo "re-add and edit it immediately."
                 echo " "
                 echo "Do you want to delete this drive from the custom configuration (y/n)?"
                 read -s -n 1 Keyboard_yn
                 if [[ $Keyboard_yn == "y" ]]; then
                    echo "Custom Drive Configuration for "$serial" Deleted"
                    echo " "
                    
### Roll through the Custom_Drives data until a match for $serial occurs, then copy all but that data back.
                    tempstring=""
                    for (( i=1; i<=24; i++ )); do
                       tempvar="$(echo $Custom_Drives | cut -d',' -f $i)"
                       if [[ ! $tempvar == "" ]]; then
                          tempsn="$(echo $tempvar | cut -d":" -f 1)"
                          if [[ ! $tempsn == $serial ]]; then
                             if [[ ! $tempstring == "" ]]; then
                                tempstring=$tempstring","$tempvar
                             else
                                tempstring=$tempvar
                             fi
                          fi
                       fi
                    done
                    if [[ ! $tempstring == "" ]]; then
                       Custom_Drives=$tempstring
                     #  echo "New Custom_Drives="$Custom_Drives
                     #  echo " "
                    fi
                 fi

              fi

# Lets assign the local variables with the default values.  They will be change
# later if the drive is in the Custom_Drives variable.

              sectorswarn=$sectorsWarn
              sectorscrit=$sectorsCrit
              reallocwarn=$reAllocWarn
              multizonewarn=$multiZoneWarn
              multizonecrit=$multiZoneCrit
              rawreadwarn=$rawReadWarn
              rawreadcrit=$rawReadCrit
              seekerrorswarn=$seekErrorsWarn
              seekerrorscrit=$seekErrorsCrit
              testage=$testAgeWarn
              testAgeOvrd="0"
              heliummin=$heliumMin

              if [[ ! "$(echo $Custom_Drives | grep $serial)" ]]; then
                 echo "The drive is not in the Custom Drive Config database."
                 echo " "
                 echo "Displaying Default Values"

                 if [[ $Custom_DrivesDrive == "HDD" ]]; then
                    tempwarn=$HDDtempWarn; tempcrit=$HDDtempCrit
                 fi
                 if [[ $Custom_DrivesDrive == "SSD" ]]; then
                    tempwarn=$SSDtempWarn; tempcrit=$SSDtempCrit
                 fi
                 if [[ $Custom_DrivesDrive == "NVM" ]]; then
                    tempwarn=$NVMtempWarn; tempcrit=$NVMtempCrit
                 fi
 
                 echo " "
                 echo "The current alarm setpoints are:"
                 echo "Temperature Warning=("$tempwarn")  Temperature Critical=("$tempcrit")"
                 echo "Sectors Warning=("$sectorswarn")  Sectors Critical=("$sectorscrit")  ReAllocated Sectors Warning=("$reallocwarn")"
                 echo "MultiZone Warning=("$multizonewarn")  MultiZone Critical=("$multizonecrit")"
                 echo "Raw Read Error Rate Warning=("$rawreadwarn")  Raw Read Error Rate Critical=("$rawreadcrit")"
                 echo "Seek Error Rate Warning=("$seekerrorswarn")  Seek Error Rate Critical=("$seekerrorscrit")"
                 echo "Test Age=("$testage")  Ignore Test Age=("$testAgeOvrd")"
                 echo "Helium Minimum Level=("$heliummin")"
                 echo " "

                 echo "Would you like to customize an Alarm Setpoint for this drive?"
                 echo "Return accepts current setting, 'y' to modify. "
                 read -s -n 1 Keyboard_yn

                 if [[ $Keyboard_yn == "y" ]]; then
                    echo " "
                    echo "Let's modify some values..."
                    echo "Return to accept current value or enter a new value."
                    echo " "
                    echo "Temperature Warning=("$tempwarn") "
                    read Keyboard_yn
                      if [[ $Keyboard_yn != $tempwarn && $Keyboard_yn != "" ]]; then
                         tempwarn=$Keyboard_yn
                      fi
                    echo "Temperature Critical=("$tempcrit") "
                    read Keyboard_yn
                      if [[ $Keyboard_yn != $tempcrit && $Keyboard_yn != "" ]]; then
                         tempcrit=$Keyboard_yn
                      fi

                    echo "Sectors Warning=("$sectorswarn") "
                    read Keyboard_yn
                      if [[ $Keyboard_yn != $sectorswarn && $Keyboard_yn != "" ]]; then
                         sectorswarn=$Keyboard_yn
                      fi
                    echo "Sectors Critical=("$sectorscrit") "
                    read Keyboard_yn
                      if [[ $Keyboard_yn != $sectorscrit && $Keyboard_yn != "" ]]; then
                         sectorscrit=$Keyboard_yn
                      fi

                    echo "Reallocated Sectors Warning=("$reallocwarn") "
                    read Keyboard_yn
                      if [[ $Keyboard_yn != $reallocwarn && $Keyboard_yn != "" ]]; then
                         reallocwarn=$Keyboard_yn
                      fi

                    echo "MultiZone Warning=("$multizonewarn") "
                    read Keyboard_yn
                      if [[ $Keyboard_yn != $mulitzonewarn && $Keyboard_yn != "" ]]; then
                         multizonewarn=$Keyboard_yn
                      fi

                    echo "MultiZone Critical=("$multizonecrit") "
                    read Keyboard_yn
                      if [[ $Keyboard_yn != $mulitzonecrit && $Keyboard_yn != "" ]]; then
                         multizonecrit=$Keyboard_yn
                      fi

                    echo "Raw Read Rate Warning=("$rawreadwarn") "
                    read Keyboard_yn
                      if [[ $Keyboard_yn != $rawreadwarn && $Keyboard_yn != "" ]]; then
                         rawreadwarn=$Keyboard_yn
                      fi
                    echo "Raw Read Rate Critical=("$rawreadcrit") "
                    read Keyboard_yn
                      if [[ $Keyboard_yn != $rawreadcrit && $Keyboard_yn != "" ]]; then
                         rawreadcrit=$Keyboard_yn
                      fi

                    echo "Seek Errors Warning=("$seekerrorswarn") "
                    read Keyboard_yn
                      if [[ $Keyboard_yn != $seekerrorswarn && $Keyboard_yn != "" ]]; then
                         seekerrorswarn=$Keyboard_yn
                      fi

                    echo "Seek Errors Critical=("$seekerrorscrit") "
                    read Keyboard_yn
                      if [[ $Keyboard_yn != $seekerrorscrit && $Keyboard_yn != "" ]]; then
                         seekerrorscrit=$Keyboard_yn
                      fi

                    echo "Test Age=("$testage") "
                    read Keyboard_yn
                      if [[ $Keyboard_yn != $testage && $Keyboard_yn != "" ]]; then
                         testage=$Keyboard_yn
                      fi

                    echo "Ignore Test Age=("$testAgeOvrd") (0=No, 1=Yes)"
                    read Keyboard_yn
                    if [[ $Keyboard_yn != $testAgeOvrd && $Keyboard_yn != "" ]]; then
                         testAgeOvrd=$Keyboard_yn
                      fi

                   echo "Helium Warning Level=("$heliummin") "
                    read Keyboard_yn
                      if [[ $Keyboard_yn != $heliummin && $Keyboard_yn != "" ]]; then
                         heliummin=$Keyboard_yn
                      fi

                 echo " "
                 echo "The current alarm setpoints are:"
                 echo "Temperature Warning=("$tempwarn")  Temperature Critical=("$tempcrit")"
                 echo "Sectors Warning=("$sectorswarn")  Sectors Critical=("$sectorscrit")  ReAllocated Sectors Warning=("$reallocwarn")"
                 echo "MultiZone Warning=("$multizonewarn")  MultiZone Critical=("$multizonecrit")"
                 echo "Raw Read Error Rate Warning=("$rawreadwarn")  Raw Read Error Rate Critical=("$rawreadcrit")"
                 echo "Seek Error Rate Warning=("$seekerrorswarn")  Seek Error Rate Critical=("$seekerrorscrit")"
                 echo "Test Age=("$testage")  Ignore Test Age=("$testAgeOvrd")"
                 echo "Helium Minimum Level=("$heliummin")"
                 echo " "

                    echo "Adding "$drive" Serial Number: "$serial" to the custom configuration"
                    echo "variable."
                    echo " "
         # Add all the current values for this $serial to the Custom_Drives variable.
         
                    if [[ $Custom_Drives == "" ]]; then
                       Custom_Drives=$serial":"$tempwarn":"$tempcrit":"$sectorswarn":"$sectorscrit":"$reallocwarn":"$multizonewarn":"$multizonecrit":"$rawreadwarn":"$rawreadcrit":"$seekerrorswarn":"$seekerrorscrit":"$testage":"$testAgeOvrd":"$heliummin
                    else
                       Custom_Drives=$Custom_Drives","$serial":"$tempwarn":"$tempcrit":"$sectorswarn":"$sectorscrit":"$reallocwarn":"$multizonewarn":"$multizonecrit":"$rawreadwarn":"$rawreadcrit":"$seekerrorswarn":"$seekerrorscrit":"$testage":"$testAgeOvrd":"$heliummin
                    fi
            echo " "
            else
               echo "Drive skipped."
            fi
         fi
            echo " "
            echo "Press any key to continue"
            read -s -n 1 key
            clear
           done
        echo "Make sure you write your changes."
        echo "Press any key to continue"
        read -s -n 1 key       
        sleep .5
        ;;

        W)
        echo " "
        echo "Writing Configuration File"
        echo " "
        echo " "
        sleep 1
        update_config_file
        echo "File updated."
        echo " "
        x=100
        sleep 1
        ;;


        X)
        echo "Exiting, Not Saving"
        sleep 1
        x=100
        ;;


        *)
        echo "Invalid Option"
        sleep 2
        ;;
# End Second Level
    esac
    done
    ;;


    H)
    clear
    echo "How to use this configuration tool"
    echo " "
    echo "This tool has many options and you should be able to perform a complete"
    echo "configuration using this tool."
    echo " "
    echo "In order to use the advanced options you will need to have created an external"
    echo "configuration file then the tool will be able to read and write to this file."
    echo " "
    echo "Throughout this process you will be asked questions that require three different"
    echo "responses:"
    echo " "
    echo "  1) String content: Where you will either enter a new string followed by the"
    echo "     Enter/Return key, or just press Enter/Return to accept the current value."
    echo " "
    echo "  2) Number content: Where you will either enter a new number followed by the"
    echo "     Enter/Return key, or just press Enter/Return to accept the current value."
    echo " "
    echo "  3) True/False content: Where you will either enter 't' or 'f' followed by the"
    echo "     Enter/Return key, or just press Enter/Return to accept the current value."
    echo " "
    echo "  4) Some options will give you a choice of 'd' to delete the value and"
    echo "     continue, or 'e' to Edit."
    echo " "
    echo "Just to re-iterate: Press the Enter/Return key to accept the current value."
    echo "Press 't' or 'f' to change to 'true' or 'false'.  Enter a number or string"
    echo "followed by the Enter/Return key to change a value."
    echo " "
    echo "For more detailed Help information, run the program with the '-h' parameter."
    echo " "
    echo "Lastly this configuration process will not, I repeat, will not alter the script"
    echo "file.  It will only alter the configuration file which by default will be"
    echo "located in the same directory as the script is located."
    echo " "
    echo -n "Press any key to continue"
    read -n 1 key
    echo " "
    sleep 1
    ;;


    N)
    clear
    echo "Creating a new configuration file.  This will overwrite an existing file (blank to abort)."
    echo " "
    echo -n "Enter your email address to send the report to: "    
    read Keyboard_email
    if [[ $Keyboard_email == "" ]]; then
       echo "Aborting"
       sleep 2
       continue
    fi
    if [[ ! $Keyboard_email == "" ]]; then email=$Keyboard_email; fi
    echo "Set Value: "$email
    echo " "
    echo "Current from address: "$from" "
    echo 'While most people are able to use the default "from" address,'
    echo 'Some email servers will not work unless you use the email address'
    echo 'the email address the server is assocciated with.'
    echo -n "Enter your from email address: "    
    read Keyboard_email
    if [[ ! $Keyboard_email == "" ]]; then from=$Keyboard_email; fi
    echo "Set Value: "$from
    echo " "
    echo "Enter path and name of statistics file or just hit Enter to use default (recommended): "
    echo 'Default is '$SCRIPT_DIR'/statistical_data_file.csv'
    read Keyboard_statistics
    if [[ $Keyboard_statistics == "" ]]; then echo "Default Selected"; Keyboard_statistics="$SCRIPT_DIR/statisticalsmartdata.csv"; fi
    echo "Set Value: "$Keyboard_statistics
    echo " "
    echo "Would you like to automatically setup for some basic drive offsets (y/n): "
    read -s -n 1 Keyboard_yn
    if [[ $Keyboard_yn == "y" ]]; then
    echo " "
    echo "Collecting data, Please wait..."
    get_smartHDD_listings
    get_smartSSD_listings
    get_smartNVM_listings
    smartdrivesall="$smartdrives $smartdrivesSSD $smartdrivesNVM"
    echo " "
    echo "AUTOMATIC DRIVE COMPENSATION - UDMA_CRC, MultiZone, and Reallocated Sectors"
    echo " "
    for drive in $smartdrivesall; do
       clear_variables
       get_drive_data
              if [[ ! $crcErrors == "0" ]] && [[ ! $crcErrors == "" ]]; then listofdrivescrc="$listofdrivescrc$serial":"$crcErrors,"; fi
              if [[ ! $multiZone == "0" ]] && [[ ! $multiZone == "" ]]; then listofdrivesmulti="$listofdrivesmulti$serial":"$multiZone,"; fi
              if [[ ! $reAlloc == "0" ]] && [[ ! $reAlloc == "" ]]; then listofdrivesbad="$listofdrivesbad$serial":"$reAlloc,"; fi
    done
    echo "Scanning Results:"
    if [[ ! $listofdrivescrc == "" ]]; then CRC_Errors="$(echo "$listofdrivescrc" | sed 's/.$//')"; echo "UDMA_CRC Errors detected"; else CRC_Errors=""; echo "No UDMA_CRC Errors"; fi
    if [[ ! $listofdrivesmulti == "" ]]; then Multi_Zone="$(echo "$listofdrivesmulti" | sed 's/.$//')"; echo "MultiZone Errors Detected"; else Multi_Zone=""; echo "No MultiZone Errors"; fi
    if [[ ! $listofdrivesbad == "" ]]; then Bad_Sectors="$(echo "$listofdrivesbad" | sed 's/.$//')"; echo "Bad Sectors Detected"; else Bad_Sectors=""; echo "No Reallocated Sectors"; fi
    echo " "
    echo "Values Set:"
    echo "CRC_Errors: "$CRC_Errors
    echo "Multi_Zone_Errors: "$Multi_Zone
    echo "Reallocated_Sectors: "$Bad_Sectors
    echo " "
    fi
    echo "Creating the new file..."
### This sets the default values up for the external config file.
(
echo "#" $programver
echo "#"
echo "# This file is used exclusively to configure the multi_report version 1.6c or later."
echo "#"
echo "# The configuration file will be created in the same directory as the script."
echo "#"
echo "# The configuration file will override the default values coded into the script."
echo " "
echo "###### Email Address ######"
echo "# Enter your email address to send the report to.  The from address does not need to be changed unless you experience"
echo "# an error sending the email.  Some email servers only use the email address associated with the email server."
echo " "
echo 'email="'$email'"'
echo 'from="'$from'"'
echo " "
echo "###### Custom Hack ######"
echo "# Custom Hacks are for users with generally very unsupported drives and the data must be manually manipulated."
echo "# The goal is to not have any script customized so I will look for fixes where I can."
echo "#"
echo" # Please look at the new Experimental Custom Drive Settings under -config."
echo "#"
echo "# Allowable custom hacks are: mistermanko, snowlucas2022, diedrichg, or none."
echo 'custom_hack="none"'
echo " "
echo "###### Zpool Status Summary Table Settings"
echo " "
echo "usedWarn=80               # Pool used percentage for CRITICAL color to be used."
echo "scrubAgeWarn=37           # Maximum age (in days) of last pool scrub before CRITICAL color will be used (30 + 7 days for day of week). Default=37."
echo " "
echo "###### Temperature Settings"
echo "HDDtempWarn=45            # HDD Drive temp (in C) upper OK limit before a WARNING color/message will be used."
echo "HDDtempCrit=50            # HDD Drive temp (in C) upper OK limit before a CRITICAL color/message will be used."
echo 'HDDmaxovrd="true"         # HDD Max Drive Temp Override. This value when "true" will not alarm on any Current Power Cycle Max Temperature Limit.'
echo "SSDtempWarn=45            # SSD Drive temp (in C) upper OK limit before a WARNING color/message will be used."
echo "SSDtempCrit=50            # SSD Drive temp (in C) upper OK limit before a CRITICAL color/message will be used."
echo 'SSDmaxovrd="true"         # SSD Max Drive Temp Override. This value when "true" will not alarm on any Current Power Cycle Max Temperature Limit.'
echo "NVMtempWarn=50            # NVM Drive temp (in C) upper OK limit before a WARNING color/message will be used."
echo "NVMtempCrit=60            # NVM Drive temp (in C) upper OK limit before a CRITICAL color/message will be used."
echo 'NVMmaxovrd="true"         # NVM Max Drive Temp Override. This value when "true" will not alarm on any Current Power Cycle Max Temperature Limit.'
echo "                          # --- NOTE: NVMe drives currently do not report Min/Max temperatures so this is a future feature."
echo " "
echo "###### SSD/NVMe Specific Settings"
echo " "
echo "wearLevelCrit=9           # Wear Level Alarm Setpoint lower OK limit before a WARNING color/message, 9% is the default."
echo " "
echo "###### General Settings"
echo "# Output Formats"
echo 'powerTimeFormat="h"       # Format for power-on hours string, valid options are "ymdh", "ymd", "ym", "y", or "h" (year month day hour).'
echo 'tempdisplay="*C"          # The format you desire the temperature to be displayed in. Common formats are: "*C", "^C", or "^c". Choose your own.'
echo 'non_exist_value="---"     # How do you desire non-existent data to be displayed.  The Default is "---", popular options are "N/A" or " ".'
echo 'pool_capacity="zfs"       # Select "zfs" or "zpool" for Zpool Status Report - Pool Size and Free Space capacities. zfs is default.'
echo " "
echo "# Ignore or Activate Alarms"
echo 'ignoreUDMA="false"        # Set to "true" to ignore all UltraDMA CRC Errors for the summary alarm (Email Header) only, errors will appear in the graphical chart.'
echo 'ignoreSeekError="true"    # Set to "true" to ignore all Seek Error Rate/Health errors.  Default is true.'
echo 'ignoreReadError="true"    # Set to "true" to ignore all Raw Read Error Rate/Health errors.  Default is true.'
echo 'ignoreMultiZone="false"   # Set to "true" to ignore all MultiZone Errors. Default is false.'
echo 'disableWarranty="true"    # Set to "true to disable email Subject line alerts for any expired warranty alert. The email body will still report the alert.'
echo " "
echo "# Disable or Activate Input/Output File Settings"
echo 'includeSSD="true"         # Set to "true" will engage SSD Automatic Detection and Reporting, false = Disable SSD Automatic Detection and Reporting.'
echo 'includeNVM="true"         # Set to "true" will engage NVM Automatic Detection and Reporting, false = Disable NVM Automatic Detection and Reporting.'
echo 'reportnonSMART="true"     # Will force even non-SMART devices to be reported, "true" = normal operation to report non-SMART devices.'
echo 'disableRAWdata="false"    # Set to "true" to remove the 'smartctl -a' data and non-smart data appended to the normal report.  Default is false.'
echo 'ata_auto_enable="false"   # Set to "true" to automatically update Log Error count to only display a log error when a new one occurs.'
echo " "
echo "# Media Alarms"
echo "sectorsWarn=1             # Number of sectors per drive to allow with errors before WARNING color/message will be used, this value should be less than sectorsCrit."
echo "sectorsCrit=9             # Number of sectors per drive with errors before CRITICAL color/message will be used."
echo "reAllocWarn=0             # Number of Reallocated sector events allowed.  Over this amount is an alarm condition."
echo "multiZoneWarn=0           # Number of MultiZone Errors to allow before a Warning color/message will be used.  Default is 0."
echo "multiZoneCrit=5           # Number of MultiZone Errors to allow before a Warning color/message will be used.  Default is 5."
echo 'deviceRedFlag="true"      # Set to "true" to have the Device Column indicate RED for ANY alarm condition.  Default is true.'
echo 'heliumAlarm="true"        # Set to "true" to set for a critical alarm any He value below "heliumMin" value.  Default is true.'
echo 'heliumMin=100             # Set to 100 for a zero leak helium result.  An alert will occur below this value.'
echo "rawReadWarn=5             # Number of read errors to allow before WARNING color/message will be used, this value should be less than rawReadCrit."
echo "rawReadCrit=100           # Number of read errors to allow before CRITICAL color/message will be used."
echo "seekErrorsWarn=5          # Number of seek errors to allow before WARNING color/message will be used, this value should be less than seekErrorsCrit."
echo "seekErrorsCrit=100        # Number of seek errors to allow before CRITICAL color/message will be used."
echo " "
echo "# Time-Limited Error Recovery (TLER)"
echo 'SCT_Drive_Enable="false"  # Set to "true" to send a command to enable SCT on your drives for user defined timeout if the TLER state is Disabled.'
echo 'SCT_Warning="TLER_No_Msg" # Set to "all" will generate a Warning Message for all devices not reporting SCT enabled. "TLER" reports only drive which support TLER.'
echo '                          # "TLER_No_Msg" will only report for TLER drives and not report a Warning Message if the drive can set TLER on.'
echo "SCT_Read_Timeout=70       # Set to the read threshold. Default = 70 = 7.0 seconds."
echo "SCT_Write_Timeout=70      # Set to the write threshold. Default = 70 = 7.0 seconds."
echo " "
echo "# SMART Testing Alarm"
echo "testAgeWarn=2             # Maximum age (in days) of last SMART test before CRITICAL color/message will be used."
echo " "
echo "###### Statistical Data File"
echo 'statistical_data_file="'$Keyboard_statistics'"'
echo 'expDataEnable="true"      # Set to "true" will save all drive data into a CSV file defined by "statistical_data_file" below.'
echo 'expDataEmail="true"       # Set to "true" to have an attachment of the file emailed to you. Default is true.'
echo "expDataPurge=730          # Set to the number of day you wish to keep in the data.  Older data will be purged. Default is 730 days (2 years). 0=Disable."
echo 'expDataEmailSend="Mon"    # Set to the day of the week the statistical report is emailed.  (All, Mon, Tue, Wed, Thu, Fri, Sat, Sun, Month)'
echo " "
echo "###### FreeNAS config backup settings"
echo 'configBackup="true"      # Set to "true" to save config backup (which renders next two options operational); "false" to keep disable config backups.'
echo 'configSendDay="Mon"      # Set to the day of the week the config is emailed.  (All, Mon, Tue, Wed, Thu, Fri, Sat, Sun, Month)'
echo 'saveBackup="false"       # Set to "false" to delete FreeNAS config backup after mail is sent; "true" to keep it in dir below.'
echo 'backupLocation="/tmp/"   # Directory in which to store the backup FreeNAS config files.'
echo " "
echo "###### Attach multi_report_config.txt to Email ######"
echo 'Config_Email_Enable="true"    # Set to "true" to enable periodic email (which renders next two options operational).'
echo 'Config_Changed_Email="true"   # If "true" it will attach the updated/changed file to the email.'
echo 'Config_Backup_Day="Mon"       # Set to the day of the week the multi_report_config.txt is emailed.  (All, Mon, Tue, Wed, Thu, Fri, Sat, Sun, Month, Never)'
echo " "
echo "########## REPORT CHART CONFIGURATION ##############"
echo " "
echo "###### REPORT HEADER TITLE ######"
echo 'HDDreportTitle="Spinning Rust Summary Report"     # This is the title of the HDD report, change as you desire.'
echo 'SSDreportTitle="SSD Summary Report"               # This is the title of the SSD report, change as you desire.'
echo 'NVMreportTitle="NVMe Summary Report"              # This is the title of the NVMe report, change as you desire.'
echo " "
echo "### CUSTOM REPORT CONFIGURATION ###"
echo "# By default most items are selected. Change the item to "false" to have it not displayed in the graph, "true" to have it displayed."
echo "# NOTE: Alarm setpoints are not affected by these settings, this is only what columns of data are to be displayed on the graph."
echo "# I would recommend that you remove columns of data that you don't really care about to make the graph less busy."
echo " "
echo "# For Zpool Status Summary"
echo 'Zpool_Pool_Name_Title="Pool Name"'
echo 'Zpool_Status_Title="Status"'
echo 'Zpool_Pool_Size_Title="Pool Size"'
echo 'Zpool_Free_Space_Title="Free Space"'
echo 'Zpool_Used_Space_Title="Used Space"'
echo 'Zfs_Pool_Size_Title="^Pool Size"'
echo 'Zfs_Free_Space_Title="^Free Space"'
echo 'Zfs_Used_Space_Title="^Used Space"'
echo 'Zpool_Read_Errors_Title="Read Errors"'
echo 'Zpool_Write_Errors_Title="Write Errors"'
echo 'Zpool_Checksum_Errors_Title="Cksum Errors"'
echo 'Zpool_Scrub_Repaired_Title="Scrub Repaired Bytes"'
echo 'Zpool_Scrub_Errors_Title="Scrub Errors"'
echo 'Zpool_Scrub_Age_Title="Last Scrub Age"'
echo 'Zpool_Scrub_Duration_Title="Last Scrub Duration"'
echo " "
echo "# For Hard Drive Section"
echo 'HDD_Device_ID="true"'
echo 'HDD_Device_ID_Title="Device ID"'
echo 'HDD_Serial_Number="true"'
echo 'HDD_Serial_Number_Title="Serial Number"'
echo 'HDD_Model_Number="true"'
echo 'HDD_Model_Number_Title="Model Number"'
echo 'HDD_Capacity="true"'
echo 'HDD_Capacity_Title="HDD Capacity"'
echo 'HDD_Rotational_Rate="true"'
echo 'HDD_Rotational_Rate_Title="RPM"'
echo 'HDD_SMART_Status="true"'
echo 'HDD_SMART_Status_Title="SMART Status"'
echo 'HDD_Warranty="true"'
echo 'HDD_Warranty_Title="Warr- anty"'
echo 'HDD_Raw_Read_Error_Rate="true"'
echo 'HDD_Raw_Read_Error_Rate_Title="Read Error Rate"'
echo 'HDD_Drive_Temp="true"'
echo 'HDD_Drive_Temp_Title="Curr Temp"'
echo 'HDD_Drive_Temp_Min="true"'
echo 'HDD_Drive_Temp_Min_Title="Temp Min"'
echo 'HDD_Drive_Temp_Max="true"'
echo 'HDD_Drive_Temp_Max_Title="Temp Max"'
echo 'HDD_Power_On_Hours="true"'
echo 'HDD_Power_On_Hours_Title="Power On Time"'
echo 'HDD_Start_Stop_Count="true"'
echo 'HDD_Start_Stop_Count_Title="Start Stop Count"'
echo 'HDD_Load_Cycle="true"'
echo 'HDD_Load_Cycle_Title="Load Cycle Count"'
echo 'HDD_Spin_Retry="true"'
echo 'HDD_Spin_Retry_Title="Spin Retry Count"'
echo 'HDD_Reallocated_Sectors="true"'
echo 'HDD_Reallocated_Sectors_Title="Re-alloc Sects"'
echo 'HDD_Reallocated_Events="true"'
echo 'HDD_Reallocated_Events_Title="Re-alloc Evnt"'
echo 'HDD_Pending_Sectors="true"'
echo 'HDD_Pending_Sectors_Title="Curr Pend Sects"'
echo 'HDD_Offline_Uncorrectable="true"'
echo 'HDD_Offline_Uncorrectable_Title="Offl Unc Sects"'
echo 'HDD_UDMA_CRC_Errors="true"'
echo 'HDD_UDMA_CRC_Errors_Title="UDMA CRC Error"'
echo 'HDD_Seek_Error_Rate="true"'
echo 'HDD_Seek_Error_Rate_Title="Seek Error Rate"'
echo 'HDD_MultiZone_Errors="true"'
echo 'HDD_MultiZone_Errors_Title="Multi Zone Error"'
echo 'HDD_Helium_Level="true"'
echo 'HDD_Helium_Level_Title="He Level"'
echo 'HDD_Last_Test_Age="true"'
echo 'HDD_Last_Test_Age_Title="Last Test Age"'
echo 'HDD_Last_Test_Type="true"'
echo 'HDD_Last_Test_Type_Title="Last Test Type"'
echo " "
echo "# For Solid State Drive Section"
echo 'SSD_Device_ID="true"'
echo 'SSD_Device_ID_Title="Device ID"'
echo 'SSD_Serial_Number="true"'
echo 'SSD_Serial_Number_Title="Serial Number"'
echo 'SSD_Model_Number="true"'
echo 'SSD_Model_Number_Title="Model Number"'
echo 'SSD_Capacity="true"'
echo 'SSD_Capacity_Title="HDD Capacity"'
echo 'SSD_SMART_Status="true"'
echo 'SSD_SMART_Status_Title="SMART Status"'
echo 'SSD_Warranty="true"'
echo 'SSD_Warranty_Title="Warr- anty"'
echo 'SSD_Drive_Temp="true"'
echo 'SSD_Drive_Temp_Title="Curr Temp"'
echo 'SSD_Drive_Temp_Min="true"'
echo 'SSD_Drive_Temp_Min_Title="Temp Min"'
echo 'SSD_Drive_Temp_Max="true"'
echo 'SSD_Drive_Temp_Max_Title="Temp Max"'
echo 'SSD_Power_On_Hours="true"'
echo 'SSD_Power_On_Hours_Title="Power On Time"'
echo 'SSD_Wear_Level="true"'
echo 'SSD_Wear_Level_Title="Wear Level"'
echo 'SSD_Reallocated_Sectors="true"'
echo 'SSD_Reallocated_Sectors_Title="Re-alloc Sects"'
echo 'SSD_Reallocated_Events="true"'
echo 'SSD_Reallocated_Events_Title="Re-alloc Evnt"'
echo 'SSD_Pending_Sectors="true"'
echo 'SSD_Pending_Sectors_Title="Curr Pend Sects"'
echo 'SSD_Offline_Uncorrectable="true"'
echo 'SSD_Offline_Uncorrectable_Title="Offl Unc Sects"'
echo 'SSD_UDMA_CRC_Errors="true"'
echo 'SSD_UDMA_CRC_Errors_Title="UDMA CRC Error"'
echo 'SSD_Last_Test_Age="true"'
echo 'SSD_Last_Test_Age_Title="Last Test Age"'
echo 'SSD_Last_Test_Type="true"'
echo 'SSD_Last_Test_Type_Title="Last Test Type"'
echo " "
echo "# For NVMe Drive Section"
echo 'NVM_Device_ID="true"'
echo 'NVM_Device_ID_Title="Device ID"'
echo 'NVM_Serial_Number="true"'
echo 'NVM_Serial_Number_Title="Serial Number"'
echo 'NVM_Model_Number="true"'
echo 'NVM_Model_Number_Title="Model Number"'
echo 'NVM_Capacity="true"'
echo 'NVM_Capacity_Title="HDD Capacity"'
echo 'NVM_SMART_Status="true"'
echo 'NVM_SMART_Status_Title="SMART Status"'
echo 'NVM_Warranty="true"'
echo 'NVM_Warranty_Title="Warr- anty"'
echo 'NVM_Critical_Warning="true"'
echo 'NVM_Critical_Warning_Title="Critical Warning"'
echo 'NVM_Drive_Temp="true"'
echo 'NVM_Drive_Temp_Title="Curr Temp"'
echo 'NVM_Drive_Temp_Min="false"               # I have not found this on an NVMe drive yet, so set to false'
echo 'NVM_Drive_Temp_Min_Title="Temp Min"'
echo 'NVM_Drive_Temp_Max="false"               # I have not found this on an NVMe drive yet, so set to false'
echo 'NVM_Drive_Temp_Max_Title="Temp Max"'
echo 'NVM_Power_On_Hours="true"'
echo 'NVM_Power_On_Hours_Title="Power On Time"'
echo 'NVM_Wear_Level="true"'
echo 'NVM_Wear_Level_Title="Wear Level"'
echo " "
echo " "
echo "###### Drive Ignore List"
echo "# What does it do:"
echo "#  Use this to list any drives to ignore and remove from the report.  This is very useful for ignoring USB Flash Drives"
echo "#  or other drives for which good data is not able to be collected (non-standard)."
echo "#"
echo "# How to use it:"
echo "#  We are using a comma delimited file to identify the drive serial numbers.  You MUST use the exact and full serial"
echo "#  number smartctl reports, if there is no identical match then it will not match. Additionally you may list drives"
echo "#  from other systems and they will not have any effect on a system where the drive does not exist.  This is great"
echo "#  to have one configuration file that can be used on several systems."
echo "#"
echo '# Example: "VMWare,1JUMLBD,21HNSAFC21410E"'
echo " "
echo 'Ignore_Drives="none"'
echo " "
echo " "
echo "###### Drive UDMA_CRC_Error_Count List"
echo "# What does it do:"
echo "#  If you have a drive which has an UDMA count other than 0 (zero), this setting will offset the"
echo "#  value back to zero for the concerns of monitoring future increases of this specific error. Any match will"
echo "#  subtract the given value to report a 0 (zero) value and highlight it in yellow to denote it was overridden."
echo "#  The Warning Title will not be flagged if this is zero'd out in this manner."
echo "#  NOTE: UDMA_CRC_Errors are typically permanently stored in the drive and cannot be reset to zero even though"
echo "#        they are frequently caused by a data cable communications error."
echo "#"
echo "# How to use it:"
echo "#  List each drive by serial number and include the current UDMA_CRC_Error_Count value."
echo "#  The format is very specific and will not work if you "wing it", use the Live EXAMPLE."
echo "#"
echo "#  Set the FLAG in the FLAGS Section ignoreUDMA to "false" (the default setting)."
echo "#"
echo "# If the error count exceeds the limit minus the offset then a warning message will be generated."
echo "# On the Status Report the UDMA CRC Errors block will be YELLOW with a value of "0" for an overridden value."
echo "#   -- NOTE: We are using the colon : as the separator between the drive serial number and the value to change."
echo "#"
echo "# Format: variable="Drive_Serial_Number:Current_UDMA_Error_Count" and add a comma if you have more than one drive."
echo "#"
echo "# The below example shows drive WD-WMC4N2578099 has 1 UDMA_CRC_Error, drive S2X1J90CA48799 has 2 errors."
echo "#"
echo '# Example: CRC_Errors="WD-WMC4N2578099:1,S2X1J90CA48799:2,P02618119268:1"'
echo " "
if [[ $CRC_Errors == "" ]]; then echo 'CRC_Errors="none"'; else echo 'CRC_Errors="'$CRC_Errors'"'; fi 
echo " "
echo " "
echo "###### Multi_Zone_Errors List"
echo "# What does it do:"
echo "#   This identifies drives with Multi_Zone_Errors which may be irritating people."
echo "#   Multi_Zone_Errors "for some drives, not all drives" are pretty much meaningless."
echo "#"
echo "# How to use it:"
echo "#   Use same format as CRC_Errors (see above)."
echo " "
if [[ $Multi_Zone == "" ]]; then echo 'Multi_Zone="none"'; else echo 'Multi_Zone="'$Multi_Zone'"'; fi
echo " "
echo " "
echo "#######  Reallocated Sectors Exceptions"
echo "# What does it do:"
echo "#  This will offset any Reallocated Sectors count by the value provided."
echo "#"
echo "#  I do not recommend using this feature as I'm a believer in if you have over 5 bad sectors, odds are the drive will get worse."
echo "#  I'd recommend replacing the drive before complete failure.  But that is your decision."
echo "#"
echo "#  Why is it even an option?"
echo "#  I use it for testing purposes only but you may want to use it."
echo "#"
echo "# How to use it:"
echo "#   Use same format as CRC_Errors (see above)."
echo " "
if [[ $Bad_Sectors == "" ]]; then echo 'Bad_Sectors="none"'; else echo 'Bad_Sectors="'$Bad_Sectors'"'; fi
echo " "
echo "######## ATA Error Log Silencing ##################"
echo "# What does it do:"
echo "#   This will ignore error log messages equal to or less than the threshold."
echo "# How to use:"
echo "#   Same as the CRC_Errors, [drive serial number:error count]"
echo " "
echo 'ata_errors="none"'
echo " "
echo "####### Custom Drive Configuration (Experimental)"
echo "# Used to define specific alarm values for specific drives by serial number."
echo "# This should only be used for drives where the default alarm settings"
echo "# are not proper.  Up to 24 unique drive values may be stored."
echo "#"
echo "# Use -config to set these values."
echo " "
echo 'Custom_Drives=""'
echo " "
echo "####### Warranty Expiration Date"
echo "# What does it do:"
echo "# This section is used to add warranty expirations for designated drives and to create an alert when they expire."
echo "# The date format is YYYY-MM-DD."
echo "#"
echo "# Below is an example for the format using my own drives, which yes, are expired."
echo "# As previously stated above, drive serial numbers must be an exact match to what smartctl reports to function."
echo "#"
echo "# If the drive does not exist, for example my drives are not on your system, then nothing will happen."
echo "#"
echo "# How to use it:"
echo '#   Use the format ="Drive_Serial_Number:YYYY-MM-DD" and add a comma if you have more than one drive.'
echo "#"
echo '# Example: Drive_Warranty="K1JUMLBD:2020-09-30,K1JRSWLD:2020-09-30,K1JUMW4D:2020-09-30,K1GVD84B:2020-10-12"'
echo " "
echo 'Drive_Warranty="none"'
echo " "
echo 'expiredWarrantyBoxColor="#000000"   # "#000000" = normal box perimeter color.'
echo 'WarrantyBoxPixels="1"   # Box line thickness. 1 = normal, 2 = thick, 3 = Very Thick, used for expired drives only.'
echo 'WarrantyBackgndColor="#f1ffad"  # Hex code or "none" = normal background, Only for expired drives.'
echo " "
echo '######## Enable-Disable Text Portion ########'
echo 'enable_text="true"    # This will display the Text Section when = "true" or remove it when not "true".  Default="true"'
echo " "
echo "###### Global table of colors"
echo "# The colors selected you can change but you will need to look up the proper HEX code for a color."
echo " "
echo 'okColor="#b5fcb9"       # Hex code for color to use in SMART Status column if drives pass (default is darker light green, #b5fcb9).'
echo 'warnColor="#f765d0"     # Hex code for WARN color (default is purple, #f765d0).'
echo 'critColor="#ff0000"     # Hex code for CRITICAL color (default is red, #ff0000).'
echo 'altColor="#f4f4f4"      # Table background alternates row colors between white and this color (default is light gray, #f4f4f4).'
echo 'whtColor="#ffffff"      # Hex for White background.'
echo 'ovrdColor="#ffffe4"     # Hex code for Override Yellow.'
echo 'blueColor="#87ceeb"     # Hex code for Sky Blue, used for the SCRUB In Progress background.'
echo 'yellowColor="#f1ffad"   # Hex code for pale yellow.'
) > "$Config_File_Name"

    echo " "
    sleep 2
    echo "Humm, kind of slow..."
    sleep 2
    echo " "
    echo "Do you have enough RAM? Looks like about 8KB.  Troubleshooting..."
    sleep 2
    echo " "
    echo "I found the problem, the system was identified as a Tandy TRS-80 Model 1"
    echo "Wow! That was a fantastic consumer computer, in it's day."
    echo "Adjusting for the 1.774 MHz clock rate..."
    sleep 2
    echo "Success!"
    echo " "
    echo "New clean configuration complete."
    echo " "
    echo "Path and Name if the configuration file: "$Config_File_Name
    echo " "
    echo " "
    echo "If you desire more customization, rerun the -config and select Advanced options."
    echo " "
    echo "And for those who don't know what TRS-80 is, Google it."
    exit 0
    ;;


    X)
    echo " "
    echo " "
    echo "Exiting..."
    echo " "
    echo " "
    z=50
    
    exit 1
    ;;


    *)
    echo " "
    echo " "
    echo "DO YOU WANT TO PLAY A GAME?"
    echo " "
    echo " "
    sleep 2
    ;;
# End First Level
esac
done
shopt -u nocasematch

}

################# HELP INSTRUCTIONS #################

display_help () {

echo "NAME"
echo "      Multi Report - System status reporting for TrueNAS Core and Scale"
echo " "
echo "SYNOPSIS"
echo "      multi_report.sh [options]"
echo " "
echo "COPYRIGHT AND LICENSE"
echo "      Multi Report is Copyright (C) by its authors and licensed under the"
echo "      GNU General Public License v3.0"
echo " "
echo "DESCRIPTION"
echo "      Multi Report generates an email containing a summary chart of your"
echo "      media and their health. Directly after the chart is a Text Section which"
echo "      may immediately contain failure information followed by Zpool data,"
echo "      key SMART data for each drive, and raw data for drives that do not report"
echo "      SMART.  In addition if configured, statistical data is collected for"
echo "      long-term monitoring. This script currently runs on both Core (FreeBSD)"
echo "      and Scale (Debian Linux) versions."
echo " "
echo "OPTIONS"
echo "      -help         This message."
echo "      -h            List the most common options."
echo "      -s            Record drive statistics only, do not generate a"
echo "                    corresponding email."
echo "      -config       Generate or edit a configuration file in the directory the"
echo "                    script is run from."
echo "      -delete       Deletes the statistical data file if the file exists."
echo "      -dump [all]   Generates an email with attachments of all drive data and the"
echo "                    multi_report_config.txt additionally it also suppress the"
echo "                    config_backup file and statistics file from being attached"
echo "                    to the email unless you use the [all] option, then the"
echo "                    config_backup and statistics files will be appended."
echo " "
echo "      The options listed below are intended for developer use only."
echo " "
echo "      HDD | SSD | NVM input_file = (TEST) Use the selected drive data report"
echo "        created from the -dump option.  This assists in developer recognition"
echo "        of drives not properly reporting data."
echo " "
echo "      -purgetestdata This will purge all test data from the statistical data"
echo "                     file."
echo " "
echo "      Running the script without any switches will collect statistical data"
echo "      and generate a report."
echo " "
echo "CONFIGURATION"
echo "      The script has become quite complex over time and with added features"
echo "      ultimately required an external configuration file with version 1.6c"
echo "      to simplify upgrades to the end user."
echo " "
echo "      If the external configuration file does not exist, the script will use"
echo "      the values hard code into the script (just like versions 1.6b and"
echo "      earlier), however there is now an email address check to ensure you have"
echo "      changed the email address within the script."
echo " "
echo "      In order to generate an external configuration file you must use the"
echo "      [-config] parameter when running the script which is the preferred"
echo "      method to configure your script.  Four options will be available:"
echo " "
echo "          N)ew configuration file"
echo "          A)dvanced configuration"
echo "          H)ow to use this configuration tool"
echo "          X) Exit"
echo " "
echo "      N)ew configuration file will create/overwrite a new configuration file."
echo "      This is the minimal setup before running the script without parameters."
echo "      The configuration file will be created in the directory the script is"
echo "      located in."
echo " "
echo " "
echo "      Default settings should be sufficient to test this script."
echo " "
echo "STATISTICAL DATA"
echo "      Besides the emailed chart the script can also email you attachments for"
echo "      your FreeNAS/TrueNAS configuration file and a Statistical Data file."
echo " "
echo "      The statistical data file is a comma delimited collection of drive data"
echo "      that can be opened in any spreadsheet program such as Microsoft Excel."
echo "      This data could prove to be useful in diagnosing and troubleshooting"
echo "      drive or system problems."
echo " "
echo "EMAIL CONTENT"
echo "      Normal operation of this script will produce an output email and it may"
echo "      or may not have attachments per your configuration.  The email will"
echo "      contain the following information:"
echo " "
echo "      - Subject with Summary Result of 'All is Good', '*WARNING*', or"
echo "        '*CRITICAL ERROR*'"  
echo "        The summary result is based on your settings of the warning and critical"
echo "        settings, where:"
echo "        All is Good = No Alarm indications."
echo "        *WARNING* = A warning threshold has been crossed and it means you should"
echo "           investigate and take action."
echo "        *CRITICAL* = Something significant has occurred and your data could be"
echo "           at risk, take immediate action."
echo " "
echo "      - The version of the script and the version of TrueNAS you are running."
echo "      - The date and time the script was run."
echo "      - Zpool Status Report Summary: (Pool Name/Status/Size/Errors/Scrub Info)"
echo "      - HDD Summary Report Chart: (Drive ID/Serial Number/other data)"
echo "      - SSD Summary Report Chart: (Basically the same as the HDD report)"
echo "      - NVMe Summary Report Chart: (Basically the same as the SSD report)"
echo "      - Text Section:  The Text section contains the text version of most of"
echo "        the previously displayed data.  It will tell you"
echo "      -- if using an external configuration file"
echo "      -- if saving statistical information"
echo "      -- if a drive warranty has expired"
echo "      -- Zpool native report - in which the gptid's are listed '*followed by a" 
echo "         listing of the drives that make up the pool and the drives are listed"
echo "         in the order the gptid numbers are listed.*'"
echo "      -- Drive relevant SMART data followed by if TLER/SCT is enabled/disabled"
echo "         or available."
echo "      -- NON-SMART data will be listed for drives that do not support SMART."
echo " "
echo "      While all this data is nice to have, there is no substitute for having"
echo "      due diligence in examining your hardware and ensuring it is working"
echo "      correctly.  This means you may need to examine your SMART data closer."
echo " "
echo "USAGE"
echo "      This script was designed to be run from the CRON service, generally once"
echo "      a day in order to produce an email output to notify the user of any"
echo "      problems or trends. To identify trends the script also collects"
echo "      statistical data for analysis."
echo " "
echo "      A good starting point is to set up a CRON job to run this script once a"
echo "      day at e.g. 2:00AM using no switches. This will produce an email snapshot"
echo "      once a day."
echo " "
echo "      In addition if you are trying to troubleshoot heat problems for example"
echo "      then I would recommend you setup an additional CRON job run the file with"
echo "      the -s switch for collecting statistical data only (i.e. no email report)."
echo "      This statistics cron job should run more frequently, usually every hour"
echo "      or more frequently.  The corresponding cron job should be scheduled to"
echo "      not overlap with the daily report email."
echo "      --If you sleep your drives then this option may not be desirable.--"
echo " "
echo "CUSTOMIZATIONS AND FEATURES"
echo "      There are quite a few built in features in the external configuration file"
echo "      and these are a few:"
echo " "
echo "      Custom Chart Titles: Change the name of any or all headers and columns."
echo "      Selectable Columns: Display or remove as many or few columns of data as"
echo "          desired. This is great for removing a column with no relevant data."
echo "      Alarm Setpoints: Practically everything has an alarm setpoint, from pool"
echo "          capacity to Scrub Age, to temperature Warnings and Critical Warnings,"
echo "          and a plethora of options."
echo "      TLER: You can monitor and even have TLER automatically set if required,"
echo "          for drives which support it. The default is to not automatically set"
echo "          TLER on, I believe the user should make that decision."
echo "      Statistical Data: Modify the location of your data, if you want it emailed"
echo "          and when to email, and we include an automatic purge to ensure the"
echo "          data file doesn't get too large (default 2 years)."
echo "      UDMA CRC Error Corrections: Have you ever had a hard drive UDMA_CRC_Error?"
echo "          Well they often are caused by a poor/loose data cable but the error"
echo "          will be recorded forever in the drive electronics. This option lets"
echo "          you zero out the value in the script. This feature is usable for"
echo "          Bad Sectors and Multi Zone Errors as well."
echo "      Ignore Drive: Every wished you could just ignore a USB Flash Drive or any"
echo "          drive just giving you problems? With this feature the drive will be"
echo "          completely ignored in the script."
echo "      Warranty Expiring Warning: You can configure the configuration file to"
echo "          provide a warning message for a drive on a certain date.  This a great"
echo "          tool to keep track on when it might be time to consider buying some"
echo "          replacement drives."
echo "      Custom Colors: Use the HEX color codes to change the color scheme of the"
echo "          background and alerting colors on the charts.  This is ONLY"
echo "          changeable manually, you have to edit the config file."
echo " "
echo "      It is very important that if you edit the configuration file or the script"
echo "      that you need to maintain the proper formatting of the text or you will"
echo "      throw a wrench into things."
echo " "
echo "HOW TO HANDLE ERRORS"
echo "      If you run across errors running the script, odd are it is because a drive"
echo "      was not recognized properly.  I recommend you post your error to the forum"
echo "      to as for assistance.  It is very possible you will be asked for a -dump"
echo "      of your data in order to let the developers assist you and correct the"
echo "      problem."
echo " "
echo "      Please note that a -dump file is not the same as a cut/paste of a terminal"
echo "      window.  Critical formatting data is lost that is required."
echo " "
echo "Advice:  When troubleshooting a problem you may be asked to provide dump data"
echo "to assist in troubleshooting.  Use the "-dump all" to include all possible data."
echo "Use "-dump" if you only need to provide the drive data and configuration file."
echo " "

}

display_help_commands () {

echo "NAME"
echo "      Multi Report - System status reporting for TrueNAS Core and Scale"
echo " "
echo "SYNOPSIS"
echo "      multi_report.sh [options]"
echo " "
echo "COPYRIGHT AND LICENSE"
echo "      Multi Report is Copyright (C) by its authors and licensed under the"
echo "      GNU General Public License v3.0"
echo " "
echo "COMMON OPTIONS"
echo "      -h            This message."
echo "      -help         Full Help message."
echo "      -s            Record drive statistics only, do not generate a"
echo "                    corresponding email."
echo "      -config       Generate or edit a configuration file in the directory the"
echo "                    script is run from."
echo "      -dump [all]   Generates an email with attachments of all drive data and the"
echo "                    multi_report_config.txt additionally it also suppress the"
echo "                    config_backup file and statistics file from being attached"
echo "                    to the email unless you use the [all] option, then the"
echo "                    config_backup and statistics files will be appended."
echo " "
echo "Advice:  When troubleshooting a problem you may be asked to provide dump data"
echo "to assist in troubleshooting.  Use the "-dump all" to include all possible data."
echo "Use "-dump" if you only need to provide the drive data and configuration file."
echo " "
}

######################  DUMP DRIVE DATA ###################
# This routine will dump the selected drive data into individual files for troubleshooting.
#
# Let's make this a user interactive feature
#
dump_drive_data () {

 (
  # Write MIME section header for file attachment (encoded with base64)
  echo "--${boundary}"
  echo "Content-Type: text/html"
  echo "Content-Transfer-Encoding: base64"
  echo "Content-Disposition: attachment; filename=drive_${drive}_a.txt"
  base64 "/tmp/drive_${drive}_a.txt"

  echo "--${boundary}"
  echo "Content-Type: text/html"
  echo "Content-Transfer-Encoding: base64"
  echo "Content-Disposition: attachment; filename=drive_${drive}_x.txt"
  base64 "/tmp/drive_${drive}_x.txt"
 ) >> "$logfile"
force_delay
}

### DEFINE FUNCTIONS END ###

#######################
#######################
###                 ###
###  PROGRAM START  ###
###                 ###
#######################
#######################

# The order in which these processed occur is unfortunately dependent.
# The -s switch will just collect statistical data.
# The HDD|SSD|NVM switch will allow a raw text file for smartctl -a, followed by the input filename.

echo $programver
smartdata=""

if ! [[ "$1" == "-config" || "$1" == "-help" || "$1" == "-delete" || "$1" == "HDD" || "$1" == "SSD" || "$1" == "NVM" || "$1" == "-s" || "$1" == "" || "$1" == "-dump" || "$1" == "-purgetestdata" || "$1" == "-h" ]]; then
echo '"'$1'" is not a valid option.'
echo "Use -h for help and look under OPTIONS."
echo " "
exit 1
fi

if [[ "$1" == "-config" ]]; then
generate_config_file
exit 0
fi

if [[ "$1" == "-help" ]]; then
clear
display_help
exit 0
fi

if [[ "$1" == "-h" ]]; then
clear
display_help_commands
exit 0
fi

# if -dump then interactive user selected dumping, if "all" then automatic dumping of everything.
# Use dump_all=1 during the running routine to gather all the drive data and dump to drive ID files.
# if -dump all is used, then include config and statistical attachments (dump_all=2).
# Dump the files into /tmp/ and then email them.

if [[ "$1" == "-dump" ]]; then
   if [[ "$2" == "all" ]]; then dump_all="2"; echo "Attaching Drive Data, Multi-Report Configuration, Statistics, and TrueNAS Configuration files."; else dump_all="1"; echo "Attaching Drive Data and Multi-Report Configuration files."; fi
else
   dump_all="0"
fi

if [[ "$1" == "-delete" ]]; then
echo "Preparing to Delete Statistical Data File"
echo " "
read -p "Press Enter/Return to Continue or CTRL-C to Abort Script"
rm "$statistical_data_file"
echo " "
echo "File Obliterated !!!"
echo " "
exit 0
fi

if [[ "$1" == "-purgetestdata" ]]; then
purge_testdata
exit 0
fi

if [[ "$1" == "-s" ]]; then echo "Commencing Statistical Data Collection Only"; fi

load_config

# Cleanup previous run files.
cleanup_files

if [[ "$dump_all" == "1" ]]; then configBackup="false"; expDataEmail="false"; fi
if [[ "$dump_all" == "2" ]]; then configBackup="true"; expDataEmail="true"; configSendDay="All"; expDataEmailSend="All"; fi

# Not certain I need this here, comment out on final production tests.
testfile=""

datestamp2=$(date -Idate)
datestamp=$(date +%Y/%m/%d)
# FreeBSD gets second resolution unfortunately
  if [[ $softver != "Linux" ]]; then
     timestamp=$(date +%T)
  else
# Linux gets millisecond resolution
  timestamp=$(date +"%T.%2N")
  fi

if [[ $(date +"%m-%d") == "04-01" ]]; then Fun=1; echo "Fun Day"; else Fun=0; fi

if [[ "$1" == "HDD" ]]; then
### Add a test routine if $2 is null, exit stating missing parameter and then spit out the HELP command

# Read the data in the testdata_path location and create the testdata.txt file
create_testdata_text_file

testfile="$2"

if test -f "$testfile"; then
echo "Test File Exists"
else
echo "Test File Does Not Exist"
exit 1
fi
fi

get_smartHDD_listings
testfile=""

if [[ "$1" == "SSD" ]]; then
testfile="$2"
if test -f "$testfile"; then
echo "Test File Exists"
else
echo "Test File Does Not Exist"
exit 1
fi
fi
get_smartSSD_listings
testfile=""

if [[ "$1" == "NVM" ]]; then
testfile="$2"

if test -f "$testfile"; then
echo "Test File Exists"
else
echo "Test File Does Not Exist"
exit 1
fi
fi
get_smartNVM_listings
testfile=""

get_smartOther_listings

email_preformat

config_backup

zpool_report

  if [[ $expDataEnable == "true" ]]; then
     if test -e "$statistical_data_file"; then
# Purge items over expDataPurge days
        statistical_data_file_created=0
     else
# The file does not exist, create it.
       printf "Date,Time,Device ID,Drive Type,Serial Number,SMART Status,Temp,Power On Hours,Wear Level,Start Stop Count,Load Cycle,Spin Retry,Reallocated Sectors,\
       Reallocated Sector Events,Pending Sectors,Offline Uncorrectable,UDMA CRC Errors,Seek Error Rate,Multi Zone Errors,Read Error Rate,Helium Level\n" > "$statistical_data_file"
# And set flag the file was created.
       statistical_data_file_created=1
     fi
  fi

# Generate SMART HDD Report
SER1=""
if [[ "$smartdrives" != "" ]]; then
generate_table "HDD"
if [[ "$1" == "HDD" ]]; then
  testfile="$2"
fi

for drive in $smartdrives; do
  clear_variables
  get_drive_data
  crunch_numbers "HDD"
  write_table "HDD"
done
end_table "HDD"
fi
testfile=""

# Generate SSD Report
SER1=""
if [[ $includeSSD == "true" ]]; then
# Test if any SSD's are available, if not then no report, if yes then generate SSD/NVM Report.
   if [[ $smartdrivesSSD != "" ]]; then
     generate_table "SSD"
       if [[ "$1" == "SSD" ]]; then
          testfile="$2"
       fi
     for drive in $smartdrivesSSD; do
       clear_variables
       get_drive_data
       crunch_numbers "SSD"
       write_table "SSD"
     done
     end_table "SSD"
     testfile=""
   fi
fi

# Generate NVMe Report
SER1=""
if [[ $includeNVM == "true" ]]; then
   if [[ $smartdrivesNVM != "" ]]; then
     generate_table "NVM"
       if [[ "$1" == "NVM" ]]; then
          testfile="$2"
       fi
       for drive in $smartdrivesNVM; do
         clear_variables
         get_drive_data
         crunch_numbers "NVM"
         write_table "NVM"
       done
       end_table "NVM"
       testfile=""
   fi
fi
       for drive in $nonsmartdrives; do
         clear_variables
         get_drive_data "NON" 
       done

# This purge happens here directly after data collection.
# A zero (0) value = Disable Purging (Keep all data)
if [[ $expDataPurge != 0 ]]; then
purge_exportdata
fi
write_ata_errors="0"
if [[ "$enable_text" == "true" ]]; then
detailed_report $2

if [[ $reportnonSMART == "true" ]]; then
  if [[ $disableRAWdata != "true" ]]; then
    non_smart_report
  fi
fi
fi
# Update multi_report_config.txt file if required.
   if [[ $write_ata_errors == "1" ]]; then
       ata_errors="$(echo "$temp_ata_errors" | sed 's/.$//')"
       update_config_file
   fi

if [[ "$1" == "-s" ]]; then
  echo "Statistical Data Collection Complete"
else
  email_datafile
  remove_junk_report
  create_email
fi

# All reporting files are left in the /tmp/ directory for troubleshooting and cleaned up when the script is initial run.