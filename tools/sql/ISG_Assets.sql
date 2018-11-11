USE [isg_AssetMgmt]
GO

/****** Object:  Table [dbo].[ISG_Assets]    Script Date: 11/11/2018 17:40:11 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ISG_Assets](
	[Hostname] [nchar](50) NULL,
	[host_id] [int] IDENTITY(1,1) NOT NULL,
	[IPAddress] [nchar](50) NULL,
	[MACAddress] [nchar](50) NULL,
	[OS] [nchar](50) NULL,
	[SPVersion] [nchar](10) NULL,
	[Manufacturer] [nchar](50) NULL,
	[Model] [nchar](50) NULL,
	[MemoryCapacity] [nchar](10) NULL,
	[MaxClockSpeed] [nchar](10) NULL,
	[LogicalCoreCount] [nchar](10) NULL,
	[CoreCount] [nchar](10) NULL,
	[ProcessorModel] [nchar](50) NULL,
	[SerialNumber] [nchar](50) NULL,
	[IsLaptop] [nchar](10) NULL,
	[Last_Updated] [datetime] NULL,
 CONSTRAINT [PK_ISG_Assets] PRIMARY KEY CLUSTERED 
(
	[host_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


