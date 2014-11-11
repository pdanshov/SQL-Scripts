-- Set database to search
	USE dbname
	GO
	------------------------------------------------------------------------------------------------------------------------------------
	-- Set test value here and set @SearchViews to 1 if views are to be included - 0 if not; no other code below changes
	DECLARE @TestValue NVARCHAR(MAX) = 'text to search'
	DECLARE @SearchViews BIT = 0
	------------------------------------------------------------------------------------------------------------------------------------
	DECLARE @SQL NVARCHAR(MAX)
	DECLARE @varSQL NVARCHAR(MAX)
	DECLARE @WhereClause NVARCHAR(MAX)
	DECLARE @TableName NVARCHAR(128)
	DECLARE @varTableName NVARCHAR(128)
	DECLARE @TableSchema NVARCHAR(128)
	DECLARE @ColumnName NVARCHAR(128)
	     
	DECLARE @SchemaObjects TABLE (
	    TABLE_NAME NVARCHAR(128),
	    TABLE_SCHEMA NVARCHAR(128)
	)
	 
	INSERT INTO @SchemaObjects
	SELECT TABLE_NAME, TABLE_SCHEMA FROM INFORMATION_SCHEMA.TABLES
	    WHERE TABLE_TYPE = 'BASE TABLE'
	 
	IF @SearchViews = 1
	BEGIN
	    INSERT INTO @SchemaObjects
	    SELECT TABLE_NAME, TABLE_SCHEMA FROM INFORMATION_SCHEMA.VIEWS
	END
	 
	DECLARE TableCursor CURSOR FAST_FORWARD FOR
	SELECT TABLE_NAME, TABLE_SCHEMA FROM @SchemaObjects
	 
	OPEN TableCursor
	FETCH NEXT FROM TableCursor INTO @TableName, @TableSchema
	WHILE @@FETCH_STATUS = 0
	BEGIN
	    SET @WhereClause = ''
	 
	    DECLARE ColumnCursor CURSOR FAST_FORWARD FOR
	    SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS
	        WHERE TABLE_NAME = @TableName AND TABLE_SCHEMA = @TableSchema AND ((DATA_TYPE IN ('CHAR','NCHAR','VARCHAR','NVARCHAR')) AND (CHARACTER_MAXIMUM_LENGTH IS NOT NULL) AND (CHARACTER_MAXIMUM_LENGTH >= LEN(@TestValue)) OR DATA_TYPE IN ('TEXT','NTEXT'))
	    OPEN ColumnCursor
	    FETCH NEXT FROM ColumnCursor INTO @ColumnName
	    WHILE @@FETCH_STATUS = 0
	    BEGIN
	        IF LEN(@WhereClause) > 0 SET @WhereClause = @WhereClause + ' OR '
	        SET @WhereClause = @WhereClause + '(CONVERT(NVARCHAR,[' + @ColumnName + ']) LIKE ''%' + @TestValue + '%'')'
	        FETCH NEXT FROM ColumnCursor INTO @ColumnName
	    END
	    CLOSE ColumnCursor
	    DEALLOCATE ColumnCursor
	    IF LEN(@WhereClause) > 0
	    BEGIN      
	        SET @varTableName = REPLACE(@TableName,' ','_')
	        SET @varSQL = 'DECLARE @' + @varTableName + CHAR(10) + ' TABLE (' + CHAR(10)
	        SELECT @varSQL = @varSQL + ' ' + sc.name + ' ' +
	        CASE WHEN st.name = 'TIMESTAMP' THEN 'DATETIME' ELSE UPPER(st.name) END +
	        CASE WHEN st.name IN ('VARCHAR','NVARCHAR','CHAR','NCHAR') THEN '(' +
	        CASE WHEN sc.[length] > 4000 THEN 'MAX' ELSE CAST(sc.[length] AS NVARCHAR) END + ') ' ELSE ' ' END +
	        CASE WHEN sc.isnullable = 1 THEN 'NULL' ELSE 'NOT NULL' END + ',' + CHAR(10)
	        FROM sysobjects so
	        JOIN syscolumns sc ON sc.id = so.id
	        JOIN systypes st ON st.xusertype = sc.xusertype
	        WHERE so.name = @TableName
	        ORDER BY sc.colid
	  
	        SELECT @varSQL = SUBSTRING(@varSQL,1,LEN(@varSQL) - 2) + CHAR(10) + ');' + CHAR(10)
	         
	        SET @varSQL = @varSQL + 'INSERT INTO @' + @varTableName + CHAR(10) + 'SELECT * FROM [' + @TableSchema + '].[' + @TableName + ']' + CHAR(10) + 'WHERE ' + @WhereClause + ';' + CHAR(10)
	        SET @varSQL = @varSQL + 'IF EXISTS(SELECT * FROM @' + @varTableName + ')' + CHAR(10) + 'SELECT ''[' + @TableSchema + '].[' + @TableName + ']'' AS [Table Schema/Table Name], * FROM @' + @varTableName + ';'
	        SET @SQL = 'SELECT ''[' + @TableSchema + '].[' + @TableName + ']'' AS [Table Schema/Table Name], * FROM [' + @TableSchema + '].[' + @TableName + '] WHERE ' + @WhereClause     
	        PRINT @SQL
	         
	        PRINT @varSQL
	        EXEC (@varSQL)
	    END
	    FETCH NEXT FROM TableCursor INTO @TableName, @TableSchema
	END
	CLOSE TableCursor
	DEALLOCATE TableCursor