/*
    工业监控平台初始化数据库脚本 v1
    目标数据库：SQL Server 2022
    说明：
    1. 脚本按第一阶段最小可落地表集编写；
    2. 使用 IF OBJECT_ID / IF NOT EXISTS 方式避免重复创建；
    3. 时间统一使用 UTC；
    4. 默认 schema 使用 dbo。
*/

SET NOCOUNT ON;
GO

/* =========================================================
   1. 基础配置表
   ========================================================= */

IF OBJECT_ID(N'dbo.PlatformSites', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.PlatformSites
    (
        Id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_PlatformSites PRIMARY KEY,
        SiteCode NVARCHAR(64) NOT NULL,
        SiteName NVARCHAR(128) NOT NULL,
        TimeZoneId NVARCHAR(64) NOT NULL CONSTRAINT DF_PlatformSites_TimeZoneId DEFAULT N'Asia/Shanghai',
        IsEnabled BIT NOT NULL CONSTRAINT DF_PlatformSites_IsEnabled DEFAULT (1),
        CreatedAt DATETIME2(3) NOT NULL CONSTRAINT DF_PlatformSites_CreatedAt DEFAULT SYSUTCDATETIME(),
        UpdatedAt DATETIME2(3) NOT NULL CONSTRAINT DF_PlatformSites_UpdatedAt DEFAULT SYSUTCDATETIME()
    );
END
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = N'UX_PlatformSites_SiteCode'
      AND object_id = OBJECT_ID(N'dbo.PlatformSites')
)
BEGIN
    CREATE UNIQUE INDEX UX_PlatformSites_SiteCode
        ON dbo.PlatformSites(SiteCode);
END
GO

IF OBJECT_ID(N'dbo.Devices', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Devices
    (
        Id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Devices PRIMARY KEY,
        SiteId BIGINT NOT NULL,
        DeviceCode NVARCHAR(64) NOT NULL,
        DeviceName NVARCHAR(128) NOT NULL,
        DeviceType NVARCHAR(64) NOT NULL,
        SourceType NVARCHAR(32) NOT NULL,
        SourceEndpoint NVARCHAR(256) NULL,
        IsEnabled BIT NOT NULL CONSTRAINT DF_Devices_IsEnabled DEFAULT (1),
        CreatedAt DATETIME2(3) NOT NULL CONSTRAINT DF_Devices_CreatedAt DEFAULT SYSUTCDATETIME(),
        UpdatedAt DATETIME2(3) NOT NULL CONSTRAINT DF_Devices_UpdatedAt DEFAULT SYSUTCDATETIME(),
        CONSTRAINT FK_Devices_PlatformSites
            FOREIGN KEY (SiteId) REFERENCES dbo.PlatformSites(Id)
    );
END
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = N'UX_Devices_SiteId_DeviceCode'
      AND object_id = OBJECT_ID(N'dbo.Devices')
)
BEGIN
    CREATE UNIQUE INDEX UX_Devices_SiteId_DeviceCode
        ON dbo.Devices(SiteId, DeviceCode);
END
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_Devices_SiteId_IsEnabled'
      AND object_id = OBJECT_ID(N'dbo.Devices')
)
BEGIN
    CREATE INDEX IX_Devices_SiteId_IsEnabled
        ON dbo.Devices(SiteId, IsEnabled);
END
GO

IF OBJECT_ID(N'dbo.TagDefinitions', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.TagDefinitions
    (
        Id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_TagDefinitions PRIMARY KEY,
        DeviceId BIGINT NOT NULL,
        TagCode NVARCHAR(128) NOT NULL,
        TagName NVARCHAR(128) NOT NULL,
        SourceNode NVARCHAR(256) NOT NULL,
        DataType NVARCHAR(32) NOT NULL,
        Unit NVARCHAR(32) NULL,
        PrecisionScale INT NOT NULL CONSTRAINT DF_TagDefinitions_PrecisionScale DEFAULT (2),
        ArchiveEnabled BIT NOT NULL CONSTRAINT DF_TagDefinitions_ArchiveEnabled DEFAULT (0),
        SnapshotIntervalSeconds INT NOT NULL CONSTRAINT DF_TagDefinitions_SnapshotIntervalSeconds DEFAULT (5),
        Deadband DECIMAL(18,6) NULL,
        IsWritable BIT NOT NULL CONSTRAINT DF_TagDefinitions_IsWritable DEFAULT (0),
        IsAlarmSource BIT NOT NULL CONSTRAINT DF_TagDefinitions_IsAlarmSource DEFAULT (0),
        DisplayOrder INT NOT NULL CONSTRAINT DF_TagDefinitions_DisplayOrder DEFAULT (0),
        IsEnabled BIT NOT NULL CONSTRAINT DF_TagDefinitions_IsEnabled DEFAULT (1),
        CreatedAt DATETIME2(3) NOT NULL CONSTRAINT DF_TagDefinitions_CreatedAt DEFAULT SYSUTCDATETIME(),
        UpdatedAt DATETIME2(3) NOT NULL CONSTRAINT DF_TagDefinitions_UpdatedAt DEFAULT SYSUTCDATETIME(),
        CONSTRAINT FK_TagDefinitions_Devices
            FOREIGN KEY (DeviceId) REFERENCES dbo.Devices(Id)
    );
END
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = N'UX_TagDefinitions_DeviceId_TagCode'
      AND object_id = OBJECT_ID(N'dbo.TagDefinitions')
)
BEGIN
    CREATE UNIQUE INDEX UX_TagDefinitions_DeviceId_TagCode
        ON dbo.TagDefinitions(DeviceId, TagCode);
