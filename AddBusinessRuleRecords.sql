
/************************************************************************
 ********* Peter Danshov - Add Business Rule Records to Table ***********
 ************************************************************************
 *
 *		pdanshv@gmail.com 11.10.14
 *
 *		sys smconfig 		   = groups and sub-group menu items
 *		sys smconfigvalue 	   = new record with configref equal to smconfig
 *		sys dbo.tblSmMenuDescr = main menu items
 *		sys dbo.tblSmMenu	   = sub-menu items
 *
 *		All smconfig menu items must have captions:
 *			Trav10.5: sys dbo.tbl.syscaption [ObjectID] = sys dbo.tblsmconfig [CaptionId]
 *
 *		Traverse Company Setup:
 *			System Manager -> Company Setup -> Business Rules -> Application -> EDI
 *
 ************************************************************************/

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
	/*EdiUCC128Seq*/ ( 10045, 275, 'ED', 'EdiUCC128Seq', 10024, 0, 60, 1, 0, 'UCC128 Sequence', NULL, 1, 0, 0, NULL, NULL, 0, NULL, NULL );

