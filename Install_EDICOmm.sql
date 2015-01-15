


-----------------------------------------------------------------------------
--
--								Peter Danshov
--					pdanshv@gmail.com		01.14.2015
--		This script installs EDIComm tables, data, stored procedures
--
--
-----------------------------------------------------------------------------

SET @company = '123'; -- Set the company database here < < <- <- <-- <-- <--- <---
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
 
IF @company != '123'
BEGIN
	PRINT N'';
	PRINT N'';
	PRINT N'********************************************************************************************';
	PRINT N'			Company is set to   '''+@company+'''   . Running Installation... ';
	PRINT N'********************************************************************************************';
	PRINT N'';
	
	-- Create Table
	USE [SYS]
	GO
	/****** Object:  Table [dbo].[tblSysGenReports]    Script Date: 01/14/2015 12:12:17 ******/
	SET ANSI_NULLS ON
	GO
	SET QUOTED_IDENTIFIER ON
	GO
	SET ANSI_PADDING ON
	GO
	CREATE TABLE [dbo].[tblSysGenReports](
	, [RptGroup] [varchar](20) NOT NULL,
	, [RptCode] [varchar](20) NOT NULL,
	, [RptDescr] [varchar](50) NULL,
	, [RptSQLSource] [varchar](500) NULL,
	, [RptSQLParam] [varchar](500) NULL,
	, [RptDesFilePath] [varchar](255) NULL,
	, [RptDesFileOverwriteOptions] [smallint] NULL,
	, [CapCompanyName] [varchar](50) NULL,
	, [CapSheetName] [varchar](35) NULL,
	, [CapSelection] [varchar](500) NULL,
	, [CapRptName] [varchar](50) NULL,
	, [OptSplitSheetYN] [bit] NULL,
	, [OptFreezeCol] [smallint] NULL,
	, [OptFreezeRow] [smallint] NULL,
	, [OptVisibleYN] [bit] NULL,
	, [OptShowStatusYN] [bit] NULL,
	, [SecReportDetail] [varchar](500) NULL,
	, [SecGroupBy1Header] [varchar](255) NULL,
	, [SecGroupBy1] [varchar](255) NULL,
	, [SecGroupBy1Footer] [varchar](255) NULL,
	, [SecGroupBy2Header] [varchar](255) NULL,
	, [SecGroupBy2] [varchar](255) NULL,
	, [SecGroupBy2Footer] [varchar](255) NULL,
	, [SecGroupBy3Header] [varchar](255) NULL,
	, [SecGroupBy3] [varchar](255) NULL,
	, [SecGroupBy3Footer] [varchar](255) NULL,
	, [SecGroupBy4Header] [varchar](255) NULL,
	, [SecGroupBy4] [varchar](255) NULL,
	, [SecGroupBy4Footer] [varchar](255) NULL,
	, [SecGroupBy5Header] [varchar](255) NULL,
	, [SecGroupBy5] [varchar](255) NULL,
	, [SecGroupBy5Footer] [varchar](255) NULL,
	, [SecGrandTotalFooter] [varchar](255) NULL,
	, [FmtRptFormat] [smallint] NULL,
	, [FmtColorSchema] [smallint] NULL,
	, [FmtCaptions] [varchar](500) NULL,
	, [FmtGreenbarYN] [bit] NULL,
	, [FmtFontSize] [decimal](6, 2) NULL,
	, [PageLandscapeYN] [bit] NULL,
	, [PageRMargin] [decimal](6, 4) NULL,
	, [PageLMargin] [decimal](6, 4) NULL,
	, [PageTMargin] [decimal](6, 4) NULL,
	, [PageBMargin] [decimal](6, 4) NULL,
	, [PageZoom] [smallint] NULL,
	, [PageFitToPagesWide] [smallint] NULL,
	, [ArchiveDirPaths] [varchar](1000) NULL,
	, [CommandLineGroup] [varchar](20) NULL,
	, [CommandLineParam] [varchar](20) NULL,
	 CONSTRAINT [PK_tblSysGenReports_1] PRIMARY KEY CLUSTERED 
	(
	, [RptGroup] ASC,
	, [RptCode] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
	) ON [PRIMARY]
	GO
	SET ANSI_PADDING OFF
	GO



	
	
	-- Load Data
	INSERT INTO [SYS].dbo.tblSysGenReports ( RptGroup, RptCode, RptDescr, RptSQLSource, RptSQLParam, RptDesFilePath, RptDesFileOverwriteOptions, CapCompanyName, CapSheetName, CapSelection, CapRptName, OptSplitSheetYN, OptFreezeCol, OptFreezeRow, OptVisibleYN, OptShowStatusYN, SecReportDetail, SecGroupBy1Header, SecGroupBy1, SecGroupBy1Footer, SecGroupBy2Header, SecGroupBy2, SecGroupBy2Footer, SecGroupBy3Header, SecGroupBy3, SecGroupBy3Footer, SecGroupBy4Header, SecGroupBy4, SecGroupBy4Footer, SecGroupBy5Header, SecGroupBy5, SecGroupBy5Footer, SecGrandTotalFooter, FmtRptFormat, FmtColorSchema, FmtCaptions, FmtGreenbarYN, FmtFontSize, PageLandscapeYN, PageRMargin, PageLMargin, PageTMargin, PageBMargin, PageZoom, PageFitToPagesWide, ArchiveDirPaths, CommandLineGroup, CommandLineParam )
	VALUES
	( 'EDI', 'FA_JRNL', 'EDI FA Import Journal', 'dbo.csi_EdFaImportLog_proc', '@ImportBatchId=''[PostRun]''', NULL, NULL, NULL, NULL, NULL, 'EDI FA Import Journal', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Import Batch Id|Document|Partner Id|Name|Sender Mail Id|ISA Seq|GS Seq|ST Seq|Send Date|Send Time|Status', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '997', 'RPTIML' ),
	( 'EDI', 'PO_DTL_JRNL', 'EDI PO Detail Journal', 'dbo.csi_EdPoImportDtlLog_proc', '@ImportBatchId=''[PostRun]''', '@PartnerId=''', NULL, NULL, NULL, NULL, NULL, 'EDI PO Detail Journal', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Post Run|Partner ID|Partner Name|Cust Po Num|Type Code|Department ID|Item Id|PO Line Num|Store Name|Po Date|Start Ship Date|Cancel Ship Date|Ship Not Before Date|Store Num|Upc|Qty Ord|Units Sell|$#,##0.00:Unit Price|$#,##0.00:Ext Price|Color Descr|Size Descr|Item Decr|$#,##0.00:Retail Price|$#,##0.00:Ext Retail Price|Req Acknl YN|Po Status|Po Status Desc|Item Buyer Code|Item Vendor Code|Ship to Code|Ship No Later Than Date|Message', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '850', 'RPTIML' ),
	( 'EDI', 'PO_VAL_LOG', 'EDI Po Validation Log', 'dbo.csi_EdPoValidate_log_proc', '@ImportBatchId=''[PostRun]''', NULL, NULL, NULL, NULL, NULL, EDI Po Validation Log, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Post Run|Status|Partner ID|Partner Name|Cust Po Num|Error Code|Descr|Line Number|H/D', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '850', 'RPTVAL' );



	
	
	
	-- Create Stored Procedures
	-- [Company Name].dbo.csi_EdFaImportLog_proc
	EXEC('
	USE ['+@company+']
	GO
	/****** Object:  StoredProcedure [dbo].[csi_EdFaImportLog_proc]    Script Date: 01/14/2015 12:53:18 ******/
	SET ANSI_NULLS ON
	GO
	SET QUOTED_IDENTIFIER ON
	GO
	CREATE PROC [dbo].[csi_EdFaImportLog_proc]  
	  @ImportBatchId varchar(14)
	  
	--rptEdFaImportLog '''',1
	AS
	SET NOCOUNT ON
	BEGIN TRY
	   SELECT h.ImportBatchId,d.DocDesc,
	   CASE WHEN ISNULL(p.partnerId,'''')='''' THEN ''[Missing]'' ELSE p.partnerId  END PartnerId ,
	   CASE WHEN ISNULL(p.PartnerName,'''')='''' THEN ''[Missing]'' ELSE p.PartnerName END PartnerName,
	   m.SenderId, 
	   m.ISAControlNum,m.GSControlNum,m.STControlNum,cast (SendDate as datetime) SendDate,
	   cast(SendTime as datetime) SendTime,
	   CASE ISNULL(h.GSAckCode,'''')   
	   WHEN ''E'' THEN ''Error''  
	   WHEN ''R'' THEN ''Rejected''  
	   WHEN ''A'' THEN ''Accepted''  
	   WHEN ''''  THEN ''Unacknowledged''  
	   END FAReturnCode  

	   FROM dbo.tblEdFaHeader h
	   LEFT JOIN dbo.tblEdMailControl m ON h.ImportBatchId=m.ImportBatchId AND h.KeySenderId=m.SenderId AND h.KeyISAControlNum= m.ISAControlNum AND h.KeyGSControlNum=m.GSControlNum AND ISNULL(h.KeySTControlNum,'''')=ISNULL(m.STControlNum,'''')
	   LEFT JOIN dbo.tblEdDocument d ON h.DocType=d.DocType  
	   LEFT JOIN dbo.tblEdPartnerDoc pd ON d.DocId=pd.DocID AND m.SenderID=pd.MailId  
	   LEFT JOIN dbo.tblEdPartner p ON pd.PartnerId=p.PartnerId  
	   WHERE  m.ImportBatchId = @ImportBatchId
	END TRY
	BEGIN CATCH
		EXEC dbo.csi_RaiseError_proc
	END CATCH
	GO');

	
	
	
	
	-- [Company Name].dbo.csi_EdPoImportDtlLog_proc
	EXEC('
	USE ['+@company+']
	GO
	/****** Object:  StoredProcedure [dbo].[csi_EdPoImportDtlLog_proc]    Script Date: 01/14/2015 13:02:22 ******/
	SET ANSI_NULLS ON
	GO
	SET QUOTED_IDENTIFIER ON
	GO
	CREATE Proc [dbo].[csi_EdPoImportDtlLog_proc]    @ImportBatchID varchar(14) ='''',     
													 @PartnerId varchar(20)=''''    
		AS      
		   SET NOCOUNT ON      
		   -- EXEC  csi_EdPoImportDtlLog_proc
		   SELECT h.ImportBatchId, h.PartnerID, p.PartnerName, h.CustPoNum, h.TypeCode, h.DepartmentID,
				  d.ItemId ,d.polinenum,'''' ShipToName, 
				  CASE WHEN  ISDATE(h.PoDate) = 0 THEN NULL ELSE CASE LTRIM(RTRIM(h.PoDate))  WHEN '''' THEN NULL ELSE CAST(h.PoDate AS DATETIME)  END END PoDate,                 
				  CASE WHEN  ISDATE(h.StartShipDate) = 0 THEN NULL ELSE CASE LTRIM(RTRIM(h.StartShipDate)) WHEN '''' THEN NULL ELSE CAST (StartShipDate AS DATETIME) END END StartShipDate,                
				  CASE WHEN  ISDATE(h.CancelShipDate) = 0 THEN NULL ELSE CASE LTRIM(RTRIM(h.cancelShipDate)) WHEN '''' THEN NULL ELSE CAST(CancelShipDate AS DATETIME) END END CancelShipDate, 
				  CASE WHEN  ISDATE(h.UDF5) = 0 THEN NULL ELSE CASE LTRIM(RTRIM(h.UDF5))  WHEN '''' THEN NULL  ELSE cast(h.UDF5 AS DATEtime) end end ShipNotBeforDate, 
				  d.StoreNum, d.ItemUpc,                
				  cast(isNULL(d.QtyOrd,0) as float) QtyOrd, d.UnitsSell,                 
				  cast (isNULL(d.UnitPrice,0) as float) UnitPrice,                 
				  (cast(isNULL(d.UnitPrice,0) as float) * cast(isNULL(d.QtyOrd,0) as float)) ExtPrice,                
				  d.ColorDescr, d.SizeDescr, d.ItemDecr,                
				  cast (isNULL(d.RetailPrice,0)  as float) RetailPrice,                
				  (cast(isNULL(d.retailPrice,0) as float) * cast(isNULL(d.QtyOrd,0) as float))  ExtRetailPrice,                
				  h.ReqAcknlYN, h.PoStatus , S.Descr as PoStatusDesc,
				  d.ItemBuyerCode , d.ItemVendorCode,    
				  ISNULL(d.UDF4,'''') ShipToCode,
				  CASE WHEN  ISDATE(d.UDF5) = 0 THEN NULL ELSE case LTRIM(rtrim(d.UDF5)) WHEN '''' THEN NULL ELSE cast(d.UDF5 AS DATEtime) END END ShipNoLaterDate
		  FROM dbo.tblEdPoHeader h                  
		  LEFT JOIN dbo.tblEdPoDetail d ON h.ImportBatchId = d.ImportBatchId AND h.KeyLevelSeq1=d.KeyLevelSeq1                
		  LEFT JOIN dbo.tblEdPartner p on h.PartnerID = p.PartnerID              
		  LEFT JOIN dbo.tblEdPoStatus S on h.PoStatus = S.PoStatus           
		  WHERE ( @ImportBatchID='''' OR @ImportBatchID=h.ImportBatchId ) AND (@PartnerId='''' OR @PartnerId=h.PartnerID)    
	GO');



	
	
	-- [Company Name].dbo.csi_EdPoValidate_log_proc
	EXEC('
	USE ['+@company+']
	GO
	/****** Object:  StoredProcedure [dbo].[csi_EdPoValidate_log_proc]    Script Date: 01/14/2015 13:08:12 ******/
	SET ANSI_NULLS ON
	GO
	SET QUOTED_IDENTIFIER ON
	GO
	CREATE  PROC [dbo].[csi_EdPoValidate_log_proc]
	@ImportBatchId pPostRun  =''''   
	AS      
	SELECT ImportBatchId,''WARNING'' errStatus ,l.PartnerId,p.PartnerName,l.CustPoNum,ErrCode,ErrDescr,LineNum,ErrRecType     
	FROM dbo.tblEdPoErrorlog l      
	LEFT JOIN dbo.tblEdPartner p on l.PartnerID = p.PartnerID    
	WHERE errStatus=1  AND (l.ImportBatchId =@ImportBatchId OR ISNULL (@ImportBatchId,'''')='''')       
	UNION          
	SELECT ImportBatchId,''FAILED VALIDATION'',l.PartnerId,p.PartnerName,CustPoNum,ErrCode,ErrDescr, LineNum,ErrRecType 
	FROM dbo.tblEdPoErrorlog  l    
	LEFT JOIN dbo.tblEdPartner p on l.PartnerID = p.PartnerID    
	WHERE errStatus<>1   AND (l.ImportBatchId =@ImportBatchId  OR ISNULL (@ImportBatchId,'''')='''')           
	UNION        
	SELECT DISTINCT  h.ImportBatchId,''PASSED VALIDATION'',h.PartnerId,p.PartnerName,h.CustPoNum,NULL,NULL, NULL,NULL  
	FROM dbo.tblEdPoHeader h         
	LEFT JOIN (SELECT ImportBatchId,PartnerId,CustpoNum FROM dbo.tblEdPoErrorlog WHERE errStatus>1) e ON h.ImportBatchId=e.ImportBatchId AND h.PartnerId=e.PartnerId AND h.CustPoNum=e.CustPoNum         
	LEFT JOIN dbo.tblEdPartner p on h.PartnerID = p.PartnerID    
	WHERE (h.ImportBatchId =@ImportBatchId OR ISNULL (@ImportBatchId,'''')='''')     AND e.PartnerId IS NULL      
	ORDER BY 1 Desc,l.PartnerId,l.CustPoNum, ErrRecType DESC, LineNum 
	GO');

	
	
	PRINT N'';
	PRINT N'';
	PRINT N'***************************************************************************************';
	PRINT N'							Done Installing. ';
	PRINT N'***************************************************************************************';
	PRINT N'';
END
ELSE
BEGIN
	PRINT N'';
	PRINT N'';
	PRINT N'******************************************************************************************************************************';
	PRINT N'			Company is set to   '''+@company+'''   .';
	PRINT N'			Please set the @company variable to the Unique Traverse Company Database Name and Re-Run this script.';
	PRINT N'******************************************************************************************************************************';
	PRINT N'';
END
















































