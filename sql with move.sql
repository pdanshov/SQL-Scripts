RESTORE DATABASE AdventureWorks2008R2
   FROM AdventureWorks2008R2Backups
   WITH NORECOVERY, 
      MOVE 'AdventureWorks2008R2_Data' TO 
'C:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\Data\NewAdvWorks2008R2.mdf', 
      MOVE 'AdventureWorks2008R2_Log' 
TO 'C:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\Data\NewAdvWorks2008R2.ldf'
RESTORE LOG AdventureWorks2008R2
   FROM AdventureWorks2008R2Backups
   WITH RECOVERY
