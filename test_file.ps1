$SQLQuery_AssetInsert = 
"INSERT INTO [isg_AssetMgmt].[dbo].[ISG_Assets]
([Hostname])
VALUES
(@'ComputerName')
GO"


$AssetInsertVars = @( "ComputerName='hello'" )
Invoke-Sqlcmd -Query $SQLQuery_AssetInsert -Variable $AssetInsertVars -ServerInstance "SEL-DBS-11.synseal.com,1433" -Database isg_AssetMgmt
