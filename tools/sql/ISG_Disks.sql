USE [isg_AssetMgmt]
GO

/****** Object:  Table [dbo].[ISG_Disks]    Script Date: 11/11/2018 17:41:01 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ISG_Disks](
	[Hostname] [nchar](50) NULL,
	[Caption] [nchar](50) NULL,
	[Size] [nchar](50) NULL,
	[FreeSpace] [nchar](50) NULL,
	[DeviceID] [nchar](50) NULL,
	[VolumeSerialNumber] [nchar](50) NULL,
	[VolumeName] [nchar](50) NULL,
	[FileSystem] [nchar](50) NULL,
	[Name] [nchar](50) NULL,
	[Status] [nchar](50) NULL,
	[Disk_id] [int] IDENTITY(1,1) NOT NULL,
 CONSTRAINT [PK_ISG_Disks] PRIMARY KEY CLUSTERED 
(
	[Disk_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


