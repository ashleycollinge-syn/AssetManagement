#REQUIRES -Version 2.0

<#
.SYNOPSIS
    Dynamic Asset Management Script
.DESCRIPTION
    Pulls a list of all machines in AD. Runs through the machines and for each one collects
    some generic information which it outputs to the ISG_Assets table.
    Any Asset failures get outputted to ISG_AssetFailures
.NOTES
    File Name      : script.ps1
    Author         : Ashley Collinge (ashley.collinge@synseal.com)
					James Smith (james.smith@synseal.com)
    Prerequisite   : PowerShell V2 over Vista and upper.
#>

#$secpasswd = ConvertTo-SecureString (Read-Host) -AsPlainText -Force
#$mycreds = New-Object System.Management.Automation.PSCredential ("administrator", $secpasswd)

# get a list of all of the computers from AD

$Logfile = "$(gc env:computername).log"

Function LogWrite
{
   Param ([string]$logstring)

   Add-content $Logfile -value $logstring
}


$computers = Get-ADComputer -Filter * -Properties DNSHostName
$computers | ForEach-Object {
    Write-Host $_.DNSHostName
    Try
    {
        <# Here is where we need to do all of the data collection, we only need to insert to sql when approp. #>
        $localDNSHostname = $_.DNSHostName
        $secpasswd = ConvertTo-SecureString "" -AsPlainText -Force
        $mycreds = New-Object System.Management.Automation.PSCredential ("administrator", $secpasswd)
        $s = New-PSSession -ComputerName $_.DNSHostName -Credential $mycreds -Authentication Negotiate -EnableNetworkAccess -ErrorAction Stop
        $computernamePre = Invoke-Command -Session $s -ScriptBlock {Get-ChildItem -Path env:computername} #Select-Object COMPUTERNAME | Select-Object -ExpandProperty "PSComputerName" | Out-String}
        $computername = $computernamePre.PSComputerName
        $IPAddress = Invoke-Command -Session $s -ScriptBlock {Get-WmiObject win32_networkadapterconfiguration | where { $_.ipaddress -like "1*" } | select -ExpandProperty ipaddress | select -First 1}
        $MacAddress2 = Invoke-Command -Session $s -ScriptBlock {Get-WmiObject -Class Win32_NetworkAdapter}
        $MacAddress = $MacAddress2.MacAddress | Out-String
        $OperatingSystem = Invoke-Command -Session $s -ScriptBlock {Get-WmiObject win32_operatingsystem | select -expand "Caption"}
        $ServicePackVersion = Invoke-Command -Session $s -ScriptBlock {Get-WmiObject Win32_operatingSystem | select -expand "ServicePackMajorVersion"}
        $SerialNumber = Invoke-Command -Session $s -scriptBlock {Get-WmiObject win32_bios | select -expand "SerialNumber"}

        [String]$ProcessorMaxClockSpeed = Invoke-Command -Session $s -ScriptBlock { Get-WmiObject Win32_Processor | Select-Object -ExpandProperty MaxClockSpeed | Out-String}
        [String]$ProcessorModel = Invoke-Command -Session $s -ScriptBlock {Get-WmiObject Win32_Processor | Select-Object -ExpandProperty Name | Out-String}
        [String]$ProcessorNumberOfCores = Invoke-Command -Session $s -ScriptBlock {Get-WmiObject Win32_Processor | Select-Object -ExpandProperty NumberOfCores | Out-String}
        [String]$ProcessorNumberOfLogicalProcessors = Invoke-Command -Session $s -ScriptBlock {Get-WmiObject Win32_Processor | Select-Object -ExpandProperty NumberOfLogicalProcessors | Out-String}
        [String]$Manufacturer = Invoke-Command -Session $s -ScriptBlock {Get-WmiObject Win32_ComputerSystem | Select-Object -ExpandProperty Manufacturer}
        [String]$Model = Invoke-Command -Session $s -ScriptBlock {Get-WmiObject Win32_ComputerSystem | Select-Object -ExpandProperty Model}
        [String]$MemoryCapacity = Invoke-Command -Session $s -ScriptBlock {Get-WmiObject Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum | Select-Object -ExpandProperty Sum}
        $SystemEnclosure =  Invoke-Command -Session $s -ScriptBlock {Get-WmiObject -Class win32_systemenclosure}
        if(!$SystemEnclosure) {
            $isLaptop = "true"
        }
        else {
            $isLaptop = "false"
        }
        $Last_Updated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        
        $SQLQuery_ForUpdating = "
        SET ANSI_WARNINGS OFF;
        IF EXISTS (SELECT * FROM [dbo].[ISG_Assets] WHERE [Hostname]='$computername')
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
                WHERE [Hostname]='$computername'
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
                        ('$computername'
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
        Invoke-SQLcmd -ServerInstance 'SEL-DBS-11.synseal.com,1433' -query $SQLQuery_ForUpdating -Database isg_AssetMgmt
        LogWrite -logstring "Got generic info from $computername "
        Remove-PSSession -Session $s -ea silentlycontinue
        try {
            $script= {
                $value = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty
                $value | ForEach-Object -Process { $_.GetValue('DisplayName'), $_.GetValue('DisplayVersion'), $_.GetValue('Publisher')}
                return $value
            }
    
            $s = New-PSSession -ComputerName $_.DNSHostName -Credential $mycreds -Authentication Negotiate -EnableNetworkAccess -ErrorAction Stop
            $hostname = $_.DNSHostName
            $obj = Invoke-Command -Session $s -ScriptBlock $script
            Write-Host $obj
            foreach ($product in $obj) {
                if (!$product.DisplayName) {
                }
                else {
                    $DisplayName = $product.DisplayName
                    $DisplayVersion = $product.DisplayVersion
                    $Publisher = $product.Publisher
                    $insert_software = "
                    SET ANSI_WARNINGS OFF;
                    IF EXISTS (SELECT * FROM [dbo].[ISG_Installed_Software] WHERE [DisplayName]='$DisplayName' AND [Hostname] = '$computername')
                        UPDATE [dbo].[ISG_Installed_Software] 
                            SET [DisplayName] = '$DisplayName'
                            ,[DisplayVersion] = '$DisplayVersion'
                            ,[Publisher] = '$Publisher'
                            WHERE [Hostname]='$computername' AND [DisplayName] = '$DisplayName'
                            ELSE
                                INSERT INTO [isg_AssetMgmt].[dbo].[ISG_Installed_Software]
                                    ([Hostname]
                                    ,[DisplayName]
                                    ,[DisplayVersion]
                                    ,[Publisher]
                                    )
                                VALUES
                                    ('$computername'
                                    ,'$DisplayName'
                                    ,'$DisplayVersion'
                                    ,'$Publisher')
                    SET ANSI_WARNINGS ON;
                    "
                    Invoke-SQLcmd -ServerInstance 'SEL-DBS-11.synseal.com,1433' -query $insert_software -Database isg_AssetMgmt
                }
            }
            LogWrite -logstring "Got software info from $computername "
            Remove-PSSession -Session $s -ea SilentlyContinue

            # more here

            try {
                # collect disk info here
                $script= {
                    $value = Get-WmiObject -Class Win32_LogicalDisk
                    return $value
                }
                $s = New-PSSession -ComputerName "SEL0486.synseal.com" -Credential $mycreds -Authentication Negotiate -EnableNetworkAccess
                $obj = Invoke-Command -Session $s -ScriptBlock $script
                foreach ($drive in $obj) {
                    if (($drive.DriveType = 3) -And ($drive.MediaType = 12)) {
                        $Caption = $drive.Caption
                        $DeviceID = $drive.DeviceID
                        $FileSystem = $drive.FileSystem
                        $FreeSpace = $drive.FreeSpace
                        $Name = $drive.Name
                        $Size = $drive.Size
                        $Status = $drive.Status
                        $VolumeName = $drive.VolumeName
                        $VolumeSerialNumber = $drive.VolumeSerialNumber
                        $insert_disk = "
                        SET ANSI_WARNINGS OFF;
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
                            ('$computername'
                            ,'$Caption'
                            ,'$DeviceID'
                            ,'$FileSystem'
                            ,'$FreeSpace'
                            ,'$Name'
                            ,'$Size'
                            ,'$Status'
                            ,'$VolumeName'
                            ,'$VolumeSerialNumber')
                        GO
                        SET ANSI_WARNINGS ON;
                        "
                        Invoke-SQLcmd -ServerInstance 'SEL-DBS-11.synseal.com,1433' -query $insert_disk -Database isg_AssetMgmt
                        LogWrite -logstring "got disk info from $computername "
                        Remove-PSSession -Session $s -ea silentlycontinue
                    }
                    else {
                        LogWrite -logstring "failed to get disk info from $computername "
                        Remove-PSSession -Session $s -ea silentlycontinue
                    }
                }
            }
            catch {
                LogWrite -logstring "failed to get disk info from $computername "
                Remove-PSSession -Session $s -ea silentlycontinue
            }
        }
        catch {
            LogWrite -logstring "Failed to get generic info from $computername "
            Remove-PSSession -Session $s -ea silentlycontinue
        }
    }
    catch
    {
        Write-Host failed to connect
        $datetime_attempt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $insertquery=" 
        SET ANSI_WARNINGS OFF;
        INSERT INTO [dbo].[ISG_AssetFailures] 
                ([ComputerName]
                ,[WinRMResult]
                ,[datetime_attempt]) 
            VALUES 
                ('$localDNSHostname'
                ,'$_.Exception'
                ,'$datetime_attempt')
        GO 
        SET ANSI_WARNINGS ON;
        " 
        Invoke-SQLcmd -ServerInstance 'SEL-DBS-11.synseal.com,1433' -query $insertquery -Database isg_AssetMgmt
        LogWrite -logstring "Failed to get generic info from $computername "
        Remove-PSSession -Session $s -ea silentlycontinue
    }

    # more stuff here
}