END
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_TagDefinitions_DeviceId_IsEnabled'
      AND object_id = OBJECT_ID(N'dbo.TagDefinitions')
)
BEGIN
    CREATE INDEX IX_TagDefinitions_DeviceId_IsEnabled
        ON dbo.TagDefinitions(DeviceId, IsEnabled);
END
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_TagDefinitions_IsAlarmSource_IsEnabled'
      AND object_id = OBJECT_ID(N'dbo.TagDefinitions')
)
BEGIN
    CREATE INDEX IX_TagDefinitions_IsAlarmSource_IsEnabled
        ON dbo.TagDefinitions(IsAlarmSource, IsEnabled);
END
GO

/* =========================================================
   2. 实时与历史数据表
   ========================================================= */

IF OBJECT_ID(N'dbo.TagSnapshots', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.TagSnapshots
    (
        TagId BIGINT NOT NULL CONSTRAINT PK_TagSnapshots PRIMARY KEY,
        ValueText NVARCHAR(256) NULL,
        ValueNumber DECIMAL(24,8) NULL,
        ValueBool BIT NULL,
        QualityCode NVARCHAR(32) NOT NULL,
        SourceTimestamp DATETIME2(3) NOT NULL,
        ReceivedAt DATETIME2(3) NOT NULL,
        UpdatedAt DATETIME2(3) NOT NULL CONSTRAINT DF_TagSnapshots_UpdatedAt DEFAULT SYSUTCDATETIME(),
        CONSTRAINT FK_TagSnapshots_TagDefinitions
            FOREIGN KEY (TagId) REFERENCES dbo.TagDefinitions(Id)
    );
END
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_TagSnapshots_UpdatedAt'
      AND object_id = OBJECT_ID(N'dbo.TagSnapshots')
)
BEGIN
    CREATE INDEX IX_TagSnapshots_UpdatedAt
        ON dbo.TagSnapshots(UpdatedAt);
END
GO

IF OBJECT_ID(N'dbo.TagHistory', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.TagHistory
    (
        Id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_TagHistory PRIMARY KEY,
        TagId BIGINT NOT NULL,
        ValueText NVARCHAR(256) NULL,
        ValueNumber DECIMAL(24,8) NULL,
        ValueBool BIT NULL,
        QualityCode NVARCHAR(32) NOT NULL,
        SourceTimestamp DATETIME2(3) NOT NULL,
        ReceivedAt DATETIME2(3) NOT NULL CONSTRAINT DF_TagHistory_ReceivedAt DEFAULT SYSUTCDATETIME(),
        CONSTRAINT FK_TagHistory_TagDefinitions
            FOREIGN KEY (TagId) REFERENCES dbo.TagDefinitions(Id)
    );
END
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_TagHistory_TagId_SourceTimestamp'
      AND object_id = OBJECT_ID(N'dbo.TagHistory')
)
BEGIN
    CREATE INDEX IX_TagHistory_TagId_SourceTimestamp
        ON dbo.TagHistory(TagId, SourceTimestamp);
END
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_TagHistory_SourceTimestamp'
      AND object_id = OBJECT_ID(N'dbo.TagHistory')
)
BEGIN
    CREATE INDEX IX_TagHistory_SourceTimestamp
        ON dbo.TagHistory(SourceTimestamp);
END
GO

