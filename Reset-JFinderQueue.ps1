<#

.SYNOPSIS

Reset's the Sun Message Queue used by JFinder.

Written by Simon Brown (2011).

.DESCRIPTION

The Reset-JFinderQueue function clears and reset's the Sun Message

Queue used by JFinder.  It includes the option to re-import all previously

failed jobs.

.PARAMETER reimport

Specifies whether or not you wish to re-import all failed jobs.

.EXAMPLE


--------------- EXAMPLE 1 -----------------


Reset-JFinderQueue



#>
Function Reset-JFinderQueue {
Param (
[switch]$ReImport = $false
)

###  Stop Services ###
Get-Service | Where {$_.Name -eq "JFinder"} | Stop-Service
Get-Service | Where {$_.Name -eq "iMQ_Broker"} | Stop-Service

$ProcessorInfo = Get-WmiObject -Class Win32_Processor

If ($ProcessorInfo.DataWidth -eq "32")
{
	$JFinderLocation = "C:\Program Files\AutoFORM\JFinderV2\"
	$MQLocation = "C:\Program Files\Sun\MessageQueue3\bin\ "
}
ElseIf ($ProcessorInfo.DataWidth -eq "64")
{
	$JFinderLocation = "C:\Program Files (x86)\AutoFORM\JFinderV2\"
	$MQLocation = "C:\Program Files (x86)\Sun\MessageQueue3\bin\"
}

Set-Location $JFinderLocation\WORK\PICKUP
New-Item -Name BACKUP -ItemType Directory -Force
Get-ChildItem | Where {!$_.PSIsContainer} | ForEach-Object {
	Move-Item -Path $_.FullName -Destination .\BACKUP\ -Force
}

Set-Location $JFinderLocation\WORK\PROCESSED
New-Item -Name BACKUP -ItemType Directory -Force
Get-ChildItem | Where {!$_.PSIsContainer} | ForEach-Object {
	Move-Item -Path $_.FullName -Destination .\BACKUP\ -Force
}
If ($ReImport)
{
	Get-ChildItem -LiteralPath .\BACKUP | Where {$_.Name -like "FPickUp*.zip"} | Foreach-Object {
		$FullName = $_.FullName
		$NewName = $_.Name.Substring(2)
		$NewFullName = $_.PSParentPath + "\" + $NewName
		Rename-Item -Path $_.Name -NewName $NewName -Force}
}

Set-Location $MQLocation
Invoke-Command -ScriptBlock {imqbrokerd.exe -reset messages}

If ($ReImport)
{
	Set-Location $JFinderLocation\WORK\PROCESSED\BACKUP
	Get-ChildItem | Where {$_.Name -like "Pickup*.zip"} | ForEach-Object {
		Move-Item -Path $_.FullName -Destination ..\ -Force}
}

###  Start Services  ###
Get-Service | Where {$_.Name -eq "JFinder"} | Start-Service
Get-Service | Where {$_.Name -eq "iMQ_Broker"} | Start-Service





















}