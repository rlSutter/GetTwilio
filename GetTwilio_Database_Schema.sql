-- ============================================
-- GetTwilio Webhook Database Schema
-- SQL Server DDL Script
-- ============================================
-- This script creates the database schema required for the GetTwilio webhook service
-- which processes email delivery status notifications from Twilio/SendGrid

-- ============================================
-- Database Creation (if needed)
-- ============================================
-- Uncomment the following lines if you need to create the database
-- CREATE DATABASE [yourdb];

-- ============================================
-- Main Database Tables
-- ============================================

-- S_CONTACT table - Contact information
-- This table stores contact details including email addresses and suppression flags
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='S_CONTACT' AND xtype='U')
BEGIN
    CREATE TABLE [yourdb].[dbo].[S_CONTACT] (
        [ROW_ID] NVARCHAR(15) NOT NULL PRIMARY KEY,
        [EMAIL_ADDR] NVARCHAR(100) NULL,
        [SUPPRESS_EMAIL_FLG] NVARCHAR(1) NULL DEFAULT 'N',
        [PR_DEPT_OU_ID] NVARCHAR(15) NULL,
        [X_REGISTRATION_NUM] NVARCHAR(50) NULL,
        [X_TRAINER_NUM] NVARCHAR(50) NULL,
        [FST_NAME] NVARCHAR(50) NULL,
        [LST_NAME] NVARCHAR(50) NULL,
        [PHONE_NUM] NVARCHAR(20) NULL,
        [CREATED] DATETIME NULL,
        [CREATED_BY] NVARCHAR(15) NULL,
        [LAST_UPD] DATETIME NULL,
        [LAST_UPD_BY] NVARCHAR(15) NULL,
        [ROW_STATUS] NVARCHAR(1) NULL DEFAULT 'Y'
    );
    
    -- Create indexes for performance
    CREATE INDEX [IX_S_CONTACT_EMAIL] ON [yourdb].[dbo].[S_CONTACT] ([EMAIL_ADDR]);
    CREATE INDEX [IX_S_CONTACT_SUPPRESS] ON [yourdb].[dbo].[S_CONTACT] ([SUPPRESS_EMAIL_FLG]);
    CREATE INDEX [IX_S_CONTACT_REG_NUM] ON [yourdb].[dbo].[S_CONTACT] ([X_REGISTRATION_NUM]);
    CREATE INDEX [IX_S_CONTACT_TRAINER_NUM] ON [yourdb].[dbo].[S_CONTACT] ([X_TRAINER_NUM]);
    CREATE INDEX [IX_S_CONTACT_OU_ID] ON [yourdb].[dbo].[S_CONTACT] ([PR_DEPT_OU_ID]);
END;