IF OBJECT_ID(N'dbo.DeviceStatusSnapshots', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.DeviceStatusSnapshots
    (
        DeviceId BIGINT NOT NULL CONSTRAINT PK_DeviceStatusSnapshots PRIMARY KEY,
        RunStatus NVARCHAR(32) NULL,
        FaultStatus NVARCHAR(32) NULL,
        AlarmLevel NVARCHAR(32) NULL,
        IsOnline BIT NOT NULL CONSTRAINT DF_DeviceStatusSnapshots_IsOnline DEFAULT (0),
        LastSeenAt DATETIME2(3) NULL,
        UpdatedAt DATETIME2(3) NOT NULL CONSTRAINT DF_DeviceStatusSnapshots_UpdatedAt DEFAULT SYSUTCDATETIME(),
        CONSTRAINT FK_DeviceStatusSnapshots_Devices
            FOREIGN KEY (DeviceId) REFERENCES dbo.Devices(Id)
    );
END
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_DeviceStatusSnapshots_IsOnline_UpdatedAt'
      AND object_id = OBJECT_ID(N'dbo.DeviceStatusSnapshots')
)
BEGIN
    CREATE INDEX IX_DeviceStatusSnapshots_IsOnline_UpdatedAt
        ON dbo.DeviceStatusSnapshots(IsOnline, UpdatedAt);
END
GO

/* =========================================================
   3. 报警表
   ========================================================= */

IF OBJECT_ID(N'dbo.AlarmDefinitions', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.AlarmDefinitions
    (
        Id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_AlarmDefinitions PRIMARY KEY,
        SiteId BIGINT NOT NULL,
        AlarmCode NVARCHAR(128) NOT NULL,
        AlarmName NVARCHAR(128) NOT NULL,
        DeviceId BIGINT NULL,
        TagId BIGINT NULL,
        Severity NVARCHAR(32) NOT NULL,
        TriggerType NVARCHAR(32) NOT NULL,
        TriggerExpression NVARCHAR(256) NOT NULL,
        RecoveryExpression NVARCHAR(256) NULL,
        NotifyEnabled BIT NOT NULL CONSTRAINT DF_AlarmDefinitions_NotifyEnabled DEFAULT (0),
        IsEnabled BIT NOT NULL CONSTRAINT DF_AlarmDefinitions_IsEnabled DEFAULT (1),
        CreatedAt DATETIME2(3) NOT NULL CONSTRAINT DF_AlarmDefinitions_CreatedAt DEFAULT SYSUTCDATETIME(),
        UpdatedAt DATETIME2(3) NOT NULL CONSTRAINT DF_AlarmDefinitions_UpdatedAt DEFAULT SYSUTCDATETIME(),
        CONSTRAINT FK_AlarmDefinitions_PlatformSites
            FOREIGN KEY (SiteId) REFERENCES dbo.PlatformSites(Id),
        CONSTRAINT FK_AlarmDefinitions_Devices
            FOREIGN KEY (DeviceId) REFERENCES dbo.Devices(Id),
        CONSTRAINT FK_AlarmDefinitions_TagDefinitions
            FOREIGN KEY (TagId) REFERENCES dbo.TagDefinitions(Id)
    );
END
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = N'UX_AlarmDefinitions_SiteId_AlarmCode'
      AND object_id = OBJECT_ID(N'dbo.AlarmDefinitions')
)
BEGIN
    CREATE UNIQUE INDEX UX_AlarmDefinitions_SiteId_AlarmCode
        ON dbo.AlarmDefinitions(SiteId, AlarmCode);
END
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_AlarmDefinitions_DeviceId_IsEnabled'
      AND object_id = OBJECT_ID(N'dbo.AlarmDefinitions')
)
BEGIN
    CREATE INDEX IX_AlarmDefinitions_DeviceId_IsEnabled
        ON dbo.AlarmDefinitions(DeviceId, IsEnabled);
END
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_AlarmDefinitions_TagId_IsEnabled'
      AND object_id = OBJECT_ID(N'dbo.AlarmDefinitions')
)
BEGIN
    CREATE INDEX IX_AlarmDefinitions_TagId_IsEnabled
        ON dbo.AlarmDefinitions(TagId, IsEnabled);
END
GO

