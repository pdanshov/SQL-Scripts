declare @a varchar(8),@b varchar(8)
select @a='aaa',@b='AAA'
if @a=@b
begin 
	print 'Yes'
end
else
begin 
	print 'No'
end


declare @a varchar(8),@b varchar(8)
select @a='aaa',@b='AAA'
if cast (@a as varbinary(8))=cast (@b as varbinary(8))
begin 
	print 'Yes'
end
else
begin 
	print 'No'
end

select convert(datetime,convert(varchar,getdate(),101))