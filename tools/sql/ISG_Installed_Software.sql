USE [isg_AssetMgmt]
GO

/****** Object:  Table [dbo].[ISG_Installed_Software]    Script Date: 11/11/2018 17:40:48 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ISG_Installed_Software](
	[Hostname] [nchar](100) NULL,
	[DisplayName] [nchar](100) NULL,
	[DisplayVersion] [nchar](100) NULL,
	[Publisher] [nchar](100) NULL,
	[software_id] [int] IDENTITY(1,1) NOT NULL,
 CONSTRAINT [PK_ISG_Installed_Software] PRIMARY KEY CLUSTERED 
(
	[software_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


