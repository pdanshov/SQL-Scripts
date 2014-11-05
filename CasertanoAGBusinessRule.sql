
/********* Peter Danshov - Add Business Rule Records to Table, Casertano - 08.26.14 Tue 1437 EST pdanshv@gmail.com ***********/

INSERT INTO [dbo].[tblSmConfig] (ConfigRef, RecType, AppId, ConfigId, CTConfigRef, OptConfigRef, DispSeq, Visible, RoleConfigYn, CaptionId, SrchID, DefaultValue, MaxWidth, RequiredYn, ValueListId, ReqAppId, ReadOnlyYn, MinValue, MaxValue)
VALUES
/*EdiGrpAg*/ ( 10051, 2048, 'ED', 'EdiGrpAg', 356, 0, 10, 'True', 'False', 'Application Advice - 824', NULL, NULL, 0, 'False', NULL, NULL, 'False', NULL, NULL ),
	/*EdiAGFileName*/ ( 10052, 61, 'ED', 'EdiAGFileName', 10031, 0, 10, 'True', 'False', 'AG File Name', NULL, NULL, 0, 'False', NULL, NULL, 'False', NULL, NULL );

