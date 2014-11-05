USE [001]
GO

/****** Object:  Table [dbo].[tblEdMailControl]    Script Date: 08/13/2014 15:51:19 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[tblEdMailControl](
	[ImportId] [int] IDENTITY(1,1) NOT NULL,
	[ImportBatchId] [varchar](14) NULL,
	[DocType] [varchar](50) NULL,
	[DocKey] [varchar](50) NULL,
	[SenderID] [varchar](50) NULL,
	[ReceiverID] [varchar](50) NULL,
	[ISAControlNum] [varchar](50) NULL,
	[GSControlNum] [varchar](50) NULL,
	[STControlNum] [varchar](50) NULL,
	[GSVersion] [varchar](50) NULL,
	[StatusFlag] [varchar](50) NULL,
	[SendDate] [datetime] NULL,
	[SendTime] [varchar](50) NULL,
	[IsNew] [bit] NULL,
	[DeletedYn] [bit] NULL,
	[DeleteUserId] [dbo].[pUserID] NULL,
	[DeleteWrkStnId] [dbo].[pWrkStnID] NULL,
	[DeleteDate] [datetime] NULL,
	[FAISAControlNum] [varchar](50) NULL,
	[FAGSControlNum] [varchar](50) NULL,
	[FASTControlNum] [varchar](50) NULL,
	[FAReturnCode] [varchar](1) NULL,
	[FADate] [varchar](8) NULL,
	[FATime] [varchar](4) NULL,
	[KeyLevelSeq1] [int] NULL,
	[PartnerId] [varchar](20) NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO


