#!/bin/bash

##### Version 2.0
echo "smr-check Version 2.0"

# Forked from BasilHendroff repository as it has not been updated in several years.
# Updated on 3 August 2025 by JoeSchmuckatelli (joeschmuck2023@hotmail.com) with ten more drives.


###### 	MODEL NUMBER MATCH ######
# Table column widths
DeviceWidth=7
ModelWidth=15
SerialWidth=20

# Gather drive information and populate arrays
midclt call disk.query | jq -S '.[] | {devname: .devname, model: .model, serial: .serial}' > tmp.json

declare -a "Device=($(<tmp.json jq -r '.devname | @sh'))"
declare -a "Model=($(<tmp.json jq -r '.model | @sh'))"
declare -a "Serial=($(<tmp.json jq -r '.serial | @sh'))"

rm tmp.json

# Detection engine
# $1 = Name of array
# $2 = Any character to trigger silent mode
function DetectSMR() {
	# Initialise
	name=$1[@]
	SMR=("${!name}")
	unset TMP

	# For each drive
	for ((i=0;i<${#Device[@]};i++)); do
	# Is this manufacturer prefix in the model name?
	  if [[ "${Model[$i]:0:6}" == *"${SMR[0]}"* ]]; then
	# If so, add the trimmed model name to a temporary array  
		TMP[$i]="${Model[$i]#*" "}"
		TMP[$i]="${TMP[$i]%%-*}"
	# Is this string in the trimmed model name (usually a suffix)?
		if [[ "${TMP[$i]}" == *"${SMR[-1]}"* ]]; then
		  for ((j=1;j<$((${#SMR[@]}-1));j++)); do
	# Is this number in the trimmed model name?
			if [[ "${TMP[$i]}" == *"${SMR[j]}"* ]]; then
			  if [[ -z "$2" ]]; then  
				printf "$fmt" "${Device[$i]}" "${TMP[$i]}" "${Serial[$i]}"
			  else
				f=1
			  fi
			fi
		  done
		fi
	  fi
	done
	}
	
# The SMR database is made up of a number of arrays (sorted by suffix below)
#
# References:
# 1. https://www.truenas.com/community/resources/list-of-known-smr-drives.141/
# 2. https://nascompares.com/answer/list-of-wd-cmr-and-smr-hard-drives-hdd/
# 3. https://hddscan.com/blog/2020/hdd-wd-smr.html
# 4. https://www.seagate.com/files/www-content/datasheets/pdfs/skyhawk-3-5-hdd-DS1902-15M-2103US-en_US.pdf
# 5. https://www.seagate.com/www-content/datasheets/pdfs/skyhawk-3-5-hdd-DS1902-15-2009GB-en_AS.pdf
# 6. https://www.seagate.com/www-content/datasheets/pdfs/barracuda-2-5-DS1907-3-2005GB-en_AU.pdf
# 7. https://gutendata.de/portfolio-item/how-to-shoose-hard-drive-introduction-in-magnetic-recording-technology-that-maybe-you-heard-on-pmr-cmr-and-epmr-smr-hamr-and-mamr-tdmr-and-bpmr/
# 8. https://documents.westerndigital.com/content/dam/doc-library/en_us/assets/public/western-digital/product/data-center-drives/ultrastar-dc-hc600-series/data-sheet-ultrastar-dc-hc620.pdf 
# 9. https://documents.westerndigital.com/content/dam/doc-library/en_us/assets/public/western-digital/product/data-center-drives/ultrastar-dc-hc600-series/data-sheet-ultrastar-dc-hc650.pdf
# 10. https://www.toshiba-storage.com/wp/wp-content/uploads/2017/08/TOSH_16046_P300_GB_30_11.pdf
# 11. https://www.seagate.com/products/enterprise-drives/exos/exos-m/
# 12. https://www.westerndigital.com/products/internal-drives/data-center-drives/ultrastar-dc-hc650-hdd?sku=ultrastar-dc-hc650-20-tb
# 13. https://www.westerndigital.com/products/internal-drives/data-center-drives/ultrastar-dc-hc690-hdd?sku=WSH723200AL4201
# 14. https://www.westerndigital.com/products/internal-drives/data-center-drives/ultrastar-dc-hc670-hdd?sku=ultrastar-dc-hc670-26-tb
# 15. https://www.westerndigital.com/products/internal-drives/data-center-drives/ultrastar-dc-hc680-hdd?sku=ultrastar-dc-hc680-28tb-se

# Format of data:
# Need the model number as presented by midclt. `midclt call disk.query | jq`
# The first column must be contained in the drive model.
# The last column must match.  Use null "" to ignore the last column.
# Any column in between, one must match as well.


# DRIVE MANUFACTURER AND MODEL            REF    DESCRIPTION
#----------------------------------------- ---    -----------------------------------------
# Western Digital
WD01=("WDC WD" "40" "60" "EDAZ")            #3    WD Elements(3.5) 4TB 6TB
WD02=("WDC WD" "20" "30" "40" "60" "EFAX")  #1    WD Red(3.5) 2TB 3TB 4TB 6TB  
WD03=("WDC WD" "40" "60" "EMAZ")            #3 #7 WD Elements/MyBook/Easystore(3.5) 6TB
WD04=("WDC WD" "20" "30" "40" "60" "EZAZ")  #1 #7 WD Blue/Elements(3.5) 2TB 3TB 4TB 6TB  
WD05=("WDC WD" "5000" "LPSX")               #2    WD Black(2.5) 500GB
WD06=("WDC WD" "9000" "LPZX")               #1    WD Blue(2.5) 900GB
WD07=("WDC WD" "40" "50" "NDZM")            #7    WD ArmorATD/MyPassport/G-DRIVE(2.5) 4TB 5TB
WD08=("WDC WD" "40" "50" "NDZW")            #7    WD MyPassport(2.5) 4TB 5TB
WD09=("WDC WD" "30" "NMRW")                 #7    WD Easystore(2.5) 3TB
WD10=("WDC WD" "40" "NMZM")                 #7    WD ArmorATD/MyPassport/G-DRIVE(2.5) 4TB 
WD11=("WDC WD" "30" "40" "50" "NMZW")       #7    WD P10/Elements/Easystore/PS4/Xbox(2.5) 4TB
WD12=("WDC WD" "40" "NPZZ")                 #3    WD Blue(2.5) 4TB
WD13=("WDC WD" "10" "20" "SDZM")            #7    WD MyPassport(2.5) 1TB 2TB
WD14=("WDC WD" "10" "20" "SMZM")            #7    WD ArmorATD/G-DRIVE(2.5) 1TB 2TB
WD15=("WDC WD" "10" "20" "SDZW")            #7    WD MyPassport(2.5) 1TB 2TB
WD16=("WDC WD" "10" "20" "SMZW")            #7    WD P10/Easystore/Elements(2.5) 2TB
WD17=("WDC WD" "10" "SPSX")                 #1    WD Black(2.5) 1TB
WD18=("WDC WD" "10" "SPWX")                 #1    WD Blue(2.5) 1TB
WD19=("WDC WD" "10" "20" "SPZX")            #1    WD Blue(2.5) 1TB 2TB
WD20=("WSH" "723200" "723220" "AL")			#13	  WD Ultrastar DC HC690 Data Center Drive (3.5) 30TB 32TB
WD21=("ULTRASTAR" "HC650" "HC670" "TB")		#12	#14 WD Ultrastar DC HC650/HC670 Data Center Drive (3.5) 20TB/26TB
WD22=("ULTRASTAR" "HC680" "26TB" "27TB" "28TB" "")	#15 WD Ultrastar DC HC680 Data Center Drive (3.5) 26TB 27TB 28TB
# New upcoming SMR drives: UltraSMR 36TB and 44TB (2026/2027)

# Hitachi Global Storage Technologies (now Western Digital) 
HGST01=("HSH72" "1414" "1415" "AL42M0")     #7 #8 Ultrastar HC620(3.5) 14TB 15TB
HGST02=("HSH72" "1414" "1415" "AL42M4")     #7 #8 Ultrastar HC620(3.5) 14TB 15TB
HGST03=("HSH72" "1414" "1415" "AL52M0")     #7 #8 Ultrastar HC620(3.5) 14TB 15TB
HGST04=("HSH72" "1414" "1415" "AL52M4")     #7 #8 Ultrastar HC620(3.5) 14TB 15TB
HGST05=("HSH72" "1414" "1415" "ALE6M0")     #7 #8 Ultrastar HC620(3.5) 14TB 15TB
HGST06=("HSH72" "1414" "1415" "ALE6M4")     #7 #8 Ultrastar HC620(3.5) 14TB 15TB
HGST07=("HSH72" "1414" "1415" "ALN6M0")     #7 #8 Ultrastar HC620(3.5) 14TB 15TB
HGST08=("HSH72" "1414" "1415" "ALN6M4")     #7 #8 Ultrastar HC620(3.5) 14TB 15TB
HGST09=("WSH72" "2020" "ALN6L1")            #7 #9 Ultrastar HC650(3.5) 20TB
HGST10=("WSH72" "2020" "ALN6L4")            #7 #9 Ultrastar HC650(3.5) 20TB
HGST11=("WSH72" "2020" "ALN6L5")            #7 #9 Ultrastar HC650(3.5) 20TB
HGST12=("WSH72" "2020" "AL4201")            #7 #9 Ultrastar HC650(3.5) 20TB
HGST13=("WSH72" "2020" "AL4204")            #7 #9 Ultrastar HC650(3.5) 20TB
HGST14=("WSH72" "2020" "AL4205")            #7 #9 Ultrastar HC650(3.5) 20TB

# Seagate
ST01=("ST" "6000" "8000" "AS0002")          #1    Archive(3.5) 6TB 8TB 
ST02=("ST" "8000" "AS0003")                 #1    Exos (3.5) 8TB 
ST03=("ST" "5000" "AS0011")                 #1    Archive(3.5) 5TB
ST04=("ST" "4000" "5000" "DM000")           #1 #7 Desktop/Expansion(3.5) 4TB 5TB
ST05=("ST" "5000" "6000" "DM003")           #1 #7 Barracuda/Expansion/BackupoPlus(3.5) 5TB 6TB
ST06=("ST" "4000" "8000" "DM004")           #1 #7 Barracuda/Expansion/LaCie(3.5) 4TB 8TB
ST07=("ST" "2000" "DM005")                  #1    Barracuda(3.5) 4TB 2TB
ST08=("ST" "3000" "DM007")                  #1    Barracuda(3.5) 3TB
ST09=("ST" "2000" "DM008")                  #1    Barracuda(3.5) 2TB
ST10=("ST" "500" "DM009")                   #7    Barracuda(3.5) 500GB
ST11=("ST" "5000" "LM000")                  #1 #6 #7  Barracuda/BackupPlus/Expansion/LaCie/Portable/Xbox(2.5) 5TB
ST12=("ST" "2000" "LM007")                  #7    BackupPlus/Expansion/LaCie/Portable/PS/Xbox/DJI(2.5) 2TB
ST13=("ST" "2000" "LM010")                  #7    LaCie/BackupPlus(2.5) 2TB
ST14=("ST" "2000" "LM015")                  #1 #6 Barracuda/Xbox(2.5) 2TB
ST15=("ST" "3000" "4000" "LM024")           #1 #6 #7 Barracuda/BackupPlus/ExpaPS4/nsion/LaCie/Portable/PS4/Xbox(2.5) 3TB 4TB
ST16=("ST" "500" "LM030")                   #6    Barracuda(2.5) 500GB
ST17=("ST" "500" "LM034")                   #6    Barracuda(2.5) 500GB
ST18=("ST" "1000" "LM035")                  #7    BackupPlus/Expansion/LaCie/Portable/Chromebook/Duet/Joy(2.5) 1TB
ST19=("ST" "1000" "LM038")                  #7    LaCie/BackupPlus(2.5) 1TB
ST20=("ST" "1000" "LM048")                  #1 #6 Barracuda(2.5) 1TB
ST21=("ST" "1000" "LM049")                  #6    Barracuda(2.5) 1TB
ST22=("ST" "2000" "LX001")                  #7    FireCuda(2.5) 2TB
ST23=("ST" "1000" "LX015")                  #7    FireCuda(2.5) 1TB
ST24=("ST" "500" "LX025")                   #7    FireCuda(2.5) 500GB
ST25=("ST" "8000" "VX002")                  #2 #4 Skyhawk(3.5) 8TB
ST26=("ST" "4000" "VX005")                  #2 #4 Skyhawk(3.5) 4TB
ST27=("ST" "2000" "VX007")                  #2    Skyhawk(3.5) 2TB
ST28=("ST" "1000" "8000" "VX008")           #1 #2 Skyhawk(3.5) 1TB 8TB 
ST29=("ST" "6000" "VX010")                  #2    Skyhawk(3.5) 6TB
ST30=("ST" "6000" "VX011")                  #2 #4 Skyhawk(3.5) 6TB
ST31=("ST" "2000" "VX012")                  #2 #4 Skyhawk(3.5) 2TB
ST32=("ST" "4000" "VX013")                  #2 #5 Skyhawk(3.5 UK) 4TB
ST33=("ST" "2000" "VX015")                  #2 #5 Skyhawk(3.5 UK) 2TB
ST34=("ST" "3000" "VX016")                  #2    Skyhawk(3.5) 3TB
ST35=("ST" "3000" "VX017")                  #2    Skyhawk(3.5) 3TB
ST36=("ST" "32000" "36000" "NM003K")        #10   Mosaic 3+ (3.5) 32TB 36TB

# Toshiba
TO01=("DT02" "400" "600" "ABA")             #1 #7 DT02(3.5) 4TB 6TB
TO02=("MQ04" "200" "ABD")                   #1 #7 MQ04(2.5) 2TB
TO03=("MQ04" "100" "ABF")                   #1 #7 MQ04(2.5) 1TB
TO04=("MQ04" "400" "UBB")                   #7    Canvio(2.5) 4TB
TO05=("MQ04" "200" "UBD")                   #7    Canvio(2.5) 2TB
TO06=("MQ04" "100" "UBF")                   #7    Canvio(2.5) 1TB
TO07=("HDWC" "360" "EK3JB")                 #7    Canvio(3.5) 6TB
TO08=("HDWD" "240" "260" "320" "UZSVA" "")  #1 #7 #10 P300(3.5) 2TB 4TB 6TB		# Added null as the drive model numbers do not always list "UZSVZ"
TO09=("HDWL" "110" "120" "EZSTA" "")        #1 #7 L200(2.5) 1TB 2TB				# Repeated
TO10=("HDWL" "110" "120" "UZSVA" "")        #1 #7 L200(2.5) 1TB 2TB				# Repeated

# To test this script when you have no SMR drives, configure and temporarily uncomment one of the the TEST arrays below with a valid CMR drives on your system. 
# TEST=("WDC WD" "30" "EFRX")
# TEST=("HGST" "HDN72" "HDN92" "6060" "ALE")
# TEST=("ST" "6000" "VN0041")
# Now uncomment the TEST lines below (there should be two of them), and run the script. Remeber to comment all TEST lines again when you've finished.

# Quiet detection phase. If an SMR drive is detected flag f will be set.
f=0

# Detect Western Digital SMR drives
for k in {01..22}; do
  DetectSMR WD"$k" q
done

# Detect HGST SMR drives
for k in {01..14}; do
  DetectSMR HGST"$k" q
done

# Detect Seagate SMR drives
for k in {01..36}; do
  DetectSMR ST"$k" q
done

# Detect Toshiba SMR drives
for k in {01..10}; do
  DetectSMR TO"$k" q
done

# DetectSMR TEST q

# If the flag f is still unset, no SMR drive was detected. :)
if [[ "$f" == 0 ]]; then
  echo
  echo "No known SMR drives detected based on midclt provided model number."
  echo
else
# otherwise, one or more SMR drives were detected so diplay all SMR drives in a table :(
  echo
  echo "Known SMR drive(s) detected based on midclt provided model number."
  echo

  fmt="%${DeviceWidth}s | %${ModelWidth}s | %${SerialWidth}s |\n"
  
  printf "$fmt" "Device" "Model" "Serial Number" 
  separator=$(printf "%-$((DeviceWidth+ModelWidth+SerialWidth+8))s" "-")
  echo "${separator// /-}"

# Detect Western Digital SMR drives
  for k in {01..22}; do
    DetectSMR WD"$k"
  done

# Detect HGST SMR drives
for k in {01..14}; do
  DetectSMR HGST"$k"
done

# Detect Seagate SMR drives
  for k in {01..36}; do
    DetectSMR ST"$k"
  done

# Detect Toshiba SMR drives
for k in {01..10}; do
  DetectSMR TO"$k"
done

# DetectSMR TEST  
  echo
fi
