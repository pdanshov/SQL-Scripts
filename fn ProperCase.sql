SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO


CREATE    function dbo.ProperCase(@data varchar(255))
returns varchar(255)
as 	
	
begin
declare @MyString as varchar(255)
declare @Last as varchar(1)
declare @len int
declare @i int


set @data=lower(rtrim(ltrim(@data)))

	set @len=len(@data)
	set @i=2
	set @MyString=upper(substring(@data,1,1))
		while @i<@len
			begin
				if @last = ' ' set @MyString = @MyString + upper(substring(@data,@i,1)) else set @MyString = @MyString + substring(@data,@i,1)
				set @Last = substring(@data,@i,1)
				set @i=@i+1
			end
	set @MyString=@MyString + substring(@data,@len,1)

	if PATINDEX ( '%Aaws%' , @MyString )<>0  set @MyString= Replace(@MyString,'Aaws','AAWS')
	if PATINDEX ( '%A.a.w.s%' , @MyString )<>0  set @MyString= Replace(@MyString,'A.a.w.s','A.A.W.S')
	if PATINDEX ( '%Gso%' , @MyString )<>0  set @MyString= Replace(@MyString,'Gso','GSO')

	if PATINDEX ( 'Po Box' , @MyString )<>0  set @MyString= Replace(@MyString,'Po Box','PO BOX')
	if PATINDEX ( 'P.o. Box' , @MyString )<>0  set @MyString= Replace(@MyString,'P.o. Box','P.O. BOX')
 

return(@MyString)
end


/*
select  dbo.ProperCase('THE AAWS BROWN A.A.W.S FOX JUMPED (UP) OVER THE LAZZY GSO DOG') 

*/




GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

