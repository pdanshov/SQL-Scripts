USE [001]
GO

/****** Object:  Table [dbo].[tblEdPartner]    Script Date: 08/13/2014 15:49:33 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[tblEdPartner](
	[PartnerID] [dbo].[pPartnerID] NOT NULL,
	[PartnerName] [varchar](50) NOT NULL,
	[CustID] [dbo].[pCustID] NOT NULL,
	[ContactName] [varchar](50) NULL,
	[ContactPhone] [varchar](15) NULL,
	[ContactFax] [varchar](15) NULL,
	[ContactEmail] [varchar](255) NULL,
	[ContactWebSite] [varchar](255) NULL,
	[EdiVendorID] [varchar](50) NULL,
	[OptReqDunsYN] [bit] NULL,
	[OptReqDeptYN] [bit] NULL,
	[OptReqMerchandiseTypeCodeYN] [bit] NULL,
	[OptConsolInvcYN] [bit] NULL,
	[OptConsolAsnYN] [bit] NULL,
	[OptInvcStoreDirectYN] [bit] NULL,
	[OptAsnStoreDirectYN] [bit] NULL,
	[OptUCCGenMethod] [smallint] NULL,
	[DfltShipToType] [smallint] NULL,
	[DfltAsnLblTmpl] [varchar](10) NULL,
	[DfltShipperID] [varchar](50) NULL,
	[DfltItemUirType] [varchar](24) NULL,
	[DUNS] [varchar](20) NULL,
	[StartDate] [datetime] NULL,
	[ActiveYn] [bit] NULL,
	[ISAControlNum] [int] NULL,
	[GSControlNum] [int] NULL,
	[STControlNum] [int] NULL,
	[ts] [timestamp] NOT NULL,
	[OptAllowPoChangesYN] [bit] NULL,
	[optUseInvPrice] [bit] NULL,
	[OptSumAsnYN] [bit] NULL,
	[optUseUomXrefYN] [bit] NULL,
	[OptAsnRequireAllSoLines] [bit] NULL,
	[AltCustId] [varchar](20) NULL,
 CONSTRAINT [PK_tblEDPartner] PRIMARY KEY CLUSTERED 
(
	[PartnerID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY],
 CONSTRAINT [IX_tblEdPartner_CustID] UNIQUE NONCLUSTERED 
(
	[CustID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO


