
CREATE    function dbo.FormatZero(@data varchar(255),@pos int)
returns varchar(255)
as 	
	
begin
declare @i int
	set @data=ltrim(@data)
	set @data=rtrim(@data)

	
	
	
	set @i=@pos-len(@data)
	while @i>0
		begin
		set @data='0' + @data
		set @i=@i-1
		end
	return(@data)
end