IF OBJECT_ID(N'dbo.AlarmEvents', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.AlarmEvents
    (
        Id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_AlarmEvents PRIMARY KEY,
        AlarmDefinitionId BIGINT NOT NULL,
        SiteId BIGINT NOT NULL,
        DeviceId BIGINT NULL,
        TagId BIGINT NULL,
        AlarmCode NVARCHAR(128) NOT NULL,
        AlarmName NVARCHAR(128) NOT NULL,
        Severity NVARCHAR(32) NOT NULL,
        Status NVARCHAR(32) NOT NULL,
        Message NVARCHAR(512) NOT NULL,
        TriggerValue NVARCHAR(256) NULL,
        TriggeredAt DATETIME2(3) NOT NULL,
        RecoveredAt DATETIME2(3) NULL,
        AcknowledgedAt DATETIME2(3) NULL,
        AcknowledgedBy NVARCHAR(64) NULL,
        SourceType NVARCHAR(32) NOT NULL,
        CreatedAt DATETIME2(3) NOT NULL CONSTRAINT DF_AlarmEvents_CreatedAt DEFAULT SYSUTCDATETIME(),
        CONSTRAINT FK_AlarmEvents_AlarmDefinitions
            FOREIGN KEY (AlarmDefinitionId) REFERENCES dbo.AlarmDefinitions(Id),
        CONSTRAINT FK_AlarmEvents_PlatformSites
            FOREIGN KEY (SiteId) REFERENCES dbo.PlatformSites(Id),
        CONSTRAINT FK_AlarmEvents_Devices
            FOREIGN KEY (DeviceId) REFERENCES dbo.Devices(Id),
        CONSTRAINT FK_AlarmEvents_TagDefinitions
            FOREIGN KEY (TagId) REFERENCES dbo.TagDefinitions(Id)
    );
END
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_AlarmEvents_SiteId_TriggeredAt'
      AND object_id = OBJECT_ID(N'dbo.AlarmEvents')
)
BEGIN
    CREATE INDEX IX_AlarmEvents_SiteId_TriggeredAt
        ON dbo.AlarmEvents(SiteId, TriggeredAt);
END
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_AlarmEvents_Status_Severity'
      AND object_id = OBJECT_ID(N'dbo.AlarmEvents')
)
BEGIN
    CREATE INDEX IX_AlarmEvents_Status_Severity
        ON dbo.AlarmEvents(Status, Severity);
END
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_AlarmEvents_DeviceId_TriggeredAt'
      AND object_id = OBJECT_ID(N'dbo.AlarmEvents')
)
BEGIN
    CREATE INDEX IX_AlarmEvents_DeviceId_TriggeredAt
        ON dbo.AlarmEvents(DeviceId, TriggeredAt);
END
GO

/* =========================================================
   4. 用户权限与审计表
   ========================================================= */

IF OBJECT_ID(N'dbo.Users', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Users
    (
        Id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Users PRIMARY KEY,
        UserName NVARCHAR(64) NOT NULL,
        DisplayName NVARCHAR(64) NOT NULL,
        PasswordHash NVARCHAR(256) NOT NULL,
        Mobile NVARCHAR(32) NULL,
        Email NVARCHAR(128) NULL,
        IsEnabled BIT NOT NULL CONSTRAINT DF_Users_IsEnabled DEFAULT (1),
        LastLoginAt DATETIME2(3) NULL,
        CreatedAt DATETIME2(3) NOT NULL CONSTRAINT DF_Users_CreatedAt DEFAULT SYSUTCDATETIME(),
        UpdatedAt DATETIME2(3) NOT NULL CONSTRAINT DF_Users_UpdatedAt DEFAULT SYSUTCDATETIME()
    );
END
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = N'UX_Users_UserName'
      AND object_id = OBJECT_ID(N'dbo.Users')
)
BEGIN
    CREATE UNIQUE INDEX UX_Users_UserName
        ON dbo.Users(UserName);
END
GO

IF OBJECT_ID(N'dbo.Roles', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Roles
    (
        Id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Roles PRIMARY KEY,
        RoleCode NVARCHAR(64) NOT NULL,
        RoleName NVARCHAR(64) NOT NULL,
        IsEnabled BIT NOT NULL CONSTRAINT DF_Roles_IsEnabled DEFAULT (1),
        CreatedAt DATETIME2(3) NOT NULL CONSTRAINT DF_Roles_CreatedAt DEFAULT SYSUTCDATETIME(),
        UpdatedAt DATETIME2(3) NOT NULL CONSTRAINT DF_Roles_UpdatedAt DEFAULT SYSUTCDATETIME()
    );
END
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = N'UX_Roles_RoleCode'
      AND object_id = OBJECT_ID(N'dbo.Roles')
)
BEGIN
    CREATE UNIQUE INDEX UX_Roles_RoleCode
        ON dbo.Roles(RoleCode);