-- S_EVT_ACT table - Activity/Event tracking
-- This table stores activity records for email delivery events
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='S_EVT_ACT' AND xtype='U')
BEGIN
    CREATE TABLE [yourdb].[dbo].[S_EVT_ACT] (
        [ROW_ID] NVARCHAR(15) NOT NULL PRIMARY KEY,
        [ACTIVITY_UID] NVARCHAR(15) NULL,
        [ALARM_FLAG] NVARCHAR(1) NULL DEFAULT 'N',
        [APPT_REPT_FLG] NVARCHAR(1) NULL DEFAULT 'N',
        [APPT_START_DT] DATETIME NULL,
        [ASGN_MANL_FLG] NVARCHAR(1) NULL DEFAULT 'Y',
        [ASGN_USR_EXCLD_FLG] NVARCHAR(1) NULL DEFAULT 'Y',
        [BEST_ACTION_FLG] NVARCHAR(1) NULL DEFAULT 'N',
        [BILLABLE_FLG] NVARCHAR(1) NULL DEFAULT 'N',
        [CAL_DISP_FLG] NVARCHAR(1) NULL DEFAULT 'N',
        [COMMENTS_LONG] NVARCHAR(1500) NULL,
        [CONFLICT_ID] INT NULL DEFAULT 0,
        [COST_CURCY_CD] NVARCHAR(3) NULL DEFAULT 'USD',
        [COST_EXCH_DT] DATETIME NULL,
        [CREATED] DATETIME NULL,
        [CREATED_BY] NVARCHAR(15) NULL,
        [CREATOR_LOGIN] NVARCHAR(50) NULL,
        [DCKING_NUM] INT NULL DEFAULT 0,
        [DURATION_HRS] DECIMAL(5,2) NULL DEFAULT 0.00,
        [EMAIL_ATT_FLG] NVARCHAR(1) NULL DEFAULT 'N',
        [EMAIL_FORWARD_FLG] NVARCHAR(1) NULL DEFAULT 'N',
        [EMAIL_RECIP_ADDR] NVARCHAR(100) NULL,
        [EVT_PRIORITY_CD] NVARCHAR(10) NULL,
        [EVT_STAT_CD] NVARCHAR(10) NULL,
        [LAST_UPD] DATETIME NULL,
        [LAST_UPD_BY] NVARCHAR(15) NULL,
        [MODIFICATION_NUM] INT NULL DEFAULT 0,
        [NAME] NVARCHAR(100) NULL,
        [OWNER_LOGIN] NVARCHAR(50) NULL,
        [OWNER_PER_ID] NVARCHAR(15) NULL,
        [PCT_COMPLETE] INT NULL DEFAULT 100,
        [PRIV_FLG] NVARCHAR(1) NULL DEFAULT 'N',
        [ROW_STATUS] NVARCHAR(1) NULL DEFAULT 'Y',
        [TARGET_OU_ID] NVARCHAR(15) NULL,
        [TARGET_PER_ID] NVARCHAR(15) NULL,
        [TEMPLATE_FLG] NVARCHAR(1) NULL DEFAULT 'N',
        [TMSHT_RLTD_FLG] NVARCHAR(1) NULL DEFAULT 'N',
        [TODO_CD] NVARCHAR(50) NULL,
        [TODO_ACTL_START_DT] DATETIME NULL,
        [TODO_ACTL_END_DT] DATETIME NULL
    );
    
    -- Create indexes for performance
    CREATE INDEX [IX_S_EVT_ACT_EMAIL] ON [yourdb].[dbo].[S_EVT_ACT] ([EMAIL_RECIP_ADDR]);
    CREATE INDEX [IX_S_EVT_ACT_TARGET] ON [yourdb].[dbo].[S_EVT_ACT] ([TARGET_PER_ID]);
    CREATE INDEX [IX_S_EVT_ACT_CREATED] ON [yourdb].[dbo].[S_EVT_ACT] ([CREATED]);
    CREATE INDEX [IX_S_EVT_ACT_TODO_CD] ON [yourdb].[dbo].[S_EVT_ACT] ([TODO_CD]);
    CREATE INDEX [IX_S_EVT_ACT_STATUS] ON [yourdb].[dbo].[S_EVT_ACT] ([EVT_STAT_CD]);
    CREATE INDEX [IX_S_EVT_ACT_OWNER] ON [yourdb].[dbo].[S_EVT_ACT] ([OWNER_PER_ID]);
END;

-- CX_CON_DEST table - Contact destination preferences
-- This table stores contact communication preferences and destinations
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='CX_CON_DEST' AND xtype='U')
BEGIN
    CREATE TABLE [yourdb].[dbo].[CX_CON_DEST] (
        [ROW_ID] NVARCHAR(15) NOT NULL PRIMARY KEY,
        [TYPE] NVARCHAR(20) NULL,
        [EMAIL_ADDR] NVARCHAR(100) NULL,
        [CONTACT_ID] NVARCHAR(15) NULL,
        [ACTIVE_FLG] NVARCHAR(1) NULL DEFAULT 'Y',
        [CREATED] DATETIME NULL DEFAULT GETDATE(),
        [CREATED_BY] NVARCHAR(15) NULL,
        [LAST_UPD] DATETIME NULL DEFAULT GETDATE(),
        [LAST_UPD_BY] NVARCHAR(15) NULL
    );
    
    -- Create indexes for performance
    CREATE INDEX [IX_CX_CON_DEST_TYPE] ON [yourdb].[dbo].[CX_CON_DEST] ([TYPE]);
    CREATE INDEX [IX_CX_CON_DEST_EMAIL] ON [yourdb].[dbo].[CX_CON_DEST] ([EMAIL_ADDR]);
    CREATE INDEX [IX_CX_CON_DEST_CONTACT] ON [yourdb].[dbo].[CX_CON_DEST] ([CONTACT_ID]);
END;

-- ============================================
-- Email Delivery Tracking Tables (Optional Enhancement)
-- ============================================

