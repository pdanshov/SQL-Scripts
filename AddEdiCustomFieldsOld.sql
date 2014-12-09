
/*******************************************************************
 ********* Peter Danshov - Add EDI Custom Fields *******************
 *******************************************************************
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
 *******************************************************************/
 
 INSERT INTO [I31].[dbo].[tblSmCustomField] (Id, FieldName, Definition)
 VALUES
 (default, 'EDISCAC', '<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>Text</FieldType><Description>SCAC Number</Description><Required>false</Required><MaxLength>4</MaxLength><LimitToList>false</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /></CustomField>'), /*'0x0000000000046D79'*/
 (default, 'EDITrackingNumYN', '<<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>YesNo</FieldType><Description>Use Tracking Number</Description><Required>false</Required><MaxLength>0</MaxLength><LimitToList>false</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /></CustomField>'),
 (default, 'EdiDistroId', '<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>Text</FieldType><Description>EdiDistroId</Description><Required>false</Required><MaxLength>24</MaxLength><LimitToList>false</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /></CustomField>'),
 (default, 'EdiMaxCartonValue', '<CustomField xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><FieldType>Number</FieldType><Description>EdiMaxCartonValue</Description><Required>false</Required><MaxLength>0</MaxLength><LimitToList>false</LimitToList><MinValue>0</MinValue><MaxValue>0</MaxValue><DropDownList /></CustomField>'),
 
 INSERT INTO [I31].[dbo].[tblSmCustomFieldEntry] (Id, FieldId, EntityName, Layout)
 VALUES
 (769, 'eng', 'EDI', default), /*'0x0000000000046D79'*/
 