END
GO

IF OBJECT_ID(N'dbo.UserRoles', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.UserRoles
    (
        Id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_UserRoles PRIMARY KEY,
        UserId BIGINT NOT NULL,
        RoleId BIGINT NOT NULL,
        CreatedAt DATETIME2(3) NOT NULL CONSTRAINT DF_UserRoles_CreatedAt DEFAULT SYSUTCDATETIME(),
        CONSTRAINT FK_UserRoles_Users
            FOREIGN KEY (UserId) REFERENCES dbo.Users(Id),
        CONSTRAINT FK_UserRoles_Roles
            FOREIGN KEY (RoleId) REFERENCES dbo.Roles(Id)
    );
END
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = N'UX_UserRoles_UserId_RoleId'
      AND object_id = OBJECT_ID(N'dbo.UserRoles')
)
BEGIN
    CREATE UNIQUE INDEX UX_UserRoles_UserId_RoleId
        ON dbo.UserRoles(UserId, RoleId);
END
GO

IF OBJECT_ID(N'dbo.AuditLogs', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.AuditLogs
    (
        Id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_AuditLogs PRIMARY KEY,
        UserId BIGINT NULL,
        UserName NVARCHAR(64) NOT NULL,
        ActionType NVARCHAR(64) NOT NULL,
        TargetType NVARCHAR(64) NOT NULL,
        TargetId NVARCHAR(64) NULL,
        Detail NVARCHAR(MAX) NULL,
        ClientIp NVARCHAR(64) NULL,
        CreatedAt DATETIME2(3) NOT NULL CONSTRAINT DF_AuditLogs_CreatedAt DEFAULT SYSUTCDATETIME(),
        CONSTRAINT FK_AuditLogs_Users
            FOREIGN KEY (UserId) REFERENCES dbo.Users(Id)
    );
END
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_AuditLogs_UserId_CreatedAt'
      AND object_id = OBJECT_ID(N'dbo.AuditLogs')
)
BEGIN
    CREATE INDEX IX_AuditLogs_UserId_CreatedAt
        ON dbo.AuditLogs(UserId, CreatedAt);
END
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_AuditLogs_ActionType_CreatedAt'
      AND object_id = OBJECT_ID(N'dbo.AuditLogs')
)
BEGIN
    CREATE INDEX IX_AuditLogs_ActionType_CreatedAt
        ON dbo.AuditLogs(ActionType, CreatedAt);
END
GO

/* =========================================================
   5. 同步控制表
   ========================================================= */

IF OBJECT_ID(N'dbo.SyncCheckpoints', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.SyncCheckpoints
    (
        Id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_SyncCheckpoints PRIMARY KEY,
        SyncKey NVARCHAR(128) NOT NULL,
        LastSourceTimestamp DATETIME2(3) NULL,
        LastSequence BIGINT NULL,
        LastStatus NVARCHAR(32) NOT NULL,
        LastError NVARCHAR(512) NULL,
        UpdatedAt DATETIME2(3) NOT NULL CONSTRAINT DF_SyncCheckpoints_UpdatedAt DEFAULT SYSUTCDATETIME()
    );
END
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = N'UX_SyncCheckpoints_SyncKey'
      AND object_id = OBJECT_ID(N'dbo.SyncCheckpoints')
)
BEGIN
    CREATE UNIQUE INDEX UX_SyncCheckpoints_SyncKey
        ON dbo.SyncCheckpoints(SyncKey);
END
GO

/* =========================================================
   6. 初始化种子数据
   ========================================================= */

IF NOT EXISTS (SELECT 1 FROM dbo.PlatformSites WHERE SiteCode = N'default-site')
BEGIN
    INSERT INTO dbo.PlatformSites (SiteCode, SiteName, TimeZoneId, IsEnabled)
    VALUES (N'default-site', N'默认站点', N'Asia/Shanghai', 1);
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Roles WHERE RoleCode = N'admin')
BEGIN
    INSERT INTO dbo.Roles (RoleCode, RoleName, IsEnabled)
    VALUES (N'admin', N'系统管理员', 1);
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Roles WHERE RoleCode = N'manager')
BEGIN
    INSERT INTO dbo.Roles (RoleCode, RoleName, IsEnabled)
    VALUES (N'manager', N'管理查看用户', 1);
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Roles WHERE RoleCode = N'operator')
BEGIN
    INSERT INTO dbo.Roles (RoleCode, RoleName, IsEnabled)
    VALUES (N'operator', N'运行操作用户', 1);
END
GO