-- EMAIL_DELIVERY_EVENTS table - Email delivery event tracking
-- This table provides detailed tracking for email delivery events
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='EMAIL_DELIVERY_EVENTS' AND xtype='U')
BEGIN
    CREATE TABLE [yourdb].[dbo].[EMAIL_DELIVERY_EVENTS] (
        [EVENT_ID] NVARCHAR(50) NOT NULL PRIMARY KEY,
        [EMAIL_ADDRESS] NVARCHAR(100) NULL,
        [EVENT_TYPE] NVARCHAR(20) NULL,
        [EVENT_TIMESTAMP] DATETIME NULL,
        [UNIX_TIMESTAMP] BIGINT NULL,
        [MESSAGE_ID] NVARCHAR(100) NULL,
        [SMTP_ID] NVARCHAR(100) NULL,
        [SENDGRID_EVENT_ID] NVARCHAR(100) NULL,
        [SENDGRID_MESSAGE_ID] NVARCHAR(100) NULL,
        [REASON] NVARCHAR(500) NULL,
        [STATUS] NVARCHAR(20) NULL,
        [RESPONSE] NVARCHAR(500) NULL,
        [ATTEMPT] INT NULL,
        [USER_AGENT] NVARCHAR(200) NULL,
        [IP_ADDRESS] NVARCHAR(45) NULL,
        [URL] NVARCHAR(500) NULL,
        [ASM_GROUP_ID] INT NULL,
        [TLS] NVARCHAR(10) NULL,
        [TYPE] NVARCHAR(20) NULL,
        [CATEGORY] NVARCHAR(100) NULL,
        [CONTACT_ID] NVARCHAR(15) NULL,
        [ACTIVITY_ID] NVARCHAR(15) NULL,
        [PROCESSED] BIT NULL DEFAULT 0,
        [CREATED] DATETIME NULL DEFAULT GETDATE(),
        [CREATED_BY] NVARCHAR(15) NULL DEFAULT 'SYSTEM'
    );
    
    -- Create indexes for performance
    CREATE INDEX [IX_EMAIL_DELIVERY_EVENTS_EMAIL] ON [yourdb].[dbo].[EMAIL_DELIVERY_EVENTS] ([EMAIL_ADDRESS]);
    CREATE INDEX [IX_EMAIL_DELIVERY_EVENTS_TYPE] ON [yourdb].[dbo].[EMAIL_DELIVERY_EVENTS] ([EVENT_TYPE]);
    CREATE INDEX [IX_EMAIL_DELIVERY_EVENTS_TIMESTAMP] ON [yourdb].[dbo].[EMAIL_DELIVERY_EVENTS] ([EVENT_TIMESTAMP]);
    CREATE INDEX [IX_EMAIL_DELIVERY_EVENTS_MESSAGE_ID] ON [yourdb].[dbo].[EMAIL_DELIVERY_EVENTS] ([MESSAGE_ID]);
    CREATE INDEX [IX_EMAIL_DELIVERY_EVENTS_CONTACT] ON [yourdb].[dbo].[EMAIL_DELIVERY_EVENTS] ([CONTACT_ID]);
    CREATE INDEX [IX_EMAIL_DELIVERY_EVENTS_PROCESSED] ON [yourdb].[dbo].[EMAIL_DELIVERY_EVENTS] ([PROCESSED]);
END;

-- EMAIL_SUPPRESSION_LIST table - Email suppression tracking
-- This table tracks suppressed email addresses and reasons
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='EMAIL_SUPPRESSION_LIST' AND xtype='U')
BEGIN
    CREATE TABLE [yourdb].[dbo].[EMAIL_SUPPRESSION_LIST] (
        [SUPPRESSION_ID] NVARCHAR(50) NOT NULL PRIMARY KEY,
        [EMAIL_ADDRESS] NVARCHAR(100) NULL,
        [SUPPRESSION_TYPE] NVARCHAR(20) NULL,
        [REASON] NVARCHAR(500) NULL,
        [MESSAGE_ID] NVARCHAR(100) NULL,
        [CONTACT_ID] NVARCHAR(15) NULL,
        [SUPPRESSED_DATE] DATETIME NULL DEFAULT GETDATE(),
        [SUPPRESSED_BY] NVARCHAR(15) NULL DEFAULT 'SYSTEM',
        [ACTIVE] BIT NULL DEFAULT 1,
        [CREATED] DATETIME NULL DEFAULT GETDATE()
    );
    
    -- Create indexes for performance
    CREATE INDEX [IX_EMAIL_SUPPRESSION_EMAIL] ON [yourdb].[dbo].[EMAIL_SUPPRESSION_LIST] ([EMAIL_ADDRESS]);
    CREATE INDEX [IX_EMAIL_SUPPRESSION_TYPE] ON [yourdb].[dbo].[EMAIL_SUPPRESSION_LIST] ([SUPPRESSION_TYPE]);
    CREATE INDEX [IX_EMAIL_SUPPRESSION_DATE] ON [yourdb].[dbo].[EMAIL_SUPPRESSION_LIST] ([SUPPRESSED_DATE]);
    CREATE INDEX [IX_EMAIL_SUPPRESSION_ACTIVE] ON [yourdb].[dbo].[EMAIL_SUPPRESSION_LIST] ([ACTIVE]);
