EXEC sp_attach_db @dbname = N'PI5', 
   @filename1 = N'c:\Program Files\Microsoft SQL Server\MSSQL\Data\PI5_dat.mdf', 
   @filename2 = N'c:\Program Files\Microsoft SQL Server\MSSQL\Data\PI5_log.ldf'


EXEC sp_attach_single_file_db @dbname = 'PI5', 
   @physname = 'c:\Program Files\Microsoft SQL Server\MSSQL\Data\PI5_dat.mdf'
