# this script is to run through all of the machines in AD
# and determine whether they can be contacted through WMI
# save this information to a sql table for easy access
# 
# will also do a small run of connecting to the pc and
# trying to pull down some info to prove the connection
# is working, also outputs to sql table

Import-Module ActiveDirectory

$secpasswd = ConvertTo-SecureString (Read-Host) -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential ("administrator", $secpasswd)


<# Get-ADComputer -Filter * -Properties DNSHostName | ForEach-Object {
    Write-Host Testing: $_.DNSHostName
    #Test-WSMan -ComputerName $_.DNSHostName -Authentication Negotiate
    #Test-Connection -ComputerName $_.DNSHostName -Count 1 -Quiet
    Enter-PSSession -ComputerName $_.DNSHostName -EnableNetworkAccess -Credential $mycreds -Authentication Negotiate
    Write-Host $env:COMPUTERNAME
    Exit-PSSession
} #>

$computers = Get-ADComputer -Filter * -Properties DNSHostName
$computers | ForEach-Object {
    Write-Host $_.DNSHostName
    Try
    {
        $localDNSHostname = $_.DNSHostName
        $s = New-PSSession -ComputerName $_.DNSHostName -Credential $mycreds -Authentication Negotiate -EnableNetworkAccess -ErrorAction Stop
        $computername = Invoke-Command -Session $s -ScriptBlock {Get-ChildItem -Path env:computername | Select-Object COMPUTERNAME}
        Write-Host "Remotely accessed: " ($computername | Select-Object -ExpandProperty "PSComputerName")
        $insertquery=" 
        SET ANSI_WARNINGS OFF;
        INSERT INTO [dbo].[WinRMTest] 
                ([ComputerName] 
                ,[WinRM_Result]) 
            VALUES 
                ('$localDNSHostname'
                ,'Succeeded')
        GO 
        SET ANSI_WARNINGS ON;
        " 
        Invoke-SQLcmd -ServerInstance 'SEL-DBS-11.synseal.com,1433' -query $insertquery -Database isg_AssetMgmt
        Remove-PSSession -Session $s
    }
    catch
    {
        Write-Host failed to connect
        $insertquery=" 
        SET ANSI_WARNINGS OFF;
        INSERT INTO [dbo].[WinRMTest] 
                ([ComputerName] 
                ,[WinRM_Result]) 
            VALUES 
                ('$localDNSHostname'
                ,'Failed')
        GO 
        SET ANSI_WARNINGS ON;
        " 
        Invoke-SQLcmd -ServerInstance 'SEL-DBS-11.synseal.com,1433' -query $insertquery -Database isg_AssetMgmt
    }
}
<# 1098 #>