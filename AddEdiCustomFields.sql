
DECLARE @company varchar(30); /* Also allowed: DECLARE @find varchar(30) = 'EDI'; */
/*******************************************************************
 ********* Peter Danshov - Add EDI Custom Fields *******************
 *******************************************************************
 *
 *		pdanshv@gmail.com 12.08.14
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

 -- TRUNCATE TABLE dbo.tblName; -- this deallocated the data pages used to store table data
 -- DELETE FROM table_name; or DELETE * FROM table_name; -- Deletes one row at a time, leaves more logs, takes more resources 
 
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
SET @company = 'EDI'; -- Set the company database here < < <- <- <-- <-- <--- <---
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------

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
(15, ''EDIMaxCartonValue'', ''<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>Number</FieldType><Description>Populated by EDI SO Generation; Manual Entry Also</Description><Required>false</Required><MaxLength>0</MaxLength><LimitToList>false</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /></CustomField>''),
(16, ''EDIMaxCartonWeight'', ''<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>Number</FieldType><Description>Populated by EDI SO Generation; Manual Entry Also</Description><Required>false</Required><MaxLength>0</MaxLength><LimitToList>false</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /></CustomField>''),
(17, ''EDIShipToType'', ''<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>Entity</FieldType><Description>Ship To Types: 0-Store, 1-DC, 2-Consolidator, 3-Drop Ship</Description><Required>false</Required><MaxLength>10</MaxLength><LimitToList>true</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /><LookupId>CSIEdiShipToType</LookupId></CustomField>''),
(18, ''EDIARStoreID'', ''<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>Entity</FieldType><Description>AR Ship To ID for a record withEDIShipToType=0</Description><Required>false</Required><MaxLength>50</MaxLength><LimitToList>false</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /><LookupId>CsiShipVia</LookupId></CustomField>''),
(19, ''EDIARDCID'', ''<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>Text</FieldType><Description>AR Ship To ID for a record withEDIShipToType=1</Description><Required>false</Required><MaxLength>50</MaxLength><LimitToList>false</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /></CustomField>''),
(20, ''EDIARConsolID'', ''<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>Text</FieldType><Description>AR Ship To ID for a record withEDIShipToType=2</Description><Required>false</Required><MaxLength>50</MaxLength><LimitToList>false</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /></CustomField>''),
(21, ''EDIStoreCode'', ''<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>Text</FieldType><Description>Populated by EDI SO Generation; Manual Entry Also</Description><Required>false</Required><MaxLength>50</MaxLength><LimitToList>false</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /></CustomField>''),
(22, ''EDIPOLineNum'', ''<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>Text</FieldType><Description>PO Line Number</Description><Required>false</Required><MaxLength>0</MaxLength><LimitToList>false</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /></CustomField>'');

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
(43, 22, ''tblSOTransDetail'', null);

SET IDENTITY_INSERT ['+@company+'].dbo.tblSmCustomFieldEntity OFF;
EXEC ['+@company+'].dbo.trav_DSViewRebuildAll_proc;
');

