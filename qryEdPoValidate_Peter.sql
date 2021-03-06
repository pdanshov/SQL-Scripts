USE [I31]
GO
/****** Object:  StoredProcedure [dbo].[qryEdValidatePo]    Script Date: 09/19/2014 10:00:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




/*          
          
alter table  DROP CONSTRAINT tmp_080216_id   
  
  
select * from tbledpoheader  
declare @x int            
exec qryEdValidatePo @x out          
select @x          
       
       
       
rollback             
       
       
       select * from tbledPoHeader   
*/          
ALTER PROCEDURE [dbo].[qryEdValidatePo]                          
@TotCount int =0 OUT                           
as  
SET NOCOUNT ON                      
                   
       
                                   
DECLARE @ErrCode int,                          
        @DfltLoc pLocId,                          
        @ConfigValue varchar(255)                           
                                  
DECLARE @PrecUPrice tinyint,@PrecUcost tinyint,                      
        @PartnerID pPartnerID,                      
        @CustID pCustID,                      
        @CustLevel varchar(10),                      
        @UnitBasePrice pDec,                      
        @CustPriceID varchar(10),                      
        @ItemID pItemID,                      
        @UnitPrice pDec,                      
        @QtyOrd pDec,                      
        @UnitsSell puom,                      
        @ID integer,                      
        @ForcePOPrice bit,      
        @ReceiverID varchar(50),      
        @ValidateYN as bit,  
        @CreateMissingVDStores bit                          
                      
SELECT  @ErrCode=0,                          
        @DfltLoc='',                          
        @ConfigValue='',          
        @TotCount =0,      
        @ValidateYN=0,  
        @CreateMissingVDStores=1      
      
--Err status 0=OK,1=Warning,2=Error Cont, 3 = Err Stop , 4= Delete                           
                 -- rollback trans                                                           
--Po's to Validate                          
CREATE TABLE #tmp                          
  (Id int,                          
  ImportBatchId varchar(14),                          
  PartnerId varchar(10) null,                          
  CustPoNum varchar(30) null,                          
  CustId pCustId null,                          
 SenderId varchar(20) null     
CONSTRAINT tmp_080217_id PRIMARY KEY (ID))                          
                          
CREATE TABLE #tmpDtl                          
  (Id int,                          
  ImportBatchId varchar(14),                          
  PartnerId varchar(10),                          
  CustPoNum varchar(30),                          
  CustId pCustId,                          
  SenderId varchar(20)     
CONSTRAINT tmpDtl_080216_id PRIMARY KEY (ID))        
      
      
CREATE TABLE #TmpSender(      
  Id Int IDENTITY(1,1),      
  CurSenderId varchar(20),      
  NewSenderId varchar(20)      
  CONSTRAINT tmpSender_080216_id PRIMARY KEY (ID)   )               
      
CREATE TABLE #tmpStores (ID int,  
                         CustId varchar(20))  
                     
  
                        
      
CREATE TABLE #tmpItem(      
 Id Int,      
 ImportBatchId pPostRun,      
 SenderId varchar(50),      
        CustPoNum varchar(50),      
 UnitsSell varchar(10),      
 iItem varchar(50),      
 iCode varchar(50),      
 Descr varchar(50),      
 DfltItemUirType varchar(12),      
 PartnerId varchar(12)  
            CONSTRAINT tmpItem_080216_id PRIMARY KEY (ID)    )               
                                           
EXEC glbSmGetSingleConfigValue_sp 'SM',null,'WhseID',@ConfigValue out                           
SELECT @DfltLoc=@ConfigValue              
      
EXEC dbo.glbSmGetSingleConfigValue_sp 'ED', NULL, 'EDIForcePOPrice', @ConfigValue OUT                            
SET @ForcePOPrice = ISNULL(CAST(@ConfigValue AS bit), 0)         
      
EXEC dbo.glbSmGetSingleConfigValue_sp 'ED', NULL, 'EdiCommID', @ConfigValue OUT                              
SET @ReceiverID = ISNULL(@ConfigValue, '')        
      
EXEC dbo.glbSmGetSingleConfigValue_sp 'ED', NULL, 'EdiValidatePoYn', @ConfigValue OUT                              
SET @ValidateYN = CASE WHEN ISNULL(@ConfigValue, 'TRUE')='TRUE' THEN 1 ELSE 0 END      
      
EXEC glbSmGetSingleConfigValue_sp 'SM',null,'PrecUPrice',@ConfigValue out                         
SET @PrecUPrice= CAST(@ConfigValue AS Tinyint)                              
 EXEC glbSmGetSingleConfigValue_sp 'SM',null,'PrecUcost',@ConfigValue out                         
SET @PrecUcost = CAST(@ConfigValue AS Tinyint)                              
         
                                 
                                  SET @ErrCode=10                          
EXEC dbo.trvsp_SmSetFunctionStatus 'EDI PO Validation', @ErrCode, 'Clearing Log'                            
  SET @ValidateYN =1    
      
BEGIN TRANSACTION                          
                          
DELETE FROM dbo.tblEdPoErrorlog                           
IF @@ERROR <> 0 GOTO ErrorTrap      
      
 -- ***** Select division comm ids      
SET @ErrCode=11       
INSERT INTO #TmpSender (CurSenderId, NewSenderId)      
      
SELECT d.CommDivision,p.MailId      
FROM (SELECT DISTINCT PartnerId, CommDivision       
      FROM dbo.tblEdPartnerCommDiv (NOLOCK) ) d       
INNER JOIN       
     (SELECT PartnerId,MailId      
      FROM tblEdPartnerDoc (NOLOCK)      
      WHERE DocId='850') p ON d.PartnerId=p.PartnerId      
IF @@ERROR <> 0 GOTO ErrorTrap      
      
      
      
