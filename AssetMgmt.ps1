#REQUIRES -Version 2.0

<#
.SYNOPSIS
    Asset Management Script
.DESCRIPTION
    Using AD the script will go to each ADComputer and retrieve the
    following information and save to a SQL database.
    - Generic Asset Information
        - Hostname
        - IP Address
        - MAC Address
        - Operating System
        - Service Pack Version
        - Manufacturer
        - Model
        - Memory Capacity
        - Max Clock Speed
        - Logical Core Count
        - Physical Core Count
        - Processor Model
        - Serial Number
        - Laptop or not
    - Installed Software
        - Display Name
        - Display Version
        - Publisher
    - Disk Information
        - Caption
        - Size
        - Free Space
        - Device ID
        - Volume Serial Number
        - Volume Name
        - File System
        - Name
        - Status
.PARAMETER ComputerName
.EXAMPLE
.NOTES
    File Name      : AssetMgmt.ps1
    Author         : Ashley Collinge (ashley.collinge@synseal.com)
					James Smith (james.smith@synseal.com)
    Prerequisite   : PowerShell V2 over Vista and upper.
#>

param (
    [string]$price = 100, 
    [string]$ComputerName = $env:computername,    
    [switch]$SaveData = $false
)

<# Declare all of the Powershell script blocks needed to send to clients#>

$PSScript_GetAsset = {
    $AssetInformation = New-Object PSObject
    $AssetInformation | Add-Member Noteproperty Hostname (Get-ChildItem -Path env:computername).Value
    $NetworkInfo = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq "True" }
    $IPAddresses = ForEach($item in $NetworkInfo) {$item.IPAddress[0]}
    $AssetInformation | Add-Member Noteproperty IPAddress $IPAddresses
    $AssetInformation | Add-Member Noteproperty MacAddress $NetworkInfo.MACAddress
    $OSInfo = Get-WmiObject Win32_OperatingSystem
    $AssetInformation | Add-Member Noteproperty OperatingSystem ($OSInfo | Select-Object -ExpandProperty "Caption")
    $AssetInformation | Add-Member Noteproperty ServicePackVersion ($OSInfo | Select-Object -ExpandProperty "ServicePackMajorVersion")
    $AssetInformation | Add-Member Noteproperty SerialNumber (Get-WmiObject Win32_BIOS | Select-Object -ExpandProperty "SerialNumber")
    $CSInfo = Get-WmiObject Win32_ComputerSystem
    $AssetInformation | Add-Member NoteProperty Manufacturer ($CSInfo | Select-Object -ExpandProperty "Manufacturer")
    $AssetInformation | Add-Member Noteproperty Model ($CSInfo | Select-Object -ExpandProperty "Model")
    $AssetInformation | Add-Member Noteproperty MemoryCapacity (Get-WmiObject Win32_PhysicalMemory | Measure-Object -Property "Capacity" -Sum | Select-Object -ExpandProperty "Sum")
    $CPUInfo = Get-WmiObject Win32_Processor
    $AssetInformation | Add-Member Noteproperty ProcessorMaxClockSpeed ($CPUInfo | Select-Object -ExpandProperty "MaxClockSpeed")
    $AssetInformation | Add-Member Noteproperty ProcessorNumberOfLogicalProcessors ($CPUInfo | Select-Object -ExpandProperty "NumberOfLogicalProcessors")
    $AssetInformation | Add-Member Noteproperty ProcessorNumberOfCores ($CPUInfo | Select-Object -ExpandProperty "NumberOfCores")
    $AssetInformation | Add-Member Noteproperty ProcessorModel ($CPUInfo | Select-Object -ExpandProperty "Name")
    $SystemEnclosure =  Get-WmiObject -Class Win32_SystemEnclosure
    if(!$SystemEnclosure) {
        $AssetInformation | Add-Member Noteproperty isLaptop "true"
    }
    else {
        $AssetInformation | Add-Member Noteproperty isLaptop "false"
    }
    return $AssetInformation
}

$PSScript_GetSoftware =
{
    $value = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty
    #$value | ForEach-Object -Process { $_.GetValue('DisplayName'), $_.GetValue('DisplayVersion'), $_.GetValue('Publisher')}
    return $value
}

$PSScript_GetDisk =
{
    $value = Get-WmiObject -Class Win32_LogicalDisk
    return $value
}

$SQLQuery_AssetFailure = 
"SET ANSI_WARNINGS OFF;
INSERT INTO [dbo].[ISG_AssetFailures] 
        ([ComputerName]
        ,[WinRMResult]
        ,[datetime_attempt]) 
    VALUES 
        ('$localDNSHostname'
        ,'$_.Exception'
        ,'$datetime_attempt')
SET ANSI_WARNINGS ON;
GO"

<# Declare all of the helper functions we need. #>

$Logfile = "AssetMgmt.log"
Function LogWrite
{
    <# 
    This function will log the string passed to it
    to a text file in the relative dir the script
    is ran from.
    #>
   Param ([string]$logstring)
   Add-content $Logfile -value $logstring
}

<# Start the main function #>

$ADComputers = Get-ADComputer -Filter * -Properties DNSHostName
$Password = ConvertTo-SecureString "" -AsPlainText -Force
$ADCredentials = New-Object System.Management.Automation.PSCredential ("administrator", $Password)

<# For each of the computers in AD, collect information #>
ForEach ($ADComputer in $ADComputers) {
        Write-Host ($ADComputer.DNSHostName + "Connecting to WinRM")
        try{
            $ClientComputerSession = New-PSSession -ComputerName $ADComputer.DNSHostName -Credential $ADCredentials -Authentication Negotiate -EnableNetworkAccess -ErrorAction Stop
        }
        catch {
            Write-Host "Failed to connect to WinRM: "$ADComputer.DNSHostName
            Continue
        }

        <# Run the generic asset collection function #>
        Write-Host ($ADComputer.DNSHostName + "Collecting generic asset information")
        $AssetInformation = Invoke-Command -Session $ClientComputerSession -ScriptBlock $PSScript_GetAsset
        $Hostname = $AssetInformation.Hostname
        $IPAddress = $AssetInformation.IPAddress
        $MacAddress = $AssetInformation.MacAddress
        $OperatingSystem = $AssetInformation.OperatingSystem
        $ServicePackVersion = $AssetInformation.ServicePackVersion
        $SerialNumber = $AssetInformation.SerialNumber
        $Manufacturer = $AssetInformation.Manufacturer
        $Model = $AssetInformation.Model
        $MemoryCapacity = $AssetInformation.MemoryCapacity
        $ProcessorMaxClockSpeed = $AssetInformation.ProcessorMaxClockSpeed
        $ProcessorNumberOfLogicalProcessors = $AssetInformation.ProcessorNumberOfLogicalProcessors
        $ProcessorNumberOfCores = $AssetInformation.ProcessorNumberOfCores
        $ProcessorModel = $AssetInformation.ProcessorModel
        $isLaptop = $AssetInformation.isLaptop
        $Last_Updated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

        <# Save Generic asset info to sql #>

        $SQLQuery_AssetInsert = 
        "SET ANSI_WARNINGS OFF;
        IF EXISTS (SELECT * FROM [dbo].[ISG_Assets] WHERE [Hostname]='$Hostname')
            UPDATE [dbo].[ISG_Assets] 
                SET [IPAddress] = '$IPAddress'
                ,[MACAddress] = '$MacAddress'
                ,[OS] = '$OperatingSystem'
                ,[SPVersion] = '$ServicePackVersion'
                ,[Manufacturer] = '$Manufacturer'
                ,[Model] = '$Model'
                ,[MemoryCapacity] = '$MemoryCapacity'
                ,[MaxClockSpeed] = '$ProcessorMaxClockSpeed'
                ,[LogicalCoreCount] = '$ProcessorNumberOfLogicalProcessors'
                ,[CoreCount] = '$ProcessorNumberOfCores'
                ,[ProcessorModel] = '$ProcessorModel'
                ,[SerialNumber] = '$SerialNumber'
                ,[IsLaptop] = '$isLaptop'
                ,[Last_Updated] = '$Last_Updated'
                WHERE [Hostname]='$Hostname'
                ELSE
                    INSERT INTO [isg_AssetMgmt].[dbo].[ISG_Assets]
                        ([Hostname]
                        ,[IPAddress]
                        ,[MACAddress]
                        ,[OS]
                        ,[SPVersion]
                        ,[Manufacturer]
                        ,[Model]
                        ,[MemoryCapacity]
                        ,[MaxClockSpeed]
                        ,[LogicalCoreCount]
                        ,[CoreCount]
                        ,[ProcessorModel]
                        ,[SerialNumber]
                        ,[IsLaptop]
                        ,[Last_Updated])
                    VALUES
                        ('$Hostname'
                        ,'$IPAddress'
                        ,'$MacAddress'
                        ,'$OperatingSystem'
                        ,'$ServicePackVersion'
                        ,'$Manufacturer'
                        ,'$Model'
                        ,'$MemoryCapacity'
                        ,'$ProcessorMaxClockSpeed'
                        ,'$ProcessorNumberOfLogicalProcessors'
                        ,'$ProcessorNumberOfCores'
                        ,'$ProcessorModel'
                        ,'$SerialNumber'
                        ,'$isLaptop'
                        ,'$Last_Updated')
        SET ANSI_WARNINGS ON;
        GO"
        Invoke-SQLcmd -ServerInstance 'SEL-DBS-11.synseal.com,1433' -query $SQLQuery_AssetInsert -Database isg_AssetMgmt

        <# Run the installed software function #>
        Write-Host ($ADComputer.DNSHostName + "Collecting software information")
        $SoftwareInformation = Invoke-Command -Session $ClientComputerSession -ScriptBlock $PSScript_GetSoftware
        
        foreach ($SoftwareProduct in $SoftwareInformation) {
            if (!$SoftwareProduct.DisplayName) {
                # If there is no Display name don't include in collection
            }
            else {
                $DisplayName = $SoftwareProduct.DisplayName
                $DisplayVersion = $SoftwareProduct.DisplayVersion
                $Publisher = $SoftwareProduct.Publisher

                <# Save software info to sql #>

                $SQLQuery_SoftwareInsert = 
                "SET ANSI_WARNINGS OFF;
                IF EXISTS (SELECT * FROM [dbo].[ISG_Installed_Software] WHERE [DisplayName]='$DisplayName' AND [Hostname] = '$Hostname')
                    UPDATE [dbo].[ISG_Installed_Software] 
                        SET [DisplayName] = '$DisplayName'
                        ,[DisplayVersion] = '$DisplayVersion'
                        ,[Publisher] = '$Publisher'
                        WHERE [Hostname]='$Hostname' AND [DisplayName] = '$DisplayName'
                        ELSE
                            INSERT INTO [isg_AssetMgmt].[dbo].[ISG_Installed_Software]
                                ([Hostname]
                                ,[DisplayName]
                                ,[DisplayVersion]
                                ,[Publisher]
                                )
                            VALUES
                                ('$Hostname'
                                ,'$DisplayName'
                                ,'$DisplayVersion'
                                ,'$Publisher')
                SET ANSI_WARNINGS ON;
                GO"

                Invoke-SQLcmd -ServerInstance 'SEL-DBS-11.synseal.com,1433' -query $SQLQuery_SoftwareInsert -Database isg_AssetMgmt
            }
        }

        <# Start disk info collection here #>
        Write-Host ($ADComputer.DNSHostName + "Collecting disk information")
        $DiskInformation = Invoke-Command -Session $ClientComputerSession -ScriptBlock $PSScript_GetDisk
        foreach ($Drive in $DiskInformation) {
            if (($Drive.DriveType = 3) -And ($Drive.MediaType = 12) -And ($Drive.FileSystem)) {
                $Caption = $Drive.Caption
                $DeviceID = $Drive.DeviceID
                $FileSystem = $Drive.FileSystem
                $FreeSpace = $Drive.FreeSpace
                $Name = $Drive.Name
                $Size = $Drive.Size
                $Status = $Drive.Status
                $VolumeName = $Drive.VolumeName
                $VolumeSerialNumber = $Drive.VolumeSerialNumber

                $SQLQuery_DiskInsert = 
                "SET ANSI_WARNINGS OFF;
                INSERT INTO [isg_AssetMgmt].[dbo].[ISG_Disks]
                    ([Hostname]
                    ,[Caption]
                    ,[DeviceID]
                    ,[FileSystem]
                    ,[FreeSpace]
                    ,[Name]
                    ,[Size]
                    ,[Status]
                    ,[VolumeName]
                    ,[VolumeSerialNumber])
                VALUES
                    ('$Hostname'
                    ,'$Caption'
                    ,'$DeviceID'
                    ,'$FileSystem'
                    ,'$FreeSpace'
                    ,'$Name'
                    ,'$Size'
                    ,'$Status'
                    ,'$VolumeName'
                    ,'$VolumeSerialNumber')
                SET ANSI_WARNINGS ON;
                GO"

                Invoke-SQLcmd -ServerInstance 'SEL-DBS-11.synseal.com,1433' -query $SQLQuery_DiskInsert -Database isg_AssetMgmt
            }
        }
        Remove-PSSession -Session $ClientComputerSession
}
