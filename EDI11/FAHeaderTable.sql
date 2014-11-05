USE [001]
GO

/****** Object:  Table [dbo].[tblEdFaHeader]    Script Date: 08/13/2014 15:41:02 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[tblEdFaHeader](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ImportBatchId] [varchar](14) NULL,
	[DocType] [varchar](50) NULL,
	[KeySenderId] [varchar](50) NULL,
	[KeyISAControlNum] [varchar](50) NULL,
	[KeyGSControlNum] [varchar](50) NULL,
	[KeySTControlNum] [varchar](50) NULL,
	[GSControlNumber] [varchar](50) NULL,
	[GSAckCode] [varchar](50) NULL,
	[SegmentsSent] [varchar](50) NULL,
	[SegmentsReceived] [varchar](50) NULL,
	[SegmentsAccepted] [varchar](50) NULL,
 CONSTRAINT [PK_tblEdFaHeader] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO


