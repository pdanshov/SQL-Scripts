

/***********************************************************************

	Computer Solutions International, Inc.
	EDI Install
	Insert Groups, Rule Items, Menus
	12.11.14 - 1432
	Olga Khin okhin@csi-ny.com
	Peter Danshov pdanshv@gmail.com
	
 ***********************************************************************/

USE [SYS]

INSERT INTO tblSmApp (AppId, Description, Version, BaseAppID, DefaultTable, ClientProgYn)
VALUES
/*EDI Module*/ ('ED', 'Electronic Data Interchange', 11, null, null, 'False');

-- EDI FA Group
select * from tblSmConfig
where appid='ed'
and rectype= 2048 --(groups)
declare @idg int
select @idg=(MAX(ConfigRef)+1) from dbo.tblSmConfig
insert into tblSmConfig
(ConfigRef,[RecType]
      ,[AppId]
      ,[ConfigId]
      ,[CTConfigRef]
      ,[OptConfigRef]
      ,[DispSeq]
      ,[Visible]
      ,[RoleConfigYn]
      ,[CaptionId]
      ,[SrchID]
      ,[DefaultValue]
      ,[MaxWidth]
      ,[RequiredYn]
      ,[ValueListId]
      ,[ReqAppId]
      ,[ReadOnlyYn]
      ,[MinValue]
      ,[MaxValue])
      select @idg,
      2048,
      'ED',
      'EdiGrpFa',
	  356, 0, 10, 1, 0, 'Functional Acknowledgment, 997', NULL, NULL, 0, 0, NULL, NULL, 0, NULL, NULL
select @idg

	-- EDI FA Filename under EDI FA Group
	declare @id int
	select @id=(MAX(ConfigRef)+1) from dbo.tblSmConfig
	insert into tblSmConfig
	(ConfigRef,[RecType]
		  ,[AppId]
		  ,[ConfigId]
		  ,[CTConfigRef]
		  ,[OptConfigRef]
		  ,[DispSeq]
		  ,[Visible]
		  ,[RoleConfigYn]
		  ,[CaptionId]
		  ,[SrchID]
		  ,[DefaultValue]
		  ,[MaxWidth]
		  ,[RequiredYn]
		  ,[ValueListId]
		  ,[ReqAppId]
		  ,[ReadOnlyYn]
		  ,[MinValue]
		  ,[MaxValue])
		  select @id,
		  61,
		  'ED',
		  'EdiFaFileName',
		  10023, 0, 10, 1, 0, 'FA File Name', NULL, NULL, 0, 0, NULL, NULL, 0, NULL, NULL
	select @id

-- EDI Invoice Group
select * from tblSmConfig
where appid='ed'
and rectype= 2048 --(groups)
declare @idg int
select @idg=(MAX(ConfigRef)+1) from dbo.tblSmConfig
insert into tblSmConfig
(ConfigRef,[RecType]
      ,[AppId]
      ,[ConfigId]
      ,[CTConfigRef]
      ,[OptConfigRef]
      ,[DispSeq]
      ,[Visible]
      ,[RoleConfigYn]
      ,[CaptionId]
      ,[SrchID]
      ,[DefaultValue]
      ,[MaxWidth]
      ,[RequiredYn]
      ,[ValueListId]
      ,[ReqAppId]
      ,[ReadOnlyYn]
      ,[MinValue]
      ,[MaxValue])
      select @idg,
      2048,
	  'ED',
	  'EdiGrpInvc',
	  356, 0, 60, 1, 0, 'Invoices - 810', NULL, NULL, 0, 0, NULL, NULL, 0, NULL, NULL
select @idg

	-- EDI Invoice Filename under EDI Invoice Group
	declare @id int
	select @id=(MAX(ConfigRef)+1) from dbo.tblSmConfig
	insert into tblSmConfig
	(ConfigRef,[RecType]
		  ,[AppId]
		  ,[ConfigId]
		  ,[CTConfigRef]
		  ,[OptConfigRef]
		  ,[DispSeq]
		  ,[Visible]
		  ,[RoleConfigYn]
		  ,[CaptionId]
		  ,[SrchID]
		  ,[DefaultValue]
		  ,[MaxWidth]
		  ,[RequiredYn]
		  ,[ValueListId]
		  ,[ReqAppId]
		  ,[ReadOnlyYn]
		  ,[MinValue]
		  ,[MaxValue])
		  select @id,
		  61,
		  'ED',
		  'EdiInFileName',
		  10025, 0, 0, 1, 0, 'Invoice File Name', NULL, NULL, 0, 0, NULL, NULL, 0, NULL, NULL
	select @id

-- EDI Purchase Order Group
select * from tblSmConfig
where appid='ed'
and rectype= 2048 --(groups)
declare @idg int
select @idg=(MAX(ConfigRef)+1) from dbo.tblSmConfig
insert into tblSmConfig
(ConfigRef,[RecType]
      ,[AppId]
      ,[ConfigId]
      ,[CTConfigRef]
      ,[OptConfigRef]
      ,[DispSeq]
      ,[Visible]
      ,[RoleConfigYn]
      ,[CaptionId]
      ,[SrchID]
      ,[DefaultValue]
      ,[MaxWidth]
      ,[RequiredYn]
      ,[ValueListId]
      ,[ReqAppId]
      ,[ReadOnlyYn]
      ,[MinValue]
      ,[MaxValue])
      select @idg,
      2048,
	  'ED',
	  'EdiGrpPo',
	  356, 0, 50, 1, 0, 'Purchase Orders - 850', NULL, NULL, 0, 0, NULL, NULL, 0, NULL, NULL
select @idg

	-- EDI Create Transaction under EDI Purchase Order Group
	declare @id int
	select @id=(MAX(ConfigRef)+1) from dbo.tblSmConfig
	insert into tblSmConfig
	(ConfigRef,[RecType]
		  ,[AppId]
		  ,[ConfigId]
		  ,[CTConfigRef]
		  ,[OptConfigRef]
		  ,[DispSeq]
		  ,[Visible]
		  ,[RoleConfigYn]
		  ,[CaptionId]
		  ,[SrchID]
		  ,[DefaultValue]
		  ,[MaxWidth]
		  ,[RequiredYn]
		  ,[ValueListId]
		  ,[ReqAppId]
		  ,[ReadOnlyYn]
		  ,[MinValue]
		  ,[MaxValue])
		  select @id,
		  1024,
		  'ED',
		  'EdiCreateTrans',
		  10028, 0, 75, 1, 0, 'Create Transactions', NULL, 0, 0, 0, 'lkpTrueFalse', NULL, 0, NULL, NULL
	select @id
	
	-- EDI Delete ?? POrc Y/N ?? under EDI Purchase Order Group
	declare @id int
	select @id=(MAX(ConfigRef)+1) from dbo.tblSmConfig
	insert into tblSmConfig
	(ConfigRef,[RecType]
		  ,[AppId]
		  ,[ConfigId]
		  ,[CTConfigRef]
		  ,[OptConfigRef]
		  ,[DispSeq]
		  ,[Visible]
		  ,[RoleConfigYn]
		  ,[CaptionId]
		  ,[SrchID]
		  ,[DefaultValue]
		  ,[MaxWidth]
		  ,[RequiredYn]
		  ,[ValueListId]
		  ,[ReqAppId]
		  ,[ReadOnlyYn]
		  ,[MinValue]
		  ,[MaxValue])
		  select @id,
		  1024,
		  'ED',
		  'EdiDeletePorcPOYn',
		  10028, 0, 60, 1, 0, 'Delete Processed PO', NULL, NULL, 0, 0, NULL, NULL, 0, NULL, NULL
	select @id
	
	-- EDI Force PO Price under EDI Purchase Order Group
	declare @id int
	select @id=(MAX(ConfigRef)+1) from dbo.tblSmConfig
	insert into tblSmConfig
	(ConfigRef,[RecType]
		  ,[AppId]
		  ,[ConfigId]
		  ,[CTConfigRef]
		  ,[OptConfigRef]
		  ,[DispSeq]
		  ,[Visible]
		  ,[RoleConfigYn]
		  ,[CaptionId]
		  ,[SrchID]
		  ,[DefaultValue]
		  ,[MaxWidth]
		  ,[RequiredYn]
		  ,[ValueListId]
		  ,[ReqAppId]
		  ,[ReadOnlyYn]
		  ,[MinValue]
		  ,[MaxValue])
		  select @id,
		  1024,
		  'ED',
		  'EDIForcePoPrice',
		  10028, 0, 65, 1, 0, 'Force Purchase Order Price', NULL, 0, 0, 0, 'lkpTrueFalse', NULL, 0, NULL, NULL
	select @id
	
	-- EDI PO Filename under EDI Purchase Order Group
	declare @id int
	select @id=(MAX(ConfigRef)+1) from dbo.tblSmConfig
	insert into tblSmConfig
	(ConfigRef,[RecType]
		  ,[AppId]
		  ,[ConfigId]
		  ,[CTConfigRef]
		  ,[OptConfigRef]
		  ,[DispSeq]
		  ,[Visible]
		  ,[RoleConfigYn]
		  ,[CaptionId]
		  ,[SrchID]
		  ,[DefaultValue]
		  ,[MaxWidth]
		  ,[RequiredYn]
		  ,[ValueListId]
		  ,[ReqAppId]
		  ,[ReadOnlyYn]
		  ,[MinValue]
		  ,[MaxValue])
		  select @id,
		  61,
		  'ED',
		  'EdiPoFileName',
		  10028, 0, 5, 1, 0, 'PO File Name', NULL, NULL, 0, 0, NULL, NULL, 0, NULL, NULL
	select @id

