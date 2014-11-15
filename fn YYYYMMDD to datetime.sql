SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO



CREATE          function YYYYMMDD(@string varchar(8)) returns datetime
begin 	

declare @MyDate as datetime
declare @MyString varchar(8)

set @mydate=null

set @MyString = substring(@string,5,2)+'/'+substring(@string,7,2)+'/'+substring(@string,3,2)
if isdate(@myString)=1 select  @mydate= convert(DATETIME,@MyString)

set @MyString = substring(@string,1,2)+'/'+substring(@string,3,2)+'/'+substring(@string,7,2)
if isdate(@myString)=1 select  @mydate= convert(DATETIME,@MyString)


return @mydate
end




GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

