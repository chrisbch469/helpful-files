# Create for migrating from old print server to new print server so users can keep their settings
#	1. Gets existing printers, copies to text file
#	2. Replace svprint01 with hcbvprint01 in text file
#	3. For every printer in text file, add new printer
#	4. Get existing default printer, replace with hcbvprint01
#	5. Set default printer
#	6. Remove old printers and text files created with script
#  (This is  commented out until testing actual printing with new printers, but it will remove old printers)

$OldPrintSvr = "oldprintservername"
$NewPrintSvr = "newprintservername"

# create directory for temp files
New-Item -Force -Path "c:\" -Name "temp" -ItemType "directory"
New-Item -Force -Path "c:\temp\" -Name "oldPrinters.txt" -ItemType "file"
New-Item -Force -Path "c:\temp\" -Name "newPrinters.txt" -ItemType "file"

# create text file with printers and change to new servername
(Get-Printer).name | where {$_ -match $OldPrintSvr} > c:\temp\oldPrinters.txt
(Get-Content c:\temp\oldPrinters.txt) -replace $OldPrintSvr, $NewPrintSvr | Set-Content c:\temp\newPrinters.txt
$NewPrinterList = Get-Content c:\temp\newPrinters.txt
$oldPrinterList = Get-Content c:\temp\oldPrinters.txt

# add new printers using new servername
Foreach ($Printer in $NewPrinterList){
	Add-Printer -ConnectionName $Printer
}

# get default printer, change servername and set default
$OldDefaultPrinter = (Get-WmiObject win32_printer | Where-Object Default -eq $True).Name
$DefPrinter = $oldDefaultPrinter -replace "$OldPrintSvr", "$NewPrintSvr"
# set default print /y with name (/n) 
RUNDLL32 PRINTUI.DLL,PrintUIEntry /y /n "$DefPrinter"

# remove printer that connects to old server name
#Foreach ($oldPrinter in $oldPrinterList){
#	Remove-Printer -Name $oldPrinter
#}

# remove files (uncomment after testing)
# Remove-Item C:\temp\*.txt*