-- EDI Advanced Ship Notice Group
select * from tblSmConfig
where appid='ed'
and rectype= 2048 --(groups)
declare @idg int
select @idg=(MAX(ConfigRef)+1) from dbo.tblSmConfig
insert into tblSmConfig
(ConfigRef,[RecType]
      ,[AppId]
      ,[ConfigId]
      ,[CTConfigRef]
      ,[OptConfigRef]
      ,[DispSeq]
      ,[Visible]
      ,[RoleConfigYn]
      ,[CaptionId]
      ,[SrchID]
      ,[DefaultValue]
      ,[MaxWidth]
      ,[RequiredYn]
      ,[ValueListId]
      ,[ReqAppId]
      ,[ReadOnlyYn]
      ,[MinValue]
      ,[MaxValue])
      select @idg,
      2048,
	  'ED',
	  'EdiGrpASN',
	  356, 0, 60, 1, 0, 'Advanced Ship Notice - 856', NULL, NULL, 0, 0, NULL, NULL, 0, NULL, NULL
select @idg

	-- EDI ASN Filename under EDI ASN Group
	declare @id int
	select @id=(MAX(ConfigRef)+1) from dbo.tblSmConfig
	insert into tblSmConfig
	(ConfigRef,[RecType]
		  ,[AppId]
		  ,[ConfigId]
		  ,[CTConfigRef]
		  ,[OptConfigRef]
		  ,[DispSeq]
		  ,[Visible]
		  ,[RoleConfigYn]
		  ,[CaptionId]
		  ,[SrchID]
		  ,[DefaultValue]
		  ,[MaxWidth]
		  ,[RequiredYn]
		  ,[ValueListId]
		  ,[ReqAppId]
		  ,[ReadOnlyYn]
		  ,[MinValue]
		  ,[MaxValue])
		  select @id,
		  61,
		  'ED',
		  'EdiASNFileName',
		  10020, 0, 80, 1, 0, 'ASN File Name', NULL, NULL, 0, 0, NULL, NULL, 0, NULL, NULL
	select @id
	
	-- EDI ASN Number Sequence Filename under EDI ASN Group
	declare @id int
	select @id=(MAX(ConfigRef)+1) from dbo.tblSmConfig
	insert into tblSmConfig
	(ConfigRef,[RecType]
		  ,[AppId]
		  ,[ConfigId]
		  ,[CTConfigRef]
		  ,[OptConfigRef]
		  ,[DispSeq]
		  ,[Visible]
		  ,[RoleConfigYn]
		  ,[CaptionId]
		  ,[SrchID]
		  ,[DefaultValue]
		  ,[MaxWidth]
		  ,[RequiredYn]
		  ,[ValueListId]
		  ,[ReqAppId]
		  ,[ReadOnlyYn]
		  ,[MinValue]
		  ,[MaxValue])
		  select @id,
		  275,
		  'ED',
		  'EdiASNNumberSeq',
		  10020, 0, 70, 1, 0, 'ASN Number Sequence', NULL, 1, 0, 0, NULL, NULL, 0, NULL, NULL
	select @id

