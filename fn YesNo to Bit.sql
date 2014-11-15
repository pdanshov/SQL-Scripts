SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE   function YesNoBit(@string varchar(255))
returns bit
as 	
begin
declare @b bit

	set @string=ltrim(@string)
	set @string=rtrim(@string)
	
	set @b = 0

	if @string = 'y' set @b = 1
	if @string = 'Y' set @b = 1


	return(@b)

end


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

