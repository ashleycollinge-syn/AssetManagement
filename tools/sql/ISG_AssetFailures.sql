USE [isg_AssetMgmt]
GO

/****** Object:  Table [dbo].[ISG_AssetFailures]    Script Date: 11/11/2018 17:40:38 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ISG_AssetFailures](
	[ComputerName] [nchar](100) NULL,
	[WinRMResult] [nchar](200) NULL,
	[failure_id] [int] IDENTITY(1,1) NOT NULL,
	[datetime_attempt] [datetime] NULL,
 CONSTRAINT [PK_ISG_AssetFailures] PRIMARY KEY CLUSTERED 
(
	[failure_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


