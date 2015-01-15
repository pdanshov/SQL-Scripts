SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[fncUpdateCustomField]   
(   
   @xml as XML,   
   @FieldName as nvarchar(max),   
   @FieldValue as nvarchar(max)   
)   
RETURNS xml   
AS   
BEGIN   
--parse the list of values into a table for processing   
Declare @nodes Table ([Name] varchar(max), [Value] varchar(max))   
  
INSERT INTO @nodes ([Name], [Value])   
SELECT e.props.value('./Name[1]', 'VARCHAR(max)') as [Name]   
   , e.props.value('./Value[1]', 'VARCHAR(max)') as [Value]   
FROM @xml.nodes('/ArrayOfEntityPropertyOfString/EntityPropertyOfString') as e(props)   
WHERE (e.props.exist('Name') = 1) AND (e.props.exist('Value') = 1)   
            
--modify the data   
--   if the fieldvalue is blank delete the node   
--   if the fieldvalue is not blank and the node doesn't exist insert the node and value   
--  if the fieldvalue is not blank and the node already exists and is different from the passed fieldvalue update it   
  
if @FieldValue=''   
   DELETE @nodes Where [Name] = @FieldName   
else if (select COUNT(*) from @nodes where [Name]=@FieldName)=0   
   INSERT @nodes ([Name], [Value]) VALUES (@FieldName, @FieldValue)   
else   
   UPDATE @nodes Set [Value] = @FieldValue WHERE [Name] = @FieldName and [Value] <> @FieldValue   
  
--   
update @nodes set [Value] = replace([Value], '&', '&amp;') where [value] like '%&%'  --1110KSI - Errors occur xml if & is not changed to &amp;   
update @nodes set [value] = replace([value], '&amp;amp;', '&amp;') where [value] like '%&amp;amp;%'  --0311KSI - Removes duplicate if & was already changed to &amp;   
  
--reconstruct the XML string discarding any entries with a null/blank [Name] or [Value]   
DECLARE @newString varchar(max)   
SET @newString = ''   
  
SELECT @newString = @newString + '<EntityPropertyOfString><Name>' + [Name] + '</Name><Value>'+ [Value] + '</Value></EntityPropertyOfString>'   
FROM @nodes   
WHERE NULLIF([Name], '') IS NOT NULL AND NULLIF([value], '') IS NOT NULL   
  
IF @newString <> ''   
   SELECT @newString = '<ArrayOfEntityPropertyOfString xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">' + @newString + '</ArrayOfEntityPropertyOfString>'   
ELSE   
   SELECT @newString = null   
      
return CAST(@newString AS XML)   
  
END   
  

GO


