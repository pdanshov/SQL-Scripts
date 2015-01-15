


-----------------------------------------------------------------------------
--
--								Peter Danshov
--					pdanshv@gmail.com		01.14.2015
--		This script installs Ar Ship To custom form in TRAVERSE
--
--
-----------------------------------------------------------------------------

INSERT INTO [SYS].dbo.tblSmMenuCustom ( MenuId, Description, PluginName, AssemblyName )
VALUES ( '1100812', 'Custom SO Transaction (CSI)', 'CustomShipToPlugin', 'CSI.EDI.Client.CustomShipTo.dll' );

