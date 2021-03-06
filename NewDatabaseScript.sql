IF NOT EXISTS (SELECT name FROM master.dbo.sysdatabases WHERE name = N'ReportServer') CREATE DATABASE [ReportServer] COLLATE Latin1_General_CI_AS_KS_WS
GO

IF NOT EXISTS (SELECT name FROM master.dbo.sysdatabases WHERE name = N'ReportServerTempDB') CREATE DATABASE [ReportServerTempDB] COLLATE Latin1_General_CI_AS_KS_WS
GO

USE [ReportServer]
GO

if not exists (select * from sysusers where issqlrole = 1 and name = 'RSExecRole')
BEGIN
 EXEC sp_addrole 'RSExecRole'
END
GO

USE msdb
GO

if not exists (select * from sysusers where issqlrole = 1 and name = 'RSExecRole')
BEGIN
 EXEC sp_addrole 'RSExecRole'
END
GO

USE master
GO

if not exists (select * from sysusers where issqlrole = 1 and name = 'RSExecRole')
BEGIN
 EXEC sp_addrole 'RSExecRole'
END
GO

USE [ReportServerTempDB]
GO

if not exists (select * from sysusers where issqlrole = 1 and name = 'RSExecRole')
BEGIN
 EXEC sp_addrole 'RSExecRole'
END
GO

USE [ReportServerTempDB]
GO

-- !!! This assumes the database is created and the user is either a dbo or is added to the RSExecRole
-- !!! Please run setup to create the database, users, role !!!

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetDBVersion]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetDBVersion]
GO

CREATE PROCEDURE [dbo].[GetDBVersion]
@DBVersion nvarchar(32) OUTPUT
AS
set @DBVersion = 'T.0.8.40'
GO
GRANT EXECUTE ON [dbo].[GetDBVersion] TO RSExecRole
GO

-------------------------------------------------------

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SessionLock]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[SessionLock]
GO

CREATE TABLE [dbo].[SessionLock] (
    [SessionID] varchar(32) NOT NULL
)
GO

GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES ON [dbo].[SessionLock] TO RSExecRole
GO

CREATE UNIQUE CLUSTERED INDEX [IDX_SessionLock] ON [dbo].[SessionLock]([SessionID])
GO

-------------------------------------------------------

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SessionData]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[SessionData]
GO

CREATE TABLE [dbo].[SessionData] (
    [SessionID] varchar(32) NOT NULL,
    [CompiledDefinition] uniqueidentifier NULL, -- when session starts from definition, this holds compiled definition snapshot id
    [SnapshotDataID] uniqueidentifier NULL,
    [IsPermanentSnapshot] bit NULL,
    [ReportPath] nvarchar(424) NULL, -- Report Path is empty string ("") when session starts from definition
    [Timeout] int NOT NULL,
    [AutoRefreshSeconds] int NULL, -- How often data should be refreshed
    [Expiration] datetime NOT NULL,
    [ShowHideInfo] image NULL,
    [DataSourceInfo] image NULL,
    [OwnerID] uniqueidentifier NOT NULL,
    [EffectiveParams] ntext NULL,
    [CreationTime] DateTime NOT NULL,
    [HasInteractivity] bit NULL,
    [SnapshotExpirationDate] datetime NULL, -- when this snapshot expires - cache or exec snapshot
    [HistoryDate] datetime NULL, -- if this is not null, session was started from history
    [PageHeight] float NULL,  -- page properties are only populated for temporary reports.
    [PageWidth] float NULL,
    [TopMargin] float NULL,
    [BottomMargin] float NULL,
    [LeftMargin] float NULL,
    [RightMargin] float NULL,
    [ExecutionType] smallint NULL
)
GO

EXEC sp_tableoption N'[dbo].[SessionData]', 'text in row', 'ON'
GO

GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES ON [dbo].[SessionData] TO RSExecRole
GO

CREATE UNIQUE CLUSTERED INDEX [IDX_SessionData] ON [dbo].[SessionData]([SessionID])
GO

CREATE INDEX [IX_SessionCleanup] ON [dbo].[SessionData]([Expiration])
GO

CREATE INDEX [IX_SessionSnapshotID] ON [dbo].[SessionData]([SnapshotDataID])
GO

-------------------------------------------------------

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ExecutionCache]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[ExecutionCache]
GO

CREATE TABLE [dbo].[ExecutionCache] (
    [ExecutionCacheID] uniqueidentifier NOT NULL,
    [ReportID] uniqueidentifier NOT NULL,
    [ExpirationFlags] int NOT NULL,
    [AbsoluteExpiration] datetime NULL,
    [RelativeExpiration] int NULL,
    [SnapshotDataID] uniqueidentifier NOT NULL
)
GO

GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES ON [dbo].[ExecutionCache] TO RSExecRole
GO

ALTER TABLE [dbo].[ExecutionCache] ADD 
    CONSTRAINT [PK_ExecutionCache] PRIMARY KEY NONCLUSTERED
    (
         [ExecutionCacheID]
    )
GO

CREATE UNIQUE CLUSTERED INDEX [IX_ExecutionCache] ON [dbo].[ExecutionCache] ([AbsoluteExpiration] DESC, [ReportID], [SnapshotDataID]) 
GO

-------------------------------------------------------

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SnapshotData]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[SnapshotData]
GO

CREATE TABLE [dbo].[SnapshotData]  (
    [SnapshotDataID] uniqueidentifier NOT NULL,
    [CreatedDate] datetime NOT NULL,
    [ParamsHash] int NULL, -- Hash of values of parameters that are used in query
    [QueryParams] ntext NULL, -- Values of parameters that are used in query
    [EffectiveParams] ntext NULL, -- Full set of effective parameters
    [Description] nvarchar(512) NULL,
    [DependsOnUser] bit NULL,
    [PermanentRefcount] int NOT NULL, -- this counts only permanent references, NOT SESSIONS!!!
    [TransientRefcount] int NOT NULL, -- this is to count sessions, may be more than expected
    [ExpirationDate] datetime NOT NULL, -- Expired snapshots should be erased regardless of TransiendRefcount
    [PageCount] int NULL,
    [HasDocMap] bit NULL,
    [Machine] nvarchar(512) NOT NULL
)
GO

EXEC sp_tableoption N'[dbo].[SnapshotData]', 'text in row', 'ON'
GO

GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES ON [dbo].[SnapshotData] TO RSExecRole
GO

ALTER TABLE [dbo].[SnapshotData] ADD 
    CONSTRAINT [PK_SnapshotData] PRIMARY KEY CLUSTERED
    (
         [SnapshotDataID]
    )
GO

CREATE INDEX [IX_SnapshotCleaning] ON [dbo].[SnapshotData]([PermanentRefcount], [TransientRefcount])
GO

CREATE INDEX [IS_SnapshotExpiration] ON [dbo].[SnapshotData]([PermanentRefcount], [ExpirationDate])
GO

-------------------------------------------------------

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ChunkData]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[ChunkData]
GO

CREATE TABLE [dbo].[ChunkData] (
    [ChunkID]  uniqueidentifier NOT NULL,
    [SnapshotDataID] uniqueidentifier NOT NULL,
    [ChunkFlags] tinyint NULL,
    [ChunkName] nvarchar(260), -- Name of the chunk
    [ChunkType] int, -- internal type of the chunk
    [Version] smallint NULL, -- version of the chunk    
    [MimeType] nvarchar(260), -- mime type of the content of the chunk
    [Content] image -- content of the chunk
)
GO

GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES ON [dbo].[ChunkData] TO RSExecRole
GO

ALTER TABLE [dbo].[ChunkData] WITH NOCHECK ADD 
    CONSTRAINT [PK_ChunkData] PRIMARY KEY NONCLUSTERED 
    (
        [ChunkID]
    )  ON [PRIMARY] 
GO

CREATE UNIQUE CLUSTERED INDEX [IX_ChunkData] ON [dbo].[ChunkData]([SnapshotDataID], [ChunkType], [ChunkName]) ON [PRIMARY]
GO

-------------------------------------------------------

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[PersistedStream]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[PersistedStream]
GO

CREATE TABLE [dbo].[PersistedStream] (
    [SessionID] varchar(32) NOT NULL,
    [Index] int NOT NULL,
    [Content] image NULL,
    [Name] nvarchar(260) NULL,
    [MimeType] nvarchar(260) NULL,
    [Extension] nvarchar(260) NULL,
    [Encoding] nvarchar(260) NULL,
    [Error] nvarchar(512) NULL,
    [RefCount] int NOT NULL,
    [ExpirationDate] datetime NOT NULL
)  ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES ON [dbo].[PersistedStream] TO RSExecRole
GO

ALTER TABLE [dbo].[PersistedStream] ADD
    CONSTRAINT [PK_PersistedStream] PRIMARY KEY CLUSTERED 
    (
        [SessionID],
        [Index]
    ) ON [PRIMARY]
GO


USE [ReportServer]
GO

-- !!! This assumes the database is created and the user is either a dbo or is added to the RSExecRole
-- !!! Please run setup to create the database, users, role !!!


--------------------------------------------------
------------- Database version
--------------------------------------------------

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetDBVersion]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetDBVersion]
GO

CREATE PROCEDURE [dbo].[GetDBVersion]
@DBVersion nvarchar(32) OUTPUT
AS
SET @DBVersion = 'C.0.8.40'
GO

GRANT EXECUTE ON [dbo].[GetDBVersion] TO RSExecRole
GO

-- gchander 6/25/03: dbo always exist; db.dbo.table preferred over db..table; dbo, not DBO if case sensitive
-- SessionData, SessionLock, ExecutionCache will be in tempdb. SnapshotData and ChunkData in both.
-- Snapshots pointed to by IF, Execution Snapshot, history will be in main db, all the rest in tempdb


--------------------------------------------------
------------- Deletion of Foreign Keys
--------------------------------------------------

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FK_ModelDrillModel]') and OBJECTPROPERTY(id, N'IsForeignKey') = 1)
ALTER TABLE [dbo].[ModelDrill] DROP CONSTRAINT [FK_ModelDrillModel]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FK_ModelPerspectiveModel]') and OBJECTPROPERTY(id, N'IsForeignKey') = 1)
ALTER TABLE [dbo].[ModelPerspective] DROP CONSTRAINT [FK_ModelPerspectiveModel]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FK_ModelDrillReport]') and OBJECTPROPERTY(id, N'IsForeignKey') = 1)
ALTER TABLE [dbo].[ModelDrill] DROP CONSTRAINT [FK_ModelDrillReport]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FK_ChunkDataSnapshotDataID]') and OBJECTPROPERTY(id, N'IsForeignKey') = 1)
ALTER TABLE [dbo].[ChunkData] DROP CONSTRAINT [FK_ChunkDataSnapshotDataID]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FK_DataSourceItemID]') and OBJECTPROPERTY(id, N'IsForeignKey') = 1)
ALTER TABLE [dbo].[DataSource] DROP CONSTRAINT [FK_DataSourceItemID]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FK_CachePolicyReportID]') and OBJECTPROPERTY(id, N'IsForeignKey') = 1)
ALTER TABLE [dbo].[CachePolicy] DROP CONSTRAINT [FK_CachePolicyReportID]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FK_PolicyUserRole_User]') and OBJECTPROPERTY(id, N'IsForeignKey') = 1)
ALTER TABLE [dbo].[PolicyUserRole] DROP CONSTRAINT [FK_PolicyUserRole_User]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FK_PolicyUserRole_Role]') and OBJECTPROPERTY(id, N'IsForeignKey') = 1)
ALTER TABLE [dbo].[PolicyUserRole] DROP CONSTRAINT [FK_PolicyUserRole_Role]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FK_PolicyUserRole_Policy]') and OBJECTPROPERTY(id, N'IsForeignKey') = 1)
ALTER TABLE [dbo].[PolicyUserRole] DROP CONSTRAINT [FK_PolicyUserRole_Policy]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FK_DeliveryProviders_Provider]') and OBJECTPROPERTY(id, N'IsForeignKey') = 1)
ALTER TABLE [dbo].[DeliveryProvider] DROP CONSTRAINT [FK_DeliveryProviders_Provider]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FK_Subscriptions_Provider]') and OBJECTPROPERTY(id, N'IsForeignKey') = 1)
ALTER TABLE [dbo].[Subscriptions] DROP CONSTRAINT [FK_Subscriptions_Provider]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FK_Subscriptions_Owner]') and OBJECTPROPERTY(id, N'IsForeignKey') = 1)
ALTER TABLE [dbo].[Subscriptions] DROP CONSTRAINT [FK_Subscriptions_Owner]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FK_Subscriptions_ModifiedBy]') and OBJECTPROPERTY(id, N'IsForeignKey') = 1)
ALTER TABLE [dbo].[Subscriptions] DROP CONSTRAINT [FK_Subscriptions_ModifiedBy]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FK_Schedule_Catalog]') and OBJECTPROPERTY(id, N'IsForeignKey') = 1)
ALTER TABLE [dbo].[Schedule] DROP CONSTRAINT [FK_Schedule_Catalog]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FK_ReportSchedule_Report]') and OBJECTPROPERTY(id, N'IsForeignKey') = 1)
ALTER TABLE [dbo].[ReportSchedule] DROP CONSTRAINT [FK_ReportSchedule_Report]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FK_Schedule_Users]') and OBJECTPROPERTY(id, N'IsForeignKey') = 1)
ALTER TABLE [dbo].[Schedule] DROP CONSTRAINT [FK_Schedule_Users]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FK_ReportSchedule_Schedule]') and OBJECTPROPERTY(id, N'IsForeignKey') = 1)
ALTER TABLE [dbo].[ReportSchedule] DROP CONSTRAINT [FK_ReportSchedule_Schedule]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FK_ReportSchedule_Subscriptions]') and OBJECTPROPERTY(id, N'IsForeignKey') = 1)
ALTER TABLE [dbo].[ReportSchedule] DROP CONSTRAINT [FK_ReportSchedule_Subscriptions]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FK_Catalog_ParentID]') and OBJECTPROPERTY(id, N'IsForeignKey') = 1)
ALTER TABLE [dbo].[Catalog] DROP CONSTRAINT [FK_Catalog_ParentID]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FK_Catalog_LinkSourceID]') and OBJECTPROPERTY(id, N'IsForeignKey') = 1)
ALTER TABLE [dbo].[Catalog] DROP CONSTRAINT [FK_Catalog_LinkSourceID]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FK_Catalog_Policy]') and OBJECTPROPERTY(id, N'IsForeignKey') = 1)
ALTER TABLE [dbo].[Catalog] DROP CONSTRAINT [FK_Catalog_Policy]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FK_Catalog_CreatedByID]') and OBJECTPROPERTY(id, N'IsForeignKey') = 1)
ALTER TABLE [dbo].[Catalog] DROP CONSTRAINT [FK_Catalog_CreatedByID]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FK_Catalog_ModifiedByID]') and OBJECTPROPERTY(id, N'IsForeignKey') = 1)
ALTER TABLE [dbo].[Catalog] DROP CONSTRAINT [FK_Catalog_ModifiedByID]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FK_Subscriptions_Catalog]') and OBJECTPROPERTY(id, N'IsForeignKey') = 1)
ALTER TABLE [dbo].[Subscriptions] DROP CONSTRAINT [FK_Subscriptions_Catalog]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FK_Notifications_Subscriptions]') and OBJECTPROPERTY(id, N'IsForeignKey') = 1)
ALTER TABLE [dbo].[Notifications] DROP CONSTRAINT [FK_Notifications_Subscriptions]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FK_Snapshot_Catalog]') and OBJECTPROPERTY(id, N'IsForeignKey') = 1)
ALTER TABLE [dbo].[Notifications] DROP CONSTRAINT [FK_Snapshot_Catalog]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FK_ActiveSubscriptions_Subscriptions]') and OBJECTPROPERTY(id, N'IsForeignKey') = 1)
ALTER TABLE [dbo].[ActiveSubscriptions] DROP CONSTRAINT [FK_ActiveSubscriptions_Subscriptions]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FK_SecDataPolicyID]') and OBJECTPROPERTY(id, N'IsForeignKey') = 1)
ALTER TABLE [dbo].[SecData] DROP CONSTRAINT [FK_SecDataPolicyID]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FK_PoliciesPolicyID]') and OBJECTPROPERTY(id, N'IsForeignKey') = 1)
ALTER TABLE [dbo].[ModelItemPolicy] DROP CONSTRAINT [FK_PoliciesPolicyID]
GO


--------------------------------------------------
------------- Deletion of Triggers
--------------------------------------------------

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[Provider_Subscription]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
drop trigger [dbo].[Provider_Subscription]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[Item_Subscription]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
drop trigger [dbo].[Item_Subscription]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[History_Notifications]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
drop trigger [dbo].[History_Notifications]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[HistoryDelete_SnapshotRefcount]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
drop trigger [dbo].[HistoryDelete_SnapshotRefcount]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ReportSchedule_Schedule]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
drop trigger [dbo].[ReportSchedule_Schedule]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[Schedule_UpdateExpiration]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
drop trigger [dbo].[Schedule_UpdateExpiration]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[Schedule_DeleteAgentJob]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
drop trigger [dbo].[Schedule_DeleteAgentJob]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[Subscription_delete_DataSource]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
drop trigger [dbo].[Subscription_delete_DataSource]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[Subscription_delete_Schedule]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
drop trigger [dbo].[Subscription_delete_Schedule]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CacheDelete_SnapshotRefcount]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
drop trigger [dbo].[CacheDelete_SnapshotRefcount]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CacheInsert_SnapshotRefcount]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
drop trigger [dbo].[CacheInsert_SnapshotRefcount]
GO


--------------------------------------------------
------------- Deletion of Tables
--------------------------------------------------

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ModelDrill]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[ModelDrill]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ServerParametersInstance]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[ServerParametersInstance]
GO


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ModelPerspective]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[ModelPerspective]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SnapshotData]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[SnapshotData]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ChunkData]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[ChunkData]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CachePolicy]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[CachePolicy]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DeliveryProvider]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[DeliveryProvider]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[Provider]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[Provider]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ConfigurationInfo]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[ConfigurationInfo]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[Notifications]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[Notifications]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[Catalog]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[Catalog]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DataSource]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[DataSource]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[Users]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[Users]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[Policies]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[Policies]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SecData]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[SecData]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[Roles]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[Roles]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[PolicyUserRole]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[PolicyUserRole]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ReportSchedule]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[ReportSchedule]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ActiveSubscriptions]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[ActiveSubscriptions]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[Schedule]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[Schedule]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[Subscriptions]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[Subscriptions]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[Event]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[Event]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[History]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[History]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[Keys]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[Keys]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ModelItemPolicy]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[ModelItemPolicy]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[RunningJobs]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[RunningJobs]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ExecutionLog]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[ExecutionLog]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[Batch]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[Batch]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[UpgradeInfo]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[UpgradeInfo]
GO


--------------------------------------------------
------------- Creation of tables
--------------------------------------------------

CREATE TABLE [dbo].[Keys] (
    [MachineName] nvarchar(256) NULL,
    [InstallationID] uniqueidentifier NOT NULL,
    [InstanceName] nvarchar(32) NULL,
    [Client] int NOT NULL, -- 1 = Service, -1 = lock record
    [PublicKey] image,
    [SymmetricKey] image
) ON [PRIMARY]
GO

GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES ON [dbo].[Keys] TO RSExecRole
GO

ALTER TABLE [dbo].[Keys] WITH NOCHECK ADD 
    CONSTRAINT [PK_Keys] PRIMARY KEY CLUSTERED (
        [InstallationID],
        [Client]
    ) ON [PRIMARY] 
GO

-- The lock row
insert into [dbo].[Keys]
    ([MachineName], [InstanceName], [InstallationID], [Client], [PublicKey], [SymmetricKey])
values
    (null, null, '00000000-0000-0000-0000-000000000000', -1, null, null)

CREATE TABLE [dbo].[History] (
    [HistoryID] [uniqueidentifier] NOT NULL,
    [ReportID] [uniqueidentifier] NOT NULL,
    [SnapshotDataID] [uniqueidentifier] NOT NULL,
    [SnapshotDate] [datetime] NOT NULL
) ON [PRIMARY]
GO

GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES ON [dbo].[History] TO RSExecRole
GO

ALTER TABLE [dbo].[History] WITH NOCHECK ADD 
    CONSTRAINT [PK_History] PRIMARY KEY NONCLUSTERED (
        [HistoryID]
    ) ON [PRIMARY] 
GO

CREATE UNIQUE CLUSTERED INDEX [IX_History] ON [dbo].[History]([ReportID], [SnapshotDate]) ON [PRIMARY]
GO

CREATE TRIGGER [dbo].[HistoryDelete_SnapshotRefcount] ON [dbo].[History] 
AFTER DELETE
AS
   UPDATE [dbo].[SnapshotData]
   SET [PermanentRefcount] = [PermanentRefcount] - 1
   FROM [SnapshotData] SD INNER JOIN deleted D on SD.[SnapshotDataID] = D.[SnapshotDataID]
GO

CREATE TRIGGER [dbo].[History_Notifications] ON [dbo].[History]  
AFTER INSERT
AS 
   insert
      into [dbo].[Event]
      ([EventID], [EventType], [EventData], [TimeEntered]) 
      select NewID(), 'ReportHistorySnapshotCreated', inserted.[HistoryID], GETUTCDATE()
   from inserted
GO

CREATE TABLE [dbo].[ConfigurationInfo] (
    [ConfigInfoID] [uniqueidentifier] NOT NULL ,
    [Name] [nvarchar] (260) NOT NULL ,
    [Value] [ntext] NOT NULL 
) ON [PRIMARY]
GO

GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES ON [dbo].[ConfigurationInfo] TO RSExecRole
GO

EXEC sp_tableoption N'[dbo].[ConfigurationInfo]', 'text in row', 'ON'
GO

CREATE UNIQUE CLUSTERED INDEX [IX_ConfigurationInfo] ON [dbo].[ConfigurationInfo]([Name]) ON [PRIMARY]
GO

ALTER TABLE [dbo].[ConfigurationInfo] WITH NOCHECK ADD
    CONSTRAINT [PK_ConfigurationInfo] PRIMARY KEY (
        [ConfigInfoID]
    ) ON [PRIMARY]
GO

CREATE TABLE [dbo].[Catalog] (
    [ItemID] [uniqueidentifier] NOT NULL ,
    [Path] [nvarchar] (425) NOT NULL ,
    [Name] [nvarchar] (425) NOT NULL ,
    [ParentID] [uniqueidentifier] NULL,
    [Type] [int] NOT NULL ,
    [Content] [image] NULL ,
    [Intermediate] [uniqueidentifier] NULL ,
    [SnapshotDataID] [uniqueidentifier] NULL ,
    [LinkSourceID] [uniqueidentifier] NULL ,
    [Property] [ntext] NULL ,
    [Description] [nvarchar] (512) NULL ,
    [Hidden] [bit] NULL,
    [CreatedByID] [uniqueidentifier] NOT NULL ,
    [CreationDate] [datetime] NOT NULL ,
    [ModifiedByID] [uniqueidentifier] NOT NULL ,
    [ModifiedDate] [datetime] NOT NULL ,
    [MimeType] [nvarchar] (260) NULL,
    [SnapshotLimit] [int] NULL,
    [Parameter] [ntext] NULL,
    [PolicyID] [uniqueidentifier] NOT NULL,
    [PolicyRoot] [bit] NOT NULL,
    [ExecutionFlag] [int] NOT NULL,
    [ExecutionTime] datetime NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

GRANT SELECT, UPDATE, INSERT, DELETE, REFERENCES ON [dbo].[Catalog] TO RSExecRole
GO

EXEC sp_tableoption N'[dbo].[Catalog]', 'text in row', 'ON'
GO

ALTER TABLE [dbo].[Catalog] WITH NOCHECK ADD
    CONSTRAINT [PK_Catalog] PRIMARY KEY NONCLUSTERED (
        [ItemID]
    ) ON [PRIMARY]
GO

CREATE UNIQUE CLUSTERED INDEX [IX_Catalog] ON [dbo].[Catalog]([Path]) ON [PRIMARY]
GO

CREATE INDEX [IX_Link] ON [dbo].[Catalog]([LinkSourceID]) ON [PRIMARY]
GO

CREATE INDEX [IX_Parent] ON [dbo].[Catalog]([ParentID]) ON [PRIMARY]
GO

CREATE TABLE [dbo].[UpgradeInfo] (
    [Item] nvarchar(260) NOT NULL,
    [Status] nvarchar(512) NULL
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[UpgradeInfo] ADD CONSTRAINT
    [PK_UpgradeInfo] PRIMARY KEY CLUSTERED (
        [Item]
    ) ON [PRIMARY]
GO

CREATE TABLE [dbo].[ModelDrill] (
    [ModelDrillID] [uniqueidentifier] NOT NULL,
    [ModelID] [uniqueidentifier] NOT NULL,
    [ReportID] [uniqueidentifier] NOT NULL,
    [ModelItemID] nvarchar(425) NOT NULL,
    [Type] tinyint NOT NULL
) ON [PRIMARY]
GO

GRANT SELECT, UPDATE, INSERT, DELETE, REFERENCES ON [dbo].[ModelDrill] TO RSExecRole
GO

CREATE UNIQUE CLUSTERED INDEX [IX_ModelDrillModelID] ON [dbo].[ModelDrill]([ModelID],[ReportID],[ModelDrillID]) ON [PRIMARY]
GO

ALTER TABLE [dbo].[ModelDrill] WITH NOCHECK ADD
    CONSTRAINT [PK_ModelDrill] PRIMARY KEY NONCLUSTERED (
        [ModelDrillID]
    )  ON [PRIMARY],
    CONSTRAINT [FK_ModelDrillModel] FOREIGN KEY (
        [ModelID]
    ) REFERENCES [dbo].[Catalog] (
        [ItemID]
    ) ON DELETE CASCADE,
    CONSTRAINT [FK_ModelDrillReport] FOREIGN KEY (
        [ReportID]
    ) REFERENCES [dbo].[Catalog] (
        [ItemID]
    )
GO

CREATE TABLE [dbo].[ModelPerspective] (
    [ID] uniqueidentifier NOT NULL,
    [ModelID] uniqueidentifier NOT NULL,
    [PerspectiveID] ntext NOT NULL, -- this is nvarchar(3850), but doesn't fit in row
    [PerspectiveName] ntext NULL,
    [PerspectiveDescription] ntext NULL
) ON [PRIMARY]
GO

GRANT SELECT, UPDATE, INSERT, DELETE, REFERENCES ON [dbo].[ModelPerspective] TO RSExecRole
GO

EXEC sp_tableoption N'[dbo].[ModelPerspective]', 'text in row', 'ON'
GO

CREATE CLUSTERED INDEX [IX_ModelPerspective] ON [dbo].[ModelPerspective]([ModelID]) ON [PRIMARY]
GO

ALTER TABLE [dbo].[ModelPerspective] WITH NOCHECK ADD
    CONSTRAINT [FK_ModelPerspectiveModel] FOREIGN KEY (
        [ModelID]
    ) REFERENCES [dbo].[Catalog] (
        [ItemID]
    ) ON DELETE CASCADE 
GO

CREATE TABLE [dbo].[CachePolicy] (
    [CachePolicyID] uniqueidentifier NOT NULL,
    [ReportID] uniqueidentifier NOT NULL,
    [ExpirationFlags] int  NOT NULL,
    [CacheExpiration] int NULL
)
GO

GRANT SELECT, UPDATE, INSERT, DELETE, REFERENCES ON [dbo].[CachePolicy] TO RSExecRole
GO

ALTER TABLE [dbo].[CachePolicy] WITH NOCHECK ADD
    CONSTRAINT [PK_CachePolicy] PRIMARY KEY NONCLUSTERED (
        [CachePolicyID]
    ),
    CONSTRAINT [FK_CachePolicyReportID] FOREIGN KEY (
        [ReportID]
    ) REFERENCES [dbo].[Catalog] (
        [ItemID]
    ) ON DELETE CASCADE 
GO

CREATE UNIQUE CLUSTERED INDEX [IX_CachePolicyReportID] ON [dbo].[CachePolicy]([ReportID]) ON [PRIMARY]
GO

CREATE TABLE [dbo].[Users](
    [UserID] [uniqueidentifier] NOT NULL,
    [Sid] [varbinary] (85) NULL,
    [UserType] [int] NOT NULL,
    [AuthType] [int] NOT NULL, -- for now is always Windows - 1 
    [UserName] [nvarchar] (260) NULL 
) ON [PRIMARY]
GO

GRANT SELECT, UPDATE, INSERT, DELETE, REFERENCES ON [dbo].[Users] TO RSExecRole
GO

ALTER TABLE [dbo].[Users] WITH NOCHECK ADD
    CONSTRAINT [PK_Users] PRIMARY KEY NONCLUSTERED (
        [UserID]
    ) ON [PRIMARY]
GO

CREATE UNIQUE CLUSTERED INDEX [IX_Users] ON [dbo].[Users]([Sid], [UserName], [AuthType]) ON [PRIMARY]
GO

CREATE TABLE [dbo].[DataSource] (
    [DSID] [uniqueidentifier] NOT NULL,
    -- reference to Catalog table if it is a standalone data source or data source embedded in rerport
    [ItemID] uniqueidentifier NULL, 
    -- reference to subscirption table if it is a subscription datasource
    [SubscriptionID] uniqueidentifier NULL,
    [Name] [nvarchar] (260) NULL, -- only for scoped data sources, MUST be NULL for standalone!!!
    [Extension] [nvarchar] (260) NULL,
    [Link] [uniqueidentifier] NULL,
    [CredentialRetrieval] [int], -- Prompt = 1, Store = 2, Integrated = 3, None = 4
    [Prompt] [ntext],
    [ConnectionString] [image] NULL,
    [OriginalConnectionString] [image] NULL,
    [OriginalConnectStringExpressionBased] [bit] NULL,
    [UserName] [image],
    [Password] [image],
    [Flags] [int],
    [Version] [int] NOT NULL
) ON [PRIMARY]
GO

GRANT SELECT, UPDATE, INSERT, DELETE, REFERENCES ON [dbo].[DataSource] TO RSExecRole
GO

EXEC sp_tableoption N'[dbo].[DataSource]', 'text in row', 'ON'
GO

ALTER TABLE [dbo].[DataSource] WITH NOCHECK ADD
    CONSTRAINT [PK_DataSource] PRIMARY KEY CLUSTERED (
        [DSID]
    ) ON [PRIMARY],
    CONSTRAINT [FK_DataSourceItemID] FOREIGN KEY (
        [ItemID]
    ) REFERENCES [dbo].[Catalog] (
        [ItemID] 
    )
GO

CREATE INDEX [IX_DataSourceItemID] ON [dbo].[DataSource]([ItemID]) ON [PRIMARY]
GO

CREATE INDEX [IX_DataSourceSubscriptionID] ON [dbo].[DataSource]([SubscriptionID]) ON [PRIMARY]
GO

CREATE TABLE [dbo].[Policies](
    [PolicyID] uniqueidentifier NOT NULL,
    [PolicyFlag] [tinyint] NULL
)  ON [PRIMARY]
GO

GRANT SELECT, UPDATE, INSERT, DELETE, REFERENCES ON [dbo].[Policies] TO RSExecRole
GO

ALTER TABLE [dbo].[Policies] WITH NOCHECK ADD 
    CONSTRAINT [PK_Policies] PRIMARY KEY CLUSTERED (
        [PolicyID]
    ) ON [PRIMARY] 
GO

CREATE TABLE [dbo].[ModelItemPolicy] (
    [ID] uniqueidentifier NOT NULL,
    [CatalogItemID] uniqueidentifier NOT NULL,
    [ModelItemID] nvarchar(425) NOT NULL,
    [PolicyID] uniqueidentifier NOT NULL
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[ModelItemPolicy] WITH NOCHECK ADD
    CONSTRAINT [PK_ModelItemPolicy] PRIMARY KEY NONCLUSTERED (
       [ID]
    ) ON [PRIMARY]
GO

CREATE CLUSTERED INDEX [IX_ModelItemPolicy] ON [dbo].[ModelItemPolicy]([CatalogItemID], [ModelItemID]) ON [PRIMARY]
GO

CREATE TABLE [dbo].[SecData](
    [SecDataID] uniqueidentifier NOT NULL,
    [PolicyID] uniqueidentifier NOT NULL,
    [AuthType] int NOT NULL,
    [XmlDescription] [ntext] NOT NULL,  
    [NtSecDescPrimary] [image] NOT NULL,
    [NtSecDescSecondary] [ntext] NULL,
)  ON [PRIMARY] TEXTIMAGE_ON[PRIMARY]
GO

GRANT SELECT, UPDATE, INSERT, DELETE, REFERENCES ON [dbo].[SecData] TO RSExecRole
GO

EXEC sp_tableoption N'[dbo].[SecData]', 'text in row', 'ON'
GO

ALTER TABLE [dbo].[SecData] WITH NOCHECK ADD
    CONSTRAINT [PK_SecData] PRIMARY KEY  NONCLUSTERED (
        [SecDataID]
    )  ON [PRIMARY]
GO

CREATE UNIQUE CLUSTERED INDEX [IX_SecData] ON [dbo].[SecData]([PolicyID], [AuthType]) ON [PRIMARY]
GO

CREATE TABLE [dbo].[Roles](
    [RoleID] uniqueidentifier NOT NULL,
    [RoleName] [nvarchar] (260) NOT NULL,
    [Description] [nvarchar] (512) NULL,
    [TaskMask] [nvarchar] (32) NOT NULL,
    [RoleFlags] [tinyint] NOT NULL  
)  ON [PRIMARY] 
GO

GRANT SELECT, UPDATE, INSERT, DELETE, REFERENCES ON [dbo].[Roles] TO RSExecRole
GO

ALTER TABLE [dbo].[Roles] WITH NOCHECK ADD
    CONSTRAINT [PK_Roles] PRIMARY KEY NONCLUSTERED (
        [RoleID]
    ) ON [PRIMARY]
GO

--TODO: replace with this and add role type CREATE UNIQUE CLUSTERED INDEX [IX_Roles] ON [dbo].[Roles]([RoleName], [RoleFlags]) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [IX_Roles] ON [dbo].[Roles]([RoleName]) ON [PRIMARY]
GO

CREATE TABLE [dbo].[PolicyUserRole](
    [ID] uniqueidentifier NOT NULL,
    [RoleID] uniqueidentifier NOT NULL,
    [UserID] uniqueidentifier NOT NULL,
    [PolicyID] uniqueidentifier NOT NULL,
)  ON [PRIMARY]
GO

GRANT SELECT, UPDATE, INSERT, DELETE, REFERENCES ON [dbo].[PolicyUserRole] TO RSExecRole
GO

CREATE UNIQUE CLUSTERED INDEX [IX_PolicyUserRole] ON [dbo].[PolicyUserRole]([RoleID], [UserID], [PolicyID]) ON [PRIMARY]
GO

ALTER TABLE [dbo].[PolicyUserRole] WITH NOCHECK ADD
    CONSTRAINT [PK_PolicyUserRole] PRIMARY KEY NONCLUSTERED (
        [ID]
    ) ON [PRIMARY],
    CONSTRAINT [FK_PolicyUserRole_User] FOREIGN KEY (
        [UserID]
    ) REFERENCES [dbo].[Users] (
        [UserID]
    ),
    CONSTRAINT [FK_PolicyUserRole_Role] FOREIGN KEY (
        [RoleID]
    ) REFERENCES [dbo].[Roles] (
        [RoleID]
    ),
    CONSTRAINT [FK_PolicyUserRole_Policy] FOREIGN KEY (
        [PolicyID]
    ) REFERENCES [dbo].[Policies] (
        [PolicyID]
    ) ON DELETE CASCADE 
GO

ALTER TABLE [dbo].[SecData] WITH NOCHECK ADD 
    CONSTRAINT [FK_SecDataPolicyID] FOREIGN KEY (
        [PolicyID]
    ) REFERENCES [dbo].[Policies] (
        [PolicyID]
    ) ON DELETE CASCADE 
GO

ALTER TABLE [dbo].[ModelItemPolicy] WITH NOCHECK ADD
    CONSTRAINT [FK_PoliciesPolicyID] FOREIGN KEY (
        [PolicyID]
    ) REFERENCES [dbo].[Policies] (
        [PolicyID]
    ) ON DELETE CASCADE
GO

ALTER TABLE [dbo].[Catalog] WITH NOCHECK ADD
    CONSTRAINT [FK_Catalog_ParentID] FOREIGN KEY (
        [ParentID]
    ) REFERENCES [dbo].[Catalog] (
        [ItemID]
    ),
    CONSTRAINT [FK_Catalog_LinkSourceID] FOREIGN KEY (
        [LinkSourceID]
    ) REFERENCES [dbo].[Catalog] (
        [ItemID]
    ),
    CONSTRAINT [FK_Catalog_Policy] FOREIGN KEY (
        [PolicyID]
    ) REFERENCES [dbo].[Policies] (
        [PolicyID]
    ),
    CONSTRAINT [FK_Catalog_CreatedByID] FOREIGN KEY (
        [CreatedByID]
    ) REFERENCES [dbo].[Users] (
        [UserID]
    ),
    CONSTRAINT [FK_Catalog_ModifiedByID] FOREIGN KEY (
        [ModifiedByID]
    ) REFERENCES [dbo].[Users] (
        [UserID]
    )
GO

--------------------------------------------------
------------- Eventing Info

CREATE TABLE [dbo].[Event] (
    [EventID] [uniqueidentifier] NOT NULL ,
    [EventType] [nvarchar] (260) NOT NULL ,
    [EventData] [nvarchar] (260) NULL ,
    [TimeEntered] [datetime] NOT NULL ,
    [ProcessStart] [datetime] NULL,
    [ProcessHeartbeat] [datetime] NULL,
    [BatchID] [uniqueidentifier] NULL 
) ON [PRIMARY]
GO

GRANT SELECT, UPDATE, INSERT, DELETE, REFERENCES ON [dbo].[Event] TO RSExecRole
GO

ALTER TABLE [dbo].[Event] WITH NOCHECK ADD
    CONSTRAINT [PK_Event] PRIMARY KEY CLUSTERED (
        [EventID]
    )  ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IX_Event2] ON [dbo].[Event] ([ProcessStart]) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IX_Event3] ON [dbo].[Event] ([TimeEntered]) ON [PRIMARY]
GO

CREATE INDEX [IX_Event_TimeEntered] ON [dbo].[Event]([TimeEntered]) ON [PRIMARY]
GO

--------------------------------------------------
------------- Execution Log

CREATE TABLE [dbo].[ExecutionLog] (
    [InstanceName] nvarchar(38) NOT NULL,
    [ReportID] uniqueidentifier NULL, -- Path could be null in error conditions
    [UserName] nvarchar(260) NULL,
    [RequestType] bit NOT NULL,
    [Format] nvarchar(26) NULL,
    [Parameters] ntext NULL,
    [TimeStart] DateTime NOT NULL,
    [TimeEnd] DateTime NOT NULL,
    [TimeDataRetrieval] int NOT NULL,
    [TimeProcessing] int NOT NULL,
    [TimeRendering] int NOT NULL,
    [Source] tinyint NOT NULL,
    [Status] nvarchar(32) NOT NULL,
    [ByteCount] bigint NOT NULL,
    [RowCount] bigint NOT NULL
) ON [PRIMARY]
GO

GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES ON [dbo].[ExecutionLog] TO RSExecRole
GO

CREATE CLUSTERED INDEX [IX_ExecutionLog] ON [dbo].[ExecutionLog]([TimeStart]) ON [PRIMARY]
GO

--------------------------------------------------
------------- Subscription Info

CREATE TABLE [dbo].[Subscriptions] (
    [SubscriptionID] [uniqueidentifier] NOT NULL,
    [OwnerID] [uniqueidentifier] NOT NULL,
    [Report_OID] [uniqueidentifier] NOT NULL,
    [Locale] [nvarchar] (128) NOT NULL,
    [InactiveFlags] [int] NOT NULL,
    [ExtensionSettings] [ntext] NULL,
    [ModifiedByID] [uniqueidentifier] NOT NULL,
    [ModifiedDate] [datetime] NOT NULL,
    [Description] [nvarchar] (512) NULL,
    [LastStatus] [nvarchar] (260) NULL,
    [EventType] [nvarchar] (260) NOT NULL,
    [MatchData] [ntext] NULL,
    [LastRunTime] [datetime] NULL,
    [Parameters] [ntext] NULL,
    [DataSettings] [ntext] NULL,
    [DeliveryExtension] [nvarchar] (260) NULL,
    [Version] [int] NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

GRANT SELECT, UPDATE, INSERT, DELETE, REFERENCES ON [dbo].[Subscriptions] TO RSExecRole
GO

ALTER TABLE [dbo].[Subscriptions] WITH NOCHECK ADD
    CONSTRAINT [PK_Subscriptions] PRIMARY KEY CLUSTERED (
        [SubscriptionID]
    ) ON [PRIMARY],
    CONSTRAINT [FK_Subscriptions_Catalog] FOREIGN KEY (
        [Report_OID]
    ) REFERENCES [dbo].[Catalog] (
        [ItemID]
    ) ON DELETE CASCADE NOT FOR REPLICATION,
    CONSTRAINT [FK_Subscriptions_ModifiedBy] FOREIGN KEY (
        [ModifiedByID]
    ) REFERENCES [dbo].[Users] (
        [UserID]
    ),
    CONSTRAINT [FK_Subscriptions_Owner] FOREIGN KEY (
        [OwnerID]
    ) REFERENCES [dbo].[Users] (
        [UserID]
    )
GO

CREATE TABLE [dbo].[ActiveSubscriptions] (
    [ActiveID] [uniqueidentifier] NOT NULL ,
    [SubscriptionID] [uniqueidentifier] NOT NULL ,
    [TotalNotifications] [int] NULL ,
    [TotalSuccesses] [int] NOT NULL ,
    [TotalFailures] [int] NOT NULL 
) ON [PRIMARY]
GO

GRANT SELECT, UPDATE, INSERT, DELETE, REFERENCES ON [dbo].[ActiveSubscriptions] TO RSExecRole
GO

ALTER TABLE [dbo].[ActiveSubscriptions] WITH NOCHECK ADD
    CONSTRAINT [PK_ActiveSubscriptions] PRIMARY KEY CLUSTERED (
        [ActiveID]
    )  ON [PRIMARY],
    CONSTRAINT [FK_ActiveSubscriptions_Subscriptions] FOREIGN KEY (
        [SubscriptionID]
    ) REFERENCES [dbo].[Subscriptions] (
        [SubscriptionID]
    ) ON DELETE CASCADE
GO

CREATE TABLE [dbo].[SnapshotData]  (
    [SnapshotDataID] uniqueidentifier NOT NULL,
    [CreatedDate] datetime NOT NULL,
    [ParamsHash] int NULL, -- Hash of values of parameters that are used in query
    [QueryParams] ntext NULL, -- Values of parameters that are used in query
    [EffectiveParams] ntext NULL, -- Full set of effective parameters
    [Description] nvarchar(512) NULL,
    [DependsOnUser] bit NULL,
    [PermanentRefcount] int NOT NULL, -- this counts only permanent references, NOT SESSIONS!!!
    [TransientRefcount] int NOT NULL, -- this is to count sessions, may be more than expected
    [ExpirationDate] datetime NOT NULL, -- Expired snapshots should be erased regardless of TransiendRefcount
    [PageCount] int NULL,
    [HasDocMap] bit NULL
)
GO

GRANT SELECT, UPDATE, INSERT, DELETE, REFERENCES ON [dbo].[SnapshotData] TO RSExecRole
GO

EXEC sp_tableoption N'[dbo].[SnapshotData]', 'text in row', 'ON'
GO

CREATE INDEX [IX_SnapshotCleaning] ON [dbo].[SnapshotData]([PermanentRefcount]) ON [PRIMARY]
GO

ALTER TABLE [dbo].[SnapshotData] ADD
    CONSTRAINT [PK_SnapshotData] PRIMARY KEY CLUSTERED (
         [SnapshotDataID]
    )
GO

CREATE TABLE [dbo].[ChunkData] (
    [ChunkID]  uniqueidentifier NOT NULL,
    [SnapshotDataID] uniqueidentifier NOT NULL,
    [ChunkFlags] tinyint NULL,
    [ChunkName] nvarchar(260), -- Name of the chunk
    [ChunkType] int, -- internal type of the chunk
    [Version] smallint NULL, -- version of the chunk
    [MimeType] nvarchar(260), -- mime type of the content of the chunk
    [Content] image -- content of the chunk
)
GO

GRANT SELECT, UPDATE, INSERT, DELETE, REFERENCES ON [dbo].[ChunkData] TO RSExecRole
GO

ALTER TABLE [dbo].[ChunkData] WITH NOCHECK ADD
    CONSTRAINT [PK_ChunkData] PRIMARY KEY NONCLUSTERED (
        [ChunkID]
    ) ON [PRIMARY]
GO

CREATE UNIQUE CLUSTERED INDEX [IX_ChunkData] ON [dbo].[ChunkData]([SnapshotDataID], [ChunkType], [ChunkName]) ON [PRIMARY]
GO
-- end session tables

CREATE TRIGGER [dbo].[Subscription_delete_DataSource] ON [dbo].[Subscriptions]
AFTER DELETE 
AS
    delete DataSource from DataSource DS inner join deleted D on DS.SubscriptionID = D.SubscriptionID
GO

CREATE TRIGGER [dbo].[Subscription_delete_Schedule] ON [dbo].[Subscriptions] 
AFTER DELETE 
AS
    delete ReportSchedule from ReportSchedule RS inner join deleted D on RS.SubscriptionID = D.SubscriptionID
GO

--------------------------------------------------
------------- Notification Info

CREATE TABLE [dbo].[Notifications] (
    [NotificationID] uniqueidentifier NOT NULL,
    [SubscriptionID] uniqueidentifier NOT NULL,
    [ActivationID] uniqueidentifier NULL,
    [ReportID] uniqueidentifier NOT NULL,
    [SnapShotDate] datetime NULL,
    [ExtensionSettings] ntext NOT NULL,
    [Locale] nvarchar(128) NOT NULL,
    [Parameters] ntext NULL,
    [ProcessStart] datetime NULL,
    [NotificationEntered] datetime NOT NULL,
    [ProcessAfter] datetime NULL,
    [Attempt] int NULL,
    [SubscriptionLastRunTime] datetime NOT NULL,
    [DeliveryExtension] nvarchar(260) NOT NULL,
    [SubscriptionOwnerID] uniqueidentifier NOT NULL,
    [IsDataDriven] bit NOT NULL,
    [BatchID] uniqueidentifier NULL,
    [ProcessHeartbeat] datetime NULL,
    [Version] [int] NOT NULL
) ON [PRIMARY]
GO

GRANT SELECT, UPDATE, INSERT, DELETE, REFERENCES ON [dbo].[Notifications] TO RSExecRole
GO

ALTER TABLE [dbo].[Notifications] WITH NOCHECK ADD
    CONSTRAINT [PK_Notifications] PRIMARY KEY CLUSTERED (
        [NotificationID]
    ) ON [PRIMARY],
    CONSTRAINT [FK_Notifications_Subscriptions] FOREIGN KEY (
        [SubscriptionID]
    ) REFERENCES [dbo].[Subscriptions] (
        [SubscriptionID]
    ) ON DELETE CASCADE
GO

CREATE NONCLUSTERED INDEX [IX_Notifications] ON [dbo].[Notifications] ([ProcessAfter]) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IX_Notifications2] ON [dbo].[Notifications] ([ProcessStart]) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IX_Notifications3] ON [dbo].[Notifications] ([NotificationEntered]) ON [PRIMARY]
GO

--------------------------------------------------
------------- Batching

CREATE TABLE [dbo].[Batch] (
    [BatchID] [uniqueidentifier] NOT NULL ,
    [AddedOn] [datetime] NOT NULL ,
    [Action] [varchar] (32) NOT NULL ,
    [Item] [nvarchar] (425) NULL ,
    [Parent] [nvarchar] (425) NULL ,
    [Param] [nvarchar] (425) NULL ,
    [BoolParam] [bit] NULL ,
    [Content] [image] NULL ,
    [Properties] [ntext] NULL 
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

GRANT SELECT, UPDATE, INSERT, DELETE, REFERENCES ON [dbo].[Batch] TO RSExecRole
GO

CREATE CLUSTERED INDEX [IX_Batch] ON [dbo].[Batch]([BatchID], [AddedOn]) ON [PRIMARY]
GO

CREATE INDEX [IX_Batch_1] ON [dbo].[Batch]([AddedOn]) ON [PRIMARY]
GO

--------------------------------------------------
------------- Report Scheduling

CREATE TABLE [dbo].[Schedule] (
    [ScheduleID] [uniqueidentifier] NOT NULL ,
    [Name] [nvarchar] (260) NOT NULL ,
    [StartDate] [datetime] NOT NULL ,
    [Flags] [int] NOT NULL ,
    [NextRunTime] [datetime] NULL ,
    [LastRunTime] [datetime] NULL ,
    [EndDate] [datetime] NULL ,
    [RecurrenceType] [int] NULL ,
    [MinutesInterval] [int] NULL ,
    [DaysInterval] [int] NULL ,
    [WeeksInterval] [int] NULL ,
    [DaysOfWeek] [int] NULL ,
    [DaysOfMonth] [int] NULL ,
    [Month] [int] NULL ,
    [MonthlyWeek] [int] NULL ,
    [State] [int] NULL ,
    [LastRunStatus] [nvarchar] (260) NULL ,
    [ScheduledRunTimeout] [int] NULL ,
    [CreatedById] [uniqueidentifier] NOT NULL ,
    [EventType] [nvarchar] (260) NOT NULL ,
    [EventData] [nvarchar] (260) NULL ,
    [Type] [int] NOT NULL,
    [ConsistancyCheck] [datetime] NULL
) ON [PRIMARY]
GO

GRANT SELECT, UPDATE, INSERT, DELETE, REFERENCES ON [dbo].[Schedule] TO RSExecRole
GO

ALTER TABLE [dbo].[Schedule] WITH NOCHECK ADD 
    CONSTRAINT [PK_ScheduleID] PRIMARY KEY CLUSTERED (
        [ScheduleID]
    ) ON [PRIMARY], 
    CONSTRAINT [IX_Schedule] UNIQUE NONCLUSTERED (
        [Name]
    ) ON [PRIMARY], 
    CONSTRAINT [FK_Schedule_Users] FOREIGN KEY (
        [CreatedById]
    ) REFERENCES [dbo].[Users] (
        [UserID]
    )
GO

CREATE TABLE [dbo].[ReportSchedule] (
    [ScheduleID] [uniqueidentifier] NOT NULL ,
    [ReportID] [uniqueidentifier] NOT NULL ,
    [SubscriptionID] [uniqueidentifier] NULL,
    [ReportAction] [int] NOT NULL 
) ON [PRIMARY]
GO

GRANT SELECT, UPDATE, INSERT, DELETE, REFERENCES ON [dbo].[ReportSchedule] TO RSExecRole
GO

CREATE INDEX [IX_ReportSchedule_ReportID] ON [dbo].[ReportSchedule] ([ReportID]) ON [PRIMARY]
GO

CREATE INDEX [IX_ReportSchedule_ScheduleID] ON [dbo].[ReportSchedule] ([ScheduleID]) ON [PRIMARY]
GO

CREATE INDEX [IX_ReportSchedule_SubscriptionID] ON [dbo].[ReportSchedule] ([SubscriptionID]) ON [PRIMARY]
GO

ALTER TABLE [dbo].[ReportSchedule] ADD
    CONSTRAINT [FK_ReportSchedule_Report] FOREIGN KEY (
        [ReportID]
    ) REFERENCES [dbo].[Catalog] (
        [ItemID]
    ) ON DELETE CASCADE,
    CONSTRAINT [FK_ReportSchedule_Schedule] FOREIGN KEY (
        [ScheduleID]
    ) REFERENCES [dbo].[Schedule] (
        [ScheduleID]
    ) ON DELETE CASCADE,
    CONSTRAINT [FK_ReportSchedule_Subscriptions] FOREIGN KEY (
        [SubscriptionID]
    ) REFERENCES [dbo].[Subscriptions] (
        [SubscriptionID]
    ) NOT FOR REPLICATION
GO

ALTER TABLE [dbo].[ReportSchedule]
    NOCHECK CONSTRAINT [FK_ReportSchedule_Subscriptions]
GO

CREATE TRIGGER [dbo].[ReportSchedule_Schedule] ON [dbo].[ReportSchedule]
AFTER DELETE
AS

-- if the deleted row is the last connection between a schedule and a report delete the schedule
-- as long as the schedule is not a shared schedule (type == 0)
delete [Schedule] from 
    [Schedule] S inner join deleted D on S.[ScheduleID] = D.[ScheduleID] 
where
    S.[Type] != 0 and
    not exists (select * from [ReportSchedule] R where S.[ScheduleID] = R.[ScheduleID])
GO

CREATE TRIGGER [dbo].[Schedule_UpdateExpiration] ON [dbo].[Schedule]  
AFTER UPDATE
AS 
UPDATE
   EC
SET
   AbsoluteExpiration = I.NextRunTime
FROM
   [ReportServerTempDB].dbo.ExecutionCache AS EC
   INNER JOIN ReportSchedule AS RS ON EC.ReportID = RS.ReportID
   INNER JOIN inserted AS I ON RS.ScheduleID = I.ScheduleID AND RS.ReportAction = 3
GO

CREATE TRIGGER [dbo].[Schedule_DeleteAgentJob] ON [dbo].[Schedule]  
AFTER DELETE
AS 
DECLARE id_cursor CURSOR
FOR
    SELECT ScheduleID from deleted
OPEN id_cursor

DECLARE @next_id uniqueidentifier
FETCH NEXT FROM id_cursor INTO @next_id
WHILE (@@FETCH_STATUS <> -1) -- -1 == FETCH statement failed or the row was beyond the result set.
BEGIN
    if (@@FETCH_STATUS <> -2) -- - 2 == Row fetched is missing.
    BEGIN
        exec msdb.dbo.sp_delete_job @job_name = @next_id -- delete the schedule
    END
    FETCH NEXT FROM id_cursor INTO @next_id
END
CLOSE id_cursor
DEALLOCATE id_cursor
GO

--------------------------------------------------
------------- Running jobs tables

CREATE TABLE [dbo].[RunningJobs] (
    [JobID] nvarchar(32) NOT NULL,
    [StartDate] datetime NOT NULL,
    [ComputerName] nvarchar(32) NOT NULL,
    [RequestName] nvarchar(425) NOT NULL,
    [RequestPath] nvarchar(425) NOT NULL,
    [UserId] uniqueidentifier NOT NULL, 
    [Description] ntext NULL,
    [Timeout] int NOT NULL,
    [JobAction] smallint NOT NULL,
    [JobType] smallint NOT NULL,
    [JobStatus] smallint NOT NULL
) ON [PRIMARY]
GO

GRANT SELECT, UPDATE, INSERT, DELETE, REFERENCES ON [dbo].[RunningJobs] TO RSExecRole
GO

ALTER TABLE [dbo].[RunningJobs] ADD 
    CONSTRAINT [PK_RunningJobs] PRIMARY KEY CLUSTERED (
        [JobID]
    )
GO

CREATE INDEX [IX_RunningJobsStatus] ON [dbo].[RunningJobs]([ComputerName], [JobType]) ON [PRIMARY]
GO

CREATE TABLE [dbo].[ServerParametersInstance] (
    [ServerParametersID] nvarchar(32) NOT NULL,
    [ParentID] nvarchar(32) NULL,
    [Path] [nvarchar] (425) NOT NULL,
    [CreateDate] datetime NOT NULL,
    [ModifiedDate] datetime NOT NULL,
    [Timeout] int NOT NULL,
    [Expiration] datetime NOT NULL,
    [ParametersValues] image NOT NULL
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[ServerParametersInstance] ADD 
    CONSTRAINT [PK_ServerParametersInstance] PRIMARY KEY CLUSTERED (
        [ServerParametersID]
    )
GO

CREATE INDEX [IX_ServerParametersInstanceExpiration] ON [dbo].[ServerParametersInstance]([Expiration] DESC) ON [PRIMARY]
GO

EXEC sp_tableoption N'[dbo].[ServerParametersInstance]', 'text in row', 'ON'
GO


--------------------------------------------------
------------- Creation of Stored Procedures
--------------------------------------------------
-- START STORED PROCEDURES

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SetKeysForInstallation]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SetKeysForInstallation]
GO

CREATE PROCEDURE [dbo].[SetKeysForInstallation]
@InstallationID uniqueidentifier,
@SymmetricKey image = NULL,
@PublicKey image
AS

update [dbo].[Keys]
set [SymmetricKey] = @SymmetricKey, [PublicKey] = @PublicKey
where [InstallationID] = @InstallationID and [Client] = 1

GO
GRANT EXECUTE ON [dbo].[SetKeysForInstallation] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetAnnouncedKey]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetAnnouncedKey]
GO

CREATE PROCEDURE [dbo].[GetAnnouncedKey]
@InstallationID uniqueidentifier
AS

select PublicKey, MachineName, InstanceName
from Keys
where InstallationID = @InstallationID and Client = 1

GO
GRANT EXECUTE ON [dbo].[GetAnnouncedKey] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[AnnounceOrGetKey]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[AnnounceOrGetKey]
GO

CREATE PROCEDURE [dbo].[AnnounceOrGetKey]
@MachineName nvarchar(256),
@InstanceName nvarchar(32),
@InstallationID uniqueidentifier,
@PublicKey image,
@NumAnnouncedServices int OUTPUT
AS

-- Acquire lock
IF NOT EXISTS (SELECT * FROM [dbo].[Keys] WITH(XLOCK) WHERE [Client] < 0)
BEGIN
    RAISERROR('Keys lock row not found', 16, 1)
    RETURN
END

-- Get the number of services that have already announced their presence
SELECT @NumAnnouncedServices = count(*)
FROM [dbo].[Keys]
WHERE [Client] = 1

DECLARE @StoredInstallationID uniqueidentifier
DECLARE @StoredInstanceName nvarchar(32)

SELECT @StoredInstallationID = [InstallationID], @StoredInstanceName = [InstanceName]
FROM [dbo].[Keys]
WHERE [InstallationID] = @InstallationID AND [Client] = 1

IF @StoredInstallationID IS NULL -- no record present
BEGIN
    INSERT INTO [dbo].[Keys]
        ([MachineName], [InstanceName], [InstallationID], [Client], [PublicKey], [SymmetricKey])
    VALUES
        (@MachineName, @InstanceName, @InstallationID, 1, @PublicKey, null)
END
ELSE
BEGIN
    IF @StoredInstanceName IS NULL
    BEGIN
        UPDATE [dbo].[Keys]
        SET [InstanceName] = @InstanceName
        WHERE [InstallationID] = @InstallationID AND [Client] = 1
    END
END

SELECT [MachineName], [SymmetricKey], [PublicKey]
FROM [Keys]
WHERE [InstallationID] = @InstallationID and [Client] = 1

GO
GRANT EXECUTE ON [dbo].[AnnounceOrGetKey] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SetMachineName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SetMachineName]
GO

CREATE PROCEDURE [dbo].[SetMachineName]
@MachineName nvarchar(256),
@InstallationID uniqueidentifier
AS

UPDATE [dbo].[Keys]
SET MachineName = @MachineName
WHERE [InstallationID] = @InstallationID and [Client] = 1

GO
GRANT EXECUTE ON [dbo].[SetMachineName] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ListInstallations]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[ListInstallations]
GO

CREATE PROCEDURE [dbo].[ListInstallations]
AS

SELECT
    [MachineName],
    [InstanceName],
    [InstallationID],
    CASE WHEN [SymmetricKey] IS null THEN 0 ELSE 1 END
FROM [dbo].[Keys]
WHERE [Client] = 1

GO
GRANT EXECUTE ON [dbo].[ListInstallations] TO RSExecRole
GO


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ListInfoForReencryption]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[ListInfoForReencryption]
GO

CREATE PROCEDURE [dbo].[ListInfoForReencryption]
AS

SELECT [DSID]
FROM [dbo].[DataSource] WITH (XLOCK, TABLOCK)

SELECT [SubscriptionID]
FROM [dbo].[Subscriptions] WITH (XLOCK, TABLOCK)

SELECT [InstallationID], [PublicKey]
FROM [dbo].[Keys] WITH (XLOCK, TABLOCK)
WHERE [Client] = 1 AND ([SymmetricKey] IS NOT NULL)

GO
GRANT EXECUTE ON [dbo].[ListInfoForReencryption] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetDatasourceInfoForReencryption]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetDatasourceInfoForReencryption]
GO

CREATE PROCEDURE [dbo].[GetDatasourceInfoForReencryption]
@DSID as uniqueidentifier
AS

SELECT
    [ConnectionString],
    [OriginalConnectionString],
    [UserName],
    [Password],
    [CredentialRetrieval],
    [Version]
FROM [dbo].[DataSource]
WHERE [DSID] = @DSID

GO
GRANT EXECUTE ON [dbo].[GetDatasourceInfoForReencryption] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SetReencryptedDatasourceInfo]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SetReencryptedDatasourceInfo]
GO

CREATE PROCEDURE [dbo].[SetReencryptedDatasourceInfo]
@DSID uniqueidentifier,
@ConnectionString image = NULL,
@OriginalConnectionString image = NULL,
@UserName image = NULL,
@Password image = NULL,
@CredentialRetrieval int,
@Version int
AS

UPDATE [dbo].[DataSource]
SET
    [ConnectionString] = @ConnectionString,
    [OriginalConnectionString] = @OriginalConnectionString,
    [UserName] = @UserName,
    [Password] = @Password,
    [CredentialRetrieval] = @CredentialRetrieval,
    [Version] = @Version
WHERE [DSID] = @DSID

GO
GRANT EXECUTE ON [dbo].[SetReencryptedDatasourceInfo] TO RSExecRole
GO


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetSubscriptionInfoForReencryption]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetSubscriptionInfoForReencryption]
GO

CREATE PROCEDURE [dbo].[GetSubscriptionInfoForReencryption]
@SubscriptionID as uniqueidentifier
AS

SELECT [DeliveryExtension], [ExtensionSettings], [Version]
FROM [dbo].[Subscriptions]
WHERE [SubscriptionID] = @SubscriptionID

GO
GRANT EXECUTE ON [dbo].[GetSubscriptionInfoForReencryption] TO RSExecRole
GO


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SetReencryptedSubscriptionInfo]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SetReencryptedSubscriptionInfo]
GO

CREATE PROCEDURE [dbo].[SetReencryptedSubscriptionInfo]
@SubscriptionID as uniqueidentifier,
@ExtensionSettings as ntext = NULL,
@Version as int
AS

UPDATE [dbo].[Subscriptions]
SET [ExtensionSettings] = @ExtensionSettings,
    [Version] = @Version
WHERE [SubscriptionID] = @SubscriptionID

GO
GRANT EXECUTE ON [dbo].[SetReencryptedSubscriptionInfo] TO RSExecRole
GO


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DeleteEncryptedContent]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[DeleteEncryptedContent]
GO

CREATE PROCEDURE [dbo].[DeleteEncryptedContent]
AS

-- Remove the encryption keys
delete from keys where client >= 0

-- Remove the encrypted content
update datasource
set CredentialRetrieval = 1, -- CredentialRetrieval.Prompt
    ConnectionString = null,
    OriginalConnectionString = null,
    UserName = null,
    Password = null

GO
GRANT EXECUTE ON [dbo].[DeleteEncryptedContent] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DeleteKey]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[DeleteKey]
GO

CREATE PROCEDURE [dbo].[DeleteKey]
@InstallationID uniqueidentifier
AS

if (@InstallationID = '00000000-0000-0000-0000-000000000000')
RAISERROR('Cannot delete reserved key', 16, 1)

-- Remove the encryption keys
delete from keys where InstallationID = @InstallationID and Client = 1

GO
GRANT EXECUTE ON [dbo].[DeleteKey] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetAllConfigurationInfo]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetAllConfigurationInfo]
GO

CREATE PROCEDURE [dbo].[GetAllConfigurationInfo]
AS
SELECT [Name], [Value]
FROM [ConfigurationInfo]
GO
GRANT EXECUTE ON [dbo].[GetAllConfigurationInfo] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetOneConfigurationInfo]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetOneConfigurationInfo]
GO

CREATE PROCEDURE [dbo].[GetOneConfigurationInfo]
@Name nvarchar (260)
AS
SELECT [Value]
FROM [ConfigurationInfo]
WHERE [Name] = @Name
GO
GRANT EXECUTE ON [dbo].[GetOneConfigurationInfo] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SetConfigurationInfo]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SetConfigurationInfo]
GO

CREATE PROCEDURE [dbo].[SetConfigurationInfo]
@Name nvarchar (260),
@Value ntext
AS
DELETE
FROM [ConfigurationInfo]
WHERE [Name] = @Name

IF @Value is not null BEGIN
   INSERT
   INTO ConfigurationInfo
   VALUES ( newid(), @Name, @Value )
END
GO
GRANT EXECUTE ON [dbo].[SetConfigurationInfo] TO RSExecRole

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[AddEvent]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[AddEvent]
GO

CREATE PROCEDURE [dbo].[AddEvent] 
@EventType nvarchar (260),
@EventData nvarchar (260)
AS

insert into [Event] 
    ([EventID], [EventType], [EventData], [TimeEntered], [ProcessStart], [BatchID]) 
values
    (NewID(), @EventType, @EventData, GETUTCDATE(), NULL, NULL)
GO
GRANT EXECUTE ON [dbo].[AddEvent] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DeleteEvent]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[DeleteEvent]
GO

CREATE PROCEDURE [dbo].[DeleteEvent] 
@ID uniqueidentifier
AS
delete from [Event] where [EventID] = @ID
GO
GRANT EXECUTE ON [dbo].[DeleteEvent] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CleanEventRecords]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CleanEventRecords]
GO

CREATE PROCEDURE [dbo].[CleanEventRecords] 
@MaxAgeMinutes int
AS
-- Reset all notifications which have been add over n minutes ago
Update [Event] set [ProcessStart] = NULL, [ProcessHeartbeat] = NULL
where [EventID] in
   ( SELECT [EventID]
     FROM [Event]
     WHERE [ProcessHeartbeat] < DATEADD(minute, -(@MaxAgeMinutes), GETUTCDATE()) )
GO
GRANT EXECUTE ON [dbo].[CleanEventRecords] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[AddExecutionLogEntry]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[AddExecutionLogEntry]
GO

CREATE PROCEDURE [dbo].[AddExecutionLogEntry]
@InstanceName nvarchar(38),
@Report nvarchar(260),
@UserSid varbinary(85) = NULL,
@UserName nvarchar(260),
@AuthType int,
@RequestType bit,
@Format nvarchar(26),
@Parameters ntext,
@TimeStart DateTime,
@TimeEnd DateTime,
@TimeDataRetrieval int,
@TimeProcessing int,
@TimeRendering int,
@Source tinyint,
@Status nvarchar(32),
@ByteCount bigint,
@RowCount bigint
AS

-- Unless is is specifically 'False', it's true
if exists (select * from ConfigurationInfo where [Name] = 'EnableExecutionLogging' and [Value] like 'False')
begin
return
end

Declare @ReportID uniqueidentifier
select @ReportID = ItemID from Catalog with (nolock) where Path = @Report

insert into ExecutionLog
(InstanceName, ReportID, UserName, RequestType, [Format], Parameters, TimeStart, TimeEnd, TimeDataRetrieval, TimeProcessing, TimeRendering, Source, Status, ByteCount, [RowCount])
Values
(@InstanceName, @ReportID, @UserName, @RequestType, @Format, @Parameters, @TimeStart, @TimeEnd, @TimeDataRetrieval, @TimeProcessing, @TimeRendering, @Source, @Status, @ByteCount, @RowCount)

GO
GRANT EXECUTE ON [dbo].[AddExecutionLogEntry] TO RSExecRole
GO


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ExpireExecutionLogEntries]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[ExpireExecutionLogEntries]
GO

CREATE PROCEDURE [dbo].[ExpireExecutionLogEntries]
AS

-- -1 means no expiration
if exists (select * from ConfigurationInfo where [Name] = 'ExecutionLogDaysKept' and CAST(CAST(Value as nvarchar) as integer) = -1)
begin
return
end

delete from ExecutionLog 
where DateDiff(day, TimeStart, getdate()) >= (select CAST(CAST(Value as nvarchar) as integer) from ConfigurationInfo where [Name] = 'ExecutionLogDaysKept')

GO
GRANT EXECUTE ON [dbo].[ExpireExecutionLogEntries] TO RSExecRole
GO



if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetUserIDBySid]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetUserIDBySid]
GO

-- looks up any user name by its SID, if not it creates a regular user
CREATE PROCEDURE [dbo].[GetUserIDBySid]
@UserSid varbinary(85),
@UserName nvarchar(260),
@AuthType int,
@UserID uniqueidentifier OUTPUT
AS
SELECT @UserID = (SELECT UserID FROM Users WHERE Sid = @UserSid AND AuthType = @AuthType)
IF @UserID IS NULL
   BEGIN
      SET @UserID = newid()
      INSERT INTO Users
      (UserID, Sid, UserType, AuthType, UserName)
      VALUES 
      (@UserID, @UserSid, 0, @AuthType, @UserName)
   END 
GO
GRANT EXECUTE ON [dbo].[GetUserIDBySid] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetUserIDByName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetUserIDByName]
GO

-- looks up any user name by its User Name, if not it creates a regular user
CREATE PROCEDURE [dbo].[GetUserIDByName]
@UserName nvarchar(260),
@AuthType int,
@UserID uniqueidentifier OUTPUT
AS
SELECT @UserID = (SELECT UserID FROM Users WHERE UserName = @UserName AND AuthType = @AuthType)
IF @UserID IS NULL
   BEGIN
      SET @UserID = newid()
      INSERT INTO Users
      (UserID, Sid, UserType, AuthType, UserName)
      VALUES 
      (@UserID, NULL, 0,    @AuthType, @UserName)
   END 
GO
GRANT EXECUTE ON [dbo].[GetUserIDByName] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetUserID]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetUserID]
GO

-- looks up any user name, if not it creates a regular user - uses Sid
CREATE PROCEDURE [dbo].[GetUserID]
@UserSid varbinary(85) = NULL,
@UserName nvarchar(260),
@AuthType int,
@UserID uniqueidentifier OUTPUT
AS
    IF @AuthType = 1 -- Windows
    BEGIN
        EXEC GetUserIDBySid @UserSid, @UserName, @AuthType, @UserID OUTPUT
    END
    ELSE
    BEGIN
        EXEC GetUserIDByName @UserName, @AuthType, @UserID OUTPUT
    END
GO

GRANT EXECUTE ON [dbo].[GetUserID] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetPrincipalID]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetPrincipalID]
GO

-- looks up a principal, if not there looks up regular users and turns them into principals
-- if not, it creates a principal
CREATE PROCEDURE [dbo].[GetPrincipalID]
@UserSid varbinary(85) = NULL,
@UserName nvarchar(260),
@AuthType int,
@UserID uniqueidentifier OUTPUT
AS
-- windows auth
IF @AuthType = 1
BEGIN
    -- is this a principal?
    SELECT @UserID = (SELECT UserID FROM Users WHERE Sid = @UserSid AND UserType = 1 AND AuthType = @AuthType)
END
ELSE
BEGIN
    -- is this a principal?
    SELECT @UserID = (SELECT UserID FROM Users WHERE UserName = @UserName AND UserType = 1 AND AuthType = @AuthType)
END
IF @UserID IS NULL
   BEGIN
        IF @AuthType = 1 -- Windows
        BEGIN
            -- Is this a regular user
            SELECT @UserID = (SELECT UserID FROM Users WHERE Sid = @UserSid AND UserType = 0 AND AuthType = @AuthType)
        END
        ELSE
        BEGIN
            -- Is this a regular user
            SELECT @UserID = (SELECT UserID FROM Users WHERE UserName = @UserName AND UserType = 0 AND AuthType = @AuthType)
        END
      -- No, create a new principal
      IF @UserID IS NULL
         BEGIN
            SET @UserID = newid()
            INSERT INTO Users
            (UserID, Sid,   UserType, AuthType, UserName)
            VALUES 
            (@UserID, @UserSid, 1,    @AuthType, @UserName)
         END 
      ELSE
         BEGIN
             UPDATE Users SET UserType = 1 WHERE UserID = @UserID
         END
    END
GO
GRANT EXECUTE ON [dbo].[GetPrincipalID] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CreateSubscription]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CreateSubscription]
GO

CREATE PROCEDURE [dbo].[CreateSubscription]
@id uniqueidentifier,
@Locale nvarchar (128),
@Report_Name nvarchar (425),
@OwnerSid varbinary (85) = NULL,
@OwnerName nvarchar(260),
@OwnerAuthType int,
@DeliveryExtension nvarchar (260) = NULL,
@InactiveFlags int,
@ExtensionSettings ntext = NULL,
@ModifiedBySid varbinary (85) = NULL,
@ModifiedByName nvarchar(260),
@ModifiedByAuthType int,
@ModifiedDate datetime,
@Description nvarchar(512) = NULL,
@LastStatus nvarchar(260) = NULL,
@EventType nvarchar(260),
@MatchData ntext = NULL,
@Parameters ntext = NULL,
@DataSettings ntext = NULL,
@Version int

AS

-- Create a subscription with the given data.  The name must match a name in the
-- Catalog table and it must be a report type (2) or linked report (4)

DECLARE @Report_OID uniqueidentifier
DECLARE @OwnerID uniqueidentifier
DECLARE @ModifiedByID uniqueidentifier
DECLARE @TempDeliveryID uniqueidentifier

--Get the report id for this subscription
select @Report_OID = (select [ItemID] from [Catalog] where [Catalog].[Path] = @Report_Name and ([Catalog].[Type] = 2 or [Catalog].[Type] = 4))

EXEC GetUserID @OwnerSid, @OwnerName, @OwnerAuthType, @OwnerID OUTPUT
EXEC GetUserID @ModifiedBySid, @ModifiedByName, @ModifiedByAuthType, @ModifiedByID OUTPUT

if (@Report_OID is NULL)
begin
RAISERROR('Report Not Found', 16, 1)
return
end

Insert into Subscriptions
    (
        [SubscriptionID], 
        [OwnerID],
        [Report_OID], 
        [Locale],
        [DeliveryExtension],
        [InactiveFlags],
        [ExtensionSettings],
        [ModifiedByID],
        [ModifiedDate],
        [Description],
        [LastStatus],
        [EventType],
        [MatchData],
        [LastRunTime],
        [Parameters],
        [DataSettings],
	[Version]
    )
values
    (@id, @OwnerID, @Report_OID, @Locale, @DeliveryExtension, @InactiveFlags, @ExtensionSettings, @ModifiedByID, @ModifiedDate,
     @Description, @LastStatus, @EventType, @MatchData, NULL, @Parameters, @DataSettings, @Version)
GO
GRANT EXECUTE ON [dbo].[CreateSubscription] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DeliveryRemovedInactivateSubscription]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[DeliveryRemovedInactivateSubscription]
GO

CREATE PROCEDURE [dbo].[DeliveryRemovedInactivateSubscription] 
@DeliveryExtension nvarchar(260),
@Status nvarchar(260)
AS
update 
    Subscriptions
set
    [DeliveryExtension] = '',
    [InactiveFlags] = [InactiveFlags] | 1, -- Delivery Provider Removed Flag == 1
    [LastStatus] = @Status
where
    [DeliveryExtension] = @DeliveryExtension
GO

GRANT EXECUTE ON [dbo].[DeliveryRemovedInactivateSubscription] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DeleteSubscription]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[DeleteSubscription]
GO

CREATE PROCEDURE [dbo].[DeleteSubscription] 
@SubscriptionID uniqueidentifier
AS
-- Delete the given subscription
delete from [Subscriptions] where [SubscriptionID] = @SubscriptionID
GO

GRANT EXECUTE ON [dbo].[DeleteSubscription] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetSubscription]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetSubscription]
GO

CREATE PROCEDURE [dbo].[GetSubscription]
@SubscriptionID uniqueidentifier,
@AuthType int
AS

-- Grab all of the-- subscription properties given a id 
select 
        S.[SubscriptionID],
        S.[Report_OID],
        S.[Locale],
        S.[InactiveFlags],
        S.[DeliveryExtension], 
        S.[ExtensionSettings],
        SUSER_SNAME(Modified.[Sid]), 
        Modified.[UserName],
        S.[ModifiedDate], 
        S.[Description],
        S.[LastStatus],
        S.[EventType],
        S.[MatchData],
        S.[Parameters],
        S.[DataSettings],
        A.[TotalNotifications],
        A.[TotalSuccesses],
        A.[TotalFailures],
        SUSER_SNAME(Owner.[Sid]),
        Owner.[UserName],
        CAT.[Path],
        S.[LastRunTime],
        CAT.[Type],
        SD.NtSecDescPrimary,
        S.[Version]
from
    [Subscriptions] S inner join [Catalog] CAT on S.[Report_OID] = CAT.[ItemID]
    inner join [Users] Owner on S.OwnerID = Owner.UserID
    inner join [Users] Modified on S.ModifiedByID = Modified.UserID
    left outer join [SecData] SD on CAT.PolicyID = SD.PolicyID AND SD.AuthType = @AuthType
    left outer join [ActiveSubscriptions] A with (NOLOCK) on S.[SubscriptionID] = A.[SubscriptionID]
where
    S.[SubscriptionID] = @SubscriptionID
GO
GRANT EXECUTE ON [dbo].[GetSubscription] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ListSubscriptionsUsingDataSource]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[ListSubscriptionsUsingDataSource]
GO

CREATE PROCEDURE [dbo].[ListSubscriptionsUsingDataSource]
@DataSourceName nvarchar(450),
@AuthType int
AS
select 
    S.[SubscriptionID],
    S.[Report_OID],
    S.[Locale],
    S.[InactiveFlags],
    S.[DeliveryExtension], 
    S.[ExtensionSettings],
    SUSER_SNAME(Modified.[Sid]),
    Modified.[UserName],
    S.[ModifiedDate], 
    S.[Description],
    S.[LastStatus],
    S.[EventType],
    S.[MatchData],
    S.[Parameters],
    S.[DataSettings],
    A.[TotalNotifications],
    A.[TotalSuccesses],
    A.[TotalFailures],
    SUSER_SNAME(Owner.[Sid]),
    Owner.[UserName],
    CAT.[Path],
    S.[LastRunTime],
    CAT.[Type],
    SD.NtSecDescPrimary,
    S.[Version]
from
    [DataSource] DS inner join Catalog C on C.ItemID = DS.Link
    inner join Subscriptions S on S.[SubscriptionID] = DS.[SubscriptionID]
    inner join [Catalog] CAT on S.[Report_OID] = CAT.[ItemID]
    inner join [Users] Owner on S.OwnerID = Owner.UserID
    inner join [Users] Modified on S.ModifiedByID = Modified.UserID
    left join [SecData] SD on SD.[PolicyID] = CAT.[PolicyID] AND SD.AuthType = @AuthType
    left outer join [ActiveSubscriptions] A with (NOLOCK) on S.[SubscriptionID] = A.[SubscriptionID]
where 
    C.Path = @DataSourceName 
GO
GRANT EXECUTE ON [dbo].[ListSubscriptionsUsingDataSource] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[UpdateSubscriptionStatus]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[UpdateSubscriptionStatus]
GO

CREATE PROCEDURE [dbo].[UpdateSubscriptionStatus]
@SubscriptionID uniqueidentifier,
@Status nvarchar(260)
AS

update Subscriptions set
        [LastStatus] = @Status
where
    [SubscriptionID] = @SubscriptionID

GO 
GRANT EXECUTE ON [dbo].[UpdateSubscriptionStatus] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[UpdateSubscription]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[UpdateSubscription]
GO

CREATE PROCEDURE [dbo].[UpdateSubscription]
@id uniqueidentifier,
@Locale nvarchar(260),
@OwnerSid varbinary(85) = NULL,
@OwnerName nvarchar(260),
@OwnerAuthType int,
@DeliveryExtension nvarchar(260),
@InactiveFlags int,
@ExtensionSettings ntext = NULL,
@ModifiedBySid varbinary(85) = NULL, 
@ModifiedByName nvarchar(260),
@ModifiedByAuthType int,
@ModifiedDate datetime,
@Description nvarchar(512) = NULL,
@LastStatus nvarchar(260) = NULL,
@EventType nvarchar(260),
@MatchData ntext = NULL,
@Parameters ntext = NULL,
@DataSettings ntext = NULL,
@Version int
AS
-- Update a subscription's information.
DECLARE @ModifiedByID uniqueidentifier
DECLARE @OwnerID uniqueidentifier

EXEC GetUserID @ModifiedBySid, @OwnerName,@OwnerAuthType, @ModifiedByID OUTPUT
EXEC GetUserID @OwnerSid, @ModifiedByName, @ModifiedByAuthType, @OwnerID OUTPUT

-- Make sure there is a valid provider
update Subscriptions set
        [DeliveryExtension] = @DeliveryExtension,
        [Locale] = @Locale,
        [OwnerID] = @OwnerID,
        [InactiveFlags] = @InactiveFlags,
        [ExtensionSettings] = @ExtensionSettings,
        [ModifiedByID] = @ModifiedByID,
        [ModifiedDate] = @ModifiedDate,
        [Description] = @Description,
        [LastStatus] = @LastStatus,
        [EventType] = @EventType,
        [MatchData] = @MatchData,
        [Parameters] = @Parameters,
        [DataSettings] = @DataSettings,
	[Version] = @Version
where
    [SubscriptionID] = @id
GO
GRANT EXECUTE ON [dbo].[UpdateSubscription] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[InvalidateSubscription]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[InvalidateSubscription]
GO

CREATE PROCEDURE [dbo].[InvalidateSubscription] 
@SubscriptionID uniqueidentifier,
@Flags int,
@LastStatus nvarchar(260)
AS

-- Mark all subscriptions for this report as inactive for the given flags
update 
    Subscriptions 
set 
    [InactiveFlags] = S.[InactiveFlags] | @Flags,
    [LastStatus] = @LastStatus
from 
    Subscriptions S 
where 
    SubscriptionID = @SubscriptionID
GO
GRANT EXECUTE ON [dbo].[InvalidateSubscription] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CleanNotificationRecords]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CleanNotificationRecords]
GO

CREATE PROCEDURE [dbo].[CleanNotificationRecords] 
@MaxAgeMinutes int
AS
-- Reset all notifications which have been add over n minutes ago
Update [Notifications] set [ProcessStart] = NULL, [ProcessHeartbeat] = NULL, [Attempt] = 1
where [NotificationID] in
   ( SELECT [NotificationID]
     FROM [Notifications]
     WHERE [ProcessHeartbeat] < DATEADD(minute, -(@MaxAgeMinutes), GETUTCDATE()) and [Attempt] is NULL )

Update [Notifications] set [ProcessStart] = NULL, [ProcessHeartbeat] = NULL, [Attempt] = [Attempt] + 1
where [NotificationID] in
   ( SELECT [NotificationID]
     FROM [Notifications]
     WHERE [ProcessHeartbeat] < DATEADD(minute, -(@MaxAgeMinutes), GETUTCDATE()) and [Attempt] is not NULL )
GO
GRANT EXECUTE ON [dbo].[CleanNotificationRecords] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CreateSnapShotNotifications]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CreateSnapShotNotifications]
GO

CREATE PROCEDURE [dbo].[CreateSnapShotNotifications] 
@HistoryID uniqueidentifier,
@LastRunTime datetime
AS
update [Subscriptions]
set
    [LastRunTime] = @LastRunTime
from
    History SS inner join [Subscriptions] S on S.[Report_OID] = SS.[ReportID]
where 
    SS.[HistoryID] = @HistoryID and S.EventType = 'ReportHistorySnapshotCreated' and InactiveFlags = 0


-- Find all valid subscriptions for the given report and create a new notification row for
-- each subscription
insert into [Notifications] 
    (
    [NotificationID], 
    [SubscriptionID],
    [ActivationID],
    [ReportID],
    [SnapShotDate],
    [ExtensionSettings],
    [Locale],
    [Parameters],
    [NotificationEntered],
    [SubscriptionLastRunTime],
    [DeliveryExtension],
    [SubscriptionOwnerID],
    [IsDataDriven],
    [Version]
    ) 
select 
    NewID(),
    S.[SubscriptionID],
    NULL,
    S.[Report_OID],
    NULL,
    S.[ExtensionSettings],
    S.[Locale],
    S.[Parameters],
    GETUTCDATE(), 
    S.[LastRunTime],
    S.[DeliveryExtension],
    S.[OwnerID],
    0,
    S.[Version]
from 
    [Subscriptions] S with (READPAST) inner join History H on S.[Report_OID] = H.[ReportID]
where 
    H.[HistoryID] = @HistoryID and S.EventType = 'ReportHistorySnapshotCreated' and InactiveFlags = 0 and
    S.[DataSettings] is null

-- Create any data driven subscription by creating a data driven event
insert into [Event]
    (
    [EventID],
    [EventType],
    [EventData],
    [TimeEntered]
    )
select
    NewID(),
    'DataDrivenSubscription',
    S.SubscriptionID,
    GETUTCDATE()
from
    [Subscriptions] S with (READPAST) inner join History H on S.[Report_OID] = H.[ReportID]
where 
    H.[HistoryID] = @HistoryID and S.EventType = 'ReportHistorySnapshotCreated' and InactiveFlags = 0 and
    S.[DataSettings] is not null
    
GO
GRANT EXECUTE ON [dbo].[CreateSnapShotNotifications] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CreateDataDrivenNotification]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CreateDataDrivenNotification]
GO

CREATE PROCEDURE [dbo].[CreateDataDrivenNotification]
@SubscriptionID uniqueidentifier,
@ActiveationID uniqueidentifier,
@ReportID uniqueidentifier,
@ExtensionSettings ntext,
@Locale nvarchar(128),
@Parameters ntext,
@LastRunTime datetime,
@DeliveryExtension nvarchar(260),
@OwnerSid varbinary (85) = null,
@OwnerName nvarchar(260),
@OwnerAuthType int,
@Version int
AS

declare @OwnerID as uniqueidentifier

EXEC GetUserID @OwnerSid,@OwnerName, @OwnerAuthType, @OwnerID OUTPUT

-- Insert into the notification table
insert into [Notifications] 
    (
    [NotificationID], 
    [SubscriptionID],
    [ActivationID],
    [ReportID],
    [SnapShotDate],
    [ExtensionSettings],
    [Locale],
    [Parameters],
    [NotificationEntered],
    [SubscriptionLastRunTime],
    [DeliveryExtension],
    [SubscriptionOwnerID],
    [IsDataDriven],
    [Version]
    )
values
    (
    NewID(),
    @SubscriptionID,
    @ActiveationID,
    @ReportID,
    NULL,
    @ExtensionSettings,
    @Locale,
    @Parameters,
    GETUTCDATE(),
    @LastRunTime,
    @DeliveryExtension,
    @OwnerID,
    1,
    @Version
    )

GO
GRANT EXECUTE ON [dbo].[CreateDataDrivenNotification] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CreateNewActiveSubscription]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CreateNewActiveSubscription]
GO

CREATE PROCEDURE [dbo].[CreateNewActiveSubscription]
@ActiveID uniqueidentifier,
@SubscriptionID uniqueidentifier
AS


-- Insert into the activesubscription table
insert into [ActiveSubscriptions] 
    (
    [ActiveID], 
    [SubscriptionID],
    [TotalNotifications],
    [TotalSuccesses],
    [TotalFailures]
    )
values
    (
    @ActiveID,
    @SubscriptionID,
    NULL,
    0,
    0
    )


GO
GRANT EXECUTE ON [dbo].[CreateNewActiveSubscription] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[UpdateActiveSubscription]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[UpdateActiveSubscription]
GO

CREATE PROCEDURE [dbo].[UpdateActiveSubscription]
@ActiveID uniqueidentifier,
@TotalNotifications int = NULL,
@TotalSuccesses int = NULL,
@TotalFailures int = NULL
AS

if @TotalNotifications is not NULL
begin
    update ActiveSubscriptions set TotalNotifications = @TotalNotifications where ActiveID = @ActiveID
end

if @TotalSuccesses is not NULL
begin
    update ActiveSubscriptions set TotalSuccesses = @TotalSuccesses where ActiveID = @ActiveID
end

if @TotalFailures is not NULL
begin
    update ActiveSubscriptions set TotalFailures = @TotalFailures where ActiveID = @ActiveID
end

GO
GRANT EXECUTE ON [dbo].[UpdateActiveSubscription] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DeleteActiveSubscription]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[DeleteActiveSubscription]
GO

CREATE PROCEDURE [dbo].[DeleteActiveSubscription]
@ActiveID uniqueidentifier
AS

delete from ActiveSubscriptions where ActiveID = @ActiveID

GO
GRANT EXECUTE ON [dbo].[DeleteActiveSubscription] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetAndHoldLockActiveSubscription]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetAndHoldLockActiveSubscription]
GO

CREATE PROCEDURE [dbo].[GetAndHoldLockActiveSubscription]
@ActiveID uniqueidentifier
AS

select 
    TotalNotifications, 
    TotalSuccesses, 
    TotalFailures 
from 
    ActiveSubscriptions with (XLOCK)
where
    ActiveID = @ActiveID

GO
GRANT EXECUTE ON [dbo].[GetAndHoldLockActiveSubscription] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CreateCacheUpdateNotifications]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CreateCacheUpdateNotifications]
GO

CREATE PROCEDURE [dbo].[CreateCacheUpdateNotifications] 
@ReportID uniqueidentifier,
@LastRunTime datetime
AS

update [Subscriptions]
set
    [LastRunTime] = @LastRunTime
from
    [Subscriptions] S 
where 
    S.[Report_OID] = @ReportID and S.EventType = 'SnapshotUpdated' and InactiveFlags = 0


-- Find all valid subscriptions for the given report and create a new notification row for
-- each subscription
insert into [Notifications] 
    (
    [NotificationID], 
    [SubscriptionID],
    [ActivationID],
    [ReportID],
    [SnapShotDate],
    [ExtensionSettings],
    [Locale],
    [Parameters],
    [NotificationEntered],
    [SubscriptionLastRunTime],
    [DeliveryExtension],
    [SubscriptionOwnerID],
    [IsDataDriven],
    [Version]
    ) 
select 
    NewID(),
    S.[SubscriptionID],
    NULL,
    S.[Report_OID],
    NULL,
    S.[ExtensionSettings],
    S.[Locale],
    S.[Parameters],
    GETUTCDATE(), 
    S.[LastRunTime],
    S.[DeliveryExtension],
    S.[OwnerID],
    0,
    S.[Version]
from 
    [Subscriptions] S  inner join Catalog C on S.[Report_OID] = C.[ItemID]
where 
    C.[ItemID] = @ReportID and S.EventType = 'SnapshotUpdated' and InactiveFlags = 0 and
    S.[DataSettings] is null

-- Create any data driven subscription by creating a data driven event
insert into [Event]
    (
    [EventID],
    [EventType],
    [EventData],
    [TimeEntered]
    )
select
    NewID(),
    'DataDrivenSubscription',
    S.SubscriptionID,
    GETUTCDATE()
from
    [Subscriptions] S  inner join Catalog C on S.[Report_OID] = C.[ItemID]
where 
    C.[ItemID] = @ReportID and S.EventType = 'SnapshotUpdated' and InactiveFlags = 0 and
    S.[DataSettings] is not null
    
GO
GRANT EXECUTE ON [dbo].[CreateCacheUpdateNotifications] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetCacheSchedule]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetCacheSchedule]
GO

CREATE PROCEDURE [dbo].[GetCacheSchedule] 
@ReportID uniqueidentifier
AS
SELECT
    S.[ScheduleID],
    S.[Name],
    S.[StartDate], 
    S.[Flags],
    S.[NextRunTime],
    S.[LastRunTime], 
    S.[EndDate], 
    S.[RecurrenceType],
    S.[MinutesInterval],
    S.[DaysInterval],
    S.[WeeksInterval],
    S.[DaysOfWeek], 
    S.[DaysOfMonth], 
    S.[Month], 
    S.[MonthlyWeek], 
    S.[State], 
    S.[LastRunStatus],
    S.[ScheduledRunTimeout],
    S.[EventType],
    S.[EventData],
    S.[Type],
    SUSER_SNAME(Owner.[Sid]),
    Owner.[UserName],
    RS.ReportAction
FROM
    Schedule S with (XLOCK) inner join ReportSchedule RS on S.ScheduleID = RS.ScheduleID
    inner join [Users] Owner on S.[CreatedById] = Owner.[UserID]
WHERE
    (RS.ReportAction = 1 or RS.ReportAction = 3) and -- 1 == UpdateCache, 3 == Invalidate cache
    RS.[ReportID] = @ReportID
GO
GRANT EXECUTE ON [dbo].[GetCacheSchedule] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DeleteNotification]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[DeleteNotification]
GO

CREATE PROCEDURE [dbo].[DeleteNotification] 
@ID uniqueidentifier
AS
delete from [Notifications] where [NotificationID] = @ID
GO
GRANT EXECUTE ON [dbo].[DeleteNotification] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SetNotificationAttempt]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SetNotificationAttempt]
GO

CREATE PROCEDURE [dbo].[SetNotificationAttempt] 
@Attempt int,
@SecondsToAdd int,
@NotificationID uniqueidentifier
AS

update 
    [Notifications] 
set 
    [ProcessStart] = NULL, 
    [Attempt] = @Attempt, 
    [ProcessAfter] = DateAdd(second, @SecondsToAdd, GetUtcDate())
where
    [NotificationID] = @NotificationID
GO
GRANT EXECUTE ON [dbo].[SetNotificationAttempt] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CreateTimeBasedSubscriptionNotification]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CreateTimeBasedSubscriptionNotification]
GO

CREATE PROCEDURE [dbo].[CreateTimeBasedSubscriptionNotification]
@SubscriptionID uniqueidentifier,
@LastRunTime datetime
as

insert into [Notifications] 
    (
    [NotificationID], 
    [SubscriptionID],
    [ActivationID],
    [ReportID],
    [SnapShotDate],
    [ExtensionSettings],
    [Locale],
    [Parameters],
    [NotificationEntered],
    [SubscriptionLastRunTime],
    [DeliveryExtension],
    [SubscriptionOwnerID],
    [IsDataDriven],
    [Version]
    ) 
select 
    NewID(),
    S.[SubscriptionID],
    NULL,
    S.[Report_OID],
    NULL,
    S.[ExtensionSettings],
    S.[Locale],
    S.[Parameters],
    GETUTCDATE(), 
    @LastRunTime,
    S.[DeliveryExtension],
    S.[OwnerID],
    0,
    S.[Version]
from 
    [Subscriptions] S 
where 
    S.[SubscriptionID] = @SubscriptionID and InactiveFlags = 0 and
    S.[DataSettings] is null


-- Create any data driven subscription by creating a data driven event
insert into [Event]
    (
    [EventID],
    [EventType],
    [EventData],
    [TimeEntered]
    )
select
    NewID(),
    'DataDrivenSubscription',
    S.SubscriptionID,
    GETUTCDATE()
from
    [Subscriptions] S 
where 
    S.[SubscriptionID] = @SubscriptionID and InactiveFlags = 0 and
    S.[DataSettings] is not null

update [Subscriptions]
set
    [LastRunTime] = @LastRunTime
where 
    [SubscriptionID] = @SubscriptionID and InactiveFlags = 0

GO
GRANT EXECUTE ON [dbo].[CreateTimeBasedSubscriptionNotification] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DeleteTimeBasedSubscriptionSchedule]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[DeleteTimeBasedSubscriptionSchedule]
GO

CREATE PROCEDURE [dbo].[DeleteTimeBasedSubscriptionSchedule]
@SubscriptionID as uniqueidentifier
as

delete ReportSchedule from ReportSchedule RS inner join Subscriptions S on S.[SubscriptionID] = RS.[SubscriptionID]
where
    S.[SubscriptionID] = @SubscriptionID
GO

GRANT EXECUTE ON [dbo].[DeleteTimeBasedSubscriptionSchedule] TO RSExecRole
GO

--------------------------------------------------
------------- Provider Info

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ListUsedDeliveryProviders]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[ListUsedDeliveryProviders]
GO

CREATE PROCEDURE [dbo].[ListUsedDeliveryProviders] 
AS
select distinct [DeliveryExtension] from Subscriptions where [DeliveryExtension] <> ''
GO
GRANT EXECUTE ON [dbo].[ListUsedDeliveryProviders] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id('[dbo].[AddBatchRecord]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[AddBatchRecord]
GO

CREATE PROCEDURE [dbo].[AddBatchRecord]
@BatchID uniqueidentifier,
@UserName nvarchar(260),
@Action varchar(32),
@Item nvarchar(425) = NULL,
@Parent nvarchar(425) = NULL,
@Param nvarchar(425) = NULL,
@BoolParam bit = NULL,
@Content image = NULL,
@Properties ntext = NULL
AS

IF @Action='BatchStart' BEGIN
   INSERT
   INTO [Batch] (BatchID, AddedOn, [Action], Item, Parent, Param, BoolParam, Content, Properties)
   VALUES (@BatchID, GETUTCDATE(), @Action, @UserName, @Parent, @Param, @BoolParam, @Content, @Properties)
END ELSE BEGIN
   IF EXISTS (SELECT * FROM Batch WHERE BatchID = @BatchID AND [Action] = 'BatchStart' AND Item = @UserName) BEGIN
      INSERT
      INTO [Batch] (BatchID, AddedOn, [Action], Item, Parent, Param, BoolParam, Content, Properties)
      VALUES (@BatchID, GETUTCDATE(), @Action, @Item, @Parent, @Param, @BoolParam, @Content, @Properties)
   END ELSE BEGIN
      RAISERROR( 'Batch does not exist', 16, 1 )
   END
END
GO
GRANT EXECUTE ON [dbo].[AddBatchRecord] TO RSExecRole
GO

if exists (select * from sysobjects where id = object_id('[dbo].[GetBatchRecords]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetBatchRecords]
GO

CREATE PROCEDURE [dbo].[GetBatchRecords]
@BatchID uniqueidentifier
AS
SELECT [Action], Item, Parent, Param, BoolParam, Content, Properties
FROM [Batch]
WHERE BatchID = @BatchID
ORDER BY AddedOn
GO
GRANT EXECUTE ON [dbo].[GetBatchRecords] TO RSExecRole
GO

if exists (select * from sysobjects where id = object_id('[dbo].[DeleteBatchRecords]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[DeleteBatchRecords]
GO

CREATE PROCEDURE [dbo].[DeleteBatchRecords]
@BatchID uniqueidentifier
AS
DELETE
FROM [Batch]
WHERE BatchID = @BatchID
GO
GRANT EXECUTE ON [dbo].[DeleteBatchRecords] TO RSExecRole
GO

if exists (select * from sysobjects where id = object_id('[dbo].[CleanBatchRecords]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CleanBatchRecords]
GO

CREATE PROCEDURE [dbo].[CleanBatchRecords]
@MaxAgeMinutes int
AS
DELETE FROM [Batch]
where BatchID in
   ( SELECT BatchID
     FROM [Batch]
     WHERE AddedOn < DATEADD(minute, -(@MaxAgeMinutes), GETUTCDATE()) )
GO
GRANT EXECUTE ON [dbo].[CleanBatchRecords] TO RSExecRole
GO

if exists (select * from sysobjects where id = object_id('[dbo].[CleanOrphanedPolicies]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CleanOrphanedPolicies]
GO

-- Cleaning orphan policies
CREATE PROCEDURE [dbo].[CleanOrphanedPolicies]
AS
DELETE
   [Policies]
WHERE
   [Policies].[PolicyFlag] = 0
   AND
   NOT EXISTS (SELECT ItemID FROM [Catalog] WHERE [Catalog].[PolicyID] = [Policies].[PolicyID])

DELETE
   [Policies]
FROM
   [Policies]
   INNER JOIN [ModelItemPolicy] ON [ModelItemPolicy].[PolicyID] = [Policies].[PolicyID]
WHERE
   NOT EXISTS (SELECT ItemID
               FROM [Catalog] 
               WHERE [Catalog].[ItemID] = [ModelItemPolicy].[CatalogItemID])

GO
GRANT EXECUTE ON [dbo].[CleanOrphanedPolicies] TO RSExecRole
GO

--------------------------------------------------
------------- Snapshot manipulation

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[IncreaseTransientSnapshotRefcount]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[IncreaseTransientSnapshotRefcount]
GO

CREATE PROCEDURE [dbo].[IncreaseTransientSnapshotRefcount]
@SnapshotDataID as uniqueidentifier,
@IsPermanentSnapshot as bit,
@ExpirationMinutes as int
AS

DECLARE @soon AS datetime
SET @soon = DATEADD(n, @ExpirationMinutes, GETDATE())

if @IsPermanentSnapshot = 1
BEGIN
   UPDATE SnapshotData
   SET ExpirationDate = @soon, TransientRefcount = TransientRefcount + 1
   WHERE SnapshotDataID = @SnapshotDataID
END ELSE BEGIN
   UPDATE [ReportServerTempDB].dbo.SnapshotData
   SET ExpirationDate = @soon, TransientRefcount = TransientRefcount + 1
   WHERE SnapshotDataID = @SnapshotDataID
END
GO

GRANT EXECUTE ON [dbo].[IncreaseTransientSnapshotRefcount] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DecreaseTransientSnapshotRefcount]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[DecreaseTransientSnapshotRefcount]
GO

CREATE PROCEDURE [dbo].[DecreaseTransientSnapshotRefcount]
@SnapshotDataID as uniqueidentifier,
@IsPermanentSnapshot as bit
AS

if @IsPermanentSnapshot = 1
BEGIN
   UPDATE SnapshotData
   SET TransientRefcount = TransientRefcount - 1
   WHERE SnapshotDataID = @SnapshotDataID
END ELSE BEGIN
   UPDATE [ReportServerTempDB].dbo.SnapshotData
   SET TransientRefcount = TransientRefcount - 1
   WHERE SnapshotDataID = @SnapshotDataID
END
GO

GRANT EXECUTE ON [dbo].[DecreaseTransientSnapshotRefcount] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[MarkSnapshotAsDependentOnUser]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[MarkSnapshotAsDependentOnUser]
GO

CREATE PROCEDURE [dbo].[MarkSnapshotAsDependentOnUser]
@SnapshotDataID as uniqueidentifier,
@IsPermanentSnapshot as bit
AS

if @IsPermanentSnapshot = 1
BEGIN
   UPDATE SnapshotData
   SET DependsOnUser = 1
   WHERE SnapshotDataID = @SnapshotDataID
END ELSE BEGIN
   UPDATE [ReportServerTempDB].dbo.SnapshotData
   SET DependsOnUser = 1
   WHERE SnapshotDataID = @SnapshotDataID
END
GO

GRANT EXECUTE ON [dbo].[MarkSnapshotAsDependentOnUser] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SetSnapshotChunksVersion]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SetSnapshotChunksVersion]
GO

CREATE PROCEDURE [dbo].[SetSnapshotChunksVersion]
@SnapshotDataID as uniqueidentifier,
@IsPermanentSnapshot as bit,
@Version as smallint
AS

if @IsPermanentSnapshot = 1
BEGIN
   if @Version > 0
   BEGIN
      UPDATE ChunkData
      SET Version = @Version
      WHERE SnapshotDataID = @SnapshotDataID
   END ELSE BEGIN
      UPDATE ChunkData
      SET Version = Version
      WHERE SnapshotDataID = @SnapshotDataID
   END   
END ELSE BEGIN
   if @Version > 0
   BEGIN
      UPDATE [ReportServerTempDB].dbo.ChunkData
      SET Version = @Version
      WHERE SnapshotDataID = @SnapshotDataID
   END ELSE BEGIN
      UPDATE [ReportServerTempDB].dbo.ChunkData
      SET Version = Version
      WHERE SnapshotDataID = @SnapshotDataID
   END   
END
GO

GRANT EXECUTE ON [dbo].[SetSnapshotChunksVersion] TO RSExecRole
GO


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[LockSnapshotForUpgrade]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[LockSnapshotForUpgrade]
GO

CREATE PROCEDURE [dbo].[LockSnapshotForUpgrade]
@SnapshotDataID as uniqueidentifier,
@IsPermanentSnapshot as bit
AS
if @IsPermanentSnapshot = 1
BEGIN
   SELECT ChunkName from ChunkData with (XLOCK)
   WHERE SnapshotDataID = @SnapshotDataID
END ELSE BEGIN
   SELECT ChunkName from [ReportServerTempDB].dbo.ChunkData with (XLOCK)
   WHERE SnapshotDataID = @SnapshotDataID
END
GO

GRANT EXECUTE ON [dbo].[LockSnapshotForUpgrade] TO RSExecRole
GO


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[InsertUnreferencedSnapshot]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[InsertUnreferencedSnapshot]
GO

CREATE PROCEDURE [dbo].[InsertUnreferencedSnapshot]
@ReportID as uniqueidentifier = NULL,
@EffectiveParams as ntext = NULL,
@QueryParams as ntext = NULL,
@ParamsHash as int = NULL,
@CreatedDate as datetime,
@Description as nvarchar(512) = NULL,
@SnapshotDataID as uniqueidentifier,
@IsPermanentSnapshot as bit,
@SnapshotTimeoutMinutes as int,
@Machine as nvarchar(512) = NULL
AS
DECLARE @now datetime
SET @now = GETDATE()

IF @IsPermanentSnapshot = 1
BEGIN
   INSERT INTO SnapshotData
      (SnapshotDataID, CreatedDate, EffectiveParams, QueryParams, ParamsHash, Description, PermanentRefcount, TransientRefcount, ExpirationDate)
   VALUES
      (@SnapshotDataID, @CreatedDate, @EffectiveParams, @QueryParams, @ParamsHash, @Description, 0, 1, DATEADD(n, @SnapshotTimeoutMinutes, @now))
END ELSE BEGIN
   INSERT INTO [ReportServerTempDB].dbo.SnapshotData
      (SnapshotDataID, CreatedDate, EffectiveParams, QueryParams, ParamsHash, Description, PermanentRefcount, TransientRefcount, ExpirationDate, Machine)
   VALUES
      (@SnapshotDataID, @CreatedDate, @EffectiveParams, @QueryParams, @ParamsHash, @Description, 0, 1, DATEADD(n, @SnapshotTimeoutMinutes, @now), @Machine)
END      
GO

GRANT EXECuTE ON [dbo].[InsertUnreferencedSnapshot] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[PromoteSnapshotInfo]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[PromoteSnapshotInfo]
GO

CREATE PROCEDURE [dbo].[PromoteSnapshotInfo]
@SnapshotDataID as uniqueidentifier,
@IsPermanentSnapshot as bit,
@PageCount as int,
@HasDocMap as bit
AS

IF @IsPermanentSnapshot = 1
BEGIN
   UPDATE SnapshotData SET PageCount = @PageCount, HasDocMap = @HasDocMap
   WHERE SnapshotDataID = @SnapshotDataID
END ELSE BEGIN
   UPDATE [ReportServerTempDB].dbo.SnapshotData SET PageCount = @PageCount, HasDocMap = @HasDocMap
   WHERE SnapshotDataID = @SnapshotDataID
END      
GO

GRANT EXECUTE ON [dbo].[PromoteSnapshotInfo] TO RSExecRole
GO


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetSnapshotPromotedInfo]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetSnapshotPromotedInfo]
GO

CREATE PROCEDURE [dbo].[GetSnapshotPromotedInfo]
@SnapshotDataID as uniqueidentifier,
@IsPermanentSnapshot as bit
AS

IF @IsPermanentSnapshot = 1
BEGIN
   SELECT PageCount, HasDocMap
   FROM SnapshotData
   WHERE SnapshotDataID = @SnapshotDataID
END ELSE BEGIN
   SELECT PageCount, HasDocMap 
   FROM [ReportServerTempDB].dbo.SnapshotData
   WHERE SnapshotDataID = @SnapshotDataID
END      
GO

GRANT EXECUTE ON [dbo].[GetSnapshotPromotedInfo] TO RSExecRole
GO


if exists (select * from sysobjects where id = object_id('[dbo].[AddHistoryRecord]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[AddHistoryRecord]
GO

-- add new record to History table
CREATE PROCEDURE [dbo].[AddHistoryRecord]
@HistoryID uniqueidentifier,
@ReportID uniqueidentifier,
@SnapshotDate datetime,
@SnapshotDataID uniqueidentifier,
@SnapshotTransientRefcountChange int
AS
INSERT
INTO History (HistoryID, ReportID, SnapshotDataID, SnapshotDate)
VALUES (@HistoryID, @ReportID, @SnapshotDataID, @SnapshotDate)

IF @@ERROR = 0
BEGIN
   UPDATE SnapshotData
   -- Snapshots, when created, have transient refcount set to 1. Here create permanent reference
   -- here so we need to increase permanent refcount and decrease transient refcount. However,
   -- if it was already referenced by the execution snapshot, transient refcount was already
   -- decreased. Hence, there's a parameter @SnapshotTransientRefcountChange that is 0 or -1.
   SET PermanentRefcount = PermanentRefcount + 1, TransientRefcount = TransientRefcount + @SnapshotTransientRefcountChange
   WHERE SnapshotData.SnapshotDataID = @SnapshotDataID
END
GO
GRANT EXECUTE ON [dbo].[AddHistoryRecord] TO RSExecRole
GO

if exists (select * from sysobjects where id = object_id('[dbo].[SetHistoryLimit]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SetHistoryLimit]
GO

CREATE PROCEDURE [dbo].[SetHistoryLimit]
@Path nvarchar (425),
@SnapshotLimit int = NULL
AS
UPDATE Catalog
SET SnapshotLimit=@SnapshotLimit
WHERE Path = @Path
GO
GRANT EXECUTE ON [dbo].[SetHistoryLimit] TO RSExecRole
GO

if exists (select * from sysobjects where id = object_id('[dbo].[ListHistory]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[ListHistory]
GO

-- list all historical snapshots for a specific report
CREATE PROCEDURE [dbo].[ListHistory]
@ReportID uniqueidentifier
AS
SELECT
   S.SnapshotDate,
   (SELECT SUM(DATALENGTH( CD.Content ) ) FROM ChunkData AS CD WHERE CD.SnapshotDataID = S.SnapshotDataID )
FROM
   History AS S -- skipping intermediate table SnapshotData
WHERE
   S.ReportID = @ReportID
GO
GRANT EXECUTE ON [dbo].[ListHistory] TO RSExecRole
GO

if exists (select * from sysobjects where id = object_id('[dbo].[CleanHistoryForReport]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CleanHistoryForReport]
GO

-- delete snapshots exceeding # of snapshots. won't work if @SnapshotLimit = 0
CREATE PROCEDURE [dbo].[CleanHistoryForReport]
@SnapshotLimit int,
@ReportID uniqueidentifier
AS
DECLARE @cmd varchar(2000)
SET @cmd =
'DELETE
 FROM History
 WHERE ReportID = ''' + cast(@ReportID as varchar(40) ) + ''' and SnapshotDate <
    (SELECT MIN(SnapshotDate)
     FROM
        (SELECT TOP ' + CAST(@SnapshotLimit as varchar(20)) + ' SnapshotDate
         FROM History
         WHERE ReportID = ''' + cast(@ReportID as varchar(40) ) + '''
         ORDER BY SnapshotDate DESC
        ) AS TopSnapshots
    )'
EXEC( @cmd )
GO
GRANT EXECUTE ON [dbo].[CleanHistoryForReport] TO RSExecRole
GO

if exists (select * from sysobjects where id = object_id('[dbo].[CleanAllHistories]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CleanAllHistories]
GO

-- delete snapshots exceeding # of snapshots for the whole system
CREATE PROCEDURE [dbo].[CleanAllHistories]
@SnapshotLimit int
AS
DECLARE @cmd varchar(2000)
SET @cmd =
'DELETE
 FROM History
 WHERE HistoryID in 
    (SELECT HistoryID
     FROM History JOIN Catalog AS ReportJoinSnapshot ON ItemID = ReportID
     WHERE SnapshotLimit is NULL and SnapshotDate <
       (SELECT MIN(SnapshotDate) 
        FROM 
          (SELECT TOP ' + CAST(@SnapshotLimit as varchar(20)) + ' SnapshotDate
           FROM History AS InnerSnapshot
           WHERE InnerSnapshot.ReportID = ReportJoinSnapshot.ItemID
           ORDER BY SnapshotDate DESC
          ) AS TopSnapshots
       )
    )'
EXEC( @cmd )
GO
GRANT EXECUTE ON [dbo].[CleanAllHistories] TO RSExecRole
GO

if exists (select * from sysobjects where id = object_id('[dbo].[DeleteHistoryRecord]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[DeleteHistoryRecord]
GO

-- delete one historical snapshot
CREATE PROCEDURE [dbo].[DeleteHistoryRecord]
@ReportID uniqueidentifier,
@SnapshotDate DateTime
AS
DELETE
FROM History
WHERE ReportID = @ReportID AND SnapshotDate = @SnapshotDate
GO
GRANT EXECUTE ON [dbo].[DeleteHistoryRecord] TO RSExecRole
GO

if exists (select * from sysobjects where id = object_id('[dbo].[DeleteAllHistoryForReport]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[DeleteAllHistoryForReport]
GO

-- delete all snapshots for a report
CREATE PROCEDURE [dbo].[DeleteAllHistoryForReport]
@ReportID uniqueidentifier
AS
DELETE
FROM History
WHERE HistoryID in
   (SELECT HistoryID
    FROM History JOIN Catalog on ItemID = ReportID
    WHERE ReportID = @ReportID
   )
GO
GRANT EXECUTE ON [dbo].[DeleteAllHistoryForReport] TO RSExecRole
GO

if exists (select * from sysobjects where id = object_id('[dbo].[DeleteHistoriesWithNoPolicy]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[DeleteHistoriesWithNoPolicy]
GO

-- delete all snapshots for all reports that inherit system History policy
CREATE PROCEDURE [dbo].[DeleteHistoriesWithNoPolicy]
AS
DELETE
FROM History
WHERE HistoryID in
   (SELECT HistoryID
    FROM History JOIN Catalog on ItemID = ReportID
    WHERE SnapshotLimit is null
   )
GO
GRANT EXECUTE ON [dbo].[DeleteHistoriesWithNoPolicy] TO RSExecRole
GO


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[Get_sqlagent_job_status]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[Get_sqlagent_job_status]
GO

CREATE PROCEDURE [dbo].[Get_sqlagent_job_status]
  -- Individual job parameters
  @job_id                     UNIQUEIDENTIFIER = NULL,  -- If provided will only return info about this job
                                                        --   Note: Only @job_id or @job_name needs to be provided    
  @job_name                   sysname          = NULL,  -- If provided will only return info about this job 
  @owner_login_name           sysname          = NULL   -- If provided will only return jobs for this owner
AS
BEGIN
  DECLARE @retval           INT
  DECLARE @job_owner_sid    VARBINARY(85)
  DECLARE @is_sysadmin      INT

  SET NOCOUNT ON

  -- Remove any leading/trailing spaces from parameters (except @owner_login_name)
  SELECT @job_name         = LTRIM(RTRIM(@job_name)) 

  -- Turn [nullable] empty string parameters into NULLs
  IF (@job_name         = N'') SELECT @job_name = NULL


  -- Verify the job if supplied. This also checks if the caller has rights to view the job 
  IF ((@job_id IS NOT NULL) OR (@job_name IS NOT NULL))
  BEGIN
    EXECUTE @retval = msdb..sp_verify_job_identifiers '@job_name',
                                                      '@job_id',
                                                       @job_name OUTPUT,
                                                       @job_id   OUTPUT
    IF (@retval <> 0)
      RETURN(1) -- Failure

  END
  
  -- If the login name isn't given, set it to the job owner or the current caller 
  IF(@owner_login_name IS NULL)
  BEGIN
        
    SET @owner_login_name = (SELECT SUSER_SNAME(sj.owner_sid) FROM msdb.dbo.sysjobs sj where sj.job_id = @job_id)

    SET @is_sysadmin = ISNULL(IS_SRVROLEMEMBER(N'sysadmin', @owner_login_name), 0)

  END
  ELSE
  BEGIN
    -- Check owner
    IF (SUSER_SID(@owner_login_name) IS NULL)
    BEGIN
      RAISERROR(14262, -1, -1, '@owner_login_name', @owner_login_name)
      RETURN(1) -- Failure
    END

    --only allow sysadmin types to specify the owner
    IF ((ISNULL(IS_SRVROLEMEMBER(N'sysadmin'), 0) <> 1) AND
        (ISNULL(IS_MEMBER(N'SQLAgentAdminRole'), 0) = 1) AND
        (SUSER_SNAME() <> @owner_login_name))
    BEGIN
      --TODO: RAISERROR(14525, -1, -1)
      RETURN(1) -- Failure
    END

    SET @is_sysadmin = 0
  END


  IF (@job_id IS NOT NULL)
  BEGIN
    -- Individual job...
    EXECUTE @retval =  master.dbo.xp_sqlagent_enum_jobs @is_sysadmin, @owner_login_name, @job_id
    IF (@retval <> 0)
      RETURN(1) -- Failure

  END
  ELSE
  BEGIN
    -- Set of jobs...
    EXECUTE @retval =  master.dbo.xp_sqlagent_enum_jobs @is_sysadmin, @owner_login_name
    IF (@retval <> 0)
      RETURN(1) -- Failure

  END

  RETURN(0) -- Success
END
GO
GRANT EXECUTE ON [dbo].[Get_sqlagent_job_status] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CreateTask]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CreateTask]
GO

CREATE PROCEDURE [dbo].[CreateTask]
@ScheduleID uniqueidentifier,
@Name nvarchar (260),
@StartDate datetime,
@Flags int,
@NextRunTime datetime = NULL,
@LastRunTime datetime = NULL,
@EndDate datetime = NULL,
@RecurrenceType int = NULL,
@MinutesInterval int = NULL,
@DaysInterval int = NULL,
@WeeksInterval int = NULL,
@DaysOfWeek int = NULL,
@DaysOfMonth int = NULL,
@Month int = NULL,
@MonthlyWeek int = NULL,
@State int = NULL,
@LastRunStatus nvarchar (260) = NULL,
@ScheduledRunTimeout int = NULL,
@UserSid varbinary (85) = null,
@UserName nvarchar(260),
@AuthType int,
@EventType nvarchar (260),
@EventData nvarchar (260),
@Type int
AS

DECLARE @UserID uniqueidentifier

EXEC GetUserID @UserSid, @UserName, @AuthType, @UserID OUTPUT

-- Create a task with the given data. 
Insert into Schedule 
    (
        [ScheduleID], 
        [Name],
        [StartDate],
        [Flags],
        [NextRunTime],
        [LastRunTime], 
        [EndDate], 
        [RecurrenceType], 
        [MinutesInterval],
        [DaysInterval],
        [WeeksInterval],
        [DaysOfWeek], 
        [DaysOfMonth], 
        [Month], 
        [MonthlyWeek],
        [State], 
        [LastRunStatus],
        [ScheduledRunTimeout],
        [CreatedById],
        [EventType],
        [EventData],
        [Type]
    )
values
    (@ScheduleID, @Name, @StartDate, @Flags, @NextRunTime, @LastRunTime, @EndDate, @RecurrenceType, @MinutesInterval,
     @DaysInterval, @WeeksInterval, @DaysOfWeek, @DaysOfMonth, @Month, @MonthlyWeek, @State, @LastRunStatus,
     @ScheduledRunTimeout, @UserID, @EventType, @EventData, @Type)

GO
GRANT EXECUTE ON [dbo].[CreateTask] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[UpdateTask]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[UpdateTask]
GO

CREATE PROCEDURE [dbo].[UpdateTask]
@ScheduleID uniqueidentifier,
@Name nvarchar (260),
@StartDate datetime,
@Flags int,
@NextRunTime datetime = NULL,
@LastRunTime datetime = NULL,
@EndDate datetime = NULL,
@RecurrenceType int = NULL,
@MinutesInterval int = NULL,
@DaysInterval int = NULL,
@WeeksInterval int = NULL,
@DaysOfWeek int = NULL,
@DaysOfMonth int = NULL,
@Month int = NULL,
@MonthlyWeek int = NULL,
@State int = NULL,
@LastRunStatus nvarchar (260) = NULL,
@ScheduledRunTimeout int = NULL

AS

-- Update a tasks values. ScheduleID and Report information can not be updated
Update Schedule set
        [StartDate] = @StartDate, 
        [Name] = @Name,
        [Flags] = @Flags,
        [NextRunTime] = @NextRunTime,
        [LastRunTime] = @LastRunTime,
        [EndDate] = @EndDate, 
        [RecurrenceType] = @RecurrenceType, 
        [MinutesInterval] = @MinutesInterval,
        [DaysInterval] = @DaysInterval,
        [WeeksInterval] = @WeeksInterval,
        [DaysOfWeek] = @DaysOfWeek, 
        [DaysOfMonth] = @DaysOfMonth, 
        [Month] = @Month, 
        [MonthlyWeek] = @MonthlyWeek, 
        [State] = @State, 
        [LastRunStatus] = @LastRunStatus,
        [ScheduledRunTimeout] = @ScheduledRunTimeout
where
    [ScheduleID] = @ScheduleID

GO
GRANT EXECUTE ON [dbo].[UpdateTask] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[UpdateScheduleNextRunTime]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[UpdateScheduleNextRunTime]
GO

CREATE PROCEDURE [dbo].[UpdateScheduleNextRunTime]
@ScheduleID as uniqueidentifier,
@NextRunTime as datetime
as
update Schedule set [NextRunTime] = @NextRunTime where [ScheduleID] = @ScheduleID
GO
GRANT EXECUTE ON [dbo].[UpdateScheduleNextRunTime] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ListScheduledReports]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[ListScheduledReports]
GO

CREATE PROCEDURE [dbo].[ListScheduledReports]
@ScheduleID uniqueidentifier,
@AuthType int
AS
-- List all reports for a schedule
select 
        RS.[ReportAction],
        RS.[ScheduleID],
        RS.[ReportID],
        RS.[SubscriptionID],
        C.[Path],
        C.[Name],
        C.[Description],
        C.[ModifiedDate],
        SUSER_SNAME(U.[Sid]),
        U.[UserName],
        DATALENGTH( C.Content ),
        C.ExecutionTime,
        S.[Type],
        SD.[NtSecDescPrimary]
from
    [ReportSchedule] RS Inner join [Catalog] C on RS.[ReportID] = C.[ItemID]
    left outer join [SecData] SD on SD.[PolicyID] = C.[PolicyID] AND    SD.AuthType = @AuthType
    Inner join [Schedule] S on RS.[ScheduleID] = S.[ScheduleID]
    Inner join [Users] U on C.[ModifiedByID] = U.UserID
where
    RS.[ScheduleID] = @ScheduleID 
    
GO
GRANT EXECUTE ON [dbo].[ListScheduledReports] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ListTasks]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[ListTasks]
GO

CREATE PROCEDURE [dbo].[ListTasks]
AS

select 
        S.[ScheduleID],
        S.[Name],
        S.[StartDate],
        S.[Flags],
        S.[NextRunTime],
        S.[LastRunTime],
        S.[EndDate],
        S.[RecurrenceType],
        S.[MinutesInterval],
        S.[DaysInterval],
        S.[WeeksInterval],
        S.[DaysOfWeek],
        S.[DaysOfMonth],
        S.[Month],
        S.[MonthlyWeek],
        S.[State], 
        S.[LastRunStatus],
        S.[ScheduledRunTimeout],
        S.[EventType],
        S.[EventData],
        S.[Type],
        SUSER_SNAME(Owner.[Sid]),
        Owner.[UserName],
        (select count(*) from ReportSchedule where ReportSchedule.ScheduleID = S.ScheduleID)
from
    [Schedule] S  inner join [Users] Owner on S.[CreatedById] = Owner.UserID
where
    S.[Type] = 0 -- Type 0 is shared schedules
GO
GRANT EXECUTE ON [dbo].[ListTasks] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ListTasksForMaintenance]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[ListTasksForMaintenance]
GO

CREATE PROCEDURE [dbo].[ListTasksForMaintenance]
AS

declare @date datetime
set @date = GETUTCDATE()

update
    [Schedule]
set
    [ConsistancyCheck] = @date
from 
(
  SELECT TOP 20 [ScheduleID] FROM [Schedule] WITH(UPDLOCK) WHERE [ConsistancyCheck] is NULL
) AS t1
WHERE [Schedule].[ScheduleID] = t1.[ScheduleID]

select top 20
        S.[ScheduleID],
        S.[Name],
        S.[StartDate],
        S.[Flags],
        S.[NextRunTime],
        S.[LastRunTime],
        S.[EndDate],
        S.[RecurrenceType],
        S.[MinutesInterval],
        S.[DaysInterval],
        S.[WeeksInterval],
        S.[DaysOfWeek],
        S.[DaysOfMonth],
        S.[Month],
        S.[MonthlyWeek],
        S.[State], 
        S.[LastRunStatus],
        S.[ScheduledRunTimeout],
        S.[EventType],
        S.[EventData],
        S.[Type]
from
    [Schedule] S
where
    [ConsistancyCheck] = @date
GO
GRANT EXECUTE ON [dbo].[ListTasksForMaintenance] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ClearScheduleConsistancyFlags]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[ClearScheduleConsistancyFlags]
GO

CREATE PROCEDURE [dbo].[ClearScheduleConsistancyFlags]
AS
update [Schedule] with (tablock, xlock) set [ConsistancyCheck] = NULL
GO
GRANT EXECUTE ON [dbo].[ClearScheduleConsistancyFlags] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetAReportsReportAction]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetAReportsReportAction]
GO

CREATE PROCEDURE [dbo].[GetAReportsReportAction]
@ReportID uniqueidentifier,
@ReportAction int
AS
select 
        RS.[ReportAction],
        RS.[ScheduleID],
        RS.[ReportID],
        RS.[SubscriptionID],
        C.[Path]
from
    [ReportSchedule] RS Inner join [Catalog] C on RS.[ReportID] = C.[ItemID]
where
    C.ItemID = @ReportID and RS.[ReportAction] = @ReportAction
GO
GRANT EXECUTE ON [dbo].[GetAReportsReportAction] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetTimeBasedSubscriptionReportAction]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetTimeBasedSubscriptionReportAction]
GO

CREATE PROCEDURE [dbo].[GetTimeBasedSubscriptionReportAction]
@SubscriptionID uniqueidentifier
AS
select 
        RS.[ReportAction],
        RS.[ScheduleID],
        RS.[ReportID],
        RS.[SubscriptionID],
        C.[Path]
from
    [ReportSchedule] RS Inner join [Catalog] C on RS.[ReportID] = C.[ItemID]
where
    RS.[SubscriptionID] = @SubscriptionID
GO
GRANT EXECUTE ON [dbo].[GetTimeBasedSubscriptionReportAction] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetTaskProperties]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetTaskProperties]
GO

CREATE PROCEDURE [dbo].[GetTaskProperties]
@ScheduleID uniqueidentifier
AS
-- Grab all of a tasks properties given a task id
select 
        S.[ScheduleID],
        S.[Name],
        S.[StartDate], 
        S.[Flags],
        S.[NextRunTime],
        S.[LastRunTime], 
        S.[EndDate], 
        S.[RecurrenceType],
        S.[MinutesInterval],
        S.[DaysInterval],
        S.[WeeksInterval],
        S.[DaysOfWeek], 
        S.[DaysOfMonth], 
        S.[Month], 
        S.[MonthlyWeek], 
        S.[State], 
        S.[LastRunStatus],
        S.[ScheduledRunTimeout],
        S.[EventType],
        S.[EventData],
        S.[Type],
        SUSER_SNAME(Owner.[Sid]),
        Owner.[UserName]
from
    [Schedule] S with (XLOCK) 
    Inner join [Users] Owner on S.[CreatedById] = Owner.UserID
where
    S.[ScheduleID] = @ScheduleID
GO
GRANT EXECUTE ON [dbo].[GetTaskProperties] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DeleteTask]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[DeleteTask]
GO

CREATE PROCEDURE [dbo].[DeleteTask]
@ScheduleID uniqueidentifier
AS
-- Delete the task with the given task id
DELETE FROM Schedule
WHERE [ScheduleID] = @ScheduleID
GO
GRANT EXECUTE ON [dbo].[DeleteTask] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetSchedulesReports]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetSchedulesReports]
GO

CREATE PROCEDURE [dbo].[GetSchedulesReports] 
@ID uniqueidentifier
AS

select 
    C.Path
from
    ReportSchedule RS inner join Catalog C on (C.ItemID = RS.ReportID)
where
    ScheduleID = @ID
GO
GRANT EXECUTE ON [dbo].[GetSchedulesReports] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[AddReportSchedule]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[AddReportSchedule]
GO

CREATE PROCEDURE [dbo].[AddReportSchedule]
@ScheduleID uniqueidentifier,
@ReportID uniqueidentifier,
@SubscriptionID uniqueidentifier = NULL,
@Action int
AS

Insert into ReportSchedule ([ScheduleID], [ReportID], [SubscriptionID], [ReportAction]) values (@ScheduleID, @ReportID, @SubscriptionID, @Action)
GO
GRANT EXECUTE ON [dbo].[AddReportSchedule] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DeleteReportSchedule]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[DeleteReportSchedule]
GO

CREATE PROCEDURE [dbo].[DeleteReportSchedule]
@ScheduleID uniqueidentifier,
@ReportID uniqueidentifier,
@SubscriptionID uniqueidentifier = NULL,
@ReportAction int
AS

IF @SubscriptionID is NULL
BEGIN
delete from ReportSchedule where ScheduleID = @ScheduleID and ReportID = @ReportID and ReportAction = @ReportAction
END
ELSE
BEGIN
delete from ReportSchedule where ScheduleID = @ScheduleID and ReportID = @ReportID and ReportAction = @ReportAction and SubscriptionID = @SubscriptionID
END
GO
GRANT EXECUTE ON [dbo].[DeleteReportSchedule] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetSnapShotSchedule]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetSnapShotSchedule]
GO

CREATE PROCEDURE [dbo].[GetSnapShotSchedule] 
@ReportID uniqueidentifier
AS

select
    S.[ScheduleID],
    S.[Name],
    S.[StartDate], 
    S.[Flags],
    S.[NextRunTime],
    S.[LastRunTime], 
    S.[EndDate], 
    S.[RecurrenceType],
    S.[MinutesInterval],
    S.[DaysInterval],
    S.[WeeksInterval],
    S.[DaysOfWeek], 
    S.[DaysOfMonth], 
    S.[Month], 
    S.[MonthlyWeek], 
    S.[State], 
    S.[LastRunStatus],
    S.[ScheduledRunTimeout],
    S.[EventType],
    S.[EventData],
    S.[Type],
    SUSER_SNAME(Owner.[Sid]),
    Owner.[UserName]
from
    Schedule S with (XLOCK) inner join ReportSchedule RS on S.ScheduleID = RS.ScheduleID
    inner join [Users] Owner on S.[CreatedById] = Owner.[UserID]
where
    RS.ReportAction = 2 and -- 2 == create snapshot
    RS.ReportID = @ReportID
GO
GRANT EXECUTE ON [dbo].[GetSnapShotSchedule] TO RSExecRole
GO

--------------------------------------------------
------------- Time based subscriptions

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CreateTimeBasedSubscriptionSchedule]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CreateTimeBasedSubscriptionSchedule]
GO

CREATE PROCEDURE [dbo].[CreateTimeBasedSubscriptionSchedule]
@SubscriptionID as uniqueidentifier,
@ScheduleID uniqueidentifier,
@Schedule_Name nvarchar (260),
@Report_Name nvarchar (425),
@StartDate datetime,
@Flags int,
@NextRunTime datetime = NULL,
@LastRunTime datetime = NULL,
@EndDate datetime = NULL,
@RecurrenceType int = NULL,
@MinutesInterval int = NULL,
@DaysInterval int = NULL,
@WeeksInterval int = NULL,
@DaysOfWeek int = NULL,
@DaysOfMonth int = NULL,
@Month int = NULL,
@MonthlyWeek int = NULL,
@State int = NULL,
@LastRunStatus nvarchar (260) = NULL,
@ScheduledRunTimeout int = NULL,
@UserSid varbinary (85) = NULL,
@UserName nvarchar(260),
@AuthType int,
@EventType nvarchar (260),
@EventData nvarchar (260)
AS

EXEC CreateTask @ScheduleID, @Schedule_Name, @StartDate, @Flags, @NextRunTime, @LastRunTime, 
        @EndDate, @RecurrenceType, @MinutesInterval, @DaysInterval, @WeeksInterval, @DaysOfWeek, 
        @DaysOfMonth, @Month, @MonthlyWeek, @State, @LastRunStatus, 
        @ScheduledRunTimeout, @UserSid, @UserName, @AuthType, @EventType, @EventData, 1 -- scoped type

-- add a row to the reportSchedule table
declare @Report_OID uniqueidentifier
select @Report_OID = (select [ItemID] from [Catalog] with (HOLDLOCK) where [Catalog].[Path] = @Report_Name and ([Catalog].[Type] = 2 or [Catalog].[Type] = 4))
EXEC AddReportSchedule @ScheduleID, @Report_OID, @SubscriptionID, 4 -- TimedSubscription action

GO
GRANT EXECUTE ON [dbo].[CreateTimeBasedSubscriptionSchedule] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetTimeBasedSubscriptionSchedule]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetTimeBasedSubscriptionSchedule]
GO

CREATE PROCEDURE [dbo].[GetTimeBasedSubscriptionSchedule]
@SubscriptionID as uniqueidentifier
AS

select
    S.[ScheduleID],
    S.[Name],
    S.[StartDate], 
    S.[Flags],
    S.[NextRunTime],
    S.[LastRunTime], 
    S.[EndDate], 
    S.[RecurrenceType],
    S.[MinutesInterval], 
    S.[DaysInterval],
    S.[WeeksInterval],
    S.[DaysOfWeek], 
    S.[DaysOfMonth], 
    S.[Month], 
    S.[MonthlyWeek], 
    S.[State], 
    S.[LastRunStatus],
    S.[ScheduledRunTimeout],
    S.[EventType],
    S.[EventData],
    S.[Type],
    SUSER_SNAME(Owner.[Sid]),
    Owner.[UserName]
from
    [ReportSchedule] R inner join Schedule S with (XLOCK) on R.[ScheduleID] = S.[ScheduleID]
    Inner join [Users] Owner on S.[CreatedById] = Owner.UserID
where
    R.[SubscriptionID] = @SubscriptionID
GO
GRANT EXECUTE ON [dbo].[GetTimeBasedSubscriptionSchedule] TO RSExecRole
GO

--------------------------------------------------
------------- Running Jobs

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[AddRunningJob]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[AddRunningJob]
GO

CREATE PROCEDURE [dbo].[AddRunningJob]
@JobID as nvarchar(32),
@StartDate as datetime,
@ComputerName as nvarchar(32),
@RequestName as nvarchar(425),
@RequestPath as nvarchar(425),
@UserSid varbinary(85) = NULL,
@UserName nvarchar(260),
@AuthType int,
@Description as ntext  = NULL,
@Timeout as int,
@JobAction as smallint,
@JobType as smallint,
@JobStatus as smallint
AS

DECLARE @UserID uniqueidentifier
EXEC GetUserID @UserSid, @UserName, @AuthType, @UserID OUTPUT

INSERT INTO RunningJobs (JobID, StartDate, ComputerName, RequestName, RequestPath, UserID, Description, Timeout, JobAction, JobType, JobStatus )
VALUES             (@JobID, @StartDate, @ComputerName,  @RequestName, @RequestPath, @UserID, @Description, @Timeout, @JobAction, @JobType, @JobStatus)
GO

GRANT EXECUTE ON [dbo].[AddRunningJob] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[RemoveRunningJob]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[RemoveRunningJob]
GO

CREATE PROCEDURE [dbo].[RemoveRunningJob]
@JobID as nvarchar(32)
AS
DELETE FROM RunningJobs WHERE JobID = @JobID
GO

GRANT EXECUTE ON [dbo].[RemoveRunningJob] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[UpdateRunningJob]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[UpdateRunningJob]
GO

CREATE PROCEDURE [dbo].[UpdateRunningJob]
@JobID as nvarchar(32),
@JobStatus as smallint
AS
UPDATE RunningJobs SET JobStatus = @JobStatus WHERE JobID = @JobID
GO

GRANT EXECUTE ON [dbo].[UpdateRunningJob] TO RSExecRole
GO


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetMyRunningJobs]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetMyRunningJobs]
GO

CREATE PROCEDURE [dbo].[GetMyRunningJobs]
@ComputerName as nvarchar(32),
@JobType as smallint
AS
SELECT JobID, StartDate, ComputerName, RequestName, RequestPath, SUSER_SNAME(Users.[Sid]), Users.[UserName], Description, 
    Timeout, JobAction, JobType, JobStatus
FROM RunningJobs INNER JOIN Users 
ON RunningJobs.UserID = Users.UserID
WHERE ComputerName = @ComputerName
AND JobType = @JobType
GO

GRANT EXECUTE ON [dbo].[GetMyRunningJobs] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ListRunningJobs]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[ListRunningJobs]
GO

CREATE PROCEDURE [dbo].[ListRunningJobs]
AS
SELECT JobID, StartDate, ComputerName, RequestName, RequestPath, SUSER_SNAME(Users.[Sid]), Users.[UserName], Description, 
    Timeout, JobAction, JobType, JobStatus
FROM RunningJobs 
INNER JOIN Users 
ON RunningJobs.UserID = Users.UserID
GO

GRANT EXECUTE ON [dbo].[ListRunningJobs] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CleanExpiredJobs]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CleanExpiredJobs]
GO

CREATE PROCEDURE [dbo].[CleanExpiredJobs]
AS
DELETE FROM RunningJobs WHERE DATEADD(s, Timeout, StartDate) < GETDATE()
GO

GRANT EXECUTE ON [dbo].[CleanExpiredJobs] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CreateObject]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CreateObject]
GO

-- This SP should never be called with a policy ID unless it is guarenteed that
-- the parent will not be deleted before the insert (such as while running this script)
CREATE PROCEDURE [dbo].[CreateObject]
@ItemID uniqueidentifier,
@Name nvarchar (425),
@Path nvarchar (425),
@ParentID uniqueidentifier,
@Type int,
@Content image = NULL,
@Intermediate uniqueidentifier = NULL,
@LinkSourceID uniqueidentifier = NULL,
@Property ntext = NULL,
@Parameter ntext = NULL,
@Description ntext = NULL,
@Hidden bit = NULL,
@CreatedBySid varbinary(85) = NULL,
@CreatedByName nvarchar(260),
@AuthType int,
@CreationDate datetime,
@MimeType nvarchar (260) = NULL,
@SnapshotLimit int = NULL,
@PolicyRoot int = 0,
@PolicyID uniqueidentifier = NULL,
@ExecutionFlag int = 1 -- allow live execution, don't keep history
AS

DECLARE @CreatedByID uniqueidentifier
EXEC GetUserID @CreatedBySid, @CreatedByName, @AuthType, @CreatedByID OUTPUT

UPDATE Catalog with (XLOCK)
SET ModifiedByID = @CreatedByID, ModifiedDate = @CreationDate
WHERE ItemID = @ParentID

-- If no policyID, use the parent's
IF @PolicyID is NULL BEGIN
   SET @PolicyID = (SELECT PolicyID FROM [dbo].[Catalog] WHERE Catalog.ItemID = @ParentID)
END

-- If there is no policy ID then we are guarenteed not to have a parent
IF @PolicyID is NULL BEGIN
RAISERROR ('Parent Not Found', 16, 1)
return
END

INSERT INTO Catalog (ItemID,  Path,  Name,  ParentID,  Type,  Content,  Intermediate,  LinkSourceID,  Property,  Description,  Hidden,  CreatedByID,  CreationDate,  ModifiedByID,  ModifiedDate,  MimeType,  SnapshotLimit,  [Parameter],  PolicyID,  PolicyRoot, ExecutionFlag )
VALUES             (@ItemID, @Path, @Name, @ParentID, @Type, @Content, @Intermediate, @LinkSourceID, @Property, @Description, @Hidden, @CreatedByID, @CreationDate, @CreatedByID,  @CreationDate, @MimeType, @SnapshotLimit, @Parameter, @PolicyID, @PolicyRoot , @ExecutionFlag)

IF @Intermediate IS NOT NULL AND @@ERROR = 0 BEGIN
   UPDATE SnapshotData
   SET PermanentRefcount = PermanentRefcount + 1, TransientRefcount = TransientRefcount - 1
   WHERE SnapshotData.SnapshotDataID = @Intermediate
END

GO
GRANT EXECUTE ON [dbo].[CreateObject] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DeleteObject]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[DeleteObject]
GO

CREATE PROCEDURE [dbo].[DeleteObject]
@Path nvarchar (425),
@Prefix nvarchar (850)
AS

-- Remove reference for intermediate formats
UPDATE SnapshotData
SET PermanentRefcount = PermanentRefcount - 1
FROM
   Catalog AS R WITH (XLOCK)
   INNER JOIN [SnapshotData] AS SD ON R.Intermediate = SD.SnapshotDataID
WHERE
   (R.Path = @Path OR R.Path LIKE @Prefix ESCAPE '*')

-- Remove reference for execution snapshots
UPDATE SnapshotData
SET PermanentRefcount = PermanentRefcount - 1
FROM
   Catalog AS R WITH (XLOCK)
   INNER JOIN [SnapshotData] AS SD ON R.SnapshotDataID = SD.SnapshotDataID
WHERE
   (R.Path = @Path OR R.Path LIKE @Prefix ESCAPE '*')

-- Remove history for deleted reports and linked report
DELETE History
FROM
   [Catalog] AS R
   INNER JOIN [History] AS S ON R.ItemID = S.ReportID
WHERE
   (R.Path = @Path OR R.Path LIKE @Prefix ESCAPE '*')
   
-- Remove model drill reports
DELETE ModelDrill
FROM
   [Catalog] AS C
   INNER JOIN [ModelDrill] AS M ON C.ItemID = M.ReportID
WHERE
   (C.Path = @Path OR C.Path LIKE @Prefix ESCAPE '*')
      

-- Adjust data sources
UPDATE [DataSource]
   SET
      [Flags] = [Flags] & 0x7FFFFFFD, -- broken link
      [Link] = NULL
FROM
   [Catalog] AS C
   INNER JOIN [DataSource] AS DS ON C.[ItemID] = DS.[Link]
WHERE
   (C.Path = @Path OR C.Path LIKE @Prefix ESCAPE '*')

-- Clean all data sources
DELETE [DataSource]
FROM
    [Catalog] AS R
    INNER JOIN [DataSource] AS DS ON R.[ItemID] = DS.[ItemID]
WHERE    
    (R.Path = @Path OR R.Path LIKE @Prefix ESCAPE '*')

-- Update linked reports
UPDATE LR
   SET
      LR.LinkSourceID = NULL
FROM
   [Catalog] AS R INNER JOIN [Catalog] AS LR ON R.ItemID = LR.LinkSourceID
WHERE
   (R.Path = @Path OR R.Path LIKE @Prefix ESCAPE '*')
   AND
   (LR.Path NOT LIKE @Prefix ESCAPE '*')

-- Remove references for cache entries
UPDATE SN
SET
   PermanentRefcount = PermanentRefcount - 1
FROM
   [ReportServerTempDB].dbo.SnapshotData AS SN
   INNER JOIN [ReportServerTempDB].dbo.ExecutionCache AS EC on SN.SnapshotDataID = EC.SnapshotDataID
   INNER JOIN Catalog AS C ON EC.ReportID = C.ItemID
WHERE
   (Path = @Path OR Path LIKE @Prefix ESCAPE '*')
   
-- Clean cache entries for items to be deleted   
DELETE EC
FROM
   [ReportServerTempDB].dbo.ExecutionCache AS EC
   INNER JOIN Catalog AS C ON EC.ReportID = C.ItemID
WHERE
   (Path = @Path OR Path LIKE @Prefix ESCAPE '*')

-- Finally delete items
DELETE
FROM
   [Catalog]
WHERE
   (Path = @Path OR Path LIKE @Prefix ESCAPE '*')

EXEC CleanOrphanedPolicies
GO
GRANT EXECUTE ON [dbo].[DeleteObject] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FindObjectsNonRecursive]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[FindObjectsNonRecursive]
GO

CREATE PROCEDURE [dbo].[FindObjectsNonRecursive]
@Path nvarchar (425),
@AuthType int
AS
SELECT 
    C.Type,
    C.PolicyID,
    SD.NtSecDescPrimary,
    C.Name, 
    C.Path, 
    C.ItemID,
    DATALENGTH( C.Content ) AS [Size],
    C.Description,
    C.CreationDate, 
    C.ModifiedDate,
    SUSER_SNAME(CU.Sid), 
    CU.[UserName],
    SUSER_SNAME(MU.Sid),
    MU.[UserName],
    C.MimeType,
    C.ExecutionTime,
    C.Hidden
FROM
   Catalog AS C 
   INNER JOIN Catalog AS P ON C.ParentID = P.ItemID
   INNER JOIN Users AS CU ON C.CreatedByID = CU.UserID
   INNER JOIN Users AS MU ON C.ModifiedByID = MU.UserID
   LEFT OUTER JOIN SecData SD ON C.PolicyID = SD.PolicyID AND SD.AuthType = @AuthType
WHERE P.Path = @Path
GO
GRANT EXECUTE ON [dbo].[FindObjectsNonRecursive] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FindObjectsRecursive]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[FindObjectsRecursive]
GO

CREATE PROCEDURE [dbo].[FindObjectsRecursive]
@Prefix nvarchar (850),
@AuthType int
AS
SELECT 
    C.Type,
    C.PolicyID,
    SD.NtSecDescPrimary,
    C.Name,
    C.Path,
    C.ItemID,
    DATALENGTH( C.Content ) AS [Size],
    C.Description,
    C.CreationDate,
    C.ModifiedDate,
    SUSER_SNAME(CU.Sid),
    CU.UserName,
    SUSER_SNAME(MU.Sid),
    MU.UserName,
    C.MimeType,
    C.ExecutionTime,
    C.Hidden
from
   Catalog AS C
   INNER JOIN Users AS CU ON C.CreatedByID = CU.UserID
   INNER JOIN Users AS MU ON C.ModifiedByID = MU.UserID
   LEFT OUTER JOIN SecData AS SD ON C.PolicyID = SD.PolicyID AND SD.AuthType = @AuthType
WHERE C.Path LIKE @Prefix ESCAPE '*'
GO
GRANT EXECUTE ON [dbo].[FindObjectsRecursive] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FindObjectsByLink]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[FindObjectsByLink]
GO

CREATE PROCEDURE [dbo].[FindObjectsByLink]
@Link uniqueidentifier,
@AuthType int
AS
SELECT 
    C.Type, 
    C.PolicyID,
    SD.NtSecDescPrimary,
    C.Name, 
    C.Path, 
    C.ItemID, 
    DATALENGTH( C.Content ) AS [Size], 
    C.Description,
    C.CreationDate, 
    C.ModifiedDate, 
    SUSER_SNAME(CU.Sid),
    CU.UserName,
    SUSER_SNAME(MU.Sid),
    MU.UserName,
    C.MimeType,
    C.ExecutionTime,
    C.Hidden
FROM
   Catalog AS C
   INNER JOIN Users AS CU ON C.CreatedByID = CU.UserID
   INNER JOIN Users AS MU ON C.ModifiedByID = MU.UserID
   LEFT OUTER JOIN SecData AS SD ON C.PolicyID = SD.PolicyID AND SD.AuthType = @AuthType
WHERE C.LinkSourceID = @Link
GO
GRANT EXECUTE ON [dbo].[FindObjectsByLink] TO RSExecRole
GO

--------------------------------------------------
------------- Procedures used to update linked reports

if exists (select * from sysobjects where id = object_id('[dbo].[GetIDPairsByLink]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetIDPairsByLink]
GO

CREATE PROCEDURE [dbo].[GetIDPairsByLink]
@Link uniqueidentifier
AS
SELECT LinkSourceID, ItemID
FROM Catalog
WHERE LinkSourceID = @Link
GO
GRANT EXECUTE ON [dbo].[GetIDPairsByLink] TO RSExecRole
GO

if exists (select * from sysobjects where id = object_id('[dbo].[GetChildrenBeforeDelete]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetChildrenBeforeDelete]
GO

CREATE PROCEDURE [dbo].[GetChildrenBeforeDelete]
@Prefix nvarchar (850),
@AuthType int
AS
SELECT C.PolicyID, C.Type, SD.NtSecDescPrimary
FROM
   Catalog AS C LEFT OUTER JOIN SecData AS SD ON C.PolicyID = SD.PolicyID AND SD.AuthType = @AuthType
WHERE
   C.Path LIKE @Prefix ESCAPE '*'  -- return children only, not item itself
GO
GRANT EXECUTE ON [dbo].[GetChildrenBeforeDelete] TO RSExecRole
GO


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetAllProperties]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetAllProperties]
GO

CREATE PROCEDURE [dbo].[GetAllProperties]
@Path nvarchar (425),
@AuthType int
AS
select
   Property,
   Description,
   Type,
   DATALENGTH( Content ),
   ItemID, 
   SUSER_SNAME(C.Sid),
   C.UserName,
   CreationDate,
   SUSER_SNAME(M.Sid),
   M.UserName,
   ModifiedDate,
   MimeType,
   ExecutionTime,
   NtSecDescPrimary,
   [LinkSourceID],
   Hidden,
   ExecutionFlag,
   SnapshotLimit
FROM Catalog
   INNER JOIN Users C ON Catalog.CreatedByID = C.UserID
   INNER JOIN Users M ON Catalog.ModifiedByID = M.UserID
   LEFT OUTER JOIN SecData ON Catalog.PolicyID = SecData.PolicyID AND SecData.AuthType = @AuthType
WHERE Path = @Path
GO
GRANT EXECUTE ON [dbo].[GetAllProperties] TO RSExecRole
GO


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetParameters]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetParameters]
GO

CREATE PROCEDURE [dbo].[GetParameters]
@Path nvarchar (425),
@AuthType int
AS
SELECT
   Type,
   [Parameter],
   ItemID,
   SecData.NtSecDescPrimary,
   [LinkSourceID],
   [ExecutionFlag]
FROM Catalog 
LEFT OUTER JOIN SecData ON Catalog.PolicyID = SecData.PolicyID AND SecData.AuthType = @AuthType
WHERE Path = @Path
GO
GRANT EXECUTE ON [dbo].[GetParameters] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetObjectContent]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetObjectContent]
GO

CREATE PROCEDURE [dbo].[GetObjectContent]
@Path nvarchar (425),
@AuthType int
AS
SELECT Type, Content, LinkSourceID, MimeType, SecData.NtSecDescPrimary, ItemID
FROM Catalog
LEFT OUTER JOIN SecData ON Catalog.PolicyID = SecData.PolicyID AND SecData.AuthType = @AuthType
WHERE Path = @Path
GO
GRANT EXECUTE ON [dbo].[GetObjectContent] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetCompiledDefinition]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetCompiledDefinition]
GO

-- used to create snapshots
CREATE PROCEDURE [dbo].[GetCompiledDefinition]
@Path nvarchar (425),
@AuthType int
AS
    SELECT
       MainItem.Type,
       MainItem.Intermediate,
       MainItem.LinkSourceID,
       MainItem.Property,
       MainItem.Description,
       SecData.NtSecDescPrimary,
       MainItem.ItemID,         
       MainItem.ExecutionFlag,  
       LinkTarget.Intermediate,
       LinkTarget.Property,
       LinkTarget.Description,
       MainItem.[SnapshotDataID]
    FROM Catalog MainItem
    LEFT OUTER JOIN SecData ON MainItem.PolicyID = SecData.PolicyID AND SecData.AuthType = @AuthType
    LEFT OUTER JOIN Catalog LinkTarget with (INDEX = PK_CATALOG) on MainItem.LinkSourceID = LinkTarget.ItemID
    WHERE MainItem.Path = @Path
GO
GRANT EXECUTE ON [dbo].[GetCompiledDefinition] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetReportForExecution]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetReportForExecution]
GO

-- gets either the intermediate format or snapshot from cache
CREATE PROCEDURE [dbo].[GetReportForExecution]
@Path nvarchar (425),
@ParamsHash int,
@AuthType int
AS

DECLARE @now AS datetime
SET @now = GETDATE()

IF ( NOT EXISTS (
    SELECT *
        FROM
            Catalog AS C
            INNER JOIN [ReportServerTempDB].dbo.ExecutionCache AS EC ON C.ItemID = EC.ReportID
            INNER JOIN [ReportServerTempDB].dbo.SnapshotData AS SN ON EC.SnapshotDataID = SN.SnapshotDataID
        WHERE
            C.Path = @Path AND
            EC.AbsoluteExpiration > @now AND
            SN.ParamsHash = @ParamsHash
   ) ) 
BEGIN   -- no cache
    SELECT
        Cat.Type,
        Cat.LinkSourceID,
        Cat2.Path,
        Cat.Property,
        Cat.Description,
        SecData.NtSecDescPrimary,
        Cat.ItemID,
        CAST (0 AS BIT), -- not found,
        Cat.Intermediate,
        Cat.ExecutionFlag,
        SD.SnapshotDataID,
        SD.DependsOnUser,
        Cat.ExecutionTime,
        (SELECT Schedule.NextRunTime
         FROM
             Schedule WITH (XLOCK)
             INNER JOIN ReportSchedule ON Schedule.ScheduleID = ReportSchedule.ScheduleID 
         WHERE ReportSchedule.ReportID = Cat.ItemID AND ReportSchedule.ReportAction = 1), -- update snapshot
        (SELECT Schedule.ScheduleID
         FROM
             Schedule
             INNER JOIN ReportSchedule ON Schedule.ScheduleID = ReportSchedule.ScheduleID 
         WHERE ReportSchedule.ReportID = Cat.ItemID AND ReportSchedule.ReportAction = 1), -- update snapshot
        (SELECT CachePolicy.ExpirationFlags FROM CachePolicy WHERE CachePolicy.ReportID = Cat.ItemID),
        Cat2.Intermediate
    FROM
        Catalog AS Cat
        LEFT OUTER JOIN SecData ON Cat.PolicyID = SecData.PolicyID AND SecData.AuthType = @AuthType
        LEFT OUTER JOIN Catalog AS Cat2 on Cat.LinkSourceID = Cat2.ItemID
        LEFT OUTER JOIN SnapshotData AS SD ON Cat.SnapshotDataID = SD.SnapshotDataID
    WHERE Cat.Path = @Path
END
ELSE
BEGIN   -- use cache
    SELECT TOP 1
        Cat.Type,
        Cat.LinkSourceID,
        Cat2.Path,
        Cat.Property,
        Cat.Description,
        SecData.NtSecDescPrimary,
        Cat.ItemID,
        CAST (1 AS BIT), -- found,
        SN.SnapshotDataID,
        SN.DependsOnUser,
        SN.EffectiveParams,
        SN.CreatedDate,
        EC.AbsoluteExpiration,
        (SELECT CachePolicy.ExpirationFlags FROM CachePolicy WHERE CachePolicy.ReportID = Cat.ItemID),
        (SELECT Schedule.ScheduleID
         FROM
             Schedule WITH (XLOCK)
             INNER JOIN ReportSchedule ON Schedule.ScheduleID = ReportSchedule.ScheduleID 
             WHERE ReportSchedule.ReportID = Cat.ItemID AND ReportSchedule.ReportAction = 1), -- update snapshot
        SN.QueryParams     
    FROM
        Catalog AS Cat
        INNER JOIN [ReportServerTempDB].dbo.ExecutionCache AS EC ON Cat.ItemID = EC.ReportID
        INNER JOIN [ReportServerTempDB].dbo.SnapshotData AS SN ON EC.SnapshotDataID = SN.SnapshotDataID
        LEFT OUTER JOIN SecData ON Cat.PolicyID = SecData.PolicyID AND SecData.AuthType = @AuthType
        LEFT OUTER JOIN Catalog AS Cat2 on Cat.LinkSourceID = Cat2.ItemID
    WHERE
        Cat.Path = @Path 
        AND AbsoluteExpiration > @now 
        AND SN.ParamsHash = @ParamsHash
    ORDER BY SN.CreatedDate DESC
END

GO
GRANT EXECUTE ON [dbo].[GetReportForExecution] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetReportParametersForExecution]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetReportParametersForExecution]
GO

-- gets either the intermediate format or snapshot from cache
CREATE PROCEDURE [dbo].[GetReportParametersForExecution]
@Path nvarchar (425),
@HistoryID DateTime = NULL,
@AuthType int
AS
SELECT
   C.[ItemID],
   C.[Type],
   C.[ExecutionFlag],
   [SecData].[NtSecDescPrimary],
   C.[Parameter],
   C.[Intermediate],
   C.[SnapshotDataID],
   [History].[SnapshotDataID],
   L.[Intermediate],
   C.[LinkSourceID],
   C.[ExecutionTime]
FROM
   [Catalog] AS C
   LEFT OUTER JOIN [SecData] ON C.[PolicyID] = [SecData].[PolicyID] AND [SecData].AuthType = @AuthType
   LEFT OUTER JOIN [History] ON ( C.[ItemID] = [History].[ReportID] AND [History].[SnapshotDate] = @HistoryID )
   LEFT OUTER JOIN [Catalog] AS L ON C.[LinkSourceID] = L.[ItemID]
WHERE
   C.[Path] = @Path
GO

GRANT EXECUTE ON [dbo].[GetReportParametersForExecution] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[MoveObject]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[MoveObject]
GO

CREATE PROCEDURE [dbo].[MoveObject]
@OldPath nvarchar (425),
@OldPrefix nvarchar (850),
@NewName nvarchar (425),
@NewPath nvarchar (425),
@NewParentID uniqueidentifier,
@RenameOnly as bit,
@MaxPathLength as int
AS

DECLARE @LongPath nvarchar(425)
SET @LongPath =
  (SELECT TOP 1 Path
   FROM Catalog
   WHERE
      LEN(Path)-LEN(@OldPath)+LEN(@NewPath) > @MaxPathLength AND
      Path LIKE @OldPrefix ESCAPE '*')
   
IF @LongPath IS NOT NULL BEGIN
   SELECT @LongPath
   RETURN
END

IF @RenameOnly = 0 -- if this a full-blown move, not just a rename
BEGIN
    -- adjust policies on the top item that gets moved
    DECLARE @OldInheritedPolicyID as uniqueidentifier
    SELECT @OldInheritedPolicyID = (SELECT PolicyID FROM Catalog with (XLOCK) WHERE Path = @OldPath AND PolicyRoot = 0)
    IF (@OldInheritedPolicyID IS NOT NULL)
       BEGIN -- this was not a policy root, change it to inherit from target folder
         DECLARE @NewPolicyID as uniqueidentifier
         SELECT @NewPolicyID = (SELECT PolicyID FROM Catalog with (XLOCK) WHERE ItemID = @NewParentID)
         -- update item and children that shared the old policy
         UPDATE Catalog SET PolicyID = @NewPolicyID WHERE Path = @OldPath 
         UPDATE Catalog SET PolicyID = @NewPolicyID 
            WHERE Path LIKE @OldPrefix ESCAPE '*' 
            AND Catalog.PolicyID = @OldInheritedPolicyID
     END
END

-- Update item that gets moved (Path, Name, and ParentId)
update Catalog
set Name = @NewName, Path = @NewPath, ParentID = @NewParentID
where Path = @OldPath
-- Update all its children (Path only, Names and ParentIds stay the same)
update Catalog
set Path = STUFF(Path, 1, LEN(@OldPath), @NewPath )
where Path like @OldPrefix escape '*'
GO
GRANT EXECUTE ON [dbo].[MoveObject] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ObjectExists]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[ObjectExists]
GO

CREATE PROCEDURE [dbo].[ObjectExists]
@Path nvarchar (425),
@AuthType int
AS
SELECT Type, ItemID, SnapshotLimit, NtSecDescPrimary, ExecutionFlag, Intermediate, [LinkSourceID]
FROM Catalog
LEFT OUTER JOIN SecData
ON Catalog.PolicyID = SecData.PolicyID AND SecData.AuthType = @AuthType
WHERE Path = @Path
GO
GRANT EXECUTE ON [dbo].[ObjectExists] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SetAllProperties]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SetAllProperties]
GO

CREATE PROCEDURE [dbo].[SetAllProperties]
@Path nvarchar (425),
@Property ntext,
@Description ntext = NULL,
@Hidden bit = NULL,
@ModifiedBySid varbinary (85) = NULL,
@ModifiedByName nvarchar(260),
@AuthType int,
@ModifiedDate DateTime
AS

DECLARE @ModifiedByID uniqueidentifier
EXEC GetUserID @ModifiedBySid, @ModifiedByName, @AuthType, @ModifiedByID OUTPUT

UPDATE Catalog
SET Property = @Property, Description = @Description, Hidden = @Hidden, ModifiedByID = @ModifiedByID, ModifiedDate = @ModifiedDate
WHERE Path = @Path
GO
GRANT EXECUTE ON [dbo].[SetAllProperties] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FlushReportFromCache]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[FlushReportFromCache]
GO

CREATE PROCEDURE [dbo].[FlushReportFromCache]
@Path as nvarchar(425)
AS

UPDATE SN
   SET SN.PermanentRefcount = SN.PermanentRefcount - 1
FROM
   [ReportServerTempDB].dbo.SnapshotData AS SN
   INNER JOIN [ReportServerTempDB].dbo.ExecutionCache AS EC ON SN.SnapshotDataID = EC.SnapshotDataID
   INNER JOIN Catalog AS C ON EC.ReportID = C.ItemID
WHERE C.Path = @Path

DELETE EC
FROM
   [ReportServerTempDB].dbo.ExecutionCache AS EC
   INNER JOIN Catalog ON EC.ReportID = Catalog.ItemID
WHERE Catalog.Path = @Path

GO
GRANT EXECUTE ON [dbo].[FlushReportFromCache] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SetParameters]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SetParameters]
GO

CREATE PROCEDURE [dbo].[SetParameters]
@Path nvarchar (425),
@Parameter ntext
AS
UPDATE Catalog
SET [Parameter] = @Parameter
WHERE Path = @Path
EXEC FlushReportFromCache @Path
GO
GRANT EXECUTE ON [dbo].[SetParameters] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SetObjectContent]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SetObjectContent]
GO

CREATE PROCEDURE [dbo].[SetObjectContent]
@Path nvarchar (425),
@Type int,
@Content image = NULL,
@Intermediate uniqueidentifier = NULL,
@Parameter ntext = NULL,
@LinkSourceID uniqueidentifier = NULL,
@MimeType nvarchar (260) = NULL
AS

DECLARE @OldIntermediate as uniqueidentifier
SET @OldIntermediate = (SELECT Intermediate FROM Catalog WITH (XLOCK) WHERE Path = @Path)

UPDATE SnapshotData
SET PermanentRefcount = PermanentRefcount - 1
WHERE SnapshotData.SnapshotDataID = @OldIntermediate

UPDATE Catalog
SET Type=@Type, Content = @Content, Intermediate = @Intermediate, [Parameter] = @Parameter, LinkSourceID = @LinkSourceID, MimeType = @MimeType
WHERE Path = @Path

UPDATE SnapshotData
SET PermanentRefcount = PermanentRefcount + 1, TransientRefcount = TransientRefcount - 1
WHERE SnapshotData.SnapshotDataID = @Intermediate

EXEC FlushReportFromCache @Path

GO
GRANT EXECUTE ON [dbo].[SetObjectContent] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SetLastModified]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SetLastModified]
GO

CREATE PROCEDURE [dbo].[SetLastModified]
@Path nvarchar (425),
@ModifiedBySid varbinary (85) = NULL,
@ModifiedByName nvarchar(260),
@AuthType int,
@ModifiedDate DateTime
AS
DECLARE @ModifiedByID uniqueidentifier
EXEC GetUserID @ModifiedBySid, @ModifiedByName, @AuthType, @ModifiedByID OUTPUT
UPDATE Catalog
SET ModifiedByID = @ModifiedByID, ModifiedDate = @ModifiedDate
WHERE Path = @Path
GO
GRANT EXECUTE ON [dbo].[SetLastModified] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetNameById]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetNameById]
GO

CREATE PROCEDURE [dbo].[GetNameById]
@ItemID uniqueidentifier
AS
SELECT Path
FROM Catalog
WHERE ItemID = @ItemID
GO
GRANT EXECUTE ON [dbo].[GetNameById] TO RSExecRole
GO

--------------------------------------------------
------------- Data source procedures to store user names and passwords

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[AddDataSource]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[AddDataSource]
GO

CREATE PROCEDURE [dbo].[AddDataSource]
@DSID [uniqueidentifier],
@ItemID [uniqueidentifier] = NULL, -- null for future suport dynamic delivery
@SubscriptionID [uniqueidentifier] = NULL,
@Name [nvarchar] (260) = NULL, -- only for scoped data sources, MUST be NULL for standalone!!!
@Extension [nvarchar] (260) = NULL,
@LinkID [uniqueidentifier] = NULL, -- link id is trusted, if it is provided - we use it
@LinkPath [nvarchar] (425) = NULL, -- if LinkId is not provided we try to look up LinkPath
@CredentialRetrieval [int],
@Prompt [ntext] = NULL,
@ConnectionString [image] = NULL,
@OriginalConnectionString [image] = NULL,
@OriginalConnectStringExpressionBased [bit] = NULL,
@UserName [image] = NULL,
@Password [image] = NULL,
@Flags [int],
@AuthType [int],
@Version [int]
AS

DECLARE @ActualLinkID uniqueidentifier
SET @ActualLinkID = NULL

IF (@LinkID is NULL) AND (@LinkPath is not NULL) BEGIN
   SELECT
      Type, ItemID, NtSecDescPrimary
   FROM
      Catalog LEFT OUTER JOIN SecData ON Catalog.PolicyID = SecData.PolicyID AND SecData.AuthType = @AuthType
   WHERE
      Path = @LinkPath
   SET @ActualLinkID = (SELECT ItemID FROM Catalog WHERE Path = @LinkPath)
END
ELSE BEGIN
   SET @ActualLinkID = @LinkID
END

INSERT
    INTO DataSource
        ([DSID], [ItemID], [SubscriptionID], [Name], [Extension], [Link],
        [CredentialRetrieval], [Prompt],
        [ConnectionString], [OriginalConnectionString], [OriginalConnectStringExpressionBased], 
        [UserName], [Password], [Flags], [Version])
    VALUES
        (@DSID, @ItemID, @SubscriptionID, @Name, @Extension, @ActualLinkID,
        @CredentialRetrieval, @Prompt,
        @ConnectionString, @OriginalConnectionString, @OriginalConnectStringExpressionBased,
        @UserName, @Password, @Flags, @Version)
   
GO
GRANT EXECUTE ON [dbo].[AddDataSource] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetDataSources]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetDataSources]
GO

CREATE  PROCEDURE [dbo].[GetDataSources]
@ItemID [uniqueidentifier],
@AuthType int
AS
SELECT -- select data sources and their links (if they exist)
    DS.[DSID],      -- 0
    DS.[ItemID],    -- 1
    DS.[Name],      -- 2
    DS.[Extension], -- 3
    DS.[Link],      -- 4
    DS.[CredentialRetrieval], -- 5
    DS.[Prompt],    -- 6
    DS.[ConnectionString], -- 7
    DS.[OriginalConnectionString], -- 8
    DS.[UserName],  -- 9
    DS.[Password],  -- 10
    DS.[Flags],     -- 11
    DSL.[DSID],     -- 12
    DSL.[ItemID],   -- 13
    DSL.[Name],     -- 14
    DSL.[Extension], -- 15
    DSL.[Link],     -- 16
    DSL.[CredentialRetrieval], -- 17
    DSL.[Prompt],   -- 18
    DSL.[ConnectionString], -- 19
    DSL.[UserName], -- 20
    DSL.[Password], -- 21
    DSL.[Flags],	-- 22
    C.Path,         -- 23
    SD.NtSecDescPrimary, -- 24
    DS.[OriginalConnectStringExpressionBased], -- 25
    DS.[Version], -- 26
    DSL.[Version], -- 27
    (SELECT 1 WHERE EXISTS (SELECT * from [ModelItemPolicy] AS MIP WHERE C.[ItemID] = MIP.[CatalogItemID])) -- 28
FROM
   [DataSource] AS DS LEFT OUTER JOIN
       ([DataSource] AS DSL
       INNER JOIN [Catalog] AS C ON DSL.[ItemID] = C.[ItemID]
       LEFT OUTER JOIN [SecData] AS SD ON C.[PolicyID] = SD.[PolicyID] AND SD.AuthType = @AuthType)
   ON DS.[Link] = DSL.[ItemID]
WHERE
   DS.[ItemID] = @ItemID or DS.[SubscriptionID] = @ItemID
GO
GRANT EXECUTE ON [dbo].[GetDataSources] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DeleteDataSources]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[DeleteDataSources]
GO

CREATE PROCEDURE [dbo].[DeleteDataSources]
@ItemID [uniqueidentifier]
AS

DELETE
FROM [DataSource]
WHERE [ItemID] = @ItemID or [SubscriptionID] = @ItemID 
GO
GRANT EXECUTE ON [dbo].[DeleteDataSources] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ChangeStateOfDataSource]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[ChangeStateOfDataSource]
GO

CREATE PROCEDURE [dbo].[ChangeStateOfDataSource]
@ItemID [uniqueidentifier],
@Enable bit
AS
IF @Enable != 0 BEGIN
   UPDATE [DataSource]
      SET
         [Flags] = [Flags] | 1
   WHERE [ItemID] = @ItemID
END
ELSE
BEGIN
   UPDATE [DataSource]
      SET
         [Flags] = [Flags] & 0x7FFFFFFE
   WHERE [ItemID] = @ItemID
END
GO

GRANT EXECUTE ON [dbo].[ChangeStateOfDataSource] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FindItemsByDataSource]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[FindItemsByDataSource]
GO

CREATE PROCEDURE [dbo].[FindItemsByDataSource]
@ItemID uniqueidentifier,
@AuthType int
AS
SELECT 
    C.Type,
    C.PolicyID,
    SD.NtSecDescPrimary,
    C.Name, 
    C.Path, 
    C.ItemID,
    DATALENGTH( C.Content ) AS [Size],
    C.Description,
    C.CreationDate, 
    C.ModifiedDate,
    SUSER_SNAME(CU.Sid), 
    CU.UserName,
    SUSER_SNAME(MU.Sid),
    MU.UserName,
    C.MimeType,
    C.ExecutionTime,
    C.Hidden
FROM
   Catalog AS C 
   INNER JOIN Users AS CU ON C.CreatedByID = CU.UserID
   INNER JOIN Users AS MU ON C.ModifiedByID = MU.UserID
   LEFT OUTER JOIN SecData AS SD ON C.PolicyID = SD.PolicyID AND SD.AuthType = @AuthType
   INNER JOIN DataSource AS DS ON C.ItemID = DS.ItemID
WHERE
   DS.Link = @ItemID
GO
GRANT EXECUTE ON [dbo].[FindItemsByDataSource] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CopyExecutionSnapshot]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CopyExecutionSnapshot]
GO

CREATE PROCEDURE [dbo].[CopyExecutionSnapshot]
@SourceReportID uniqueidentifier,
@TargetReportID uniqueidentifier,
@ReservedUntilUTC datetime
AS

DECLARE @SourceSnapshotDataID uniqueidentifier
SET @SourceSnapshotDataID = (SELECT SnapshotDataID FROM Catalog WHERE ItemID = @SourceReportID)
DECLARE @TargetSnapshotDataID uniqueidentifier
SET @TargetSnapshotDataID = newid()
DECLARE @ChunkID uniqueidentifier

IF @SourceSnapshotDataID IS NOT NULL BEGIN
   -- We need to copy entries in SnapshotData and ChunkData tables.
   INSERT INTO SnapshotData
      (SnapshotDataID, CreatedDate, ParamsHash, QueryParams, EffectiveParams, Description, PermanentRefcount, TransientRefcount, ExpirationDate)
   SELECT
      @TargetSnapshotDataID, SD.CreatedDate, SD.ParamsHash, SD.QueryParams, SD.EffectiveParams, SD.Description, 1, 0, @ReservedUntilUTC
   FROM
      SnapshotData as SD
   WHERE
      SD.SnapshotDataID = @SourceSnapshotDataID

   INSERT INTO ChunkData
      (ChunkID, SnapshotDataID, ChunkName, ChunkType, ChunkFlags, Content, Version)
   SELECT
      newid(), @TargetSnapshotDataID, CD.ChunkName, CD.ChunkType, CD.ChunkFlags, CD.Content, CD.Version
   FROM
      ChunkData as CD
   WHERE
      CD.SnapshotDataID = @SourceSnapshotDataID

   UPDATE Target
   SET
      Target.SnapshotDataID = @TargetSnapshotDataID,
      Target.ExecutionTime = Source.ExecutionTime
   FROM
      Catalog Target,
      Catalog Source
   WHERE
     Source.ItemID = @SourceReportID AND
      Target.ItemID = @TargetReportID
   END

GO
GRANT EXECUTE ON [dbo].[CopyExecutionSnapshot] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CreateRole]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CreateRole]
GO

CREATE PROCEDURE [dbo].[CreateRole]
@RoleID as uniqueidentifier,
@RoleName as nvarchar(260),
@Description as nvarchar(512) = null,
@TaskMask as nvarchar(32),
@RoleFlags as tinyint
AS
INSERT INTO Roles
(RoleID, RoleName, Description, TaskMask, RoleFlags)
VALUES
(@RoleID, @RoleName, @Description, @TaskMask, @RoleFlags)
GO
GRANT EXECUTE ON [dbo].[CreateRole] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetRoles]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetRoles]
GO

CREATE PROCEDURE [dbo].[GetRoles]
@RoleFlags as tinyint = NULL
AS
SELECT
    RoleName,
    Description,
    TaskMask
FROM
    Roles
WHERE
    (@RoleFlags is NULL) OR
    (RoleFlags = @RoleFlags)
GO
GRANT EXECUTE ON [dbo].[GetRoles] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DeleteRole]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[DeleteRole]
GO

-- Delete all policies associated with this role
CREATE PROCEDURE [dbo].[DeleteRole]
@RoleName nvarchar(260)
AS
-- if you call this, you must delete/reconstruct all policies associated with this role
DELETE FROM Roles WHERE RoleName = @RoleName
GO

GRANT EXECUTE ON [dbo].[DeleteRole] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ReadRoleProperties]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[ReadRoleProperties]
GO

CREATE PROCEDURE [dbo].[ReadRoleProperties]
@RoleName as nvarchar(260)
AS 
SELECT Description, TaskMask, RoleFlags FROM Roles WHERE RoleName = @RoleName
GO
GRANT EXECUTE ON [dbo].[ReadRoleProperties] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SetRoleProperties]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SetRoleProperties]
GO

CREATE PROCEDURE [dbo].[SetRoleProperties]
@RoleName as nvarchar(260),
@Description as nvarchar(512) = NULL,
@TaskMask as nvarchar(32),
@RoleFlags as tinyint
AS 
DECLARE @ExistingRoleFlags as tinyint
SET @ExistingRoleFlags = (SELECT RoleFlags FROM Roles WHERE RoleName = @RoleName)
IF @ExistingRoleFlags IS NULL
BEGIN
    RETURN
END
IF @ExistingRoleFlags <> @RoleFlags
BEGIN
    RAISERROR ('Bad role flags', 16, 1)
END
UPDATE Roles SET 
Description = @Description, 
TaskMask = @TaskMask,
RoleFlags = @RoleFlags
WHERE RoleName = @RoleName
GO
GRANT EXECUTE ON [dbo].[SetRoleProperties] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetPoliciesForRole]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetPoliciesForRole]
GO

CREATE PROCEDURE [dbo].[GetPoliciesForRole]
@RoleName as nvarchar(260),
@AuthType as int
AS 
SELECT
    Policies.PolicyID,
    SecData.XmlDescription, 
    Policies.PolicyFlag,
    Catalog.Type,
    Catalog.Path,
    ModelItemPolicy.CatalogItemID,
    ModelItemPolicy.ModelItemID,
    RelatedRoles.RoleID,
    RelatedRoles.RoleName,
    RelatedRoles.TaskMask,
    RelatedRoles.RoleFlags
FROM
    Roles
    INNER JOIN PolicyUserRole ON Roles.RoleID = PolicyUserRole.RoleID
    INNER JOIN Policies ON PolicyUserRole.PolicyID = Policies.PolicyID
    INNER JOIN PolicyUserRole AS RelatedPolicyUserRole ON Policies.PolicyID = RelatedPolicyUserRole.PolicyID
    INNER JOIN Roles AS RelatedRoles ON RelatedPolicyUserRole.RoleID = RelatedRoles.RoleID
    LEFT OUTER JOIN SecData ON Policies.PolicyID = SecData.PolicyID AND SecData.AuthType = @AuthType
    LEFT OUTER JOIN Catalog ON Policies.PolicyID = Catalog.PolicyID AND Catalog.PolicyRoot = 1
    LEFT OUTER JOIN ModelItemPolicy ON Policies.PolicyID = ModelItemPolicy.PolicyID
WHERE
    Roles.RoleName = @RoleName
ORDER BY
    Policies.PolicyID
GO
GRANT EXECUTE ON [dbo].[GetPoliciesForRole] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[UpdatePolicy]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[UpdatePolicy]
GO

CREATE PROCEDURE [dbo].[UpdatePolicy]
@PolicyID as uniqueidentifier,
@PrimarySecDesc as image,
@SecondarySecDesc as ntext = NULL,
@AuthType int
AS
UPDATE SecData SET NtSecDescPrimary = @PrimarySecDesc,
NtSecDescSecondary = @SecondarySecDesc 
WHERE SecData.PolicyID = @PolicyID
AND SecData.AuthType = @AuthType
GO
GRANT EXECUTE ON [dbo].[UpdatePolicy] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SetPolicy]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SetPolicy]
GO

-- this assumes the item exists in the catalog
CREATE PROCEDURE [dbo].[SetPolicy]
@ItemName as nvarchar(425),
@ItemNameLike as nvarchar(850),
@PrimarySecDesc as image,
@SecondarySecDesc as ntext = NULL,
@XmlPolicy as ntext,
@AuthType int,
@PolicyID uniqueidentifier OUTPUT
AS 
SELECT @PolicyID = (SELECT PolicyID FROM Catalog WHERE Path = @ItemName AND PolicyRoot = 1)
IF (@PolicyID IS NULL)
   BEGIN -- this is not a policy root
     SET @PolicyID = newid()
     INSERT INTO Policies (PolicyID, PolicyFlag)
     VALUES (@PolicyID, 0)
     INSERT INTO SecData (SecDataID, PolicyID, AuthType, XmlDescription, NTSecDescPrimary, NtSecDescSecondary)
     VALUES (newid(), @PolicyID, @AuthType, @XmlPolicy, @PrimarySecDesc, @SecondarySecDesc)
     DECLARE @OldPolicyID as uniqueidentifier
     SELECT @OldPolicyID = (SELECT PolicyID FROM Catalog WHERE Path = @ItemName)
     -- update item and children that shared the old policy
     UPDATE Catalog SET PolicyID = @PolicyID, PolicyRoot = 1 WHERE Path = @ItemName 
     UPDATE Catalog SET PolicyID = @PolicyID 
    WHERE Path LIKE @ItemNameLike ESCAPE '*' 
    AND Catalog.PolicyID = @OldPolicyID
   END
ELSE
   BEGIN
      UPDATE Policies SET 
      PolicyFlag = 0
      WHERE Policies.PolicyID = @PolicyID
      DECLARE @SecDataID as uniqueidentifier
      SELECT @SecDataID = (SELECT SecDataID FROM SecData WHERE PolicyID = @PolicyID and AuthType = @AuthType)
      IF (@SecDataID IS NULL)
      BEGIN -- insert new sec desc's
        INSERT INTO SecData (SecDataID, PolicyID, AuthType, XmlDescription ,NTSecDescPrimary, NtSecDescSecondary)
        VALUES (newid(), @PolicyID, @AuthType, @XmlPolicy, @PrimarySecDesc, @SecondarySecDesc)
      END
      ELSE
      BEGIN -- update existing sec desc's
        UPDATE SecData SET 
        XmlDescription = @XmlPolicy,
        NtSecDescPrimary = @PrimarySecDesc,
        NtSecDescSecondary = @SecondarySecDesc
        WHERE SecData.PolicyID = @PolicyID
        AND AuthType = @AuthType
      END
   END
DELETE FROM PolicyUserRole WHERE PolicyID = @PolicyID 
GO
GRANT EXECUTE ON [dbo].[SetPolicy] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SetSystemPolicy]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SetSystemPolicy]
GO

-- update the system policy
CREATE PROCEDURE [dbo].[SetSystemPolicy]
@PrimarySecDesc as image,
@SecondarySecDesc as ntext = NULL,
@XmlPolicy as ntext,
@AuthType as int,
@PolicyID uniqueidentifier OUTPUT
AS 
SELECT @PolicyID = (SELECT PolicyID FROM Policies WHERE PolicyFlag = 1)
IF (@PolicyID IS NULL)
   BEGIN
     SET @PolicyID = newid()
     INSERT INTO Policies (PolicyID, PolicyFlag)
     VALUES (@PolicyID, 1)
     INSERT INTO SecData (SecDataID, PolicyID, AuthType, XmlDescription, NTSecDescPrimary, NtSecDescSecondary)
     VALUES (newid(), @PolicyID, @AuthType, @XmlPolicy, @PrimarySecDesc, @SecondarySecDesc)
   END
ELSE
   BEGIN
      DECLARE @SecDataID as uniqueidentifier
      SELECT @SecDataID = (SELECT SecDataID FROM SecData WHERE PolicyID = @PolicyID and AuthType = @AuthType)
      IF (@SecDataID IS NULL)
      BEGIN -- insert new sec desc's
        INSERT INTO SecData (SecDataID, PolicyID, AuthType, XmlDescription, NTSecDescPrimary, NtSecDescSecondary)
        VALUES (newid(), @PolicyID, @AuthType, @XmlPolicy, @PrimarySecDesc, @SecondarySecDesc)
      END
      ELSE
      BEGIN -- update existing sec desc's
        UPDATE SecData SET 
        XmlDescription = @XmlPolicy,
        NtSecDescPrimary = @PrimarySecDesc,
        NtSecDescSecondary = @SecondarySecDesc
        WHERE SecData.PolicyID = @PolicyID
        AND AuthType = @AuthType

      END      
   END
DELETE FROM PolicyUserRole WHERE PolicyID = @PolicyID 
GO
GRANT EXECUTE ON [dbo].[SetSystemPolicy] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SetModelItemPolicy]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SetModelItemPolicy]
GO

-- update the system policy
CREATE PROCEDURE [dbo].[SetModelItemPolicy]
@CatalogItemID as uniqueidentifier,
@ModelItemID as nvarchar(425),
@PrimarySecDesc as image,
@SecondarySecDesc as ntext = NULL,
@XmlPolicy as ntext,
@AuthType as int,
@PolicyID uniqueidentifier OUTPUT
AS 
SELECT @PolicyID = (SELECT PolicyID FROM ModelItemPolicy WHERE CatalogItemID = @CatalogItemID AND ModelItemID = @ModelItemID )
IF (@PolicyID IS NULL)
   BEGIN
     SET @PolicyID = newid()
     INSERT INTO Policies (PolicyID, PolicyFlag)
     VALUES (@PolicyID, 2)
     INSERT INTO SecData (SecDataID, PolicyID, AuthType, XmlDescription, NTSecDescPrimary, NtSecDescSecondary)
     VALUES (newid(), @PolicyID, @AuthType, @XmlPolicy, @PrimarySecDesc, @SecondarySecDesc)
     INSERT INTO ModelItemPolicy (ID, CatalogItemID, ModelItemID, PolicyID)
     VALUES (newid(), @CatalogItemID, @ModelItemID, @PolicyID)
   END
ELSE
   BEGIN
      DECLARE @SecDataID as uniqueidentifier
      SELECT @SecDataID = (SELECT SecDataID FROM SecData WHERE PolicyID = @PolicyID and AuthType = @AuthType)
      IF (@SecDataID IS NULL)
      BEGIN -- insert new sec desc's
        INSERT INTO SecData (SecDataID, PolicyID, AuthType, XmlDescription, NTSecDescPrimary, NtSecDescSecondary)
        VALUES (newid(), @PolicyID, @AuthType, @XmlPolicy, @PrimarySecDesc, @SecondarySecDesc)
      END
      ELSE
      BEGIN -- update existing sec desc's
        UPDATE SecData SET 
        XmlDescription = @XmlPolicy,
        NtSecDescPrimary = @PrimarySecDesc,
        NtSecDescSecondary = @SecondarySecDesc
        WHERE SecData.PolicyID = @PolicyID
        AND AuthType = @AuthType

      END      
   END
DELETE FROM PolicyUserRole WHERE PolicyID = @PolicyID 
GO
GRANT EXECUTE ON [dbo].[SetModelItemPolicy] TO RSExecRole
GO


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[UpdatePolicyPrincipal]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[UpdatePolicyPrincipal]
GO

CREATE PROCEDURE [dbo].[UpdatePolicyPrincipal]
@PolicyID uniqueidentifier,
@PrincipalSid varbinary(85) = NULL,
@PrincipalName nvarchar(260),
@PrincipalAuthType int,
@RoleName nvarchar(260),
@PrincipalID uniqueidentifier OUTPUT,
@RoleID uniqueidentifier OUTPUT
AS 
EXEC GetPrincipalID @PrincipalSid , @PrincipalName, @PrincipalAuthType, @PrincipalID  OUTPUT
SELECT @RoleID = (SELECT RoleID FROM Roles WHERE RoleName = @RoleName)
INSERT INTO PolicyUserRole 
(ID, RoleID, UserID, PolicyID)
VALUES (newid(), @RoleID, @PrincipalID, @PolicyID)
GO
GRANT EXECUTE ON [dbo].[UpdatePolicyPrincipal] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[UpdatePolicyRole]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[UpdatePolicyRole]
GO

CREATE PROCEDURE [dbo].[UpdatePolicyRole]
@PolicyID uniqueidentifier,
@PrincipalID uniqueidentifier,
@RoleName nvarchar(260),
@RoleID uniqueidentifier OUTPUT
AS 
SELECT @RoleID = (SELECT RoleID FROM Roles WHERE RoleName = @RoleName)
INSERT INTO PolicyUserRole 
(ID, RoleID, UserID, PolicyID)
VALUES (newid(), @RoleID, @PrincipalID, @PolicyID)
GO
GRANT EXECUTE ON [dbo].[UpdatePolicyRole] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetPolicy]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetPolicy]
GO

CREATE PROCEDURE [dbo].[GetPolicy]
@ItemName as nvarchar(425),
@AuthType int
AS 
SELECT SecData.XmlDescription, Catalog.PolicyRoot , SecData.NtSecDescPrimary, Catalog.Type
FROM Catalog 
INNER JOIN Policies ON Catalog.PolicyID = Policies.PolicyID 
LEFT OUTER JOIN SecData ON Policies.PolicyID = SecData.PolicyID AND AuthType = @AuthType
WHERE Catalog.Path = @ItemName
AND PolicyFlag = 0
GO
GRANT EXECUTE ON [dbo].[GetPolicy] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetSystemPolicy]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetSystemPolicy]
GO

CREATE PROCEDURE [dbo].[GetSystemPolicy]
@AuthType int
AS 
SELECT SecData.NtSecDescPrimary, SecData.XmlDescription
FROM Policies 
LEFT OUTER JOIN SecData ON Policies.PolicyID = SecData.PolicyID AND AuthType = @AuthType
WHERE PolicyFlag = 1
GO
GRANT EXECUTE ON [dbo].[GetSystemPolicy] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DeletePolicy]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[DeletePolicy]
GO

CREATE PROCEDURE [dbo].[DeletePolicy]
@ItemName as nvarchar(425)
AS 
DECLARE @OldPolicyID uniqueidentifier
SELECT @OldPolicyID = (SELECT PolicyID FROM Catalog WHERE Catalog.Path = @ItemName)
UPDATE Catalog SET PolicyID = 
(SELECT Parent.PolicyID FROM Catalog Parent, Catalog WHERE Parent.ItemID = Catalog.ParentID AND Catalog.Path = @ItemName),
PolicyRoot = 0
WHERE Catalog.PolicyID = @OldPolicyID
DELETE Policies FROM Policies WHERE Policies.PolicyID = @OldPolicyID 
GO
GRANT EXECUTE ON [dbo].[DeletePolicy] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CreateSession]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CreateSession]
GO

-- Writes or updates session record
CREATE PROCEDURE [dbo].[CreateSession]
@SessionID as varchar(32),
@CompiledDefinition as uniqueidentifier = NULL,
@SnapshotDataID as uniqueidentifier = NULL,
@IsPermanentSnapshot as bit = NULL,
@ReportPath as nvarchar(440) = NULL,
@Timeout as int,
@AutoRefreshSeconds as int = NULL,
@DataSourceInfo as image = NULL,
@OwnerName as nvarchar (260),
@OwnerSid as varbinary (85) = NULL,
@AuthType as int,
@EffectiveParams as ntext = NULL,
@HistoryDate as datetime = NULL,
@PageHeight as float = NULL,
@PageWidth as float = NULL,
@TopMargin as float = NULL,
@BottomMargin as float = NULL,
@LeftMargin as float = NULL,
@RightMargin as float = NULL,
@ExecutionType as smallint = NULL
AS

UPDATE PS
SET PS.RefCount = 1
FROM
	[ReportServerTempDB].dbo.PersistedStream as PS
WHERE
	PS.SessionID = @SessionID	
	
UPDATE SN
SET TransientRefcount = TransientRefcount + 1
FROM
   SnapshotData AS SN
WHERE
   SN.SnapshotDataID = @SnapshotDataID
   
UPDATE SN
SET TransientRefcount = TransientRefcount + 1
FROM
   [ReportServerTempDB].dbo.SnapshotData AS SN
WHERE
   SN.SnapshotDataID = @SnapshotDataID

DECLARE @OwnerID uniqueidentifier
EXEC GetUserID @OwnerSid, @OwnerName, @AuthType, @OwnerID OUTPUT

DECLARE @now datetime
SET @now = GETDATE()

INSERT
   INTO [ReportServerTempDB].dbo.SessionData (
      SessionID,
      CompiledDefinition,
      SnapshotDataID,
      IsPermanentSnapshot,
      ReportPath,
      Timeout,
      AutoRefreshSeconds,
      Expiration,
      DataSourceInfo,
      OwnerID,
      EffectiveParams,
      CreationTime,
      HistoryDate,
      PageHeight,
      PageWidth,
      TopMargin,
      BottomMargin,
      LeftMargin,
      RightMargin,
      ExecutionType )
   VALUES (
      @SessionID,
      @CompiledDefinition,
      @SnapshotDataID,
      @IsPermanentSnapshot,
      @ReportPath,
      @Timeout,
      @AutoRefreshSeconds,
      DATEADD(s, @Timeout, @now),
      @DataSourceInfo,
      @OwnerID,
      @EffectiveParams,
      @now,
      @HistoryDate,
      @PageHeight,
      @PageWidth,
      @TopMargin,
      @BottomMargin,
      @LeftMargin,
      @RightMargin,
      @ExecutionType )
      
GO

GRANT EXECUTE ON [dbo].[CreateSession] TO RSExecRole
GO


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DeleteModelItemPolicy]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[DeleteModelItemPolicy]
GO

CREATE PROCEDURE [dbo].[DeleteModelItemPolicy]
@CatalogItemID as uniqueidentifier,
@ModelItemID as nvarchar(425)
AS 
DECLARE @PolicyID uniqueidentifier
SELECT @PolicyID = (SELECT PolicyID FROM ModelItemPolicy WHERE CatalogItemID = @CatalogItemID AND ModelItemID = @ModelItemID)
DELETE Policies FROM Policies WHERE Policies.PolicyID = @PolicyID
GO
GRANT EXECUTE ON [dbo].[DeleteModelItemPolicy] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DeleteAllModelItemPolicies]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[DeleteAllModelItemPolicies]
GO

CREATE PROCEDURE [dbo].[DeleteAllModelItemPolicies]
@Path as nvarchar(450)
AS 

DELETE Policies
FROM
   Policies AS P
   INNER JOIN ModelItemPolicy AS MIP ON P.PolicyID = MIP.PolicyID
   INNER JOIN Catalog AS C ON MIP.CatalogItemID = C.ItemID
WHERE
   C.[Path] = @Path

GO
GRANT EXECUTE ON [dbo].[DeleteAllModelItemPolicies] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetModelItemInfo]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetModelItemInfo]
GO

CREATE PROCEDURE [dbo].[GetModelItemInfo]
@Path nvarchar (425),
@AuthType int
AS

SELECT
    C.[ItemID], C.[Type], C.[ModifiedDate], C.[Description], SD.[NtSecDescPrimary]
FROM
    [Catalog] AS C
    LEFT OUTER JOIN [SecData] AS SD ON C.[PolicyID] = SD.[PolicyID] AND SD.[AuthType] = @AuthType
WHERE
    C.[Path] = @Path

SELECT
    MIP.[ModelItemID], SD.[NtSecDescPrimary], SD.[XmlDescription]
FROM
    [Catalog] AS C
    INNER JOIN [ModelItemPolicy] AS MIP ON C.[ItemID] = MIP.[CatalogItemID]
    LEFT OUTER JOIN [SecData] AS SD ON MIP.[PolicyID] = SD.[PolicyID]
WHERE
    C.[Path] = @Path
    
GO
GRANT EXECUTE ON [dbo].[GetModelItemInfo] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetModelDefinition]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetModelDefinition]
GO

CREATE PROCEDURE [dbo].[GetModelDefinition]
@CatalogItemID as uniqueidentifier
AS

SELECT
    C.[Content]
FROM
    [Catalog] AS C
WHERE
    C.[ItemID] = @CatalogItemID
    
GO
GRANT EXECUTE ON [dbo].[GetModelDefinition] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[AddModelPerspective]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[AddModelPerspective]
GO

CREATE PROCEDURE [dbo].[AddModelPerspective]
@ModelID as uniqueidentifier,
@PerspectiveID as ntext,
@PerspectiveName as ntext = null,
@PerspectiveDescription as ntext = null
AS

INSERT
INTO [ModelPerspective]
    ([ID], [ModelID], [PerspectiveID], [PerspectiveName], [PerspectiveDescription])
VALUES
    (newid(), @ModelID, @PerspectiveID, @PerspectiveName, @PerspectiveDescription)
GO
GRANT EXECUTE ON [dbo].[AddModelPerspective] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DeleteModelPerspectives]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[DeleteModelPerspectives]
GO

CREATE PROCEDURE [dbo].[DeleteModelPerspectives]
@ModelID as uniqueidentifier
AS

DELETE
FROM [ModelPerspective]
WHERE [ModelID] = @ModelID
GO
GRANT EXECUTE ON [dbo].[DeleteModelPerspectives] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetModelsAndPerspectives]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetModelsAndPerspectives]
GO

CREATE PROCEDURE [dbo].[GetModelsAndPerspectives]
@AuthType int
AS

SELECT
    C.[PolicyID],
    SD.[NtSecDescPrimary],
    C.[ItemID],
    C.[Path],
    C.[Description],
    P.[PerspectiveID],
    P.[PerspectiveName],
    P.[PerspectiveDescription]
FROM
    [Catalog] as C
    LEFT OUTER JOIN [ModelPerspective] as P ON C.[ItemID] = P.[ModelID]
    LEFT OUTER JOIN [SecData] AS SD ON C.[PolicyID] = SD.[PolicyID] AND SD.[AuthType] = @AuthType
WHERE
    C.[Type] = 6 -- Model
ORDER BY
    C.[Path]    

GO
GRANT EXECUTE ON [dbo].[GetModelsAndPerspectives] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetModelPerspectives]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetModelPerspectives]
GO

CREATE PROCEDURE [dbo].[GetModelPerspectives]
@Path nvarchar (425),
@AuthType int
AS

SELECT
    C.[Type],
    SD.[NtSecDescPrimary],
    C.[Description]
FROM
    [Catalog] as C
    LEFT OUTER JOIN [SecData] AS SD ON C.[PolicyID] = SD.[PolicyID] AND SD.[AuthType] = @AuthType
WHERE
    [Path] = @Path

SELECT
    P.[PerspectiveID],
    P.[PerspectiveName],
    P.[PerspectiveDescription]
FROM
    [Catalog] as C
    INNER JOIN [ModelPerspective] as P ON C.[ItemID] = P.[ModelID]
WHERE
    [Path] = @Path

GO
GRANT EXECUTE ON [dbo].[GetModelPerspectives] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DereferenceSessionSnapshot]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[DereferenceSessionSnapshot]
GO

CREATE PROCEDURE [dbo].[DereferenceSessionSnapshot]
@SessionID as varchar(32),
@OwnerID as uniqueidentifier
AS

UPDATE SN
SET TransientRefcount = TransientRefcount - 1
FROM
   SnapshotData AS SN
   INNER JOIN [ReportServerTempDB].dbo.SessionData AS SE ON SN.SnapshotDataID = SE.SnapshotDataID
WHERE
   SE.SessionID = @SessionID AND
   SE.OwnerID = @OwnerID
   
UPDATE SN
SET TransientRefcount = TransientRefcount - 1
FROM
   [ReportServerTempDB].dbo.SnapshotData AS SN
   INNER JOIN [ReportServerTempDB].dbo.SessionData AS SE ON SN.SnapshotDataID = SE.SnapshotDataID
WHERE
   SE.SessionID = @SessionID AND
   SE.OwnerID = @OwnerID
   
GO
GRANT EXECUTE ON [dbo].[DereferenceSessionSnapshot] TO RSExecRole
GO


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SetSessionData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SetSessionData]
GO

-- Writes or updates session record
CREATE PROCEDURE [dbo].[SetSessionData]
@SessionID as varchar(32),
@ReportPath as nvarchar(440),
@HistoryDate as datetime = NULL,
@Timeout as int,
@AutoRefreshSeconds as int = NULL,
@EffectiveParams ntext = NULL,
@OwnerSid as varbinary (85) = NULL,
@OwnerName as nvarchar (260),
@AuthType as int,
@ShowHideInfo as image = NULL,
@DataSourceInfo as image = NULL,
@SnapshotDataID as uniqueidentifier = NULL,
@IsPermanentSnapshot as bit = NULL,
@SnapshotTimeoutSeconds as int = NULL,
@HasInteractivity as bit,
@SnapshotExpirationDate as datetime = NULL,
@ExecutionType smallint  = NULL
AS

DECLARE @OwnerID uniqueidentifier
EXEC GetUserID @OwnerSid, @OwnerName, @AuthType, @OwnerID OUTPUT

DECLARE @now datetime
SET @now = GETDATE()

-- is there a session for the same report ?
DECLARE @OldSnapshotDataID uniqueidentifier
DECLARE @OldIsPermanentSnapshot bit
DECLARE @OldSessionID varchar(32)

SELECT
   @OldSessionID = SessionID,
   @OldSnapshotDataID = SnapshotDataID,
   @OldIsPermanentSnapshot = IsPermanentSnapshot
FROM [ReportServerTempDB].dbo.SessionData WITH (XLOCK) 
WHERE SessionID = @SessionID

IF @OldSessionID IS NOT NULL
BEGIN -- Yes, update it
   IF @OldSnapshotDataID != @SnapshotDataID or @SnapshotDataID is NULL BEGIN
      EXEC DereferenceSessionSnapshot @SessionID, @OwnerID
   END

   UPDATE
      [ReportServerTempDB].dbo.SessionData
   SET
      SnapshotDataID = @SnapshotDataID,
      IsPermanentSnapshot = @IsPermanentSnapshot,
      Timeout = @Timeout,
      AutoRefreshSeconds = @AutoRefreshSeconds,
      SnapshotExpirationDate = @SnapshotExpirationDate,
      -- we want database session to expire later than in-memory session
      Expiration = DATEADD(s, @Timeout+10, @now),
      ShowHideInfo = @ShowHideInfo,
      DataSourceInfo = @DataSourceInfo,
      ExecutionType = @ExecutionType
      -- EffectiveParams = @EffectiveParams, -- no need to update user params as they are always same
      -- ReportPath = @ReportPath
      -- OwnerID = @OwnerID
   WHERE
      SessionID = @SessionID

   -- update expiration date on a snapshot that we reference
   IF @IsPermanentSnapshot != 0 BEGIN
      UPDATE
         SnapshotData
      SET
         ExpirationDate = DATEADD(n, @SnapshotTimeoutSeconds, @now)
      WHERE
         SnapshotDataID = @SnapshotDataID
   END ELSE BEGIN
      UPDATE
         [ReportServerTempDB].dbo.SnapshotData
      SET
         ExpirationDate = DATEADD(n, @SnapshotTimeoutSeconds, @now)
      WHERE
         SnapshotDataID = @SnapshotDataID
   END

END
ELSE
BEGIN -- no, insert it
   UPDATE PS
	SET PS.RefCount = 1
	FROM
		[ReportServerTempDB].dbo.PersistedStream as PS
	WHERE
		PS.SessionID = @SessionID	
		
	INSERT INTO [ReportServerTempDB].dbo.SessionData
      (SessionID, SnapshotDataID, IsPermanentSnapshot, ReportPath,
       EffectiveParams, Timeout, AutoRefreshSeconds, Expiration,
       ShowHideInfo, DataSourceInfo, OwnerID, 
       CreationTime, HasInteractivity, SnapshotExpirationDate, HistoryDate, ExecutionType)
   VALUES
      (@SessionID, @SnapshotDataID, @IsPermanentSnapshot, @ReportPath,
       @EffectiveParams, @Timeout, @AutoRefreshSeconds, DATEADD(s, @Timeout, @now),
       @ShowHideInfo, @DataSourceInfo, @OwnerID, @now,
       @HasInteractivity, @SnapshotExpirationDate, @HistoryDate, @ExecutionType)
END
GO

GRANT EXECUTE ON [dbo].[SetSessionData] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[WriteLockSession]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[WriteLockSession]
GO

CREATE PROCEDURE [dbo].[WriteLockSession]
@SessionID as varchar(32)
AS
INSERT INTO [ReportServerTempDB].dbo.SessionLock WITH (ROWLOCK) (SessionID) VALUES (@SessionID)
GO

GRANT EXECUTE ON [dbo].[WriteLockSession] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CheckSessionLock]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CheckSessionLock]
GO

CREATE PROCEDURE [dbo].[CheckSessionLock]
@SessionID as varchar(32)
AS
DECLARE @Selected nvarchar(32)
SELECT @Selected=SessionID FROM [ReportServerTempDB].dbo.SessionLock WITH (ROWLOCK) WHERE SessionID = @SessionID
GO

GRANT EXECUTE ON [dbo].[CheckSessionLock] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ReadLockSnapshot]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[ReadLockSnapshot]
GO

CREATE PROCEDURE [dbo].[ReadLockSnapshot]
@SnapshotDataID as uniqueidentifier
AS
SELECT SnapshotDataID
FROM
   SnapshotData WITH (REPEATABLEREAD, ROWLOCK)
WHERE
   SnapshotDataID = @SnapshotDataID     
GO

GRANT EXECUTE ON [dbo].[ReadLockSnapshot] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetSessionData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetSessionData]
GO

-- Get record from session data, update session and snapshot
CREATE PROCEDURE [dbo].[GetSessionData]
@SessionID as varchar(32),
@OwnerSid as varbinary(85) = NULL,
@OwnerName as nvarchar(260),
@AuthType as int,
@SnapshotTimeoutMinutes as int
AS

DECLARE @OwnerID uniqueidentifier
EXEC GetUserID @OwnerSid, @OwnerName, @AuthType, @OwnerID OUTPUT

DECLARE @now as datetime
SET @now = GETDATE()

DECLARE @DBSessionID varchar(32)
DECLARE @SnapshotDataID uniqueidentifier
DECLARE @IsPermanentSnapshot bit

EXEC CheckSessionLock @SessionID = @SessionID

SELECT
    @DBSessionID = SE.SessionID,
    @SnapshotDataID = SE.SnapshotDataID,
    @IsPermanentSnapshot = SE.IsPermanentSnapshot
FROM
    [ReportServerTempDB].dbo.SessionData AS SE WITH (XLOCK)
WHERE
    SE.OwnerID = @OwnerID AND
    SE.SessionID = @SessionID AND 
    SE.Expiration > @now

-- We need this update to keep session around while we process it.
-- TODO: This assumes that it will be processed within the session timeout.
UPDATE
   SE 
SET
   Expiration = DATEADD(s, Timeout, @now)
FROM
   [ReportServerTempDB].dbo.SessionData AS SE
WHERE
   SE.SessionID = @DBSessionID

-- Update snapshot expiration to prevent early deletion
-- If session uses snapshot, it is already refcounted. However, if session lasts for too long,
-- snapshot may expire. Therefore, every time we touch snapshot we should change expiration.

IF (@DBSessionID IS NOT NULL) BEGIN -- We return something only if session is present

IF @IsPermanentSnapshot != 0 BEGIN -- If session has snapshot and it is permanent

SELECT
    SN.SnapshotDataID,
    SE.ShowHideInfo,
    SE.DataSourceInfo,
    SN.Description,
    SE.EffectiveParams,
    SN.CreatedDate,
    SE.IsPermanentSnapshot,
    SE.CreationTime,
    SE.HasInteractivity,
    SE.Timeout,
    SE.SnapshotExpirationDate,
    SE.ReportPath,
    SE.HistoryDate,
    SE.CompiledDefinition,
    SN.PageCount,
    SN.HasDocMap,
    SE.Expiration,
    SN.EffectiveParams,
    SE.PageHeight,
    SE.PageWidth,
    SE.TopMargin,
    SE.BottomMargin,
    SE.LeftMargin,
    SE.RightMargin,
    SE.AutoRefreshSeconds,
    SE.ExecutionType
FROM
    [ReportServerTempDB].dbo.SessionData AS SE
    INNER JOIN SnapshotData AS SN ON SN.SnapshotDataID = SE.SnapshotDataID
WHERE
   SE.SessionID = @DBSessionID

UPDATE SnapshotData
SET ExpirationDate = DATEADD(n, @SnapshotTimeoutMinutes, @now)
WHERE SnapshotDataID = @SnapshotDataID

END ELSE IF @IsPermanentSnapshot = 0 BEGIN -- If session has snapshot and it is temporary

SELECT
    SN.SnapshotDataID,
    SE.ShowHideInfo,
    SE.DataSourceInfo,
    SN.Description,
    SE.EffectiveParams,
    SN.CreatedDate,
    SE.IsPermanentSnapshot,
    SE.CreationTime,
    SE.HasInteractivity,
    SE.Timeout,
    SE.SnapshotExpirationDate,
    SE.ReportPath,
    SE.HistoryDate,
    SE.CompiledDefinition,
    SN.PageCount,
    SN.HasDocMap,
    SE.Expiration,
    SN.EffectiveParams,
    SE.PageHeight,
    SE.PageWidth,
    SE.TopMargin,
    SE.BottomMargin,
    SE.LeftMargin,
    SE.RightMargin,
    SE.AutoRefreshSeconds,
    SE.ExecutionType
FROM
    [ReportServerTempDB].dbo.SessionData AS SE
    INNER JOIN [ReportServerTempDB].dbo.SnapshotData AS SN ON SN.SnapshotDataID = SE.SnapshotDataID
WHERE
   SE.SessionID = @DBSessionID
   
UPDATE [ReportServerTempDB].dbo.SnapshotData
SET ExpirationDate = DATEADD(n, @SnapshotTimeoutMinutes, @now)
WHERE SnapshotDataID = @SnapshotDataID

END ELSE BEGIN -- If session doesn't have snapshot

SELECT
    null,
    SE.ShowHideInfo,
    SE.DataSourceInfo,
    null,
    SE.EffectiveParams,
    null,
    SE.IsPermanentSnapshot,
    SE.CreationTime,
    SE.HasInteractivity,
    SE.Timeout,
    SE.SnapshotExpirationDate,
    SE.ReportPath,
    SE.HistoryDate,
    SE.CompiledDefinition,
    null,
    null,
    SE.Expiration,
    null,
    SE.PageHeight,
    SE.PageWidth,
    SE.TopMargin,
    SE.BottomMargin,
    SE.LeftMargin,
    SE.RightMargin,
    SE.AutoRefreshSeconds,
    SE.ExecutionType
FROM
    [ReportServerTempDB].dbo.SessionData AS SE
WHERE
   SE.SessionID = @DBSessionID

END

END

GO
GRANT EXECUTE ON [dbo].[GetSessionData] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetSnapshotFromHistory]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetSnapshotFromHistory]
GO

CREATE PROCEDURE [dbo].[GetSnapshotFromHistory]
@Path nvarchar (425),
@SnapshotDate datetime,
@AuthType int
AS
SELECT
   Catalog.ItemID,
   Catalog.Type,
   SnapshotData.SnapshotDataID, 
   SnapshotData.DependsOnUser,
   SnapshotData.Description,
   SecData.NtSecDescPrimary,
   Catalog.[Property]
FROM 
   SnapshotData 
   INNER JOIN History ON History.SnapshotDataID = SnapshotData.SnapshotDataID
   INNER JOIN Catalog ON History.ReportID = Catalog.ItemID
   LEFT OUTER JOIN SecData ON Catalog.PolicyID = SecData.PolicyID AND SecData.AuthType = @AuthType
WHERE 
   Catalog.Path = @Path 
   AND History.SnapshotDate = @SnapshotDate
GO
GRANT EXECUTE ON [dbo].[GetSnapshotFromHistory] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CleanExpiredSessions]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CleanExpiredSessions]
GO

CREATE PROCEDURE [dbo].[CleanExpiredSessions]
@SessionsCleaned int OUTPUT
AS
SET DEADLOCK_PRIORITY LOW
DECLARE @now as datetime
SET @now = GETDATE()
CREATE TABLE #tempSession
   (SessionID varchar(32) COLLATE Latin1_General_CI_AS_KS_WS,
    SnapshotDataID uniqueidentifier,
    CompiledDefinition uniqueidentifier)

INSERT INTO #tempSession
SELECT TOP 20 SessionID, SnapshotDataID, CompiledDefinition
FROM [ReportServerTempDB].dbo.SessionData WITH (XLOCK)
WHERE Expiration < @now

SET @SessionsCleaned = @@ROWCOUNT
IF @SessionsCleaned = 0 RETURN

-- Mark persisted streams for this session to be deleted
UPDATE PS
SET
	RefCount = 0,
	ExpirationDate = GETDATE()
FROM
    [ReportServerTempDB].dbo.PersistedStream AS PS
    INNER JOIN #tempSession on PS.SessionID = #tempsession.SessionID

DELETE SE
FROM
   [ReportServerTempDB].dbo.SessionData AS SE
   INNER JOIN #tempSession on SE.SessionID = #tempsession.SessionID

UPDATE SN
SET
   TransientRefcount = TransientRefcount-1
FROM
   [ReportServerTempDB].dbo.SnapshotData AS SN
   INNER JOIN #tempSession AS SE ON SN.SnapshotDataID = SE.CompiledDefinition

UPDATE SN
SET
   TransientRefcount = TransientRefcount-
      (SELECT COUNT(*)
       FROM #tempSession AS SE1
       WHERE SE1.SnapshotDataID = SN.SnapshotDataID)
FROM
   SnapshotData AS SN
   INNER JOIN #tempSession AS SE ON SN.SnapshotDataID = SE.SnapshotDataID

UPDATE SN
SET
   TransientRefcount = TransientRefcount-
      (SELECT COUNT(*)
       FROM #tempSession AS SE1
       WHERE SE1.SnapshotDataID = SN.SnapshotDataID)
FROM
   [ReportServerTempDB].dbo.SnapshotData AS SN
   INNER JOIN #tempSession AS SE ON SN.SnapshotDataID = SE.SnapshotDataID

GO
GRANT EXECUTE ON [dbo].[CleanExpiredSessions] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CleanExpiredCache]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CleanExpiredCache]
GO

CREATE PROCEDURE [dbo].[CleanExpiredCache]
AS
DECLARE @now as datetime
SET @now = DATEADD(minute, -1, GETDATE())

UPDATE SN
SET
   PermanentRefcount = PermanentRefcount - 1
FROM
   [ReportServerTempDB].dbo.SnapshotData AS SN
   INNER JOIN [ReportServerTempDB].dbo.ExecutionCache AS EC ON SN.SnapshotDataID = EC.SnapshotDataID
WHERE
   EC.AbsoluteExpiration < @now
   
DELETE EC
FROM
   [ReportServerTempDB].dbo.ExecutionCache AS EC
WHERE
   EC.AbsoluteExpiration < @now
GO
GRANT EXECUTE ON [dbo].[CleanExpiredCache] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SetSessionCredentials]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SetSessionCredentials]
GO

CREATE PROCEDURE [dbo].[SetSessionCredentials]
@SessionID as varchar(32),
@OwnerSid as varbinary(85) = NULL,
@OwnerName as nvarchar(260),
@AuthType as int,
@DataSourceInfo as image = NULL,
@Expiration as datetime,
@EffectiveParams as ntext = NULL
AS

DECLARE @OwnerID uniqueidentifier
EXEC GetUserID @OwnerSid, @OwnerName, @AuthType, @OwnerID OUTPUT

EXEC DereferenceSessionSnapshot @SessionID, @OwnerID

UPDATE SE
SET
   SE.DataSourceInfo = @DataSourceInfo,
   SE.SnapshotDataID = null,
   SE.IsPermanentSnapshot = null,
   SE.SnapshotExpirationDate = null,
   SE.ShowHideInfo = null,
   SE.HasInteractivity = null,
   SE.AutoRefreshSeconds = null,
   SE.Expiration = @Expiration,
   SE.EffectiveParams = @EffectiveParams
FROM
   [ReportServerTempDB].dbo.SessionData AS SE
WHERE
   SE.SessionID = @SessionID AND
   SE.OwnerID = @OwnerID
GO
GRANT EXECUTE ON [dbo].[SetSessionCredentials] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SetSessionParameters]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SetSessionParameters]
GO

CREATE PROCEDURE [dbo].[SetSessionParameters]
@SessionID as varchar(32),
@OwnerSid as varbinary(85) = NULL,
@OwnerName as nvarchar(260),
@AuthType as int,
@EffectiveParams as ntext = NULL
AS

DECLARE @OwnerID uniqueidentifier
EXEC GetUserID @OwnerSid, @OwnerName, @AuthType, @OwnerID OUTPUT

UPDATE SE
SET
   SE.EffectiveParams = @EffectiveParams
FROM
   [ReportServerTempDB].dbo.SessionData AS SE
WHERE
   SE.SessionID = @SessionID AND
   SE.OwnerID = @OwnerID
GO
GRANT EXECUTE ON [dbo].[SetSessionParameters] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ClearSessionSnapshot]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[ClearSessionSnapshot]
GO

CREATE PROCEDURE [dbo].[ClearSessionSnapshot]
@SessionID as varchar(32),
@OwnerSid as varbinary(85) = NULL,
@OwnerName as nvarchar(260),
@AuthType as int,
@Expiration as datetime
AS

DECLARE @OwnerID uniqueidentifier
EXEC GetUserID @OwnerSid, @OwnerName, @AuthType, @OwnerID OUTPUT

EXEC DereferenceSessionSnapshot @SessionID, @OwnerID

UPDATE SE
SET
   SE.SnapshotDataID = null,
   SE.IsPermanentSnapshot = null,
   SE.SnapshotExpirationDate = null,
   SE.ShowHideInfo = null,
   SE.HasInteractivity = null,
   SE.AutoRefreshSeconds = null,
   SE.Expiration = @Expiration
FROM
   [ReportServerTempDB].dbo.SessionData AS SE
WHERE
   SE.SessionID = @SessionID AND
   SE.OwnerID = @OwnerID
GO
GRANT EXECUTE ON [dbo].[ClearSessionSnapshot] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[RemoveReportFromSession]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[RemoveReportFromSession]
GO

CREATE PROCEDURE [dbo].[RemoveReportFromSession]
@SessionID as varchar(32),
@ReportPath as nvarchar(440), 
@OwnerSid as varbinary(85) = NULL,
@OwnerName as nvarchar(260),
@AuthType as int
AS

DECLARE @OwnerID uniqueidentifier
EXEC GetUserID @OwnerSid, @OwnerName, @AuthType, @OwnerID OUTPUT

EXEC DereferenceSessionSnapshot @SessionID, @OwnerID
   
DELETE
   SE
FROM
   [ReportServerTempDB].dbo.SessionData AS SE
WHERE
   SE.SessionID = @SessionID AND
   SE.ReportPath = @ReportPath AND
   SE.OwnerID = @OwnerID
   
-- Delete any persisted streams associated with this session
UPDATE PS
SET
	PS.RefCount = 0,
	PS.ExpirationDate = GETDATE()
FROM
    [ReportServerTempDB].dbo.PersistedStream AS PS
WHERE
    PS.SessionID = @SessionID

GO
GRANT EXECUTE ON [dbo].[RemoveReportFromSession] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CleanBrokenSnapshots]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CleanBrokenSnapshots]
GO

CREATE PROCEDURE [dbo].[CleanBrokenSnapshots]
@Machine nvarchar(512),
@SnapshotsCleaned int OUTPUT,
@ChunksCleaned int OUTPUT,
@TempSnapshotID uniqueidentifier OUTPUT
AS
    SET DEADLOCK_PRIORITY LOW
    DECLARE @now AS datetime
    SELECT @now = GETDATE()
    
    CREATE TABLE #tempSnapshot (SnapshotDataID uniqueidentifier)
    INSERT INTO #tempSnapshot SELECT TOP 1 SnapshotDataID 
    FROM SnapshotData  WITH (NOLOCK) 
    where SnapshotData.PermanentRefcount <= 0 
    AND ExpirationDate < @now
    SET @SnapshotsCleaned = @@ROWCOUNT

    DELETE ChunkData FROM ChunkData INNER JOIN #tempSnapshot
    ON ChunkData.SnapshotDataID = #tempSnapshot.SnapshotDataID
    SET @ChunksCleaned = @@ROWCOUNT

    DELETE SnapshotData FROM SnapshotData INNER JOIN #tempSnapshot
    ON SnapshotData.SnapshotDataID = #tempSnapshot.SnapshotDataID
    
    TRUNCATE TABLE #tempSnapshot

    INSERT INTO #tempSnapshot SELECT TOP 1 SnapshotDataID 
    FROM [ReportServerTempDB].dbo.SnapshotData  WITH (NOLOCK) 
    where [ReportServerTempDB].dbo.SnapshotData.PermanentRefcount <= 0 
    AND [ReportServerTempDB].dbo.SnapshotData.ExpirationDate < @now
    AND [ReportServerTempDB].dbo.SnapshotData.Machine = @Machine
    SET @SnapshotsCleaned = @SnapshotsCleaned + @@ROWCOUNT

    SELECT @TempSnapshotID = (SELECT SnapshotDataID FROM #tempSnapshot)

    DELETE [ReportServerTempDB].dbo.ChunkData FROM [ReportServerTempDB].dbo.ChunkData INNER JOIN #tempSnapshot
    ON [ReportServerTempDB].dbo.ChunkData.SnapshotDataID = #tempSnapshot.SnapshotDataID
    SET @ChunksCleaned = @ChunksCleaned + @@ROWCOUNT

    DELETE [ReportServerTempDB].dbo.SnapshotData FROM [ReportServerTempDB].dbo.SnapshotData INNER JOIN #tempSnapshot
    ON [ReportServerTempDB].dbo.SnapshotData.SnapshotDataID = #tempSnapshot.SnapshotDataID
GO

GRANT EXECUTE ON [dbo].[CleanBrokenSnapshots] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CleanOrphanedSnapshots]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CleanOrphanedSnapshots]
GO

CREATE PROCEDURE [dbo].[CleanOrphanedSnapshots]
@Machine nvarchar(512),
@SnapshotsCleaned int OUTPUT,
@ChunksCleaned int OUTPUT,
@TempSnapshotID uniqueidentifier OUTPUT
AS 
    SET DEADLOCK_PRIORITY LOW
    CREATE TABLE #tempSnapshot (SnapshotDataID uniqueidentifier)
    INSERT INTO #tempSnapshot SELECT TOP 1 SnapshotDataID 
    FROM SnapshotData  WITH (NOLOCK) 
    where SnapshotData.PermanentRefcount = 0 
    AND SnapshotData.TransientRefcount = 0 
    SET @SnapshotsCleaned = @@ROWCOUNT

    DELETE ChunkData FROM ChunkData INNER JOIN #tempSnapshot
    ON ChunkData.SnapshotDataID = #tempSnapshot.SnapshotDataID
    SET @ChunksCleaned = @@ROWCOUNT

    DELETE SnapshotData FROM SnapshotData INNER JOIN #tempSnapshot
    ON SnapshotData.SnapshotDataID = #tempSnapshot.SnapshotDataID
    
    TRUNCATE TABLE #tempSnapshot

    INSERT INTO #tempSnapshot SELECT TOP 1 SnapshotDataID 
    FROM [ReportServerTempDB].dbo.SnapshotData  WITH (NOLOCK) 
    where [ReportServerTempDB].dbo.SnapshotData.PermanentRefcount = 0 
    AND [ReportServerTempDB].dbo.SnapshotData.TransientRefcount = 0 
    AND [ReportServerTempDB].dbo.SnapshotData.Machine = @Machine
    SET @SnapshotsCleaned = @SnapshotsCleaned + @@ROWCOUNT

    SELECT @TempSnapshotID = (SELECT SnapshotDataID FROM #tempSnapshot)

    DELETE [ReportServerTempDB].dbo.ChunkData FROM [ReportServerTempDB].dbo.ChunkData INNER JOIN #tempSnapshot
    ON [ReportServerTempDB].dbo.ChunkData.SnapshotDataID = #tempSnapshot.SnapshotDataID
    SET @ChunksCleaned = @ChunksCleaned + @@ROWCOUNT

    DELETE [ReportServerTempDB].dbo.SnapshotData FROM [ReportServerTempDB].dbo.SnapshotData INNER JOIN #tempSnapshot
    ON [ReportServerTempDB].dbo.SnapshotData.SnapshotDataID = #tempSnapshot.SnapshotDataID
GO
        
GRANT EXECUTE ON [dbo].[CleanOrphanedSnapshots] TO RSExecRole
GO


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SetCacheOptions]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SetCacheOptions]
GO

CREATE PROCEDURE [dbo].[SetCacheOptions]
@Path as nvarchar(425),
@CacheReport as bit,
@ExpirationFlags as int,
@CacheExpiration as int = NULL
AS
DECLARE @CachePolicyID as uniqueidentifier
SELECT @CachePolicyID = (SELECT CachePolicyID 
FROM CachePolicy with (XLOCK) INNER JOIN Catalog ON Catalog.ItemID = CachePolicy.ReportID
WHERE  Catalog.Path = @Path)
IF @CachePolicyID IS NULL -- no policy exists
BEGIN
    IF @CacheReport = 1 -- create a new one
    BEGIN
        INSERT INTO CachePolicy
        (CachePolicyID, ReportID, ExpirationFlags, CacheExpiration)
        (SELECT NEWID(), ItemID, @ExpirationFlags, @CacheExpiration
        FROM Catalog WHERE Catalog.Path = @Path)
    END
    -- ELSE if it has no policy and we want to remove its policy do nothing
END
ELSE -- existing policy
BEGIN
    IF @CacheReport = 1
    BEGIN
        UPDATE CachePolicy SET ExpirationFlags = @ExpirationFlags, CacheExpiration = @CacheExpiration
        WHERE CachePolicyID = @CachePolicyID
        EXEC FlushReportFromCache @Path
    END
    ELSE
    BEGIN
        DELETE FROM CachePolicy 
        WHERE CachePolicyID = @CachePolicyID
        EXEC FlushReportFromCache @Path
    END
END
GO
GRANT EXECUTE ON [dbo].[SetCacheOptions] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetCacheOptions]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetCacheOptions]
GO

CREATE PROCEDURE [dbo].[GetCacheOptions]
@Path as nvarchar(425)
AS
    SELECT ExpirationFlags, CacheExpiration, 
    S.[ScheduleID],
    S.[Name],
    S.[StartDate],
    S.[Flags],
    S.[NextRunTime],
    S.[LastRunTime],
    S.[EndDate],
    S.[RecurrenceType],
    S.[MinutesInterval],
    S.[DaysInterval],
    S.[WeeksInterval],
    S.[DaysOfWeek],
    S.[DaysOfMonth],
    S.[Month],
    S.[MonthlyWeek],
    S.[State], 
    S.[LastRunStatus],
    S.[ScheduledRunTimeout],
    S.[EventType],
    S.[EventData],
    S.[Type]
    FROM CachePolicy INNER JOIN Catalog ON Catalog.ItemID = CachePolicy.ReportID
    LEFT outer join reportschedule rs on catalog.itemid = rs.reportid and rs.reportaction = 3
    LEFT OUTER JOIN [Schedule] S ON S.ScheduleID = rs.ScheduleID
    LEFT OUTER JOIN [Users] Owner on Owner.UserID = S.[CreatedById]
    WHERE Catalog.Path = @Path 
GO
GRANT EXECUTE ON [dbo].[GetCacheOptions] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[AddReportToCache]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[AddReportToCache]
GO

CREATE PROCEDURE [dbo].[AddReportToCache]
@ReportID as uniqueidentifier,
@ExecutionDate datetime,
@SnapshotDataID uniqueidentifier,
@ExpirationDate datetime OUTPUT,
@ScheduleID uniqueidentifier OUTPUT
AS
DECLARE @ExpirationFlags as int
DECLARE @Timeout as int

SET @ExpirationDate = NULL
SET @ScheduleID = NULL
SET @ExpirationFlags = (SELECT ExpirationFlags FROM CachePolicy WHERE ReportID = @ReportID)
IF @ExpirationFlags = 1 -- timeout based
BEGIN
    SET @Timeout = (SELECT CacheExpiration FROM CachePolicy WHERE ReportID = @ReportID)
    SET @ExpirationDate = DATEADD(n, @Timeout, @ExecutionDate)
END
ELSE IF @ExpirationFlags = 2 -- schedule based
BEGIN
    SET @ScheduleID = (SELECT s.ScheduleID FROM Schedule s INNER JOIN ReportSchedule rs on rs.ScheduleID = s.ScheduleID and rs.ReportAction = 3 WHERE rs.ReportID = @ReportID)
    SET @ExpirationDate = (SELECT Schedule.NextRunTime FROM Schedule with (XLOCK) WHERE Schedule.ScheduleID = @ScheduleID)
END
ELSE
BEGIN
    RAISERROR('Invalid cache flags', 16, 1)
END

-- and to the report cache
INSERT INTO [ReportServerTempDB].dbo.ExecutionCache
(ExecutionCacheID, ReportID, ExpirationFlags, AbsoluteExpiration, RelativeExpiration, SnapshotDataID)
VALUES
(newid(), @ReportID, @ExpirationFlags, @ExpirationDate, @Timeout, @SnapshotDataID )

UPDATE [ReportServerTempDB].dbo.SnapshotData
SET PermanentRefcount = PermanentRefcount + 1
WHERE SnapshotDataID = @SnapshotDataID;   

GO
GRANT EXECUTE ON [dbo].[AddReportToCache] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetExecutionOptions]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetExecutionOptions]
GO

CREATE PROCEDURE [dbo].[GetExecutionOptions]
@Path nvarchar(425)
AS
    SELECT ExecutionFlag, 
    S.[ScheduleID],
    S.[Name],
    S.[StartDate],
    S.[Flags],
    S.[NextRunTime],
    S.[LastRunTime],
    S.[EndDate],
    S.[RecurrenceType],
    S.[MinutesInterval],
    S.[DaysInterval],
    S.[WeeksInterval],
    S.[DaysOfWeek],
    S.[DaysOfMonth],
    S.[Month],
    S.[MonthlyWeek],
    S.[State], 
    S.[LastRunStatus],
    S.[ScheduledRunTimeout],
    S.[EventType],
    S.[EventData],
    S.[Type]
    FROM Catalog 
    LEFT OUTER JOIN ReportSchedule ON Catalog.ItemID = ReportSchedule.ReportID AND ReportSchedule.ReportAction = 1
    LEFT OUTER JOIN [Schedule] S ON S.ScheduleID = ReportSchedule.ScheduleID
    LEFT OUTER JOIN [Users] Owner on Owner.UserID = S.[CreatedById]
    WHERE Catalog.Path = @Path 
GO
GRANT EXECUTE ON [dbo].[GetExecutionOptions] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SetExecutionOptions]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SetExecutionOptions]
GO

CREATE PROCEDURE [dbo].[SetExecutionOptions]
@Path as nvarchar(425),
@ExecutionFlag as int,
@ExecutionChanged as bit = 0
AS
IF @ExecutionChanged = 0
BEGIN
    UPDATE Catalog SET ExecutionFlag = @ExecutionFlag WHERE Catalog.Path = @Path
END
ELSE
BEGIN
    IF (@ExecutionFlag & 3) = 2
    BEGIN   -- set it to snapshot, flush cache
        EXEC FlushReportFromCache @Path
        DELETE CachePolicy FROM CachePolicy INNER JOIN Catalog ON CachePolicy.ReportID = Catalog.ItemID
        WHERE Catalog.Path = @Path
    END

    -- now clean existing snapshot and execution time if any
    UPDATE SnapshotData
    SET PermanentRefcount = PermanentRefcount - 1
    FROM
       SnapshotData
       INNER JOIN Catalog ON SnapshotData.SnapshotDataID = Catalog.SnapshotDataID
    WHERE Catalog.Path = @Path
    
    UPDATE Catalog
    SET ExecutionFlag = @ExecutionFlag, SnapshotDataID = NULL, ExecutionTime = NULL
    WHERE Catalog.Path = @Path
END
GO
GRANT EXECUTE ON [dbo].[SetExecutionOptions] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[UpdateSnapshot]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[UpdateSnapshot]
GO

CREATE PROCEDURE [dbo].[UpdateSnapshot]
@Path as nvarchar(425),
@SnapshotDataID as uniqueidentifier,
@executionDate as datetime
AS
DECLARE @OldSnapshotDataID uniqueidentifier
SET @OldSnapshotDataID = (SELECT SnapshotDataID FROM Catalog WITH (XLOCK) WHERE Catalog.Path = @Path)

-- update reference count in snapshot table
UPDATE SnapshotData
SET PermanentRefcount = PermanentRefcount-1
WHERE SnapshotData.SnapshotDataID = @OldSnapshotDataID

-- update catalog to point to the new execution snapshot
UPDATE Catalog
SET SnapshotDataID = @SnapshotDataID, ExecutionTime = @executionDate
WHERE Catalog.Path = @Path

UPDATE SnapshotData
SET PermanentRefcount = PermanentRefcount+1, TransientRefcount = TransientRefcount-1
WHERE SnapshotData.SnapshotDataID = @SnapshotDataID

GO

GRANT EXECUTE ON [dbo].[UpdateSnapshot] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CreateChunkAndGetPointer]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CreateChunkAndGetPointer]
GO

CREATE PROCEDURE [dbo].[CreateChunkAndGetPointer]
@SnapshotDataID uniqueidentifier,
@IsPermanentSnapshot bit,
@ChunkName nvarchar(260),
@ChunkType int,
@MimeType nvarchar(260) = NULL,
@Version smallint,
@Content image,
@ChunkFlags tinyint = NULL,
@ChunkPointer binary(16) OUTPUT
AS

DECLARE @ChunkID uniqueidentifier
SET @ChunkID = NEWID()

IF @IsPermanentSnapshot != 0 BEGIN

    DELETE ChunkData
    WHERE
        SnapshotDataID = @SnapshotDataID AND
        ChunkName = @ChunkName AND
        ChunkType = @ChunkType

    INSERT
    INTO ChunkData
        (ChunkID, SnapshotDataID, ChunkName, ChunkType, MimeType, Version, ChunkFlags, Content)
    VALUES
        (@ChunkID, @SnapshotDataID, @ChunkName, @ChunkType, @MimeType, @Version, @ChunkFlags, @Content)

    SELECT @ChunkPointer = TEXTPTR(Content)
                FROM ChunkData
                WHERE ChunkData.ChunkID = @ChunkID

END ELSE BEGIN

    DELETE [ReportServerTempDB].dbo.ChunkData
    WHERE
        SnapshotDataID = @SnapshotDataID AND
        ChunkName = @ChunkName AND
        ChunkType = @ChunkType

    INSERT
    INTO [ReportServerTempDB].dbo.ChunkData
        (ChunkID, SnapshotDataID, ChunkName, ChunkType, MimeType, Version, ChunkFlags, Content)
    VALUES
        (@ChunkID, @SnapshotDataID, @ChunkName, @ChunkType, @MimeType, @Version, @ChunkFlags, @Content)

    SELECT @ChunkPointer = TEXTPTR(Content)
                FROM [ReportServerTempDB].dbo.ChunkData AS CH
                WHERE CH.ChunkID = @ChunkID
END   
   
GO
GRANT EXECUTE ON [dbo].[CreateChunkAndGetPointer] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[WriteChunkPortion]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[WriteChunkPortion]
GO

CREATE PROCEDURE [dbo].[WriteChunkPortion]
@ChunkPointer binary(16),
@IsPermanentSnapshot bit,
@DataIndex int = NULL,
@DeleteLength int = NULL,
@Content image
AS

IF @IsPermanentSnapshot != 0 BEGIN
    UPDATETEXT ChunkData.Content @ChunkPointer @DataIndex @DeleteLength @Content
END ELSE BEGIN
    UPDATETEXT [ReportServerTempDB].dbo.ChunkData.Content @ChunkPointer @DataIndex @DeleteLength @Content
END

GO
GRANT EXECUTE ON [dbo].[WriteChunkPortion] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetChunkPointerAndLength]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetChunkPointerAndLength]
GO

CREATE PROCEDURE [dbo].[GetChunkPointerAndLength]
@SnapshotDataID uniqueidentifier,
@IsPermanentSnapshot bit,
@ChunkName nvarchar(260),
@ChunkType int
AS
IF @IsPermanentSnapshot != 0 BEGIN

    SELECT
       TEXTPTR(Content),
       DATALENGTH(Content),
       MimeType,
       ChunkFlags,
       Version
    FROM
       ChunkData AS CH WITH (HOLDLOCK, ROWLOCK)
    WHERE
       SnapshotDataID = @SnapshotDataID AND
       ChunkName = @ChunkName AND
       ChunkType = @ChunkType      
       
END ELSE BEGIN

    SELECT
       TEXTPTR(Content),
       DATALENGTH(Content),
       MimeType,
       ChunkFlags,
       Version
    FROM
       [ReportServerTempDB].dbo.ChunkData AS CH WITH (HOLDLOCK, ROWLOCK)
    WHERE
       SnapshotDataID = @SnapshotDataID AND
       ChunkName = @ChunkName AND
       ChunkType = @ChunkType      

END
GO
GRANT EXECUTE ON [dbo].[GetChunkPointerAndLength] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetChunkInformation]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetChunkInformation]
GO

CREATE PROCEDURE [dbo].[GetChunkInformation]
@SnapshotDataID uniqueidentifier,
@IsPermanentSnapshot bit,
@ChunkName nvarchar(260),
@ChunkType int
AS
IF @IsPermanentSnapshot != 0 BEGIN

    SELECT
       MimeType
    FROM
       ChunkData AS CH WITH (HOLDLOCK, ROWLOCK)
    WHERE
       SnapshotDataID = @SnapshotDataID AND
       ChunkName = @ChunkName AND
       ChunkType = @ChunkType      
       
END ELSE BEGIN

    SELECT
       MimeType
    FROM
       [ReportServerTempDB].dbo.ChunkData AS CH WITH (HOLDLOCK, ROWLOCK)
    WHERE
       SnapshotDataID = @SnapshotDataID AND
       ChunkName = @ChunkName AND
       ChunkType = @ChunkType      

END
GO
GRANT EXECUTE ON [dbo].[GetChunkInformation] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ReadChunkPortion]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[ReadChunkPortion]
GO

CREATE PROCEDURE [dbo].[ReadChunkPortion]
@ChunkPointer binary(16),
@IsPermanentSnapshot bit,
@DataIndex int,
@Length int
AS

IF @IsPermanentSnapshot != 0 BEGIN
    READTEXT ChunkData.Content @ChunkPointer @DataIndex @Length
END ELSE BEGIN
    READTEXT [ReportServerTempDB].dbo.ChunkData.Content @ChunkPointer @DataIndex @Length
END
GO
GRANT EXECUTE ON [dbo].[ReadChunkPortion] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CopyChunksOfType]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CopyChunksOfType]
GO

CREATE PROCEDURE [dbo].[CopyChunksOfType]
@FromSnapshotID uniqueidentifier,
@FromIsPermanent bit,
@ToSnapshotID uniqueidentifier,
@ToIsPermanent bit,
@ChunkType int
AS

IF @FromIsPermanent != 0 AND @ToIsPermanent = 0 BEGIN

    INSERT INTO [ReportServerTempDB].dbo.ChunkData
        (ChunkID, SnapshotDataID, ChunkName, ChunkType, MimeType, Version, ChunkFlags, Content)
    SELECT
        newid(), @ToSnapshotID, S.ChunkName, S.ChunkType, S.MimeType, S.Version, S.ChunkFlags, S.Content
    FROM
        ChunkData AS S
    WHERE   
        S.SnapshotDataID = @FromSnapshotID AND
        S.ChunkType = @ChunkType AND
    NOT EXISTS(
        SELECT T.ChunkName
        FROM [ReportServerTempDB].dbo.ChunkData AS T -- exclude the ones in the target
        WHERE
            T.ChunkName = S.ChunkName AND
            T.ChunkType = S.ChunkType AND
            T.SnapshotDataID = @ToSnapshotID)

END ELSE IF @FromIsPermanent = 0 AND @ToIsPermanent = 0 BEGIN

    INSERT INTO [ReportServerTempDB].dbo.ChunkData
        (ChunkID, SnapshotDataID, ChunkName, ChunkType, MimeType, Version, ChunkFlags, Content)
    SELECT
        newid(), @ToSnapshotID, S.ChunkName, S.ChunkType, S.MimeType, S.Version, S.ChunkFlags, S.Content
    FROM
        [ReportServerTempDB].dbo.ChunkData AS S
    WHERE   
        S.SnapshotDataID = @FromSnapshotID AND
        S.ChunkType = @ChunkType AND
        NOT EXISTS(
            SELECT T.ChunkName
            FROM [ReportServerTempDB].dbo.ChunkData AS T -- exclude the ones in the target
            WHERE
                T.ChunkName = S.ChunkName AND
                T.ChunkType = S.ChunkType AND
                T.SnapshotDataID = @ToSnapshotID)

END ELSE IF @FromIsPermanent != 0 AND @ToIsPermanent != 0 BEGIN

    INSERT INTO ChunkData
        (ChunkID, SnapshotDataID, ChunkName, ChunkType, MimeType, Version, ChunkFlags, Content)
    SELECT
        newid(), @ToSnapshotID, S.ChunkName, S.ChunkType, S.MimeType, S.Version, S.ChunkFlags, S.Content
    FROM
        ChunkData AS S
    WHERE   
        S.SnapshotDataID = @FromSnapshotID AND
        S.ChunkType = @ChunkType AND
        NOT EXISTS(
            SELECT T.ChunkName
            FROM ChunkData AS T -- exclude the ones in the target
            WHERE
                T.ChunkName = S.ChunkName AND
                T.ChunkType = S.ChunkType AND
                T.SnapshotDataID = @ToSnapshotID)

END ELSE BEGIN
   RAISERROR('Unsupported chunk copy', 16, 1)
END
         
GO
GRANT EXECUTE ON [dbo].[CopyChunksOfType] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DeleteSnapshotAndChunks]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[DeleteSnapshotAndChunks]
GO

CREATE PROCEDURE [dbo].[DeleteSnapshotAndChunks]
@SnapshotID uniqueidentifier,
@IsPermanentSnapshot bit
AS

IF @IsPermanentSnapshot != 0 BEGIN

    DELETE ChunkData
    WHERE ChunkData.SnapshotDataID = @SnapshotID
       
    DELETE SnapshotData
    WHERE SnapshotData.SnapshotDataID = @SnapshotID
   
END ELSE BEGIN

    DELETE [ReportServerTempDB].dbo.ChunkData
    WHERE SnapshotDataID = @SnapshotID
       
    DELETE [ReportServerTempDB].dbo.SnapshotData
    WHERE SnapshotDataID = @SnapshotID

END   
      
GO
GRANT EXECUTE ON [dbo].[DeleteSnapshotAndChunks] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DeleteOneChunk]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[DeleteOneChunk]
GO

CREATE PROCEDURE [dbo].[DeleteOneChunk]
@SnapshotID uniqueidentifier,
@IsPermanentSnapshot bit,
@ChunkName nvarchar(260),
@ChunkType int
AS

IF @IsPermanentSnapshot != 0 BEGIN

DELETE ChunkData
WHERE   
    SnapshotDataID = @SnapshotID AND
    ChunkName = @ChunkName AND
    ChunkType = @ChunkType
    
END ELSE BEGIN

DELETE [ReportServerTempDB].dbo.ChunkData
WHERE   
    SnapshotDataID = @SnapshotID AND
    ChunkName = @ChunkName AND
    ChunkType = @ChunkType

END    
    
GO
GRANT EXECUTE ON [dbo].[DeleteOneChunk] TO RSExecRole
GO

--------------------------------------------------
------------- Persisted stream SPs

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DeletePersistedStreams]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[DeletePersistedStreams]
GO

CREATE PROCEDURE [dbo].[DeletePersistedStreams]
@SessionID varchar(32)
AS

delete 
	[ReportServerTempDB].dbo.PersistedStream
from 
	(select top 1 * from [ReportServerTempDB].dbo.PersistedStream PS2 where PS2.SessionID = @SessionID) as e1
where 
	e1.SessionID = [ReportServerTempDB].dbo.PersistedStream.[SessionID] and
	e1.[Index] = [ReportServerTempDB].dbo.PersistedStream.[Index]
    
GO
GRANT EXECUTE ON [dbo].[DeletePersistedStreams] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DeleteExpiredPersistedStreams]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[DeleteExpiredPersistedStreams]
GO

CREATE PROCEDURE [dbo].[DeleteExpiredPersistedStreams]
AS

SET DEADLOCK_PRIORITY LOW
DELETE
	[ReportServerTempDB].dbo.PersistedStream
FROM 
	(SELECT TOP 1 * FROM [ReportServerTempDB].dbo.PersistedStream PS2 WHERE PS2.RefCount = 0 AND GETDATE() > PS2.ExpirationDate) AS e1
WHERE 
	e1.SessionID = [ReportServerTempDB].dbo.PersistedStream.[SessionID] AND
	e1.[Index] = [ReportServerTempDB].dbo.PersistedStream.[Index]
    
GO
GRANT EXECUTE ON [dbo].[DeleteExpiredPersistedStreams] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DeletePersistedStream]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[DeletePersistedStream]
GO

CREATE PROCEDURE [dbo].[DeletePersistedStream]
@SessionID varchar(32),
@Index int
AS

delete from [ReportServerTempDB].dbo.PersistedStream where SessionID = @SessionID and [Index] = @Index
    
GO
GRANT EXECUTE ON [dbo].[DeletePersistedStream] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[AddPersistedStream]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[AddPersistedStream]
GO

CREATE PROCEDURE [dbo].[AddPersistedStream]
@SessionID varchar(32),
@Index int
AS

DECLARE @RefCount int
DECLARE @id varchar(32)
DECLARE @ExpirationDate datetime

set @RefCount = 0
set @ExpirationDate = DATEADD(day, 2, GETDATE())

set @id = (select SessionID from [ReportServerTempDB].dbo.SessionData where SessionID = @SessionID)

if @id is not null
begin
set @RefCount = 1
end

INSERT INTO [ReportServerTempDB].dbo.PersistedStream (SessionID, [Index], [RefCount], [ExpirationDate]) VALUES (@SessionID, @Index, @RefCount, @ExpirationDate)
    
GO
GRANT EXECUTE ON [dbo].[AddPersistedStream] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[LockPersistedStream]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[LockPersistedStream]
GO

CREATE PROCEDURE [dbo].[LockPersistedStream]
@SessionID varchar(32),
@Index int
AS

SELECT [Index] FROM [ReportServerTempDB].dbo.PersistedStream WITH (XLOCK) WHERE SessionID = @SessionID AND [Index] = @Index
    
GO
GRANT EXECUTE ON [dbo].[LockPersistedStream] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[WriteFirstPortionPersistedStream]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[WriteFirstPortionPersistedStream]
GO

CREATE PROCEDURE [dbo].[WriteFirstPortionPersistedStream]
@SessionID varchar(32),
@Index int,
@Name nvarchar(260) = NULL,
@MimeType nvarchar(260) = NULL,
@Extension nvarchar(260) = NULL,
@Encoding nvarchar(260) = NULL,
@Content image
AS

UPDATE [ReportServerTempDB].dbo.PersistedStream set Content = @Content, [Name] = @Name, MimeType = @MimeType, Extension = @Extension WHERE SessionID = @SessionID AND [Index] = @Index

SELECT TEXTPTR(Content) FROM [ReportServerTempDB].dbo.PersistedStream WHERE SessionID = @SessionID AND [Index] = @Index

GO
GRANT EXECUTE ON [dbo].[WriteFirstPortionPersistedStream] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[WriteNextPortionPersistedStream]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[WriteNextPortionPersistedStream]
GO

CREATE PROCEDURE [dbo].[WriteNextPortionPersistedStream]
@DataPointer binary(16),
@DataIndex int,
@DeleteLength int,
@Content image
AS

UPDATETEXT [ReportServerTempDB].dbo.PersistedStream.Content @DataPointer @DataIndex @DeleteLength @Content

GO
GRANT EXECUTE ON [dbo].[WriteNextPortionPersistedStream] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetFirstPortionPersistedStream]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetFirstPortionPersistedStream]
GO

CREATE PROCEDURE [dbo].[GetFirstPortionPersistedStream]
@SessionID varchar(32)
AS

SELECT 
    TOP 1
    TEXTPTR(P.Content), 
    DATALENGTH(P.Content), 
    P.[Index],
    P.[Name], 
    P.MimeType, 
    P.Extension, 
    P.Encoding,
    P.Error
FROM 
    [ReportServerTempDB].dbo.PersistedStream P WITH (XLOCK)
WHERE 
    P.SessionID = @SessionID
GO
GRANT EXECUTE ON [dbo].[GetFirstPortionPersistedStream] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SetPersistedStreamError]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SetPersistedStreamError]
GO

CREATE PROCEDURE [dbo].[SetPersistedStreamError]
@SessionID varchar(32),
@Index int,
@AllRows bit,
@Error nvarchar(512)
AS

if @AllRows = 0
BEGIN
    UPDATE [ReportServerTempDB].dbo.PersistedStream SET Error = @Error WHERE SessionID = @SessionID and [Index] = @Index
END
ELSE
BEGIN
    UPDATE [ReportServerTempDB].dbo.PersistedStream SET Error = @Error WHERE SessionID = @SessionID
END

GO
GRANT EXECUTE ON [dbo].[SetPersistedStreamError] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetNextPortionPersistedStream]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetNextPortionPersistedStream]
GO

CREATE PROCEDURE [dbo].[GetNextPortionPersistedStream]
@DataPointer binary(16),
@DataIndex int,
@Length int
AS

READTEXT [ReportServerTempDB].dbo.PersistedStream.Content @DataPointer @DataIndex @Length

GO
GRANT EXECUTE ON [dbo].[GetNextPortionPersistedStream] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetSnapshotChunks]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetSnapshotChunks]
GO

CREATE PROCEDURE [dbo].[GetSnapshotChunks]
@SnapshotDataID uniqueidentifier,
@IsPermanentSnapshot bit
AS

IF @IsPermanentSnapshot != 0 BEGIN

SELECT ChunkName, ChunkType, ChunkFlags, MimeType, Version, datalength(Content)
FROM ChunkData
WHERE   
    SnapshotDataID = @SnapshotDataID
    
END ELSE BEGIN

SELECT ChunkName, ChunkType, ChunkFlags, MimeType, Version, datalength(Content)
FROM [ReportServerTempDB].dbo.ChunkData
WHERE   
    SnapshotDataID = @SnapshotDataID
END    
    
GO
GRANT EXECUTE ON [dbo].[GetSnapshotChunks] TO RSExecRole
GO


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SetDrillthroughReports]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SetDrillthroughReports]
GO

CREATE PROCEDURE [dbo].[SetDrillthroughReports]
@ReportID uniqueidentifier,
@ModelID uniqueidentifier,
@ModelItemID nvarchar(425),
@Type tinyint
AS
 INSERT INTO ModelDrill (ModelDrillID, ModelID, ReportID, ModelItemID, [Type])
 VALUES (newid(), @ModelID, @ReportID, @ModelItemID, @Type)
GO

GRANT EXECUTE ON [dbo].[SetDrillthroughReports] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DeleteDrillthroughReports]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[DeleteDrillthroughReports]
GO

CREATE PROCEDURE [dbo].[DeleteDrillthroughReports]
@ModelID uniqueidentifier,
@ModelItemID nvarchar(425)
AS
 DELETE ModelDrill WHERE ModelID = @ModelID and ModelItemID = @ModelItemID
GO

GRANT EXECUTE ON [dbo].[DeleteDrillthroughReports] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetDrillthroughReports]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetDrillthroughReports]
GO

CREATE PROCEDURE [dbo].[GetDrillthroughReports]
@ModelID uniqueidentifier,
@ModelItemID nvarchar(425)
AS
 SELECT 
 ModelDrill.Type, 
 Catalog.Path
 FROM ModelDrill INNER JOIN Catalog ON ModelDrill.ReportID = Catalog.ItemID
 WHERE ModelID = @ModelID
 AND ModelItemID = @ModelItemID 
GO

GRANT EXECUTE ON [dbo].[GetDrillthroughReports] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetDrillthroughReport]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetDrillthroughReport]
GO

CREATE PROCEDURE [dbo].[GetDrillthroughReport]
@ModelPath nvarchar(425),
@ModelItemID nvarchar(425),
@Type tinyint
AS
 SELECT 
 CatRep.Path
 FROM ModelDrill 
 INNER JOIN Catalog CatMod ON ModelDrill.ModelID = CatMod.ItemID
 INNER JOIN Catalog CatRep ON ModelDrill.ReportID = CatRep.ItemID
 WHERE CatMod.Path = @ModelPath
 AND ModelItemID = @ModelItemID 
 AND ModelDrill.[Type] = @Type
GO

GRANT EXECUTE ON [dbo].[GetDrillthroughReport] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetUpgradeItems]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetUpgradeItems]
GO

CREATE PROCEDURE [dbo].[GetUpgradeItems]
AS
SELECT 
    [Item],
    [Status]
FROM 
    [UpgradeInfo]
GO

GRANT EXECUTE ON [dbo].[GetUpgradeItems] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SetUpgradeItemStatus]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SetUpgradeItemStatus]
GO

CREATE PROCEDURE [dbo].[SetUpgradeItemStatus]
@ItemName nvarchar(260),
@Status nvarchar(512)
AS
UPDATE 
    [UpgradeInfo]
SET
    [Status] = @Status
WHERE
    [Item] = @ItemName
GO

GRANT EXECUTE ON [dbo].[SetUpgradeItemStatus] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetPolicyRoots]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetPolicyRoots]
GO

CREATE PROCEDURE [dbo].[GetPolicyRoots]
AS
SELECT 
    [Path],
    [Type]
FROM 
    [Catalog] 
WHERE 
    [PolicyRoot] = 1
GO

GRANT EXECUTE ON [dbo].[GetPolicyRoots] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetDataSourceForUpgrade]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetDataSourceForUpgrade]
GO

CREATE PROCEDURE [dbo].[GetDataSourceForUpgrade]
@CurrentVersion int
AS
SELECT 
    [DSID]
FROM 
    [DataSource]
WHERE
    [Version] != @CurrentVersion
GO

GRANT EXECUTE ON [dbo].[GetDataSourceForUpgrade] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetSubscriptionsForUpgrade]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetSubscriptionsForUpgrade]
GO

CREATE PROCEDURE [dbo].[GetSubscriptionsForUpgrade]
@CurrentVersion int
AS
SELECT 
    [SubscriptionID]
FROM 
    [Subscriptions]
WHERE
    [Version] != @CurrentVersion
GO

GRANT EXECUTE ON [dbo].[GetSubscriptionsForUpgrade] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[StoreServerParameters]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[StoreServerParameters]
GO

CREATE PROCEDURE [dbo].[StoreServerParameters]
@ServerParametersID nvarchar(32),
@Path nvarchar(425),
@CurrentDate datetime,
@Timeout int,
@Expiration datetime,
@ParametersValues image,
@ParentParametersID nvarchar(32) = NULL
AS

DECLARE @ExistingServerParametersID as nvarchar(32)
SET @ExistingServerParametersID = (SELECT ServerParametersID from [dbo].[ServerParametersInstance] WHERE ServerParametersID = @ServerParametersID)
IF @ExistingServerParametersID IS NULL -- new row
BEGIN
  INSERT INTO [dbo].[ServerParametersInstance]
    (ServerParametersID, ParentID, Path, CreateDate, ModifiedDate, Timeout, Expiration, ParametersValues)
  VALUES
    (@ServerParametersID, @ParentParametersID, @Path, @CurrentDate, @CurrentDate, @Timeout, @Expiration, @ParametersValues)
END
ELSE
BEGIN
  UPDATE [dbo].[ServerParametersInstance]
  SET Timeout = @Timeout,
  Expiration = @Expiration,
  ParametersValues = @ParametersValues,
  ModifiedDate = @CurrentDate,
  Path = @Path,
  ParentID = @ParentParametersID
  WHERE ServerParametersID = @ServerParametersID
END
GO

GRANT EXECUTE ON [dbo].[StoreServerParameters] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetServerParameters]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetServerParameters]
GO

CREATE PROCEDURE [dbo].[GetServerParameters]
@ServerParametersID nvarchar(32)
AS
DECLARE @now as DATETIME
SET @now = GETDATE()
SELECT Child.Path, Child.ParametersValues, Parent.ParametersValues
FROM [dbo].[ServerParametersInstance] Child
LEFT OUTER JOIN [dbo].[ServerParametersInstance] Parent
ON Child.ParentID = Parent.ServerParametersID
WHERE Child.ServerParametersID = @ServerParametersID 
AND Child.Expiration > @now
GO


GRANT EXECUTE ON [dbo].[GetServerParameters] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CleanExpiredServerParameters]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CleanExpiredServerParameters]
GO

CREATE PROCEDURE [dbo].[CleanExpiredServerParameters]
@ParametersCleaned INT OUTPUT
AS
  DECLARE @now as DATETIME
  SET @now = GETDATE()

DELETE FROM [dbo].[ServerParametersInstance] 
WHERE ServerParametersID IN 
(  SELECT TOP 20 ServerParametersID FROM [dbo].[ServerParametersInstance]
  WHERE Expiration < @now
)

SET @ParametersCleaned = @@ROWCOUNT
 
GO

GRANT EXECUTE ON [dbo].[CleanExpiredServerParameters] TO RSExecRole
GO



-- END STORED PROCEDURES
--------------------------------------------------
------------- Initial population
--------------------------------------------------

INSERT INTO [dbo].[ConfigurationInfo] VALUES ( newid(), 'MyReportsRole', N'My Reports' )
INSERT INTO [dbo].[ConfigurationInfo] VALUES ( newid(), 'EnableMyReports', 'False' )
INSERT INTO [dbo].[ConfigurationInfo] VALUES ( newid(), 'UseSessionCookies', 'true' )
INSERT INTO [dbo].[ConfigurationInfo] VALUES ( newid(), 'SessionTimeout', '600' ) -- 10 min
INSERT INTO [dbo].[ConfigurationInfo] VALUES ( newid(), 'SystemSnapshotLimit', '-1' )
INSERT INTO [dbo].[ConfigurationInfo] VALUES ( newid(), 'SystemReportTimeout', '1800' ) -- 30 min
INSERT INTO [dbo].[ConfigurationInfo] VALUES ( newid(), 'SiteName', 'SQL Server Reporting Services' )
INSERT INTO [dbo].[ConfigurationInfo] VALUES ( newid(), 'EnableExecutionLogging', 'True' )
INSERT INTO [dbo].[ConfigurationInfo] VALUES ( newid(), 'ExecutionLogDaysKept', '60' )
INSERT INTO [dbo].[ConfigurationInfo] VALUES ( newid(), 'SnapshotCompression', 'SQL' )
INSERT INTO [dbo].[ConfigurationInfo] VALUES ( newid(), 'EnableIntegratedSecurity', 'true' )
INSERT INTO [dbo].[ConfigurationInfo] VALUES ( newid(), 'ExternalImagesTimeout', '600' ) -- 10 min
INSERT INTO [dbo].[ConfigurationInfo] VALUES ( newid(), 'StoredParametersThreshold', '1500' ) 
INSERT INTO [dbo].[ConfigurationInfo] VALUES ( newid(), 'StoredParametersLifetime', '180' ) -- days
INSERT INTO [dbo].[ConfigurationInfo] VALUES ( newid(), 'EnableReportDesignClientDownload', 'True' )
INSERT INTO [dbo].[ConfigurationInfo] VALUES ( newid(), 'EnableClientPrinting', 'True' )
INSERT INTO [dbo].[ConfigurationInfo] VALUES ( newid(), 'EnableRemoteErrors', 'False' )
GO

DECLARE @NewItemID uniqueidentifier 
DECLARE @Now DateTime
DECLARE @NewPolicyID uniqueidentifier 

SET @NewItemID = newid()
SET @Now = GETDATE()

-- Create builtin roles

DECLARE @RoleIDPublisher uniqueidentifier
SET @RoleIDPublisher = newid()
EXEC [dbo].[CreateRole]
@RoleID = @RoleIDPublisher,
@RoleName = N'Publisher',
@Description = N'May publish reports and linked reports to the Report Server.',
@TaskMask = '0101010100001010',
@RoleFlags = 0

/*
ConfigureAccess             =0,
CreateLinkedReports         =1, x
ViewReports                 =2, 
ManageReports               =3, x
ViewResources               =4, 
ManageResources             =5, x
ViewFolders                 =6, 
ManageFolders               =7, x
ManageSnapshots             =8,
Subscribe                   =9, 
ManageAnySubscription       =10,
ViewDatasources             =11,
ManageDatasources           =12,x
ViewModels                  =13,
ManageModels                =14, x
ConsumeReports              =15
*/


DECLARE @RoleIDBrowser uniqueidentifier
SET @RoleIDBrowser = newid()
EXEC [dbo].[CreateRole]
@RoleID = @RoleIDBrowser,
@RoleName = N'Browser',  -- This string is localized.  Changing it here requires a change in setupmanagement.dll
@Description = N'May view folders, reports and subscribe to reports.',  -- This string is localized.  Changing it here requires a change in setupmanagement.dll
@TaskMask = '0010101001000100',

@RoleFlags = 0

/*
ConfigureAccess             =0,
CreateLinkedReports         =1,
ViewReports                 =2, x
ManageReports               =3,
ViewResources               =4, x
ManageResources             =5,
ViewFolders                 =6, x
ManageFolders               =7,
ManageSnapshots             =8,
Subscribe                   =9, x
ManageAnySubscription       =10
ViewDatasources             =11,
ManageDatasources           =12, 
ViewModels                  =13,x
ManageModels                =14 ,
ConsumeReports              =15
*/


DECLARE @RoleIDContentManager uniqueidentifier
SET @RoleIDContentManager = newid()
EXEC [dbo].[CreateRole]
@RoleID = @RoleIDContentManager,
@RoleName = N'Content Manager', -- This string is localized.  Changing it here requires a change in setupmanagement.dll
@Description = N'May manage content in the Report Server.  This includes folders, reports and resources.', -- This string is localized.  Changing it here requires a change in setupmanagement.dll
@TaskMask = '1111111111111111',
@RoleFlags = 0
/*
ConfigureAccess             =0, x
CreateLinkedReports         =1, x
ViewReports                 =2, x
ManageReports               =3, x
ViewResources               =4, x
ManageResources             =5, x
ViewFolders                 =6, x
ManageFolders               =7, x
ManageSnapshots             =8, x
Subscribe                   =9, x
ManageAnySubscription       =10,x
ViewDatasources             =11,x
ManageDatasources           =12,x
ViewModels                  =13,x
ManageModels                =14,x
ConsumeReports              =15,x
*/

DECLARE @RoleIDReportConsumer uniqueidentifier
SET @RoleIDReportConsumer = newid()
EXEC [dbo].[CreateRole]
@RoleID = @RoleIDReportConsumer,
@RoleName = N'Report Builder', -- This string is localized.  Changing it here requires a change in setupmanagement.dll
@Description = N'May view report definitions.', -- This string is localized.  Changing it here requires a change in setupmanagement.dll
@TaskMask = '0010101001000101',
@RoleFlags = 0
/*
ConfigureAccess             =0,
CreateLinkedReports         =1,
ViewReports                 =2,
ManageReports               =3,
ViewResources               =4,
ManageResources             =5,
ViewFolders                 =6,
ManageFolders               =7,
ManageSnapshots             =8,
Subscribe                   =9,
ManageAnySubscription       =10,
ViewDatasources             =11,
ManageDatasources           =12,
ViewModels                  =13,
ManageModels                =14,
ConsumeReports              =15 x
*/

DECLARE @RoleIDMyReports uniqueidentifier
SET @RoleIDMyReports = newid()
EXEC [dbo].[CreateRole]
@RoleID = @RoleIDMyReports,
@RoleName = N'My Reports',  -- This string is localized.  Changing it here requires a change in setupmanagement.dll
@Description = N'May publish reports and linked reports; manage folders, reports and resources in a users My Reports folder.',  -- This string is localized.  Changing it here requires a change in setupmanagement.dll
@TaskMask = '0111111111011000',
@RoleFlags = 0
/*
ConfigureAccess            =0,
PublishLinkedReport        =1, X
ViewReports                =2, X
ManageReports              =3, X
ViewResources              =4, X
ManageResources            =5, X
ViewFolders                =6, X
ManageFolders              =7, X
ManageSnapshots            =8, X
Subscribe                  =9, X
ManageAllSubscriptions     =10,
ViewDatasources            =11,X
ManageDatasources          =12 X
ViewModels                 =13,
ManageModels               =14,
ConsumeReports             =15
*/

DECLARE @RoleIDAdministrator uniqueidentifier
SET @RoleIDAdministrator = newid()
EXEC [dbo].[CreateRole]
@RoleID = @RoleIDAdministrator,
@RoleName = N'System Administrator',  -- This string is localized.  Changing it here requires a change in setupmanagement.dll
@Description = N'View and modify system role assignments, system role definitions, system properties, and shared schedules.',  -- This string is localized.  Changing it here requires a change in setupmanagement.dll
@TaskMask = '110101011',
@RoleFlags = 1 --system role
/*
ManageRoles                 = 0, x
ManageSystemSecurity        = 1, x
ViewSystemProperties        = 2,
ManageSystemProperties      = 3, x
ViewSharedSchedules         = 4,
ManageSharedSchedules       = 5, x
GenerateEvents              = 6,
ManageJobs                  = 7, x
ExecuteReportDefinitions    = 8  x
*/

DECLARE @RoleIDSysBrowser uniqueidentifier
SET @RoleIDSysBrowser = newid()
EXEC [dbo].[CreateRole]
@RoleID = @RoleIDSysBrowser,
@RoleName = N'System User',  -- This string is localized.  Changing it here requires a change in setupmanagement.dll
@Description = N'View system properties and shared schedules.',  -- This string is localized.  Changing it here requires a change in setupmanagement.dll
@TaskMask = '001010001',
@RoleFlags = 1 --system role
/*
ManageRoles                 = 0, 
ManageSystemSecurity        = 1, 
ViewSystemProperties        = 2, x
ManageSystemProperties      = 3, 
ViewSharedSchedules         = 4, x
ManageSharedSchedules       = 5, 
GenerateEvents              = 6,
ManageJobs                  = 7,
ExecuteReportDefinitions    = 8  x
*/

DECLARE @RoleIDModelItemBrowser uniqueidentifier
SET @RoleIDModelItemBrowser = newid()
EXEC [dbo].[CreateRole]
@RoleID = @RoleIDModelItemBrowser,
@RoleName = N'Model Item Browser', -- This string is localized.  Changing it here requires a change in setupmanagement.dll
@Description = N'Allows users to view models items in a particular model.', -- This string is localized.  Changing it here requires a change in setupmanagement.dll
@TaskMask = '1',
@RoleFlags = 2 -- Model item role

/*Create policies*/
SET @NewPolicyID = newid()
INSERT INTO [dbo].[Policies] (
    [PolicyID],
    [PolicyFlag]) 
VALUES (
    @NewPolicyID,
    0)

INSERT INTO [dbo].[SecData] (
    [SecDataID],
    [PolicyID], 
    [XmlDescription],
    [NtSecDescPrimary], 
    [AuthType]) 
VALUES (
    newid(),
    @NewPolicyID, 
    -- The xml string is localized.  Changing the group user name or role name fields required a change in setupmanagement.dll
    N'<Policies><Policy><GroupUserName>BUILTIN\Administrators</GroupUserName><Roles><Role><Name>Content Manager</Name></Role></Roles></Policy></Policies>' ,
    0x06050054000000020100048034000000440000000000000014000000020020000100000000041800FF00060001020000000000052000000020020000010200000000000520000000200200000102000000000005200000002002000054000000030100048034000000440000000000000014000000020020000100000000041800FFFF3F00010200000000000520000000200200000102000000000005200000002002000001020000000000052000000020020000540000000401000480340000004400000000000000140000000200200001000000000418001D000000010200000000000520000000200200000102000000000005200000002002000001020000000000052000000020020000540000000501000480340000004400000000000000140000000200200001000000000418001F000600010200000000000520000000200200000102000000000005200000002002000001020000000000052000000020020000540000000601000480340000004400000000000000140000000200200001000000000418001F00060001020000000000052000000020020000010200000000000520000000200200000102000000000005200000002002000054000000070100048034000000440000000000000014000000020020000100000000041800FF010600010200000000000520000000200200000102000000000005200000002002000001020000000000052000000020020000,
    1)

DECLARE @SystemPolicyID uniqueidentifier
SET @SystemPolicyID = newid()
INSERT INTO [dbo].[Policies] (
    [PolicyID], 
    [PolicyFlag])
VALUES (
    @SystemPolicyID, 
    1)

INSERT INTO [dbo].[SecData] (
    [SecDataID],
    [PolicyID], 
    [XmlDescription],
    [NtSecDescPrimary], 
    [AuthType])
VALUES (
    newid(),
    @SystemPolicyID, 
    -- The xml string is localized.  Changing the group user name or role name fields required a change in setupmanagement.dll
    N'<Policies><Policy><GroupUserName>BUILTIN\Administrators</GroupUserName><Roles><Role><Name>System Administrator</Name></Role></Roles></Policy></Policies>',
    0x01050054000000010100048034000000440000000000000014000000020020000100000000041800BF3F0600010200000000000520000000200200000102000000000005200000002002000001020000000000052000000020020000,
    1)


-- Create builtin principals
DECLARE @EveryoneID as uniqueidentifier
-- The xml string is localized.  Changing the group user name or role name fields required a change in setupmanagement.dll
EXEC [dbo].[GetPrincipalID] 0x010100000000000100000000, N'Everyone', 1, @EveryoneID OUTPUT

DECLARE @AdminID as uniqueidentifier
-- The xml string is localized.  Changing the group user name or role name fields required a change in setupmanagement.dll
EXEC [dbo].[GetPrincipalID] 0x01020000000000052000000020020000, N'BUILTIN\Administrators' , 1, @AdminID OUTPUT

-- create role-policy-principal relationships
INSERT INTO [dbo].[PolicyUserRole]
([ID], [RoleID], [UserID], [PolicyID])
VALUES
(newid(),  @RoleIDBrowser, @EveryoneID, @NewPolicyID)

INSERT INTO [dbo].[PolicyUserRole]
([ID], [RoleID], [UserID], [PolicyID])
VALUES
(newid(),  @RoleIDContentManager, @AdminID, @NewPolicyID)

INSERT INTO [dbo].[PolicyUserRole]
([ID], [RoleID], [UserID], [PolicyID])
VALUES
(newid(),  @RoleIDAdministrator, @AdminID, @SystemPolicyID)

INSERT INTO [dbo].[PolicyUserRole]
([ID], [RoleID], [UserID], [PolicyID])
VALUES
(newid(),  @RoleIDSysBrowser, @EveryoneID, @SystemPolicyID)

EXEC [dbo].[CreateObject]
   @ItemID = @NewItemID, 
   @Name = '', 
   @Path = '', 
   @ParentID = NULL,
   @Type = 1, 
   @Content = null, 
   @Intermediate = null, 
   @LinkSourceID = null,
   @Property = null,
   @Description = null,
   @CreatedBySid = 0x010100000000000512000000, -- local system
   @CreatedByName = N'NT AUTHORITY\SYSTEM',
   @AuthType = 1,
   @CreationDate = @Now,
   @MimeType = null,
   @SnapshotLimit = null,
   @PolicyRoot = 1,
   @PolicyID = @NewPolicyID
GO

--------------------------------------------------
------------- Master and MSDB rights
--------------------------------------------------

USE master
GO
GRANT EXECUTE ON master.dbo.xp_sqlagent_notify TO RSExecRole
GO

GRANT EXECUTE ON master.dbo.xp_sqlagent_enum_jobs TO RSExecRole
GO

GRANT EXECUTE ON master.dbo.xp_sqlagent_is_starting TO RSExecRole
GO

USE msdb
GO

-- Permissions for SQL Agent SP's
GRANT EXECUTE ON msdb.dbo.sp_help_category TO RSExecRole
GO
GRANT EXECUTE ON msdb.dbo.sp_add_category TO RSExecRole
GO
GRANT EXECUTE ON msdb.dbo.sp_add_job TO RSExecRole
GO
GRANT EXECUTE ON msdb.dbo.sp_add_jobserver TO RSExecRole
GO
GRANT EXECUTE ON msdb.dbo.sp_add_jobstep TO RSExecRole
GO
GRANT EXECUTE ON msdb.dbo.sp_add_jobschedule TO RSExecRole
GO
GRANT EXECUTE ON msdb.dbo.sp_help_job TO RSExecRole
GO
GRANT EXECUTE ON msdb.dbo.sp_delete_job TO RSExecRole
GO
GRANT EXECUTE ON msdb.dbo.sp_help_jobschedule TO RSExecRole
GO
GRANT EXECUTE ON msdb.dbo.sp_verify_job_identifiers TO RSExecRole
GO
GRANT SELECT ON msdb.dbo.sysjobs TO RSExecRole
GO
GRANT SELECT ON msdb.dbo.syscategories TO RSExecRole
GO

-- Yukon Requires that the user is in the SQLAgentOperatorRole
if exists (select * from sysusers where issqlrole = 1 and name = N'SQLAgentOperatorRole')
BEGIN
EXEC msdb.dbo.sp_addrolemember N'SQLAgentOperatorRole', N'RSExecRole'
END
GO

USE [ReportServerTempDB]


--------------------------------------
-- T.0.8.40 to T.0.8.41
--------------------------------------
-- No change in tables

--------------------------------------
-- T.0.8.41 to T.0.8.42
--------------------------------------

if (select count(*) from dbo.syscolumns where id = object_id('SessionData') and name = 'ExecutionType') = 1
begin
ALTER TABLE [dbo].[SessionData] DROP COLUMN [ExecutionType]
end
GO

if (select count(*) from dbo.syscolumns where id = object_id('SessionData') and name = 'AwaitingFirstExecution') = 0
begin
ALTER TABLE [dbo].[SessionData] ADD [AwaitingFirstExecution] bit NULL
end
GO
--------------------------------------
-- T.0.8.41 to T.0.8.43
--------------------------------------
if (
    select count(*)  
    from sysusers u
    join sysmembers m on u.uid = m.memberuid
    join sysusers r   on r.uid = m.groupuid
    where r.name = 'db_owner' and u.name = 'RSExecRole'
   ) = 0
begin
	exec sp_addrolemember 'db_owner', 'RSExecRole'
end
GO



USE [ReportServerTempDB]

--------------------------------------
-- T.0.8.43 to T.0.8.44
--------------------------------------
-- No change in tables

--------------------------------------
-- T.0.8.43 to T.0.8.45
--------------------------------------
-- No change in tables
--------------------------------------
-- T.0.8.45 to T.0.8.49
--------------------------------------
-- No change in tables
--------------------------------------
-- T.0.8.49 to T.0.8.50
--------------------------------------
-- No change in tables

--------------------------------------
-- T.0.8.50 to T.0.8.51
--------------------------------------
-- No change in tables


USE [ReportServerTempDB]

--------------------------------------
-- T.0.8.51 to T.0.8.52
--------------------------------------
-- No change in tables

--------------------------------------
-- T.0.8.52 to T.0.8.53
--------------------------------------
 -- No change in tables



USE [ReportServerTempDB]

--------------------------------------
-- T.0.8.53 to T.0.8.54
--------------------------------------
-- No change in tables




USE [ReportServer]

--------------------------------------
-- C.0.8.40 to C.0.8.41
--------------------------------------
-- No change in tables

--------------------------------------
-- C.0.8.41 to C.0.8.42
--------------------------------------
-- No change in tables

--------------------------------------
-- C.0.8.41 to C.0.8.43
--------------------------------------
if (
    select count(*)  
    from sysusers u
    join sysmembers m on u.uid = m.memberuid
    join sysusers r   on r.uid = m.groupuid
    where r.name = 'db_owner' and u.name = 'RSExecRole'
   ) = 0
begin
	exec sp_addrolemember 'db_owner', 'RSExecRole'
end
GO



USE [ReportServer]

--------------------------------------
-- C.0.8.43 to C.0.8.44
--------------------------------------
if not exists (select * from [dbo].[ConfigurationInfo] where [Name] = N'SharePointIntegrated')
begin
	INSERT INTO [dbo].[ConfigurationInfo] VALUES ( newid(), 'SharePointIntegrated', 'False' )
end
GO

--------------------------------------
-- C.0.8.44 to C.0.8.45
--------------------------------------
-- No change in tables

--------------------------------------
-- C.0.8.45 to C.0.8.46
--------------------------------------
-- No change in tables

--------------------------------------
-- C.0.8.46 to C.0.8.47
--------------------------------------
-- No change in tables
--------------------------------------
-- C.0.8.47 to C.0.8.48
--------------------------------------
-- One change in table Schedules - new column Path: [Path] [nvarchar] (425) NULL
if (select count(*) from dbo.syscolumns where id = object_id('Schedule') and name = 'Path') = 0
begin
	alter table [dbo].[Schedule] add Path [nvarchar] (260) NULL
end
GO
--------------------------------------
-- C.0.8.48 to C.0.8.49
--------------------------------------
-- No change in tables
--------------------------------------
-- C.0.8.49 to C.0.8.50
--------------------------------------
-- Removed unique constraint IX_Schedule. 
-- Added indexes IX_Schedule_name and IX_Schedule_path.
-- Added triggers Schedule_Insert and Schedule_Update.
if exists (select * from dbo.sysindexes where [name]='IX_Schedule')
begin
	alter table [dbo].[Schedule] drop constraint IX_Schedule
end
GO
-- Triggers Schedule_Insert and Schedule_Update are to enforce
-- the uniqueness of the Name+Path. We cannot use unique index as
-- combined size for these columns exceeds the maximum 900 bytes.
if (select count(*) from dbo.sysindexes where [name]='IX_Schedule_name') = 0
begin
	CREATE INDEX [IX_Schedule_name] ON [dbo].[Schedule] ([Name]) ON [PRIMARY]
end
GO

if (select count(*) from dbo.sysindexes where [name]='IX_Schedule_name') = 0
begin
	CREATE INDEX [IX_Schedule_path] ON [dbo].[Schedule] ([Path]) ON [PRIMARY]
end
GO

if (select count(*) from dbo.sysobjects where id = object_id(N'[dbo].[Schedule_Insert]') and OBJECTPROPERTY(id, N'IsTrigger') = 1) = 1
begin
	DROP TRIGGER [Schedule_Insert]
end
GO

CREATE TRIGGER [dbo].[Schedule_Insert] ON [dbo].[Schedule]  
INSTEAD OF INSERT AS
if exists (select * from [dbo].[Schedule] as s, inserted as ins 
		   where s.Name = ins.Name and 
		   (s.Path = ins.Path or (s.Path is null and ins.Path is null)))
	raiserror('Schedule already exists', 16, 1)
else
	insert into [dbo].[Schedule]
	select 
		ScheduleID,
		Name,
		StartDate,
		Flags,
		NextRunTime,
		LastRunTime,
		EndDate,
		RecurrenceType,
		MinutesInterval,
		DaysInterval,
		WeeksInterval,
		DaysOfWeek,
		DaysOfMonth,
		Month,
		MonthlyWeek,
		State,
		LastRunStatus,
		ScheduledRunTimeout,
		CreatedById,
		EventType,
		EventData,
		Type,
		ConsistancyCheck,
		Path
	from inserted

GO

if (select count(*) from dbo.sysobjects where id = object_id(N'[dbo].[Schedule_Update]') and OBJECTPROPERTY(id, N'IsTrigger') = 1) = 1
begin
	DROP TRIGGER [Schedule_Update]
end
GO

CREATE TRIGGER [dbo].[Schedule_Update] ON [dbo].[Schedule]  
INSTEAD OF UPDATE AS

if (update(Name) or update(Path)) and 
	exists (select * from [dbo].[Schedule] as s with (nolock), inserted as ins 
			where s.Name = ins.Name and 
				  (s.Path = ins.Path or (s.Path is null and ins.Path is null)) and
				  s.ScheduleID <> ins.ScheduleID)
	raiserror('Schedule already exists', 16, 1)
else
	update [dbo].[Schedule]
	set Name				= ins.Name,
		StartDate			= ins.StartDate,
		Flags				= ins.Flags,
		NextRunTime			= ins.NextRunTime,
		LastRunTime			= ins.LastRunTime,
		EndDate				= ins.EndDate,
		RecurrenceType		= ins.RecurrenceType,
		MinutesInterval		= ins.MinutesInterval,
		DaysInterval		= ins.DaysInterval,
		WeeksInterval		= ins.WeeksInterval,
		DaysOfWeek			= ins.DaysOfWeek,
		DaysOfMonth			= ins.DaysOfMonth,
		Month				= ins.Month,
		MonthlyWeek			= ins.MonthlyWeek,
		State				= ins.State,
		LastRunStatus		= ins.LastRunStatus,
		ScheduledRunTimeout = ins.ScheduledRunTimeout,
		CreatedById			= ins.CreatedById,
		EventType			= ins.EventType,
		EventData			= ins.EventData,
		Type				= ins.Type,
		ConsistancyCheck	= ins.ConsistancyCheck,
		Path				= ins.Path
	from inserted as ins 
	where [Schedule].ScheduleID = ins.ScheduleID 
GO

--------------------------------------
-- C.0.8.50 to C.0.8.51
--------------------------------------
-- add nolock to schedule_update


USE [ReportServer]


--------------------------------------
-- C.0.8.51 to C.0.8.52
--------------------------------------
if not exists (select * from [dbo].[ConfigurationInfo] where [Name] = N'EnableLoadReportDefinition')
begin
	INSERT INTO [dbo].[ConfigurationInfo] VALUES ( newid(), 'EnableLoadReportDefinition', 'True' )
end
GO

--------------------------------------
-- C.0.8.52 to C.0.8.53
--------------------------------------

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[Schedule_Insert]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
drop trigger [dbo].[Schedule_Insert]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[Schedule_Update]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
drop trigger [dbo].[Schedule_Update]
GO

if exists (select * from sysindexes where [name]='IX_Schedule_name')
drop index [Schedule].[IX_Schedule_name]
GO

if exists (select * from sysindexes where [name]='IX_Schedule_path')
drop index [Schedule].[IX_Schedule_path]
GO

if exists (select * from sysindexes where [name]='IX_Schedule')
ALTER TABLE [dbo].[Schedule] DROP 
    CONSTRAINT [IX_Schedule]
GO

ALTER TABLE [dbo].[Schedule] WITH NOCHECK ADD 
    CONSTRAINT [IX_Schedule] UNIQUE NONCLUSTERED (
		[Name], [Path]
	) ON [PRIMARY]
GO

USE [ReportServer]

--------------------------------------
-- C.0.8.53 to C.0.8.54
--------------------------------------

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[Schedule_Insert]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
drop trigger [dbo].[Schedule_Insert]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[Schedule_Update]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
drop trigger [dbo].[Schedule_Update]
GO

if exists (select * from dbo.sysindexes where [name]='IX_Schedule_name')
drop index [Schedule].[IX_Schedule_name]
GO

if exists (select * from dbo.sysindexes where [name]='IX_Schedule_path')
drop index [Schedule].[IX_Schedule_path]
GO

if exists (select * from dbo.sysindexes where [name]='IX_Schedule')
ALTER TABLE [dbo].[Schedule] DROP 
    CONSTRAINT [IX_Schedule]
GO

ALTER TABLE [dbo].[Schedule] WITH NOCHECK ADD 
    CONSTRAINT [IX_Schedule] UNIQUE NONCLUSTERED (
		[Name], [Path]
	) ON [PRIMARY]
GO


USE [ReportServer]

-- START STORED PROCEDURES

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SetKeysForInstallation]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SetKeysForInstallation]
GO

CREATE PROCEDURE [dbo].[SetKeysForInstallation]
@InstallationID uniqueidentifier,
@SymmetricKey image = NULL,
@PublicKey image
AS

update [dbo].[Keys]
set [SymmetricKey] = @SymmetricKey, [PublicKey] = @PublicKey
where [InstallationID] = @InstallationID and [Client] = 1

GO
GRANT EXECUTE ON [dbo].[SetKeysForInstallation] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetAnnouncedKey]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetAnnouncedKey]
GO

CREATE PROCEDURE [dbo].[GetAnnouncedKey]
@InstallationID uniqueidentifier
AS

select PublicKey, MachineName, InstanceName
from Keys
where InstallationID = @InstallationID and Client = 1

GO
GRANT EXECUTE ON [dbo].[GetAnnouncedKey] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[AnnounceOrGetKey]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[AnnounceOrGetKey]
GO

CREATE PROCEDURE [dbo].[AnnounceOrGetKey]
@MachineName nvarchar(256),
@InstanceName nvarchar(32),
@InstallationID uniqueidentifier,
@PublicKey image,
@NumAnnouncedServices int OUTPUT
AS

-- Acquire lock
IF NOT EXISTS (SELECT * FROM [dbo].[Keys] WITH(XLOCK) WHERE [Client] < 0)
BEGIN
    RAISERROR('Keys lock row not found', 16, 1)
    RETURN
END

-- Get the number of services that have already announced their presence
SELECT @NumAnnouncedServices = count(*)
FROM [dbo].[Keys]
WHERE [Client] = 1

DECLARE @StoredInstallationID uniqueidentifier
DECLARE @StoredInstanceName nvarchar(32)

SELECT @StoredInstallationID = [InstallationID], @StoredInstanceName = [InstanceName]
FROM [dbo].[Keys]
WHERE [InstallationID] = @InstallationID AND [Client] = 1

IF @StoredInstallationID IS NULL -- no record present
BEGIN
    INSERT INTO [dbo].[Keys]
        ([MachineName], [InstanceName], [InstallationID], [Client], [PublicKey], [SymmetricKey])
    VALUES
        (@MachineName, @InstanceName, @InstallationID, 1, @PublicKey, null)
END
ELSE
BEGIN
    IF @StoredInstanceName IS NULL
    BEGIN
        UPDATE [dbo].[Keys]
        SET [InstanceName] = @InstanceName
        WHERE [InstallationID] = @InstallationID AND [Client] = 1
    END
END

SELECT [MachineName], [SymmetricKey], [PublicKey]
FROM [Keys]
WHERE [InstallationID] = @InstallationID and [Client] = 1

GO
GRANT EXECUTE ON [dbo].[AnnounceOrGetKey] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SetMachineName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SetMachineName]
GO

CREATE PROCEDURE [dbo].[SetMachineName]
@MachineName nvarchar(256),
@InstallationID uniqueidentifier
AS

UPDATE [dbo].[Keys]
SET MachineName = @MachineName
WHERE [InstallationID] = @InstallationID and [Client] = 1

GO
GRANT EXECUTE ON [dbo].[SetMachineName] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ListInstallations]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[ListInstallations]
GO

CREATE PROCEDURE [dbo].[ListInstallations]
AS

SELECT
    [MachineName],
    [InstanceName],
    [InstallationID],
    CASE WHEN [SymmetricKey] IS null THEN 0 ELSE 1 END
FROM [dbo].[Keys]
WHERE [Client] = 1

GO
GRANT EXECUTE ON [dbo].[ListInstallations] TO RSExecRole
GO


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ListInfoForReencryption]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[ListInfoForReencryption]
GO

CREATE PROCEDURE [dbo].[ListInfoForReencryption]
AS

SELECT [DSID]
FROM [dbo].[DataSource] WITH (XLOCK, TABLOCK)

SELECT [SubscriptionID]
FROM [dbo].[Subscriptions] WITH (XLOCK, TABLOCK)

SELECT [InstallationID], [PublicKey]
FROM [dbo].[Keys] WITH (XLOCK, TABLOCK)
WHERE [Client] = 1 AND ([SymmetricKey] IS NOT NULL)

GO
GRANT EXECUTE ON [dbo].[ListInfoForReencryption] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetDatasourceInfoForReencryption]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetDatasourceInfoForReencryption]
GO

CREATE PROCEDURE [dbo].[GetDatasourceInfoForReencryption]
@DSID as uniqueidentifier
AS

SELECT
    [ConnectionString],
    [OriginalConnectionString],
    [UserName],
    [Password],
    [CredentialRetrieval],
    [Version]
FROM [dbo].[DataSource]
WHERE [DSID] = @DSID

GO
GRANT EXECUTE ON [dbo].[GetDatasourceInfoForReencryption] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SetReencryptedDatasourceInfo]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SetReencryptedDatasourceInfo]
GO

CREATE PROCEDURE [dbo].[SetReencryptedDatasourceInfo]
@DSID uniqueidentifier,
@ConnectionString image = NULL,
@OriginalConnectionString image = NULL,
@UserName image = NULL,
@Password image = NULL,
@CredentialRetrieval int,
@Version int
AS

UPDATE [dbo].[DataSource]
SET
    [ConnectionString] = @ConnectionString,
    [OriginalConnectionString] = @OriginalConnectionString,
    [UserName] = @UserName,
    [Password] = @Password,
    [CredentialRetrieval] = @CredentialRetrieval,
    [Version] = @Version
WHERE [DSID] = @DSID

GO
GRANT EXECUTE ON [dbo].[SetReencryptedDatasourceInfo] TO RSExecRole
GO


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetSubscriptionInfoForReencryption]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetSubscriptionInfoForReencryption]
GO

CREATE PROCEDURE [dbo].[GetSubscriptionInfoForReencryption]
@SubscriptionID as uniqueidentifier
AS

SELECT [DeliveryExtension], [ExtensionSettings], [Version]
FROM [dbo].[Subscriptions]
WHERE [SubscriptionID] = @SubscriptionID

GO
GRANT EXECUTE ON [dbo].[GetSubscriptionInfoForReencryption] TO RSExecRole
GO


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SetReencryptedSubscriptionInfo]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SetReencryptedSubscriptionInfo]
GO

CREATE PROCEDURE [dbo].[SetReencryptedSubscriptionInfo]
@SubscriptionID as uniqueidentifier,
@ExtensionSettings as ntext = NULL,
@Version as int
AS

UPDATE [dbo].[Subscriptions]
SET [ExtensionSettings] = @ExtensionSettings,
    [Version] = @Version
WHERE [SubscriptionID] = @SubscriptionID

GO
GRANT EXECUTE ON [dbo].[SetReencryptedSubscriptionInfo] TO RSExecRole
GO


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DeleteEncryptedContent]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[DeleteEncryptedContent]
GO

CREATE PROCEDURE [dbo].[DeleteEncryptedContent]
AS

-- Remove the encryption keys
delete from keys where client >= 0

-- Remove the encrypted content
update datasource
set CredentialRetrieval = 1, -- CredentialRetrieval.Prompt
    ConnectionString = null,
    OriginalConnectionString = null,
    UserName = null,
    Password = null

GO
GRANT EXECUTE ON [dbo].[DeleteEncryptedContent] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DeleteKey]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[DeleteKey]
GO

CREATE PROCEDURE [dbo].[DeleteKey]
@InstallationID uniqueidentifier
AS

if (@InstallationID = '00000000-0000-0000-0000-000000000000')
RAISERROR('Cannot delete reserved key', 16, 1)

-- Remove the encryption keys
delete from keys where InstallationID = @InstallationID and Client = 1

GO
GRANT EXECUTE ON [dbo].[DeleteKey] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetAllConfigurationInfo]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetAllConfigurationInfo]
GO

CREATE PROCEDURE [dbo].[GetAllConfigurationInfo]
AS
SELECT [Name], [Value]
FROM [ConfigurationInfo]
GO
GRANT EXECUTE ON [dbo].[GetAllConfigurationInfo] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetOneConfigurationInfo]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetOneConfigurationInfo]
GO

CREATE PROCEDURE [dbo].[GetOneConfigurationInfo]
@Name nvarchar (260)
AS
SELECT [Value]
FROM [ConfigurationInfo]
WHERE [Name] = @Name
GO
GRANT EXECUTE ON [dbo].[GetOneConfigurationInfo] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SetConfigurationInfo]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SetConfigurationInfo]
GO

CREATE PROCEDURE [dbo].[SetConfigurationInfo]
@Name nvarchar (260),
@Value ntext
AS
DELETE
FROM [ConfigurationInfo]
WHERE [Name] = @Name

IF @Value is not null BEGIN
   INSERT
   INTO ConfigurationInfo
   VALUES ( newid(), @Name, @Value )
END
GO
GRANT EXECUTE ON [dbo].[SetConfigurationInfo] TO RSExecRole

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[AddEvent]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[AddEvent]
GO

CREATE PROCEDURE [dbo].[AddEvent] 
@EventType nvarchar (260),
@EventData nvarchar (260)
AS

insert into [Event] 
    ([EventID], [EventType], [EventData], [TimeEntered], [ProcessStart], [BatchID]) 
values
    (NewID(), @EventType, @EventData, GETUTCDATE(), NULL, NULL)
GO
GRANT EXECUTE ON [dbo].[AddEvent] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DeleteEvent]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[DeleteEvent]
GO

CREATE PROCEDURE [dbo].[DeleteEvent] 
@ID uniqueidentifier
AS
delete from [Event] where [EventID] = @ID
GO
GRANT EXECUTE ON [dbo].[DeleteEvent] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CleanEventRecords]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CleanEventRecords]
GO

CREATE PROCEDURE [dbo].[CleanEventRecords] 
@MaxAgeMinutes int
AS
-- Reset all notifications which have been add over n minutes ago
Update [Event] set [ProcessStart] = NULL, [ProcessHeartbeat] = NULL
where [EventID] in
   ( SELECT [EventID]
     FROM [Event]
     WHERE [ProcessHeartbeat] < DATEADD(minute, -(@MaxAgeMinutes), GETUTCDATE()) )
GO
GRANT EXECUTE ON [dbo].[CleanEventRecords] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[AddExecutionLogEntry]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[AddExecutionLogEntry]
GO

CREATE PROCEDURE [dbo].[AddExecutionLogEntry]
@InstanceName nvarchar(38),
@Report nvarchar(260),
@UserSid varbinary(85) = NULL,
@UserName nvarchar(260),
@AuthType int,
@RequestType bit,
@Format nvarchar(26),
@Parameters ntext,
@TimeStart DateTime,
@TimeEnd DateTime,
@TimeDataRetrieval int,
@TimeProcessing int,
@TimeRendering int,
@Source tinyint,
@Status nvarchar(32),
@ByteCount bigint,
@RowCount bigint
AS

-- Unless is is specifically 'False', it's true
if exists (select * from ConfigurationInfo where [Name] = 'EnableExecutionLogging' and [Value] like 'False')
begin
return
end

Declare @ReportID uniqueidentifier
select @ReportID = ItemID from Catalog with (nolock) where Path = @Report

insert into ExecutionLog
(InstanceName, ReportID, UserName, RequestType, [Format], Parameters, TimeStart, TimeEnd, TimeDataRetrieval, TimeProcessing, TimeRendering, Source, Status, ByteCount, [RowCount])
Values
(@InstanceName, @ReportID, @UserName, @RequestType, @Format, @Parameters, @TimeStart, @TimeEnd, @TimeDataRetrieval, @TimeProcessing, @TimeRendering, @Source, @Status, @ByteCount, @RowCount)

GO
GRANT EXECUTE ON [dbo].[AddExecutionLogEntry] TO RSExecRole
GO


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ExpireExecutionLogEntries]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[ExpireExecutionLogEntries]
GO

CREATE PROCEDURE [dbo].[ExpireExecutionLogEntries]
AS

-- -1 means no expiration
if exists (select * from ConfigurationInfo where [Name] = 'ExecutionLogDaysKept' and CAST(CAST(Value as nvarchar) as integer) = -1)
begin
return
end

delete from ExecutionLog 
where DateDiff(day, TimeStart, getdate()) >= (select CAST(CAST(Value as nvarchar) as integer) from ConfigurationInfo where [Name] = 'ExecutionLogDaysKept')

GO
GRANT EXECUTE ON [dbo].[ExpireExecutionLogEntries] TO RSExecRole
GO



if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetUserIDBySid]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetUserIDBySid]
GO

-- looks up any user name by its SID, if not it creates a regular user
CREATE PROCEDURE [dbo].[GetUserIDBySid]
@UserSid varbinary(85),
@UserName nvarchar(260),
@AuthType int,
@UserID uniqueidentifier OUTPUT
AS
SELECT @UserID = (SELECT UserID FROM Users WHERE Sid = @UserSid AND AuthType = @AuthType)
IF @UserID IS NULL
   BEGIN
      SET @UserID = newid()
      INSERT INTO Users
      (UserID, Sid, UserType, AuthType, UserName)
      VALUES 
      (@UserID, @UserSid, 0, @AuthType, @UserName)
   END 
GO
GRANT EXECUTE ON [dbo].[GetUserIDBySid] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetUserIDByName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetUserIDByName]
GO

-- looks up any user name by its User Name, if not it creates a regular user
CREATE PROCEDURE [dbo].[GetUserIDByName]
@UserName nvarchar(260),
@AuthType int,
@UserID uniqueidentifier OUTPUT
AS
SELECT @UserID = (SELECT UserID FROM Users WHERE UserName = @UserName AND AuthType = @AuthType)
IF @UserID IS NULL
   BEGIN
      SET @UserID = newid()
      INSERT INTO Users
      (UserID, Sid, UserType, AuthType, UserName)
      VALUES 
      (@UserID, NULL, 0,    @AuthType, @UserName)
   END 
GO
GRANT EXECUTE ON [dbo].[GetUserIDByName] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetUserID]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetUserID]
GO

-- looks up any user name, if not it creates a regular user - uses Sid
CREATE PROCEDURE [dbo].[GetUserID]
@UserSid varbinary(85) = NULL,
@UserName nvarchar(260),
@AuthType int,
@UserID uniqueidentifier OUTPUT
AS
    IF @AuthType = 1 -- Windows
    BEGIN
        EXEC GetUserIDBySid @UserSid, @UserName, @AuthType, @UserID OUTPUT
    END
    ELSE
    BEGIN
        EXEC GetUserIDByName @UserName, @AuthType, @UserID OUTPUT
    END
GO

GRANT EXECUTE ON [dbo].[GetUserID] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetPrincipalID]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetPrincipalID]
GO

-- looks up a principal, if not there looks up regular users and turns them into principals
-- if not, it creates a principal
CREATE PROCEDURE [dbo].[GetPrincipalID]
@UserSid varbinary(85) = NULL,
@UserName nvarchar(260),
@AuthType int,
@UserID uniqueidentifier OUTPUT
AS
-- windows auth
IF @AuthType = 1
BEGIN
    -- is this a principal?
    SELECT @UserID = (SELECT UserID FROM Users WHERE Sid = @UserSid AND UserType = 1 AND AuthType = @AuthType)
END
ELSE
BEGIN
    -- is this a principal?
    SELECT @UserID = (SELECT UserID FROM Users WHERE UserName = @UserName AND UserType = 1 AND AuthType = @AuthType)
END
IF @UserID IS NULL
   BEGIN
        IF @AuthType = 1 -- Windows
        BEGIN
            -- Is this a regular user
            SELECT @UserID = (SELECT UserID FROM Users WHERE Sid = @UserSid AND UserType = 0 AND AuthType = @AuthType)
        END
        ELSE
        BEGIN
            -- Is this a regular user
            SELECT @UserID = (SELECT UserID FROM Users WHERE UserName = @UserName AND UserType = 0 AND AuthType = @AuthType)
        END
      -- No, create a new principal
      IF @UserID IS NULL
         BEGIN
            SET @UserID = newid()
            INSERT INTO Users
            (UserID, Sid,   UserType, AuthType, UserName)
            VALUES 
            (@UserID, @UserSid, 1,    @AuthType, @UserName)
         END 
      ELSE
         BEGIN
             UPDATE Users SET UserType = 1 WHERE UserID = @UserID
         END
    END
GO
GRANT EXECUTE ON [dbo].[GetPrincipalID] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CreateSubscription]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CreateSubscription]
GO

CREATE PROCEDURE [dbo].[CreateSubscription]
@id uniqueidentifier,
@Locale nvarchar (128),
@Report_Name nvarchar (425),
@OwnerSid varbinary (85) = NULL,
@OwnerName nvarchar(260),
@OwnerAuthType int,
@DeliveryExtension nvarchar (260) = NULL,
@InactiveFlags int,
@ExtensionSettings ntext = NULL,
@ModifiedBySid varbinary (85) = NULL,
@ModifiedByName nvarchar(260),
@ModifiedByAuthType int,
@ModifiedDate datetime,
@Description nvarchar(512) = NULL,
@LastStatus nvarchar(260) = NULL,
@EventType nvarchar(260),
@MatchData ntext = NULL,
@Parameters ntext = NULL,
@DataSettings ntext = NULL,
@Version int

AS

-- Create a subscription with the given data.  The name must match a name in the
-- Catalog table and it must be a report type (2) or linked report (4)

DECLARE @Report_OID uniqueidentifier
DECLARE @OwnerID uniqueidentifier
DECLARE @ModifiedByID uniqueidentifier
DECLARE @TempDeliveryID uniqueidentifier

--Get the report id for this subscription
select @Report_OID = (select [ItemID] from [Catalog] where [Catalog].[Path] = @Report_Name and ([Catalog].[Type] = 2 or [Catalog].[Type] = 4))

EXEC GetUserID @OwnerSid, @OwnerName, @OwnerAuthType, @OwnerID OUTPUT
EXEC GetUserID @ModifiedBySid, @ModifiedByName, @ModifiedByAuthType, @ModifiedByID OUTPUT

if (@Report_OID is NULL)
begin
RAISERROR('Report Not Found', 16, 1)
return
end

Insert into Subscriptions
    (
        [SubscriptionID], 
        [OwnerID],
        [Report_OID], 
        [Locale],
        [DeliveryExtension],
        [InactiveFlags],
        [ExtensionSettings],
        [ModifiedByID],
        [ModifiedDate],
        [Description],
        [LastStatus],
        [EventType],
        [MatchData],
        [LastRunTime],
        [Parameters],
        [DataSettings],
    [Version]
    )
values
    (@id, @OwnerID, @Report_OID, @Locale, @DeliveryExtension, @InactiveFlags, @ExtensionSettings, @ModifiedByID, @ModifiedDate,
     @Description, @LastStatus, @EventType, @MatchData, NULL, @Parameters, @DataSettings, @Version)
GO
GRANT EXECUTE ON [dbo].[CreateSubscription] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DeliveryRemovedInactivateSubscription]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[DeliveryRemovedInactivateSubscription]
GO

CREATE PROCEDURE [dbo].[DeliveryRemovedInactivateSubscription] 
@DeliveryExtension nvarchar(260),
@Status nvarchar(260)
AS
update 
    Subscriptions
set
    [DeliveryExtension] = '',
    [InactiveFlags] = [InactiveFlags] | 1, -- Delivery Provider Removed Flag == 1
    [LastStatus] = @Status
where
    [DeliveryExtension] = @DeliveryExtension
GO

GRANT EXECUTE ON [dbo].[DeliveryRemovedInactivateSubscription] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DeleteSubscription]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[DeleteSubscription]
GO

CREATE PROCEDURE [dbo].[DeleteSubscription] 
@SubscriptionID uniqueidentifier
AS
-- Delete the given subscription
delete from [Subscriptions] where [SubscriptionID] = @SubscriptionID
GO

GRANT EXECUTE ON [dbo].[DeleteSubscription] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetSubscription]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetSubscription]
GO

CREATE PROCEDURE [dbo].[GetSubscription]
@SubscriptionID uniqueidentifier
AS

-- Grab all of the-- subscription properties given a id 
select 
        S.[SubscriptionID],
        S.[Report_OID],
        S.[Locale],
        S.[InactiveFlags],
        S.[DeliveryExtension], 
        S.[ExtensionSettings],
        SUSER_SNAME(Modified.[Sid]), 
        Modified.[UserName],
        S.[ModifiedDate], 
        S.[Description],
        S.[LastStatus],
        S.[EventType],
        S.[MatchData],
        S.[Parameters],
        S.[DataSettings],
        A.[TotalNotifications],
        A.[TotalSuccesses],
        A.[TotalFailures],
        SUSER_SNAME(Owner.[Sid]),
        Owner.[UserName],
        CAT.[Path],
        S.[LastRunTime],
        CAT.[Type],
        SD.NtSecDescPrimary,
        S.[Version],
        Owner.[AuthType]
from
    [Subscriptions] S inner join [Catalog] CAT on S.[Report_OID] = CAT.[ItemID]
    inner join [Users] Owner on S.OwnerID = Owner.UserID
    inner join [Users] Modified on S.ModifiedByID = Modified.UserID
    left outer join [SecData] SD on CAT.PolicyID = SD.PolicyID AND SD.AuthType = Owner.AuthType
    left outer join [ActiveSubscriptions] A with (NOLOCK) on S.[SubscriptionID] = A.[SubscriptionID]
where
    S.[SubscriptionID] = @SubscriptionID
GO
GRANT EXECUTE ON [dbo].[GetSubscription] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ListSubscriptionsUsingDataSource]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[ListSubscriptionsUsingDataSource]
GO

CREATE PROCEDURE [dbo].[ListSubscriptionsUsingDataSource]
@DataSourceName nvarchar(450)
AS
select 
    S.[SubscriptionID],
    S.[Report_OID],
    S.[Locale],
    S.[InactiveFlags],
    S.[DeliveryExtension], 
    S.[ExtensionSettings],
    SUSER_SNAME(Modified.[Sid]),
    Modified.[UserName],
    S.[ModifiedDate], 
    S.[Description],
    S.[LastStatus],
    S.[EventType],
    S.[MatchData],
    S.[Parameters],
    S.[DataSettings],
    A.[TotalNotifications],
    A.[TotalSuccesses],
    A.[TotalFailures],
    SUSER_SNAME(Owner.[Sid]),
    Owner.[UserName],
    CAT.[Path],
    S.[LastRunTime],
    CAT.[Type],
    SD.NtSecDescPrimary,
    S.[Version],
    Owner.[AuthType]
from
    [DataSource] DS inner join Catalog C on C.ItemID = DS.Link
    inner join Subscriptions S on S.[SubscriptionID] = DS.[SubscriptionID]
    inner join [Catalog] CAT on S.[Report_OID] = CAT.[ItemID]
    inner join [Users] Owner on S.OwnerID = Owner.UserID
    inner join [Users] Modified on S.ModifiedByID = Modified.UserID
    left join [SecData] SD on SD.[PolicyID] = CAT.[PolicyID] AND SD.AuthType = Owner.AuthType
    left outer join [ActiveSubscriptions] A with (NOLOCK) on S.[SubscriptionID] = A.[SubscriptionID]
where 
    C.Path = @DataSourceName 
GO
GRANT EXECUTE ON [dbo].[ListSubscriptionsUsingDataSource] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[UpdateSubscriptionStatus]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[UpdateSubscriptionStatus]
GO

CREATE PROCEDURE [dbo].[UpdateSubscriptionStatus]
@SubscriptionID uniqueidentifier,
@Status nvarchar(260)
AS

update Subscriptions set
        [LastStatus] = @Status
where
    [SubscriptionID] = @SubscriptionID

GO 
GRANT EXECUTE ON [dbo].[UpdateSubscriptionStatus] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[UpdateSubscription]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[UpdateSubscription]
GO

CREATE PROCEDURE [dbo].[UpdateSubscription]
@id uniqueidentifier,
@Locale nvarchar(260),
@OwnerSid varbinary(85) = NULL,
@OwnerName nvarchar(260),
@OwnerAuthType int,
@DeliveryExtension nvarchar(260),
@InactiveFlags int,
@ExtensionSettings ntext = NULL,
@ModifiedBySid varbinary(85) = NULL, 
@ModifiedByName nvarchar(260),
@ModifiedByAuthType int,
@ModifiedDate datetime,
@Description nvarchar(512) = NULL,
@LastStatus nvarchar(260) = NULL,
@EventType nvarchar(260),
@MatchData ntext = NULL,
@Parameters ntext = NULL,
@DataSettings ntext = NULL,
@Version int
AS
-- Update a subscription's information.
DECLARE @ModifiedByID uniqueidentifier
DECLARE @OwnerID uniqueidentifier

EXEC GetUserID @ModifiedBySid, @OwnerName,@OwnerAuthType, @ModifiedByID OUTPUT
EXEC GetUserID @OwnerSid, @ModifiedByName, @ModifiedByAuthType, @OwnerID OUTPUT

-- Make sure there is a valid provider
update Subscriptions set
        [DeliveryExtension] = @DeliveryExtension,
        [Locale] = @Locale,
        [OwnerID] = @OwnerID,
        [InactiveFlags] = @InactiveFlags,
        [ExtensionSettings] = @ExtensionSettings,
        [ModifiedByID] = @ModifiedByID,
        [ModifiedDate] = @ModifiedDate,
        [Description] = @Description,
        [LastStatus] = @LastStatus,
        [EventType] = @EventType,
        [MatchData] = @MatchData,
        [Parameters] = @Parameters,
        [DataSettings] = @DataSettings,
    [Version] = @Version
where
    [SubscriptionID] = @id
GO
GRANT EXECUTE ON [dbo].[UpdateSubscription] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[InvalidateSubscription]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[InvalidateSubscription]
GO

CREATE PROCEDURE [dbo].[InvalidateSubscription] 
@SubscriptionID uniqueidentifier,
@Flags int,
@LastStatus nvarchar(260)
AS

-- Mark all subscriptions for this report as inactive for the given flags
update 
    Subscriptions 
set 
    [InactiveFlags] = S.[InactiveFlags] | @Flags,
    [LastStatus] = @LastStatus
from 
    Subscriptions S 
where 
    SubscriptionID = @SubscriptionID
GO
GRANT EXECUTE ON [dbo].[InvalidateSubscription] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CleanNotificationRecords]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CleanNotificationRecords]
GO

CREATE PROCEDURE [dbo].[CleanNotificationRecords] 
@MaxAgeMinutes int
AS
-- Reset all notifications which have been add over n minutes ago
Update [Notifications] set [ProcessStart] = NULL, [ProcessHeartbeat] = NULL, [Attempt] = 1
where [NotificationID] in
   ( SELECT [NotificationID]
     FROM [Notifications]
     WHERE [ProcessHeartbeat] < DATEADD(minute, -(@MaxAgeMinutes), GETUTCDATE()) and [Attempt] is NULL )

Update [Notifications] set [ProcessStart] = NULL, [ProcessHeartbeat] = NULL, [Attempt] = [Attempt] + 1
where [NotificationID] in
   ( SELECT [NotificationID]
     FROM [Notifications]
     WHERE [ProcessHeartbeat] < DATEADD(minute, -(@MaxAgeMinutes), GETUTCDATE()) and [Attempt] is not NULL )
GO
GRANT EXECUTE ON [dbo].[CleanNotificationRecords] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CreateSnapShotNotifications]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CreateSnapShotNotifications]
GO

CREATE PROCEDURE [dbo].[CreateSnapShotNotifications] 
@HistoryID uniqueidentifier,
@LastRunTime datetime
AS
update [Subscriptions]
set
    [LastRunTime] = @LastRunTime
from
    History SS inner join [Subscriptions] S on S.[Report_OID] = SS.[ReportID]
where 
    SS.[HistoryID] = @HistoryID and S.EventType = 'ReportHistorySnapshotCreated' and InactiveFlags = 0


-- Find all valid subscriptions for the given report and create a new notification row for
-- each subscription
insert into [Notifications] 
    (
    [NotificationID], 
    [SubscriptionID],
    [ActivationID],
    [ReportID],
    [SnapShotDate],
    [ExtensionSettings],
    [Locale],
    [Parameters],
    [NotificationEntered],
    [SubscriptionLastRunTime],
    [DeliveryExtension],
    [SubscriptionOwnerID],
    [IsDataDriven],
    [Version]
    ) 
select 
    NewID(),
    S.[SubscriptionID],
    NULL,
    S.[Report_OID],
    NULL,
    S.[ExtensionSettings],
    S.[Locale],
    S.[Parameters],
    GETUTCDATE(), 
    S.[LastRunTime],
    S.[DeliveryExtension],
    S.[OwnerID],
    0,
    S.[Version]
from 
    [Subscriptions] S with (READPAST) inner join History H on S.[Report_OID] = H.[ReportID]
where 
    H.[HistoryID] = @HistoryID and S.EventType = 'ReportHistorySnapshotCreated' and InactiveFlags = 0 and
    S.[DataSettings] is null

-- Create any data driven subscription by creating a data driven event
insert into [Event]
    (
    [EventID],
    [EventType],
    [EventData],
    [TimeEntered]
    )
select
    NewID(),
    'DataDrivenSubscription',
    S.SubscriptionID,
    GETUTCDATE()
from
    [Subscriptions] S with (READPAST) inner join History H on S.[Report_OID] = H.[ReportID]
where 
    H.[HistoryID] = @HistoryID and S.EventType = 'ReportHistorySnapshotCreated' and InactiveFlags = 0 and
    S.[DataSettings] is not null
    
GO
GRANT EXECUTE ON [dbo].[CreateSnapShotNotifications] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CreateDataDrivenNotification]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CreateDataDrivenNotification]
GO

CREATE PROCEDURE [dbo].[CreateDataDrivenNotification]
@SubscriptionID uniqueidentifier,
@ActiveationID uniqueidentifier,
@ReportID uniqueidentifier,
@ExtensionSettings ntext,
@Locale nvarchar(128),
@Parameters ntext,
@LastRunTime datetime,
@DeliveryExtension nvarchar(260),
@OwnerSid varbinary (85) = null,
@OwnerName nvarchar(260),
@OwnerAuthType int,
@Version int
AS

declare @OwnerID as uniqueidentifier

EXEC GetUserID @OwnerSid,@OwnerName, @OwnerAuthType, @OwnerID OUTPUT

-- Insert into the notification table
insert into [Notifications] 
    (
    [NotificationID], 
    [SubscriptionID],
    [ActivationID],
    [ReportID],
    [SnapShotDate],
    [ExtensionSettings],
    [Locale],
    [Parameters],
    [NotificationEntered],
    [SubscriptionLastRunTime],
    [DeliveryExtension],
    [SubscriptionOwnerID],
    [IsDataDriven],
    [Version]
    )
values
    (
    NewID(),
    @SubscriptionID,
    @ActiveationID,
    @ReportID,
    NULL,
    @ExtensionSettings,
    @Locale,
    @Parameters,
    GETUTCDATE(),
    @LastRunTime,
    @DeliveryExtension,
    @OwnerID,
    1,
    @Version
    )

GO
GRANT EXECUTE ON [dbo].[CreateDataDrivenNotification] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CreateNewActiveSubscription]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CreateNewActiveSubscription]
GO

CREATE PROCEDURE [dbo].[CreateNewActiveSubscription]
@ActiveID uniqueidentifier,
@SubscriptionID uniqueidentifier
AS


-- Insert into the activesubscription table
insert into [ActiveSubscriptions] 
    (
    [ActiveID], 
    [SubscriptionID],
    [TotalNotifications],
    [TotalSuccesses],
    [TotalFailures]
    )
values
    (
    @ActiveID,
    @SubscriptionID,
    NULL,
    0,
    0
    )


GO
GRANT EXECUTE ON [dbo].[CreateNewActiveSubscription] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[UpdateActiveSubscription]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[UpdateActiveSubscription]
GO

CREATE PROCEDURE [dbo].[UpdateActiveSubscription]
@ActiveID uniqueidentifier,
@TotalNotifications int = NULL,
@TotalSuccesses int = NULL,
@TotalFailures int = NULL
AS

if @TotalNotifications is not NULL
begin
    update ActiveSubscriptions set TotalNotifications = @TotalNotifications where ActiveID = @ActiveID
end

if @TotalSuccesses is not NULL
begin
    update ActiveSubscriptions set TotalSuccesses = @TotalSuccesses where ActiveID = @ActiveID
end

if @TotalFailures is not NULL
begin
    update ActiveSubscriptions set TotalFailures = @TotalFailures where ActiveID = @ActiveID
end

GO
GRANT EXECUTE ON [dbo].[UpdateActiveSubscription] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DeleteActiveSubscription]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[DeleteActiveSubscription]
GO

CREATE PROCEDURE [dbo].[DeleteActiveSubscription]
@ActiveID uniqueidentifier
AS

delete from ActiveSubscriptions where ActiveID = @ActiveID

GO
GRANT EXECUTE ON [dbo].[DeleteActiveSubscription] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetAndHoldLockActiveSubscription]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetAndHoldLockActiveSubscription]
GO

CREATE PROCEDURE [dbo].[GetAndHoldLockActiveSubscription]
@ActiveID uniqueidentifier
AS

select 
    TotalNotifications, 
    TotalSuccesses, 
    TotalFailures 
from 
    ActiveSubscriptions with (XLOCK)
where
    ActiveID = @ActiveID

GO
GRANT EXECUTE ON [dbo].[GetAndHoldLockActiveSubscription] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CreateCacheUpdateNotifications]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CreateCacheUpdateNotifications]
GO

CREATE PROCEDURE [dbo].[CreateCacheUpdateNotifications] 
@ReportID uniqueidentifier,
@LastRunTime datetime
AS

update [Subscriptions]
set
    [LastRunTime] = @LastRunTime
from
    [Subscriptions] S 
where 
    S.[Report_OID] = @ReportID and S.EventType = 'SnapshotUpdated' and InactiveFlags = 0


-- Find all valid subscriptions for the given report and create a new notification row for
-- each subscription
insert into [Notifications] 
    (
    [NotificationID], 
    [SubscriptionID],
    [ActivationID],
    [ReportID],
    [SnapShotDate],
    [ExtensionSettings],
    [Locale],
    [Parameters],
    [NotificationEntered],
    [SubscriptionLastRunTime],
    [DeliveryExtension],
    [SubscriptionOwnerID],
    [IsDataDriven],
    [Version]
    ) 
select 
    NewID(),
    S.[SubscriptionID],
    NULL,
    S.[Report_OID],
    NULL,
    S.[ExtensionSettings],
    S.[Locale],
    S.[Parameters],
    GETUTCDATE(), 
    S.[LastRunTime],
    S.[DeliveryExtension],
    S.[OwnerID],
    0,
    S.[Version]
from 
    [Subscriptions] S  inner join Catalog C on S.[Report_OID] = C.[ItemID]
where 
    C.[ItemID] = @ReportID and S.EventType = 'SnapshotUpdated' and InactiveFlags = 0 and
    S.[DataSettings] is null

-- Create any data driven subscription by creating a data driven event
insert into [Event]
    (
    [EventID],
    [EventType],
    [EventData],
    [TimeEntered]
    )
select
    NewID(),
    'DataDrivenSubscription',
    S.SubscriptionID,
    GETUTCDATE()
from
    [Subscriptions] S  inner join Catalog C on S.[Report_OID] = C.[ItemID]
where 
    C.[ItemID] = @ReportID and S.EventType = 'SnapshotUpdated' and InactiveFlags = 0 and
    S.[DataSettings] is not null
    
GO
GRANT EXECUTE ON [dbo].[CreateCacheUpdateNotifications] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetCacheSchedule]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetCacheSchedule]
GO

CREATE PROCEDURE [dbo].[GetCacheSchedule] 
@ReportID uniqueidentifier
AS
SELECT
    S.[ScheduleID],
    S.[Name],
    S.[StartDate], 
    S.[Flags],
    S.[NextRunTime],
    S.[LastRunTime], 
    S.[EndDate], 
    S.[RecurrenceType],
    S.[MinutesInterval],
    S.[DaysInterval],
    S.[WeeksInterval],
    S.[DaysOfWeek], 
    S.[DaysOfMonth], 
    S.[Month], 
    S.[MonthlyWeek], 
    S.[State], 
    S.[LastRunStatus],
    S.[ScheduledRunTimeout],
    S.[EventType],
    S.[EventData],
    S.[Type],
    S.[Path],
    SUSER_SNAME(Owner.[Sid]),
    Owner.[UserName],
    Owner.[AuthType],
    RS.ReportAction
FROM
    Schedule S with (XLOCK) inner join ReportSchedule RS on S.ScheduleID = RS.ScheduleID
    inner join [Users] Owner on S.[CreatedById] = Owner.[UserID]
WHERE
    (RS.ReportAction = 1 or RS.ReportAction = 3) and -- 1 == UpdateCache, 3 == Invalidate cache
    RS.[ReportID] = @ReportID
GO
GRANT EXECUTE ON [dbo].[GetCacheSchedule] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DeleteNotification]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[DeleteNotification]
GO

CREATE PROCEDURE [dbo].[DeleteNotification] 
@ID uniqueidentifier
AS
delete from [Notifications] where [NotificationID] = @ID
GO
GRANT EXECUTE ON [dbo].[DeleteNotification] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SetNotificationAttempt]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SetNotificationAttempt]
GO

CREATE PROCEDURE [dbo].[SetNotificationAttempt] 
@Attempt int,
@SecondsToAdd int,
@NotificationID uniqueidentifier
AS

update 
    [Notifications] 
set 
    [ProcessStart] = NULL, 
    [Attempt] = @Attempt, 
    [ProcessAfter] = DateAdd(second, @SecondsToAdd, GetUtcDate())
where
    [NotificationID] = @NotificationID
GO
GRANT EXECUTE ON [dbo].[SetNotificationAttempt] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CreateTimeBasedSubscriptionNotification]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CreateTimeBasedSubscriptionNotification]
GO

CREATE PROCEDURE [dbo].[CreateTimeBasedSubscriptionNotification]
@SubscriptionID uniqueidentifier,
@LastRunTime datetime
as

insert into [Notifications] 
    (
    [NotificationID], 
    [SubscriptionID],
    [ActivationID],
    [ReportID],
    [SnapShotDate],
    [ExtensionSettings],
    [Locale],
    [Parameters],
    [NotificationEntered],
    [SubscriptionLastRunTime],
    [DeliveryExtension],
    [SubscriptionOwnerID],
    [IsDataDriven],
    [Version]
    ) 
select 
    NewID(),
    S.[SubscriptionID],
    NULL,
    S.[Report_OID],
    NULL,
    S.[ExtensionSettings],
    S.[Locale],
    S.[Parameters],
    GETUTCDATE(), 
    @LastRunTime,
    S.[DeliveryExtension],
    S.[OwnerID],
    0,
    S.[Version]
from 
    [Subscriptions] S 
where 
    S.[SubscriptionID] = @SubscriptionID and InactiveFlags = 0 and
    S.[DataSettings] is null


-- Create any data driven subscription by creating a data driven event
insert into [Event]
    (
    [EventID],
    [EventType],
    [EventData],
    [TimeEntered]
    )
select
    NewID(),
    'DataDrivenSubscription',
    S.SubscriptionID,
    GETUTCDATE()
from
    [Subscriptions] S 
where 
    S.[SubscriptionID] = @SubscriptionID and InactiveFlags = 0 and
    S.[DataSettings] is not null

update [Subscriptions]
set
    [LastRunTime] = @LastRunTime
where 
    [SubscriptionID] = @SubscriptionID and InactiveFlags = 0

GO
GRANT EXECUTE ON [dbo].[CreateTimeBasedSubscriptionNotification] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DeleteTimeBasedSubscriptionSchedule]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[DeleteTimeBasedSubscriptionSchedule]
GO

CREATE PROCEDURE [dbo].[DeleteTimeBasedSubscriptionSchedule]
@SubscriptionID as uniqueidentifier
as

delete ReportSchedule from ReportSchedule RS inner join Subscriptions S on S.[SubscriptionID] = RS.[SubscriptionID]
where
    S.[SubscriptionID] = @SubscriptionID
GO

GRANT EXECUTE ON [dbo].[DeleteTimeBasedSubscriptionSchedule] TO RSExecRole
GO

--------------------------------------------------
------------- Provider Info

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ListUsedDeliveryProviders]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[ListUsedDeliveryProviders]
GO

CREATE PROCEDURE [dbo].[ListUsedDeliveryProviders] 
AS
select distinct [DeliveryExtension] from Subscriptions where [DeliveryExtension] <> ''
GO
GRANT EXECUTE ON [dbo].[ListUsedDeliveryProviders] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id('[dbo].[AddBatchRecord]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[AddBatchRecord]
GO

CREATE PROCEDURE [dbo].[AddBatchRecord]
@BatchID uniqueidentifier,
@UserName nvarchar(260),
@Action varchar(32),
@Item nvarchar(425) = NULL,
@Parent nvarchar(425) = NULL,
@Param nvarchar(425) = NULL,
@BoolParam bit = NULL,
@Content image = NULL,
@Properties ntext = NULL
AS

IF @Action='BatchStart' BEGIN
   INSERT
   INTO [Batch] (BatchID, AddedOn, [Action], Item, Parent, Param, BoolParam, Content, Properties)
   VALUES (@BatchID, GETUTCDATE(), @Action, @UserName, @Parent, @Param, @BoolParam, @Content, @Properties)
END ELSE BEGIN
   IF EXISTS (SELECT * FROM Batch WHERE BatchID = @BatchID AND [Action] = 'BatchStart' AND Item = @UserName) BEGIN
      INSERT
      INTO [Batch] (BatchID, AddedOn, [Action], Item, Parent, Param, BoolParam, Content, Properties)
      VALUES (@BatchID, GETUTCDATE(), @Action, @Item, @Parent, @Param, @BoolParam, @Content, @Properties)
   END ELSE BEGIN
      RAISERROR( 'Batch does not exist', 16, 1 )
   END
END
GO
GRANT EXECUTE ON [dbo].[AddBatchRecord] TO RSExecRole
GO

if exists (select * from sysobjects where id = object_id('[dbo].[GetBatchRecords]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetBatchRecords]
GO

CREATE PROCEDURE [dbo].[GetBatchRecords]
@BatchID uniqueidentifier
AS
SELECT [Action], Item, Parent, Param, BoolParam, Content, Properties
FROM [Batch]
WHERE BatchID = @BatchID
ORDER BY AddedOn
GO
GRANT EXECUTE ON [dbo].[GetBatchRecords] TO RSExecRole
GO

if exists (select * from sysobjects where id = object_id('[dbo].[DeleteBatchRecords]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[DeleteBatchRecords]
GO

CREATE PROCEDURE [dbo].[DeleteBatchRecords]
@BatchID uniqueidentifier
AS
DELETE
FROM [Batch]
WHERE BatchID = @BatchID
GO
GRANT EXECUTE ON [dbo].[DeleteBatchRecords] TO RSExecRole
GO

if exists (select * from sysobjects where id = object_id('[dbo].[CleanBatchRecords]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CleanBatchRecords]
GO

CREATE PROCEDURE [dbo].[CleanBatchRecords]
@MaxAgeMinutes int
AS
DELETE FROM [Batch]
where BatchID in
   ( SELECT BatchID
     FROM [Batch]
     WHERE AddedOn < DATEADD(minute, -(@MaxAgeMinutes), GETUTCDATE()) )
GO
GRANT EXECUTE ON [dbo].[CleanBatchRecords] TO RSExecRole
GO

if exists (select * from sysobjects where id = object_id('[dbo].[CleanOrphanedPolicies]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CleanOrphanedPolicies]
GO

-- Cleaning orphan policies
CREATE PROCEDURE [dbo].[CleanOrphanedPolicies]
AS
DELETE
   [Policies]
WHERE
   [Policies].[PolicyFlag] = 0
   AND
   NOT EXISTS (SELECT ItemID FROM [Catalog] WHERE [Catalog].[PolicyID] = [Policies].[PolicyID])

DELETE
   [Policies]
FROM
   [Policies]
   INNER JOIN [ModelItemPolicy] ON [ModelItemPolicy].[PolicyID] = [Policies].[PolicyID]
WHERE
   NOT EXISTS (SELECT ItemID
               FROM [Catalog] 
               WHERE [Catalog].[ItemID] = [ModelItemPolicy].[CatalogItemID])

GO
GRANT EXECUTE ON [dbo].[CleanOrphanedPolicies] TO RSExecRole
GO

--------------------------------------------------
------------- Snapshot manipulation

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[IncreaseTransientSnapshotRefcount]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[IncreaseTransientSnapshotRefcount]
GO

CREATE PROCEDURE [dbo].[IncreaseTransientSnapshotRefcount]
@SnapshotDataID as uniqueidentifier,
@IsPermanentSnapshot as bit,
@ExpirationMinutes as int
AS

DECLARE @soon AS datetime
SET @soon = DATEADD(n, @ExpirationMinutes, GETDATE())

if @IsPermanentSnapshot = 1
BEGIN
   UPDATE SnapshotData
   SET ExpirationDate = @soon, TransientRefcount = TransientRefcount + 1
   WHERE SnapshotDataID = @SnapshotDataID
END ELSE BEGIN
   UPDATE [ReportServerTempDB].dbo.SnapshotData
   SET ExpirationDate = @soon, TransientRefcount = TransientRefcount + 1
   WHERE SnapshotDataID = @SnapshotDataID
END
GO

GRANT EXECUTE ON [dbo].[IncreaseTransientSnapshotRefcount] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DecreaseTransientSnapshotRefcount]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[DecreaseTransientSnapshotRefcount]
GO

CREATE PROCEDURE [dbo].[DecreaseTransientSnapshotRefcount]
@SnapshotDataID as uniqueidentifier,
@IsPermanentSnapshot as bit
AS

if @IsPermanentSnapshot = 1
BEGIN
   UPDATE SnapshotData
   SET TransientRefcount = TransientRefcount - 1
   WHERE SnapshotDataID = @SnapshotDataID
END ELSE BEGIN
   UPDATE [ReportServerTempDB].dbo.SnapshotData
   SET TransientRefcount = TransientRefcount - 1
   WHERE SnapshotDataID = @SnapshotDataID
END
GO

GRANT EXECUTE ON [dbo].[DecreaseTransientSnapshotRefcount] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[MarkSnapshotAsDependentOnUser]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[MarkSnapshotAsDependentOnUser]
GO

CREATE PROCEDURE [dbo].[MarkSnapshotAsDependentOnUser]
@SnapshotDataID as uniqueidentifier,
@IsPermanentSnapshot as bit
AS

if @IsPermanentSnapshot = 1
BEGIN
   UPDATE SnapshotData
   SET DependsOnUser = 1
   WHERE SnapshotDataID = @SnapshotDataID
END ELSE BEGIN
   UPDATE [ReportServerTempDB].dbo.SnapshotData
   SET DependsOnUser = 1
   WHERE SnapshotDataID = @SnapshotDataID
END
GO

GRANT EXECUTE ON [dbo].[MarkSnapshotAsDependentOnUser] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SetSnapshotChunksVersion]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SetSnapshotChunksVersion]
GO

CREATE PROCEDURE [dbo].[SetSnapshotChunksVersion]
@SnapshotDataID as uniqueidentifier,
@IsPermanentSnapshot as bit,
@Version as smallint
AS

if @IsPermanentSnapshot = 1
BEGIN
   if @Version > 0
   BEGIN
      UPDATE ChunkData
      SET Version = @Version
      WHERE SnapshotDataID = @SnapshotDataID
   END ELSE BEGIN
      UPDATE ChunkData
      SET Version = Version
      WHERE SnapshotDataID = @SnapshotDataID
   END   
END ELSE BEGIN
   if @Version > 0
   BEGIN
      UPDATE [ReportServerTempDB].dbo.ChunkData
      SET Version = @Version
      WHERE SnapshotDataID = @SnapshotDataID
   END ELSE BEGIN
      UPDATE [ReportServerTempDB].dbo.ChunkData
      SET Version = Version
      WHERE SnapshotDataID = @SnapshotDataID
   END   
END
GO

GRANT EXECUTE ON [dbo].[SetSnapshotChunksVersion] TO RSExecRole
GO


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[LockSnapshotForUpgrade]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[LockSnapshotForUpgrade]
GO

CREATE PROCEDURE [dbo].[LockSnapshotForUpgrade]
@SnapshotDataID as uniqueidentifier,
@IsPermanentSnapshot as bit
AS
if @IsPermanentSnapshot = 1
BEGIN
   SELECT ChunkName from ChunkData with (XLOCK)
   WHERE SnapshotDataID = @SnapshotDataID
END ELSE BEGIN
   SELECT ChunkName from [ReportServerTempDB].dbo.ChunkData with (XLOCK)
   WHERE SnapshotDataID = @SnapshotDataID
END
GO

GRANT EXECUTE ON [dbo].[LockSnapshotForUpgrade] TO RSExecRole
GO


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[InsertUnreferencedSnapshot]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[InsertUnreferencedSnapshot]
GO

CREATE PROCEDURE [dbo].[InsertUnreferencedSnapshot]
@ReportID as uniqueidentifier = NULL,
@EffectiveParams as ntext = NULL,
@QueryParams as ntext = NULL,
@ParamsHash as int = NULL,
@CreatedDate as datetime,
@Description as nvarchar(512) = NULL,
@SnapshotDataID as uniqueidentifier,
@IsPermanentSnapshot as bit,
@SnapshotTimeoutMinutes as int,
@Machine as nvarchar(512) = NULL
AS
DECLARE @now datetime
SET @now = GETDATE()

IF @IsPermanentSnapshot = 1
BEGIN
   INSERT INTO SnapshotData
      (SnapshotDataID, CreatedDate, EffectiveParams, QueryParams, ParamsHash, Description, PermanentRefcount, TransientRefcount, ExpirationDate)
   VALUES
      (@SnapshotDataID, @CreatedDate, @EffectiveParams, @QueryParams, @ParamsHash, @Description, 0, 1, DATEADD(n, @SnapshotTimeoutMinutes, @now))
END ELSE BEGIN
   INSERT INTO [ReportServerTempDB].dbo.SnapshotData
      (SnapshotDataID, CreatedDate, EffectiveParams, QueryParams, ParamsHash, Description, PermanentRefcount, TransientRefcount, ExpirationDate, Machine)
   VALUES
      (@SnapshotDataID, @CreatedDate, @EffectiveParams, @QueryParams, @ParamsHash, @Description, 0, 1, DATEADD(n, @SnapshotTimeoutMinutes, @now), @Machine)
END      
GO

GRANT EXECuTE ON [dbo].[InsertUnreferencedSnapshot] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[PromoteSnapshotInfo]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[PromoteSnapshotInfo]
GO

CREATE PROCEDURE [dbo].[PromoteSnapshotInfo]
@SnapshotDataID as uniqueidentifier,
@IsPermanentSnapshot as bit,
@PageCount as int,
@HasDocMap as bit
AS

IF @IsPermanentSnapshot = 1
BEGIN
   UPDATE SnapshotData SET PageCount = @PageCount, HasDocMap = @HasDocMap
   WHERE SnapshotDataID = @SnapshotDataID
END ELSE BEGIN
   UPDATE [ReportServerTempDB].dbo.SnapshotData SET PageCount = @PageCount, HasDocMap = @HasDocMap
   WHERE SnapshotDataID = @SnapshotDataID
END      
GO

GRANT EXECUTE ON [dbo].[PromoteSnapshotInfo] TO RSExecRole
GO


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetSnapshotPromotedInfo]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetSnapshotPromotedInfo]
GO

CREATE PROCEDURE [dbo].[GetSnapshotPromotedInfo]
@SnapshotDataID as uniqueidentifier,
@IsPermanentSnapshot as bit
AS

IF @IsPermanentSnapshot = 1
BEGIN
   SELECT PageCount, HasDocMap
   FROM SnapshotData
   WHERE SnapshotDataID = @SnapshotDataID
END ELSE BEGIN
   SELECT PageCount, HasDocMap 
   FROM [ReportServerTempDB].dbo.SnapshotData
   WHERE SnapshotDataID = @SnapshotDataID
END      
GO

GRANT EXECUTE ON [dbo].[GetSnapshotPromotedInfo] TO RSExecRole
GO


if exists (select * from sysobjects where id = object_id('[dbo].[AddHistoryRecord]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[AddHistoryRecord]
GO

-- add new record to History table
CREATE PROCEDURE [dbo].[AddHistoryRecord]
@HistoryID uniqueidentifier,
@ReportID uniqueidentifier,
@SnapshotDate datetime,
@SnapshotDataID uniqueidentifier,
@SnapshotTransientRefcountChange int
AS
INSERT
INTO History (HistoryID, ReportID, SnapshotDataID, SnapshotDate)
VALUES (@HistoryID, @ReportID, @SnapshotDataID, @SnapshotDate)

IF @@ERROR = 0
BEGIN
   UPDATE SnapshotData
   -- Snapshots, when created, have transient refcount set to 1. Here create permanent reference
   -- here so we need to increase permanent refcount and decrease transient refcount. However,
   -- if it was already referenced by the execution snapshot, transient refcount was already
   -- decreased. Hence, there's a parameter @SnapshotTransientRefcountChange that is 0 or -1.
   SET PermanentRefcount = PermanentRefcount + 1, TransientRefcount = TransientRefcount + @SnapshotTransientRefcountChange
   WHERE SnapshotData.SnapshotDataID = @SnapshotDataID
END
GO
GRANT EXECUTE ON [dbo].[AddHistoryRecord] TO RSExecRole
GO

if exists (select * from sysobjects where id = object_id('[dbo].[SetHistoryLimit]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SetHistoryLimit]
GO

CREATE PROCEDURE [dbo].[SetHistoryLimit]
@Path nvarchar (425),
@SnapshotLimit int = NULL
AS
UPDATE Catalog
SET SnapshotLimit=@SnapshotLimit
WHERE Path = @Path
GO
GRANT EXECUTE ON [dbo].[SetHistoryLimit] TO RSExecRole
GO

if exists (select * from sysobjects where id = object_id('[dbo].[ListHistory]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[ListHistory]
GO

-- list all historical snapshots for a specific report
CREATE PROCEDURE [dbo].[ListHistory]
@ReportID uniqueidentifier
AS
SELECT
   S.SnapshotDate,
   (SELECT SUM(DATALENGTH( CD.Content ) ) FROM ChunkData AS CD WHERE CD.SnapshotDataID = S.SnapshotDataID )
FROM
   History AS S -- skipping intermediate table SnapshotData
WHERE
   S.ReportID = @ReportID
GO
GRANT EXECUTE ON [dbo].[ListHistory] TO RSExecRole
GO

if exists (select * from sysobjects where id = object_id('[dbo].[CleanHistoryForReport]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CleanHistoryForReport]
GO

-- delete snapshots exceeding # of snapshots. won't work if @SnapshotLimit = 0
CREATE PROCEDURE [dbo].[CleanHistoryForReport]
@SnapshotLimit int,
@ReportID uniqueidentifier
AS
DECLARE @cmd varchar(2000)
SET @cmd =
'DELETE
 FROM History
 WHERE ReportID = ''' + cast(@ReportID as varchar(40) ) + ''' and SnapshotDate <
    (SELECT MIN(SnapshotDate)
     FROM
        (SELECT TOP ' + CAST(@SnapshotLimit as varchar(20)) + ' SnapshotDate
         FROM History
         WHERE ReportID = ''' + cast(@ReportID as varchar(40) ) + '''
         ORDER BY SnapshotDate DESC
        ) AS TopSnapshots
    )'
EXEC( @cmd )
GO
GRANT EXECUTE ON [dbo].[CleanHistoryForReport] TO RSExecRole
GO

if exists (select * from sysobjects where id = object_id('[dbo].[CleanAllHistories]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CleanAllHistories]
GO

-- delete snapshots exceeding # of snapshots for the whole system
CREATE PROCEDURE [dbo].[CleanAllHistories]
@SnapshotLimit int
AS
DECLARE @cmd varchar(2000)
SET @cmd =
'DELETE
 FROM History
 WHERE HistoryID in 
    (SELECT HistoryID
     FROM History JOIN Catalog AS ReportJoinSnapshot ON ItemID = ReportID
     WHERE SnapshotLimit is NULL and SnapshotDate <
       (SELECT MIN(SnapshotDate) 
        FROM 
          (SELECT TOP ' + CAST(@SnapshotLimit as varchar(20)) + ' SnapshotDate
           FROM History AS InnerSnapshot
           WHERE InnerSnapshot.ReportID = ReportJoinSnapshot.ItemID
           ORDER BY SnapshotDate DESC
          ) AS TopSnapshots
       )
    )'
EXEC( @cmd )
GO
GRANT EXECUTE ON [dbo].[CleanAllHistories] TO RSExecRole
GO

if exists (select * from sysobjects where id = object_id('[dbo].[DeleteHistoryRecord]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[DeleteHistoryRecord]
GO

-- delete one historical snapshot
CREATE PROCEDURE [dbo].[DeleteHistoryRecord]
@ReportID uniqueidentifier,
@SnapshotDate DateTime
AS
DELETE
FROM History
WHERE ReportID = @ReportID AND SnapshotDate = @SnapshotDate
GO
GRANT EXECUTE ON [dbo].[DeleteHistoryRecord] TO RSExecRole
GO

if exists (select * from sysobjects where id = object_id('[dbo].[DeleteAllHistoryForReport]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[DeleteAllHistoryForReport]
GO

-- delete all snapshots for a report
CREATE PROCEDURE [dbo].[DeleteAllHistoryForReport]
@ReportID uniqueidentifier
AS
DELETE
FROM History
WHERE HistoryID in
   (SELECT HistoryID
    FROM History JOIN Catalog on ItemID = ReportID
    WHERE ReportID = @ReportID
   )
GO
GRANT EXECUTE ON [dbo].[DeleteAllHistoryForReport] TO RSExecRole
GO

if exists (select * from sysobjects where id = object_id('[dbo].[DeleteHistoriesWithNoPolicy]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[DeleteHistoriesWithNoPolicy]
GO

-- delete all snapshots for all reports that inherit system History policy
CREATE PROCEDURE [dbo].[DeleteHistoriesWithNoPolicy]
AS
DELETE
FROM History
WHERE HistoryID in
   (SELECT HistoryID
    FROM History JOIN Catalog on ItemID = ReportID
    WHERE SnapshotLimit is null
   )
GO
GRANT EXECUTE ON [dbo].[DeleteHistoriesWithNoPolicy] TO RSExecRole
GO


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[Get_sqlagent_job_status]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[Get_sqlagent_job_status]
GO

CREATE PROCEDURE [dbo].[Get_sqlagent_job_status]
  -- Individual job parameters
  @job_id                     UNIQUEIDENTIFIER = NULL,  -- If provided will only return info about this job
                                                        --   Note: Only @job_id or @job_name needs to be provided    
  @job_name                   sysname          = NULL,  -- If provided will only return info about this job 
  @owner_login_name           sysname          = NULL   -- If provided will only return jobs for this owner
AS
BEGIN
  DECLARE @retval           INT
  DECLARE @job_owner_sid    VARBINARY(85)
  DECLARE @is_sysadmin      INT

  SET NOCOUNT ON

  -- Remove any leading/trailing spaces from parameters (except @owner_login_name)
  SELECT @job_name         = LTRIM(RTRIM(@job_name)) 

  -- Turn [nullable] empty string parameters into NULLs
  IF (@job_name         = N'') SELECT @job_name = NULL


  -- Verify the job if supplied. This also checks if the caller has rights to view the job 
  IF ((@job_id IS NOT NULL) OR (@job_name IS NOT NULL))
  BEGIN
    EXECUTE @retval = msdb..sp_verify_job_identifiers '@job_name',
                                                      '@job_id',
                                                       @job_name OUTPUT,
                                                       @job_id   OUTPUT
    IF (@retval <> 0)
      RETURN(1) -- Failure

  END
  
  -- If the login name isn't given, set it to the job owner or the current caller 
  IF(@owner_login_name IS NULL)
  BEGIN
        
    SET @owner_login_name = (SELECT SUSER_SNAME(sj.owner_sid) FROM msdb.dbo.sysjobs sj where sj.job_id = @job_id)

    SET @is_sysadmin = ISNULL(IS_SRVROLEMEMBER(N'sysadmin', @owner_login_name), 0)

  END
  ELSE
  BEGIN
    -- Check owner
    IF (SUSER_SID(@owner_login_name) IS NULL)
    BEGIN
      RAISERROR(14262, -1, -1, '@owner_login_name', @owner_login_name)
      RETURN(1) -- Failure
    END

    --only allow sysadmin types to specify the owner
    IF ((ISNULL(IS_SRVROLEMEMBER(N'sysadmin'), 0) <> 1) AND
        (ISNULL(IS_MEMBER(N'SQLAgentAdminRole'), 0) = 1) AND
        (SUSER_SNAME() <> @owner_login_name))
    BEGIN
      --TODO: RAISERROR(14525, -1, -1)
      RETURN(1) -- Failure
    END

    SET @is_sysadmin = 0
  END


  IF (@job_id IS NOT NULL)
  BEGIN
    -- Individual job...
    EXECUTE @retval =  master.dbo.xp_sqlagent_enum_jobs @is_sysadmin, @owner_login_name, @job_id
    IF (@retval <> 0)
      RETURN(1) -- Failure

  END
  ELSE
  BEGIN
    -- Set of jobs...
    EXECUTE @retval =  master.dbo.xp_sqlagent_enum_jobs @is_sysadmin, @owner_login_name
    IF (@retval <> 0)
      RETURN(1) -- Failure

  END

  RETURN(0) -- Success
END
GO
GRANT EXECUTE ON [dbo].[Get_sqlagent_job_status] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CreateTask]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CreateTask]
GO

CREATE PROCEDURE [dbo].[CreateTask]
@ScheduleID uniqueidentifier,
@Name nvarchar (260),
@StartDate datetime,
@Flags int,
@NextRunTime datetime = NULL,
@LastRunTime datetime = NULL,
@EndDate datetime = NULL,
@RecurrenceType int = NULL,
@MinutesInterval int = NULL,
@DaysInterval int = NULL,
@WeeksInterval int = NULL,
@DaysOfWeek int = NULL,
@DaysOfMonth int = NULL,
@Month int = NULL,
@MonthlyWeek int = NULL,
@State int = NULL,
@LastRunStatus nvarchar (260) = NULL,
@ScheduledRunTimeout int = NULL,
@UserSid varbinary (85) = null,
@UserName nvarchar(260),
@AuthType int,
@EventType nvarchar (260),
@EventData nvarchar (260),
@Type int ,
@Path nvarchar (425) = NULL
AS

DECLARE @UserID uniqueidentifier

EXEC GetUserID @UserSid, @UserName, @AuthType, @UserID OUTPUT

-- Create a task with the given data. 
Insert into Schedule 
    (
        [ScheduleID], 
        [Name],
        [StartDate],
        [Flags],
        [NextRunTime],
        [LastRunTime], 
        [EndDate], 
        [RecurrenceType], 
        [MinutesInterval],
        [DaysInterval],
        [WeeksInterval],
        [DaysOfWeek], 
        [DaysOfMonth], 
        [Month], 
        [MonthlyWeek],
        [State], 
        [LastRunStatus],
        [ScheduledRunTimeout],
        [CreatedById],
        [EventType],
        [EventData],
        [Type],
        [Path]
    )
values
    (@ScheduleID, @Name, @StartDate, @Flags, @NextRunTime, @LastRunTime, @EndDate, @RecurrenceType, @MinutesInterval,
     @DaysInterval, @WeeksInterval, @DaysOfWeek, @DaysOfMonth, @Month, @MonthlyWeek, @State, @LastRunStatus,
     @ScheduledRunTimeout, @UserID, @EventType, @EventData, @Type, @Path)

GO
GRANT EXECUTE ON [dbo].[CreateTask] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[UpdateTask]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[UpdateTask]
GO

CREATE PROCEDURE [dbo].[UpdateTask]
@ScheduleID uniqueidentifier,
@Name nvarchar (260),
@StartDate datetime,
@Flags int,
@NextRunTime datetime = NULL,
@LastRunTime datetime = NULL,
@EndDate datetime = NULL,
@RecurrenceType int = NULL,
@MinutesInterval int = NULL,
@DaysInterval int = NULL,
@WeeksInterval int = NULL,
@DaysOfWeek int = NULL,
@DaysOfMonth int = NULL,
@Month int = NULL,
@MonthlyWeek int = NULL,
@State int = NULL,
@LastRunStatus nvarchar (260) = NULL,
@ScheduledRunTimeout int = NULL

AS

-- Update a tasks values. ScheduleID and Report information can not be updated
Update Schedule set
        [StartDate] = @StartDate, 
        [Name] = @Name,
        [Flags] = @Flags,
        [NextRunTime] = @NextRunTime,
        [LastRunTime] = @LastRunTime,
        [EndDate] = @EndDate, 
        [RecurrenceType] = @RecurrenceType, 
        [MinutesInterval] = @MinutesInterval,
        [DaysInterval] = @DaysInterval,
        [WeeksInterval] = @WeeksInterval,
        [DaysOfWeek] = @DaysOfWeek, 
        [DaysOfMonth] = @DaysOfMonth, 
        [Month] = @Month, 
        [MonthlyWeek] = @MonthlyWeek, 
        [State] = @State, 
        [LastRunStatus] = @LastRunStatus,
        [ScheduledRunTimeout] = @ScheduledRunTimeout
where
    [ScheduleID] = @ScheduleID

GO
GRANT EXECUTE ON [dbo].[UpdateTask] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[UpdateScheduleNextRunTime]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[UpdateScheduleNextRunTime]
GO

CREATE PROCEDURE [dbo].[UpdateScheduleNextRunTime]
@ScheduleID as uniqueidentifier,
@NextRunTime as datetime
as
update Schedule set [NextRunTime] = @NextRunTime where [ScheduleID] = @ScheduleID
GO
GRANT EXECUTE ON [dbo].[UpdateScheduleNextRunTime] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ListScheduledReports]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[ListScheduledReports]
GO

CREATE PROCEDURE [dbo].[ListScheduledReports]
@ScheduleID uniqueidentifier
AS
-- List all reports for a schedule
select 
        RS.[ReportAction],
        RS.[ScheduleID],
        RS.[ReportID],
        RS.[SubscriptionID],
        C.[Path],
        C.[Name],
        C.[Description],
        C.[ModifiedDate],
        SUSER_SNAME(U.[Sid]),
        U.[UserName],
        DATALENGTH( C.Content ),
        C.ExecutionTime,
        S.[Type],
        SD.[NtSecDescPrimary]
from
    [ReportSchedule] RS Inner join [Catalog] C on RS.[ReportID] = C.[ItemID]
    Inner join [Schedule] S on RS.[ScheduleID] = S.[ScheduleID]
    Inner join [Users] U on C.[ModifiedByID] = U.UserID
    left outer join [SecData] SD on SD.[PolicyID] = C.[PolicyID] AND SD.AuthType = U.AuthType    
where
    RS.[ScheduleID] = @ScheduleID 
    
GO
GRANT EXECUTE ON [dbo].[ListScheduledReports] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ListTasks]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[ListTasks]
GO

CREATE PROCEDURE [dbo].[ListTasks]
@Path nvarchar (425) = NULL,
@Prefix nvarchar (425) = NULL
AS

select 
        S.[ScheduleID],
        S.[Name],
        S.[StartDate],
        S.[Flags],
        S.[NextRunTime],
        S.[LastRunTime],
        S.[EndDate],
        S.[RecurrenceType],
        S.[MinutesInterval],
        S.[DaysInterval],
        S.[WeeksInterval],
        S.[DaysOfWeek],
        S.[DaysOfMonth],
        S.[Month],
        S.[MonthlyWeek],
        S.[State], 
        S.[LastRunStatus],
        S.[ScheduledRunTimeout],
        S.[EventType],
        S.[EventData],
        S.[Type],
        S.[Path],
        SUSER_SNAME(Owner.[Sid]),
        Owner.[UserName],
        Owner.[AuthType],
        (select count(*) from ReportSchedule where ReportSchedule.ScheduleID = S.ScheduleID)
from
    [Schedule] S  inner join [Users] Owner on S.[CreatedById] = Owner.UserID
where
    S.[Type] = 0 /*Type 0 is shared schedules*/ and
    ((@Path is null) OR (S.Path = @Path) or (S.Path like @Prefix escape '*'))
GO
GRANT EXECUTE ON [dbo].[ListTasks] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ListTasksForMaintenance]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[ListTasksForMaintenance]
GO

CREATE PROCEDURE [dbo].[ListTasksForMaintenance]
AS

declare @date datetime
set @date = GETUTCDATE()

update
    [Schedule]
set
    [ConsistancyCheck] = @date
from 
(
  SELECT TOP 20 [ScheduleID] FROM [Schedule] WITH(UPDLOCK) WHERE [ConsistancyCheck] is NULL
) AS t1
WHERE [Schedule].[ScheduleID] = t1.[ScheduleID]

select top 20
        S.[ScheduleID],
        S.[Name],
        S.[StartDate],
        S.[Flags],
        S.[NextRunTime],
        S.[LastRunTime],
        S.[EndDate],
        S.[RecurrenceType],
        S.[MinutesInterval],
        S.[DaysInterval],
        S.[WeeksInterval],
        S.[DaysOfWeek],
        S.[DaysOfMonth],
        S.[Month],
        S.[MonthlyWeek],
        S.[State], 
        S.[LastRunStatus],
        S.[ScheduledRunTimeout],
        S.[EventType],
        S.[EventData],
        S.[Type],
        S.[Path]
from
    [Schedule] S
where
    [ConsistancyCheck] = @date
GO
GRANT EXECUTE ON [dbo].[ListTasksForMaintenance] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ClearScheduleConsistancyFlags]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[ClearScheduleConsistancyFlags]
GO

CREATE PROCEDURE [dbo].[ClearScheduleConsistancyFlags]
AS
update [Schedule] with (tablock, xlock) set [ConsistancyCheck] = NULL
GO
GRANT EXECUTE ON [dbo].[ClearScheduleConsistancyFlags] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetAReportsReportAction]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetAReportsReportAction]
GO

CREATE PROCEDURE [dbo].[GetAReportsReportAction]
@ReportID uniqueidentifier,
@ReportAction int
AS
select 
        RS.[ReportAction],
        RS.[ScheduleID],
        RS.[ReportID],
        RS.[SubscriptionID],
        C.[Path]
from
    [ReportSchedule] RS Inner join [Catalog] C on RS.[ReportID] = C.[ItemID]
where
    C.ItemID = @ReportID and RS.[ReportAction] = @ReportAction
GO
GRANT EXECUTE ON [dbo].[GetAReportsReportAction] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetTimeBasedSubscriptionReportAction]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetTimeBasedSubscriptionReportAction]
GO

CREATE PROCEDURE [dbo].[GetTimeBasedSubscriptionReportAction]
@SubscriptionID uniqueidentifier
AS
select 
        RS.[ReportAction],
        RS.[ScheduleID],
        RS.[ReportID],
        RS.[SubscriptionID],
        C.[Path]
from
    [ReportSchedule] RS Inner join [Catalog] C on RS.[ReportID] = C.[ItemID]
where
    RS.[SubscriptionID] = @SubscriptionID
GO
GRANT EXECUTE ON [dbo].[GetTimeBasedSubscriptionReportAction] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetTaskProperties]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetTaskProperties]
GO

CREATE PROCEDURE [dbo].[GetTaskProperties]
@ScheduleID uniqueidentifier
AS
-- Grab all of a tasks properties given a task id
select 
        S.[ScheduleID],
        S.[Name],
        S.[StartDate], 
        S.[Flags],
        S.[NextRunTime],
        S.[LastRunTime], 
        S.[EndDate], 
        S.[RecurrenceType],
        S.[MinutesInterval],
        S.[DaysInterval],
        S.[WeeksInterval],
        S.[DaysOfWeek], 
        S.[DaysOfMonth], 
        S.[Month], 
        S.[MonthlyWeek], 
        S.[State], 
        S.[LastRunStatus],
        S.[ScheduledRunTimeout],
        S.[EventType],
        S.[EventData],
        S.[Type],
        S.[Path],
        SUSER_SNAME(Owner.[Sid]),
        Owner.[UserName],
        Owner.[AuthType]
from
    [Schedule] S with (XLOCK) 
    Inner join [Users] Owner on S.[CreatedById] = Owner.UserID
where
    S.[ScheduleID] = @ScheduleID
GO
GRANT EXECUTE ON [dbo].[GetTaskProperties] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DeleteTask]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[DeleteTask]
GO

CREATE PROCEDURE [dbo].[DeleteTask]
@ScheduleID uniqueidentifier
AS
-- Delete the task with the given task id
DELETE FROM Schedule
WHERE [ScheduleID] = @ScheduleID
GO
GRANT EXECUTE ON [dbo].[DeleteTask] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetSchedulesReports]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetSchedulesReports]
GO

CREATE PROCEDURE [dbo].[GetSchedulesReports] 
@ID uniqueidentifier
AS

select 
    C.Path
from
    ReportSchedule RS inner join Catalog C on (C.ItemID = RS.ReportID)
where
    ScheduleID = @ID
GO
GRANT EXECUTE ON [dbo].[GetSchedulesReports] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[AddReportSchedule]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[AddReportSchedule]
GO

CREATE PROCEDURE [dbo].[AddReportSchedule]
@ScheduleID uniqueidentifier,
@ReportID uniqueidentifier,
@SubscriptionID uniqueidentifier = NULL,
@Action int
AS

Insert into ReportSchedule ([ScheduleID], [ReportID], [SubscriptionID], [ReportAction]) values (@ScheduleID, @ReportID, @SubscriptionID, @Action)
GO
GRANT EXECUTE ON [dbo].[AddReportSchedule] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DeleteReportSchedule]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[DeleteReportSchedule]
GO

CREATE PROCEDURE [dbo].[DeleteReportSchedule]
@ScheduleID uniqueidentifier,
@ReportID uniqueidentifier,
@SubscriptionID uniqueidentifier = NULL,
@ReportAction int
AS

IF @SubscriptionID is NULL
BEGIN
delete from ReportSchedule where ScheduleID = @ScheduleID and ReportID = @ReportID and ReportAction = @ReportAction
END
ELSE
BEGIN
delete from ReportSchedule where ScheduleID = @ScheduleID and ReportID = @ReportID and ReportAction = @ReportAction and SubscriptionID = @SubscriptionID
END
GO
GRANT EXECUTE ON [dbo].[DeleteReportSchedule] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetSnapShotSchedule]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetSnapShotSchedule]
GO

CREATE PROCEDURE [dbo].[GetSnapShotSchedule] 
@ReportID uniqueidentifier
AS

select
    S.[ScheduleID],
    S.[Name],
    S.[StartDate], 
    S.[Flags],
    S.[NextRunTime],
    S.[LastRunTime], 
    S.[EndDate], 
    S.[RecurrenceType],
    S.[MinutesInterval],
    S.[DaysInterval],
    S.[WeeksInterval],
    S.[DaysOfWeek], 
    S.[DaysOfMonth], 
    S.[Month], 
    S.[MonthlyWeek], 
    S.[State], 
    S.[LastRunStatus],
    S.[ScheduledRunTimeout],
    S.[EventType],
    S.[EventData],
    S.[Type],
    S.[Path],
    SUSER_SNAME(Owner.[Sid]),
    Owner.[UserName],
    Owner.[AuthType]
from
    Schedule S with (XLOCK) inner join ReportSchedule RS on S.ScheduleID = RS.ScheduleID
    inner join [Users] Owner on S.[CreatedById] = Owner.[UserID]
where
    RS.ReportAction = 2 and -- 2 == create snapshot
    RS.ReportID = @ReportID
GO
GRANT EXECUTE ON [dbo].[GetSnapShotSchedule] TO RSExecRole
GO

--------------------------------------------------
------------- Time based subscriptions

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CreateTimeBasedSubscriptionSchedule]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CreateTimeBasedSubscriptionSchedule]
GO

CREATE PROCEDURE [dbo].[CreateTimeBasedSubscriptionSchedule]
@SubscriptionID as uniqueidentifier,
@ScheduleID uniqueidentifier,
@Schedule_Name nvarchar (260),
@Report_Name nvarchar (425),
@StartDate datetime,
@Flags int,
@NextRunTime datetime = NULL,
@LastRunTime datetime = NULL,
@EndDate datetime = NULL,
@RecurrenceType int = NULL,
@MinutesInterval int = NULL,
@DaysInterval int = NULL,
@WeeksInterval int = NULL,
@DaysOfWeek int = NULL,
@DaysOfMonth int = NULL,
@Month int = NULL,
@MonthlyWeek int = NULL,
@State int = NULL,
@LastRunStatus nvarchar (260) = NULL,
@ScheduledRunTimeout int = NULL,
@UserSid varbinary (85) = NULL,
@UserName nvarchar(260),
@AuthType int,
@EventType nvarchar (260),
@EventData nvarchar (260),
@Path nvarchar (425) = NULL
AS

EXEC CreateTask @ScheduleID, @Schedule_Name, @StartDate, @Flags, @NextRunTime, @LastRunTime, 
        @EndDate, @RecurrenceType, @MinutesInterval, @DaysInterval, @WeeksInterval, @DaysOfWeek, 
        @DaysOfMonth, @Month, @MonthlyWeek, @State, @LastRunStatus, 
        @ScheduledRunTimeout, @UserSid, @UserName, @AuthType, @EventType, @EventData, 1 /*scoped type*/, @Path

if @@ERROR = 0
begin
	-- add a row to the reportSchedule table
	declare @Report_OID uniqueidentifier
	select @Report_OID = (select [ItemID] from [Catalog] with (HOLDLOCK) where [Catalog].[Path] = @Report_Name and ([Catalog].[Type] = 2 or [Catalog].[Type] = 4))
	EXEC AddReportSchedule @ScheduleID, @Report_OID, @SubscriptionID, 4 -- TimedSubscription action
end
GO

GRANT EXECUTE ON [dbo].[CreateTimeBasedSubscriptionSchedule] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetTimeBasedSubscriptionSchedule]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetTimeBasedSubscriptionSchedule]
GO

CREATE PROCEDURE [dbo].[GetTimeBasedSubscriptionSchedule]
@SubscriptionID as uniqueidentifier
AS

select
    S.[ScheduleID],
    S.[Name],
    S.[StartDate], 
    S.[Flags],
    S.[NextRunTime],
    S.[LastRunTime], 
    S.[EndDate], 
    S.[RecurrenceType],
    S.[MinutesInterval], 
    S.[DaysInterval],
    S.[WeeksInterval],
    S.[DaysOfWeek], 
    S.[DaysOfMonth], 
    S.[Month], 
    S.[MonthlyWeek], 
    S.[State], 
    S.[LastRunStatus],
    S.[ScheduledRunTimeout],
    S.[EventType],
    S.[EventData],
    S.[Type],
    S.[Path],
    SUSER_SNAME(Owner.[Sid]),
    Owner.[UserName],
    Owner.[AuthType]
from
    [ReportSchedule] R inner join Schedule S with (XLOCK) on R.[ScheduleID] = S.[ScheduleID]
    Inner join [Users] Owner on S.[CreatedById] = Owner.UserID
where
    R.[SubscriptionID] = @SubscriptionID
GO
GRANT EXECUTE ON [dbo].[GetTimeBasedSubscriptionSchedule] TO RSExecRole
GO

--------------------------------------------------
------------- Running Jobs

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[AddRunningJob]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[AddRunningJob]
GO

CREATE PROCEDURE [dbo].[AddRunningJob]
@JobID as nvarchar(32),
@StartDate as datetime,
@ComputerName as nvarchar(32),
@RequestName as nvarchar(425),
@RequestPath as nvarchar(425),
@UserSid varbinary(85) = NULL,
@UserName nvarchar(260),
@AuthType int,
@Description as ntext  = NULL,
@Timeout as int,
@JobAction as smallint,
@JobType as smallint,
@JobStatus as smallint
AS

DECLARE @UserID uniqueidentifier
EXEC GetUserID @UserSid, @UserName, @AuthType, @UserID OUTPUT

INSERT INTO RunningJobs (JobID, StartDate, ComputerName, RequestName, RequestPath, UserID, Description, Timeout, JobAction, JobType, JobStatus )
VALUES             (@JobID, @StartDate, @ComputerName,  @RequestName, @RequestPath, @UserID, @Description, @Timeout, @JobAction, @JobType, @JobStatus)
GO

GRANT EXECUTE ON [dbo].[AddRunningJob] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[RemoveRunningJob]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[RemoveRunningJob]
GO

CREATE PROCEDURE [dbo].[RemoveRunningJob]
@JobID as nvarchar(32)
AS
DELETE FROM RunningJobs WHERE JobID = @JobID
GO

GRANT EXECUTE ON [dbo].[RemoveRunningJob] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[UpdateRunningJob]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[UpdateRunningJob]
GO

CREATE PROCEDURE [dbo].[UpdateRunningJob]
@JobID as nvarchar(32),
@JobStatus as smallint
AS
UPDATE RunningJobs SET JobStatus = @JobStatus WHERE JobID = @JobID
GO

GRANT EXECUTE ON [dbo].[UpdateRunningJob] TO RSExecRole
GO


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetMyRunningJobs]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetMyRunningJobs]
GO

CREATE PROCEDURE [dbo].[GetMyRunningJobs]
@ComputerName as nvarchar(32),
@JobType as smallint
AS
SELECT JobID, StartDate, ComputerName, RequestName, RequestPath, SUSER_SNAME(Users.[Sid]), Users.[UserName], Description, 
    Timeout, JobAction, JobType, JobStatus, Users.[AuthType]
FROM RunningJobs INNER JOIN Users 
ON RunningJobs.UserID = Users.UserID
WHERE ComputerName = @ComputerName
AND JobType = @JobType
GO

GRANT EXECUTE ON [dbo].[GetMyRunningJobs] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ListRunningJobs]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[ListRunningJobs]
GO

CREATE PROCEDURE [dbo].[ListRunningJobs]
AS
SELECT JobID, StartDate, ComputerName, RequestName, RequestPath, SUSER_SNAME(Users.[Sid]), Users.[UserName], Description, 
    Timeout, JobAction, JobType, JobStatus, Users.[AuthType]
FROM RunningJobs 
INNER JOIN Users 
ON RunningJobs.UserID = Users.UserID
GO

GRANT EXECUTE ON [dbo].[ListRunningJobs] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CleanExpiredJobs]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CleanExpiredJobs]
GO

CREATE PROCEDURE [dbo].[CleanExpiredJobs]
AS
DELETE FROM RunningJobs WHERE DATEADD(s, Timeout, StartDate) < GETDATE()
GO

GRANT EXECUTE ON [dbo].[CleanExpiredJobs] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CreateObject]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CreateObject]
GO

-- This SP should never be called with a policy ID unless it is guarenteed that
-- the parent will not be deleted before the insert (such as while running this script)
CREATE PROCEDURE [dbo].[CreateObject]
@ItemID uniqueidentifier,
@Name nvarchar (425),
@Path nvarchar (425),
@ParentID uniqueidentifier,
@Type int,
@Content image = NULL,
@Intermediate uniqueidentifier = NULL,
@LinkSourceID uniqueidentifier = NULL,
@Property ntext = NULL,
@Parameter ntext = NULL,
@Description ntext = NULL,
@Hidden bit = NULL,
@CreatedBySid varbinary(85) = NULL,
@CreatedByName nvarchar(260),
@AuthType int,
@CreationDate datetime,
@ModificationDate datetime,
@MimeType nvarchar (260) = NULL,
@SnapshotLimit int = NULL,
@PolicyRoot int = 0,
@PolicyID uniqueidentifier = NULL,
@ExecutionFlag int = 1 -- allow live execution, don't keep history
AS

DECLARE @CreatedByID uniqueidentifier
EXEC GetUserID @CreatedBySid, @CreatedByName, @AuthType, @CreatedByID OUTPUT

UPDATE Catalog with (XLOCK)
SET ModifiedByID = @CreatedByID, ModifiedDate = @ModificationDate
WHERE ItemID = @ParentID

-- If no policyID, use the parent's
IF @PolicyID is NULL BEGIN
   SET @PolicyID = (SELECT PolicyID FROM [dbo].[Catalog] WHERE Catalog.ItemID = @ParentID)
END

-- If there is no policy ID then we are guarenteed not to have a parent
IF @PolicyID is NULL BEGIN
RAISERROR ('Parent Not Found', 16, 1)
return
END

INSERT INTO Catalog (ItemID,  Path,  Name,  ParentID,  Type,  Content,  Intermediate,  LinkSourceID,  Property,  Description,  Hidden,  CreatedByID,  CreationDate,  ModifiedByID,  ModifiedDate,  MimeType,  SnapshotLimit,  [Parameter],  PolicyID,  PolicyRoot, ExecutionFlag )
VALUES             (@ItemID, @Path, @Name, @ParentID, @Type, @Content, @Intermediate, @LinkSourceID, @Property, @Description, @Hidden, @CreatedByID, @CreationDate, @CreatedByID,  @ModificationDate, @MimeType, @SnapshotLimit, @Parameter, @PolicyID, @PolicyRoot , @ExecutionFlag)

IF @Intermediate IS NOT NULL AND @@ERROR = 0 BEGIN
   UPDATE SnapshotData
   SET PermanentRefcount = PermanentRefcount + 1, TransientRefcount = TransientRefcount - 1
   WHERE SnapshotData.SnapshotDataID = @Intermediate
END

GO
GRANT EXECUTE ON [dbo].[CreateObject] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DeleteObject]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[DeleteObject]
GO

CREATE PROCEDURE [dbo].[DeleteObject]
@Path nvarchar (425),
@Prefix nvarchar (850)
AS

-- Remove reference for intermediate formats
UPDATE SnapshotData
SET PermanentRefcount = PermanentRefcount - 1
FROM
   Catalog AS R WITH (XLOCK)
   INNER JOIN [SnapshotData] AS SD ON R.Intermediate = SD.SnapshotDataID
WHERE
   (R.Path = @Path OR R.Path LIKE @Prefix ESCAPE '*')

-- Remove reference for execution snapshots
UPDATE SnapshotData
SET PermanentRefcount = PermanentRefcount - 1
FROM
   Catalog AS R WITH (XLOCK)
   INNER JOIN [SnapshotData] AS SD ON R.SnapshotDataID = SD.SnapshotDataID
WHERE
   (R.Path = @Path OR R.Path LIKE @Prefix ESCAPE '*')

-- Remove history for deleted reports and linked report
DELETE History
FROM
   [Catalog] AS R
   INNER JOIN [History] AS S ON R.ItemID = S.ReportID
WHERE
   (R.Path = @Path OR R.Path LIKE @Prefix ESCAPE '*')
   
-- Remove model drill reports
DELETE ModelDrill
FROM
   [Catalog] AS C
   INNER JOIN [ModelDrill] AS M ON C.ItemID = M.ReportID
WHERE
   (C.Path = @Path OR C.Path LIKE @Prefix ESCAPE '*')
      

-- Adjust data sources
UPDATE [DataSource]
   SET
      [Flags] = [Flags] & 0x7FFFFFFD, -- broken link
      [Link] = NULL
FROM
   [Catalog] AS C
   INNER JOIN [DataSource] AS DS ON C.[ItemID] = DS.[Link]
WHERE
   (C.Path = @Path OR C.Path LIKE @Prefix ESCAPE '*')

-- Clean all data sources
DELETE [DataSource]
FROM
    [Catalog] AS R
    INNER JOIN [DataSource] AS DS ON R.[ItemID] = DS.[ItemID]
WHERE    
    (R.Path = @Path OR R.Path LIKE @Prefix ESCAPE '*')

-- Update linked reports
UPDATE LR
   SET
      LR.LinkSourceID = NULL
FROM
   [Catalog] AS R INNER JOIN [Catalog] AS LR ON R.ItemID = LR.LinkSourceID
WHERE
   (R.Path = @Path OR R.Path LIKE @Prefix ESCAPE '*')
   AND
   (LR.Path NOT LIKE @Prefix ESCAPE '*')

-- Remove references for cache entries
UPDATE SN
SET
   PermanentRefcount = PermanentRefcount - 1
FROM
   [ReportServerTempDB].dbo.SnapshotData AS SN
   INNER JOIN [ReportServerTempDB].dbo.ExecutionCache AS EC on SN.SnapshotDataID = EC.SnapshotDataID
   INNER JOIN Catalog AS C ON EC.ReportID = C.ItemID
WHERE
   (Path = @Path OR Path LIKE @Prefix ESCAPE '*')
   
-- Clean cache entries for items to be deleted   
DELETE EC
FROM
   [ReportServerTempDB].dbo.ExecutionCache AS EC
   INNER JOIN Catalog AS C ON EC.ReportID = C.ItemID
WHERE
   (Path = @Path OR Path LIKE @Prefix ESCAPE '*')

-- Finally delete items
DELETE
FROM
   [Catalog]
WHERE
   (Path = @Path OR Path LIKE @Prefix ESCAPE '*')

EXEC CleanOrphanedPolicies
GO
GRANT EXECUTE ON [dbo].[DeleteObject] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FindObjectsNonRecursive]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[FindObjectsNonRecursive]
GO

CREATE PROCEDURE [dbo].[FindObjectsNonRecursive]
@Path nvarchar (425),
@AuthType int
AS
SELECT 
    C.Type,
    C.PolicyID,
    SD.NtSecDescPrimary,
    C.Name, 
    C.Path, 
    C.ItemID,
    DATALENGTH( C.Content ) AS [Size],
    C.Description,
    C.CreationDate, 
    C.ModifiedDate,
    SUSER_SNAME(CU.Sid), 
    CU.[UserName],
    SUSER_SNAME(MU.Sid),
    MU.[UserName],
    C.MimeType,
    C.ExecutionTime,
    C.Hidden
FROM
   Catalog AS C 
   INNER JOIN Catalog AS P ON C.ParentID = P.ItemID
   INNER JOIN Users AS CU ON C.CreatedByID = CU.UserID
   INNER JOIN Users AS MU ON C.ModifiedByID = MU.UserID
   LEFT OUTER JOIN SecData SD ON C.PolicyID = SD.PolicyID AND SD.AuthType = @AuthType
WHERE P.Path = @Path
GO
GRANT EXECUTE ON [dbo].[FindObjectsNonRecursive] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FindObjectsRecursive]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[FindObjectsRecursive]
GO

CREATE PROCEDURE [dbo].[FindObjectsRecursive]
@Prefix nvarchar (850),
@AuthType int
AS
SELECT 
    C.Type,
    C.PolicyID,
    SD.NtSecDescPrimary,
    C.Name,
    C.Path,
    C.ItemID,
    DATALENGTH( C.Content ) AS [Size],
    C.Description,
    C.CreationDate,
    C.ModifiedDate,
    SUSER_SNAME(CU.Sid),
    CU.UserName,
    SUSER_SNAME(MU.Sid),
    MU.UserName,
    C.MimeType,
    C.ExecutionTime,
    C.Hidden
from
   Catalog AS C
   INNER JOIN Users AS CU ON C.CreatedByID = CU.UserID
   INNER JOIN Users AS MU ON C.ModifiedByID = MU.UserID
   LEFT OUTER JOIN SecData AS SD ON C.PolicyID = SD.PolicyID AND SD.AuthType = @AuthType
WHERE C.Path LIKE @Prefix ESCAPE '*'
GO
GRANT EXECUTE ON [dbo].[FindObjectsRecursive] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FindParents]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[FindParents]
GO

CREATE PROCEDURE [dbo].[FindParents]
@Path nvarchar (425),
@AuthType int
AS
SELECT 
    C.Type,
    C.PolicyID,
    SD.NtSecDescPrimary,
    C.Name, 
    C.Path, 
    C.ItemID,
    DATALENGTH( C.Content ) AS [Size],
    C.Description,
    C.CreationDate, 
    C.ModifiedDate,
    SUSER_SNAME(CU.Sid), 
    CU.[UserName],
    SUSER_SNAME(MU.Sid),
    MU.[UserName],
    C.MimeType,
    C.ExecutionTime,
    C.Hidden
FROM
   Catalog AS C 
   INNER JOIN Users AS CU ON C.CreatedByID = CU.UserID
   INNER JOIN Users AS MU ON C.ModifiedByID = MU.UserID
   LEFT OUTER JOIN SecData SD ON C.PolicyID = SD.PolicyID AND SD.AuthType = @AuthType
WHERE @Path LIKE C.Path + '/%'
ORDER BY DATALENGTH(C.Path) desc
GO
GRANT EXECUTE ON [dbo].[FindParents] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FindObjectsByLink]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[FindObjectsByLink]
GO

CREATE PROCEDURE [dbo].[FindObjectsByLink]
@Link uniqueidentifier,
@AuthType int
AS
SELECT 
    C.Type, 
    C.PolicyID,
    SD.NtSecDescPrimary,
    C.Name, 
    C.Path, 
    C.ItemID, 
    DATALENGTH( C.Content ) AS [Size], 
    C.Description,
    C.CreationDate, 
    C.ModifiedDate, 
    SUSER_SNAME(CU.Sid),
    CU.UserName,
    SUSER_SNAME(MU.Sid),
    MU.UserName,
    C.MimeType,
    C.ExecutionTime,
    C.Hidden
FROM
   Catalog AS C
   INNER JOIN Users AS CU ON C.CreatedByID = CU.UserID
   INNER JOIN Users AS MU ON C.ModifiedByID = MU.UserID
   LEFT OUTER JOIN SecData AS SD ON C.PolicyID = SD.PolicyID AND SD.AuthType = @AuthType
WHERE C.LinkSourceID = @Link
GO
GRANT EXECUTE ON [dbo].[FindObjectsByLink] TO RSExecRole
GO

--------------------------------------------------
------------- Procedures used to update linked reports

if exists (select * from sysobjects where id = object_id('[dbo].[GetIDPairsByLink]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetIDPairsByLink]
GO

CREATE PROCEDURE [dbo].[GetIDPairsByLink]
@Link uniqueidentifier
AS
SELECT LinkSourceID, ItemID
FROM Catalog
WHERE LinkSourceID = @Link
GO
GRANT EXECUTE ON [dbo].[GetIDPairsByLink] TO RSExecRole
GO

if exists (select * from sysobjects where id = object_id('[dbo].[GetChildrenBeforeDelete]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetChildrenBeforeDelete]
GO

CREATE PROCEDURE [dbo].[GetChildrenBeforeDelete]
@Prefix nvarchar (850),
@AuthType int
AS
SELECT C.PolicyID, C.Type, SD.NtSecDescPrimary
FROM
   Catalog AS C LEFT OUTER JOIN SecData AS SD ON C.PolicyID = SD.PolicyID AND SD.AuthType = @AuthType
WHERE
   C.Path LIKE @Prefix ESCAPE '*'  -- return children only, not item itself
GO
GRANT EXECUTE ON [dbo].[GetChildrenBeforeDelete] TO RSExecRole
GO


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetAllProperties]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetAllProperties]
GO

CREATE PROCEDURE [dbo].[GetAllProperties]
@Path nvarchar (425),
@AuthType int
AS
select
   Property,
   Description,
   Type,
   DATALENGTH( Content ),
   ItemID, 
   SUSER_SNAME(C.Sid),
   C.UserName,
   CreationDate,
   SUSER_SNAME(M.Sid),
   M.UserName,
   ModifiedDate,
   MimeType,
   ExecutionTime,
   NtSecDescPrimary,
   [LinkSourceID],
   Hidden,
   ExecutionFlag,
   SnapshotLimit, 
   [Name]
FROM Catalog
   INNER JOIN Users C ON Catalog.CreatedByID = C.UserID
   INNER JOIN Users M ON Catalog.ModifiedByID = M.UserID
   LEFT OUTER JOIN SecData ON Catalog.PolicyID = SecData.PolicyID AND SecData.AuthType = @AuthType
WHERE Path = @Path
GO
GRANT EXECUTE ON [dbo].[GetAllProperties] TO RSExecRole
GO


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetParameters]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetParameters]
GO

CREATE PROCEDURE [dbo].[GetParameters]
@Path nvarchar (425),
@AuthType int
AS
SELECT
   Type,
   [Parameter],
   ItemID,
   SecData.NtSecDescPrimary,
   [LinkSourceID],
   [ExecutionFlag]
FROM Catalog 
LEFT OUTER JOIN SecData ON Catalog.PolicyID = SecData.PolicyID AND SecData.AuthType = @AuthType
WHERE Path = @Path
GO
GRANT EXECUTE ON [dbo].[GetParameters] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetObjectContent]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetObjectContent]
GO

CREATE PROCEDURE [dbo].[GetObjectContent]
@Path nvarchar (425),
@AuthType int
AS
SELECT Type, Content, LinkSourceID, MimeType, SecData.NtSecDescPrimary, ItemID
FROM Catalog
LEFT OUTER JOIN SecData ON Catalog.PolicyID = SecData.PolicyID AND SecData.AuthType = @AuthType
WHERE Path = @Path
GO
GRANT EXECUTE ON [dbo].[GetObjectContent] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetCompiledDefinition]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetCompiledDefinition]
GO

-- used to create snapshots
CREATE PROCEDURE [dbo].[GetCompiledDefinition]
@Path nvarchar (425),
@AuthType int
AS
    SELECT
       MainItem.Type,
       MainItem.Intermediate,
       MainItem.LinkSourceID,
       MainItem.Property,
       MainItem.Description,
       SecData.NtSecDescPrimary,
       MainItem.ItemID,         
       MainItem.ExecutionFlag,  
       LinkTarget.Intermediate,
       LinkTarget.Property,
       LinkTarget.Description,
       MainItem.[SnapshotDataID]
    FROM Catalog MainItem
    LEFT OUTER JOIN SecData ON MainItem.PolicyID = SecData.PolicyID AND SecData.AuthType = @AuthType
    LEFT OUTER JOIN Catalog LinkTarget with (INDEX(PK_Catalog)) on MainItem.LinkSourceID = LinkTarget.ItemID
    WHERE MainItem.Path = @Path
GO
GRANT EXECUTE ON [dbo].[GetCompiledDefinition] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetReportForExecution]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetReportForExecution]
GO

-- gets either the intermediate format or snapshot from cache
CREATE PROCEDURE [dbo].[GetReportForExecution]
@Path nvarchar (425),
@ParamsHash int,
@AuthType int
AS

DECLARE @now AS datetime
SET @now = GETDATE()

IF ( NOT EXISTS (
    SELECT *
        FROM
            Catalog AS C
            INNER JOIN [ReportServerTempDB].dbo.ExecutionCache AS EC ON C.ItemID = EC.ReportID
            INNER JOIN [ReportServerTempDB].dbo.SnapshotData AS SN ON EC.SnapshotDataID = SN.SnapshotDataID
        WHERE
            C.Path = @Path AND
            EC.AbsoluteExpiration > @now AND
            SN.ParamsHash = @ParamsHash
   ) ) 
BEGIN   -- no cache
    SELECT
        Cat.Type,
        Cat.LinkSourceID,
        Cat2.Path,
        Cat.Property,
        Cat.Description,
        SecData.NtSecDescPrimary,
        Cat.ItemID,
        CAST (0 AS BIT), -- not found,
        Cat.Intermediate,
        Cat.ExecutionFlag,
        SD.SnapshotDataID,
        SD.DependsOnUser,
        Cat.ExecutionTime,
        (SELECT Schedule.NextRunTime
         FROM
             Schedule WITH (XLOCK)
             INNER JOIN ReportSchedule ON Schedule.ScheduleID = ReportSchedule.ScheduleID 
         WHERE ReportSchedule.ReportID = Cat.ItemID AND ReportSchedule.ReportAction = 1), -- update snapshot
        (SELECT Schedule.ScheduleID
         FROM
             Schedule
             INNER JOIN ReportSchedule ON Schedule.ScheduleID = ReportSchedule.ScheduleID 
         WHERE ReportSchedule.ReportID = Cat.ItemID AND ReportSchedule.ReportAction = 1), -- update snapshot
        (SELECT CachePolicy.ExpirationFlags FROM CachePolicy WHERE CachePolicy.ReportID = Cat.ItemID),
        Cat2.Intermediate
    FROM
        Catalog AS Cat
        LEFT OUTER JOIN SecData ON Cat.PolicyID = SecData.PolicyID AND SecData.AuthType = @AuthType
        LEFT OUTER JOIN Catalog AS Cat2 on Cat.LinkSourceID = Cat2.ItemID
        LEFT OUTER JOIN SnapshotData AS SD ON Cat.SnapshotDataID = SD.SnapshotDataID
    WHERE Cat.Path = @Path
END
ELSE
BEGIN   -- use cache
    SELECT TOP 1
        Cat.Type,
        Cat.LinkSourceID,
        Cat2.Path,
        Cat.Property,
        Cat.Description,
        SecData.NtSecDescPrimary,
        Cat.ItemID,
        CAST (1 AS BIT), -- found,
        SN.SnapshotDataID,
        SN.DependsOnUser,
        SN.EffectiveParams,
        SN.CreatedDate,
        EC.AbsoluteExpiration,
        (SELECT CachePolicy.ExpirationFlags FROM CachePolicy WHERE CachePolicy.ReportID = Cat.ItemID),
        (SELECT Schedule.ScheduleID
         FROM
             Schedule WITH (XLOCK)
             INNER JOIN ReportSchedule ON Schedule.ScheduleID = ReportSchedule.ScheduleID 
             WHERE ReportSchedule.ReportID = Cat.ItemID AND ReportSchedule.ReportAction = 1), -- update snapshot
        SN.QueryParams     
    FROM
        Catalog AS Cat
        INNER JOIN [ReportServerTempDB].dbo.ExecutionCache AS EC ON Cat.ItemID = EC.ReportID
        INNER JOIN [ReportServerTempDB].dbo.SnapshotData AS SN ON EC.SnapshotDataID = SN.SnapshotDataID
        LEFT OUTER JOIN SecData ON Cat.PolicyID = SecData.PolicyID AND SecData.AuthType = @AuthType
        LEFT OUTER JOIN Catalog AS Cat2 on Cat.LinkSourceID = Cat2.ItemID
    WHERE
        Cat.Path = @Path 
        AND AbsoluteExpiration > @now 
        AND SN.ParamsHash = @ParamsHash
    ORDER BY SN.CreatedDate DESC
END

GO
GRANT EXECUTE ON [dbo].[GetReportForExecution] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetReportParametersForExecution]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetReportParametersForExecution]
GO

-- gets either the intermediate format or snapshot from cache
CREATE PROCEDURE [dbo].[GetReportParametersForExecution]
@Path nvarchar (425),
@HistoryID DateTime = NULL,
@AuthType int
AS
SELECT
   C.[ItemID],
   C.[Type],
   C.[ExecutionFlag],
   [SecData].[NtSecDescPrimary],
   C.[Parameter],
   C.[Intermediate],
   C.[SnapshotDataID],
   [History].[SnapshotDataID],
   L.[Intermediate],
   C.[LinkSourceID],
   C.[ExecutionTime]
FROM
   [Catalog] AS C
   LEFT OUTER JOIN [SecData] ON C.[PolicyID] = [SecData].[PolicyID] AND [SecData].AuthType = @AuthType
   LEFT OUTER JOIN [History] ON ( C.[ItemID] = [History].[ReportID] AND [History].[SnapshotDate] = @HistoryID )
   LEFT OUTER JOIN [Catalog] AS L ON C.[LinkSourceID] = L.[ItemID]
WHERE
   C.[Path] = @Path
GO

GRANT EXECUTE ON [dbo].[GetReportParametersForExecution] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[MoveObject]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[MoveObject]
GO

CREATE PROCEDURE [dbo].[MoveObject]
@OldPath nvarchar (425),
@OldPrefix nvarchar (850),
@NewName nvarchar (425),
@NewPath nvarchar (425),
@NewParentID uniqueidentifier,
@RenameOnly as bit,
@MaxPathLength as int
AS

DECLARE @LongPath nvarchar(425)
SET @LongPath =
  (SELECT TOP 1 Path
   FROM Catalog
   WHERE
      LEN(Path)-LEN(@OldPath)+LEN(@NewPath) > @MaxPathLength AND
      Path LIKE @OldPrefix ESCAPE '*')
   
IF @LongPath IS NOT NULL BEGIN
   SELECT @LongPath
   RETURN
END

IF @RenameOnly = 0 -- if this a full-blown move, not just a rename
BEGIN
    -- adjust policies on the top item that gets moved
    DECLARE @OldInheritedPolicyID as uniqueidentifier
    SELECT @OldInheritedPolicyID = (SELECT PolicyID FROM Catalog with (XLOCK) WHERE Path = @OldPath AND PolicyRoot = 0)
    IF (@OldInheritedPolicyID IS NOT NULL)
       BEGIN -- this was not a policy root, change it to inherit from target folder
         DECLARE @NewPolicyID as uniqueidentifier
         SELECT @NewPolicyID = (SELECT PolicyID FROM Catalog with (XLOCK) WHERE ItemID = @NewParentID)
         -- update item and children that shared the old policy
         UPDATE Catalog SET PolicyID = @NewPolicyID WHERE Path = @OldPath 
         UPDATE Catalog SET PolicyID = @NewPolicyID 
            WHERE Path LIKE @OldPrefix ESCAPE '*' 
            AND Catalog.PolicyID = @OldInheritedPolicyID
     END
END

-- Update item that gets moved (Path, Name, and ParentId)
update Catalog
set Name = @NewName, Path = @NewPath, ParentID = @NewParentID
where Path = @OldPath
-- Update all its children (Path only, Names and ParentIds stay the same)
update Catalog
set Path = STUFF(Path, 1, LEN(@OldPath), @NewPath )
where Path like @OldPrefix escape '*'
GO
GRANT EXECUTE ON [dbo].[MoveObject] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ObjectExists]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[ObjectExists]
GO

CREATE PROCEDURE [dbo].[ObjectExists]
@Path nvarchar (425),
@AuthType int
AS
SELECT Type, ItemID, SnapshotLimit, NtSecDescPrimary, ExecutionFlag, Intermediate, [LinkSourceID]
FROM Catalog
LEFT OUTER JOIN SecData
ON Catalog.PolicyID = SecData.PolicyID AND SecData.AuthType = @AuthType
WHERE Path = @Path
GO
GRANT EXECUTE ON [dbo].[ObjectExists] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SetAllProperties]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SetAllProperties]
GO

CREATE PROCEDURE [dbo].[SetAllProperties]
@Path nvarchar (425),
@Property ntext,
@Description ntext = NULL,
@Hidden bit = NULL,
@ModifiedBySid varbinary (85) = NULL,
@ModifiedByName nvarchar(260),
@AuthType int,
@ModifiedDate DateTime
AS

DECLARE @ModifiedByID uniqueidentifier
EXEC GetUserID @ModifiedBySid, @ModifiedByName, @AuthType, @ModifiedByID OUTPUT

UPDATE Catalog
SET Property = @Property, Description = @Description, Hidden = @Hidden, ModifiedByID = @ModifiedByID, ModifiedDate = @ModifiedDate
WHERE Path = @Path
GO
GRANT EXECUTE ON [dbo].[SetAllProperties] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FlushReportFromCache]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[FlushReportFromCache]
GO

CREATE PROCEDURE [dbo].[FlushReportFromCache]
@Path as nvarchar(425)
AS

UPDATE SN
   SET SN.PermanentRefcount = SN.PermanentRefcount - 1
FROM
   [ReportServerTempDB].dbo.SnapshotData AS SN
   INNER JOIN [ReportServerTempDB].dbo.ExecutionCache AS EC ON SN.SnapshotDataID = EC.SnapshotDataID
   INNER JOIN Catalog AS C ON EC.ReportID = C.ItemID
WHERE C.Path = @Path

DELETE EC
FROM
   [ReportServerTempDB].dbo.ExecutionCache AS EC
   INNER JOIN Catalog ON EC.ReportID = Catalog.ItemID
WHERE Catalog.Path = @Path

GO
GRANT EXECUTE ON [dbo].[FlushReportFromCache] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SetParameters]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SetParameters]
GO

CREATE PROCEDURE [dbo].[SetParameters]
@Path nvarchar (425),
@Parameter ntext
AS
UPDATE Catalog
SET [Parameter] = @Parameter
WHERE Path = @Path
EXEC FlushReportFromCache @Path
GO
GRANT EXECUTE ON [dbo].[SetParameters] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SetObjectContent]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SetObjectContent]
GO

CREATE PROCEDURE [dbo].[SetObjectContent]
@Path nvarchar (425),
@Type int,
@Content image = NULL,
@Intermediate uniqueidentifier = NULL,
@Parameter ntext = NULL,
@LinkSourceID uniqueidentifier = NULL,
@MimeType nvarchar (260) = NULL
AS

DECLARE @OldIntermediate as uniqueidentifier
SET @OldIntermediate = (SELECT Intermediate FROM Catalog WITH (XLOCK) WHERE Path = @Path)

UPDATE SnapshotData
SET PermanentRefcount = PermanentRefcount - 1
WHERE SnapshotData.SnapshotDataID = @OldIntermediate

UPDATE Catalog
SET Type=@Type, Content = @Content, Intermediate = @Intermediate, [Parameter] = @Parameter, LinkSourceID = @LinkSourceID, MimeType = @MimeType
WHERE Path = @Path

UPDATE SnapshotData
SET PermanentRefcount = PermanentRefcount + 1, TransientRefcount = TransientRefcount - 1
WHERE SnapshotData.SnapshotDataID = @Intermediate

EXEC FlushReportFromCache @Path

GO
GRANT EXECUTE ON [dbo].[SetObjectContent] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SetLastModified]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SetLastModified]
GO

CREATE PROCEDURE [dbo].[SetLastModified]
@Path nvarchar (425),
@ModifiedBySid varbinary (85) = NULL,
@ModifiedByName nvarchar(260),
@AuthType int,
@ModifiedDate DateTime
AS
DECLARE @ModifiedByID uniqueidentifier
EXEC GetUserID @ModifiedBySid, @ModifiedByName, @AuthType, @ModifiedByID OUTPUT
UPDATE Catalog
SET ModifiedByID = @ModifiedByID, ModifiedDate = @ModifiedDate
WHERE Path = @Path
GO
GRANT EXECUTE ON [dbo].[SetLastModified] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetNameById]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetNameById]
GO

CREATE PROCEDURE [dbo].[GetNameById]
@ItemID uniqueidentifier
AS
SELECT Path
FROM Catalog
WHERE ItemID = @ItemID
GO
GRANT EXECUTE ON [dbo].[GetNameById] TO RSExecRole
GO

--------------------------------------------------
------------- Data source procedures to store user names and passwords

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[AddDataSource]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[AddDataSource]
GO

CREATE PROCEDURE [dbo].[AddDataSource]
@DSID [uniqueidentifier],
@ItemID [uniqueidentifier] = NULL, -- null for future suport dynamic delivery
@SubscriptionID [uniqueidentifier] = NULL,
@Name [nvarchar] (260) = NULL, -- only for scoped data sources, MUST be NULL for standalone!!!
@Extension [nvarchar] (260) = NULL,
@LinkID [uniqueidentifier] = NULL, -- link id is trusted, if it is provided - we use it
@LinkPath [nvarchar] (425) = NULL, -- if LinkId is not provided we try to look up LinkPath
@CredentialRetrieval [int],
@Prompt [ntext] = NULL,
@ConnectionString [image] = NULL,
@OriginalConnectionString [image] = NULL,
@OriginalConnectStringExpressionBased [bit] = NULL,
@UserName [image] = NULL,
@Password [image] = NULL,
@Flags [int],
@AuthType [int],
@Version [int]
AS

DECLARE @ActualLinkID uniqueidentifier
SET @ActualLinkID = NULL

IF (@LinkID is NULL) AND (@LinkPath is not NULL) BEGIN
   SELECT
      Type, ItemID, NtSecDescPrimary
   FROM
      Catalog LEFT OUTER JOIN SecData ON Catalog.PolicyID = SecData.PolicyID AND SecData.AuthType = @AuthType
   WHERE
      Path = @LinkPath
   SET @ActualLinkID = (SELECT ItemID FROM Catalog WHERE Path = @LinkPath)
END
ELSE BEGIN
   SET @ActualLinkID = @LinkID
END

INSERT
    INTO DataSource
        ([DSID], [ItemID], [SubscriptionID], [Name], [Extension], [Link],
        [CredentialRetrieval], [Prompt],
        [ConnectionString], [OriginalConnectionString], [OriginalConnectStringExpressionBased], 
        [UserName], [Password], [Flags], [Version])
    VALUES
        (@DSID, @ItemID, @SubscriptionID, @Name, @Extension, @ActualLinkID,
        @CredentialRetrieval, @Prompt,
        @ConnectionString, @OriginalConnectionString, @OriginalConnectStringExpressionBased,
        @UserName, @Password, @Flags, @Version)
   
GO
GRANT EXECUTE ON [dbo].[AddDataSource] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetDataSources]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetDataSources]
GO

CREATE  PROCEDURE [dbo].[GetDataSources]
@ItemID [uniqueidentifier],
@AuthType int
AS
SELECT -- select data sources and their links (if they exist)
    DS.[DSID],      -- 0
    DS.[ItemID],    -- 1
    DS.[Name],      -- 2
    DS.[Extension], -- 3
    DS.[Link],      -- 4
    DS.[CredentialRetrieval], -- 5
    DS.[Prompt],    -- 6
    DS.[ConnectionString], -- 7
    DS.[OriginalConnectionString], -- 8
    DS.[UserName],  -- 9
    DS.[Password],  -- 10
    DS.[Flags],     -- 11
    DSL.[DSID],     -- 12
    DSL.[ItemID],   -- 13
    DSL.[Name],     -- 14
    DSL.[Extension], -- 15
    DSL.[Link],     -- 16
    DSL.[CredentialRetrieval], -- 17
    DSL.[Prompt],   -- 18
    DSL.[ConnectionString], -- 19
    DSL.[UserName], -- 20
    DSL.[Password], -- 21
    DSL.[Flags],	-- 22
    C.Path,         -- 23
    SD.NtSecDescPrimary, -- 24
    DS.[OriginalConnectStringExpressionBased], -- 25
    DS.[Version], -- 26
    DSL.[Version], -- 27
    (SELECT 1 WHERE EXISTS (SELECT * from [ModelItemPolicy] AS MIP WHERE C.[ItemID] = MIP.[CatalogItemID])) -- 28
FROM
   [DataSource] AS DS LEFT OUTER JOIN
       ([DataSource] AS DSL
       INNER JOIN [Catalog] AS C ON DSL.[ItemID] = C.[ItemID]
       LEFT OUTER JOIN [SecData] AS SD ON C.[PolicyID] = SD.[PolicyID] AND SD.AuthType = @AuthType)
   ON DS.[Link] = DSL.[ItemID]
WHERE
   DS.[ItemID] = @ItemID or DS.[SubscriptionID] = @ItemID
GO
GRANT EXECUTE ON [dbo].[GetDataSources] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DeleteDataSources]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[DeleteDataSources]
GO

CREATE PROCEDURE [dbo].[DeleteDataSources]
@ItemID [uniqueidentifier]
AS

DELETE
FROM [DataSource]
WHERE [ItemID] = @ItemID or [SubscriptionID] = @ItemID 
GO
GRANT EXECUTE ON [dbo].[DeleteDataSources] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ChangeStateOfDataSource]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[ChangeStateOfDataSource]
GO

CREATE PROCEDURE [dbo].[ChangeStateOfDataSource]
@ItemID [uniqueidentifier],
@Enable bit
AS
IF @Enable != 0 BEGIN
   UPDATE [DataSource]
      SET
         [Flags] = [Flags] | 1
   WHERE [ItemID] = @ItemID
END
ELSE
BEGIN
   UPDATE [DataSource]
      SET
         [Flags] = [Flags] & 0x7FFFFFFE
   WHERE [ItemID] = @ItemID
END
GO

GRANT EXECUTE ON [dbo].[ChangeStateOfDataSource] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FindItemsByDataSource]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[FindItemsByDataSource]
GO

CREATE PROCEDURE [dbo].[FindItemsByDataSource]
@ItemID uniqueidentifier,
@AuthType int
AS
SELECT 
    C.Type,
    C.PolicyID,
    SD.NtSecDescPrimary,
    C.Name, 
    C.Path, 
    C.ItemID,
    DATALENGTH( C.Content ) AS [Size],
    C.Description,
    C.CreationDate, 
    C.ModifiedDate,
    SUSER_SNAME(CU.Sid), 
    CU.UserName,
    SUSER_SNAME(MU.Sid),
    MU.UserName,
    C.MimeType,
    C.ExecutionTime,
    C.Hidden
FROM
   Catalog AS C 
   INNER JOIN Users AS CU ON C.CreatedByID = CU.UserID
   INNER JOIN Users AS MU ON C.ModifiedByID = MU.UserID
   LEFT OUTER JOIN SecData AS SD ON C.PolicyID = SD.PolicyID AND SD.AuthType = @AuthType
   INNER JOIN DataSource AS DS ON C.ItemID = DS.ItemID
WHERE
   DS.Link = @ItemID
GO
GRANT EXECUTE ON [dbo].[FindItemsByDataSource] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CopyExecutionSnapshot]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CopyExecutionSnapshot]
GO

CREATE PROCEDURE [dbo].[CopyExecutionSnapshot]
@SourceReportID uniqueidentifier,
@TargetReportID uniqueidentifier,
@ReservedUntilUTC datetime
AS

DECLARE @SourceSnapshotDataID uniqueidentifier
SET @SourceSnapshotDataID = (SELECT SnapshotDataID FROM Catalog WHERE ItemID = @SourceReportID)
DECLARE @TargetSnapshotDataID uniqueidentifier
SET @TargetSnapshotDataID = newid()
DECLARE @ChunkID uniqueidentifier

IF @SourceSnapshotDataID IS NOT NULL BEGIN
   -- We need to copy entries in SnapshotData and ChunkData tables.
   INSERT INTO SnapshotData
      (SnapshotDataID, CreatedDate, ParamsHash, QueryParams, EffectiveParams, Description, PermanentRefcount, TransientRefcount, ExpirationDate)
   SELECT
      @TargetSnapshotDataID, SD.CreatedDate, SD.ParamsHash, SD.QueryParams, SD.EffectiveParams, SD.Description, 1, 0, @ReservedUntilUTC
   FROM
      SnapshotData as SD
   WHERE
      SD.SnapshotDataID = @SourceSnapshotDataID

   INSERT INTO ChunkData
      (ChunkID, SnapshotDataID, ChunkName, ChunkType, ChunkFlags, Content, Version)
   SELECT
      newid(), @TargetSnapshotDataID, CD.ChunkName, CD.ChunkType, CD.ChunkFlags, CD.Content, CD.Version
   FROM
      ChunkData as CD
   WHERE
      CD.SnapshotDataID = @SourceSnapshotDataID

   UPDATE Target
   SET
      Target.SnapshotDataID = @TargetSnapshotDataID,
      Target.ExecutionTime = Source.ExecutionTime
   FROM
      Catalog Target,
      Catalog Source
   WHERE
     Source.ItemID = @SourceReportID AND
      Target.ItemID = @TargetReportID
   END

GO
GRANT EXECUTE ON [dbo].[CopyExecutionSnapshot] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CreateRole]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CreateRole]
GO

CREATE PROCEDURE [dbo].[CreateRole]
@RoleID as uniqueidentifier,
@RoleName as nvarchar(260),
@Description as nvarchar(512) = null,
@TaskMask as nvarchar(32),
@RoleFlags as tinyint
AS
INSERT INTO Roles
(RoleID, RoleName, Description, TaskMask, RoleFlags)
VALUES
(@RoleID, @RoleName, @Description, @TaskMask, @RoleFlags)
GO
GRANT EXECUTE ON [dbo].[CreateRole] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetRoles]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetRoles]
GO

CREATE PROCEDURE [dbo].[GetRoles]
@RoleFlags as tinyint = NULL
AS
SELECT
    RoleName,
    Description,
    TaskMask
FROM
    Roles
WHERE
    (@RoleFlags is NULL) OR
    (RoleFlags = @RoleFlags)
GO
GRANT EXECUTE ON [dbo].[GetRoles] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DeleteRole]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[DeleteRole]
GO

-- Delete all policies associated with this role
CREATE PROCEDURE [dbo].[DeleteRole]
@RoleName nvarchar(260)
AS
-- if you call this, you must delete/reconstruct all policies associated with this role
DELETE FROM Roles WHERE RoleName = @RoleName
GO

GRANT EXECUTE ON [dbo].[DeleteRole] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ReadRoleProperties]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[ReadRoleProperties]
GO

CREATE PROCEDURE [dbo].[ReadRoleProperties]
@RoleName as nvarchar(260)
AS 
SELECT Description, TaskMask, RoleFlags FROM Roles WHERE RoleName = @RoleName
GO
GRANT EXECUTE ON [dbo].[ReadRoleProperties] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SetRoleProperties]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SetRoleProperties]
GO

CREATE PROCEDURE [dbo].[SetRoleProperties]
@RoleName as nvarchar(260),
@Description as nvarchar(512) = NULL,
@TaskMask as nvarchar(32),
@RoleFlags as tinyint
AS 
DECLARE @ExistingRoleFlags as tinyint
SET @ExistingRoleFlags = (SELECT RoleFlags FROM Roles WHERE RoleName = @RoleName)
IF @ExistingRoleFlags IS NULL
BEGIN
    RETURN
END
IF @ExistingRoleFlags <> @RoleFlags
BEGIN
    RAISERROR ('Bad role flags', 16, 1)
END
UPDATE Roles SET 
Description = @Description, 
TaskMask = @TaskMask,
RoleFlags = @RoleFlags
WHERE RoleName = @RoleName
GO
GRANT EXECUTE ON [dbo].[SetRoleProperties] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetPoliciesForRole]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetPoliciesForRole]
GO

CREATE PROCEDURE [dbo].[GetPoliciesForRole]
@RoleName as nvarchar(260),
@AuthType as int
AS 
SELECT
    Policies.PolicyID,
    SecData.XmlDescription, 
    Policies.PolicyFlag,
    Catalog.Type,
    Catalog.Path,
    ModelItemPolicy.CatalogItemID,
    ModelItemPolicy.ModelItemID,
    RelatedRoles.RoleID,
    RelatedRoles.RoleName,
    RelatedRoles.TaskMask,
    RelatedRoles.RoleFlags
FROM
    Roles
    INNER JOIN PolicyUserRole ON Roles.RoleID = PolicyUserRole.RoleID
    INNER JOIN Policies ON PolicyUserRole.PolicyID = Policies.PolicyID
    INNER JOIN PolicyUserRole AS RelatedPolicyUserRole ON Policies.PolicyID = RelatedPolicyUserRole.PolicyID
    INNER JOIN Roles AS RelatedRoles ON RelatedPolicyUserRole.RoleID = RelatedRoles.RoleID
    LEFT OUTER JOIN SecData ON Policies.PolicyID = SecData.PolicyID AND SecData.AuthType = @AuthType
    LEFT OUTER JOIN Catalog ON Policies.PolicyID = Catalog.PolicyID AND Catalog.PolicyRoot = 1
    LEFT OUTER JOIN ModelItemPolicy ON Policies.PolicyID = ModelItemPolicy.PolicyID
WHERE
    Roles.RoleName = @RoleName
ORDER BY
    Policies.PolicyID
GO
GRANT EXECUTE ON [dbo].[GetPoliciesForRole] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[UpdatePolicy]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[UpdatePolicy]
GO

CREATE PROCEDURE [dbo].[UpdatePolicy]
@PolicyID as uniqueidentifier,
@PrimarySecDesc as image,
@SecondarySecDesc as ntext = NULL,
@AuthType int
AS
UPDATE SecData SET NtSecDescPrimary = @PrimarySecDesc,
NtSecDescSecondary = @SecondarySecDesc 
WHERE SecData.PolicyID = @PolicyID
AND SecData.AuthType = @AuthType
GO
GRANT EXECUTE ON [dbo].[UpdatePolicy] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SetPolicy]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SetPolicy]
GO

-- this assumes the item exists in the catalog
CREATE PROCEDURE [dbo].[SetPolicy]
@ItemName as nvarchar(425),
@ItemNameLike as nvarchar(850),
@PrimarySecDesc as image,
@SecondarySecDesc as ntext = NULL,
@XmlPolicy as ntext,
@AuthType int,
@PolicyID uniqueidentifier OUTPUT
AS 
SELECT @PolicyID = (SELECT PolicyID FROM Catalog WHERE Path = @ItemName AND PolicyRoot = 1)
IF (@PolicyID IS NULL)
   BEGIN -- this is not a policy root
     SET @PolicyID = newid()
     INSERT INTO Policies (PolicyID, PolicyFlag)
     VALUES (@PolicyID, 0)
     INSERT INTO SecData (SecDataID, PolicyID, AuthType, XmlDescription, NTSecDescPrimary, NtSecDescSecondary)
     VALUES (newid(), @PolicyID, @AuthType, @XmlPolicy, @PrimarySecDesc, @SecondarySecDesc)
     DECLARE @OldPolicyID as uniqueidentifier
     SELECT @OldPolicyID = (SELECT PolicyID FROM Catalog WHERE Path = @ItemName)
     -- update item and children that shared the old policy
     UPDATE Catalog SET PolicyID = @PolicyID, PolicyRoot = 1 WHERE Path = @ItemName 
     UPDATE Catalog SET PolicyID = @PolicyID 
    WHERE Path LIKE @ItemNameLike ESCAPE '*' 
    AND Catalog.PolicyID = @OldPolicyID
   END
ELSE
   BEGIN
      UPDATE Policies SET 
      PolicyFlag = 0
      WHERE Policies.PolicyID = @PolicyID
      DECLARE @SecDataID as uniqueidentifier
      SELECT @SecDataID = (SELECT SecDataID FROM SecData WHERE PolicyID = @PolicyID and AuthType = @AuthType)
      IF (@SecDataID IS NULL)
      BEGIN -- insert new sec desc's
        INSERT INTO SecData (SecDataID, PolicyID, AuthType, XmlDescription ,NTSecDescPrimary, NtSecDescSecondary)
        VALUES (newid(), @PolicyID, @AuthType, @XmlPolicy, @PrimarySecDesc, @SecondarySecDesc)
      END
      ELSE
      BEGIN -- update existing sec desc's
        UPDATE SecData SET 
        XmlDescription = @XmlPolicy,
        NtSecDescPrimary = @PrimarySecDesc,
        NtSecDescSecondary = @SecondarySecDesc
        WHERE SecData.PolicyID = @PolicyID
        AND AuthType = @AuthType
      END
   END
DELETE FROM PolicyUserRole WHERE PolicyID = @PolicyID 
GO
GRANT EXECUTE ON [dbo].[SetPolicy] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SetSystemPolicy]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SetSystemPolicy]
GO

-- update the system policy
CREATE PROCEDURE [dbo].[SetSystemPolicy]
@PrimarySecDesc as image,
@SecondarySecDesc as ntext = NULL,
@XmlPolicy as ntext,
@AuthType as int,
@PolicyID uniqueidentifier OUTPUT
AS 
SELECT @PolicyID = (SELECT PolicyID FROM Policies WHERE PolicyFlag = 1)
IF (@PolicyID IS NULL)
   BEGIN
     SET @PolicyID = newid()
     INSERT INTO Policies (PolicyID, PolicyFlag)
     VALUES (@PolicyID, 1)
     INSERT INTO SecData (SecDataID, PolicyID, AuthType, XmlDescription, NTSecDescPrimary, NtSecDescSecondary)
     VALUES (newid(), @PolicyID, @AuthType, @XmlPolicy, @PrimarySecDesc, @SecondarySecDesc)
   END
ELSE
   BEGIN
      DECLARE @SecDataID as uniqueidentifier
      SELECT @SecDataID = (SELECT SecDataID FROM SecData WHERE PolicyID = @PolicyID and AuthType = @AuthType)
      IF (@SecDataID IS NULL)
      BEGIN -- insert new sec desc's
        INSERT INTO SecData (SecDataID, PolicyID, AuthType, XmlDescription, NTSecDescPrimary, NtSecDescSecondary)
        VALUES (newid(), @PolicyID, @AuthType, @XmlPolicy, @PrimarySecDesc, @SecondarySecDesc)
      END
      ELSE
      BEGIN -- update existing sec desc's
        UPDATE SecData SET 
        XmlDescription = @XmlPolicy,
        NtSecDescPrimary = @PrimarySecDesc,
        NtSecDescSecondary = @SecondarySecDesc
        WHERE SecData.PolicyID = @PolicyID
        AND AuthType = @AuthType

      END      
   END
DELETE FROM PolicyUserRole WHERE PolicyID = @PolicyID 
GO
GRANT EXECUTE ON [dbo].[SetSystemPolicy] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SetModelItemPolicy]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SetModelItemPolicy]
GO

-- update the system policy
CREATE PROCEDURE [dbo].[SetModelItemPolicy]
@CatalogItemID as uniqueidentifier,
@ModelItemID as nvarchar(425),
@PrimarySecDesc as image,
@SecondarySecDesc as ntext = NULL,
@XmlPolicy as ntext,
@AuthType as int,
@PolicyID uniqueidentifier OUTPUT
AS 
SELECT @PolicyID = (SELECT PolicyID FROM ModelItemPolicy WHERE CatalogItemID = @CatalogItemID AND ModelItemID = @ModelItemID )
IF (@PolicyID IS NULL)
   BEGIN
     SET @PolicyID = newid()
     INSERT INTO Policies (PolicyID, PolicyFlag)
     VALUES (@PolicyID, 2)
     INSERT INTO SecData (SecDataID, PolicyID, AuthType, XmlDescription, NTSecDescPrimary, NtSecDescSecondary)
     VALUES (newid(), @PolicyID, @AuthType, @XmlPolicy, @PrimarySecDesc, @SecondarySecDesc)
     INSERT INTO ModelItemPolicy (ID, CatalogItemID, ModelItemID, PolicyID)
     VALUES (newid(), @CatalogItemID, @ModelItemID, @PolicyID)
   END
ELSE
   BEGIN
      DECLARE @SecDataID as uniqueidentifier
      SELECT @SecDataID = (SELECT SecDataID FROM SecData WHERE PolicyID = @PolicyID and AuthType = @AuthType)
      IF (@SecDataID IS NULL)
      BEGIN -- insert new sec desc's
        INSERT INTO SecData (SecDataID, PolicyID, AuthType, XmlDescription, NTSecDescPrimary, NtSecDescSecondary)
        VALUES (newid(), @PolicyID, @AuthType, @XmlPolicy, @PrimarySecDesc, @SecondarySecDesc)
      END
      ELSE
      BEGIN -- update existing sec desc's
        UPDATE SecData SET 
        XmlDescription = @XmlPolicy,
        NtSecDescPrimary = @PrimarySecDesc,
        NtSecDescSecondary = @SecondarySecDesc
        WHERE SecData.PolicyID = @PolicyID
        AND AuthType = @AuthType

      END      
   END
DELETE FROM PolicyUserRole WHERE PolicyID = @PolicyID 
GO
GRANT EXECUTE ON [dbo].[SetModelItemPolicy] TO RSExecRole
GO


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[UpdatePolicyPrincipal]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[UpdatePolicyPrincipal]
GO

CREATE PROCEDURE [dbo].[UpdatePolicyPrincipal]
@PolicyID uniqueidentifier,
@PrincipalSid varbinary(85) = NULL,
@PrincipalName nvarchar(260),
@PrincipalAuthType int,
@RoleName nvarchar(260),
@PrincipalID uniqueidentifier OUTPUT,
@RoleID uniqueidentifier OUTPUT
AS 
EXEC GetPrincipalID @PrincipalSid , @PrincipalName, @PrincipalAuthType, @PrincipalID  OUTPUT
SELECT @RoleID = (SELECT RoleID FROM Roles WHERE RoleName = @RoleName)
INSERT INTO PolicyUserRole 
(ID, RoleID, UserID, PolicyID)
VALUES (newid(), @RoleID, @PrincipalID, @PolicyID)
GO
GRANT EXECUTE ON [dbo].[UpdatePolicyPrincipal] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[UpdatePolicyRole]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[UpdatePolicyRole]
GO

CREATE PROCEDURE [dbo].[UpdatePolicyRole]
@PolicyID uniqueidentifier,
@PrincipalID uniqueidentifier,
@RoleName nvarchar(260),
@RoleID uniqueidentifier OUTPUT
AS 
SELECT @RoleID = (SELECT RoleID FROM Roles WHERE RoleName = @RoleName)
INSERT INTO PolicyUserRole 
(ID, RoleID, UserID, PolicyID)
VALUES (newid(), @RoleID, @PrincipalID, @PolicyID)
GO
GRANT EXECUTE ON [dbo].[UpdatePolicyRole] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetPolicy]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetPolicy]
GO

CREATE PROCEDURE [dbo].[GetPolicy]
@ItemName as nvarchar(425),
@AuthType int
AS 
SELECT SecData.XmlDescription, Catalog.PolicyRoot , SecData.NtSecDescPrimary, Catalog.Type
FROM Catalog 
INNER JOIN Policies ON Catalog.PolicyID = Policies.PolicyID 
LEFT OUTER JOIN SecData ON Policies.PolicyID = SecData.PolicyID AND AuthType = @AuthType
WHERE Catalog.Path = @ItemName
AND PolicyFlag = 0
GO
GRANT EXECUTE ON [dbo].[GetPolicy] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetSystemPolicy]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetSystemPolicy]
GO

CREATE PROCEDURE [dbo].[GetSystemPolicy]
@AuthType int
AS 
SELECT SecData.NtSecDescPrimary, SecData.XmlDescription
FROM Policies 
LEFT OUTER JOIN SecData ON Policies.PolicyID = SecData.PolicyID AND AuthType = @AuthType
WHERE PolicyFlag = 1
GO
GRANT EXECUTE ON [dbo].[GetSystemPolicy] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DeletePolicy]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[DeletePolicy]
GO

CREATE PROCEDURE [dbo].[DeletePolicy]
@ItemName as nvarchar(425)
AS 
DECLARE @OldPolicyID uniqueidentifier
SELECT @OldPolicyID = (SELECT PolicyID FROM Catalog WHERE Catalog.Path = @ItemName)
UPDATE Catalog SET PolicyID = 
(SELECT Parent.PolicyID FROM Catalog Parent, Catalog WHERE Parent.ItemID = Catalog.ParentID AND Catalog.Path = @ItemName),
PolicyRoot = 0
WHERE Catalog.PolicyID = @OldPolicyID
DELETE Policies FROM Policies WHERE Policies.PolicyID = @OldPolicyID 
GO
GRANT EXECUTE ON [dbo].[DeletePolicy] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CreateSession]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CreateSession]
GO

-- Writes or updates session record
CREATE PROCEDURE [dbo].[CreateSession]
@SessionID as varchar(32),
@CompiledDefinition as uniqueidentifier = NULL,
@SnapshotDataID as uniqueidentifier = NULL,
@IsPermanentSnapshot as bit = NULL,
@ReportPath as nvarchar(440) = NULL,
@Timeout as int,
@AutoRefreshSeconds as int = NULL,
@DataSourceInfo as image = NULL,
@OwnerName as nvarchar (260),
@OwnerSid as varbinary (85) = NULL,
@AuthType as int,
@EffectiveParams as ntext = NULL,
@HistoryDate as datetime = NULL,
@PageHeight as float = NULL,
@PageWidth as float = NULL,
@TopMargin as float = NULL,
@BottomMargin as float = NULL,
@LeftMargin as float = NULL,
@RightMargin as float = NULL,
@AwaitingFirstExecution as bit = NULL
AS

UPDATE PS
SET PS.RefCount = 1
FROM
    [ReportServerTempDB].dbo.PersistedStream as PS
WHERE
    PS.SessionID = @SessionID	
    
UPDATE SN
SET TransientRefcount = TransientRefcount + 1
FROM
   SnapshotData AS SN
WHERE
   SN.SnapshotDataID = @SnapshotDataID
   
UPDATE SN
SET TransientRefcount = TransientRefcount + 1
FROM
   [ReportServerTempDB].dbo.SnapshotData AS SN
WHERE
   SN.SnapshotDataID = @SnapshotDataID

DECLARE @OwnerID uniqueidentifier
EXEC GetUserID @OwnerSid, @OwnerName, @AuthType, @OwnerID OUTPUT

DECLARE @now datetime
SET @now = GETDATE()

INSERT
   INTO [ReportServerTempDB].dbo.SessionData (
      SessionID,
      CompiledDefinition,
      SnapshotDataID,
      IsPermanentSnapshot,
      ReportPath,
      Timeout,
      AutoRefreshSeconds,
      Expiration,
      DataSourceInfo,
      OwnerID,
      EffectiveParams,
      CreationTime,
      HistoryDate,
      PageHeight,
      PageWidth,
      TopMargin,
      BottomMargin,
      LeftMargin,
      RightMargin,
      AwaitingFirstExecution )
   VALUES (
      @SessionID,
      @CompiledDefinition,
      @SnapshotDataID,
      @IsPermanentSnapshot,
      @ReportPath,
      @Timeout,
      @AutoRefreshSeconds,
      DATEADD(s, @Timeout, @now),
      @DataSourceInfo,
      @OwnerID,
      @EffectiveParams,
      @now,
      @HistoryDate,
      @PageHeight,
      @PageWidth,
      @TopMargin,
      @BottomMargin,
      @LeftMargin,
      @RightMargin,
      @AwaitingFirstExecution )
      
GO

GRANT EXECUTE ON [dbo].[CreateSession] TO RSExecRole
GO


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DeleteModelItemPolicy]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[DeleteModelItemPolicy]
GO

CREATE PROCEDURE [dbo].[DeleteModelItemPolicy]
@CatalogItemID as uniqueidentifier,
@ModelItemID as nvarchar(425)
AS 
DECLARE @PolicyID uniqueidentifier
SELECT @PolicyID = (SELECT PolicyID FROM ModelItemPolicy WHERE CatalogItemID = @CatalogItemID AND ModelItemID = @ModelItemID)
DELETE Policies FROM Policies WHERE Policies.PolicyID = @PolicyID
GO
GRANT EXECUTE ON [dbo].[DeleteModelItemPolicy] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DeleteAllModelItemPolicies]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[DeleteAllModelItemPolicies]
GO

CREATE PROCEDURE [dbo].[DeleteAllModelItemPolicies]
@Path as nvarchar(450)
AS 

DELETE Policies
FROM
   Policies AS P
   INNER JOIN ModelItemPolicy AS MIP ON P.PolicyID = MIP.PolicyID
   INNER JOIN Catalog AS C ON MIP.CatalogItemID = C.ItemID
WHERE
   C.[Path] = @Path

GO
GRANT EXECUTE ON [dbo].[DeleteAllModelItemPolicies] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetModelItemInfo]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetModelItemInfo]
GO

CREATE PROCEDURE [dbo].[GetModelItemInfo]
@Path nvarchar (425)
AS

SELECT
    MIP.[ModelItemID], SD.[NtSecDescPrimary], SD.[XmlDescription]
FROM
    [Catalog] AS C
    INNER JOIN [ModelItemPolicy] AS MIP ON C.[ItemID] = MIP.[CatalogItemID]
    LEFT OUTER JOIN [SecData] AS SD ON MIP.[PolicyID] = SD.[PolicyID]
WHERE
    C.[Path] = @Path
    
GO
GRANT EXECUTE ON [dbo].[GetModelItemInfo] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetModelDefinition]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetModelDefinition]
GO

CREATE PROCEDURE [dbo].[GetModelDefinition]
@CatalogItemID as uniqueidentifier
AS

SELECT
    C.[Content]
FROM
    [Catalog] AS C
WHERE
    C.[ItemID] = @CatalogItemID
    
GO
GRANT EXECUTE ON [dbo].[GetModelDefinition] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[AddModelPerspective]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[AddModelPerspective]
GO

CREATE PROCEDURE [dbo].[AddModelPerspective]
@ModelID as uniqueidentifier,
@PerspectiveID as ntext,
@PerspectiveName as ntext = null,
@PerspectiveDescription as ntext = null
AS

INSERT
INTO [ModelPerspective]
    ([ID], [ModelID], [PerspectiveID], [PerspectiveName], [PerspectiveDescription])
VALUES
    (newid(), @ModelID, @PerspectiveID, @PerspectiveName, @PerspectiveDescription)
GO
GRANT EXECUTE ON [dbo].[AddModelPerspective] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DeleteModelPerspectives]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[DeleteModelPerspectives]
GO

CREATE PROCEDURE [dbo].[DeleteModelPerspectives]
@ModelID as uniqueidentifier
AS

DELETE
FROM [ModelPerspective]
WHERE [ModelID] = @ModelID
GO
GRANT EXECUTE ON [dbo].[DeleteModelPerspectives] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetModelsAndPerspectives]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetModelsAndPerspectives]
GO

CREATE PROCEDURE [dbo].[GetModelsAndPerspectives]
@AuthType int,
@SitePathPrefix nvarchar(520) = '%'
AS

SELECT
    C.[PolicyID],
    SD.[NtSecDescPrimary],
    C.[ItemID],
    C.[Path],
    C.[Description],
    P.[PerspectiveID],
    P.[PerspectiveName],
    P.[PerspectiveDescription]
FROM
    [Catalog] as C
    LEFT OUTER JOIN [ModelPerspective] as P ON C.[ItemID] = P.[ModelID]
    LEFT OUTER JOIN [SecData] AS SD ON C.[PolicyID] = SD.[PolicyID] AND SD.[AuthType] = @AuthType
WHERE
    C.Path like @SitePathPrefix AND C.[Type] = 6 -- Model
ORDER BY
    C.[Path]    

GO
GRANT EXECUTE ON [dbo].[GetModelsAndPerspectives] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetModelPerspectives]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetModelPerspectives]
GO

CREATE PROCEDURE [dbo].[GetModelPerspectives]
@Path nvarchar (425),
@AuthType int
AS

SELECT
    C.[Type],
    SD.[NtSecDescPrimary],
    C.[Description]
FROM
    [Catalog] as C
    LEFT OUTER JOIN [SecData] AS SD ON C.[PolicyID] = SD.[PolicyID] AND SD.[AuthType] = @AuthType
WHERE
    [Path] = @Path

SELECT
    P.[PerspectiveID],
    P.[PerspectiveName],
    P.[PerspectiveDescription]
FROM
    [Catalog] as C
    INNER JOIN [ModelPerspective] as P ON C.[ItemID] = P.[ModelID]
WHERE
    [Path] = @Path

GO
GRANT EXECUTE ON [dbo].[GetModelPerspectives] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DereferenceSessionSnapshot]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[DereferenceSessionSnapshot]
GO

CREATE PROCEDURE [dbo].[DereferenceSessionSnapshot]
@SessionID as varchar(32),
@OwnerID as uniqueidentifier
AS

UPDATE SN
SET TransientRefcount = TransientRefcount - 1
FROM
   SnapshotData AS SN
   INNER JOIN [ReportServerTempDB].dbo.SessionData AS SE ON SN.SnapshotDataID = SE.SnapshotDataID
WHERE
   SE.SessionID = @SessionID AND
   SE.OwnerID = @OwnerID
   
UPDATE SN
SET TransientRefcount = TransientRefcount - 1
FROM
   [ReportServerTempDB].dbo.SnapshotData AS SN
   INNER JOIN [ReportServerTempDB].dbo.SessionData AS SE ON SN.SnapshotDataID = SE.SnapshotDataID
WHERE
   SE.SessionID = @SessionID AND
   SE.OwnerID = @OwnerID
   
GO
GRANT EXECUTE ON [dbo].[DereferenceSessionSnapshot] TO RSExecRole
GO


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SetSessionData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SetSessionData]
GO

-- Writes or updates session record
CREATE PROCEDURE [dbo].[SetSessionData]
@SessionID as varchar(32),
@ReportPath as nvarchar(440),
@HistoryDate as datetime = NULL,
@Timeout as int,
@AutoRefreshSeconds as int = NULL,
@EffectiveParams ntext = NULL,
@OwnerSid as varbinary (85) = NULL,
@OwnerName as nvarchar (260),
@AuthType as int,
@ShowHideInfo as image = NULL,
@DataSourceInfo as image = NULL,
@SnapshotDataID as uniqueidentifier = NULL,
@IsPermanentSnapshot as bit = NULL,
@SnapshotTimeoutSeconds as int = NULL,
@HasInteractivity as bit,
@SnapshotExpirationDate as datetime = NULL,
@AwaitingFirstExecution as bit  = NULL
AS

DECLARE @OwnerID uniqueidentifier
EXEC GetUserID @OwnerSid, @OwnerName, @AuthType, @OwnerID OUTPUT

DECLARE @now datetime
SET @now = GETDATE()

-- is there a session for the same report ?
DECLARE @OldSnapshotDataID uniqueidentifier
DECLARE @OldIsPermanentSnapshot bit
DECLARE @OldSessionID varchar(32)

SELECT
   @OldSessionID = SessionID,
   @OldSnapshotDataID = SnapshotDataID,
   @OldIsPermanentSnapshot = IsPermanentSnapshot
FROM [ReportServerTempDB].dbo.SessionData WITH (XLOCK) 
WHERE SessionID = @SessionID

IF @OldSessionID IS NOT NULL
BEGIN -- Yes, update it
   IF @OldSnapshotDataID != @SnapshotDataID or @SnapshotDataID is NULL BEGIN
      EXEC DereferenceSessionSnapshot @SessionID, @OwnerID
   END

   UPDATE
      [ReportServerTempDB].dbo.SessionData
   SET
      SnapshotDataID = @SnapshotDataID,
      IsPermanentSnapshot = @IsPermanentSnapshot,
      Timeout = @Timeout,
      AutoRefreshSeconds = @AutoRefreshSeconds,
      SnapshotExpirationDate = @SnapshotExpirationDate,
      -- we want database session to expire later than in-memory session
      Expiration = DATEADD(s, @Timeout+10, @now),
      ShowHideInfo = @ShowHideInfo,
      DataSourceInfo = @DataSourceInfo,
      AwaitingFirstExecution = @AwaitingFirstExecution
      -- EffectiveParams = @EffectiveParams, -- no need to update user params as they are always same
      -- ReportPath = @ReportPath
      -- OwnerID = @OwnerID
   WHERE
      SessionID = @SessionID

   -- update expiration date on a snapshot that we reference
   IF @IsPermanentSnapshot != 0 BEGIN
      UPDATE
         SnapshotData
      SET
         ExpirationDate = DATEADD(n, @SnapshotTimeoutSeconds, @now)
      WHERE
         SnapshotDataID = @SnapshotDataID
   END ELSE BEGIN
      UPDATE
         [ReportServerTempDB].dbo.SnapshotData
      SET
         ExpirationDate = DATEADD(n, @SnapshotTimeoutSeconds, @now)
      WHERE
         SnapshotDataID = @SnapshotDataID
   END

END
ELSE
BEGIN -- no, insert it
   UPDATE PS
    SET PS.RefCount = 1
    FROM
        [ReportServerTempDB].dbo.PersistedStream as PS
    WHERE
        PS.SessionID = @SessionID	
        
    INSERT INTO [ReportServerTempDB].dbo.SessionData
      (SessionID, SnapshotDataID, IsPermanentSnapshot, ReportPath,
       EffectiveParams, Timeout, AutoRefreshSeconds, Expiration,
       ShowHideInfo, DataSourceInfo, OwnerID, 
       CreationTime, HasInteractivity, SnapshotExpirationDate, HistoryDate, AwaitingFirstExecution)
   VALUES
      (@SessionID, @SnapshotDataID, @IsPermanentSnapshot, @ReportPath,
       @EffectiveParams, @Timeout, @AutoRefreshSeconds, DATEADD(s, @Timeout, @now),
       @ShowHideInfo, @DataSourceInfo, @OwnerID, @now,
       @HasInteractivity, @SnapshotExpirationDate, @HistoryDate, @AwaitingFirstExecution)
END
GO

GRANT EXECUTE ON [dbo].[SetSessionData] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[WriteLockSession]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[WriteLockSession]
GO

CREATE PROCEDURE [dbo].[WriteLockSession]
@SessionID as varchar(32)
AS
INSERT INTO [ReportServerTempDB].dbo.SessionLock WITH (ROWLOCK) (SessionID) VALUES (@SessionID)
GO

GRANT EXECUTE ON [dbo].[WriteLockSession] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CheckSessionLock]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CheckSessionLock]
GO

CREATE PROCEDURE [dbo].[CheckSessionLock]
@SessionID as varchar(32)
AS
DECLARE @Selected nvarchar(32)
SELECT @Selected=SessionID FROM [ReportServerTempDB].dbo.SessionLock WITH (ROWLOCK) WHERE SessionID = @SessionID
GO

GRANT EXECUTE ON [dbo].[CheckSessionLock] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ReadLockSnapshot]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[ReadLockSnapshot]
GO

CREATE PROCEDURE [dbo].[ReadLockSnapshot]
@SnapshotDataID as uniqueidentifier
AS
SELECT SnapshotDataID
FROM
   SnapshotData WITH (REPEATABLEREAD, ROWLOCK)
WHERE
   SnapshotDataID = @SnapshotDataID     
GO

GRANT EXECUTE ON [dbo].[ReadLockSnapshot] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetSessionData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetSessionData]
GO

-- Get record from session data, update session and snapshot
CREATE PROCEDURE [dbo].[GetSessionData]
@SessionID as varchar(32),
@OwnerSid as varbinary(85) = NULL,
@OwnerName as nvarchar(260),
@AuthType as int,
@SnapshotTimeoutMinutes as int
AS

DECLARE @now as datetime
SET @now = GETDATE()

DECLARE @DBSessionID varchar(32)
DECLARE @SnapshotDataID uniqueidentifier
DECLARE @IsPermanentSnapshot bit

EXEC CheckSessionLock @SessionID = @SessionID

DECLARE @OwnerID uniqueidentifier
EXEC GetUserID @OwnerSid, @OwnerName, @AuthType, @OwnerID OUTPUT

SELECT
    @DBSessionID = SE.SessionID,
    @SnapshotDataID = SE.SnapshotDataID,
    @IsPermanentSnapshot = SE.IsPermanentSnapshot
FROM
    [ReportServerTempDB].dbo.SessionData AS SE WITH (XLOCK)
WHERE
    SE.OwnerID = @OwnerID AND
    SE.SessionID = @SessionID AND 
    SE.Expiration > @now

-- We need this update to keep session around while we process it.
-- TODO: This assumes that it will be processed within the session timeout.
UPDATE
   SE 
SET
   Expiration = DATEADD(s, Timeout, @now)
FROM
   [ReportServerTempDB].dbo.SessionData AS SE
WHERE
   SE.SessionID = @DBSessionID

-- Update snapshot expiration to prevent early deletion
-- If session uses snapshot, it is already refcounted. However, if session lasts for too long,
-- snapshot may expire. Therefore, every time we touch snapshot we should change expiration.

IF (@DBSessionID IS NOT NULL) BEGIN -- We return something only if session is present

IF @IsPermanentSnapshot != 0 BEGIN -- If session has snapshot and it is permanent

SELECT
    SN.SnapshotDataID,
    SE.ShowHideInfo,
    SE.DataSourceInfo,
    SN.Description,
    SE.EffectiveParams,
    SN.CreatedDate,
    SE.IsPermanentSnapshot,
    SE.CreationTime,
    SE.HasInteractivity,
    SE.Timeout,
    SE.SnapshotExpirationDate,
    SE.ReportPath,
    SE.HistoryDate,
    SE.CompiledDefinition,
    SN.PageCount,
    SN.HasDocMap,
    SE.Expiration,
    SN.EffectiveParams,
    SE.PageHeight,
    SE.PageWidth,
    SE.TopMargin,
    SE.BottomMargin,
    SE.LeftMargin,
    SE.RightMargin,
    SE.AutoRefreshSeconds,
    SE.AwaitingFirstExecution,
    SN.[DependsOnUser]
FROM
    [ReportServerTempDB].dbo.SessionData AS SE
    INNER JOIN SnapshotData AS SN ON SN.SnapshotDataID = SE.SnapshotDataID
WHERE
   SE.SessionID = @DBSessionID

UPDATE SnapshotData
SET ExpirationDate = DATEADD(n, @SnapshotTimeoutMinutes, @now)
WHERE SnapshotDataID = @SnapshotDataID

END ELSE IF @IsPermanentSnapshot = 0 BEGIN -- If session has snapshot and it is temporary

SELECT
    SN.SnapshotDataID,
    SE.ShowHideInfo,
    SE.DataSourceInfo,
    SN.Description,
    SE.EffectiveParams,
    SN.CreatedDate,
    SE.IsPermanentSnapshot,
    SE.CreationTime,
    SE.HasInteractivity,
    SE.Timeout,
    SE.SnapshotExpirationDate,
    SE.ReportPath,
    SE.HistoryDate,
    SE.CompiledDefinition,
    SN.PageCount,
    SN.HasDocMap,
    SE.Expiration,
    SN.EffectiveParams,
    SE.PageHeight,
    SE.PageWidth,
    SE.TopMargin,
    SE.BottomMargin,
    SE.LeftMargin,
    SE.RightMargin,
    SE.AutoRefreshSeconds,
    SE.AwaitingFirstExecution,
    SN.[DependsOnUser]
FROM
    [ReportServerTempDB].dbo.SessionData AS SE
    INNER JOIN [ReportServerTempDB].dbo.SnapshotData AS SN ON SN.SnapshotDataID = SE.SnapshotDataID
WHERE
   SE.SessionID = @DBSessionID
   
UPDATE [ReportServerTempDB].dbo.SnapshotData
SET ExpirationDate = DATEADD(n, @SnapshotTimeoutMinutes, @now)
WHERE SnapshotDataID = @SnapshotDataID

END ELSE BEGIN -- If session doesn't have snapshot

SELECT
    null,
    SE.ShowHideInfo,
    SE.DataSourceInfo,
    null,
    SE.EffectiveParams,
    null,
    SE.IsPermanentSnapshot,
    SE.CreationTime,
    SE.HasInteractivity,
    SE.Timeout,
    SE.SnapshotExpirationDate,
    SE.ReportPath,
    SE.HistoryDate,
    SE.CompiledDefinition,
    null,
    null,
    SE.Expiration,
    null,
    SE.PageHeight,
    SE.PageWidth,
    SE.TopMargin,
    SE.BottomMargin,
    SE.LeftMargin,
    SE.RightMargin,
    SE.AutoRefreshSeconds,
    SE.AwaitingFirstExecution,
    null
FROM
    [ReportServerTempDB].dbo.SessionData AS SE
WHERE
   SE.SessionID = @DBSessionID

END

END

GO
GRANT EXECUTE ON [dbo].[GetSessionData] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetSnapshotFromHistory]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetSnapshotFromHistory]
GO

CREATE PROCEDURE [dbo].[GetSnapshotFromHistory]
@Path nvarchar (425),
@SnapshotDate datetime,
@AuthType int
AS
SELECT
   Catalog.ItemID,
   Catalog.Type,
   SnapshotData.SnapshotDataID, 
   SnapshotData.DependsOnUser,
   SnapshotData.Description,
   SecData.NtSecDescPrimary,
   Catalog.[Property]
FROM 
   SnapshotData 
   INNER JOIN History ON History.SnapshotDataID = SnapshotData.SnapshotDataID
   INNER JOIN Catalog ON History.ReportID = Catalog.ItemID
   LEFT OUTER JOIN SecData ON Catalog.PolicyID = SecData.PolicyID AND SecData.AuthType = @AuthType
WHERE 
   Catalog.Path = @Path 
   AND History.SnapshotDate = @SnapshotDate
GO
GRANT EXECUTE ON [dbo].[GetSnapshotFromHistory] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CleanExpiredSessions]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CleanExpiredSessions]
GO

CREATE PROCEDURE [dbo].[CleanExpiredSessions]
@SessionsCleaned int OUTPUT
AS
SET DEADLOCK_PRIORITY LOW
DECLARE @now as datetime
SET @now = GETDATE()
CREATE TABLE #tempSession
   (SessionID varchar(32) COLLATE Latin1_General_CI_AS_KS_WS,
    SnapshotDataID uniqueidentifier,
    CompiledDefinition uniqueidentifier)

INSERT INTO #tempSession
SELECT TOP 20 SessionID, SnapshotDataID, CompiledDefinition
FROM [ReportServerTempDB].dbo.SessionData WITH (XLOCK)
WHERE Expiration < @now

SET @SessionsCleaned = @@ROWCOUNT
IF @SessionsCleaned = 0 RETURN

-- Mark persisted streams for this session to be deleted
UPDATE PS
SET
    RefCount = 0,
    ExpirationDate = GETDATE()
FROM
    [ReportServerTempDB].dbo.PersistedStream AS PS
    INNER JOIN #tempSession on PS.SessionID = #tempsession.SessionID

DELETE SE
FROM
   [ReportServerTempDB].dbo.SessionData AS SE
   INNER JOIN #tempSession on SE.SessionID = #tempsession.SessionID

UPDATE SN
SET
   TransientRefcount = TransientRefcount-1
FROM
   [ReportServerTempDB].dbo.SnapshotData AS SN
   INNER JOIN #tempSession AS SE ON SN.SnapshotDataID = SE.CompiledDefinition

UPDATE SN
SET
   TransientRefcount = TransientRefcount-
      (SELECT COUNT(*)
       FROM #tempSession AS SE1
       WHERE SE1.SnapshotDataID = SN.SnapshotDataID)
FROM
   SnapshotData AS SN
   INNER JOIN #tempSession AS SE ON SN.SnapshotDataID = SE.SnapshotDataID

UPDATE SN
SET
   TransientRefcount = TransientRefcount-
      (SELECT COUNT(*)
       FROM #tempSession AS SE1
       WHERE SE1.SnapshotDataID = SN.SnapshotDataID)
FROM
   [ReportServerTempDB].dbo.SnapshotData AS SN
   INNER JOIN #tempSession AS SE ON SN.SnapshotDataID = SE.SnapshotDataID

GO
GRANT EXECUTE ON [dbo].[CleanExpiredSessions] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CleanExpiredCache]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CleanExpiredCache]
GO

CREATE PROCEDURE [dbo].[CleanExpiredCache]
AS
DECLARE @now as datetime
SET @now = DATEADD(minute, -1, GETDATE())

UPDATE SN
SET
   PermanentRefcount = PermanentRefcount - 1
FROM
   [ReportServerTempDB].dbo.SnapshotData AS SN
   INNER JOIN [ReportServerTempDB].dbo.ExecutionCache AS EC ON SN.SnapshotDataID = EC.SnapshotDataID
WHERE
   EC.AbsoluteExpiration < @now
   
DELETE EC
FROM
   [ReportServerTempDB].dbo.ExecutionCache AS EC
WHERE
   EC.AbsoluteExpiration < @now
GO
GRANT EXECUTE ON [dbo].[CleanExpiredCache] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SetSessionCredentials]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SetSessionCredentials]
GO

CREATE PROCEDURE [dbo].[SetSessionCredentials]
@SessionID as varchar(32),
@OwnerSid as varbinary(85) = NULL,
@OwnerName as nvarchar(260),
@AuthType as int,
@DataSourceInfo as image = NULL,
@Expiration as datetime,
@EffectiveParams as ntext = NULL
AS

DECLARE @OwnerID uniqueidentifier
EXEC GetUserID @OwnerSid, @OwnerName, @AuthType, @OwnerID OUTPUT

EXEC DereferenceSessionSnapshot @SessionID, @OwnerID

UPDATE SE
SET
   SE.DataSourceInfo = @DataSourceInfo,
   SE.SnapshotDataID = null,
   SE.IsPermanentSnapshot = null,
   SE.SnapshotExpirationDate = null,
   SE.ShowHideInfo = null,
   SE.HasInteractivity = null,
   SE.AutoRefreshSeconds = null,
   SE.Expiration = @Expiration,
   SE.EffectiveParams = @EffectiveParams,
   SE.AwaitingFirstExecution = 1
FROM
   [ReportServerTempDB].dbo.SessionData AS SE
WHERE
   SE.SessionID = @SessionID AND
   SE.OwnerID = @OwnerID
GO
GRANT EXECUTE ON [dbo].[SetSessionCredentials] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SetSessionParameters]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SetSessionParameters]
GO

CREATE PROCEDURE [dbo].[SetSessionParameters]
@SessionID as varchar(32),
@OwnerSid as varbinary(85) = NULL,
@OwnerName as nvarchar(260),
@AuthType as int,
@EffectiveParams as ntext = NULL
AS

DECLARE @OwnerID uniqueidentifier
EXEC GetUserID @OwnerSid, @OwnerName, @AuthType, @OwnerID OUTPUT

UPDATE SE
SET
   SE.EffectiveParams = @EffectiveParams,
   SE.AwaitingFirstExecution = 1
FROM
   [ReportServerTempDB].dbo.SessionData AS SE
WHERE
   SE.SessionID = @SessionID AND
   SE.OwnerID = @OwnerID
GO
GRANT EXECUTE ON [dbo].[SetSessionParameters] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ClearSessionSnapshot]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[ClearSessionSnapshot]
GO

CREATE PROCEDURE [dbo].[ClearSessionSnapshot]
@SessionID as varchar(32),
@OwnerSid as varbinary(85) = NULL,
@OwnerName as nvarchar(260),
@AuthType as int,
@Expiration as datetime
AS

DECLARE @OwnerID uniqueidentifier
EXEC GetUserID @OwnerSid, @OwnerName, @AuthType, @OwnerID OUTPUT

EXEC DereferenceSessionSnapshot @SessionID, @OwnerID

UPDATE SE
SET
   SE.SnapshotDataID = null,
   SE.IsPermanentSnapshot = null,
   SE.SnapshotExpirationDate = null,
   SE.ShowHideInfo = null,
   SE.HasInteractivity = null,
   SE.AutoRefreshSeconds = null,
   SE.Expiration = @Expiration
FROM
   [ReportServerTempDB].dbo.SessionData AS SE
WHERE
   SE.SessionID = @SessionID AND
   SE.OwnerID = @OwnerID
GO
GRANT EXECUTE ON [dbo].[ClearSessionSnapshot] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[RemoveReportFromSession]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[RemoveReportFromSession]
GO

CREATE PROCEDURE [dbo].[RemoveReportFromSession]
@SessionID as varchar(32),
@ReportPath as nvarchar(440), 
@OwnerSid as varbinary(85) = NULL,
@OwnerName as nvarchar(260),
@AuthType as int
AS

DECLARE @OwnerID uniqueidentifier
EXEC GetUserID @OwnerSid, @OwnerName, @AuthType, @OwnerID OUTPUT

EXEC DereferenceSessionSnapshot @SessionID, @OwnerID
   
DELETE
   SE
FROM
   [ReportServerTempDB].dbo.SessionData AS SE
WHERE
   SE.SessionID = @SessionID AND
   SE.ReportPath = @ReportPath AND
   SE.OwnerID = @OwnerID
   
-- Delete any persisted streams associated with this session
UPDATE PS
SET
    PS.RefCount = 0,
    PS.ExpirationDate = GETDATE()
FROM
    [ReportServerTempDB].dbo.PersistedStream AS PS
WHERE
    PS.SessionID = @SessionID

GO
GRANT EXECUTE ON [dbo].[RemoveReportFromSession] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CleanBrokenSnapshots]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CleanBrokenSnapshots]
GO

CREATE PROCEDURE [dbo].[CleanBrokenSnapshots]
@Machine nvarchar(512),
@SnapshotsCleaned int OUTPUT,
@ChunksCleaned int OUTPUT,
@TempSnapshotID uniqueidentifier OUTPUT
AS
    SET DEADLOCK_PRIORITY LOW
    DECLARE @now AS datetime
    SELECT @now = GETDATE()
    
    CREATE TABLE #tempSnapshot (SnapshotDataID uniqueidentifier)
    INSERT INTO #tempSnapshot SELECT TOP 1 SnapshotDataID 
    FROM SnapshotData  WITH (NOLOCK) 
    where SnapshotData.PermanentRefcount <= 0 
    AND ExpirationDate < @now
    SET @SnapshotsCleaned = @@ROWCOUNT

    DELETE ChunkData FROM ChunkData INNER JOIN #tempSnapshot
    ON ChunkData.SnapshotDataID = #tempSnapshot.SnapshotDataID
    SET @ChunksCleaned = @@ROWCOUNT

    DELETE SnapshotData FROM SnapshotData INNER JOIN #tempSnapshot
    ON SnapshotData.SnapshotDataID = #tempSnapshot.SnapshotDataID
    
    TRUNCATE TABLE #tempSnapshot

    INSERT INTO #tempSnapshot SELECT TOP 1 SnapshotDataID 
    FROM [ReportServerTempDB].dbo.SnapshotData  WITH (NOLOCK) 
    where [ReportServerTempDB].dbo.SnapshotData.PermanentRefcount <= 0 
    AND [ReportServerTempDB].dbo.SnapshotData.ExpirationDate < @now
    AND [ReportServerTempDB].dbo.SnapshotData.Machine = @Machine
    SET @SnapshotsCleaned = @SnapshotsCleaned + @@ROWCOUNT

    SELECT @TempSnapshotID = (SELECT SnapshotDataID FROM #tempSnapshot)

    DELETE [ReportServerTempDB].dbo.ChunkData FROM [ReportServerTempDB].dbo.ChunkData INNER JOIN #tempSnapshot
    ON [ReportServerTempDB].dbo.ChunkData.SnapshotDataID = #tempSnapshot.SnapshotDataID
    SET @ChunksCleaned = @ChunksCleaned + @@ROWCOUNT

    DELETE [ReportServerTempDB].dbo.SnapshotData FROM [ReportServerTempDB].dbo.SnapshotData INNER JOIN #tempSnapshot
    ON [ReportServerTempDB].dbo.SnapshotData.SnapshotDataID = #tempSnapshot.SnapshotDataID
GO

GRANT EXECUTE ON [dbo].[CleanBrokenSnapshots] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CleanOrphanedSnapshots]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CleanOrphanedSnapshots]
GO

CREATE PROCEDURE [dbo].[CleanOrphanedSnapshots]
@Machine nvarchar(512),
@SnapshotsCleaned int OUTPUT,
@ChunksCleaned int OUTPUT,
@TempSnapshotID uniqueidentifier OUTPUT
AS 
    SET DEADLOCK_PRIORITY LOW
    CREATE TABLE #tempSnapshot (SnapshotDataID uniqueidentifier)
    INSERT INTO #tempSnapshot SELECT TOP 1 SnapshotDataID 
    FROM SnapshotData  WITH (NOLOCK) 
    where SnapshotData.PermanentRefcount = 0 
    AND SnapshotData.TransientRefcount = 0 
    SET @SnapshotsCleaned = @@ROWCOUNT

    DELETE ChunkData FROM ChunkData INNER JOIN #tempSnapshot
    ON ChunkData.SnapshotDataID = #tempSnapshot.SnapshotDataID
    SET @ChunksCleaned = @@ROWCOUNT

    DELETE SnapshotData FROM SnapshotData INNER JOIN #tempSnapshot
    ON SnapshotData.SnapshotDataID = #tempSnapshot.SnapshotDataID
    
    TRUNCATE TABLE #tempSnapshot

    INSERT INTO #tempSnapshot SELECT TOP 1 SnapshotDataID 
    FROM [ReportServerTempDB].dbo.SnapshotData  WITH (NOLOCK) 
    where [ReportServerTempDB].dbo.SnapshotData.PermanentRefcount = 0 
    AND [ReportServerTempDB].dbo.SnapshotData.TransientRefcount = 0 
    AND [ReportServerTempDB].dbo.SnapshotData.Machine = @Machine
    SET @SnapshotsCleaned = @SnapshotsCleaned + @@ROWCOUNT

    SELECT @TempSnapshotID = (SELECT SnapshotDataID FROM #tempSnapshot)

    DELETE [ReportServerTempDB].dbo.ChunkData FROM [ReportServerTempDB].dbo.ChunkData INNER JOIN #tempSnapshot
    ON [ReportServerTempDB].dbo.ChunkData.SnapshotDataID = #tempSnapshot.SnapshotDataID
    SET @ChunksCleaned = @ChunksCleaned + @@ROWCOUNT

    DELETE [ReportServerTempDB].dbo.SnapshotData FROM [ReportServerTempDB].dbo.SnapshotData INNER JOIN #tempSnapshot
    ON [ReportServerTempDB].dbo.SnapshotData.SnapshotDataID = #tempSnapshot.SnapshotDataID
GO
        
GRANT EXECUTE ON [dbo].[CleanOrphanedSnapshots] TO RSExecRole
GO


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SetCacheOptions]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SetCacheOptions]
GO

CREATE PROCEDURE [dbo].[SetCacheOptions]
@Path as nvarchar(425),
@CacheReport as bit,
@ExpirationFlags as int,
@CacheExpiration as int = NULL
AS
DECLARE @CachePolicyID as uniqueidentifier
SELECT @CachePolicyID = (SELECT CachePolicyID 
FROM CachePolicy with (XLOCK) INNER JOIN Catalog ON Catalog.ItemID = CachePolicy.ReportID
WHERE  Catalog.Path = @Path)
IF @CachePolicyID IS NULL -- no policy exists
BEGIN
    IF @CacheReport = 1 -- create a new one
    BEGIN
        INSERT INTO CachePolicy
        (CachePolicyID, ReportID, ExpirationFlags, CacheExpiration)
        (SELECT NEWID(), ItemID, @ExpirationFlags, @CacheExpiration
        FROM Catalog WHERE Catalog.Path = @Path)
    END
    -- ELSE if it has no policy and we want to remove its policy do nothing
END
ELSE -- existing policy
BEGIN
    IF @CacheReport = 1
    BEGIN
        UPDATE CachePolicy SET ExpirationFlags = @ExpirationFlags, CacheExpiration = @CacheExpiration
        WHERE CachePolicyID = @CachePolicyID
        EXEC FlushReportFromCache @Path
    END
    ELSE
    BEGIN
        DELETE FROM CachePolicy 
        WHERE CachePolicyID = @CachePolicyID
        EXEC FlushReportFromCache @Path
    END
END
GO
GRANT EXECUTE ON [dbo].[SetCacheOptions] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetCacheOptions]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetCacheOptions]
GO

CREATE PROCEDURE [dbo].[GetCacheOptions]
@Path as nvarchar(425)
AS
    SELECT ExpirationFlags, CacheExpiration, 
    S.[ScheduleID],
    S.[Name],
    S.[StartDate],
    S.[Flags],
    S.[NextRunTime],
    S.[LastRunTime],
    S.[EndDate],
    S.[RecurrenceType],
    S.[MinutesInterval],
    S.[DaysInterval],
    S.[WeeksInterval],
    S.[DaysOfWeek],
    S.[DaysOfMonth],
    S.[Month],
    S.[MonthlyWeek],
    S.[State], 
    S.[LastRunStatus],
    S.[ScheduledRunTimeout],
    S.[EventType],
    S.[EventData],
    S.[Type],
    S.[Path]
    FROM CachePolicy INNER JOIN Catalog ON Catalog.ItemID = CachePolicy.ReportID
    LEFT outer join reportschedule rs on catalog.itemid = rs.reportid and rs.reportaction = 3
    LEFT OUTER JOIN [Schedule] S ON S.ScheduleID = rs.ScheduleID
    LEFT OUTER JOIN [Users] Owner on Owner.UserID = S.[CreatedById]
    WHERE Catalog.Path = @Path 
GO
GRANT EXECUTE ON [dbo].[GetCacheOptions] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[AddReportToCache]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[AddReportToCache]
GO

CREATE PROCEDURE [dbo].[AddReportToCache]
@ReportID as uniqueidentifier,
@ExecutionDate datetime,
@SnapshotDataID uniqueidentifier,
@ExpirationDate datetime OUTPUT,
@ScheduleID uniqueidentifier OUTPUT
AS
DECLARE @ExpirationFlags as int
DECLARE @Timeout as int

SET @ExpirationDate = NULL
SET @ScheduleID = NULL
SET @ExpirationFlags = (SELECT ExpirationFlags FROM CachePolicy WHERE ReportID = @ReportID)
IF @ExpirationFlags = 1 -- timeout based
BEGIN
    SET @Timeout = (SELECT CacheExpiration FROM CachePolicy WHERE ReportID = @ReportID)
    SET @ExpirationDate = DATEADD(n, @Timeout, @ExecutionDate)
END
ELSE IF @ExpirationFlags = 2 -- schedule based
BEGIN
    SET @ScheduleID = (SELECT s.ScheduleID FROM Schedule s INNER JOIN ReportSchedule rs on rs.ScheduleID = s.ScheduleID and rs.ReportAction = 3 WHERE rs.ReportID = @ReportID)
    SET @ExpirationDate = (SELECT Schedule.NextRunTime FROM Schedule with (XLOCK) WHERE Schedule.ScheduleID = @ScheduleID)
END
ELSE
BEGIN
    RAISERROR('Invalid cache flags', 16, 1)
END

-- and to the report cache
INSERT INTO [ReportServerTempDB].dbo.ExecutionCache
(ExecutionCacheID, ReportID, ExpirationFlags, AbsoluteExpiration, RelativeExpiration, SnapshotDataID)
VALUES
(newid(), @ReportID, @ExpirationFlags, @ExpirationDate, @Timeout, @SnapshotDataID )

UPDATE [ReportServerTempDB].dbo.SnapshotData
SET PermanentRefcount = PermanentRefcount + 1
WHERE SnapshotDataID = @SnapshotDataID;   

GO
GRANT EXECUTE ON [dbo].[AddReportToCache] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetExecutionOptions]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetExecutionOptions]
GO

CREATE PROCEDURE [dbo].[GetExecutionOptions]
@Path nvarchar(425)
AS
    SELECT ExecutionFlag, 
    S.[ScheduleID],
    S.[Name],
    S.[StartDate],
    S.[Flags],
    S.[NextRunTime],
    S.[LastRunTime],
    S.[EndDate],
    S.[RecurrenceType],
    S.[MinutesInterval],
    S.[DaysInterval],
    S.[WeeksInterval],
    S.[DaysOfWeek],
    S.[DaysOfMonth],
    S.[Month],
    S.[MonthlyWeek],
    S.[State], 
    S.[LastRunStatus],
    S.[ScheduledRunTimeout],
    S.[EventType],
    S.[EventData],
    S.[Type],
    S.[Path]
    FROM Catalog 
    LEFT OUTER JOIN ReportSchedule ON Catalog.ItemID = ReportSchedule.ReportID AND ReportSchedule.ReportAction = 1
    LEFT OUTER JOIN [Schedule] S ON S.ScheduleID = ReportSchedule.ScheduleID
    LEFT OUTER JOIN [Users] Owner on Owner.UserID = S.[CreatedById]
    WHERE Catalog.Path = @Path 
GO
GRANT EXECUTE ON [dbo].[GetExecutionOptions] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SetExecutionOptions]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SetExecutionOptions]
GO

CREATE PROCEDURE [dbo].[SetExecutionOptions]
@Path as nvarchar(425),
@ExecutionFlag as int,
@ExecutionChanged as bit = 0
AS
IF @ExecutionChanged = 0
BEGIN
    UPDATE Catalog SET ExecutionFlag = @ExecutionFlag WHERE Catalog.Path = @Path
END
ELSE
BEGIN
    IF (@ExecutionFlag & 3) = 2
    BEGIN   -- set it to snapshot, flush cache
        EXEC FlushReportFromCache @Path
        DELETE CachePolicy FROM CachePolicy INNER JOIN Catalog ON CachePolicy.ReportID = Catalog.ItemID
        WHERE Catalog.Path = @Path
    END

    -- now clean existing snapshot and execution time if any
    UPDATE SnapshotData
    SET PermanentRefcount = PermanentRefcount - 1
    FROM
       SnapshotData
       INNER JOIN Catalog ON SnapshotData.SnapshotDataID = Catalog.SnapshotDataID
    WHERE Catalog.Path = @Path
    
    UPDATE Catalog
    SET ExecutionFlag = @ExecutionFlag, SnapshotDataID = NULL, ExecutionTime = NULL
    WHERE Catalog.Path = @Path
END
GO
GRANT EXECUTE ON [dbo].[SetExecutionOptions] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[UpdateSnapshot]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[UpdateSnapshot]
GO

CREATE PROCEDURE [dbo].[UpdateSnapshot]
@Path as nvarchar(425),
@SnapshotDataID as uniqueidentifier,
@executionDate as datetime
AS
DECLARE @OldSnapshotDataID uniqueidentifier
SET @OldSnapshotDataID = (SELECT SnapshotDataID FROM Catalog WITH (XLOCK) WHERE Catalog.Path = @Path)

-- update reference count in snapshot table
UPDATE SnapshotData
SET PermanentRefcount = PermanentRefcount-1
WHERE SnapshotData.SnapshotDataID = @OldSnapshotDataID

-- update catalog to point to the new execution snapshot
UPDATE Catalog
SET SnapshotDataID = @SnapshotDataID, ExecutionTime = @executionDate
WHERE Catalog.Path = @Path

UPDATE SnapshotData
SET PermanentRefcount = PermanentRefcount+1, TransientRefcount = TransientRefcount-1
WHERE SnapshotData.SnapshotDataID = @SnapshotDataID

GO

GRANT EXECUTE ON [dbo].[UpdateSnapshot] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CreateChunkAndGetPointer]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CreateChunkAndGetPointer]
GO

CREATE PROCEDURE [dbo].[CreateChunkAndGetPointer]
@SnapshotDataID uniqueidentifier,
@IsPermanentSnapshot bit,
@ChunkName nvarchar(260),
@ChunkType int,
@MimeType nvarchar(260) = NULL,
@Version smallint,
@Content image,
@ChunkFlags tinyint = NULL,
@ChunkPointer binary(16) OUTPUT
AS

DECLARE @ChunkID uniqueidentifier
SET @ChunkID = NEWID()

IF @IsPermanentSnapshot != 0 BEGIN

    DELETE ChunkData
    WHERE
        SnapshotDataID = @SnapshotDataID AND
        ChunkName = @ChunkName AND
        ChunkType = @ChunkType

    INSERT
    INTO ChunkData
        (ChunkID, SnapshotDataID, ChunkName, ChunkType, MimeType, Version, ChunkFlags, Content)
    VALUES
        (@ChunkID, @SnapshotDataID, @ChunkName, @ChunkType, @MimeType, @Version, @ChunkFlags, @Content)

    SELECT @ChunkPointer = TEXTPTR(Content)
                FROM ChunkData
                WHERE ChunkData.ChunkID = @ChunkID

END ELSE BEGIN

    DELETE [ReportServerTempDB].dbo.ChunkData
    WHERE
        SnapshotDataID = @SnapshotDataID AND
        ChunkName = @ChunkName AND
        ChunkType = @ChunkType

    INSERT
    INTO [ReportServerTempDB].dbo.ChunkData
        (ChunkID, SnapshotDataID, ChunkName, ChunkType, MimeType, Version, ChunkFlags, Content)
    VALUES
        (@ChunkID, @SnapshotDataID, @ChunkName, @ChunkType, @MimeType, @Version, @ChunkFlags, @Content)

    SELECT @ChunkPointer = TEXTPTR(Content)
                FROM [ReportServerTempDB].dbo.ChunkData AS CH
                WHERE CH.ChunkID = @ChunkID
END   
   
GO
GRANT EXECUTE ON [dbo].[CreateChunkAndGetPointer] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[WriteChunkPortion]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[WriteChunkPortion]
GO

CREATE PROCEDURE [dbo].[WriteChunkPortion]
@ChunkPointer binary(16),
@IsPermanentSnapshot bit,
@DataIndex int = NULL,
@DeleteLength int = NULL,
@Content image
AS

IF @IsPermanentSnapshot != 0 BEGIN
    UPDATETEXT ChunkData.Content @ChunkPointer @DataIndex @DeleteLength @Content
END ELSE BEGIN
    UPDATETEXT [ReportServerTempDB].dbo.ChunkData.Content @ChunkPointer @DataIndex @DeleteLength @Content
END

GO
GRANT EXECUTE ON [dbo].[WriteChunkPortion] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetChunkPointerAndLength]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetChunkPointerAndLength]
GO

CREATE PROCEDURE [dbo].[GetChunkPointerAndLength]
@SnapshotDataID uniqueidentifier,
@IsPermanentSnapshot bit,
@ChunkName nvarchar(260),
@ChunkType int
AS
IF @IsPermanentSnapshot != 0 BEGIN

    SELECT
       TEXTPTR(Content),
       DATALENGTH(Content),
       MimeType,
       ChunkFlags,
       Version
    FROM
       ChunkData AS CH WITH (HOLDLOCK, ROWLOCK)
    WHERE
       SnapshotDataID = @SnapshotDataID AND
       ChunkName = @ChunkName AND
       ChunkType = @ChunkType      
       
END ELSE BEGIN

    SELECT
       TEXTPTR(Content),
       DATALENGTH(Content),
       MimeType,
       ChunkFlags,
       Version
    FROM
       [ReportServerTempDB].dbo.ChunkData AS CH WITH (HOLDLOCK, ROWLOCK)
    WHERE
       SnapshotDataID = @SnapshotDataID AND
       ChunkName = @ChunkName AND
       ChunkType = @ChunkType      

END
GO
GRANT EXECUTE ON [dbo].[GetChunkPointerAndLength] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetChunkInformation]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetChunkInformation]
GO

CREATE PROCEDURE [dbo].[GetChunkInformation]
@SnapshotDataID uniqueidentifier,
@IsPermanentSnapshot bit,
@ChunkName nvarchar(260),
@ChunkType int
AS
IF @IsPermanentSnapshot != 0 BEGIN

    SELECT
       MimeType
    FROM
       ChunkData AS CH WITH (HOLDLOCK, ROWLOCK)
    WHERE
       SnapshotDataID = @SnapshotDataID AND
       ChunkName = @ChunkName AND
       ChunkType = @ChunkType      
       
END ELSE BEGIN

    SELECT
       MimeType
    FROM
       [ReportServerTempDB].dbo.ChunkData AS CH WITH (HOLDLOCK, ROWLOCK)
    WHERE
       SnapshotDataID = @SnapshotDataID AND
       ChunkName = @ChunkName AND
       ChunkType = @ChunkType      

END
GO
GRANT EXECUTE ON [dbo].[GetChunkInformation] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ReadChunkPortion]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[ReadChunkPortion]
GO

CREATE PROCEDURE [dbo].[ReadChunkPortion]
@ChunkPointer binary(16),
@IsPermanentSnapshot bit,
@DataIndex int,
@Length int
AS

IF @IsPermanentSnapshot != 0 BEGIN
    READTEXT ChunkData.Content @ChunkPointer @DataIndex @Length
END ELSE BEGIN
    READTEXT [ReportServerTempDB].dbo.ChunkData.Content @ChunkPointer @DataIndex @Length
END
GO
GRANT EXECUTE ON [dbo].[ReadChunkPortion] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CopyChunksOfType]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CopyChunksOfType]
GO

CREATE PROCEDURE [dbo].[CopyChunksOfType]
@FromSnapshotID uniqueidentifier,
@FromIsPermanent bit,
@ToSnapshotID uniqueidentifier,
@ToIsPermanent bit,
@ChunkType int
AS

IF @FromIsPermanent != 0 AND @ToIsPermanent = 0 BEGIN

    INSERT INTO [ReportServerTempDB].dbo.ChunkData
        (ChunkID, SnapshotDataID, ChunkName, ChunkType, MimeType, Version, ChunkFlags, Content)
    SELECT
        newid(), @ToSnapshotID, S.ChunkName, S.ChunkType, S.MimeType, S.Version, S.ChunkFlags, S.Content
    FROM
        ChunkData AS S
    WHERE   
        S.SnapshotDataID = @FromSnapshotID AND
        S.ChunkType = @ChunkType AND
    NOT EXISTS(
        SELECT T.ChunkName
        FROM [ReportServerTempDB].dbo.ChunkData AS T -- exclude the ones in the target
        WHERE
            T.ChunkName = S.ChunkName AND
            T.ChunkType = S.ChunkType AND
            T.SnapshotDataID = @ToSnapshotID)

END ELSE IF @FromIsPermanent = 0 AND @ToIsPermanent = 0 BEGIN

    INSERT INTO [ReportServerTempDB].dbo.ChunkData
        (ChunkID, SnapshotDataID, ChunkName, ChunkType, MimeType, Version, ChunkFlags, Content)
    SELECT
        newid(), @ToSnapshotID, S.ChunkName, S.ChunkType, S.MimeType, S.Version, S.ChunkFlags, S.Content
    FROM
        [ReportServerTempDB].dbo.ChunkData AS S
    WHERE   
        S.SnapshotDataID = @FromSnapshotID AND
        S.ChunkType = @ChunkType AND
        NOT EXISTS(
            SELECT T.ChunkName
            FROM [ReportServerTempDB].dbo.ChunkData AS T -- exclude the ones in the target
            WHERE
                T.ChunkName = S.ChunkName AND
                T.ChunkType = S.ChunkType AND
                T.SnapshotDataID = @ToSnapshotID)

END ELSE IF @FromIsPermanent != 0 AND @ToIsPermanent != 0 BEGIN

    INSERT INTO ChunkData
        (ChunkID, SnapshotDataID, ChunkName, ChunkType, MimeType, Version, ChunkFlags, Content)
    SELECT
        newid(), @ToSnapshotID, S.ChunkName, S.ChunkType, S.MimeType, S.Version, S.ChunkFlags, S.Content
    FROM
        ChunkData AS S
    WHERE   
        S.SnapshotDataID = @FromSnapshotID AND
        S.ChunkType = @ChunkType AND
        NOT EXISTS(
            SELECT T.ChunkName
            FROM ChunkData AS T -- exclude the ones in the target
            WHERE
                T.ChunkName = S.ChunkName AND
                T.ChunkType = S.ChunkType AND
                T.SnapshotDataID = @ToSnapshotID)

END ELSE BEGIN
   RAISERROR('Unsupported chunk copy', 16, 1)
END
         
GO
GRANT EXECUTE ON [dbo].[CopyChunksOfType] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DeleteSnapshotAndChunks]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[DeleteSnapshotAndChunks]
GO

CREATE PROCEDURE [dbo].[DeleteSnapshotAndChunks]
@SnapshotID uniqueidentifier,
@IsPermanentSnapshot bit
AS

IF @IsPermanentSnapshot != 0 BEGIN

    DELETE ChunkData
    WHERE ChunkData.SnapshotDataID = @SnapshotID
       
    DELETE SnapshotData
    WHERE SnapshotData.SnapshotDataID = @SnapshotID
   
END ELSE BEGIN

    DELETE [ReportServerTempDB].dbo.ChunkData
    WHERE SnapshotDataID = @SnapshotID
       
    DELETE [ReportServerTempDB].dbo.SnapshotData
    WHERE SnapshotDataID = @SnapshotID

END   
      
GO
GRANT EXECUTE ON [dbo].[DeleteSnapshotAndChunks] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DeleteOneChunk]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[DeleteOneChunk]
GO

CREATE PROCEDURE [dbo].[DeleteOneChunk]
@SnapshotID uniqueidentifier,
@IsPermanentSnapshot bit,
@ChunkName nvarchar(260),
@ChunkType int
AS

IF @IsPermanentSnapshot != 0 BEGIN

DELETE ChunkData
WHERE   
    SnapshotDataID = @SnapshotID AND
    ChunkName = @ChunkName AND
    ChunkType = @ChunkType
    
END ELSE BEGIN

DELETE [ReportServerTempDB].dbo.ChunkData
WHERE   
    SnapshotDataID = @SnapshotID AND
    ChunkName = @ChunkName AND
    ChunkType = @ChunkType

END    
    
GO
GRANT EXECUTE ON [dbo].[DeleteOneChunk] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CreateRdlChunk]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CreateRdlChunk]
GO

CREATE PROCEDURE [dbo].[CreateRdlChunk]
	@ItemId UNIQUEIDENTIFIER, 
	@SnapshotId UNIQUEIDENTIFIER, 
	@IsPermanentSnapshot BIT, 
	@ChunkName NVARCHAR(260), 
	@ChunkFlags TINYINT, 
	@ChunkType INT, 
	@Version SMALLINT, 
	@MimeType NVARCHAR(260) = NULL
AS
BEGIN
IF @IsPermanentSnapshot != 0 BEGIN
	INSERT INTO [ChunkData] ( 
		ChunkId, SnapshotDataId, ChunkFlags, ChunkName, 
		ChunkType, Version, MimeType, Content )
	SELECT 
		NEWID(), @SnapshotId, @ChunkFlags, @ChunkName, 
		@ChunkType, @Version, @MimeType, ISNULL(Linked.Content, Original.Content)
	FROM [Catalog] Original
	LEFT OUTER JOIN [Catalog] Linked WITH (INDEX(PK_Catalog)) ON (Original.LinkSourceId = Linked.ItemId)
	WHERE	Original.ItemId = @ItemId AND 
			NOT EXISTS (
			SELECT * 
			FROM [ChunkData] 
			WHERE	SnapshotDataId = @SnapshotId AND
					ChunkName = @ChunkName AND
					ChunkType = @ChunkType )
END	
ELSE BEGIN
	INSERT INTO [ReportServerTempdb].[dbo].[ChunkData] ( 
		ChunkId, SnapshotDataId, ChunkFlags, ChunkName, 
		ChunkType, Version, MimeType, Content )
	SELECT 
		NEWID(), @SnapshotId, @ChunkFlags, @ChunkName, 
		@ChunkType, @Version, @MimeType, ISNULL(Linked.Content, Original.Content)
	FROM [Catalog] Original
	LEFT OUTER JOIN [Catalog] Linked WITH (INDEX(PK_Catalog)) ON (Original.LinkSourceId = Linked.ItemId)
	WHERE	Original.ItemId = @ItemId AND 
			NOT EXISTS (
			SELECT * 
			FROM [ReportServerTempdb].[dbo].[ChunkData]
			WHERE	SnapshotDataId = @SnapshotId AND
					ChunkName = @ChunkName AND
					ChunkType = @ChunkType )
END
END

GRANT EXECUTE ON [dbo].[CreateRdlChunk] TO RSExecRole
GO


--------------------------------------------------
------------- Persisted stream SPs

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DeletePersistedStreams]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[DeletePersistedStreams]
GO

CREATE PROCEDURE [dbo].[DeletePersistedStreams]
@SessionID varchar(32)
AS

delete 
    [ReportServerTempDB].dbo.PersistedStream
from 
    (select top 1 * from [ReportServerTempDB].dbo.PersistedStream PS2 where PS2.SessionID = @SessionID) as e1
where 
    e1.SessionID = [ReportServerTempDB].dbo.PersistedStream.[SessionID] and
    e1.[Index] = [ReportServerTempDB].dbo.PersistedStream.[Index]
    
GO
GRANT EXECUTE ON [dbo].[DeletePersistedStreams] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DeleteExpiredPersistedStreams]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[DeleteExpiredPersistedStreams]
GO

CREATE PROCEDURE [dbo].[DeleteExpiredPersistedStreams]
AS

SET DEADLOCK_PRIORITY LOW
DELETE
    [ReportServerTempDB].dbo.PersistedStream
FROM 
    (SELECT TOP 1 * FROM [ReportServerTempDB].dbo.PersistedStream PS2 WHERE PS2.RefCount = 0 AND GETDATE() > PS2.ExpirationDate) AS e1
WHERE 
    e1.SessionID = [ReportServerTempDB].dbo.PersistedStream.[SessionID] AND
    e1.[Index] = [ReportServerTempDB].dbo.PersistedStream.[Index]
    
GO
GRANT EXECUTE ON [dbo].[DeleteExpiredPersistedStreams] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DeletePersistedStream]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[DeletePersistedStream]
GO

CREATE PROCEDURE [dbo].[DeletePersistedStream]
@SessionID varchar(32),
@Index int
AS

delete from [ReportServerTempDB].dbo.PersistedStream where SessionID = @SessionID and [Index] = @Index
    
GO
GRANT EXECUTE ON [dbo].[DeletePersistedStream] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[AddPersistedStream]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[AddPersistedStream]
GO

CREATE PROCEDURE [dbo].[AddPersistedStream]
@SessionID varchar(32),
@Index int
AS

DECLARE @RefCount int
DECLARE @id varchar(32)
DECLARE @ExpirationDate datetime

set @RefCount = 0
set @ExpirationDate = DATEADD(day, 2, GETDATE())

set @id = (select SessionID from [ReportServerTempDB].dbo.SessionData where SessionID = @SessionID)

if @id is not null
begin
set @RefCount = 1
end

INSERT INTO [ReportServerTempDB].dbo.PersistedStream (SessionID, [Index], [RefCount], [ExpirationDate]) VALUES (@SessionID, @Index, @RefCount, @ExpirationDate)
    
GO
GRANT EXECUTE ON [dbo].[AddPersistedStream] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[LockPersistedStream]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[LockPersistedStream]
GO

CREATE PROCEDURE [dbo].[LockPersistedStream]
@SessionID varchar(32),
@Index int
AS

SELECT [Index] FROM [ReportServerTempDB].dbo.PersistedStream WITH (XLOCK) WHERE SessionID = @SessionID AND [Index] = @Index
    
GO
GRANT EXECUTE ON [dbo].[LockPersistedStream] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[WriteFirstPortionPersistedStream]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[WriteFirstPortionPersistedStream]
GO

CREATE PROCEDURE [dbo].[WriteFirstPortionPersistedStream]
@SessionID varchar(32),
@Index int,
@Name nvarchar(260) = NULL,
@MimeType nvarchar(260) = NULL,
@Extension nvarchar(260) = NULL,
@Encoding nvarchar(260) = NULL,
@Content image
AS

UPDATE [ReportServerTempDB].dbo.PersistedStream set Content = @Content, [Name] = @Name, MimeType = @MimeType, Extension = @Extension WHERE SessionID = @SessionID AND [Index] = @Index

SELECT TEXTPTR(Content) FROM [ReportServerTempDB].dbo.PersistedStream WHERE SessionID = @SessionID AND [Index] = @Index

GO
GRANT EXECUTE ON [dbo].[WriteFirstPortionPersistedStream] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[WriteNextPortionPersistedStream]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[WriteNextPortionPersistedStream]
GO

CREATE PROCEDURE [dbo].[WriteNextPortionPersistedStream]
@DataPointer binary(16),
@DataIndex int,
@DeleteLength int,
@Content image
AS

UPDATETEXT [ReportServerTempDB].dbo.PersistedStream.Content @DataPointer @DataIndex @DeleteLength @Content

GO
GRANT EXECUTE ON [dbo].[WriteNextPortionPersistedStream] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetFirstPortionPersistedStream]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetFirstPortionPersistedStream]
GO

CREATE PROCEDURE [dbo].[GetFirstPortionPersistedStream]
@SessionID varchar(32)
AS

SELECT 
    TOP 1
    TEXTPTR(P.Content), 
    DATALENGTH(P.Content), 
    P.[Index],
    P.[Name], 
    P.MimeType, 
    P.Extension, 
    P.Encoding,
    P.Error
FROM 
    [ReportServerTempDB].dbo.PersistedStream P WITH (XLOCK)
WHERE 
    P.SessionID = @SessionID
GO
GRANT EXECUTE ON [dbo].[GetFirstPortionPersistedStream] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SetPersistedStreamError]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SetPersistedStreamError]
GO

CREATE PROCEDURE [dbo].[SetPersistedStreamError]
@SessionID varchar(32),
@Index int,
@AllRows bit,
@Error nvarchar(512)
AS

if @AllRows = 0
BEGIN
    UPDATE [ReportServerTempDB].dbo.PersistedStream SET Error = @Error WHERE SessionID = @SessionID and [Index] = @Index
END
ELSE
BEGIN
    UPDATE [ReportServerTempDB].dbo.PersistedStream SET Error = @Error WHERE SessionID = @SessionID
END

GO
GRANT EXECUTE ON [dbo].[SetPersistedStreamError] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetNextPortionPersistedStream]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetNextPortionPersistedStream]
GO

CREATE PROCEDURE [dbo].[GetNextPortionPersistedStream]
@DataPointer binary(16),
@DataIndex int,
@Length int
AS

READTEXT [ReportServerTempDB].dbo.PersistedStream.Content @DataPointer @DataIndex @Length

GO
GRANT EXECUTE ON [dbo].[GetNextPortionPersistedStream] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetSnapshotChunks]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetSnapshotChunks]
GO

CREATE PROCEDURE [dbo].[GetSnapshotChunks]
@SnapshotDataID uniqueidentifier,
@IsPermanentSnapshot bit
AS

IF @IsPermanentSnapshot != 0 BEGIN

SELECT ChunkName, ChunkType, ChunkFlags, MimeType, Version, datalength(Content)
FROM ChunkData
WHERE   
    SnapshotDataID = @SnapshotDataID
    
END ELSE BEGIN

SELECT ChunkName, ChunkType, ChunkFlags, MimeType, Version, datalength(Content)
FROM [ReportServerTempDB].dbo.ChunkData
WHERE   
    SnapshotDataID = @SnapshotDataID
END    
    
GO
GRANT EXECUTE ON [dbo].[GetSnapshotChunks] TO RSExecRole
GO


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SetDrillthroughReports]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SetDrillthroughReports]
GO

CREATE PROCEDURE [dbo].[SetDrillthroughReports]
@ReportID uniqueidentifier,
@ModelID uniqueidentifier,
@ModelItemID nvarchar(425),
@Type tinyint
AS
 INSERT INTO ModelDrill (ModelDrillID, ModelID, ReportID, ModelItemID, [Type])
 VALUES (newid(), @ModelID, @ReportID, @ModelItemID, @Type)
GO

GRANT EXECUTE ON [dbo].[SetDrillthroughReports] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DeleteDrillthroughReports]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[DeleteDrillthroughReports]
GO

CREATE PROCEDURE [dbo].[DeleteDrillthroughReports]
@ModelID uniqueidentifier,
@ModelItemID nvarchar(425)
AS
 DELETE ModelDrill WHERE ModelID = @ModelID and ModelItemID = @ModelItemID
GO

GRANT EXECUTE ON [dbo].[DeleteDrillthroughReports] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetDrillthroughReports]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetDrillthroughReports]
GO

CREATE PROCEDURE [dbo].[GetDrillthroughReports]
@ModelID uniqueidentifier,
@ModelItemID nvarchar(425)
AS
 SELECT 
 ModelDrill.Type, 
 Catalog.Path
 FROM ModelDrill INNER JOIN Catalog ON ModelDrill.ReportID = Catalog.ItemID
 WHERE ModelID = @ModelID
 AND ModelItemID = @ModelItemID 
GO

GRANT EXECUTE ON [dbo].[GetDrillthroughReports] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetDrillthroughReport]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetDrillthroughReport]
GO

CREATE PROCEDURE [dbo].[GetDrillthroughReport]
@ModelPath nvarchar(425),
@ModelItemID nvarchar(425),
@Type tinyint
AS
 SELECT 
 CatRep.Path
 FROM ModelDrill 
 INNER JOIN Catalog CatMod ON ModelDrill.ModelID = CatMod.ItemID
 INNER JOIN Catalog CatRep ON ModelDrill.ReportID = CatRep.ItemID
 WHERE CatMod.Path = @ModelPath
 AND ModelItemID = @ModelItemID 
 AND ModelDrill.[Type] = @Type
GO

GRANT EXECUTE ON [dbo].[GetDrillthroughReport] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetUpgradeItems]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetUpgradeItems]
GO

CREATE PROCEDURE [dbo].[GetUpgradeItems]
AS
SELECT 
    [Item],
    [Status]
FROM 
    [UpgradeInfo]
GO

GRANT EXECUTE ON [dbo].[GetUpgradeItems] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SetUpgradeItemStatus]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SetUpgradeItemStatus]
GO

CREATE PROCEDURE [dbo].[SetUpgradeItemStatus]
@ItemName nvarchar(260),
@Status nvarchar(512)
AS
UPDATE 
    [UpgradeInfo]
SET
    [Status] = @Status
WHERE
    [Item] = @ItemName
GO

GRANT EXECUTE ON [dbo].[SetUpgradeItemStatus] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetPolicyRoots]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetPolicyRoots]
GO

CREATE PROCEDURE [dbo].[GetPolicyRoots]
AS
SELECT 
    [Path],
    [Type]
FROM 
    [Catalog] 
WHERE 
    [PolicyRoot] = 1
GO

GRANT EXECUTE ON [dbo].[GetPolicyRoots] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetDataSourceForUpgrade]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetDataSourceForUpgrade]
GO

CREATE PROCEDURE [dbo].[GetDataSourceForUpgrade]
@CurrentVersion int
AS
SELECT 
    [DSID]
FROM 
    [DataSource]
WHERE
    [Version] != @CurrentVersion
GO

GRANT EXECUTE ON [dbo].[GetDataSourceForUpgrade] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetSubscriptionsForUpgrade]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetSubscriptionsForUpgrade]
GO

CREATE PROCEDURE [dbo].[GetSubscriptionsForUpgrade]
@CurrentVersion int
AS
SELECT 
    [SubscriptionID]
FROM 
    [Subscriptions]
WHERE
    [Version] != @CurrentVersion
GO

GRANT EXECUTE ON [dbo].[GetSubscriptionsForUpgrade] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[StoreServerParameters]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[StoreServerParameters]
GO

CREATE PROCEDURE [dbo].[StoreServerParameters]
@ServerParametersID nvarchar(32),
@Path nvarchar(425),
@CurrentDate datetime,
@Timeout int,
@Expiration datetime,
@ParametersValues image,
@ParentParametersID nvarchar(32) = NULL
AS

DECLARE @ExistingServerParametersID as nvarchar(32)
SET @ExistingServerParametersID = (SELECT ServerParametersID from [dbo].[ServerParametersInstance] WHERE ServerParametersID = @ServerParametersID)
IF @ExistingServerParametersID IS NULL -- new row
BEGIN
  INSERT INTO [dbo].[ServerParametersInstance]
    (ServerParametersID, ParentID, Path, CreateDate, ModifiedDate, Timeout, Expiration, ParametersValues)
  VALUES
    (@ServerParametersID, @ParentParametersID, @Path, @CurrentDate, @CurrentDate, @Timeout, @Expiration, @ParametersValues)
END
ELSE
BEGIN
  UPDATE [dbo].[ServerParametersInstance]
  SET Timeout = @Timeout,
  Expiration = @Expiration,
  ParametersValues = @ParametersValues,
  ModifiedDate = @CurrentDate,
  Path = @Path,
  ParentID = @ParentParametersID
  WHERE ServerParametersID = @ServerParametersID
END
GO

GRANT EXECUTE ON [dbo].[StoreServerParameters] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetServerParameters]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetServerParameters]
GO

CREATE PROCEDURE [dbo].[GetServerParameters]
@ServerParametersID nvarchar(32)
AS
DECLARE @now as DATETIME
SET @now = GETDATE()
SELECT Child.Path, Child.ParametersValues, Parent.ParametersValues
FROM [dbo].[ServerParametersInstance] Child
LEFT OUTER JOIN [dbo].[ServerParametersInstance] Parent
ON Child.ParentID = Parent.ServerParametersID
WHERE Child.ServerParametersID = @ServerParametersID 
AND Child.Expiration > @now
GO


GRANT EXECUTE ON [dbo].[GetServerParameters] TO RSExecRole
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CleanExpiredServerParameters]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[CleanExpiredServerParameters]
GO

CREATE PROCEDURE [dbo].[CleanExpiredServerParameters]
@ParametersCleaned INT OUTPUT
AS
  DECLARE @now as DATETIME
  SET @now = GETDATE()

DELETE FROM [dbo].[ServerParametersInstance] 
WHERE ServerParametersID IN 
(  SELECT TOP 20 ServerParametersID FROM [dbo].[ServerParametersInstance]
  WHERE Expiration < @now
)

SET @ParametersCleaned = @@ROWCOUNT
 
GO

GRANT EXECUTE ON [dbo].[CleanExpiredServerParameters] TO RSExecRole
GO



-- END STORED PROCEDURES

USE [ReportServerTempDB]

-- standard script to set the database version, can  be used both the catalog database and the tempdb database
-- the idea is to first drop the existing stored procedure and then create a new on with the correct database version
-- and give the RSExecRole permissions to execute it. The correct database version replaces the T.0.8.54 place holder
-- during the build script finalization in the DatabaseMgr.cpp code.

------------- DBVersion -------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetDBVersion]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetDBVersion]
GO

CREATE PROCEDURE [dbo].[GetDBVersion]
@DBVersion nvarchar(32) OUTPUT
AS
set @DBVersion = 'T.0.8.54'
GO
GRANT EXECUTE ON [dbo].[GetDBVersion] TO RSExecRole
GO



USE [ReportServer]

-- standard script to set the database version, can  be used both the catalog database and the tempdb database
-- the idea is to first drop the existing stored procedure and then create a new on with the correct database version
-- and give the RSExecRole permissions to execute it. The correct database version replaces the C.0.8.54 place holder
-- during the build script finalization in the DatabaseMgr.cpp code.

------------- DBVersion -------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetDBVersion]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetDBVersion]
GO

CREATE PROCEDURE [dbo].[GetDBVersion]
@DBVersion nvarchar(32) OUTPUT
AS
set @DBVersion = 'C.0.8.54'
GO
GRANT EXECUTE ON [dbo].[GetDBVersion] TO RSExecRole
GO




GO