


/*******************************************************************
 ********* Peter Danshov -	pdanshv@gmail.com 01.22.2015 ***********
 *******************************************************************
 *
 *		Add Partner Item Xref EDI Menu Record
 *		to Traverse Custom Screen Table
 *	
 *******************************************************************/
 
INSERT INTO [SYS].dbo.tblSmMenuCustom ( MenuId, Description, PluginName, AssemblyName )
VALUES ( '7690501', 'Partner/Item Cross-Reference', 'PartnerItemXrefPlugin', 'CSI.EDI.Client.PartnerItemXref.dll' );
 