
/*******************************************************************
 ********* Peter Danshov - Add EDI Module Record to Table ***********
 *******************************************************************
 *
 *		pdanshv@gmail.com 12.05.14
 *
 *		sys smconfig 		   = groups and sub-group menu items
 *		sys smconfigvalue 	   = new record with configref equal to smconfig
 *		sys dbo.tblSmMenuDescr = main menu items
 *		sys dbo.tblSmMenu	   = sub-menu items
 *		sys	dbo.tblSmApp	   = top-level module
 *
 *		All smconfig menu items must have captions:
 *			Trav10.5: sys dbo.tbl.syscaption [ObjectID] = sys dbo.tblsmconfig [CaptionId]
 *
 *		Traverse Company Setup:
 *			System Manager -> Company Setup -> Business Rules -> Application -> EDI
 *
 *******************************************************************/
 
 INSERT INTO [SYS].[dbo].[tblSmApp] (AppId, Description, Version, BaseAppID, DefaultTable, ClientProgYn)
 VALUES
 /*EDI Module*/ ('ED', 'Electronic Data Interchange', 11, null, null, 'False');
 
 INSERT INTO [I31].[dbo].[tblSmApp_Installed] (AppID, Notes)
 VALUES
 ('ED',null);

