
DECLARE @company varchar(30); /* Also allowed: DECLARE @find varchar(30) = 'EDI'; */
/*******************************************************************
 ********************* Peter Danshov - Setup EDI Base **************
 *******************************************************************
 *
 *		pdanshv@gmail.com 12.09.14
 *
 *		sys smconfig 		   = groups and sub-group menu items
 *		sys smconfigvalue 	   = new record with configref equal to smconfig
 *		sys dbo.tblSmMenuDescr = main menu items
 *		sys dbo.tblSmMenu	   = sub-menu items
 *
 *		*company* dbo.tblSmCustomField			= List of custom fields found
 *												in "Manage" section of Design Studio
 *		*company* dbo.tblSmCustomFieldEntity	= Table connections for fields found
 *												in "Assign" section of Design Studio
 *
 *
 *		All smconfig menu items must have captions:
 *			Trav10.5: sys dbo.tbl.syscaption [ObjectID] = sys dbo.tblsmconfig [CaptionId]
 *
 *		Traverse Company Setup:
 *			System Manager -> Company Setup -> Business Rules -> Application -> EDI
 *
 *******************************************************************/

----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
SET @company = '123'; -- Set the company database here < < <- <- <-- <-- <--- <---
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
	
	 -- EDI Module Install
	INSERT INTO [SYS].[dbo].[tblSmApp] (AppId, Description, Version, BaseAppID, DefaultTable, ClientProgYn)
	VALUES
	/*EDI Module*/ ('ED', 'Electronic Data Interchange', 11, null, null, 'False');
	EXEC('INSERT INTO ['+@company+'].[dbo].[tblSmApp_Installed] (AppID, Notes)
	VALUES
	(''ED'',null);');
	
	 -- Business Rules
	INSERT INTO [SYS].[dbo].tblSmConfig (ConfigRef, RecType, AppId, ConfigId, CTConfigRef, OptConfigRef, DispSeq, Visible,
	RoleConfigYn, CaptionId, SrchID, DefaultValue, MaxWidth, RequiredYn, ValueListId, ReqAppId, ReadOnlyYn, MinValue, MaxValue)
	VALUES
	/*EdiGrpFa*/ ( 10023, 2048, 'ED', 'EdiGrpFa', 356, 0, 10, 1, 0, 'Functional Acknowledgment, 997', NULL, NULL, 0, 0, NULL, NULL, 0, NULL, NULL ),
		/*EdiFaFileName*/ ( 10017, 61, 'ED', 'EdiFaFileName', 10023, 0, 10, 1, 0, 'FA File Name', NULL, NULL, 0, 0, NULL, NULL, 0, NULL, NULL ),
	/*EdiGrpInvc*/ ( 10025, 2048, 'ED', 'EdiGrpInvc', 356, 0, 60, 1, 0, 'Invoices - 810', NULL, NULL, 0, 0, NULL, NULL, 0, NULL, NULL ),
		/*EdiInFileName*/ ( 10033, 61, 'ED', 'EdiInFileName', 10025, 0, 0, 1, 0, 'Invoice File Name', NULL, NULL, 0, 0, NULL, NULL, 0, NULL, NULL ),
	/*EdiGrpPo*/ ( 10028, 2048, 'ED', 'EdiGrpPo', 356, 0, 50, 1, 0, 'Purchase Orders - 850', NULL, NULL, 0, 0, NULL, NULL, 0, NULL, NULL ),
		/*EdiCreateTrans*/ ( 10010, 1024, 'ED', 'EdiCreateTrans', 10028, 0, 75, 1, 0, 'Create Transactions', NULL, 0, 0, 0, 'lkpTrueFalse', NULL, 0, NULL, NULL ),
		/*EdiDeletePorcPOYn*/ ( 10014, 1024, 'ED', 'EdiDeletePorcPOYn', 10028, 0, 60, 1, 0, 'Delete Processed PO', NULL, NULL, 0, 0, NULL, NULL, 0, NULL, NULL ),
		/*EDIForcePoPrice*/ ( 10018, 1024, 'ED', 'EDIForcePoPrice', 10028, 0, 65, 1, 0, 'Force Purchase Order Price', NULL, 0, 0, 0, 'lkpTrueFalse', NULL, 0, NULL, NULL ),
		/*EdiPoFileName*/ ( 10040, 61, 'ED', 'EdiPoFileName', 10028, 0, 5, 1, 0, 'PO File Name', NULL, NULL, 0, 0, NULL, NULL, 0, NULL, NULL ),
	/*EdiGrpASN*/ ( 10020, 2048, 'ED', 'EdiGrpASN', 356, 0, 60, 1, 0, 'Advanced Ship Notice - 856', NULL, NULL, 0, 0, NULL, NULL, 0, NULL, NULL ),
		/*EdiASNFileName*/ ( 10003, 61, 'ED', 'EdiASNFileName', 10020, 0, 80, 1, 0, 'ASN File Name', NULL, NULL, 0, 0, NULL, NULL, 0, NULL, NULL ),
		/*EdiASNNumberSeq*/ ( 10004, 275, 'ED', 'EdiASNNumberSeq', 10020, 0, 70, 1, 0, 'ASN Number Sequence', NULL, 1, 0, 0, NULL, NULL, 0, NULL, NULL ),
	/*EdiGrpGenDflt*/ ( 10024, 2048, 'ED', 'EdiGrpGenDflt', 356, 0, 20, 1, 0, 'Defaults - General', NULL, NULL, 0, 0, NULL, NULL, 0, NULL, NULL ),
		/*EdiCommID*/ ( 10008, 0, 'ED', 'EdiCommID', 10024, 0, 100, 1, 0, 'Communication ID', NULL, NULL, 15, 0, NULL, NULL, 0, NULL, NULL ),
		/*EdiCommQual*/ ( 10009, 0, 'ED', 'EdiCommQual', 10024, 0, 90, 1, 0, 'Communication Qualifier', NULL, NULL, 2, 0, NULL, NULL, 0, NULL, NULL ),
		/*EDIDfltDuns*/ --( 10015, 0, 'ED', 'EDIDfltDuns', 10024, 0, 60, 1, 0, 'Default DUNS', NULL, NULL, 0, 0, NULL, NULL, 0, NULL, NULL ),
		/*EDIDDuns*/ ( 10015, 0, 'ED', 'EDIDDuns', 10024, 0, 60, 1, 0, 'DUNS', NULL, NULL, 0, 0, NULL, NULL, 0, NULL, NULL ),
		/*EdiGenArchivePath*/ ( 10019, 62, 'ED', 'EdiGenArchivePath', 10024, 0, 90, 1, 0, 'EDI Archive Directory', NULL, NULL, 0, 0, NULL, NULL, 0, NULL, NULL ),
		/*EdiMasterPc*/ ( 10037, 0, 'ED', 'EdiMasterPc', 10024, 0, 110, 1, 0, 'EDI PC Name', NULL, NULL, 50, 0, NULL, NULL, 0, NULL, NULL ),
		/*EdiLabelApplicationPath*/ --( 10036, 61, 'ED', 'EdiLabelApplicationPath', 10024, 0, 50, 1, 0, 'Label Application File Name', NULL, 'C:\Program Files\Seagull\BarTender 7.10\Professional\bartend.exe', 0, 0, NULL, NULL, 0, NULL, NULL ),
		/*EdiLabelApplicationPath*/ ( 10036, 61, 'ED', 'EdiLabelApplicationPath', 10024, 0, 50, 1, 0, 'Label Application', NULL, 0, 0, 0, NULL, NULL, 0, NULL, NULL ),
		/*EdiUCCPrefix*/ ( 10046, 0, 'ED', 'EdiUCCPrefix', 10024, 0, 30, 1, 0, 'UCC Company Prefix', NULL, 1, 8, 0, NULL, NULL, 0, NULL, NULL ),
		/*EdiUCC128Seq*/ ( 10045, 275, 'ED', 'EdiUCC128Seq', 10024, 0, 60, 1, 0, 'UCC128 Sequence', NULL, 1, 0, 0, NULL, NULL, 0, NULL, NULL ),
		('ED',	7690101,	0,	76901,	10,	NULL,	6,	NULL,	NULL,	0,	NULL,	NULL,	NULL,	default),
		('ED',	7690102,	0,	76901,	80,	NULL,	6,	NULL,	NULL,	0,	NULL,	NULL,	NULL,	default),
		('ED',	7690201,	0,	76902,	10,	NULL,	6,	NULL,	NULL,	0,	NULL,	NULL,	NULL,	default),
		('ED',	7690202,	0,	76902,	70,	NULL,	6,	NULL,	NULL,	0,	NULL,	NULL,	NULL,	default),
		('ED',	7691301,	0,	76913,	10,	NULL,	6,	NULL,	NULL,	0,	NULL,	NULL,	NULL, default),
		('ED',	7691302,	0,	76913,	40, NULL,	6,	NULL,	NULL,	0,	NULL,	NULL,	NULL,	default),
		('ED',	769,		0,	0,		55,	NULL,	8,	NULL,	NULL,	0,	NULL,	NULL,	NULL, default),
		('ED',	76901,	0,	769,		10,	NULL,	8,	NULL,	NULL,	0,	NULL,	NULL,	NULL,	default),
		('ED',	76902,	0,	769,		20,	NULL,	8,	NULL,	NULL,	0,	NULL,	NULL,	NULL,	default),
		('ED',	76903,	0,	769,		50,	NULL,	8,	NULL,	NULL,	0,	NULL,	NULL,	NULL,	default),
		('ED',	76904,	0,	769,		60,	NULL,	8,	NULL,	NULL,	0,	NULL,	NULL,	NULL,	default),
		('ED',	76905,	0,	769,		70,	NULL,	8,	NULL,	NULL,	0,	NULL,	NULL,	NULL,	default),
		('ED',	76906,	0,	769,		80,	NULL,	8,	NULL,	NULL,	0,	NULL,	NULL,	NULL,	default),
		('ED',	76907,	0,	769,		22,	NULL,	8,	NULL,	NULL,	0,	NULL,	NULL,	NULL,	default),
		('ED',	76908,	0,	769,		24,	NULL,	8,	NULL,	NULL,	0,	NULL,	NULL,	NULL,	default),
		('ED',	76909,	0,	769,		62,	NULL,	8,	NULL,	NULL,	0,	NULL,	NULL,	NULL,	default),
		('ED',	76910,	0,	769,		26,	NULL,	8,	NULL,	NULL,	0,	NULL,	NULL,	NULL,	default),
		('ED',	76911,	0,	769,		27,	NULL,	8,	NULL,	NULL,	0,	NULL,	NULL,	NULL,	default),
		('ED',	76912,	0,	769,		25,	NULL,	8,	NULL,	NULL,	0,	NULL,	NULL,	NULL,	default),
		('ED',	76913,	0,	769,		40,	NULL,	8,	NULL,	NULL,	0,	NULL,	NULL,	NULL,	default),
		('ED',	7690302,	0,	76903,	20,	NULL,	6,	NULL,	NULL,	0,	NULL,	NULL,	NULL,	default),
		('ED',	7690402,	0,	76904,	20,	NULL,	6,	NULL,	NULL,	0,	NULL,	NULL,	NULL,	default),
		('ED',	7690602,	0,	76906,	5,	NULL,	6,	NULL,	NULL,	0,	NULL,	NULL,	NULL,	default),
		('ED',	7690701,	0,	76907,	30,	NULL,	6,	NULL,	NULL,	0,	NULL,	NULL,	NULL,	default),
		('ED',	7690801,	0,	76908,	10,	NULL,	6,	NULL,	NULL,	0,	NULL,	NULL,	NULL,	default),
		('ED',	7690902,	0,	76909,	20,	NULL,	6,	NULL,	NULL,	0,	NULL,	NULL,	NULL,	default),
		('ED',	7691001,	0,	76910,	10,	NULL,	6,	NULL,	NULL,	0,	NULL,	NULL,	NULL,	default),
		('ED',	7691101,	0,	76911,	10,	NULL,	6,	NULL,	NULL,	0,	NULL,	NULL,	NULL,	default),
		('ED',	7691201,	0,	76912,	30,	NULL,	6,	NULL,	NULL,	0,	NULL,	NULL,	NULL,	default);
	
	 -- Menu
	INSERT INTO [SYS].[dbo].[tblSmMenuDescr] (MenuId, LangID, Descr, ts)
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
	
	 -- Custom Fields
	EXEC('SET IDENTITY_INSERT ['+@company+'].dbo.tblSmCustomField ON;
	INSERT INTO ['+@company+'].dbo.tblSmCustomField (Id, FieldName, Definition)
	VALUES
	(1, ''EDIPOPostRun'', ''<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>Text</FieldType><Description>Populated by EDI SO Generation; Manual Entry Also</Description><Required>false</Required><MaxLength>20</MaxLength><LimitToList>false</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /></CustomField>''),
	(2, ''EDIDeptID'', ''<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>Text</FieldType><Description>Populated by EDI SO Generation; Manual Entry Also</Description><Required>false</Required><MaxLength>24</MaxLength><LimitToList>false</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /></CustomField>''),
	(3, ''EDICancelDate'', ''<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>Date</FieldType><Description>Populated by EDI SO Generation; Manual Entry Also</Description><Required>false</Required><MaxLength>0</MaxLength><LimitToList>false</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /></CustomField>''),
	(4, ''EDIASNYN'', ''<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>YesNo</FieldType><Description>Populated by EDI SO Generation; Manual Entry Also</Description><Required>false</Required><MaxLength>0</MaxLength><LimitToList>false</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /></CustomField>''),
	(5, ''EDIInvoiceYN'', ''<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>YesNo</FieldType><Description>Populated by EDI SO Generation; Manual Entry Also</Description><Required>false</Required><MaxLength>0</MaxLength><LimitToList>false</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /></CustomField>''),
	(6, ''EDIDUNS'', ''<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>Text</FieldType><Description>Populated by EDI SO Generation; Manual Entry Also</Description><Required>false</Required><MaxLength>24</MaxLength><LimitToList>false</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /></CustomField>''),
	(7, ''EDIInvcNum'', ''<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>Text</FieldType><Description>EDI Invoice #: only different from standard invoice # for consolidated</Description><Required>false</Required><MaxLength>24</MaxLength><LimitToList>false</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /></CustomField>''),
	(8, ''EDIShipViaCode'', ''<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>Entity</FieldType><Description>Ship Via Code Saved</Description><Required>false</Required><MaxLength>24</MaxLength><LimitToList>false</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /><LookupId>CsiShipVia</LookupId></CustomField>''),
	(9, ''EDIShipToAbbrev'', ''<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>Text</FieldType><Description>Entered In Ship To Form: Carried To SO</Description><Required>false</Required><MaxLength>24</MaxLength><LimitToList>false</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /></CustomField>''),
	(10, ''EDIShipToName'', ''<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>Text</FieldType><Description>Entered In Ship To Form: Carried To SO</Description><Required>false</Required><MaxLength>30</MaxLength><LimitToList>false</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /></CustomField>''),
	(11, ''EDIStatus'', ''<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>Entity</FieldType><Description>Packing Status: 0-New, 1-Packing Started, 2-Packing Completed</Description><Required>false</Required><MaxLength>0</MaxLength><LimitToList>false</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /><LookupId>EDOrdStatus</LookupId></CustomField>''),
	(12, ''EDIShipToCode'', ''<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>Text</FieldType><Description>EDI Ship To Code For a Specific AR Ship To ID</Description><Required>false</Required><MaxLength>24</MaxLength><LimitToList>false</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /></CustomField>''),
	(13, ''EDISCAC'', ''<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>Text</FieldType><Description>Code For Shippers</Description><Required>false</Required><MaxLength>4</MaxLength><LimitToList>false</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /></CustomField>''),
	(14, ''EDITrackingNumYN'', ''<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>YesNo</FieldType><Description>Tracking Numbers Used Yes/No</Description><Required>false</Required><MaxLength>0</MaxLength><LimitToList>false</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /></CustomField>''),
	(15, ''EDIMaxCartonValue'', ''<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>Number</FieldType><Description>Max Value</Description><Required>false</Required><MaxLength>0</MaxLength><LimitToList>false</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /></CustomField>''),
	(16, ''EDIMaxCartonWeight'', ''<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>Number</FieldType><Description>Max Weight</Description><Required>false</Required><MaxLength>0</MaxLength><LimitToList>false</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /></CustomField>''),
	(17, ''EDIShipToType'', ''<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>Entity</FieldType><Description>Ship To Types: 0-Store, 1-DC, 2-Consolidator, 3-Drop Ship</Description><Required>false</Required><MaxLength>10</MaxLength><LimitToList>true</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /><LookupId>CSIEdiShipToType</LookupId></CustomField>''),
	(18, ''EDIARStoreID'', ''<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>Entity</FieldType><Description>AR Ship To ID for a record withEDIShipToType=0</Description><Required>false</Required><MaxLength>50</MaxLength><LimitToList>false</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /><LookupId>CsiShipVia</LookupId></CustomField>''),
	(19, ''EDIARDCID'', ''<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>Text</FieldType><Description>AR Ship To ID for a record withEDIShipToType=1</Description><Required>false</Required><MaxLength>50</MaxLength><LimitToList>false</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /></CustomField>''),
	(20, ''EDIARConsolID'', ''<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>Text</FieldType><Description>AR Ship To ID for a record withEDIShipToType=2</Description><Required>false</Required><MaxLength>50</MaxLength><LimitToList>false</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /></CustomField>''),
	(21, ''EDIStoreCode'', ''<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>Text</FieldType><Description>Populated by EDI SO Generation; Manual Entry Also</Description><Required>false</Required><MaxLength>50</MaxLength><LimitToList>false</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /></CustomField>''),
	(22, ''EDIPOLineNum'', ''<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>Text</FieldType><Description>PO Line Number</Description><Required>false</Required><MaxLength>0</MaxLength><LimitToList>false</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /></CustomField>''),
	(23, ''EDIPartnerID'', ''<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>Text</FieldType><Description>Partner ID</Description><Required>false</Required><MaxLength>50</MaxLength><LimitToList>false</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /></CustomField>''),
	(24, ''EDIARShipToID'', ''<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>Text</FieldType><Description>AR Ship To ID</Description><Required>false</Required><MaxLength>50</MaxLength><LimitToList>false</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /></CustomField>'');

	SET IDENTITY_INSERT ['+@company+'].dbo.tblSmCustomField OFF;
	SET IDENTITY_INSERT ['+@company+'].dbo.tblSmCustomFieldEntity ON;
	/* FieldId = Id above */
	INSERT INTO ['+@company+'].dbo.tblSmCustomFieldEntity (Id, FieldId, EntityName, Layout)
	VALUES
	(1, 1, ''tblARHistHeader'', null), /*''0x0000000000046D79''*/
	(2, 1, ''tblSOTransheader'', null),
	(3, 2, ''tblARHistHeader'', null),
	(4, 2, ''tblSOTransheader'', null),
	(5, 3, ''tblARHistHeader'', null),
	(6, 3, ''tblSOTransheader'', null),
	(7, 4, ''tblARHistHeader'', null),
	(8, 4, ''tblSOTransheader'', null),
	(9, 5, ''tblARHistHeader'', null),
	(10, 5, ''tblSOTransheader'', null),
	(11, 6, ''tblARHistHeader'', null),
	(12, 6, ''tblSOTransheader'', null),
	(13, 7, ''tblARHistHeader'', null),
	(14, 7, ''tblSOTransheader'', null),
	(15, 8, ''tblARHistHeader'', null),
	(16, 8, ''tblSOTransheader'', null),
	(17, 9, ''tblARHistHeader'', null), /* 3 */
	(18, 9, ''tblSOTransheader'', null), /* 3 */
	(19, 9, ''tblARShipTo'', null), /* 3 */
	(20, 10, ''tblARHistHeader'', null),
	(21, 10, ''tblSOTransheader'', null),
	(22, 10, ''tblARShipTo'', null),
	(23, 11, ''tblARHistHeader'', null),
	(24, 11, ''tblSOTransheader'', null),
	(25, 12, ''tblARShipTo'', null),
	(26, 13, ''tblARShipMethod'', null),
	(27, 14, ''tblARShipMethod'', null),
	(28, 15, ''tblARShipMethod'', null),
	(29, 15, ''tblARShipTo'', null),
	(30, 16, ''tblARShipMethod'', null),
	(31, 16, ''tblARShipTo'', null),
	(32, 17, ''tblARHistHeader'', null),
	(33, 17, ''tblSOTransheader'', null),
	(34, 17, ''tblARShipTo'', null),
	(35, 18, ''tblARHistHeader'', null),
	(36, 18, ''tblSOTransheader'', null),
	(37, 19, ''tblARHistHeader'', null),
	(38, 19, ''tblSOTransheader'', null),
	(39, 20, ''tblARHistHeader'', null),
	(40, 20, ''tblSOTransheader'', null),
	(41, 21, ''tblARHistHeader'', null),
	(42, 21, ''tblSOTransheader'', null),
	(43, 22, ''tblARHistDetail'', null), --EDIPOLineNum 22
	(44, 22, ''tblSOTransDetail'', null), --EDIPOLineNum 22
	(45, 23, ''tblARHistHeader'', null), --EDIPartnerID 23
	(46, 23, ''tblSOTransheader'', null), --EDIPartnerID 23
	(47, 24, ''tblARHistHeader'', null), --EDIARShipToID 24
	(48, 24, ''tblSOTransheader'', null); --EDIARShipToID 24
	SET IDENTITY_INSERT ['+@company+'].dbo.tblSmCustomFieldEntity OFF;
	EXEC ['+@company+'].dbo.trav_DSViewRebuildAll_proc;
	');
	
	 -- Sequence # Initial Values
	EXEC('INSERT INTO ['+@company+'].dbo.tblSmTransID (FunctionID, NextID, ts)
	VALUES
	/*Batch Sequence Number used by SO Generation*/ (''EDIBatch'', 1, null),
	/*UCC128 / GS1 / Container Number*/ (''EDIUCC128'', 1000, null),
	/*Shipment Number*/ (''EDIShip'', 1000, null),
	/*EDIConInv*/ (''EDIConInv'', 1000, null); /* Last Field = Timestamp - Binary Data, nulls allowed */');
	
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



