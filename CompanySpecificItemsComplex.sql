

/***********************************************************************

	Computer Solutions International, Inc.
	EDI Install
	Insert Custom Fields and Other Company-Specific Items
	12.11.14 - 1432
	Olga Khin okhin@csi-ny.com
	Peter Danshov pdanshv@gmail.com
	
 ***********************************************************************/
DECLARE @company varchar(30) = 'CSI'; -- Set the company database here < < <- <- <-- <-- <--- <--- ^^^^^^^^^^^^^^^^^^^
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

IF @company != 'CSI'
BEGIN
	PRINT N'';
	PRINT N'';
	PRINT N'********************************************************************************************';
	PRINT N'			Company is set to   '''+@company+'''   . Running Installation... ';
	PRINT N'********************************************************************************************';
	PRINT N'';

	-- tblSmApp_Installed for Business Rules
	EXEC('INSERT INTO ['+@company+'].[dbo].[tblSmApp_Installed] (AppID, Notes)
		VALUES
		(''ED'',null);');
	
	
	
	-- Custom Fields
	EXEC('
	
	USE ['+@company+']
	GO
	
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
		-- EDIPOPostRun
	
	
	
	select * from tblSmCustomField
	select c.Id,c.FieldName,e.EntityName,e.FieldId,e.Id from tblSmCustomField c
	inner join tblSmCustomFieldEntity e
	on c.Id=e.FieldId
	
	DECLARE @FieldName varchar(50)
	DECLARE @FieldId int
	SELECT @FieldName = ''EDIPOPostRun''
	SELECT @FieldId = ISNULL(Id,'''') FROM dbo.tblSmCustomField WHERE FieldName = @FieldName
	IF @FieldId <> ''''
	BEGIN
		DELETE FROM dbo.tblSmCustomFieldEntity WHERE FieldId = @FieldId
		DELETE FROM dbo.tblSmCustomField WHERE Id = @FieldId
	END
		INSERT INTO dbo.tblSmCustomField
			([FieldName],[Definition])
		VALUES
			(@FieldName
			,''<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>Text</FieldType><Description>Populated by EDI SO Generation; Manual Entry Also</Description><Required>false</Required><MaxLength>20</MaxLength><LimitToList>false</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /></CustomField>'')
	SELECT @FieldName = ''EDIPOPostRun''
	SELECT @FieldId = ISNULL(Id,'''') FROM dbo.tblSmCustomField WHERE FieldName = @FieldName
		INSERT INTO dbo.tblSmCustomFieldEntity
			(FieldId, Layout, EntityName)
		VALUES
			(@FieldId, null, ''tblARHistHeader'')
		INSERT INTO dbo.tblSmCustomFieldEntity
			(FieldId, Layout, EntityName)
		VALUES
			(@FieldId, null, ''tblSOTransheader'')
	go
	exec dbo.trav_DSViewRebuildAll_proc
	go

	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
		-- EDIDeptID
	
	
	
	select * from tblSmCustomField
	select c.Id,c.FieldName,e.EntityName,e.FieldId,e.Id from tblSmCustomField c
	inner join tblSmCustomFieldEntity e
	on c.Id=e.FieldId

	DECLARE @FieldName varchar(50)
	DECLARE @FieldId int
	SELECT @FieldName = ''EDIDeptID''
	SELECT @FieldId = ISNULL(Id,'''') FROM dbo.tblSmCustomField WHERE FieldName = @FieldName
	IF @FieldId <> ''''
	BEGIN
		DELETE FROM dbo.tblSmCustomFieldEntity WHERE FieldId = @FieldId
		DELETE FROM dbo.tblSmCustomField WHERE Id = @FieldId
	END
		INSERT INTO dbo.tblSmCustomField
			([FieldName],[Definition])
		VALUES
			(@FieldName
			,''<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>Text</FieldType><Description>Populated by EDI SO Generation; Manual Entry Also</Description><Required>false</Required><MaxLength>24</MaxLength><LimitToList>false</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /></CustomField>'')
	SELECT @FieldName = ''EDIDeptID''
	SELECT @FieldId = ISNULL(Id,'''') FROM dbo.tblSmCustomField WHERE FieldName = @FieldName
		INSERT INTO dbo.tblSmCustomFieldEntity
			(FieldId, Layout, EntityName)
		VALUES
			(@FieldId, null, ''tblARHistHeader'')
		INSERT INTO dbo.tblSmCustomFieldEntity
			(FieldId, Layout, EntityName)
		VALUES
			(@FieldId, null, ''tblSOTransheader'')
	go
	exec dbo.trav_DSViewRebuildAll_proc
	go
	
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
		-- EDICancelDate
	
	
	
	select * from tblSmCustomField
	select c.Id,c.FieldName,e.EntityName,e.FieldId,e.Id from tblSmCustomField c
	inner join tblSmCustomFieldEntity e
	on c.Id=e.FieldId

	DECLARE @FieldName varchar(50)
	DECLARE @FieldId int
	SELECT @FieldName = ''EDICancelDate''
	SELECT @FieldId = ISNULL(Id,'''') FROM dbo.tblSmCustomField WHERE FieldName = @FieldName
	IF @FieldId <> ''''
	BEGIN
		DELETE FROM dbo.tblSmCustomFieldEntity WHERE FieldId = @FieldId
		DELETE FROM dbo.tblSmCustomField WHERE Id = @FieldId
	END
		INSERT INTO dbo.tblSmCustomField
			([FieldName],[Definition])
		VALUES
			(@FieldName
			,''<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>Date</FieldType><Description>Populated by EDI SO Generation; Manual Entry Also</Description><Required>false</Required><MaxLength>0</MaxLength><LimitToList>false</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /></CustomField>'')
	SELECT @FieldName = ''EDICancelDate''
	SELECT @FieldId = ISNULL(Id,'''') FROM dbo.tblSmCustomField WHERE FieldName = @FieldName
		INSERT INTO dbo.tblSmCustomFieldEntity
			(FieldId, Layout, EntityName)
		VALUES
			(@FieldId, null, ''tblARHistHeader'')
		INSERT INTO dbo.tblSmCustomFieldEntity
			(FieldId, Layout, EntityName)
		VALUES
			(@FieldId, null, ''tblSOTransheader'')
	go
	exec dbo.trav_DSViewRebuildAll_proc
	go
	
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
		-- EDIASNYN
	
	
	
	select * from tblSmCustomField
	select c.Id,c.FieldName,e.EntityName,e.FieldId,e.Id from tblSmCustomField c
	inner join tblSmCustomFieldEntity e
	on c.Id=e.FieldId

	DECLARE @FieldName varchar(50)
	DECLARE @FieldId int
	SELECT @FieldName = ''EDIASNYN''
	SELECT @FieldId = ISNULL(Id,'''') FROM dbo.tblSmCustomField WHERE FieldName = @FieldName
	IF @FieldId <> ''''
	BEGIN
		DELETE FROM dbo.tblSmCustomFieldEntity WHERE FieldId = @FieldId
		DELETE FROM dbo.tblSmCustomField WHERE Id = @FieldId
	END
		INSERT INTO dbo.tblSmCustomField
			([FieldName],[Definition])
		VALUES
			(@FieldName
			,''<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>YesNo</FieldType><Description>Populated by EDI SO Generation; Manual Entry Also</Description><Required>false</Required><MaxLength>0</MaxLength><LimitToList>false</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /></CustomField>'')
	SELECT @FieldName = ''EDIASNYN''
	SELECT @FieldId = ISNULL(Id,'''') FROM dbo.tblSmCustomField WHERE FieldName = @FieldName
		INSERT INTO dbo.tblSmCustomFieldEntity
			(FieldId, Layout, EntityName)
		VALUES
			(@FieldId, null, ''tblARHistHeader'')
		INSERT INTO dbo.tblSmCustomFieldEntity
			(FieldId, Layout, EntityName)
		VALUES
			(@FieldId, null, ''tblSOTransheader'')
	go
	exec dbo.trav_DSViewRebuildAll_proc
	go
	
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
		-- EDIInvoiceYN
	
	
	
	select * from tblSmCustomField
	select c.Id,c.FieldName,e.EntityName,e.FieldId,e.Id from tblSmCustomField c
	inner join tblSmCustomFieldEntity e
	on c.Id=e.FieldId

	DECLARE @FieldName varchar(50)
	DECLARE @FieldId int
	SELECT @FieldName = ''EDIInvoiceYN''
	SELECT @FieldId = ISNULL(Id,'''') FROM dbo.tblSmCustomField WHERE FieldName = @FieldName
	IF @FieldId <> ''''
	BEGIN
		DELETE FROM dbo.tblSmCustomFieldEntity WHERE FieldId = @FieldId
		DELETE FROM dbo.tblSmCustomField WHERE Id = @FieldId
	END
		INSERT INTO dbo.tblSmCustomField
			([FieldName],[Definition])
		VALUES
			(@FieldName
			,''<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>YesNo</FieldType><Description>Populated by EDI SO Generation; Manual Entry Also</Description><Required>false</Required><MaxLength>0</MaxLength><LimitToList>false</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /></CustomField>'')
	SELECT @FieldName = ''EDIInvoiceYN''
	SELECT @FieldId = ISNULL(Id,'''') FROM dbo.tblSmCustomField WHERE FieldName = @FieldName
		INSERT INTO dbo.tblSmCustomFieldEntity
			(FieldId, Layout, EntityName)
		VALUES
			(@FieldId, null, ''tblARHistHeader'')
		INSERT INTO dbo.tblSmCustomFieldEntity
			(FieldId, Layout, EntityName)
		VALUES
			(@FieldId, null, ''tblSOTransheader'')
	go
	exec dbo.trav_DSViewRebuildAll_proc
	go
	
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
		-- EDIDUNS
	
	
	
	select * from tblSmCustomField
	select c.Id,c.FieldName,e.EntityName,e.FieldId,e.Id from tblSmCustomField c
	inner join tblSmCustomFieldEntity e
	on c.Id=e.FieldId

	DECLARE @FieldName varchar(50)
	DECLARE @FieldId int
	SELECT @FieldName = ''EDIDUNS''
	SELECT @FieldId = ISNULL(Id,'''') FROM dbo.tblSmCustomField WHERE FieldName = @FieldName
	IF @FieldId <> ''''
	BEGIN
		DELETE FROM dbo.tblSmCustomFieldEntity WHERE FieldId = @FieldId
		DELETE FROM dbo.tblSmCustomField WHERE Id = @FieldId
	END
		INSERT INTO dbo.tblSmCustomField
			([FieldName],[Definition])
		VALUES
			(@FieldName
			,''<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>Text</FieldType><Description>Populated by EDI SO Generation; Manual Entry Also</Description><Required>false</Required><MaxLength>24</MaxLength><LimitToList>false</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /></CustomField>'')
	SELECT @FieldName = ''EDIDUNS''
	SELECT @FieldId = ISNULL(Id,'''') FROM dbo.tblSmCustomField WHERE FieldName = @FieldName
		INSERT INTO dbo.tblSmCustomFieldEntity
			(FieldId, Layout, EntityName)
		VALUES
			(@FieldId, null, ''tblARHistHeader'')
		INSERT INTO dbo.tblSmCustomFieldEntity
			(FieldId, Layout, EntityName)
		VALUES
			(@FieldId, null, ''tblSOTransheader'')
	go
	exec dbo.trav_DSViewRebuildAll_proc
	go
	
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
		-- EDIInvcNum
	
	
	
	select * from tblSmCustomField
	select c.Id,c.FieldName,e.EntityName,e.FieldId,e.Id from tblSmCustomField c
	inner join tblSmCustomFieldEntity e
	on c.Id=e.FieldId

	DECLARE @FieldName varchar(50)
	DECLARE @FieldId int
	SELECT @FieldName = ''EDIInvcNum''
	SELECT @FieldId = ISNULL(Id,'''') FROM dbo.tblSmCustomField WHERE FieldName = @FieldName
	IF @FieldId <> ''''
	BEGIN
		DELETE FROM dbo.tblSmCustomFieldEntity WHERE FieldId = @FieldId
		DELETE FROM dbo.tblSmCustomField WHERE Id = @FieldId
	END
		INSERT INTO dbo.tblSmCustomField
			([FieldName],[Definition])
		VALUES
			(@FieldName
			,''<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>Text</FieldType><Description>EDI Invoice #: only different from standard invoice # for consolidated</Description><Required>false</Required><MaxLength>24</MaxLength><LimitToList>false</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /></CustomField>'')
	SELECT @FieldName = ''EDIInvcNum''
	SELECT @FieldId = ISNULL(Id,'''') FROM dbo.tblSmCustomField WHERE FieldName = @FieldName
		INSERT INTO dbo.tblSmCustomFieldEntity
			(FieldId, Layout, EntityName)
		VALUES
			(@FieldId, null, ''tblARHistHeader'')
		INSERT INTO dbo.tblSmCustomFieldEntity
			(FieldId, Layout, EntityName)
		VALUES
			(@FieldId, null, ''tblSOTransheader'')
	go
	exec dbo.trav_DSViewRebuildAll_proc
	go
	
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
		-- EDIShipViaCode
	
	
	
	select * from tblSmCustomField
	select c.Id,c.FieldName,e.EntityName,e.FieldId,e.Id from tblSmCustomField c
	inner join tblSmCustomFieldEntity e
	on c.Id=e.FieldId

	DECLARE @FieldName varchar(50)
	DECLARE @FieldId int
	SELECT @FieldName = ''EDIShipViaCode''
	SELECT @FieldId = ISNULL(Id,'''') FROM dbo.tblSmCustomField WHERE FieldName = @FieldName
	IF @FieldId <> ''''
	BEGIN
		DELETE FROM dbo.tblSmCustomFieldEntity WHERE FieldId = @FieldId
		DELETE FROM dbo.tblSmCustomField WHERE Id = @FieldId
	END
		INSERT INTO dbo.tblSmCustomField
			([FieldName],[Definition])
		VALUES
			(@FieldName
			,''<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>Entity</FieldType><Description>Ship Via Code Saved</Description><Required>false</Required><MaxLength>24</MaxLength><LimitToList>false</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /><LookupId>CsiShipVia</LookupId></CustomField>'')
	SELECT @FieldName = ''EDIShipViaCode''
	SELECT @FieldId = ISNULL(Id,'''') FROM dbo.tblSmCustomField WHERE FieldName = @FieldName
		INSERT INTO dbo.tblSmCustomFieldEntity
			(FieldId, Layout, EntityName)
		VALUES
			(@FieldId, null, ''tblARHistHeader'')
		INSERT INTO dbo.tblSmCustomFieldEntity
			(FieldId, Layout, EntityName)
		VALUES
			(@FieldId, null, ''tblSOTransheader'')
	go
	exec dbo.trav_DSViewRebuildAll_proc
	go
	
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
		-- EDIShipToAbbrev
	
	
	
	select * from tblSmCustomField
	select c.Id,c.FieldName,e.EntityName,e.FieldId,e.Id from tblSmCustomField c
	inner join tblSmCustomFieldEntity e
	on c.Id=e.FieldId
	
	DECLARE @FieldName varchar(50)
	DECLARE @FieldId int
	SELECT @FieldName = ''EDIShipToAbbrev''
	SELECT @FieldId = ISNULL(Id,'''') FROM dbo.tblSmCustomField WHERE FieldName = @FieldName
	IF @FieldId <> ''''
	BEGIN
		DELETE FROM dbo.tblSmCustomFieldEntity WHERE FieldId = @FieldId
		DELETE FROM dbo.tblSmCustomField WHERE Id = @FieldId
	END
		INSERT INTO dbo.tblSmCustomField
			([FieldName],[Definition])
		VALUES
			(@FieldName
			,''<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>Text</FieldType><Description>Entered In Ship To Form: Carried To SO</Description><Required>false</Required><MaxLength>24</MaxLength><LimitToList>false</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /></CustomField>'')
	SELECT @FieldName = ''EDIShipToAbbrev''
	SELECT @FieldId = ISNULL(Id,'''') FROM dbo.tblSmCustomField WHERE FieldName = @FieldName
		INSERT INTO dbo.tblSmCustomFieldEntity
			(FieldId, Layout, EntityName)
		VALUES
			(@FieldId, null, ''tblARHistHeader'')
		INSERT INTO dbo.tblSmCustomFieldEntity
			(FieldId, Layout, EntityName)
		VALUES
			(@FieldId, null, ''tblSOTransheader'')
		INSERT INTO dbo.tblSmCustomFieldEntity
			(FieldId, Layout, EntityName)
		VALUES
			(@FieldId, null, ''tblARShipTo'')
	go
	exec dbo.trav_DSViewRebuildAll_proc
	go
	
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
		-- EDIShipToName
	
	
	
	select * from tblSmCustomField
	select c.Id,c.FieldName,e.EntityName,e.FieldId,e.Id from tblSmCustomField c
	inner join tblSmCustomFieldEntity e
	on c.Id=e.FieldId
	
	DECLARE @FieldName varchar(50)
	DECLARE @FieldId int
	SELECT @FieldName = ''EDIShipToName''
	SELECT @FieldId = ISNULL(Id,'''') FROM dbo.tblSmCustomField WHERE FieldName = @FieldName
	IF @FieldId <> ''''
	BEGIN
		DELETE FROM dbo.tblSmCustomFieldEntity WHERE FieldId = @FieldId
		DELETE FROM dbo.tblSmCustomField WHERE Id = @FieldId
	END
		INSERT INTO dbo.tblSmCustomField
			([FieldName],[Definition])
		VALUES
			(@FieldName
			,''<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>Text</FieldType><Description>Entered In Ship To Form: Carried To SO</Description><Required>false</Required><MaxLength>30</MaxLength><LimitToList>false</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /></CustomField>'')
	SELECT @FieldName = ''EDIShipToName''
	SELECT @FieldId = ISNULL(Id,'''') FROM dbo.tblSmCustomField WHERE FieldName = @FieldName
		INSERT INTO dbo.tblSmCustomFieldEntity
			(FieldId, Layout, EntityName)
		VALUES
			(@FieldId, null, ''tblARHistHeader'')
		INSERT INTO dbo.tblSmCustomFieldEntity
			(FieldId, Layout, EntityName)
		VALUES
			(@FieldId, null, ''tblSOTransheader'')
		INSERT INTO dbo.tblSmCustomFieldEntity
			(FieldId, Layout, EntityName)
		VALUES
			(@FieldId, null, ''tblARShipTo'')
	go
	exec dbo.trav_DSViewRebuildAll_proc
	go
	
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
		-- EDIStatus
	
	
	
	select * from tblSmCustomField
	select c.Id,c.FieldName,e.EntityName,e.FieldId,e.Id from tblSmCustomField c
	inner join tblSmCustomFieldEntity e
	on c.Id=e.FieldId
	
	DECLARE @FieldName varchar(50)
	DECLARE @FieldId int
	SELECT @FieldName = ''EDIStatus''
	SELECT @FieldId = ISNULL(Id,'''') FROM dbo.tblSmCustomField WHERE FieldName = @FieldName
	IF @FieldId <> ''''
	BEGIN
		DELETE FROM dbo.tblSmCustomFieldEntity WHERE FieldId = @FieldId
		DELETE FROM dbo.tblSmCustomField WHERE Id = @FieldId
	END
		INSERT INTO dbo.tblSmCustomField
			([FieldName],[Definition])
		VALUES
			(@FieldName
			,''<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>Entity</FieldType><Description>Packing Status: 0-New, 1-Packing Started, 2-Packing Completed</Description><Required>false</Required><MaxLength>0</MaxLength><LimitToList>false</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /><LookupId>EDOrdStatus</LookupId></CustomField>'')
	SELECT @FieldName = ''EDIStatus''
	SELECT @FieldId = ISNULL(Id,'''') FROM dbo.tblSmCustomField WHERE FieldName = @FieldName
		INSERT INTO dbo.tblSmCustomFieldEntity
			(FieldId, Layout, EntityName)
		VALUES
			(@FieldId, null, ''tblARHistHeader'')
		INSERT INTO dbo.tblSmCustomFieldEntity
			(FieldId, Layout, EntityName)
		VALUES
			(@FieldId, null, ''tblSOTransheader'')
	go
	go
	exec dbo.trav_DSViewRebuildAll_proc
	go
	
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
		-- EDIShipToCode
	
	
	
	select * from tblSmCustomField
	select c.Id,c.FieldName,e.EntityName,e.FieldId,e.Id from tblSmCustomField c
	inner join tblSmCustomFieldEntity e
	on c.Id=e.FieldId
	
	DECLARE @FieldName varchar(50)
	DECLARE @FieldId int
	SELECT @FieldName = ''EDIShipToCode''
	SELECT @FieldId = ISNULL(Id,'''') FROM dbo.tblSmCustomField WHERE FieldName = @FieldName
	IF @FieldId <> ''''
	BEGIN
		DELETE FROM dbo.tblSmCustomFieldEntity WHERE FieldId = @FieldId
		DELETE FROM dbo.tblSmCustomField WHERE Id = @FieldId
	END
		INSERT INTO dbo.tblSmCustomField
			([FieldName],[Definition])
		VALUES
			(@FieldName
			,''<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>Text</FieldType><Description>EDI Ship To Code For a Specific AR Ship To ID</Description><Required>false</Required><MaxLength>24</MaxLength><LimitToList>false</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /></CustomField>'')
	SELECT @FieldName = ''EDIShipToCode''
	SELECT @FieldId = ISNULL(Id,'''') FROM dbo.tblSmCustomField WHERE FieldName = @FieldName
		INSERT INTO dbo.tblSmCustomFieldEntity
			(FieldId, Layout, EntityName)
		VALUES
			(@FieldId, null, ''tblARShipTo'')
	go
	exec dbo.trav_DSViewRebuildAll_proc
	go
	
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
		-- EDISCAC
	
	
	
	select * from tblSmCustomField
	select c.Id,c.FieldName,e.EntityName,e.FieldId,e.Id from tblSmCustomField c
	inner join tblSmCustomFieldEntity e
	on c.Id=e.FieldId
	
	DECLARE @FieldName varchar(50)
	DECLARE @FieldId int
	SELECT @FieldName = ''EDISCAC''
	SELECT @FieldId = ISNULL(Id,'''') FROM dbo.tblSmCustomField WHERE FieldName = @FieldName
	IF @FieldId <> ''''
	BEGIN
		DELETE FROM dbo.tblSmCustomFieldEntity WHERE FieldId = @FieldId
		DELETE FROM dbo.tblSmCustomField WHERE Id = @FieldId
	END
		INSERT INTO dbo.tblSmCustomField
			([FieldName],[Definition])
		VALUES
			(@FieldName
			,''<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>Text</FieldType><Description>Code For Shippers</Description><Required>false</Required><MaxLength>4</MaxLength><LimitToList>false</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /></CustomField>'')
	SELECT @FieldName = ''EDISCAC''
	SELECT @FieldId = ISNULL(Id,'''') FROM dbo.tblSmCustomField WHERE FieldName = @FieldName
		INSERT INTO dbo.tblSmCustomFieldEntity
			(FieldId, Layout, EntityName)
		VALUES
			(@FieldId, null, ''tblARShipMethod'')
	go
	exec dbo.trav_DSViewRebuildAll_proc
	go
	
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
		-- EDITrackingNumYN
	
	
	
	select * from tblSmCustomField
	select c.Id,c.FieldName,e.EntityName,e.FieldId,e.Id from tblSmCustomField c
	inner join tblSmCustomFieldEntity e
	on c.Id=e.FieldId
	
	DECLARE @FieldName varchar(50)
	DECLARE @FieldId int
	SELECT @FieldName = ''EDITrackingNumYN''
	SELECT @FieldId = ISNULL(Id,'''') FROM dbo.tblSmCustomField WHERE FieldName = @FieldName
	IF @FieldId <> ''''
	BEGIN
		DELETE FROM dbo.tblSmCustomFieldEntity WHERE FieldId = @FieldId
		DELETE FROM dbo.tblSmCustomField WHERE Id = @FieldId
	END
		INSERT INTO dbo.tblSmCustomField
			([FieldName],[Definition])
		VALUES
			(@FieldName
			,''<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>YesNo</FieldType><Description>Tracking Numbers Used Yes/No</Description><Required>false</Required><MaxLength>0</MaxLength><LimitToList>false</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /></CustomField>'')
	SELECT @FieldName = ''EDITrackingNumYN''
	SELECT @FieldId = ISNULL(Id,'''') FROM dbo.tblSmCustomField WHERE FieldName = @FieldName
		INSERT INTO dbo.tblSmCustomFieldEntity
			(FieldId, Layout, EntityName)
		VALUES
			(@FieldId, null, ''tblARShipMethod'')
	go
	exec dbo.trav_DSViewRebuildAll_proc
	go
	
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
		-- EDIMaxCartonValue
	
	
	
	select * from tblSmCustomField
	select c.Id,c.FieldName,e.EntityName,e.FieldId,e.Id from tblSmCustomField c
	inner join tblSmCustomFieldEntity e
	on c.Id=e.FieldId
	
	DECLARE @FieldName varchar(50)
	DECLARE @FieldId int
	SELECT @FieldName = ''EDIMaxCartonValue''
	SELECT @FieldId = ISNULL(Id,'''') FROM dbo.tblSmCustomField WHERE FieldName = @FieldName
	IF @FieldId <> ''''
	BEGIN
		DELETE FROM dbo.tblSmCustomFieldEntity WHERE FieldId = @FieldId
		DELETE FROM dbo.tblSmCustomField WHERE Id = @FieldId
	END
		INSERT INTO dbo.tblSmCustomField
			([FieldName],[Definition])
		VALUES
			(@FieldName
			,''<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>Number</FieldType><Description>Max Value</Description><Required>false</Required><MaxLength>0</MaxLength><LimitToList>false</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /></CustomField>'')
	SELECT @FieldName = ''EDIMaxCartonValue''
	SELECT @FieldId = ISNULL(Id,'''') FROM dbo.tblSmCustomField WHERE FieldName = @FieldName
		INSERT INTO dbo.tblSmCustomFieldEntity
			(FieldId, Layout, EntityName)
		VALUES
			(@FieldId, null, ''tblARShipMethod'')
		INSERT INTO dbo.tblSmCustomFieldEntity
			(FieldId, Layout, EntityName)
		VALUES
			(@FieldId, null, ''tblARShipTo'')
	go
	exec dbo.trav_DSViewRebuildAll_proc
	go
	
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
		-- EDIMaxCartonWeight
	
	
	
	select * from tblSmCustomField
	select c.Id,c.FieldName,e.EntityName,e.FieldId,e.Id from tblSmCustomField c
	inner join tblSmCustomFieldEntity e
	on c.Id=e.FieldId
	
	DECLARE @FieldName varchar(50)
	DECLARE @FieldId int
	SELECT @FieldName = ''EDIMaxCartonWeight''
	SELECT @FieldId = ISNULL(Id,'''') FROM dbo.tblSmCustomField WHERE FieldName = @FieldName
	IF @FieldId <> ''''
	BEGIN
		DELETE FROM dbo.tblSmCustomFieldEntity WHERE FieldId = @FieldId
		DELETE FROM dbo.tblSmCustomField WHERE Id = @FieldId
	END
		INSERT INTO dbo.tblSmCustomField
			([FieldName],[Definition])
		VALUES
			(@FieldName
			,''<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>Number</FieldType><Description>Max Weight</Description><Required>false</Required><MaxLength>0</MaxLength><LimitToList>false</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /></CustomField>'')
	SELECT @FieldName = ''EDIMaxCartonWeight''
	SELECT @FieldId = ISNULL(Id,'''') FROM dbo.tblSmCustomField WHERE FieldName = @FieldName
		INSERT INTO dbo.tblSmCustomFieldEntity
			(FieldId, Layout, EntityName)
		VALUES
			(@FieldId, null, ''tblARShipMethod'')
		INSERT INTO dbo.tblSmCustomFieldEntity
			(FieldId, Layout, EntityName)
		VALUES
			(@FieldId, null, ''tblARShipTo'')
	go
	exec dbo.trav_DSViewRebuildAll_proc
	go
	
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
		-- EDIShipToType
	
	
	
	select * from tblSmCustomField
	select c.Id,c.FieldName,e.EntityName,e.FieldId,e.Id from tblSmCustomField c
	inner join tblSmCustomFieldEntity e
	on c.Id=e.FieldId
	
	DECLARE @FieldName varchar(50)
	DECLARE @FieldId int
	SELECT @FieldName = ''EDIShipToType''
	SELECT @FieldId = ISNULL(Id,'''') FROM dbo.tblSmCustomField WHERE FieldName = @FieldName
	IF @FieldId <> ''''
	BEGIN
		DELETE FROM dbo.tblSmCustomFieldEntity WHERE FieldId = @FieldId
		DELETE FROM dbo.tblSmCustomField WHERE Id = @FieldId
	END
		INSERT INTO dbo.tblSmCustomField
			([FieldName],[Definition])
		VALUES
			(@FieldName
			,''<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>Entity</FieldType><Description>Ship To Types: 0-Store, 1-DC, 2-Consolidator, 3-Drop Ship</Description><Required>false</Required><MaxLength>10</MaxLength><LimitToList>true</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /><LookupId>CSIEdiShipToType</LookupId></CustomField>'')
	SELECT @FieldName = ''EDIShipToType''
	SELECT @FieldId = ISNULL(Id,'''') FROM dbo.tblSmCustomField WHERE FieldName = @FieldName
		INSERT INTO dbo.tblSmCustomFieldEntity
			(FieldId, Layout, EntityName)
		VALUES
			(@FieldId, null, ''tblARHistHeader'')
		INSERT INTO dbo.tblSmCustomFieldEntity
			(FieldId, Layout, EntityName)
		VALUES
			(@FieldId, null, ''tblSOTransheader'')
		INSERT INTO dbo.tblSmCustomFieldEntity
			(FieldId, Layout, EntityName)
		VALUES
			(@FieldId, null, ''tblARShipTo'')
	go
	exec dbo.trav_DSViewRebuildAll_proc
	go
	
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
		-- EDIARStoreID
	
	
	
	select * from tblSmCustomField
	select c.Id,c.FieldName,e.EntityName,e.FieldId,e.Id from tblSmCustomField c
	inner join tblSmCustomFieldEntity e
	on c.Id=e.FieldId
	
	DECLARE @FieldName varchar(50)
	DECLARE @FieldId int
	SELECT @FieldName = ''EDIARStoreID''
	SELECT @FieldId = ISNULL(Id,'''') FROM dbo.tblSmCustomField WHERE FieldName = @FieldName
	IF @FieldId <> ''''
	BEGIN
		DELETE FROM dbo.tblSmCustomFieldEntity WHERE FieldId = @FieldId
		DELETE FROM dbo.tblSmCustomField WHERE Id = @FieldId
	END
		INSERT INTO dbo.tblSmCustomField
			([FieldName],[Definition])
		VALUES
			(@FieldName
			,''<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>Entity</FieldType><Description>AR Ship To ID for a record withEDIShipToType=0</Description><Required>false</Required><MaxLength>50</MaxLength><LimitToList>false</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /><LookupId>CsiShipVia</LookupId></CustomField>'')
	SELECT @FieldName = ''EDIARStoreID''
	SELECT @FieldId = ISNULL(Id,'''') FROM dbo.tblSmCustomField WHERE FieldName = @FieldName
		INSERT INTO dbo.tblSmCustomFieldEntity
			(FieldId, Layout, EntityName)
		VALUES
			(@FieldId, null, ''tblARHistHeader'')
		INSERT INTO dbo.tblSmCustomFieldEntity
			(FieldId, Layout, EntityName)
		VALUES
			(@FieldId, null, ''tblSOTransheader'')
	go
	exec dbo.trav_DSViewRebuildAll_proc
	go
	
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
		-- EDIARDCID
	
	
	
	select * from tblSmCustomField
	select c.Id,c.FieldName,e.EntityName,e.FieldId,e.Id from tblSmCustomField c
	inner join tblSmCustomFieldEntity e
	on c.Id=e.FieldId
	
	DECLARE @FieldName varchar(50)
	DECLARE @FieldId int
	SELECT @FieldName = ''EDIARDCID''
	SELECT @FieldId = ISNULL(Id,'''') FROM dbo.tblSmCustomField WHERE FieldName = @FieldName
	IF @FieldId <> ''''
	BEGIN
		DELETE FROM dbo.tblSmCustomFieldEntity WHERE FieldId = @FieldId
		DELETE FROM dbo.tblSmCustomField WHERE Id = @FieldId
	END
		INSERT INTO dbo.tblSmCustomField
			([FieldName],[Definition])
		VALUES
			(@FieldName
			,''<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>Text</FieldType><Description>AR Ship To ID for a record withEDIShipToType=1</Description><Required>false</Required><MaxLength>50</MaxLength><LimitToList>false</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /></CustomField>'')
	SELECT @FieldName = ''EDIARDCID''
	SELECT @FieldId = ISNULL(Id,'''') FROM dbo.tblSmCustomField WHERE FieldName = @FieldName
		INSERT INTO dbo.tblSmCustomFieldEntity
			(FieldId, Layout, EntityName)
		VALUES
			(@FieldId, null, ''tblARHistHeader'')
		INSERT INTO dbo.tblSmCustomFieldEntity
			(FieldId, Layout, EntityName)
		VALUES
			(@FieldId, null, ''tblSOTransheader'')
		INSERT INTO dbo.tblSmCustomFieldEntity
			(FieldId, Layout, EntityName)
		VALUES
			(@FieldId, null, ''tblARShipTo'')
	go
	exec dbo.trav_DSViewRebuildAll_proc
	go
	
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
		-- EDIARConsolID
	
	
	
	select * from tblSmCustomField
	select c.Id,c.FieldName,e.EntityName,e.FieldId,e.Id from tblSmCustomField c
	inner join tblSmCustomFieldEntity e
	on c.Id=e.FieldId
	
	DECLARE @FieldName varchar(50)
	DECLARE @FieldId int
	SELECT @FieldName = ''EDIARConsolID''
	SELECT @FieldId = ISNULL(Id,'''') FROM dbo.tblSmCustomField WHERE FieldName = @FieldName
	IF @FieldId <> ''''
	BEGIN
		DELETE FROM dbo.tblSmCustomFieldEntity WHERE FieldId = @FieldId
		DELETE FROM dbo.tblSmCustomField WHERE Id = @FieldId
	END
		INSERT INTO dbo.tblSmCustomField
			([FieldName],[Definition])
		VALUES
			(@FieldName
			,''<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>Text</FieldType><Description>AR Ship To ID for a record withEDIShipToType=2</Description><Required>false</Required><MaxLength>50</MaxLength><LimitToList>false</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /></CustomField>'')
	SELECT @FieldName = ''EDIARConsolID''
	SELECT @FieldId = ISNULL(Id,'''') FROM dbo.tblSmCustomField WHERE FieldName = @FieldName
		INSERT INTO dbo.tblSmCustomFieldEntity
			(FieldId, Layout, EntityName)
		VALUES
			(@FieldId, null, ''tblARHistHeader'')
		INSERT INTO dbo.tblSmCustomFieldEntity
			(FieldId, Layout, EntityName)
		VALUES
			(@FieldId, null, ''tblSOTransheader'')
	go
	exec dbo.trav_DSViewRebuildAll_proc
	go
	
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
		-- EDIStoreCode
	
	
	
	select * from tblSmCustomField
	select c.Id,c.FieldName,e.EntityName,e.FieldId,e.Id from tblSmCustomField c
	inner join tblSmCustomFieldEntity e
	on c.Id=e.FieldId
	
	DECLARE @FieldName varchar(50)
	DECLARE @FieldId int
	SELECT @FieldName = ''EDIStoreCode''
	SELECT @FieldId = ISNULL(Id,'''') FROM dbo.tblSmCustomField WHERE FieldName = @FieldName
	IF @FieldId <> ''''
	BEGIN
		DELETE FROM dbo.tblSmCustomFieldEntity WHERE FieldId = @FieldId
		DELETE FROM dbo.tblSmCustomField WHERE Id = @FieldId
	END
		INSERT INTO dbo.tblSmCustomField
			([FieldName],[Definition])
		VALUES
			(@FieldName
			,''<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>Text</FieldType><Description>Populated by EDI SO Generation; Manual Entry Also</Description><Required>false</Required><MaxLength>50</MaxLength><LimitToList>false</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /></CustomField>'')
	SELECT @FieldName = ''EDIStoreCode''
	SELECT @FieldId = ISNULL(Id,'''') FROM dbo.tblSmCustomField WHERE FieldName = @FieldName
		INSERT INTO dbo.tblSmCustomFieldEntity
			(FieldId, Layout, EntityName)
		VALUES
			(@FieldId, null, ''tblARHistHeader'')
		INSERT INTO dbo.tblSmCustomFieldEntity
			(FieldId, Layout, EntityName)
		VALUES
			(@FieldId, null, ''tblSOTransheader'')
	go
	exec dbo.trav_DSViewRebuildAll_proc
	go
	
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
		-- EDIPOLineNum
	
	
	
	select * from tblSmCustomField
	select c.Id,c.FieldName,e.EntityName,e.FieldId,e.Id from tblSmCustomField c
	inner join tblSmCustomFieldEntity e
	on c.Id=e.FieldId
	
	DECLARE @FieldName varchar(50)
	DECLARE @FieldId int
	SELECT @FieldName = ''EDIPOLineNum''
	SELECT @FieldId = ISNULL(Id,'''') FROM dbo.tblSmCustomField WHERE FieldName = @FieldName
	IF @FieldId <> ''''
	BEGIN
		DELETE FROM dbo.tblSmCustomFieldEntity WHERE FieldId = @FieldId
		DELETE FROM dbo.tblSmCustomField WHERE Id = @FieldId
	END
		INSERT INTO dbo.tblSmCustomField
			([FieldName],[Definition])
		VALUES
			(@FieldName
			,''<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>Text</FieldType><Description>PO Line Number</Description><Required>false</Required><MaxLength>0</MaxLength><LimitToList>false</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /></CustomField>'')
	SELECT @FieldName = ''EDIPOLineNum''
	SELECT @FieldId = ISNULL(Id,'''') FROM dbo.tblSmCustomField WHERE FieldName = @FieldName
		INSERT INTO dbo.tblSmCustomFieldEntity
			(FieldId, Layout, EntityName)
		VALUES
			(@FieldId, null, ''tblARHistDetail'')
		INSERT INTO dbo.tblSmCustomFieldEntity
			(FieldId, Layout, EntityName)
		VALUES
			(@FieldId, null, ''tblSOTransDetail'')
	go
	go
	exec dbo.trav_DSViewRebuildAll_proc
	go
	
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
		-- EDIPartnerID
	
	
	
	select * from tblSmCustomField
	select c.Id,c.FieldName,e.EntityName,e.FieldId,e.Id from tblSmCustomField c
	inner join tblSmCustomFieldEntity e
	on c.Id=e.FieldId
	
	DECLARE @FieldName varchar(50)
	DECLARE @FieldId int
	SELECT @FieldName = ''EDIPartnerID''
	SELECT @FieldId = ISNULL(Id,'''') FROM dbo.tblSmCustomField WHERE FieldName = @FieldName
	IF @FieldId <> ''''
	BEGIN
		DELETE FROM dbo.tblSmCustomFieldEntity WHERE FieldId = @FieldId
		DELETE FROM dbo.tblSmCustomField WHERE Id = @FieldId
	END
		INSERT INTO dbo.tblSmCustomField
			([FieldName],[Definition])
		VALUES
			(@FieldName
			,''<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>Text</FieldType><Description>Partner ID</Description><Required>false</Required><MaxLength>50</MaxLength><LimitToList>false</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /></CustomField>'')
	SELECT @FieldName = ''EDIPartnerID''
	SELECT @FieldId = ISNULL(Id,'''') FROM dbo.tblSmCustomField WHERE FieldName = @FieldName
		INSERT INTO dbo.tblSmCustomFieldEntity
			(FieldId, Layout, EntityName)
		VALUES
			(@FieldId, null, ''tblARHistHeader'')
		INSERT INTO dbo.tblSmCustomFieldEntity
			(FieldId, Layout, EntityName)
		VALUES
			(@FieldId, null, ''tblSOTransheader'')
	go
	exec dbo.trav_DSViewRebuildAll_proc
	go
	
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
		-- EDIARShipToID
	
	
	
	select * from tblSmCustomField
	select c.Id,c.FieldName,e.EntityName,e.FieldId,e.Id from tblSmCustomField c
	inner join tblSmCustomFieldEntity e
	on c.Id=e.FieldId
	
	DECLARE @FieldName varchar(50)
	DECLARE @FieldId int
	SELECT @FieldName = ''EDIARShipToID''
	SELECT @FieldId = ISNULL(Id,'''') FROM dbo.tblSmCustomField WHERE FieldName = @FieldName
	IF @FieldId <> ''''
	BEGIN
		DELETE FROM dbo.tblSmCustomFieldEntity WHERE FieldId = @FieldId
		DELETE FROM dbo.tblSmCustomField WHERE Id = @FieldId
	END
		INSERT INTO dbo.tblSmCustomField
			([FieldName],[Definition])
		VALUES
			(@FieldName
			,''<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>Text</FieldType><Description>AR Ship To ID</Description><Required>false</Required><MaxLength>50</MaxLength><LimitToList>false</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /></CustomField>'')
	SELECT @FieldName = ''EDIARShipToID''
	SELECT @FieldId = ISNULL(Id,'''') FROM dbo.tblSmCustomField WHERE FieldName = @FieldName
		INSERT INTO dbo.tblSmCustomFieldEntity
			(FieldId, Layout, EntityName)
		VALUES
			(@FieldId, null, ''tblARHistHeader'')
		INSERT INTO dbo.tblSmCustomFieldEntity
			(FieldId, Layout, EntityName)
		VALUES
			(@FieldId, null, ''tblSOTransheader'')
	go
	exec dbo.trav_DSViewRebuildAll_proc
	go
	
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
		-- EDIGeneratedYN
	
	
	
	select * from tblSmCustomField
	select c.Id,c.FieldName,e.EntityName,e.FieldId,e.Id from tblSmCustomField c
	inner join tblSmCustomFieldEntity e
	on c.Id=e.FieldId
	
	DECLARE @FieldName varchar(50)
	DECLARE @FieldId int
	SELECT @FieldName = ''EDIGeneratedYN''
	SELECT @FieldId = ISNULL(Id,'''') FROM dbo.tblSmCustomField WHERE FieldName = @FieldName
	IF @FieldId <> ''''
	BEGIN
		DELETE FROM dbo.tblSmCustomFieldEntity WHERE FieldId = @FieldId
		DELETE FROM dbo.tblSmCustomField WHERE Id = @FieldId
	END
		INSERT INTO dbo.tblSmCustomField
			([FieldName],[Definition])
		VALUES
			(@FieldName
			,''<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>YesNo</FieldType><Description>Generated Yes/No</Description><Required>false</Required><MaxLength>0</MaxLength><LimitToList>false</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /></CustomField>'')
	SELECT @FieldName = ''EDIGeneratedYN''
	SELECT @FieldId = ISNULL(Id,'''') FROM dbo.tblSmCustomField WHERE FieldName = @FieldName
		INSERT INTO dbo.tblSmCustomFieldEntity
			(FieldId, Layout, EntityName)
		VALUES
			(@FieldId, null, ''tblARHistHeader'')
		INSERT INTO dbo.tblSmCustomFieldEntity
			(FieldId, Layout, EntityName)
		VALUES
			(@FieldId, null, ''tblSOTransheader'')
	go
	exec dbo.trav_DSViewRebuildAll_proc
	go
	
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
	--------------------------------------------------------------------------
		-- EDIDCCode
	
	
	
	select * from tblSmCustomField
	select c.Id,c.FieldName,e.EntityName,e.FieldId,e.Id from tblSmCustomField c
	inner join tblSmCustomFieldEntity e
	on c.Id=e.FieldId
	
	DECLARE @FieldName varchar(50)
	DECLARE @FieldId int
	SELECT @FieldName = ''EDIDCCode''
	SELECT @FieldId = ISNULL(Id,'''') FROM dbo.tblSmCustomField WHERE FieldName = @FieldName
	IF @FieldId <> ''''
	BEGIN
		DELETE FROM dbo.tblSmCustomFieldEntity WHERE FieldId = @FieldId
		DELETE FROM dbo.tblSmCustomField WHERE Id = @FieldId
	END
		INSERT INTO dbo.tblSmCustomField
			([FieldName],[Definition])
		VALUES
			(@FieldName
			,''<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>Text</FieldType><Description>EDI DC Code</Description><Required>false</Required><MaxLength>24</MaxLength><LimitToList>false</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /></CustomField>'')
	SELECT @FieldName = ''EDIDCCode''
	SELECT @FieldId = ISNULL(Id,'''') FROM dbo.tblSmCustomField WHERE FieldName = @FieldName
		INSERT INTO dbo.tblSmCustomFieldEntity
			(FieldId, Layout, EntityName)
		VALUES
			(@FieldId, null, ''tblARHistHeader'')
		INSERT INTO dbo.tblSmCustomFieldEntity
			(FieldId, Layout, EntityName)
		VALUES
			(@FieldId, null, ''tblSOTransheader'')
	go
	exec dbo.trav_DSViewRebuildAll_proc
	go
	
	
	
	
	
	/********************************************************************
	 *
	 *
	 *
						Setup Company-Specific Tables
								with data
																		*
																		*
																		*
	 ********************************************************************/
	
	/****** Object:  Table [dbo].[tblEdPartner]    Script Date: 12/10/2014 14:45:41 ******/
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
		[DfltItemUirType] [smallint] NULL,
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
		[SendBlankVdsAsnYN] [bit] NULL,
		[ReqProNumYN] [bit] NULL,
		[ReqExpDelDateYN] [bit] NULL,
		[OptReqProNumYN] [bit] NULL,
		[OptReqExpDelDateYN] [bit] NULL,
		[optSendCancelASNYn] [bit] NULL,
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
	ALTER TABLE [dbo].[tblEdPartner] ADD  DEFAULT ((1)) FOR [OptReqDeptYN]
	GO
	ALTER TABLE [dbo].[tblEdPartner] ADD  DEFAULT ((0)) FOR [OptAllowPoChangesYN]
	GO
	ALTER TABLE [dbo].[tblEdPartner] ADD  DEFAULT ((0)) FOR [optUseInvPrice]
	GO
	ALTER TABLE [dbo].[tblEdPartner] ADD  DEFAULT ((0)) FOR [OptSumAsnYN]
	GO
	ALTER TABLE [dbo].[tblEdPartner] ADD  DEFAULT ((0)) FOR [optUseUomXrefYN]
	GO
	ALTER TABLE [dbo].[tblEdPartner] ADD  DEFAULT ((0)) FOR [OptAsnRequireAllSoLines]
	GO
	ALTER TABLE [dbo].[tblEdPartner] ADD  DEFAULT ((0)) FOR [SendBlankVdsAsnYN]
	GO
	ALTER TABLE [dbo].[tblEdPartner] ADD  DEFAULT ((0)) FOR [ReqProNumYN]
	GO
	ALTER TABLE [dbo].[tblEdPartner] ADD  DEFAULT ((0)) FOR [ReqExpDelDateYN]
	GO
	ALTER TABLE [dbo].[tblEdPartner] ADD  DEFAULT ((0)) FOR [OptReqProNumYN]
	GO
	ALTER TABLE [dbo].[tblEdPartner] ADD  DEFAULT ((0)) FOR [OptReqExpDelDateYN]
	GO
	ALTER TABLE [dbo].[tblEdPartner] ADD  DEFAULT ((0)) FOR [optSendCancelASNYn]
	GO
	
	
	
	/****** Object:  Table [dbo].[tblEdPartnerDoc]    Script Date: 12/10/2014 14:48:44 ******/
	SET ANSI_NULLS ON
	GO
	SET QUOTED_IDENTIFIER ON
	GO
	SET ANSI_PADDING ON
	GO
	CREATE TABLE [dbo].[tblEdPartnerDoc](
		[PartnerID] [dbo].[pPartnerID] NOT NULL,
		[DocID] [varchar](3) NOT NULL,
		[MailQual] [varchar](2) NOT NULL,
		[MailID] [varchar](15) NOT NULL,
		[Version] [varchar](10) NOT NULL,
		[ContactName] [varchar](50) NULL,
		[ContactPhone] [varchar](15) NULL,
		[StartDate] [datetime] NULL,
		[TestDate] [datetime] NULL,
		[ProductionDate] [datetime] NULL,
		[Inbound] [bit] NOT NULL,
		[Active] [bit] NOT NULL,
		[Production] [bit] NOT NULL,
		[DatabasePath] [varchar](250) NULL,
		[Passwd] [varchar](20) NULL,
		[VDPCode] [varchar](20) NULL,
	 CONSTRAINT [PK_tblEDPartnerDoc] PRIMARY KEY CLUSTERED 
	(
		[PartnerID] ASC,
		[DocID] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
	GO
	SET ANSI_PADDING OFF
	GO
	ALTER TABLE [dbo].[tblEdPartnerDoc] ADD  DEFAULT ((1)) FOR [Inbound]
	GO
	
	
	
	/****** Object:  Table [dbo].[tblEdDocument]    Script Date: 12/10/2014 14:50:55 ******/
	SET ANSI_NULLS ON
	GO
	SET QUOTED_IDENTIFIER ON
	GO
	SET ANSI_PADDING ON
	GO
	CREATE TABLE [dbo].[tblEdDocument](
		[DocID] [varchar](3) NOT NULL,
		[DocAbbr] [varchar](3) NULL,
		[DocDesc] [varchar](50) NULL,
		[FaYn] [bit] NULL,
		[RunCommand] [varchar](50) NULL,
		[InboundOutbound] [varchar](1) NULL,
	PRIMARY KEY CLUSTERED 
	(
		[DocID] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
	GO
	SET ANSI_PADDING OFF
	GO
	
	
	
	/****** Object:  Table [dbo].[tblEdMailControl]    Script Date: 12/10/2014 14:52:03 ******/
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
	
	
	
	/****** Object:  Table [dbo].[tblEdMapSchema]    Script Date: 12/10/2014 14:52:51 ******/
	SET ANSI_NULLS ON
	GO
	SET QUOTED_IDENTIFIER ON
	GO
	SET ANSI_PADDING ON
	GO
	CREATE TABLE [dbo].[tblEdMapSchema](
		[DocId] [varchar](3) NOT NULL,
		[Version] [varchar](10) NOT NULL,
		[RecType] [varchar](50) NOT NULL,
		[TableName] [varchar](50) NULL,
		[TableFields] [varchar](1000) NULL,
		[FileCols] [varchar](1000) NULL,
		[RecLevel] [smallint] NULL,
		[AutoKey] [bit] NULL,
		[UpdateYn] [bit] NULL,
		[AutoKeyNum] [smallint] NULL,
	 CONSTRAINT [PK_tblEdMapSchema] PRIMARY KEY CLUSTERED 
	(
		[DocId] ASC,
		[Version] ASC,
		[RecType] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
	GO
	SET ANSI_PADDING OFF
	GO
	ALTER TABLE [dbo].[tblEdMapSchema] ADD  DEFAULT ((0)) FOR [RecLevel]
	GO
	ALTER TABLE [dbo].[tblEdMapSchema] ADD  CONSTRAINT [DF_tblEdMapSchema_UpdateYn]  DEFAULT ((0)) FOR [UpdateYn]
	GO
	
	
	
	/****** Object:  Table [dbo].[tblEdPartnerItemXref]    Script Date: 12/10/2014 14:53:47 ******/
	SET ANSI_NULLS ON
	GO
	SET QUOTED_IDENTIFIER ON
	GO
	SET ANSI_PADDING ON
	GO
	CREATE TABLE [dbo].[tblEdPartnerItemXref](
		[PartnerId] [varchar](50) NOT NULL,
		[ItemId] [varchar](20) NOT NULL,
		[ItemUom] [dbo].[pUom] NOT NULL,
		[ItemRef] [varchar](50) NULL,
		[ts] [timestamp] NOT NULL,
		[ItemUomXref] [varchar](20) NULL,
		[ItemRef2] [varchar](50) NULL,
	 CONSTRAINT [PK_tblEdPartnerItemXref] PRIMARY KEY CLUSTERED 
	(
		[PartnerId] ASC,
		[ItemId] ASC,
		[ItemUom] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
	GO
	SET ANSI_PADDING OFF
	GO
	
	
	
	/****** Object:  Table [dbo].[tblEdComm]    Script Date: 12/10/2014 14:54:43 ******/
	SET ANSI_NULLS ON
	GO
	SET QUOTED_IDENTIFIER ON
	GO
	SET ANSI_PADDING ON
	GO
	CREATE TABLE [dbo].[tblEdComm](
		[Id] [int] IDENTITY(1,1) NOT NULL,
		[DocType] [varchar](50) NULL,
		[PostRun] [dbo].[pPostRun] NOT NULL,
		[DocKey] [varchar](50) NULL,
	PRIMARY KEY CLUSTERED 
	(
		[Id] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
	GO
	SET ANSI_PADDING OFF
	GO
	
	
	
	/****** Object:  Table [dbo].[tblEdUCC128Label]    Script Date: 12/10/2014 1:43:13 PM ******/
	SET ANSI_NULLS ON
	GO
	SET QUOTED_IDENTIFIER ON
	GO
	SET ANSI_PADDING ON
	GO
	CREATE TABLE [dbo].[tblEdUCC128Label](
		[ID] [int] IDENTITY(1,1) NOT NULL,
		[UCC128] [varchar](20) NOT NULL,
		[BOL] [varchar](50) NULL,
		[ShipToName] [varchar](35) NULL,
		[ShipToAddress1] [varchar](50) NULL,
		[ShipToAddress2] [varchar](50) NULL,
		[ShipToCity] [varchar](35) NULL,
		[ShipToRegion] [varchar](50) NULL,
		[ShipToZip] [varchar](50) NULL,
		[ShipFromName] [varchar](35) NULL,
		[ShipFromAddress1] [varchar](50) NULL,
		[ShipFromAddress2] [varchar](50) NULL,
		[ShipFromCity] [varchar](35) NULL,
		[ShipFromRegion] [varchar](50) NULL,
		[ShipFromZip] [varchar](50) NULL,
		[UPCCode] [varchar](50) NULL,
		[ProductDesc] [varchar](50) NULL,
		[StoreCode] [varchar](6) NULL,
		[DCCode] [varchar](6) NULL,
		[StoreName] [varchar](35) NULL,
		[CarrierName] [varchar](35) NULL,
		[SCAC] [varchar](50) NULL,
		[ContainerID] [int] NULL,
		[CustPONum] [varchar](50) NULL,
		[Dept] [varchar](25) NULL,
		[VendorNum] [varchar](25) NULL,
		[DeptDesc] [varchar](25) NULL,
		[printdate] [datetime] NULL,
		[PartnerID] [varchar](12) NULL,
		[TransId] [dbo].[pTransID] NOT NULL,
		[PickListNum] [varchar](50) NULL,
		[ContainersInShipment] [int] NULL,
		[ContainerSeq] [int] NULL,
		[ItemInContainer] [int] NULL,
		[UserId] [dbo].[pUserID] NOT NULL,
		[WrkStnId] [dbo].[pWrkStnID] NOT NULL,
		[ASNNumber] [varchar](50) NULL,
		[ItemBuyerCode] [varchar](50) NULL,
		[ItemVendorCode] [varchar](50) NULL,
		[CartonWeight] [varchar](10) NULL,
	 CONSTRAINT [PK_tblEdUCC128Label] PRIMARY KEY CLUSTERED 
	(
		[ID] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]
	GO
	SET ANSI_PADDING OFF
	GO
	
	
	
	/****** Object:  Table [dbo].[tblEdPoHeader]    Script Date: 12/10/2014 16:21:41 ******/
	SET ANSI_NULLS ON
	GO
	SET QUOTED_IDENTIFIER ON
	GO
	SET ANSI_PADDING ON
	GO
	CREATE TABLE [dbo].[tblEdPoHeader](
		[ID] [int] IDENTITY(1,1) NOT NULL,
		[ImportBatchId] [varchar](14) NULL,
		[PartnerID] [varchar](50) NULL,
		[SenderId] [varchar](50) NULL,
		[CustPoNum] [varchar](50) NULL,
		[PoDate] [varchar](50) NULL,
		[PurposeCode] [varchar](50) NULL,
		[TypeCode] [varchar](50) NULL,
		[StartShipDate] [varchar](50) NULL,
		[CancelShipDate] [varchar](50) NULL,
		[ContactName] [varchar](50) NULL,
		[ContactPhone] [varchar](50) NULL,
		[BuyerName] [varchar](50) NULL,
		[BuyerPhone] [varchar](50) NULL,
		[DepartmentID] [varchar](50) NULL,
		[MerchandiseTypeCode] [varchar](50) NULL,
		[ShipToCode] [varchar](50) NULL,
		[ShipToName] [varchar](50) NULL,
		[ShipToAddr1] [varchar](50) NULL,
		[ShipToAddr2] [varchar](50) NULL,
		[ShipToCity] [varchar](50) NULL,
		[ShipToRegion] [varchar](50) NULL,
		[ShipToCountry] [varchar](50) NULL,
		[ShipToPostalCode] [varchar](50) NULL,
		[BillToCode] [varchar](50) NULL,
		[BillToName] [varchar](50) NULL,
		[BillToAddr1] [varchar](50) NULL,
		[BillToAddr2] [varchar](50) NULL,
		[BillToCity] [varchar](50) NULL,
		[BillToRegion] [varchar](50) NULL,
		[BillToCountry] [varchar](50) NULL,
		[BillToPostalCode] [varchar](50) NULL,
		[TermsBasisDateCode] [varchar](50) NULL,
		[TermsDescr] [varchar](50) NULL,
		[TermsDiscDaysDue] [varchar](50) NULL,
		[TermsDiscPct] [varchar](50) NULL,
		[TermsDiscDueDate] [varchar](50) NULL,
		[TermsNetDays] [varchar](50) NULL,
		[TermsNetDueDate] [varchar](50) NULL,
		[TermsTypeCode] [varchar](50) NULL,
		[Duns] [varchar](50) NULL,
		[BackOrderAllowedYN] [varchar](50) NULL,
		[ShipAsapYN] [varchar](50) NULL,
		[ShipToStoreYN] [varchar](50) NULL,
		[UDF1] [varchar](50) NULL,
		[UDF2] [varchar](50) NULL,
		[UDF3] [varchar](50) NULL,
		[UDF4] [varchar](50) NULL,
		[UDF5] [varchar](50) NULL,
		[IsNew] [bit] NULL,
		[ErrorCode] [int] NOT NULL,
		[ReqAcknlYN] [bit] NULL,
		[PoStatus] [smallint] NULL,
		[sMessage] [varchar](255) NULL,
		[ProdGroup] [varchar](30) NULL,
		[PurchasingVendor] [varchar](50) NULL,
		[ShipCarrier] [varchar](50) NULL,
		[ShipCode] [varchar](50) NULL,
		[ShipNote] [varchar](50) NULL,
		[VDPStore] [varchar](50) NULL,
		[FDOStore] [varchar](50) NULL,
		[ShipToAttn] [varchar](50) NULL,
	 CONSTRAINT [PK_tblEdPoHeader_1] PRIMARY KEY CLUSTERED 
	(
		[ID] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
	GO
	SET ANSI_PADDING OFF
	GO
	ALTER TABLE [dbo].[tblEdPoHeader] ADD  CONSTRAINT [DF_tblEdPoHeader_ErrorCode]  DEFAULT ((0)) FOR [ErrorCode]
	GO
	ALTER TABLE [dbo].[tblEdPoHeader] ADD  DEFAULT ((0)) FOR [ReqAcknlYN]
	GO
	
	
	
	/****** Object:  Table [dbo].[tblEdPoDetail]    Script Date: 12/10/2014 16:21:48 ******/
	SET ANSI_NULLS ON
	GO
	SET QUOTED_IDENTIFIER ON
	GO
	SET ANSI_PADDING ON
	GO
	CREATE TABLE [dbo].[tblEdPoDetail](
		[ID] [int] IDENTITY(1,1) NOT NULL,
		[ImportBatchId] [varchar](14) NULL,
		[PartnerId] [varchar](50) NULL,
		[SenderId] [varchar](50) NULL,
		[CustPoNum] [varchar](50) NULL,
		[EntryNum] [varchar](50) NULL,
		[PoLineNum] [varchar](50) NULL,
		[StoreNum] [varchar](50) NULL,
		[QtyOrd] [dbo].[pDec] NOT NULL,
		[UnitsSell] [varchar](50) NULL,
		[UnitPrice] [dbo].[pDec] NOT NULL,
		[RetailPrice] [varchar](50) NULL,
		[QtyPack] [varchar](50) NULL,
		[UnitsPack] [varchar](50) NULL,
		[ItemUir] [varchar](50) NULL,
		[ItemBuyerCode] [varchar](50) NULL,
		[ItemVendorCode] [varchar](50) NULL,
		[ItemUpc] [varchar](50) NULL,
		[ItemID] [varchar](50) NULL,
		[ItemDecr] [varchar](50) NULL,
		[ColorDescr] [varchar](50) NULL,
		[SizeDescr] [varchar](50) NULL,
		[UDF1] [varchar](50) NULL,
		[UDF2] [varchar](50) NULL,
		[UDF3] [varchar](50) NULL,
		[UDF4] [varchar](50) NULL,
		[UDF5] [varchar](50) NULL,
		[IsNew] [bit] NULL,
		[ErrorCode] [int] NOT NULL,
		[UnitsSellPO] [varchar](50) NULL,
		[ManufTypeCode] [varchar](20) NULL,
	 CONSTRAINT [PK_tblEdPoDetail_1] PRIMARY KEY CLUSTERED 
	(
		[ID] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
	GO
	SET ANSI_PADDING OFF
	GO
	ALTER TABLE [dbo].[tblEdPoDetail] ADD  CONSTRAINT [DF_tblEdPoDetail_ErrorCode]  DEFAULT ((0)) FOR [ErrorCode]
	GO
	
	
	
	/****** Object:  Table [dbo].[tblEdPoHistHeader]    Script Date: 12/10/2014 14:59:13 ******/
/*	SET ANSI_NULLS ON
	GO
	SET QUOTED_IDENTIFIER ON
	GO
	SET ANSI_PADDING ON
	GO
	CREATE TABLE [dbo].[tblEdPoHistHeader](
		[PostRun] [dbo].[pPostRun] NOT NULL,
		[PartnerID] [varchar](50) NOT NULL,
		[CustPoNum] [varchar](50) NOT NULL,
		[ImportBatchId] [varchar](14) NOT NULL,
		[PoDate] [varchar](50) NULL,
		[PurposeCode] [varchar](50) NULL,
		[TypeCode] [varchar](50) NULL,
		[StartShipDate] [varchar](50) NULL,
		[CancelShipDate] [varchar](50) NULL,
		[ContactName] [varchar](50) NULL,
		[ContactPhone] [varchar](50) NULL,
		[BuyerName] [varchar](50) NULL,
		[BuyerPhone] [varchar](50) NULL,
		[DepartmentID] [varchar](50) NULL,
		[MerchandiseTypeCode] [varchar](50) NULL,
		[ShipToCode] [varchar](50) NULL,
		[ShipToName] [varchar](50) NULL,
		[ShipToAddr1] [varchar](50) NULL,
		[ShipToAddr2] [varchar](50) NULL,
		[ShipToCity] [varchar](50) NULL,
		[ShipToRegion] [varchar](50) NULL,
		[ShipToCountry] [varchar](50) NULL,
		[ShipToPostalCode] [varchar](50) NULL,
		[BillToCode] [varchar](50) NULL,
		[BillToName] [varchar](50) NULL,
		[BillToAddr1] [varchar](50) NULL,
		[BillToAddr2] [varchar](50) NULL,
		[BillToCity] [varchar](50) NULL,
		[BillToRegion] [varchar](50) NULL,
		[BillToCountry] [varchar](50) NULL,
		[BillToPostalCode] [varchar](50) NULL,
		[TermsBasisDateCode] [varchar](50) NULL,
		[TermsDescr] [varchar](50) NULL,
		[TermsDiscDaysDue] [varchar](50) NULL,
		[TermsDiscPct] [varchar](50) NULL,
		[TermsDiscDueDate] [varchar](50) NULL,
		[TermsNetDays] [varchar](50) NULL,
		[TermsNetDueDate] [varchar](50) NULL,
		[TermsTypeCode] [varchar](50) NULL,
		[Duns] [varchar](50) NULL,
		[BackOrderAllowedYN] [varchar](50) NULL,
		[ShipAsapYN] [varchar](50) NULL,
		[ShipToStoreYN] [varchar](50) NULL,
		[UDF1] [varchar](50) NULL,
		[UDF2] [varchar](50) NULL,
		[UDF3] [varchar](50) NULL,
		[UDF4] [varchar](50) NULL,
		[UDF5] [varchar](50) NULL,
		[IsNew] [bit] NULL,
		[ErrorCode] [int] NOT NULL,
		[ReqAcknlYN] [bit] NULL,
		[PoStatus] [smallint] NULL,
		[sMessage] [varchar](255) NULL,
		[ProdGroup] [varchar](30) NULL,
		[PurchasingVendor] [varchar](50) NULL,
		[ShipCarrier] [varchar](50) NULL,
		[ShipCode] [varchar](50) NULL,
		[ShipNote] [varchar](50) NULL,
		[VDPStore] [varchar](50) NULL,
		[FDOStore] [varchar](75) NULL,
		[ShipToAttn] [varchar](50) NULL,
	 CONSTRAINT [PK_tblEdPoHistHeader] PRIMARY KEY CLUSTERED 
	(
		[PostRun] ASC,
		[PartnerID] ASC,
		[CustPoNum] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
	GO
	SET ANSI_PADDING OFF
	GO
	ALTER TABLE [dbo].[tblEdPoHistHeader] ADD  DEFAULT ((0)) FOR [ReqAcknlYN]
	GO
*/	
	
	
	/****** Object:  Table [dbo].[tblEdPoHistDetail]    Script Date: 12/10/2014 15:00:25 ******/
/*	SET ANSI_NULLS ON
	GO
	SET QUOTED_IDENTIFIER ON
	GO
	SET ANSI_PADDING ON
	GO
	CREATE TABLE [dbo].[tblEdPoHistDetail](
		[PostRun] [dbo].[pPostRun] NOT NULL,
		[PartnerId] [varchar](50) NOT NULL,
		[CustPoNum] [varchar](50) NOT NULL,
		[EntryNum] [varchar](50) NOT NULL,
		[ImportBatchId] [varchar](14) NOT NULL,
		[PoLineNum] [varchar](50) NULL,
		[StoreNum] [varchar](50) NULL,
		[QtyOrd] [varchar](50) NULL,
		[UnitsSell] [varchar](50) NULL,
		[UnitPrice] [varchar](50) NULL,
		[RetailPrice] [varchar](50) NULL,
		[QtyPack] [varchar](50) NULL,
		[UnitsPack] [varchar](50) NULL,
		[ItemUir] [varchar](50) NULL,
		[ItemBuyerCode] [varchar](50) NULL,
		[ItemVendorCode] [varchar](50) NULL,
		[ItemUpc] [varchar](50) NULL,
		[ItemDecr] [varchar](50) NULL,
		[ColorDescr] [varchar](50) NULL,
		[SizeDescr] [varchar](50) NULL,
		[UDF1] [varchar](50) NULL,
		[UDF2] [varchar](50) NULL,
		[UDF3] [varchar](50) NULL,
		[UDF4] [varchar](50) NULL,
		[UDF5] [varchar](50) NULL,
		[IsNew] [bit] NULL,
		[ErrorCode] [int] NOT NULL,
		[itemID] [dbo].[pItemID] NULL,
		[SoTransid] [dbo].[pTransID] NOT NULL,
		[UnitsSellPO] [varchar](50) NULL,
		[ManufTypeCode] [varchar](20) NULL,
	 CONSTRAINT [PK_tblEdPoHistdetail] PRIMARY KEY CLUSTERED 
	(
		[PostRun] ASC,
		[PartnerId] ASC,
		[CustPoNum] ASC,
		[EntryNum] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	)ON [PRIMARY]
	GO
	SET ANSI_PADDING OFF
	GO
*/	
	
	
	/****** Object:  Table [dbo].[tblEdLabelTemplates]    Script Date: 12/10/2014 15:02:21 ******/
	SET ANSI_NULLS ON
	GO
	SET QUOTED_IDENTIFIER ON
	GO
	SET ANSI_PADDING ON
	GO
	CREATE TABLE [dbo].[tblEdLabelTemplates](
		[LblName] [varchar](12) NOT NULL,
		[lblType] [varchar](12) NOT NULL,
		[Descr] [varchar](50) NULL,
		[LblTemplatePath] [varchar](500) NULL,
		[LblParameters] [varchar](50) NULL,
		[LblAppID] [varchar](12) NULL,
	 CONSTRAINT [PK_tblEdLabelTemplates] PRIMARY KEY CLUSTERED 
	(
		[LblName] ASC,
		[lblType] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
	GO
	SET ANSI_PADDING OFF
	GO
	
	
	
	
	/***************************************************************************
	 ***************************************************************************
	 ***************************************************************************
	 ****** Populate Tables With Data    Script Date: 12/10/2014 15:02:21 ******
	 ***************************************************************************
	 ***************************************************************************
	 ***************************************************************************/
	
	
	
	INSERT INTO [dbo].[tblEdDocument] (DocID, DocAbbr, DocDesc, FaYn, RunCommand, InboundOutbound)
	VALUES
	(''810'', ''IN'', ''Invoice'', 1, ''INEX'', ''O''),
	(''832'', ''SC'', ''Sales Catalo'', 0, NULL, ''O''),
	(''846'', ''II'', ''Inventory Inquiry'', 0, ''IIEX'', ''O''),
	(''850'', ''PO'', ''Purchase Order'', 1, ''POIN'', ''I''),
	(''852'', ''PD'', ''Product Data'', 0, ''PDIN'', ''I''),
	(''855'', ''ACK'', ''PO Acknowledgement'', 0, NULL, ''O''),
	(''856'', ''SH'', ''Advanced Ship Notice'', 1, NULL, ''O''),
	(''860'', ''POC'', ''PO Change'', 0, NULL, ''O''),
	(''864'', ''TX'', ''Text Message'', 0, ''TXIN'', ''I''),
	(''997'', ''FA'', ''Fa'', 0, NULL, ''I'');
	
	INSERT INTO [dbo].[tblEdMapSchema] (DocId, Version, RecType, TableName, TableFields, FileCols, RecLevel, AutoKey, UpdateYn, AutoKeyNum)
	VALUES
	(''850'', ''4030'', ''CTRL'', ''tblEdMailControl'', ''DocType,DocKey,SenderID,ReceiverID,ISAControlNum,GSControlNum,STControlNum,GSVersion,StatusFlag,SendDate'', ''2,3,4,5,6,7,8,9,10,11'', 0, 0, 0, NULL),
	(''850'', ''4030'', ''HDR1'', ''tblEdPoHeader'', ''SenderId,CustPoNum,PoDate,PurposeCode,TypeCode,StartShipDate,CancelShipDate,ContactName,ContactPhone,BuyerName,BuyerPhone,DepartmentID,MerchandiseTypeCode,ShipToCode,ShipToName,ShipToAddr1,ShipToAddr2,ShipToCity,ShipToRegion,ShipToCountry,ShipToPostalCode,BillToCode,BillToName,BillToAddr1,BillToAddr2,BillToCity,BillToRegion,BillToCountry,BillToPostalCode,TermsBasisDateCode,TermsDescr,TermsDiscDaysDue,TermsDiscPct,TermsDiscDueDate,TermsNetDays,TermsNetDueDate,TermsTypeCode,Duns,BackOrderAllowedYN,ShipAsapYN,ShipToStoreYN,UDF1,UDF2,UDF3,UDF4,UDF5,sMessage,ProdGroup,ShipCarrier,ShipCode,ShipNote,VDPStore,FDOStore'', ''2,3,4,5,6,7,8,9,10,11,12,13,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,53,54,55,56,57'', 1, 0, 0, NULL),
	(''850'', ''4030'', ''LINE'', ''tblEdPoDetail'', ''SenderId,CustPoNum,EntryNum,PoLineNum,StoreNum,QtyOrd,UnitsSellPO,UnitPrice,RetailPrice,QtyPack,UnitsPack,ItemBuyerCode,ItemVendorCode,ItemUpc,ItemDecr,ColorDescr,SizeDescr,UDF1,UDF2,UDF3,UDF4,UDF5,ManufTypeCode'', ''2,3,4,5,6,N7,8,N9,10,11,12,14,15,16,17,18,19,20,21,22,23,24,25'', 2, 0, 0, NULL);
	
	
	
	
	
	
	/***************************************************************************
	 ***************************************************************************
	 ***************************************************************************
	 ****** Create Stored Procedures     Script Date: 12/10/2014 15:02:21 ******
	 ***************************************************************************
	 ***************************************************************************
	 ***************************************************************************/
	 
	 
	IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N''[dbo].[csi_EdPoValidateUpdate_proc]'') AND OBJECTPROPERTY(id, N''IsProcedure'') = 1)
		DROP PROCEDURE [dbo].[csi_EdPoValidateUpdate_proc]
	GO
	/****** Object:  StoredProcedure [dbo].[csi_EdPoValidateUpdate_proc]    Script Date: 12/10/2014 17:38:51 ******/
	SET ANSI_NULLS ON
	GO
	SET QUOTED_IDENTIFIER ON
	GO
	CREATE PROC [dbo].[csi_EdPoValidateUpdate_proc]
		@CustPoNum VARCHAR (75) =''''
		AS
			SET NOCOUNT ON
BEGIN TRY 
		DECLARE @MailID       VARCHAR(15),
				@PartnerID    VARCHAR(12),
				@CustID       VARCHAR(12)
		CREATE TABLE #tMailId (MailId VARCHAR(15))
		INSERT INTO #tMailId (MailId)
		SELECT DISTINCT MailID 
		FROM tblEdPoHeader
		DECLARE  cur CURSOR FOR      
			SELECT MailId FROM #tMailId
		OPEN cur
		   FETCH NEXT FROM cur INTO  @MailID
			-- Loop Records
			WHILE (@@FETCH_STATUS=0)      
			BEGIN
			   EXEC [dbo].[csi_EdGetCustIdFromMailId_proc]  ''850'',@MailId,'''',@PartnerId OUT ,@CustID OUT     
			   UPDATE [dbo].[tblEdPoHeader] SET PartnerID=@PartnerID, CustID=@CustID 
			   WHERE MailId=@MailID
			   FETCH NEXT FROM cur INTO  @MailID 
			END       
			CLOSE cur      
			DEALLOCATE cur
	   /*
	   SELECT 
	   FROM tblEdPoHeader h
	   INNER JOIN tblEdPoDetail d ON h.ImportBatchId=d.ImportBatchId AND h.KeyLevelSeq1=d.KeyLevelSeq1
	   -- get CustId 
		v.PartnerId,o.OptCode,v.OptValue
		SELECT * FROM [dbo].[tblEdPoHeader]
		(EXEC csi_EdGetPartnerDocOptions @OptCode=''GenDfltUIRType'') 
	[dbo].[csi_EdGetCustIdFromMailId_proc]
	*/
	END TRY
BEGIN CATCH
      EXEC dbo.trav_RaiseError_proc
END CATCH
	GO
	
	
	
	
	
	
	
	IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N''[dbo].[csi_EdPoValidate_proc]'') AND OBJECTPROPERTY(id, N''IsProcedure'') = 1)
		DROP PROCEDURE [dbo].[csi_EdPoValidate_proc]
	GO
	/****** Object:  StoredProcedure [dbo].[csi_EdPoValidate_proc]    Script Date: 12/10/2014 17:14:31 ******/
	SET ANSI_NULLS ON
	GO
	SET QUOTED_IDENTIFIER ON
	GO
	ALTER PROC [dbo].[csi_EdPoValidate_proc] 
		  @ImportBatchId        VARCHAR(14) = '''',
		  @TotalKeys            INT   =0       OUT,
		  @TotalKeysValid       INT   =0       OUT, 
		  @TotalKeysError       INT   =0       OUT,  
		  @TotalKeysWarning     INT   =0       OUT,
		  @TotalRows            INT   =0       OUT
	AS
	SET NOCOUNT ON
BEGIN TRY 
		EXEC csi_EdPoValidateUpdate_proc
		SELECT @TotalKeys         = SUM(TotalKeys),
			   @TotalKeysValid    = SUM(TotalKeysValid),
			   @TotalKeysError    = SUM( TotalKeysError),
			   @TotalKeysWarning  = SUM(TotalKeysWarning) 
		FROM  (SELECT 1 TotalKeys,
				  CASE WHEN h.ErrorCode =0 THEN 1 ELSE 0 END TotalKeysValid, 
				  CASE WHEN h.ErrorCode =1 THEN 1 ELSE 0 END TotalKeysWarning, 
				  CASE WHEN h.ErrorCode >1 THEN 1 ELSE 0 END TotalKeysError
				  FROM tblEdPoHeader h
				  WHERE ImportBatchId=@ImportBatchId) s
	   SELECT @TotalKeys         = ISNULL(@TotalKeys,0),
			   @TotalKeysValid   = ISNULL(@TotalKeysValid,0),
			   @TotalKeysError   = ISNULL(@TotalKeysError,0),
			   @TotalKeysWarning =ISNULL(@TotalKeysWarning,0)
			   		  END TRY
BEGIN CATCH
      EXEC dbo.trav_RaiseError_proc
END CATCH
			   	GO
	
	
	
	
	
	
	
	
	IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N''[dbo].[csi_EdPoImportDtlLog_proc]'') AND OBJECTPROPERTY(id, N''IsProcedure'') = 1)
		DROP PROCEDURE [dbo].[csi_EdPoImportDtlLog_proc]
	GO
	/****** Object:  StoredProcedure [dbo].[csi_EdPoImportDtlLog_proc]    Script Date: 12/10/2014 17:14:30 ******/
	SET ANSI_NULLS ON
	GO
	SET QUOTED_IDENTIFIER ON
	GO
	ALTER Proc [dbo].[csi_EdPoImportDtlLog_proc]    @ImportBatchID varchar(14) ='''',     
													 @PartnerId varchar(20)=''''    
		AS
SET NOCOUNT ON
BEGIN TRY 
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
		  END TRY
BEGIN CATCH
      EXEC dbo.trav_RaiseError_proc
END CATCH
	GO
		
		
		
		
		
		
		IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N''[dbo].[csi_EdPoValidate_proc]'') AND OBJECTPROPERTY(id, N''IsProcedure'') = 1)
		DROP PROCEDURE [dbo].[csi_EdPoValidate_proc]
		GO
		/****** Object:  StoredProcedure [dbo].[csi_EdPoValidate_proc]    Script Date: 12/11/2014 16:56:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[csi_EdPoValidate_proc] 
      @ImportBatchId        VARCHAR(14) = '''',
	  @TotalKeys            INT   =0       OUT,
	  @TotalKeysValid       INT   =0       OUT, 
	  @TotalKeysError       INT   =0       OUT,  
	  @TotalKeysWarning     INT   =0       OUT,
	  @TotalRows            INT   =0       OUT
AS  
SET NOCOUNT ON
BEGIN TRY
    --Err status 0=OK,1=Warning,2=Error Cont, 3 = Err Stop  
	DECLARE @ErrCode INT
    EXEC csi_EdPoValidateUpdate_proc @ImportBatchId
	CREATE TABLE #tHeader_1 (ImportBatchId VARCHAR(14),KeyLevelSeq1 INT)
	CREATE TABLE #tDetail_1 (ImportBatchId VARCHAR(14),KeyLevelSeq1 INT,KeyLevelSeq2 INT)
	CREATE TABLE #tDfltUIR_1 (PartnerId VARCHAR(20),OptKey VARCHAR(100), OptValue INT)
	DELETE FROM dbo.tblEdPoErrorlog    
	-- get partner UIR defaults
    INSERT INTO #tDfltUIR_1  EXEC csi_EdGetPartnerDocOptions '''',''GenDfltUIRType''
	-- select headers
    INSERT INTO #tHeader_1 (ImportBatchId,KeyLevelSeq1 )
	SELECT ImportBatchId,KeyLevelSeq1
	FROM tblEdPoHeader 
	WHERE ISNULL(@ImportBatchId,'''')='''' OR ImportBatchId=@ImportBatchId
	--select details
	INSERT INTO #tDetail_1 (ImportBatchId,KeyLevelSeq1,KeyLevelSeq2)
	SELECT th.ImportBatchId,th.KeyLevelSeq1,d.KeyLevelSeq2
	FROM #tHeader_1 th
	INNER JOIN  tblEdPoDetail  d ON th.ImportBatchId =d.ImportBatchId AND th.KeyLevelSeq1=d.KeyLevelSeq1 
    SET @ErrCode=235      
    INSERT INTO dbo.tblEdPoErrorlog (ImportBatchId,KeyLevelSeq1,KeyLevelSeq2,PartnerId,CustPoNum ,LineNum, ErrCode,ErrDescr,ErrSequence,ErrRecType,ErrStatus,SkipValidationYN)   
    SELECT td.ImportBatchId,td.KeyLevelSeq1,td.KeyLevelSeq2,h.PartnerID,h.CustPoNum,d.PoLineNum,@ErrCode,''Rquired unique item reference ['' +ISNULL(uo.Descr,'''')+ ''] is missing from the PO'' ,0,''D'',2, 1                         
    FROM #tDetail_1 td                                                
    INNER JOIN dbo.tblEdPoDetail d (NOLOCK) ON td.ImportBatchId=d.ImportBatchId AND td.KeyLevelSeq1=d.KeyLevelSeq1 AND td.KeyLevelSeq2=d.KeyLevelSeq2
	INNER JOIN dbo.tblEdPoHeader h (NOLOCK) ON d.ImportBatchId=h.ImportBatchId AND h.KeyLevelSeq1=h.KeyLevelSeq1 
	LEFT JOIN #tDfltUIR_1 u ON h.PartnerID=d.PartnerId
	LEFT JOIN dbo.csi_EdPartnerUIROpt_view uo ON u.OptValue=uo.Id
    WHERE ISNULL(d.ItemUir,'''') = ''''      
	DELETE td
	FROM #tDetail_1 td
	INNER JOIN dbo.tblEdPoErrorlog l ON td.ImportBatchId=l.ImportBatchId AND td.KeyLevelSeq1=l.KeyLevelSeq1 AND td.KeyLevelSeq2=l.KeyLevelSeq2
	WHERE ISNULL(l.SkipValidationYN,0)=1
	select * from dbo.tblEdPoErrorlog
	SELECT @TotalKeys         = SUM(TotalKeys),
	       @TotalKeysValid    = SUM(TotalKeysValid),
		   @TotalKeysError    = SUM( TotalKeysError),
		   @TotalKeysWarning  = SUM(TotalKeysWarning) 
    FROM  (SELECT 1 TotalKeys,
	          CASE WHEN h.ErrorCode =0 THEN 1 ELSE 0 END TotalKeysValid, 
		      CASE WHEN h.ErrorCode =1 THEN 1 ELSE 0 END TotalKeysWarning, 
		      CASE WHEN h.ErrorCode >1 THEN 1 ELSE 0 END TotalKeysError
	          FROM tblEdPoHeader h
	          WHERE ImportBatchId=@ImportBatchId) s
   SELECT @TotalKeys         = ISNULL(@TotalKeys,0),
	       @TotalKeysValid   = ISNULL(@TotalKeysValid,0),
		   @TotalKeysError   = ISNULL(@TotalKeysError,0),
		   @TotalKeysWarning =ISNULL(@TotalKeysWarning,0)
END TRY
BEGIN CATCH
      EXEC dbo.trav_RaiseError_proc
END CATCH
GO








	');
	



END
ELSE
BEGIN
	PRINT N'';
	PRINT N'';
	PRINT N'******************************************************************************************************************************';
	PRINT N'			Company is set to   '''+@company+'''   .';
	PRINT N'			Please set the @company variable to the Unique Traverse Client Company Database Name and Re-Run this script.';
	PRINT N'******************************************************************************************************************************';
	PRINT N'';
END





