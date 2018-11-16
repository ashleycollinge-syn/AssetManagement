$query = "SELECT [Hostname]
      ,[host_id]
      ,[User]
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
      ,[Last_Updated]
  FROM [isg_AssetMgmt].[dbo].[ISG_Assets]
  WHERE [Model] != 'VMware Virtual Platform' AND [Model] != 'ProLiant DL380 G7' AND [Model] != 'Proliant DL360 G7' AND [Model] != 'ProLiant DL380 Gen9'
GO"

Invoke-SQLcmd -ServerInstance 'SEL-DBS-11.synseal.com,1433' -query $query -Database ISG_AssetMgmt | Export-Csv AssetMgmt-AssetReport.csv