-- EDI General/Default Group
select * from tblSmConfig
where appid='ed'
and rectype= 2048 --(groups)
declare @idg int
select @idg=(MAX(ConfigRef)+1) from dbo.tblSmConfig
insert into tblSmConfig
(ConfigRef,[RecType]
      ,[AppId]
      ,[ConfigId]
      ,[CTConfigRef]
      ,[OptConfigRef]
      ,[DispSeq]
      ,[Visible]
      ,[RoleConfigYn]
      ,[CaptionId]
      ,[SrchID]
      ,[DefaultValue]
      ,[MaxWidth]
      ,[RequiredYn]
      ,[ValueListId]
      ,[ReqAppId]
      ,[ReadOnlyYn]
      ,[MinValue]
      ,[MaxValue])
      select @idg,
      2048,
	  'ED',
	  'EdiGrpGenDflt',
	  356, 0, 20, 1, 0, 'Defaults - General', NULL, NULL, 0, 0, NULL, NULL, 0, NULL, NULL
select @idg

	-- EDI Comm ID under EDI General/Default Group
	declare @id int
	select @id=(MAX(ConfigRef)+1) from dbo.tblSmConfig
	insert into tblSmConfig
	(ConfigRef,[RecType]
		  ,[AppId]
		  ,[ConfigId]
		  ,[CTConfigRef]
		  ,[OptConfigRef]
		  ,[DispSeq]
		  ,[Visible]
		  ,[RoleConfigYn]
		  ,[CaptionId]
		  ,[SrchID]
		  ,[DefaultValue]
		  ,[MaxWidth]
		  ,[RequiredYn]
		  ,[ValueListId]
		  ,[ReqAppId]
		  ,[ReadOnlyYn]
		  ,[MinValue]
		  ,[MaxValue])
		  select @id,
		  0,
		  'ED',
		  'EdiCommID',
		  10024, 0, 100, 1, 0, 'Communication ID', NULL, NULL, 15, 0, NULL, NULL, 0, NULL, NULL
	select @id
	
	-- EDI Comm Qualifier under EDI General/Default Group
	declare @id int
	select @id=(MAX(ConfigRef)+1) from dbo.tblSmConfig
	insert into tblSmConfig
	(ConfigRef,[RecType]
		  ,[AppId]
		  ,[ConfigId]
		  ,[CTConfigRef]
		  ,[OptConfigRef]
		  ,[DispSeq]
		  ,[Visible]
		  ,[RoleConfigYn]
		  ,[CaptionId]
		  ,[SrchID]
		  ,[DefaultValue]
		  ,[MaxWidth]
		  ,[RequiredYn]
		  ,[ValueListId]
		  ,[ReqAppId]
		  ,[ReadOnlyYn]
		  ,[MinValue]
		  ,[MaxValue])
		  select @id,
		  0,
		  'ED',
		  'EdiCommQual',
		  10024, 0, 90, 1, 0, 'Communication Qualifier', NULL, NULL, 2, 0, NULL, NULL, 0, NULL, NULL
	select @id
	
	-- EDI DUNS under EDI General/Default Group
	declare @id int
	select @id=(MAX(ConfigRef)+1) from dbo.tblSmConfig
	insert into tblSmConfig
	(ConfigRef,[RecType]
		  ,[AppId]
		  ,[ConfigId]
		  ,[CTConfigRef]
		  ,[OptConfigRef]
		  ,[DispSeq]
		  ,[Visible]
		  ,[RoleConfigYn]
		  ,[CaptionId]
		  ,[SrchID]
		  ,[DefaultValue]
		  ,[MaxWidth]
		  ,[RequiredYn]
		  ,[ValueListId]
		  ,[ReqAppId]
		  ,[ReadOnlyYn]
		  ,[MinValue]
		  ,[MaxValue])
		  select @id,
		  0,
		  'ED',
		  'EDIDDuns',
		  10024, 0, 60, 1, 0, 'DUNS', NULL, NULL, 0, 0, NULL, NULL, 0, NULL, NULL
	select @id
	
	-- EDI Archive Path under EDI General/Default Group
	declare @id int
	select @id=(MAX(ConfigRef)+1) from dbo.tblSmConfig
	insert into tblSmConfig
	(ConfigRef,[RecType]
		  ,[AppId]
		  ,[ConfigId]
		  ,[CTConfigRef]
		  ,[OptConfigRef]
		  ,[DispSeq]
		  ,[Visible]
		  ,[RoleConfigYn]
		  ,[CaptionId]
		  ,[SrchID]
		  ,[DefaultValue]
		  ,[MaxWidth]
		  ,[RequiredYn]
		  ,[ValueListId]
		  ,[ReqAppId]
		  ,[ReadOnlyYn]
		  ,[MinValue]
		  ,[MaxValue])
		  select @id,
		  62,
		  'ED',
		  'EdiGenArchivePath',
		  10024, 0, 90, 1, 0, 'EDI Archive Directory', NULL, NULL, 0, 0, NULL, NULL, 0, NULL, NULL
	select @id
	
	-- EDI Master PC under EDI General/Default Group
	declare @id int
	select @id=(MAX(ConfigRef)+1) from dbo.tblSmConfig
	insert into tblSmConfig
	(ConfigRef,[RecType]
		  ,[AppId]
		  ,[ConfigId]
		  ,[CTConfigRef]
		  ,[OptConfigRef]
		  ,[DispSeq]
		  ,[Visible]
		  ,[RoleConfigYn]
		  ,[CaptionId]
		  ,[SrchID]
		  ,[DefaultValue]
		  ,[MaxWidth]
		  ,[RequiredYn]
		  ,[ValueListId]
		  ,[ReqAppId]
		  ,[ReadOnlyYn]
		  ,[MinValue]
		  ,[MaxValue])
		  select @id,
		  0,
		  'ED',
		  'EdiMasterPc',
		  10024, 0, 110, 1, 0, 'EDI PC Name', NULL, NULL, 50, 0, NULL, NULL, 0, NULL, NULL
	select @id
	
	-- EDI Label Application Path under EDI General/Default Group
	declare @id int
	select @id=(MAX(ConfigRef)+1) from dbo.tblSmConfig
	insert into tblSmConfig
	(ConfigRef,[RecType]
		  ,[AppId]
		  ,[ConfigId]
		  ,[CTConfigRef]
		  ,[OptConfigRef]
		  ,[DispSeq]
		  ,[Visible]
		  ,[RoleConfigYn]
		  ,[CaptionId]
		  ,[SrchID]
		  ,[DefaultValue]
		  ,[MaxWidth]
		  ,[RequiredYn]
		  ,[ValueListId]
		  ,[ReqAppId]
		  ,[ReadOnlyYn]
		  ,[MinValue]
		  ,[MaxValue])
		  select @id,
		  61,
		  'ED',
		  'EdiLabelApplicationPath',
		  10024, 0, 50, 1, 0, 'Label Application', NULL, 0, 0, 0, NULL, NULL, 0, NULL, NULL
	select @id
	
	-- EDI UCC Prefix under EDI General/Default Group
	declare @id int
	select @id=(MAX(ConfigRef)+1) from dbo.tblSmConfig
	insert into tblSmConfig
	(ConfigRef,[RecType]
		  ,[AppId]
		  ,[ConfigId]
		  ,[CTConfigRef]
		  ,[OptConfigRef]
		  ,[DispSeq]
		  ,[Visible]
		  ,[RoleConfigYn]
		  ,[CaptionId]
		  ,[SrchID]
		  ,[DefaultValue]
		  ,[MaxWidth]
		  ,[RequiredYn]
		  ,[ValueListId]
		  ,[ReqAppId]
		  ,[ReadOnlyYn]
		  ,[MinValue]
		  ,[MaxValue])
		  select @id,
		  0,
		  'ED',
		  'EdiUCCPrefix',
		  10024, 0, 30, 1, 0, 'UCC Company Prefix', NULL, 1, 8, 0, NULL, NULL, 0, NULL, NULL
	select @id
	
	-- EDI UCC 128 Sequence under EDI General/Default Group
	declare @id int
	select @id=(MAX(ConfigRef)+1) from dbo.tblSmConfig
	insert into tblSmConfig
	(ConfigRef,[RecType]
		  ,[AppId]
		  ,[ConfigId]
		  ,[CTConfigRef]
		  ,[OptConfigRef]
		  ,[DispSeq]
		  ,[Visible]
		  ,[RoleConfigYn]
		  ,[CaptionId]
		  ,[SrchID]
		  ,[DefaultValue]
		  ,[MaxWidth]
		  ,[RequiredYn]
		  ,[ValueListId]
		  ,[ReqAppId]
		  ,[ReadOnlyYn]
		  ,[MinValue]
		  ,[MaxValue])
		  select @id,
		  275,
		  'ED',
		  'EdiUCC128Seq',
		  10024, 0, 60, 1, 0, 'UCC128 Sequence', NULL, 1, 0, 0, NULL, NULL, 0, NULL, NULL
	select @id






