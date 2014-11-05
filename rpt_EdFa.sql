-- ================================================
-- 
-- ================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Peter Danshov - pdanshv@gmail.com>
-- Create date: <Create Date,,09.10.14>
-- Description:	<Description,,Returns relevant field data to be used in ED FA (810).>
-- =============================================
CREATE PROCEDURE rpt_EdFa
	-- Add the parameters for the stored procedure here
	--<@Param1, sysname, @p1> <Datatype_For_Param1, , int> = <Default_Value_For_Param1, , 0>, 
	--<@Param2, sysname, @p2> <Datatype_For_Param2, , int> = <Default_Value_For_Param2, , 0>
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	-- SELECT <@Param1, sysname, @p1>, <@Param2, sysname, @p2>

	select * from tblEdMailControl
	select * from tbledpartner
	select * from tblEdDocument

END
GO

----------------------------------------------------------------------------
----------------------------------------------------------------------------
----------------------------------------------------------------------------

USE [EDI]
GO
/****** Object:  StoredProcedure [dbo].[rpt_EdFa]    Script Date: 9/30/2014 3:22:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Peter Danshov - pdanshv@gmail.com
-- Create date: 09.10.14
-- Description:	Returns relevant field data to be used in ED FA (810).
-- =============================================
ALTER PROCEDURE [dbo].[rpt_EdFa]
	-- Add the parameters for the stored procedure here
	--@p1 nvarchar(50) = NULL, 
	--@p2 nvarchar(50) = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	--SELECT @p1, @p2

	select *
	--SELECT TableA.*, TableB.*, TableC.*, TableD.*
	FROM tblEdMailControl
		INNER JOIN tbledpartner
			ON tblEdMailControl.PartnerId=tbledpartner.PartnerID
		INNER JOIN tblEdDocument
			ON tblEdDocument.DocID=tblEdMailControl.DocId;

END
