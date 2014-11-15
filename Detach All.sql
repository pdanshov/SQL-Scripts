create proc DetachAll
as


declare @x int
declare @dbName sysname
set @x=1
while @x < 20
	begin
		set @dbName = ''
		select @dbName = name from master.dbo.sysdatabases where dbid=@x
		if @dbName not in ('master','tempdb','model','msdb','')
			begin
				print @dbName
				exec sp_Detach_db @dbName, 'true'
			end
		set @x = @x + 1
	end