/**********************************************************************
 *
 *
	-- Menus
                                                                      *
																	  *
 **********************************************************************/
 
INSERT INTO tblSmMenuDescr (MenuId, LangID, Descr, ts)
VALUES
/*EDI Menu Item*/ (769, 'eng', 'EDI', default); /*'0x0000000000046D79'*/
INSERT INTO [SYS].[dbo].[tblSmMenu] (AppID, MenuId, MenuType, ParentId, [Order], ReferenceId, ObjectType, Object, Param, HideYn, Author, PluginName, AssemblyName, ts)
VALUES
/*PO Detail Journal*/ ('ED', 7690203, 0, 76902, 20, NULL, 11, NULL, NULL, 0, NULL, 'C:\Program Files\Open Systems, Inc\TRAVERSE-EDIDEMO\Document\PODetailJournal.xls', NULL, default),
/*PO Validate*/ ('ED', 7690204, 0, 76902, 30, NULL, 11, NULL, NULL, 0, NULL, 'C:\Program Files\Open Systems, Inc\TRAVERSE-EDIDEMO\Document\POValidate.xlsx', NULL, default),
/*PO Validate All*/ ('ED', 7690205, 0, 76902, 60, NULL, 11, NULL, NULL, 0, NULL, 'C:\Program Files\Open Systems, Inc\TRAVERSE-EDIDEMO\Document\POValidateAll.xls', NULL, default),
/*EDI SO Generate*/ ('ED', 7690206, 0, 76902, 80, NULL, 11, NULL, NULL, 0, NULL, 'C:\Program Files\Open Systems, Inc\TRAVERSE-EDIDEMO\Document\EDISOGenerate.xlsx', NULL, default), 
/*EDI Invoice*/ ('ED', 7690301, 0, 76903, 10, NULL, 11, NULL, NULL, 0, NULL, 'C:\Program Files\Open Systems, Inc\TRAVERSE-EDIDEMO\Document\EDI Invoice.xls', NULL, default),
/*ASN Journal*/ ('ED', 7690401, 0, 76904, 10, NULL, 11, NULL, NULL, 0, NULL, 'C:\Program Files\Open Systems, Inc\TRAVERSE-EDIDEMO\Document\ASNJournal.xls', NULL, default),
/*Partner Item Xref*/ ('ED', 7690501, 0, 76905, 10, NULL, 2, NULL, NULL, 0, NULL, 'PartnerItemXrefPlugin', 'CSI.EDI.Client.PartnerItemXref.dll', default),
/*FA Interactive View*/ ('ED', 7690601, 0, 76906, 10, NULL, 2, NULL, NULL, 0, NULL, 'CustomViewPlugin', 'CSI.ED.Client.FaInteractiveView.dll', default),
/*FA Journal*/ ('ED', 7690603, 0, 76906, 500, NULL, 11, NULL, NULL, 0, NULL, 'C:\Program Files\Open Systems, Inc\TRAVERSE-EDIDEMO\Document\FAJournal.xlsx', NULL, default),
/*PO Ack Log*/ ('ED', 7690702, 0, 76907, 20, NULL, 11, NULL, NULL, 0, NULL, 'C:\Program Files\Open Systems, Inc\TRAVERSE-EDIDEMO\Document\POAckLog.xls', NULL, default),
/*PO Change*/ ('ED', 7690802, 0, 76908, 20, NULL, 11, NULL, NULL, 0, NULL, 'C:\Program Files\Open Systems, Inc\TRAVERSE-EDIDEMO\Document\POChange.xls', NULL, default),
/*Inventory Inquiry*/ ('ED', 7690901, 0, 76909, 10, NULL, 11, NULL, NULL, 0, NULL, 'C:\Program Files\Open Systems, Inc\TRAVERSE-EDIDEMO\Document\InventoryInquiry.xls', NULL, default),
/*Text Message*/ ('ED', 7691002, 0, 76910, 20, NULL, 11, NULL, NULL, 0, NULL, 'C:\Program Files\Open Systems, Inc\TRAVERSE-EDIDEMO\Document\TextMessage.xls', NULL, default),
/*App Advice*/ ('ED', 7691102, 0, 76911, 20, NULL, 11, NULL, NULL, 0, NULL, 'C:\Program Files\Open Systems, Inc\TRAVERSE-EDIDEMO\Document\AppAdvice.xls', NULL, default),
/*PO Change Ack Log*/ ('ED', 7691202, 0, 76912, 20, NULL, 11, NULL, NULL, 0, NULL, 'C:\Program Files\Open Systems, Inc\TRAVERSE-EDIDEMO\Document\POChangeAckLog.xls', NULL, default);



