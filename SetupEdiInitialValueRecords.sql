
/***********************************************************************************
 ********* Peter Danshov - Add EDI Initial Value Setup Records to Tables ***********
 ***********************************************************************************
 *
 *		pdanshv@gmail.com 12.05.14
 *
 *		sys smconfig 		   = groups and sub-group menu items
 *		sys smconfigvalue 	   = new record with configref equal to smconfig
 *		sys dbo.tblSmMenuDescr = main menu items
 *		sys dbo.tblSmMenu	   = sub-menu items
 *		sys	dbo.tblSmApp	   = top-level module
 *
 *		All smconfig menu items must have captions:
 *			Trav10.5: sys dbo.tbl.syscaption [ObjectID] = sys dbo.tblsmconfig [CaptionId]
 *
 *		Traverse Company Setup:
 *			System Manager -> Company Setup -> Business Rules -> Application -> EDI
 *
 *******************************************************************/
 
 INSERT INTO [I31].dbo.tblSmTransID (FunctionID, NextID, ts)
 VALUES
 /*Batch Sequence Number used by SO Generation*/ ('EDIBatch', 1, null), /*'0x000000000EDC1625'*/
 /*UCC128 / GS1 / Container Number*/ ('EDIUCC128', 1000, null), /*'0x000000000EDD67C8'*/
 /*Shipment Number*/ ('EDIShip', 1000, null), /*'0x000000000EDD67CB'*/
 /*EDIConInv*/ ('EDIConInv', 1000, null); /* Timestamp - Binary Data, nulls allowed '0x000000000EDD67CD'*/

/* 
0x0000000000001788
0x0000000000001789
0x000000000000178A
0x000000000000178B
*/
