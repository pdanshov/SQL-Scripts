DELETE FROM dbo.tblSmConfig
WHERE AppId = 'ED';

	INSERT INTO ClaimOne (ClaimID, Subscriber, QualifyingInformation)
	VALUES (SELECT 1000008, 1, 1 FROM DUAL WHERE NOT EXISTS (SELECT ClaimID FROM ClaimeOne WHERE ClaimID = 1000008))

Update [dbo].[tblSmConfig] set CaptionId = 'Functional Acknowledgement, 997' WHERE ConfigRef = 10023;


--
	EXEC MASTER.DBO.SP_ENABLE_SQL_DEBUG
	GRANT debug any procedure, debug connect session TO <sa>;
	EXEC sp_configure 'clr enabled',1;
	RECONFIGURE;
--


BEGIN TRAN
--code here
IF @@TRANCOUNT>0 ROLLBACK TRAN



/**********Search ALL Database for string****************/

DECLARE @SearchStr nvarchar(100)
SET @SearchStr = '## YOUR STRING HERE ##'


    -- Copyright © 2002 Narayana Vyas Kondreddi. All rights reserved.
    -- Purpose: To search all columns of all tables for a given search string
    -- Written by: Narayana Vyas Kondreddi
    -- Site: http://vyaskn.tripod.com
    -- Updated and tested by Tim Gaunt
    -- http://www.thesitedoctor.co.uk
    -- http://blogs.thesitedoctor.co.uk/tim/2010/02/19/Search+Every+Table+And+Field+In+A+SQL+Server+Database+Updated.aspx
    -- Tested on: SQL Server 7.0, SQL Server 2000, SQL Server 2005 and SQL Server 2010
    -- Date modified: 03rd March 2011 19:00 GMT
    CREATE TABLE #Results (ColumnName nvarchar(370), ColumnValue nvarchar(3630))

    SET NOCOUNT ON

    DECLARE @TableName nvarchar(256), @ColumnName nvarchar(128), @SearchStr2 nvarchar(110)
    SET  @TableName = ''
    SET @SearchStr2 = QUOTENAME('%' + @SearchStr + '%','''')

    WHILE @TableName IS NOT NULL
    
    BEGIN
        SET @ColumnName = ''
        SET @TableName = 
        (
            SELECT MIN(QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME))
            FROM     INFORMATION_SCHEMA.TABLES
            WHERE         TABLE_TYPE = 'BASE TABLE'
                AND    QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME) > @TableName
                AND    OBJECTPROPERTY(
                        OBJECT_ID(
                            QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME)
                             ), 'IsMSShipped'
                               ) = 0
        )

        WHILE (@TableName IS NOT NULL) AND (@ColumnName IS NOT NULL)
            
        BEGIN
            SET @ColumnName =
            (
                SELECT MIN(QUOTENAME(COLUMN_NAME))
                FROM     INFORMATION_SCHEMA.COLUMNS
                WHERE         TABLE_SCHEMA    = PARSENAME(@TableName, 2)
                    AND    TABLE_NAME    = PARSENAME(@TableName, 1)
                    AND    DATA_TYPE IN ('char', 'varchar', 'nchar', 'nvarchar', 'int', 'decimal')
                    AND    QUOTENAME(COLUMN_NAME) > @ColumnName
            )
    
            IF @ColumnName IS NOT NULL
            
            BEGIN
                INSERT INTO #Results
                EXEC
                (
                    'SELECT ''' + @TableName + '.' + @ColumnName + ''', LEFT(' + @ColumnName + ', 3630) FROM ' + @TableName + ' (NOLOCK) ' +
                    ' WHERE ' + @ColumnName + ' LIKE ' + @SearchStr2
                )
            END
        END    
    END

    SELECT ColumnName, ColumnValue FROM #Results

DROP TABLE #Results

/********************************************************/


use [001] select * from tblEdComm
	- equivalent to -
select * from 001..[tblEdComm]


-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-- Create the table.
CREATE TABLE TestTable (cola int, colb char(3));
GO
SET NOCOUNT ON;
GO
-- Declare the variable to be used.
DECLARE @MyCounter int;

-- Initialize the variable.
SET @MyCounter = 0;

-- Test the variable to see if the loop is finished.
WHILE (@MyCounter < 26)
BEGIN;
   -- Insert a row into the table.
   INSERT INTO TestTable VALUES
       -- Use the variable to provide the integer value
       -- for cola. Also use it to generate a unique letter
       -- for each row. Use the ASCII function to get the
       -- integer value of 'a'. Add @MyCounter. Use CHAR to
       -- convert the sum back to the character @MyCounter
       -- characters after 'a'.
       (@MyCounter,
        CHAR( ( @MyCounter + ASCII('a') ) )
       );
   -- Increment the variable to count this iteration
   -- of the loop.
   SET @MyCounter = @MyCounter + 1;
END;
GO
SET NOCOUNT OFF;
GO
-- View the data.
SELECT cola, colb
FROM TestTable;
GO
DROP TABLE TestTable;
GO


 /*

    Certain objects within MySQL, including database, table, index, column, alias, view, stored procedure, partition, tablespace, and other object names are known as identifiers.

    ...

    If an identifier contains special characters or is a reserved word, you must quote it whenever you refer to it.

    ...

    The identifier quote character is the backtick ("`"):

A complete list of reserved words can be found in section 9.3 Reserved Words. Here are a few of the most commonly used ones:

+-------------------+--------------+--------------+
| AND               | BEFORE       | BETWEEN      |
| BY                | CALL         | CASE         |
| CHANGE            | CHAR         | CHARACTER    |
| COLUMN            | CURRENT_DATE | CURRENT_TIME |
| CURRENT_TIMESTAMP | CURRENT_USER | DATABASES    |
| DEFAULT           | DELETE       | DESC         |
| DESCRIBE          | DISTINCT     | FOREIGN      |
| FROM              | FULLTEXT     | INDEX        |
| INSERT            | INTERVAL     | KEY          |
| KEYS              | LIKE         | LIMIT        |
| LONG              | MATCH        | NOT          |
| OPTION            | READ         | REPEAT       |
| REQUIRE           | RETURN       | TABLE        |
| TO                | USER         | UTC_TIME     |
+-------------------+--------------+--------------+
 */