END;

-- ============================================
-- Views for Reporting
-- ============================================

-- View to show email delivery statistics
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='V_EMAIL_DELIVERY_STATS' AND xtype='V')
BEGIN
    EXEC('CREATE VIEW [yourdb].[dbo].[V_EMAIL_DELIVERY_STATS] AS
    SELECT 
        c.EMAIL_ADDR,
        c.SUPPRESS_EMAIL_FLG,
        COUNT(e.ROW_ID) as EventCount,
        COUNT(CASE WHEN e.TODO_CD = ''Data Maintenance'' THEN 1 END) as SuppressionEvents,
        COUNT(CASE WHEN e.TODO_CD = ''Email read'' THEN 1 END) as ReadEvents,
        MAX(e.CREATED) as LastEventDate,
        MAX(e.COMMENTS_LONG) as LastEventReason
    FROM [yourdb].[dbo].[S_CONTACT] c
    LEFT JOIN [yourdb].[dbo].[S_EVT_ACT] e ON c.ROW_ID = e.TARGET_PER_ID
    WHERE e.EMAIL_RECIP_ADDR = c.EMAIL_ADDR
    GROUP BY c.EMAIL_ADDR, c.SUPPRESS_EMAIL_FLG
    HAVING COUNT(e.ROW_ID) > 0');
END;

-- View to show email suppression summary
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='V_EMAIL_SUPPRESSION_SUMMARY' AND xtype='V')
BEGIN
    EXEC('CREATE VIEW [yourdb].[dbo].[V_EMAIL_SUPPRESSION_SUMMARY] AS
    SELECT 
        s.SUPPRESSION_TYPE,
        COUNT(*) as SuppressionCount,
        COUNT(DISTINCT s.EMAIL_ADDRESS) as UniqueEmails,
        MAX(s.SUPPRESSED_DATE) as LastSuppressionDate
    FROM [yourdb].[dbo].[EMAIL_SUPPRESSION_LIST] s
    WHERE s.ACTIVE = 1
    GROUP BY s.SUPPRESSION_TYPE');
END;

-- ============================================
-- Stored Procedures
-- ============================================

-- Procedure to clean up old email events
IF EXISTS (SELECT * FROM sysobjects WHERE name='SP_CLEANUP_OLD_EMAIL_EVENTS' AND xtype='P')
    DROP PROCEDURE [yourdb].[dbo].[SP_CLEANUP_OLD_EMAIL_EVENTS];

EXEC('CREATE PROCEDURE [yourdb].[dbo].[SP_CLEANUP_OLD_EMAIL_EVENTS]
    @DaysOld INT = 90
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Delete old email delivery events
    DELETE FROM [yourdb].[dbo].[EMAIL_DELIVERY_EVENTS] 
    WHERE CREATED < DATEADD(DAY, -@DaysOld, GETDATE());
    
    -- Delete old activity records
    DELETE FROM [yourdb].[dbo].[S_EVT_ACT] 
    WHERE TODO_CD IN (''Data Maintenance'', ''Email read'') 
    AND CREATED < DATEADD(DAY, -@DaysOld, GETDATE());
    
    SELECT @@ROWCOUNT as RecordsDeleted;
END');

-- Procedure to get email delivery statistics by date range
IF EXISTS (SELECT * FROM sysobjects WHERE name='SP_GET_EMAIL_DELIVERY_STATS' AND xtype='P')
    DROP PROCEDURE [yourdb].[dbo].[SP_GET_EMAIL_DELIVERY_STATS];

EXEC('CREATE PROCEDURE [yourdb].[dbo].[SP_GET_EMAIL_DELIVERY_STATS]
    @StartDate DATETIME,
    @EndDate DATETIME
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        COUNT(*) as TotalEvents,
        COUNT(CASE WHEN TODO_CD = ''Data Maintenance'' THEN 1 END) as SuppressionEvents,
        COUNT(CASE WHEN TODO_CD = ''Email read'' THEN 1 END) as ReadEvents,
        COUNT(DISTINCT EMAIL_RECIP_ADDR) as UniqueEmails,
        COUNT(DISTINCT TARGET_PER_ID) as UniqueContacts
    FROM [yourdb].[dbo].[S_EVT_ACT]
    WHERE TODO_CD IN (''Data Maintenance'', ''Email read'')
    AND CREATED BETWEEN @StartDate AND @EndDate;
END');

-- Procedure to restore suppressed email address
IF EXISTS (SELECT * FROM sysobjects WHERE name='SP_RESTORE_EMAIL_ADDRESS' AND xtype='P')
    DROP PROCEDURE [yourdb].[dbo].[SP_RESTORE_EMAIL_ADDRESS];

EXEC('CREATE PROCEDURE [yourdb].[dbo].[SP_RESTORE_EMAIL_ADDRESS]
    @EmailAddress NVARCHAR(100),
    @ContactId NVARCHAR(15) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Update contact record
    UPDATE [yourdb].[dbo].[S_CONTACT] 
    SET SUPPRESS_EMAIL_FLG = ''N''
    WHERE EMAIL_ADDR = @EmailAddress
    AND (@ContactId IS NULL OR ROW_ID = @ContactId);
    
    -- Deactivate suppression records
    UPDATE [yourdb].[dbo].[EMAIL_SUPPRESSION_LIST] 
    SET ACTIVE = 0
    WHERE EMAIL_ADDRESS = @EmailAddress
    AND ACTIVE = 1;
    
    SELECT @@ROWCOUNT as RecordsUpdated;
END');

-- ============================================
-- Sample Data (Optional)
-- ============================================
-- Uncomment the following section to insert sample data for testing

/*
-- Sample contact record
INSERT INTO [yourdb].[dbo].[S_CONTACT] 
([ROW_ID], [EMAIL_ADDR], [SUPPRESS_EMAIL_FLG], [PR_DEPT_OU_ID], [X_REGISTRATION_NUM], [X_TRAINER_NUM], [CREATED], [CREATED_BY], [ROW_STATUS])
VALUES 
('1-SAMPLE', 'test@example.com', 'N', '1-OU001', 'REG123', 'TRAIN456', GETDATE(), 'SYSTEM', 'Y');

-- Sample email delivery event
INSERT INTO [yourdb].[dbo].[EMAIL_DELIVERY_EVENTS] 
([EVENT_ID], [EMAIL_ADDRESS], [EVENT_TYPE], [EVENT_TIMESTAMP], [MESSAGE_ID], [CONTACT_ID], [PROCESSED])
VALUES 
('EVT001', 'test@example.com', 'bounce', GETDATE(), 'MSG001', '1-SAMPLE', 0);
*/

-- ============================================
-- Permissions
-- ============================================
-- Grant necessary permissions to the application user
-- Replace 'GetTwilioUser' with your actual application user

/*
-- Create application user (uncomment if needed)
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = ''GetTwilioUser'')
BEGIN
    CREATE LOGIN [GetTwilioUser] WITH PASSWORD = ''YourSecurePassword123!'';
END;

-- Create database user
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = ''GetTwilioUser'')
BEGIN
    USE [yourdb];
    CREATE USER [GetTwilioUser] FOR LOGIN [GetTwilioUser];
END;

-- Grant permissions
USE [yourdb];
GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[S_CONTACT] TO [GetTwilioUser];
GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[S_EVT_ACT] TO [GetTwilioUser];
GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[CX_CON_DEST] TO [GetTwilioUser];
GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[EMAIL_DELIVERY_EVENTS] TO [GetTwilioUser];
GRANT SELECT, INSERT, UPDATE, DELETE ON [dbo].[EMAIL_SUPPRESSION_LIST] TO [GetTwilioUser];
GRANT EXECUTE ON [dbo].[SP_CLEANUP_OLD_EMAIL_EVENTS] TO [GetTwilioUser];
GRANT EXECUTE ON [dbo].[SP_GET_EMAIL_DELIVERY_STATS] TO [GetTwilioUser];
GRANT EXECUTE ON [dbo].[SP_RESTORE_EMAIL_ADDRESS] TO [GetTwilioUser];
*/

-- ============================================
-- Script Completion
-- ============================================
PRINT 'GetTwilio Database Schema created successfully!';
PRINT 'Remember to:';
PRINT '1. Update connection strings in web.config';
PRINT '2. Create and configure application user with appropriate permissions';
PRINT '3. Test the webhook endpoint with sample data';
PRINT '4. Set up log4net configuration for logging';
PRINT '5. Configure Twilio/SendGrid webhook URL to point to the service endpoint';