IF (SELECT COUNT(*) FROM #TmpSender)>0      
   BEGIN      
  -- ***** Replace division comm id in po detail        
 SET @ErrCode=12      
 UPDATE d SET d.SenderId=t.NewSenderId      
 from tbledpodetail  d (NOLOCK)      
 INNER JOIN #TmpSender t ON d.SenderId=t.CurSenderId      
 IF @@ERROR <> 0 GOTO ErrorTrap      
       
  -- ***** Replace division comm id in mail table      
 SET @ErrCode=13      
 UPDATE c SET c.SenderId=t.NewSenderId      
 from tbledmailcontrol c (NOLOCK)      
 INNER JOIN tbledpoheader h (NOLOCK) ON c.ImportBatchId=h.ImportBatchId AND c.DocKey = h.CustPoNum AND c.SenderID = h.SenderID      
 INNER JOIN #TmpSender t ON c.SenderId=t.CurSenderId      
 WHERE c.DocType='850'      
 IF @@ERROR <> 0 GOTO ErrorTrap      
       
  -- ***** Replace division comm id in po header      
 SET @ErrCode=14      
 UPDATE h SET h.SenderId=t.NewSenderId      
 from tbledpoHeader h (NOLOCK)      
 INNER JOIN #TmpSender t ON h.SenderId=t.CurSenderId      
 IF @@ERROR <> 0 GOTO ErrorTrap       
   END      
      
 -- Replace invalid linenumbers   
  
UPDATE dbo.tblEdPoDetail SET  PoLineNum = 0 WHERE  ISNUMERIC(PoLIneNum)=0  
 -- ***** Incorrect Receiver ID                      
SET @ErrCode=15                          
EXEC dbo.trvsp_SmSetFunctionStatus 'EDI PO Validation', @ErrCode, 'Validate Receiver ID'                            
                         
INSERT INTO dbo.tblEdPoErrorlog (ImportBatchId,RecId,PartnerId,CustPoNum ,LineNum, ErrCode,ErrDescr,ErrSequence,ErrRecType,ErrStatus)                            
SELECT h.ImportBatchId,ID,h.PartnerID,h.CustPoNum,0,@ErrCode,'Receiver ID [' + m.ReceiverID + '] does not match EDI Communication ID [' + @ReceiverID + ']',0,'H',4                            
FROM dbo.tblEdPoHeader  h (NOLOCK)      
INNER JOIN dbo.tblEdMailControl m (NOLOCK) ON h.ImportBatchId = m.ImportBatchId AND m.DocKey = h.CustPoNum AND h.SenderID = m.SenderID      
WHERE m.DocType = '850' AND m.ReceiverID <> @ReceiverID      
IF @@ERROR <> 0 GOTO ErrorTrap                             
-- *****                             
               
 -- ***** Missing header key                          
SET @ErrCode=20                        
EXEC dbo.trvsp_SmSetFunctionStatus 'EDI PO Validation', @ErrCode, 'Validate Key Header Data'                          
                       
INSERT INTO dbo.tblEdPoErrorlog (ImportBatchId,RecId,PartnerId,CustPoNum ,LineNum, ErrCode,ErrDescr,ErrSequence,ErrRecType,ErrStatus)                          
SELECT ImportBatchId,ID,'Error','Error',0,@ErrCode,'Missing Key Header Data, Records Deleted' ,0,'H',4                          
FROM dbo.tblEdPoHeader (NOLOCK)                           
WHERE isnull(ImportBatchId,'')='' OR  LTRIM(RTRIM(ISNULL(SenderId,'')))='' OR  LTRIM(RTRIM(ISNULL(CustPoNum,'')))=''                                              
IF @@ERROR <> 0 GOTO ErrorTrap                           
                                
DELETE h       
FROM dbo.tblEdPoHeader h (NOLOCK)      
INNER JOIN dbo.tblEdPoErrorlog e (NOLOCK) ON h.Id=e.RecId       
WHERE ErrRecType='H' AND ErrStatus =4                          
IF @@ERROR <> 0 GOTO ErrorTrap                             
-- *****                           
                        
-- ***** Missing detail key                          
SET @ErrCode=30                         
EXEC dbo.trvsp_SmSetFunctionStatus 'EDI PO Validation', @ErrCode, 'Validate Key Detail Data'                              
INSERT INTO dbo.tblEdPoErrorlog (ImportBatchId,RecID,PartnerId,CustPoNum ,LineNum, ErrCode,ErrDescr,ErrSequence,ErrRecType,ErrStatus)                          
SELECT ImportBatchId,ID,'Error','Error',0,@ErrCode,'Missing Key Detail Data, Records Deleted', 0,'H',4                           
FROM dbo.tblEdPoDetail  (NOLOCK)                          
WHERE isnull(ImportBatchId,'')='' OR  LTRIM(RTRIM(ISNULL(SenderId,'')))='' OR  LTRIM(RTRIM(ISNULL(CustPoNum,'')))=''                          
IF @@ERROR <> 0 GOTO ErrorTrap                           
                          
DELETE d       
FROM dbo.tblEdPoDetail d  (NOLOCK) INNER JOIN dbo.tblEdPoErrorlog e (NOLOCK) ON d.Id=e.RecId       
WHERE ErrRecType='D' AND ErrStatus =4                          
IF @@ERROR <> 0 GOTO ErrorTrap                                               
-- *****                          
                          
-- ***** Headers with missing detail records                          
SET @ErrCode=40                                              
EXEC dbo.trvsp_SmSetFunctionStatus 'EDI PO Validation', @ErrCode, 'Validate for missing detail records'                                              
INSERT INTO dbo.tblEdPoErrorlog (ImportBatchId,RecID,PartnerId,CustPoNum ,LineNum, ErrCode,ErrDescr,ErrSequence,ErrRecType,ErrStatus)                          
SELECT h.ImportBatchId,h.ID,'Error','Error',0,@ErrCode,'Missing Detail Records, Records Deleted' ,0,'H',4                           
FROM dbo.tblEdPoHeader h  (NOLOCK)                          
LEFT JOIN dbo.tblEdPoDetail d  (NOLOCK) ON h.ImportBatchId=d.ImportBatchId AND h.SenderId=d.SenderId AND h.CustpoNum=d.CustPoNum                          
WHERE d.ID IS NULL                                               
IF @@ERROR <> 0 GOTO ErrorTrap                           
                                              
DELETE h       
FROM dbo.tblEdPoHeader  h (NOLOCK) INNER JOIN dbo.tblEdPoErrorlog e (NOLOCK) ON h.Id=e.RecId       
WHERE ErrRecType='H' AND ErrStatus =4                          
IF @@ERROR <> 0 GOTO ErrorTrap                            
-- *****      
                          
-- Details with missing Header records                          
SET @ErrCode=50                                             
EXEC dbo.trvsp_SmSetFunctionStatus 'EDI PO Validation', @ErrCode, 'Validate for missing header records'                          
INSERT INTO dbo.tblEdPoErrorlog (ImportBatchId,RecID,PartnerId,CustPoNum ,LineNum, ErrCode,ErrDescr,ErrSequence,ErrRecType,ErrStatus)                          
SELECT d.ImportBatchId,d.ID,'Error','Error',0,@ErrCode,'Missing Header Records, Records Deleted' ,0,'D',4                           
FROM dbo.tblEdPoDetail d (NOLOCK)                           
LEFT JOIN dbo.tblEdPoHeader h  (NOLOCK) ON d.ImportBatchId=h.ImportBatchId AND d.SenderId=h.SenderId AND d.CustpoNum=h.CustPoNum                          
WHERE h.ID IS NULL                                                
IF @@ERROR <> 0 GOTO ErrorTrap                           
                          
DELETE d       
FROM dbo.tblEdPoDetail d (NOLOCK) INNER JOIN dbo.tblEdPoErrorlog e (NOLOCK) ON d.Id=e.RecId       
WHERE ErrRecType='D' AND ErrStatus =4                          
IF @@ERROR <> 0 GOTO ErrorTrap                           
-- *****                           
      
                     
-- ***** save list of Po's to validate          
SET @ErrCode=60                      
EXEC dbo.trvsp_SmSetFunctionStatus 'EDI PO Validation', @ErrCode, 'Saving list..'                                                                  
INSERT INTO #tmp(Id,ImportBatchId,PartnerId,CustPoNum,CustID,SenderID)                          
SELECT h.Id,h.ImportBatchId,pd.PartnerId,h.CustPoNum ,c.CustId,h.SenderId                          
FROM dbo.tblEdPoHeader h  (NOLOCK)                          
LEFT JOIN dbo.tblEdPartnerDoc pd  (NOLOCK)ON h.SenderId=pd.MailId AND pd.DocId='850'                          
LEFT JOIN dbo.tblEdPartner p  (NOLOCK)ON pd.PartnerId=p.PartnerID                          
LEFT JOIN dbo.tblArCust c (NOLOCK) ON p.CustId=c.CustId                                                                  
IF @@ERROR <> 0 GOTO ErrorTrap                                              
-- *****      
                          
-- ***** Update with partner and cust info HEADER                          
SET @ErrCode=70      
EXEC dbo.trvsp_SmSetFunctionStatus 'EDI PO Validation', @ErrCode, 'Updating Po Header Information'                          
UPDATE h SET PartnerId=t.PartnerId                          
FROM dbo.tblEdPoHeader h (NOLOCK)                          
INNER JOIN #tmp t ON h.Id=t.Id                          
IF @@ERROR <> 0 GOTO ErrorTrap                           
-- *****      
      
-- ***** Update with partner and cust info DETAIL                      
SET @ErrCode=80                          
UPDATE d SET PartnerId=h.PartnerId                          
FROM dbo.tblEdPoDetail d  (NOLOCK)                        
INNER JOIN dbo.tblEdPoHeader h (NOLOCK) ON d.ImportBatchId=h.ImportBatchId AND d.SenderId=h.SenderId AND d.CustpoNum=h.CustPoNum                          
INNER JOIN #tmp t ON h.Id=t.Id                         
IF @@ERROR <> 0 GOTO ErrorTrap                           
-- *****                          
                                                 
-- ***** Missing Partner                          
SET @ErrCode=90                          
EXEC dbo.trvsp_SmSetFunctionStatus 'EDI PO Validation', @ErrCode, 'Validate for invalid sender'                          
INSERT INTO dbo.tblEdPoErrorlog (ImportBatchId,RecID,PartnerId,CustPoNum ,LineNum, ErrCode,ErrDescr,ErrSequence,ErrRecType,ErrStatus)                          
SELECT ImportBatchId,ID,'[Missing]',t.CustPoNum,0,@ErrCode,'Sender ['+ ISNULL(t.SenderId,'')+'] not setup to receive POs' ,0,'H',3                           
FROM #tmp t WHERE ISNULL(PartnerId,'')=''                          
IF @@ERROR <> 0 GOTO ErrorTrap                                                         
      
DELETE t      
FROM #tmp t INNER JOIN dbo.tblEdPoErrorlog l (NOLOCK) ON t.Id=l.RecId       
WHERE ErrRecType='H' AND ErrStatus=3      
IF @@ERROR <> 0 GOTO ErrorTrap      
-- *****      
                              
-- ***** Inactive Partner      
SET @ErrCode=100                          
EXEC dbo.trvsp_SmSetFunctionStatus 'EDI PO Validation', @ErrCode, 'Validate for invalid sender'                          
INSERT INTO dbo.tblEdPoErrorlog (ImportBatchId,RecID,PartnerId,CustPoNum ,LineNum, ErrCode,ErrDescr,ErrSequence,ErrRecType,ErrStatus)                          
SELECT ImportBatchId,ID,t.PartnerID,t.CustPoNum,0,@ErrCode,'Partner ['+ ISNULL(t.PartnerID,'')+'] is not active' ,0,'H',3                           
FROM #tmp t LEFT JOIN dbo.tblEdPartner p (NOLOCK) ON t.PartnerID = p.PartnerID        
WHERE p.ActiveYN = 0        
IF @@ERROR <> 0 GOTO ErrorTrap       
      
DELETE t      
FROM #tmp t INNER JOIN dbo.tblEdPoErrorlog l (NOLOCK)  ON t.Id=l.RecId       
WHERE ErrRecType='H' AND ErrStatus=3      
IF @@ERROR <> 0 GOTO ErrorTrap      
-- *****      
        
-- ***** Missing Customer                          
SET @ErrCode=@ErrCode+10                          
EXEC dbo.trvsp_SmSetFunctionStatus 'EDI PO Validation', @ErrCode, 'Validate for invalid customer'                          
INSERT INTO dbo.tblEdPoErrorlog (ImportBatchId,RecID,PartnerId,CustPoNum ,LineNum, ErrCode,ErrDescr,ErrSequence,ErrRecType,ErrStatus)                          
SELECT ImportBatchId,ID,CASE WHEN ISNULL(PartnerId,'')='' THEN '[Missing]' ELSE PartnerID END,t.CustPoNum,0,@ErrCode,'Sender ['+ ISNULL(t.SenderId,'')+'] / Customer not setup' ,0,'H',3                          
FROM #tmp t WHERE ISNULL(t.CustId,'')=''                          
IF @@ERROR <> 0 GOTO ErrorTrap      
      
DELETE t      
FROM #tmp t INNER JOIN dbo.tblEdPoErrorlog l (NOLOCK) ON t.Id=l.RecId       
WHERE ErrRecType='H' AND ErrStatus=3      
IF @@ERROR <> 0 GOTO ErrorTrap      
-- *****      
      
-- ***** Inactive or Missing Document         
SET @ErrCode=110                        
EXEC dbo.trvsp_SmSetFunctionStatus 'EDI PO Validation', @ErrCode, 'Validate for invalid document'                          
INSERT INTO dbo.tblEdPoErrorlog (ImportBatchId,RecID,PartnerId,CustPoNum ,LineNum, ErrCode,ErrDescr,ErrSequence,ErrRecType,ErrStatus)           
SELECT ImportBatchId,ID,t.PartnerID,t.CustPoNum,0,@ErrCode,'Document [850] for Partner ['+ ISNULL(t.PartnerId,'')+'] not setup or inactive' ,0,'H',3                           
FROM #tmp t LEFT JOIN dbo.tblEdPartnerDoc p (NOLOCK) ON t.PartnerID = p.PartnerID AND p.DocID = '850'        
WHERE p.DocID IS NULL OR ISNULL(p.Active,0) = 0        
IF @@ERROR <> 0 GOTO ErrorTrap      
      
DELETE t      
FROM #tmp t INNER JOIN dbo.tblEdPoErrorlog l (NOLOCK) ON t.Id=l.RecId       
WHERE ErrRecType='H' AND ErrStatus=3      
IF @@ERROR <> 0 GOTO ErrorTrap                       
-- *****                        
      
      
                
-- ***** Check for existing unprocesssed POs      
SET @ErrCode=120      
EXEC dbo.trvsp_SmSetFunctionStatus 'EDI PO Validation', @ErrCode, 'Validate for duplicates'                          
SELECT h.Id,h.ImportBatchId,h.SenderId,h.CustPoNum ,d.MaxImportBatchID                         
INTO #DupTemp                          
    FROM dbo.tblEdPoHeader h                           
    INNER JOIN #tmp t ON h.Id=t.Id                           
    INNER JOIN (SELECT MAX(ImportBatchID) MAXImportBatchID,SenderID,CustPoNum                          
    FROM dbo.tblEdPoHeader  (NOLOCK)                         
    GROUP BY SenderID,CustPoNum                          
    HAVING COUNT(ID)>1) d ON h.SenderID=d.SenderId AND h.CustPoNum=d.CustPoNum AND h.ImportBatchId<>d.MaxImportBatchID                          
    IF @@ERROR <> 0 GOTO ErrorTrap                           
         
                  
    IF (SELECT COUNT(*) FROM #DupTemp) >0                           
       BEGIN                                                        
         SET @ErrCode=130                          
        
      
         INSERT INTO dbo.tblEdPoErrorlog (ImportBatchId,RecID,PartnerId,CustPoNum ,LineNum, ErrCode,ErrDescr,ErrSequence,ErrRecType,ErrStatus)                          
         SELECT dup.MaxImportBatchID,t.ID,t.PartnerId,t.CustPoNum,0,@ErrCode,'PO already imported in batch Id ['+dup.ImportBatchId+']. Old Records Removed.'   ,0,'H',1                           
         FROM #DupTemp dup                          
         INNER JOIN dbo.tblEdPoHeader h (NOLOCK) ON dup.Id=h.Id                          
         INNER JOIN #tmp t ON dup.Id=t.Id                           
         IF @@ERROR <> 0 GOTO ErrorTrap                            
                             
               
  DELETE d FROM dbo.tblEdPoDetail d                          
         INNER JOIN #DupTemp td ON d.SenderID=td.SenderId AND d.CustPoNum=td.CustPoNum AND d.ImportBatchId=td.ImportBatchId                          
         IF @@ERROR <> 0 GOTO ErrorTrap                           
                                   
         DELETE h FROM dbo.tblEdPoHeader h                          
         INNER JOIN #DupTemp td ON  h.SenderID=td.SenderId AND h.CustPoNum=td.CustPoNum AND h.ImportBatchId=td.ImportBatchId                            
         IF @@ERROR <> 0 GOTO ErrorTrap       
       
         DELETE l      
  FROM dbo.tblEdPoErrorlog l INNER JOIN #DupTemp d ON l.RecId=d.Id       
  WHERE ErrCode<>130      
         IF @@ERROR <> 0 GOTO ErrorTrap      
      
      END                           
-- *****                       
                                    
-- ***** Check for Po's already in history             
      
IF @ValidateYN=1      
    BEGIN               
 SET @ErrCode=140                           
 EXEC dbo.trvsp_SmSetFunctionStatus 'EDI PO Validation', @ErrCode, 'Check EDI History for PO'                          
 INSERT INTO dbo.tblEdPoErrorlog (ImportBatchId,RecID,PartnerId,CustPoNum ,LineNum, ErrCode,ErrDescr,ErrSequence,ErrRecType,ErrStatus)  
 -------------------------------------------------------     
   --Changed error code here and the following two unique checks directly below to error with continue - Peter
   -------------------------------------------------------------
   SELECT t.ImportBatchId,t.Id,t.PartnerID,t.CustpoNum,0,@ErrCode,'PO ['+ t.CustpoNum  +'] for Partner ['+ t.partnerid +'] already exists in history', 0,'H',2
 --SELECT t.ImportBatchId,t.Id,t.PartnerID,t.CustpoNum,0,@ErrCode,'PO ['+ t.CustpoNum  +'] for Partner ['+ t.partnerid +'] already exists in history', 0,'H',3                          
 FROM #tmp t INNER JOIN dbo.tblEdPoHistHeader h (NOLOCK) ON t.PartnerId=h.PartnerId AND t.CustPoNum=h.CustPoNum                           
 IF @@ERROR <> 0 GOTO ErrorTrap                             
 -- *****      
    END      
ELSE      
    BEGIN            
      -- warning only         
 SET @ErrCode=140                           
 EXEC dbo.trvsp_SmSetFunctionStatus 'EDI PO Validation', @ErrCode, 'Check EDI History for PO'                          
 INSERT INTO dbo.tblEdPoErrorlog (ImportBatchId,RecID,PartnerId,CustPoNum ,LineNum, ErrCode,ErrDescr,ErrSequence,ErrRecType,ErrStatus)                          
 SELECT t.ImportBatchId,t.Id,t.PartnerID,t.CustpoNum,0,@ErrCode,'PO ['+ t.CustpoNum  +'] for Partner ['+ t.partnerid +'] already exists in history', 0,'H',1                          
 FROM #tmp t INNER JOIN dbo.tblEdPoHistHeader h (NOLOCK) ON t.PartnerId=h.PartnerId AND t.CustPoNum=h.CustPoNum                           
 IF @@ERROR <> 0 GOTO ErrorTrap                             
 -- *****      
    END      
                      
-- ***** Check for So's already created from this PO                          
SET @ErrCode=150      
EXEC dbo.trvsp_SmSetFunctionStatus 'EDI PO Validation', @ErrCode, 'Check Sales Order for PO'                          
INSERT INTO dbo.tblEdPoErrorlog (ImportBatchId,RecID,PartnerId,CustPoNum ,LineNum, ErrCode,ErrDescr,ErrSequence,ErrRecType,ErrStatus)
-- Changed error code (status) here - Peter
SELECT ImportBatchId,t.Id,t.PartnerID,t.CustpoNum,0,@ErrCode,'PO ['+ t.CustpoNum  +'] already processed into sales orders',0,'H',2
FROM #tmp t INNER JOIN tblSoTransHeader s (NOLOCK) ON t.CustId=s.CustId AND t.CustPoNum=s.CustPoNum                          
IF @@ERROR <> 0 GOTO ErrorTrap                           
-- *****                          
                            
-- ***** Check for posted So's already created from this PO                          
SET @ErrCode=160      
EXEC dbo.trvsp_SmSetFunctionStatus 'EDI PO Validation', @ErrCode, 'Check AR History for PO'                          
INSERT INTO dbo.tblEdPoErrorlog (ImportBatchId,Recid,PartnerId,CustPoNum ,LineNum, ErrCode,ErrDescr,ErrSequence,ErrRecType,ErrStatus)
-- Changed error code (status) here - Peter
SELECT ImportBatchId,t.Id,t.PartnerID,t.CustpoNum,0,@ErrCode,'PO ['+ t.CustpoNum  +'] already posted into Accounts Receivable',0,'H',2
FROM #tmp t INNER JOIN tblArHistHeader h (NOLOCK) ON t.CustId=h.CustId AND t.CustPoNum=h.CustPoNum                           
IF @@ERROR <> 0 GOTO ErrorTrap      
-- *****      
      
-- ***** Remove errors                    
DELETE t      
FROM #tmp t INNER JOIN dbo.tblEdPoErrorlog l (NOLOCK) ON t.Id=l.RecId       
WHERE ErrRecType='H' AND ErrStatus=3      
IF @@ERROR <> 0 GOTO ErrorTrap                          
-- *****            
                    
  /*
  -- resize vdp store                   
  UPDATE h  SET h.VDPStore=REPLICATE('0',6-LEN(h.VDpStore))+h.VDPStore               
  FROM #tmp t   
  INNER JOIN dbo.tblEdPoHeader h (NOLOCK) ON t.id =h.id     
  WHERE LEN(h.VDPStore)<>6  AND ISNULL(h.VDPStore,'')<>''              
  
   */
                     

        
                    
 IF @CreateMissingVDStores=1   
    BEGIN  
      --- Get missing VDP Stores 
      SET @ErrCode=162    
      INSERT INTO #tmpStores (ID,CustId)  
      SELECT MIN(t.ID),p.CustID  
      FROM #tmp t   
      INNER JOIN dbo.tblEdPoHeader h (NOLOCK) ON t.id =h.id     
      INNER JOIN dbo.tblEdPartner p (NOLOCK) ON t.PartnerID = p.PartnerID   
      INNER JOIN dbo.tblEdPartnerDoc pd (NOLOCK) ON p.PartnerID = pd.PartnerID AND pd.DocID = '850'        
      LEFT JOIN tblArShipTo st1 ON p.CustID=st1.CustId AND h.VDPStore=st1.EdiShipToCode 
      WHERE   h.ShipToCode=ISNULL(pd.VDPCode,'')  
              AND ((ISNULL(h.VDPStore,'')<>'' AND ISNULL(st1.CustId,'')=''))
      GROUP BY p.CustID,h.VDPStore 
      IF @@ERROR <> 0 GOTO ErrorTrap 
        
      
      -- create missing VDP stroes    
      SET @ErrCode=164    
      INSERT INTO dbo.tblArShipTo (CustId,ShiptoId,ShiptoName,Addr1,Addr2 ,City,Region,Country,PostalCode,
                                   EdiShipToType,EdiShipToCode,EdiShipToName,EdiShipToAbbrev,ShipVia)  
      SELECT t.CustID, h.VDPStore,h.ShipToName+ ' # '+RIGHT(h.VDPStore,4),h.ShipToAddr1,h.ShipToAddr2,h.ShipToCity,h.ShipToRegion,
      CASE WHEN ISNULL(ShipToCountry,'')='' THEN 'USA' ELSE ShipToCountry END,ShipToPostalCode,1,
      RIGHT(h.VDPStore,4),
      LEFT(ISNULL(h.ShipToCity,'')+' '+ISNULL(h.ShipToRegion,''),20),
      RIGHT(h.VDPStore,4),
      'UPS TPC (403AE2)'
      FROM #tmpStores t  
      INNER JOIN tblEdPoHeader h ON t.ID=h.ID   
      LEFT JOIN tblArShipTo s ON  s.CustId=t.CustId AND s.EdiShipToCode = h.VDPStore 
      WHERE s.ShiptoId IS NULL
      
      IF @@ERROR <> 0 GOTO ErrorTrap                          
       
   END
   
  /*
  select * from dbo.tblArShipTo where shiptoid  like '%1020%'
  
         
      SET @ErrCode=162    
      INSERT INTO #tmpStores (ID,CustId)  
      SELECT MIN(t.ID),p.CustID  
      FROM #tmp t   
      INNER JOIN dbo.tblEdPoHeader h (NOLOCK) ON t.id =h.id     
      INNER JOIN dbo.tblEdPartner p (NOLOCK) ON t.PartnerID = p.PartnerID   
      INNER JOIN dbo.tblEdPartnerDoc pd (NOLOCK) ON p.PartnerID = pd.PartnerID AND pd.DocID = '850'        
      LEFT JOIN tblArShipTo st1 ON p.CustID=st1.CustId AND h.VDPStore=st1.EdiShipToCode 
      LEFT JOIN tblArShipTo st2 ON p.CustID=st2.CustId AND h.FDOStore=st2.EdiShipToCode 
      WHERE   h.ShipToCode=ISNULL(pd.VDPCode,'')  
              AND ((ISNULL(h.VDPStore,'')<>'' AND ISNULL(st1.CustId,'')='') OR
                   (ISNULL(h.FDOStore,'')<>'' AND ISNULL(st2.CustId,'')=''))
         
      GROUP BY p.CustID,CASE WHEN ISNULL(h.VDPStore,'')<>'' THEN  h.VDPStore ELSE h.FDOStore END  
      IF @@ERROR <> 0 GOTO ErrorTrap                          
  
--qryEdValidatePo
  --rollback tran
      
      SET @ErrCode=164    
      INSERT INTO dbo.tblArShipTo (CustId,ShiptoId,ShiptoName,Addr1,Addr2 ,City,Region,Country,PostalCode,EdiShipToType,EdiShipToCode,EdiShipToName,EdiShipToAbbrev)  
      SELECT t.CustID,CASE WHEN ISNULL(h.VDPStore,'')<>'' THEN h.VDPStore ELSE h.FDOStore END,h.ShipToName,h.ShipToAddr1,h.ShipToAddr2,h.ShipToCity,h.ShipToRegion,
      CASE WHEN ISNULL(ShipToCountry,'')='' THEN 'USA' ELSE ShipToCountry END,ShipToPostalCode,1,
      CASE WHEN ISNULL(h.VDPStore,'')<>'' THEN RIGHT(h.VDPStore,4) ELSE h.FDOStore END,
      CASE WHEN ISNULL(h.VDPStore,'')<>'' THEN RIGHT(h.VDPStore,4) ELSE h.FDOStore END,
      CASE WHEN ISNULL(h.VDPStore,'')<>'' THEN RIGHT(h.VDPStore,4) ELSE h.FDOStore END
      FROM #tmpStores t  
      INNER JOIN tblEdPoHeader h ON t.ID=h.ID   
      LEFT JOIN tblArShipTo s ON  s.CustId=t.CustId AND s.EdiShipToCode = CASE WHEN ISNULL(h.VDPStore,'')<>'' THEN h.VDPStore ELSE h.FDOStore END
      WHERE s.ShiptoId IS NULL
      
      IF @@ERROR <> 0 GOTO ErrorTrap                          
  
  
            
    END                 
      
        SET @ErrCode=166                 
    UPDATE d  SET d.StoreNum=CASE WHEN ISNULL(h.VDPStore,'')<>'' THEN h.VDPStore ELSE h.FDOStore END 
    FROM dbo.tblEdPoDetail d  (NOLOCK)                         
    INNER JOIN dbo.tblEdPoHeader h (NOLOCK) ON d.ImportBatchId=h.ImportBatchId AND d.SenderId=h.SenderId AND d.CustpoNum=h.CustPoNum                          
    INNER JOIN #tmp t ON h.Id=t.Id                             
    INNER JOIN dbo.tblEdPartnerDoc pd (NOLOCK) ON h.PartnerID = pd.PartnerID AND pd.DocID = '850'        
    WHERE ISNULL(pd.VDPCode,'')<>'' AND h.ShipToCode=ISNULL(pd.VDPCode,'')  
    IF @@ERROR <> 0 GOTO ErrorTrap                          
                
    SET @ErrCode=168                 
    UPDATE h  SET h.ShipToCode=CASE WHEN ISNULL(h.VDPStore,'')<>'' THEN h.VDPStore ELSE h.FDOStore END
    FROM #tmp t   
    INNER JOIN dbo.tblEdPoHeader h ON t.Id=h.ID  
    INNER JOIN dbo.tblEdPartnerDoc pd (NOLOCK) ON h.PartnerID = pd.PartnerID AND pd.DocID = '850'        
    WHERE ISNULL(pd.VDPCode,'')<>'' AND h.ShipToCode=ISNULL(pd.VDPCode,'')  
    IF @@ERROR <> 0 GOTO ErrorTrap         
    */
      
    SET @ErrCode=166                 
    UPDATE d  SET d.StoreNum=h.VDPStore
    FROM dbo.tblEdPoDetail d  (NOLOCK)                         
    INNER JOIN dbo.tblEdPoHeader h (NOLOCK) ON d.ImportBatchId=h.ImportBatchId AND d.SenderId=h.SenderId AND d.CustpoNum=h.CustPoNum                          
    INNER JOIN #tmp t ON h.Id=t.Id                             
    INNER JOIN dbo.tblEdPartnerDoc pd (NOLOCK) ON h.PartnerID = pd.PartnerID AND pd.DocID = '850'        
    WHERE ISNULL(h.VDPStore,'')<>'' AND ISNULL(pd.VDPCode,'')<>'' AND h.ShipToCode=ISNULL(pd.VDPCode,'')  
    
    IF @@ERROR <> 0 GOTO ErrorTrap                          
                
    SET @ErrCode=168                 
    UPDATE h  SET h.ShipToCode=h.VDPStore
    FROM #tmp t   
    INNER JOIN dbo.tblEdPoHeader h ON t.Id=h.ID  
    INNER JOIN dbo.tblEdPartnerDoc pd (NOLOCK) ON h.PartnerID = pd.PartnerID AND pd.DocID = '850'        
    WHERE ISNULL(h.VDPStore,'')<>'' AND ISNULL(pd.VDPCode,'')<>'' AND h.ShipToCode=ISNULL(pd.VDPCode,'')  
    IF @@ERROR <> 0 GOTO ErrorTrap      
    
    
    -- Process FDO
    
   
    UPDATE h  SET  ShipToAttn=CASE WHEN ISNULL(s.EdiDsYN,0)=1 THEN SUBSTRING(h.FDOStore,5,100) ELSE h.ShipToName END,
                   ShipToName=CASE WHEN ISNULL(s.EdiDsYN,0)=1 THEN h.ShipToName ELSE  SUBSTRING(h.FDOStore,5,100)  END
    FROM #tmp t   
    INNER JOIN dbo.tblEdPoHeader h (NOLOCK) ON t.id =h.id      
    LEFT JOIN tblArShipTo s ON LEFT(h.FDOStore,4)=s.EdiShipToCode
    WHERE LEN(ISNULL(h.FDOStore,''))>4
   
    UPDATE h  SET  FDOStore=LEFT(h.FDOStore,4)
    FROM #tmp t   
    INNER JOIN dbo.tblEdPoHeader h (NOLOCK) ON t.id =h.id      
    WHERE LEN(ISNULL(h.FDOStore,''))>4
    
  --  SELECT * FROM  dbo.tblEdPoHeader
    --qryEdValidatePo
    
   -- select * from  dbo.tblEdPoHeader
   -- select * from dbo.tblEdPoErrorlog
                     
    SET @ErrCode=166                 
    UPDATE d  SET d.StoreNum=h.FDOStore
    FROM dbo.tblEdPoDetail d  (NOLOCK)                         
    INNER JOIN dbo.tblEdPoHeader h (NOLOCK) ON d.ImportBatchId=h.ImportBatchId AND d.SenderId=h.SenderId AND d.CustpoNum=h.CustPoNum                          
    INNER JOIN #tmp t ON h.Id=t.Id                             
    INNER JOIN dbo.tblEdPartnerDoc pd (NOLOCK) ON h.PartnerID = pd.PartnerID AND pd.DocID = '850'        
    WHERE ISNULL(h.FDOStore,'')<>'' AND ISNULL(pd.VDPCode,'')<>'' AND h.ShipToCode=ISNULL(pd.VDPCode,'')  
    
    IF @@ERROR <> 0 GOTO ErrorTrap                          
                
    SET @ErrCode=168                 
    UPDATE h  SET h.ShipToCode=h.FDOStore
    FROM #tmp t   
    INNER JOIN dbo.tblEdPoHeader h ON t.Id=h.ID  
    INNER JOIN dbo.tblEdPartnerDoc pd (NOLOCK) ON h.PartnerID = pd.PartnerID AND pd.DocID = '850'        
    WHERE ISNULL(h.FDOStore,'')<>'' AND ISNULL(pd.VDPCode,'')<>'' AND h.ShipToCode=ISNULL(pd.VDPCode,'')  
    IF @@ERROR <> 0 GOTO ErrorTrap    
    
    IF @CreateMissingVDStores=1   
    BEGIN  
      SET @ErrCode=164    
            
  --  INSERT INTO dbo.tblArShipTo (CustId,ShiptoId,ShiptoName,Addr1,Addr2 ,City,Region,Country,PostalCode,
   --                                EdiShipToType,EdiShipToCode,EdiShipToName,EdiShipToAbbrev,ShipVia)  
                                
      SELECT t.CustID, '00'+h.FDOStore,LEFT(h.ShipToName,14)+ ' # '+RIGHT(h.FDOStore,4),h.ShipToAddr1,h.ShipToAddr2,h.ShipToCity,h.ShipToRegion,
      CASE WHEN ISNULL(ShipToCountry,'')='' THEN 'USA' ELSE ShipToCountry END,ShipToPostalCode,1,
      h.FDOStore,
      LEFT(ISNULL(h.ShipToCity,'')+' '+ISNULL(h.ShipToRegion,''),20),
      h.FDOStore,
      'UPS TPC (403AE2)'
      FROM (SELECT tt.CustId,h.FDOStore,MIN(tt.Id) ID
            FROM  #tmp tt    
            INNER JOIN tblEdPoHeader h ON tt.ID=h.ID   
            LEFT JOIN tblArShipTo s ON  s.CustId=tt.CustId AND s.EdiShipToCode = h.FDOStore 
            WHERE ISNULL(h.FDOStore,'')<>'' AND s.ShiptoId IS NULL
            GROUP BY tt.CustId,h.FDOStore ) t
      INNER JOIN tblEdPoHeader h ON t.ID=h.ID   
      LEFT JOIN tblArShipTo s ON  s.CustId=t.CustId AND s.EdiShipToCode = h.FDOStore 
      WHERE ISNULL(h.FDOStore,'')<>'' AND s.ShiptoId IS NULL 
      
     -- select * from tblArShipTo where ShiptoId IN ('003470','001020')
     
      IF @@ERROR <> 0 GOTO ErrorTrap  
      
     -- GOTO ErrorTrap   
    END
    
 
 
                
                    -- SELECT * FROM dbo.tblEdPoHeader  
               --   DELETE from dbo.tblEdPoHeader  
               -- DELETE from dbo.tblEdPoDETAIL  
                    
-- ***** Department should be set to create SO                          
SET @ErrCode=170         
IF @ValidateYN=1                      
     BEGIN       
 EXEC dbo.trvsp_SmSetFunctionStatus 'EDI PO Validation', @ErrCode, 'Validate Transaction Creation'                          
 INSERT INTO dbo.tblEdPoErrorlog (ImportBatchId,Recid,PartnerId,CustPoNum ,LineNum, ErrCode,ErrDescr,ErrSequence,ErrRecType,ErrStatus)                          
 SELECT t.ImportBatchId,t.Id,t.PartnerID,t.CustPoNum,0,@ErrCode,'PO ['+ t.CustpoNum +'] Cannot create Transactions for department [' + h.Departmentid + ']',0,'H',2                          
 FROM #tmp t INNER JOIN dbo.tblEdPoHeader h (NOLOCK) ON t.id =h.id                    
 LEFT JOIN dbo.tblEdDepartment D (NOLOCK) ON h.DepartmentID=d.DepartmentId AND h.PartnerID=D.PartnerID                    
 WHERE D.optCreateSalesOrdersYN = 0                        
 IF @@ERROR <> 0 GOTO ErrorTrap                           
     END      
          
-- *****                      
                                            
-- ***** Validate Buyer info                    
      
IF @ValidateYN=1      
   BEGIN       
 SET @ErrCode=180      
 EXEC dbo.trvsp_SmSetFunctionStatus 'EDI PO Validation', @ErrCode, 'Validate Buyer Information'                          
 INSERT INTO dbo.tblEdPoErrorlog (ImportBatchId,Recid,PartnerId,CustPoNum ,LineNum, ErrCode,ErrDescr,ErrSequence,ErrRecType,ErrStatus)                          
 SELECT t.ImportBatchId,d.Id,t.PartnerID,t.CustPoNum,d.PoLineNum,@ErrCode,'PO ['+ t.CustpoNum +'] Line [' + d.PoLineNum + '] is missing store information',0,'D',2                     
 FROM  dbo.tblEdPoDetail d (NOLOCK)                          
 INNER JOIN dbo.tblEdPoHeader h (NOLOCK) ON d.ImportBatchId=h.ImportBatchId AND d.SenderId=h.SenderId AND d.CustpoNum=h.CustPoNum                          
 INNER JOIN #tmp t ON h.Id=t.Id                           
 WHERE ISNULL(StoreNum,'')=''                           
 IF @@ERROR <> 0 GOTO ErrorTrap                           
 -- *****      
  
   
                       
                          
 -- ***** Validate Store      
 SET @ErrCode=190      
 EXEC dbo.trvsp_SmSetFunctionStatus 'EDI PO Validation', @ErrCode, 'Validate Store Information'                          
 INSERT INTO dbo.tblEdPoErrorlog (ImportBatchId,Recid,PartnerId,CustPoNum ,LineNum, ErrCode,ErrDescr,ErrSequence,ErrRecType,ErrStatus)                          
 SELECT d.ImportBatchId,d.Id,t.PartnerID,t.CustPoNum,d.PoLineNum,@ErrCode,'PO ['+ t.CustpoNum +'] Store Number [' + d.StoreNum + '] not setup',0,'D',2                          
 FROM dbo.tblEdPoDetail d  (NOLOCK)                         
 INNER JOIN dbo.tblEdPoHeader h (NOLOCK) ON d.ImportBatchId=h.ImportBatchId AND d.SenderId=h.SenderId AND d.CustpoNum=h.CustPoNum                          
 INNER JOIN #tmp t ON h.Id=t.Id                           
 INNER JOIN dbo.tblEdPartner p (NOLOCK) ON t.PartnerId=p.PartnerId                          
 LEFT JOIN dbo.tblArShipTo st (NOLOCK) ON t.CustId=st.CustId AND d.StoreNum=st.EdiShipToCode                          
 WHERE ISNULL(st.CustId,'')=''             
 IF @@ERROR <> 0 GOTO ErrorTrap                           
 -- *****                          
                      
 -- ***** Validate Ship-to Information          
 SET @ErrCode=200      
 EXEC dbo.trvsp_SmSetFunctionStatus 'EDI PO Validation', @ErrCode, 'Validate Ship-to Information'                          
 INSERT INTO dbo.tblEdPoErrorlog (ImportBatchId,Recid,PartnerId,CustPoNum ,LineNum, ErrCode,ErrDescr,ErrSequence,ErrRecType,ErrStatus)                          
 SELECT d.ImportBatchId,d.Id,t.PartnerID,t.CustPoNum,d.PoLineNum,@ErrCode,'PO ['+ t.CustpoNum +',] Buyer [' + ISNULL(d.StoreNum,'') + ' ] ['+ISNULL(et.Descr,'')+'] [' +ISNULL(lnk.ARShipkey,'')+ '] not setup',0,'D',2                          
 FROM dbo.tblEdPoDetail d  (NOLOCK)                         
 INNER JOIN dbo.tblEdPoHeader h (NOLOCK) ON d.ImportBatchId=h.ImportBatchId AND d.SenderId=h.SenderId AND d.CustpoNum=h.CustPoNum                          
 INNER JOIN #tmp t ON h.Id=t.Id                             
 INNER JOIN dbo.tblArShipto st (NOLOCK) ON t.CustId=st.CustID AND d.StoreNum=st.ShipToId                          
 INNER JOIN dbo.tblEdpartner p  (NOLOCK) ON st.CustId=p.CustId                          
 INNER JOIN dbo.tblEdShipToType et (NOLOCK) ON p.DfltShipToType=et.ShipToTypeId                             
 LEFT JOIN (SELECT s.CustId,s.ShipToID,                           
            CASE WHEN p.DfltShipToType=1  THEN s.ShipToId                          
                 WHEN p.DfltShipToType=2 THEN s.EdiDistroId                           
                 WHEN p.DfltShipToType=3 THEN s.EdiConsolId END ARShipkey                          
            FROM dbo.tblArShipto s (NOLOCK)                          
            INNER JOIN dbo.tblEdpartner p (NOLOCK) ON s.CustId=p.CustId                          
            WHERE ISNULL(CASE WHEN p.DfltShipToType=1 THEN s.ShipToId                          
                              WHEN p.DfltShipToType=2 THEN s.EdiDistroId                           
                              WHEN p.DfltShipToType=3 THEN s.EdiConsolId END,'')<>'' ) lnk ON st.CustId=lnk.CustId AND st.ShipToId=lnk.ShipToId                            
            LEFT JOIN  dbo.tblArShipto stLnk (NOLOCK) ON lnk.CustId=stLnk.CustId AND lnk.ARShipkey=stLnk.ShipToId                         
 WHERE stLnk.CustId IS NULL 
 IF @@ERROR <> 0 GOTO ErrorTrap                
 -- *****           
      
   END       
      
      
IF @ValidateYN=1      
 --  BEGIN      
 --      UPDATE UnitsSell=,ItemId,ItemUpc      
 --      tblEdPoDetail       
 --  END       
--ELSE         
   BEGIN       
      
 -- *****  Save Item info into Temp      
 SET @ErrCode=210      
 EXEC dbo.trvsp_SmSetFunctionStatus 'EDI PO Validation', @ErrCode, 'Saving Item Information'           
       
       
 INSERT INTO #tmpItem (Id, ImportBatchId, SenderId, CustPoNum, UnitsSell ,Descr,DfltItemUirType,PartnerId)      
 SELECT d.Id,h.ImportBatchId,h.SenderId,h.CustPoNum,d.UnitsSellPo,ty.Descr , p.DfltItemUirType ,t.PartnerId      
 FROM #tmp t      
 INNER JOIN dbo.tblEdPoHeader h ON t.Id=h.Id      
 INNER JOIN dbo.tblEdPoDetail d ON h.ImportBatchId=d.ImportBatchId AND h.SenderId=d.SenderId AND h.CustpoNum=d.CustPoNum                            
 INNER JOIN dbo.tblEdPartner p (NOLOCK) ON t.CustId=p.CustId        
 LEFT JOIN dbo.tbledItemUirTypes ty (NOLOCK) ON p.DfltItemUirType=ty.UirTypeId        
 IF @@ERROR <> 0 GOTO ErrorTrap       
       
       
 UPDATE t SET iItem=xBuy.ItemID,iCode=d.ItemBuyerCode,UnitsSell=xBuy.ItemUom       
 FROM #tmpItem t       
 INNER JOIN dbo.tblEdPoDetail d ON t.Id=d.id        
 LEFT JOIN dbo.tbledPartnerItemXref xBuy (NOLOCK) ON  d.ItemBuyerCode=xBuy.ItemRef AND t.PartnerId=xBuy.PartnerID                          
 WHERE DfltItemUirType=1 AND ISNULL(d.ItemBuyerCode,'')<>''      
 IF @@ERROR <> 0 GOTO ErrorTrap       
       
 UPDATE t SET iItem=xVend.ItemID,iCode=d.ItemVendorCode,UnitsSell=xVend.ItemUom       
 FROM #tmpItem t       
 INNER JOIN dbo.tblEdPoDetail d ON t.Id=d.id        
 LEFT JOIN  dbo.tbledPartnerItemXref xVend (NOLOCK) ON  d.ItemVendorCode=xVend.ItemRef AND t.PartnerId=xVend.PartnerID      
 WHERE DfltItemUirType=2 AND ISNULL(d.ItemVendorCode,'')<>''      
 IF @@ERROR <> 0 GOTO ErrorTrap       
       
 UPDATE t SET iItem=uUpc.ItemID ,iCode=d.ItemUpc,UnitsSell=uUpc.UOM      
 FROM #tmpItem t       
 INNER JOIN dbo.tblEdPoDetail d ON t.Id=d.id        
 LEFT JOIN  dbo.tblInItemUom uUpc (NOLOCK) ON d.ItemUpc=uUpc.UpcCode       
 WHERE DfltItemUirType=3 AND ISNULL(d.ItemUpc ,'')<>''      
 IF @@ERROR <> 0 GOTO ErrorTrap       
       
 -- Update Item Info in Temp      
 UPDATE t SET iItem=uItem.ItemID,iCode=d.ItemUpc       
 FROM #tmpItem t       
 INNER JOIN dbo.tblEdPoDetail d ON t.Id=d.id        
 LEFT JOIN  dbo.tblInItemUom uItem (NOLOCK) ON d.itemId=uItem.ItemId AND d.UnitsSell=uItem.Uom      
 WHERE DfltItemUirType=4 AND ISNULL(d.itemId ,'')<>''      
 IF @@ERROR <> 0 GOTO ErrorTrap  
  
-- ***** Missing Item Info                          
 SET @ErrCode=230      
 EXEC dbo.trvsp_SmSetFunctionStatus 'EDI PO Validation', @ErrCode, 'Validate Item Information'                          
 INSERT INTO dbo.tblEdPoErrorlog (ImportBatchId,Recid,PartnerId,CustPoNum ,LineNum, ErrCode,ErrDescr,ErrSequence,ErrRecType,ErrStatus)                          
 SELECT d.ImportBatchId,it.Id,t.PartnerID,t.CustPoNum,d.PoLineNum,@ErrCode,'PO ['+ ISNULL(t.CustpoNum,'') +'] ['+ISNULL(it.Descr,'') +'] [' +ISNULL(it.iCode,'')+'] not setup',0,'D',3                          
 FROM #tmpItem it                          
 INNER JOIN #tmp t ON it.ImportBatchId=t.ImportBatchId AND it.SenderId=t.SenderId AND it.CustpoNum=t.CustPoNum                            
 INNER JOIN dbo.tblEdPoDetail d (NOLOCK) ON it.Id=d.Id                          
 WHERE ISNULL(it.iItem,'')=''                          
 IF @@ERROR <> 0 GOTO ErrorTrap        
       
 DELETE it FROM       
 #tmpItem it INNER JOIN dbo.tblEdPoErrorlog e (NOLOCK) ON it.Id=e.RecID      
 WHERE e.ErrRecType='D' AND ErrStatus=3                          
 IF @@ERROR <> 0 GOTO ErrorTrap                                              
        
       
    SET @ErrCode=217  
  
 -- check for missing required uom  
 INSERT INTO dbo.tblEdPoErrorlog (ImportBatchId,Recid,PartnerId,CustPoNum ,LineNum, ErrCode,ErrDescr,ErrSequence,ErrRecType,ErrStatus)                      
 SELECT t.ImportBatchId,it.Id,t.PartnerID,t.CustPoNum,d.PoLineNum,@ErrCode,'PO ['+ t.CustpoNum +'] '+ Descr +'['+it.iItem+ '] UOM XRef ['+d.UnitsSellPo+'] is Missing/Incorrect ' ,0,'D',3                      
  
    FROM #tmpItem it                      
 INNER JOIN #tmp t ON it.ImportBatchId=t.ImportBatchId AND it.SenderId=t.SenderId AND it.CustpoNum=t.CustPoNum                        
 INNER JOIN dbo.tblEdPoDetail d (NOLOCK) ON it.Id=d.Id    
 LEFT JOIN dbo.tbledPartnerItemXref x ON it.PartnerId=x.PartnerId AND it.iCode =x.ItemRef AND d.UnitsSellPo=x.ItemUomXRef-- it.iItem=x.ItemId AND it.UnitsSell=x.ItemUom  
 INNER  JOIN tblEdPartner p ON it.PartnerID=p.PartnerId   
 WHERE p.optUseUomXrefYN=1 AND (ISNULL(x.ItemUomXref,'')='' )-- OR d.UnitsSell<>x.ItemUomXref)   
 IF @@ERROR <> 0 GOTO ErrorTrap    
      
    DELETE it FROM       
    #tmpItem it INNER JOIN dbo.tblEdPoErrorlog e (NOLOCK) ON it.Id=e.RecID      
    WHERE e.ErrRecType='D' AND ErrStatus=3                          
    IF @@ERROR <> 0 GOTO ErrorTrap                                              
 -- *****                          
/*  
declare @x int            
exec qryEdValidatePo @x out          
select @x          
       
rollback    
*/  
 UPDATE d SET UnitsSell=t.UnitsSell      
 FROM #tmpItem t       
 INNER JOIN dbo.tblEdPoDetail d ON t.Id=d.id         
 IF @@ERROR <> 0 GOTO ErrorTrap       
                                               
                   
 -- ***** Get item id and upc                          
 SET @ErrCode=220      
 UPDATE d SET ItemId=it.iItem,ItemUpc=u.UpcCode                          
 FROM dbo.tblEdpoDetail d                           
 INNER JOIN #tmpItem it ON d.Id=it.Id                          
 LEFT JOIN dbo.tblInItemUom u (NOLOCK) ON it.iItem=u.ItemId AND it.UnitsSell=d.UnitsSell                            
 IF @@ERROR <> 0 GOTO ErrorTrap                           
 -- *****                          
                                               
 -- *****                          
       
 -- ***** csi 05/19/08      
 SET @ErrCode=235      
       
 EXEC dbo.trvsp_SmSetFunctionStatus 'EDI PO Validation', @ErrCode, 'Validate Item UOM Information'                          
 INSERT INTO dbo.tblEdPoErrorlog (ImportBatchId,Recid,PartnerId,CustPoNum ,LineNum, ErrCode,ErrDescr,ErrSequence,ErrRecType,ErrStatus)                          
 SELECT t.ImportBatchId,it.Id,t.PartnerID,t.CustPoNum,d.PoLineNum,@ErrCode,'PO ['+ t.CustpoNum +'] '+ Descr +' UOM ['+ it.UnitsSell + '] not found for ['+ it.iCode + ']' ,0,'D',3                          
 FROM #tmpItem it                          
 INNER JOIN #tmp t ON it.ImportBatchId=t.ImportBatchId AND it.SenderId=t.SenderId AND it.CustpoNum=t.CustPoNum                            
 INNER JOIN dbo.tblEdPoDetail d (NOLOCK) ON it.Id=d.Id                 
 --LEFT JOIN dbo.tbledPartnerItemXref xBuy (NOLOCK) ON  d.ItemBuyerCode=xBuy.ItemRef AND t.PartnerId=xBuy.PartnerID                          
 --LEFT JOIN dbo.tbledPartnerItemXref xBuy (NOLOCK) ON  d.ItemBuyerCode=xBuy.ItemRef AND t.PartnerId=xBuy.PartnerID                          
 --LEFT JOIN dbo.tbledPartnerItemXref xBuy (NOLOCK) ON  d.ItemBuyerCode=xBuy.ItemRef AND t.PartnerId=xBuy.PartnerID                          
 WHERE ISNULL(it.UnitsSell,'') = ''      
 IF @@ERROR <> 0 GOTO ErrorTrap                           
      
      
      
 DELETE it FROM       
 #tmpItem it INNER JOIN dbo.tblEdPoErrorlog e (NOLOCK) ON it.Id=e.RecID      
 WHERE e.ErrRecType='D' AND ErrStatus=3                          
 IF @@ERROR <> 0 GOTO ErrorTrap                           
 -- ***** csi 05/19/08      
       
 -- ***** Missing UPC                          
 SET @ErrCode=240      
 EXEC dbo.trvsp_SmSetFunctionStatus 'EDI PO Validation', @ErrCode, 'Validate UPC Information'                          
 INSERT INTO dbo.tblEdPoErrorlog (ImportBatchId,Recid,PartnerId,CustPoNum ,LineNum, ErrCode,ErrDescr,ErrSequence,ErrRecType,ErrStatus)                          
 SELECT t.ImportBatchId,it.Id,t.PartnerID,t.CustPoNum,d.PoLineNum,@ErrCode,'PO ['+ t.CustpoNum +'] '+ Descr +' ['+ it.iCode + '] not found Item [' + it.iitem + ']',0,'D',3                          
 FROM #tmpItem it                          
 INNER JOIN #tmp t ON it.ImportBatchId=t.ImportBatchId AND it.SenderId=t.SenderId AND it.CustpoNum=t.CustPoNum                            
 INNER JOIN dbo.tblEdPoDetail d (NOLOCK) ON it.Id=d.Id                          
 WHERE ISNULL(d.ItemUpc,'')=''   and it.DfltItemUirType = 3 --UPC                      
 IF @@ERROR <> 0 GOTO ErrorTrap                           
       
 DELETE it FROM       
 #tmpItem it INNER JOIN dbo.tblEdPoErrorlog e (NOLOCK) ON it.Id=e.RecID      
 WHERE e.ErrRecType='D' AND ErrStatus=3                          
 IF @@ERROR <> 0 GOTO ErrorTrap                                              
 -- *****                           
                           
 -- ***** Item not found in location                          
 SET @ErrCode=250      
 EXEC dbo.trvsp_SmSetFunctionStatus 'EDI PO Validation', @ErrCode, 'Validate Item Location'                          
 INSERT INTO dbo.tblEdPoErrorlog (ImportBatchId,Recid,PartnerId,CustPoNum ,LineNum, ErrCode,ErrDescr,ErrSequence,ErrRecType,ErrStatus)                          
 SELECT t.ImportBatchId,it.Id,t.PartnerID,t.CustPoNum,d.PoLineNum,@ErrCode,'PO ['+ t.CustpoNum +'] '+ Descr +' ['+ISNULL(it.iCode,'')+ '] ' +  'not found in location ['+ @DfltLoc+']' + 'Item [' + it.iitem + ']',0,'D',3                          
 FROM #tmpItem it                          
 INNER JOIN #tmp t ON it.ImportBatchId=t.ImportBatchId AND it.SenderId=t.SenderId AND it.CustpoNum=t.CustPoNum                            
 INNER JOIN dbo.tblEdPoDetail d (NOLOCK) ON it.Id=d.Id                          
 LEFT JOIN dbo.tblInItemLoc il (NOLOCK) ON it.iItem=il.ItemId AND il.LocId=@DfltLoc                          
 WHERE il.ItemID IS NULL                          
 IF @@ERROR <> 0 GOTO ErrorTrap         
              
 DELETE it FROM       
 #tmpItem it INNER JOIN dbo.tblEdPoErrorlog e (NOLOCK) ON it.Id=e.RecID      
 WHERE e.ErrRecType='D' AND ErrStatus=3                          
 IF @@ERROR <> 0 GOTO ErrorTrap                                              
 -- *****                         
                                                                  
 -- ***** Item Price                 
 SET @ErrCode=260                    
 EXEC dbo.trvsp_SmSetFunctionStatus 'EDI PO Validation', @ErrCode, 'Validate Item Price'                          
                       
 DECLARE Cur CURSOR FOR                       
      SELECT PartnerID, UnitPrice,QtyOrd ,  ItemID, [ID], UnitsSell FROM dbo.tblEdPoDetail                      
 OPEN Cur                      
      FETCH NEXT FROM Cur INTO @PartnerID, @UnitPrice, @QtyOrd, @ItemID, @ID, @UnitsSell                      
       
 WHILE @@FETCH_STATUS = 0                      
   BEGIN                      
                       
      SELECT @custid=p.custid,@CustLevel = c.CustLevel, @CustPriceId = c.PriceCode                      
      FROM tblEdPartner p (NOLOCK) INNER JOIN tblArcust  c (NOLOCK) ON p.custid=c.custid                        
      WHERE p.partnerid=@PartnerID                        
                                               
      SELECT @UnitBasePrice = 0                         
                    
                                           
      EXEC dbo.qrySoPriceCalc                        
    @ItemId=@ItemId,                        
           @LocId=@DfltLoc,                               @Uom=@UnitsSell,                        
           @Qty=@QtyOrd,                        
           @gPrecUPrice = @PrecUPrice,                        
           @CustLevel=@CustLevel,                        
           @PriceID=@CustPriceID,     
   @gPrecUcost = @PrecUcost,                        
           @CalcPrice=@unitbasePrice OUT                        
      IF @@ERROR <> 0 GOTO ErrorTrap         
        
      IF @UnitBasePrice <> @UnitPrice                      
      BEGIN             
       
               
        INSERT INTO dbo.tblEdPoErrorlog (ImportBatchId,Recid,PartnerId,CustPoNum ,LineNum, ErrCode,ErrDescr,ErrSequence,ErrRecType,ErrStatus)                       
        SELECT t.ImportBatchId,it.Id,t.PartnerID,t.CustPoNum,d.PoLineNum,@ErrCode,    
        'PO ['+ t.CustpoNum +'] '+ Descr +' ['+ISNULL(it.iCode,'')+ '] Price [' + cast(cast(round(@UnitPrice, @PrecUPrice) as dec(10,4)) as varchar) +'] does not match Base Price [' +     
        cast(cast(@UnitBasePrice as dec(10,4)) as varchar)  + '] ' + 'Item [' + it.iItem + ']' ,0,'D',case @ForcePOPrice when 0 then 2 else 1 end                   
        FROM #tmpItem it INNER JOIN #tmp t ON it.ImportBatchId=t.ImportBatchId AND it.SenderId=t.SenderId AND it.CustpoNum=t.CustPoNum                        
        INNER JOIN dbo.tblEdPoDetail d (NOLOCK) ON it.Id=d.Id  
        INNER JOIn dbo.tblEdPartner p ON  t.PartnerID=p.PartnerID                       
        WHERE d.ID = @ID AND isnull(p.optUseInvPrice,0)=0  
        IF @@ERROR <> 0 GOTO ErrorTrap      
      END                      
                                    
    FETCH NEXT FROM Cur INTO @PartnerID, @UnitPrice, @QtyOrd, @ItemID, @ID, @UnitsSell                      
 END                      
 CLOSE Cur                      
 DEALLOCATE Cur                      
-- *****      
   END -- AvlidateYN       
      
      
-- ***** Update Status in Po DETAIL File         
EXEC dbo.trvsp_SmSetFunctionStatus 'EDI PO Validation', @ErrCode, 'Updating PO Status'          
SET @ErrCode=270                        
UPDATE d SET ErrorCode=CASE WHEN ISNULL(ErrStatus,0)>1 THEN 1 ELSE 0 END      
FROM dbo.tblEdPoDetail d      
LEFT JOIN (SELECT RecId,MAX(ErrStatus) ErrStatus       
    FROM  dbo.tblEdPoErrorlog (NOLOCK)       
           WHERE ErrRecType='D'      
           GROUP BY RecId) l ON d.Id=l.RecId      
IF @@ERROR <> 0 GOTO ErrorTrap      
-- *****      
      
-- ***** Update Status in Po HEADER File         
SET @ErrCode=280                        
UPDATE h SET ErrorCode=CASE WHEN ISNULL(ErrStatus,0)>1 THEN 1 ELSE 0 END      
FROM dbo.tblEdPoHeader h      
LEFT JOIN (SELECT RecId,MAX(ErrStatus) ErrStatus       
    FROM  dbo.tblEdPoErrorlog (NOLOCK)       
           WHERE ErrRecType='H'      
           GROUP BY RecId) l ON h.Id=l.RecId      
IF @@ERROR <> 0 GOTO ErrorTrap      
-- *****      
      
-- ***** Reupdate Status in Po HEADER from Detail      
SET @ErrCode=290                        
UPDATE h SET ErrorCode=d.ErrorCode      
FROM dbo.tblEdPoHeader h      
INNER JOIN (SELECT ImportBatchId,PartnerId,CustPoNum,MAX(ErrorCode) ErrorCode      
            FROM dbo.tblEdPoDetail d (NOLOCK)      
            GROUP BY ImportBatchId,PartnerId,CustPoNum)d ON h.ImportBatchId=d.ImportBatchId AND h.PartnerId=d.PartnerId AND h.CustPoNum=d.CustPoNum      
WHERE h.ErrorCode=0      
-- *****      
      
-- ***** Do Copy to Po Acknol      
SET @ErrCode=300      
--Exec dbo.qryEdPOUpdateAck                 
IF @@ERROR <> 0 GOTO ErrorTrap          
-- *****          
      
-- ***** Return total valid POS         
SET @ErrCode=310       
SELECT  @TotCount=COUNT(*) FROM dbo.tblEdPoHeader (NOLOCK) WHERE ErrorCode=0                 
IF @@ERROR <> 0 GOTO ErrorTrap          
-- *****        
        
IF @@ERROR <> 0 GOTO ErrorTrap         
                        
EXEC dbo.trvsp_SmSetFunctionStatus 'EDI PO Validation', @ErrCode, 'Committing the post'           
                  
                         
COMMIT TRANSACTION                           
                          
EXEC dbo.trvsp_SmSetFunctionStatus 'EDI PO Validation', @ErrCode, 'Stopping the post'                            
                          
RETURN 0                           
                          
ErrorTrap:                            
 IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION                            
 RETURN @ErrCode




