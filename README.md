# GetTwilio Webhook Service

## Table of Contents

1. [Overview](#overview)
2. [Design](#design)
3. [Architecture](#architecture)
4. [Data Model](#data-model)
5. [Database Schema](#database-schema)
6. [Data Structures](#data-structures)
7. [Webhook Payload Format](#webhook-payload-format)
8. [Business Logic](#business-logic)
9. [Assumptions](#assumptions)
10. [Error Handling](#error-handling)
11. [Security Considerations](#security-considerations)
12. [Configuration](#configuration)
13. [Deployment](#deployment)
14. [Monitoring and Maintenance](#monitoring-and-maintenance)
15. [API Reference](#api-reference)
16. [References](#references)
17. [Update History](#update-history)
18. [Notifications](#notifications)
19. [Related Web Services](#related-web-services)
20. [Executing](#executing)
21. [Testing](#testing)
22. [Logging](#logging)
23. [Results](#results)

## Overview

This service implements an integration point for the Twilio mail processing service. When an email bounces or is rejected, a defined "web hook" on that service forwards it to this service for processing. The email address is either flagged do-not-email or removed entirely, and an activity is created, for everyone processed. This service is complemented by the CMProcessEmailImport agent which processes returned email reports from Mandrill in batch.

The GetTwilio webhook service is a C# ASP.NET web service that processes email delivery status notifications from Twilio/SendGrid. When emails are sent through Twilio's email service, delivery events (bounces, opens, clicks, spam reports, unsubscribes, etc.) are sent as webhook notifications to this service, which then updates the corresponding database records to track email engagement and manage email suppression lists.

### Purpose
This service serves as a bridge between the Twilio email platform and the internal customer relationship management system, ensuring that all email delivery events are properly recorded and tracked for customer service follow-up and email list maintenance.

### Scope
The service handles:
- Real-time email delivery event processing
- Email address validation and suppression
- Contact record updates
- Activity record creation in the CRM system
- Email engagement tracking
- Destination cleanup for invalid contacts

## Design

### System Architecture

The GetTwilio service follows a layered architecture pattern with clear separation of concerns:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Twilio        │──▶│  GetTwilio.ashx │───▶│   SQL Server    │
│   Email Service │    │   Web Service   │    │   Database      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              │
                              ▼
                       ┌─────────────────┐
                       │   Log4net       │
                       │   Logging       │
                       └─────────────────┘
```

### Design Principles

1. **Single Responsibility**: Each component has a specific, well-defined purpose
2. **Fail-Safe**: Comprehensive error handling and logging
3. **Performance**: Efficient database operations with connection pooling
4. **Maintainability**: Clear code structure and comprehensive documentation
5. **Security**: Input validation and SQL injection prevention

### Integration Overview

See BulkMailServer#Bounce_Mail_Administration for information regarding the integration, and an overview of this system.

## Architecture

### Components

- **GetTwilio.ashx** - ASP.NET HTTP handler declaration
- **GetTwilio.ashx.cs** - Main webhook processing logic
- **Database Schema** - SQL Server tables for contact management and activity tracking
- **Logging** - log4net integration for debugging and monitoring

### Data Flow

1. Twilio/SendGrid sends JSON webhook notification with email delivery events
2. Service deserializes the JSON payload
3. Extracts email address, event type, and other metadata
4. Queries the database to find the contact record
5. Updates contact record based on event type (suppresses email or tracks engagement)
6. Creates activity record for audit trail
7. Logs processing results and performance data

## Data Model

In order to support the information generated from this service, the following fields have special meaning in an activity created from this service:

| FIELD | DESCRIPTION |
|-------|-------------|
| EMAIL_RECIP_ADDR | Contains the email address operated on |
| SRA_TYPE_CD | Mapped to code "Data Maintenance" |
| COMMENTS_LONG | Contains the notice and the SMTP error message |

The Twilio service provides data in JSON object format. The Newtonsoft JSON.Net library is used to convert this into C# classes.

### Data Structures

The class defined to receive data from JSON is as follows:

```csharp
public class SmtpEvent
{
    public string email { get; set; }
    public int timestamp { get; set; }
    [JsonProperty(PropertyName = "smtp-id")]
    public string smtpid { get; set; }
    [JsonProperty(PropertyName = "event")]
    public string mailevent { get; set; }
    public string category { get; set; }
    public string sg_event_id { get; set; }
    public string sg_message_id { get; set; }
    public string reason { get; set; }
    public string status { get; set; }
    public string response { get; set; }
    public int attempt { get; set; }
    public string useragent { get; set; }
    public string ip { get; set; }
    public string url { get; set; }
    public int asm_group_id { get; set; }
    public string tls { get; set; }
    public string type { get; set; }
}
```

## Database Schema

### Primary Tables

#### S_CONTACT (yourdb.dbo.S_CONTACT)
Stores contact information including email addresses and suppression flags.

**Key Fields:**
- `ROW_ID` - Primary key
- `EMAIL_ADDR` - Contact's email address
- `SUPPRESS_EMAIL_FLG` - Flag to suppress future emails
- `PR_DEPT_OU_ID` - Organizational unit ID
- `X_REGISTRATION_NUM` - Registration number
- `X_TRAINER_NUM` - Trainer number

#### S_EVT_ACT (yourdb.dbo.S_EVT_ACT)
Tracks activities and events, including email delivery events.

**Key Fields:**
- `ROW_ID` - Primary key
- `ACTIVITY_UID` - Unique activity identifier
- `COMMENTS_LONG` - Detailed description of the event
- `EMAIL_RECIP_ADDR` - Email address that triggered the event
- `TARGET_PER_ID` - Contact ID
- `TODO_CD` - Activity type ("Data Maintenance" for suppressions, "Email read" for engagement)

#### CX_CON_DEST (yourdb.dbo.CX_CON_DEST)
Stores contact communication preferences and destinations.

**Key Fields:**
- `ROW_ID` - Primary key
- `TYPE` - Communication type (e.g., "EMAIL")
- `EMAIL_ADDR` - Email address
- `CONTACT_ID` - Reference to contact

### Enhanced Tables (Optional)

#### EMAIL_DELIVERY_EVENTS (yourdb.dbo.EMAIL_DELIVERY_EVENTS)
Detailed tracking for email delivery events with comprehensive metadata.

#### EMAIL_SUPPRESSION_LIST (yourdb.dbo.EMAIL_SUPPRESSION_LIST)
Tracks suppressed email addresses and reasons for suppression.

## Configuration

### Web.config Settings

```xml
<appSettings>
    <!-- Debug mode: Y=Yes, N=No, T=Trace -->
    <add key="GetTwilio_debug" value="Y" />
    
    <!-- Employee ID for activity records -->
    <add key="GetChat_EmpId" value="1-XXXXX" />
    
    <!-- Employee login for activity records -->
    <add key="GetChat_EmpLogin" value="TECHNICAL SUPPORT" />
</appSettings>

<connectionStrings>
    <add name="ApplicationServices"
         connectionString="data source=.\SQLEXPRESS;Integrated Security=SSPI;AttachDBFilename=|DataDirectory|\aspnetdb.mdf;User Instance=true"
         providerName="System.Data.SqlClient" />
    <add name="hcidb" 
         connectionString="server=YOUR_SERVER\YOUR_INSTANCE;uid=YOUR_USER;pwd=YOUR_PASSWORD;Min Pool Size=3;Max Pool Size=5;Connect Timeout=10;database=" 
         providerName="System.Data.SqlClient" />
</connectionStrings>
```

### Configuration Item Descriptions

The following is a description of the configuration items:

- **GetTwilio_debug**: The only way to enable debug mode. The value stored here turns that mode on or off.
- **GetChat_EmpId**: Used to specify the employee id for activities generated.
- **GetChat_EmpLogin**: Used to specify the employee login for activities generated.
- **hcidb connectionString**: Used to specify the database connection string.

This is extracted using the following code in the service:

```csharp
// ============================================
// Debug Setup
mypath = HttpRuntime.AppDomainAppPath;
Logging = "Y";
try
{
    temp = WebConfigurationManager.AppSettings["GetTwilio_debug"];
    Debug = temp;
    EmpId = WebConfigurationManager.AppSettings["GetChat_EmpId"];
    if (EmpId == "") { EmpId = "1-XXXXX"; }
    EmpLogin = WebConfigurationManager.AppSettings["GetChat_EmpLogin"];
    if (EmpLogin == "") { EmpLogin = "TECHNICAL SUPPORT"; }
}
catch { }

// ============================================
// Get system defaults
ConnectionStringSettings connSettings = ConfigurationManager.ConnectionStrings["hcidb"];
if (connSettings != null)
{
    ConnS = connSettings.ConnectionString;
}
if (ConnS == "")
{
    ConnS = "server=YOUR_SERVER\\YOUR_INSTANCE;uid=YOUR_USER;pwd=YOUR_PASSWORD;database=yourdb";
}
```

### log4net Configuration

The web.config file also contains SysLog configuration information:

```xml
<log4net>
    <appender name="RemoteSyslogAppender" type="log4net.Appender.RemoteSyslogAppender">
        <identity value="" />
        <layout type="log4net.Layout.PatternLayout" value="%message"/>
        <remoteAddress value="YOUR_SYSLOG_SERVER_IP" />
        <filter type="log4net.Filter.LevelRangeFilter">
            <levelMin value="DEBUG" />
        </filter>
    </appender>
    
    <appender name="LogFileAppender" type="log4net.Appender.RollingFileAppender">
        <file type="log4net.Util.PatternString" value="%property{LogFileName}"/>
        <appendToFile value="true"/>
        <rollingStyle value="Size"/>
        <maxSizeRollBackups value="3"/>
        <maximumFileSize value="10000KB"/>
        <staticLogFileName value="true"/>
        <layout type="log4net.Layout.PatternLayout">
            <conversionPattern value="%message%newline"/>
        </layout>
    </appender>
    
    <logger name="EventLog">
        <level value="ALL"/>
        <appender-ref ref="RemoteSyslogAppender"/>
    </logger>
    
    <logger name="DebugLog">
        <level value="ALL"/>
        <appender-ref ref="LogFileAppender"/>
    </logger>
</log4net>
```

## Webhook Payload Format

The service expects JSON payloads in the following format (based on SendGrid webhook structure):

```json
[
    {
        "email": "example@test.com",
        "timestamp": 1513299569,
        "smtp-id": "<14c5d75ce93.dfd.64b469@ismtpd-555>",
        "event": "bounce",
        "category": "cat facts",
        "sg_event_id": "6g4ZI7SA-xmRDv57GoPIPw==",
        "sg_message_id": "14c5d75ce93.dfd.64b469.filter0001.16648.5515E0B88.0",
        "reason": "500 unknown recipient",
        "status": "5.0.0",
        "response": "550 5.1.1 User unknown",
        "attempt": "1",
        "useragent": "Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0)",
        "ip": "192.168.1.1",
        "url": "https://example.com",
        "asm_group_id": 1,
        "tls": "1",
        "type": "bounce"
    }
]
```

## Business Logic

### Email Event Processing Rules

1. **Event Types Processed**:
   - `dropped` - Email was dropped by SendGrid
   - `bounce` - Email bounced back
   - `spamreport` - Email was marked as spam
   - `unsubscribe` - Recipient unsubscribed
   - `open` - Email was opened
   - `click` - Link in email was clicked

2. **Suppression Events** (removeaddr = true):
   - `dropped`, `bounce`, `spamreport`, `unsubscribe`
   - For contacts with registration/trainer numbers: Set `SUPPRESS_EMAIL_FLG = 'Y'`
   - For contacts without registration/trainer numbers: Remove email address completely
   - Delete related CX_CON_DEST records for contacts without registration/trainer numbers

3. **Engagement Events** (clicked = true):
   - `open`, `click`
   - Create activity record for tracking engagement
   - No suppression actions taken

4. **Activity Creation**: For all processed events, an activity record is created with:
   - Type: "Data Maintenance" (for suppressions) or "Email read" (for engagement)
   - Priority: "2-High"
   - Status: "Done"
   - Detailed description of the event

### Excluded Email Addresses

The service ignores the following email addresses:
- `root@bm2.example.com`
- `root@bm1.example.com`

## Assumptions

The following assumptions are made about the system:

1. **JSON Format**: The supplied JSON file is properly formed and follows the Twilio webhook format.
2. **Contact Records**: One or more email addresses exist in Contact records in the database.
3. **Database Connectivity**: The database is accessible and the connection string is valid.
4. **Webhook Reliability**: Twilio will deliver webhook notifications reliably.
5. **Data Integrity**: Contact records maintain referential integrity with related tables.

## Error Handling

### Logging Levels

- **Event Log**: Records successful processing and errors
- **Debug Log**: Detailed trace information (when debug mode is enabled)
- **JSON Log**: Raw webhook payloads stored in `C:\Logs\GetTwilio-JSON.log`

### Error Scenarios

1. **Database Connection Issues**: Automatic retry with connection pooling disabled
2. **JSON Parsing Errors**: Detailed error logging with original payload
3. **Missing Contact Records**: Logged as informational messages (not errors)
4. **SQL Execution Errors**: Comprehensive error logging with context

## Security Considerations

### Input Validation

- Email addresses are validated and sanitized
- SQL injection prevention through parameterized queries (where applicable)
- JSON payload size limits
- Error message truncation to prevent buffer overflows

### Access Control

- Database user should have minimal required permissions
- Log files should be secured with appropriate file system permissions
- Webhook endpoint should be protected with authentication if possible

## Deployment

### Prerequisites

1. SQL Server with appropriate database
2. .NET Framework 4.0 or higher
3. log4net library
4. Newtonsoft.Json library
5. Appropriate database permissions

### Installation Steps

1. Deploy the web service files to IIS
2. Run the database schema script (`GetTwilio_Database_Schema.sql`)
3. Configure web.config with appropriate connection strings and settings
4. Set up log4net configuration
5. Create application user with necessary database permissions
6. Configure Twilio/SendGrid webhook URL to point to the service endpoint

### Testing

1. Enable debug mode in web.config
2. Send test webhook payload to the service
3. Verify database updates and log entries
4. Test error scenarios (invalid JSON, database unavailable, etc.)

## Monitoring and Maintenance

### Performance Monitoring

- Monitor log file sizes and rotation
- Track database performance for contact lookups
- Monitor webhook response times

### Maintenance Tasks

- Regular cleanup of old email events using `SP_CLEANUP_OLD_EMAIL_EVENTS`
- Log file rotation and archival
- Database index maintenance
- Review and manage suppressed email addresses

### Troubleshooting

#### Common Issues

1. **Webhook Not Processing**: Check IIS logs, verify endpoint URL
2. **Database Connection Errors**: Verify connection string and permissions
3. **JSON Parsing Errors**: Check webhook payload format
4. **Missing Activity Records**: Verify web service configuration and permissions

#### Debug Mode

Enable debug mode by setting `GetTwilio_debug` to "Y" in web.config. This will:
- Log detailed trace information
- Record all SQL queries
- Show step-by-step processing information
- Display event processing details

## API Reference

### Endpoint

```
POST /GetTwilio.ashx
Content-Type: application/json
```

### Request

Raw JSON payload from Twilio/SendGrid webhook.

### Response

- **Success**: HTTP 200 with no content
- **Error**: HTTP 500 with error details in logs

### Headers

The service accepts standard HTTP headers. No special authentication headers are required (consider adding authentication for production use).

## Reporting and Analytics

### Available Views

1. **V_EMAIL_DELIVERY_STATS**: Email delivery statistics by contact
2. **V_EMAIL_SUPPRESSION_SUMMARY**: Summary of email suppressions by type

### Stored Procedures

1. **SP_CLEANUP_OLD_EMAIL_EVENTS**: Clean up old email event records
2. **SP_GET_EMAIL_DELIVERY_STATS**: Get email delivery statistics for date ranges
3. **SP_RESTORE_EMAIL_ADDRESS**: Restore a suppressed email address

### Sample Queries

```sql
-- Get email delivery statistics for the last 30 days
EXEC SP_GET_EMAIL_DELIVERY_STATS 
    @StartDate = DATEADD(DAY, -30, GETDATE()),
    @EndDate = GETDATE();

-- Get suppression summary
SELECT * FROM V_EMAIL_SUPPRESSION_SUMMARY 
ORDER BY SuppressionCount DESC;

-- Get delivery stats by contact
SELECT * FROM V_EMAIL_DELIVERY_STATS 
WHERE SUPPRESS_EMAIL_FLG = 'Y';

-- Restore a suppressed email address
EXEC SP_RESTORE_EMAIL_ADDRESS 
    @EmailAddress = 'customer@example.com',
    @ContactId = '1-CONT001';
```

## Email Event Types

### Suppression Events

- **bounce**: Email bounced back (hard or soft bounce)
- **dropped**: Email was dropped by SendGrid (invalid address, etc.)
- **spamreport**: Recipient marked email as spam
- **unsubscribe**: Recipient unsubscribed from emails

### Engagement Events

- **open**: Email was opened by recipient
- **click**: Link in email was clicked

### Other Events (Not Processed)

- **delivered**: Email was successfully delivered
- **deferred**: Email delivery was deferred
- **processed**: Email was processed by SendGrid

## Best Practices

### Email List Management

1. **Regular Cleanup**: Use stored procedures to clean up old events
2. **Suppression Monitoring**: Regularly review suppressed email addresses
3. **Engagement Tracking**: Monitor open and click rates
4. **Bounce Management**: Address hard bounces promptly

### Performance Optimization

1. **Database Indexing**: Ensure proper indexes on frequently queried fields
2. **Log Rotation**: Implement log file rotation to prevent disk space issues
3. **Connection Pooling**: Monitor database connection usage
4. **Error Handling**: Implement proper error handling and retry logic

## References

The following was referenced during implementation:

- **SendGrid Tracking Events Documentation**: https://sendgrid.com/docs/for-developers/tracking-events/ - Documentation for processing Twilio tracking events
- **GetMail Service**: This service provided the model for GetTwilio

## Update History

### 1/20/20
Updated to not send non-found email address notifications to SysLog

### 1/21/20
Updated to only create activities for the first contact record associated with an email address

### 2/17/20
Updated to use the read-only instance for querying for contacts and to support WebServicesSecurity#Version_Management

## Notifications

None at this time.

## Related Web Services

This service was based on the GetMail service

- **GenerateRecordId**: Used to generate a new S_EVT_ACT.ROW_ID
- **LogPerformanceData**: Logs performance statistics on this service

## Executing

This service is executed by Twilio using the following URL:
```
http://your-domain.com/GetTwilio.ashx
```

The service is provided a JSON object similar to the following (and formatted using https://jsonlint.com/):

```json
[{
   "email": "user@example.com",
   "event": "open",
   "ip": "192.168.1.100",
   "mc_stats": "singlesend",
   "phase_id": "send",
   "send_at": "1579273200",
   "sg_content_type": "html",
   "sg_event_id": "rj-R1PW0Rq2IrKcWXRYhWA",
   "sg_message_id": "_vRkOqq9Qaq5zWOfkmsGBw.filterdrecv-p3mdw1-56c97568b5-bclrh-18-5E21CC0E-FC.3",
   "sg_template_id": "d-850bd1f51d8e4c758ecb75b67e83a367",
   "sg_template_name": "Version 2019-12-11T16:02:40.342Z",
   "singlesend_id": "a890067f-1c2f-11ea-83c1-a2107c0f88d5",
   "template_id": "d-850bd1f51d8e4c758ecb75b67e83a367",
   "timestamp": 1579291795,
   "useragent": "Mozilla/5.0 (Windows NT 5.1; rv:11.0) Gecko Firefox/11.0 (via ggpht.com GoogleImageProxy)"
}]
```

This service attempts to parse this information to determine whom to remove/flag their email address and create an activity.

## Testing

This web service can be tested using Fiddler (available at your-tools-directory\FiddlerSetup.exe) by doing the following using the Composer tab:

1. Create a POST transaction to `http://your-production-server/GetTwilio.ashx` if using a production server, or `http://localhost:8080/GetTwilio.ashx` if executing on the development machine.
2. In the Request Headers box add `Content-type: application/json; charset=utf-8`
3. In the Request Body of the transaction, enter a test JSON object (formatted or non-formatted).
4. Click the "Execute" button to send the transaction
5. Check the transaction in the database in the Activities > All Activities view.

The results will be reported in the log file `C:\Logs\GetTwilio.log` on the server tested or the local development workstation.

## Logging

This service provides a "Debug" log, `GetTwilio.log` which is produced in the log folder (`C:\Logs` on the application servers), which is initiated when the Debug parameter is set to "Y".

### Debug Log Example

```
Trace Log Started 1/17/2020 3:32:03 PM
Parameters-
jsonString: [{"email":"user@example.com","event":"open","ip":"192.168.1.100","mc_stats":"singlesend","phase_id":"send","send_at":"1579273200","sg_content_type":"html","sg_event_id":"4ldB-uMBR_yCaElZEC3N0w","sg_message_id":"w_u0jeK0S1q9gsc4j0lORA.filterdrecv-p3las1-5bf99c48d-mg9g8-20-5E21CC15-54.14","sg_template_id":"d-850bd1f51d8e4c758ecb75b67e83a367","sg_template_name":"Version 2019-12-11T16:02:40.342Z","singlesend_id":"a890067f-1c2f-11ea-83c1-a2107c0f88d5","template_id":"d-850bd1f51d8e4c758ecb75b67e83a367","timestamp":1579293074,"useragent":"Mozilla/4.0 (compatible; ms-office; MSOffice 16)"}]

MESSAGES: 

0
>id: 
>emailAddress: user@example.com
>EmailTime: 1/17/2020 3:31:14 PM
>EmailEvent: open

....
Processing: 0 - user@example.com
> toProcess: True
> clicked: True
> removeaddr: False

Email address query: 
SELECT ROW_ID, PR_DEPT_OU_ID, X_REGISTRATION_NUM, X_TRAINER_NUM FROM yourdb.dbo.S_CONTACT WHERE LOWER(EMAIL_ADDR)='user@example.com'
>CON_ID: D204536YD3 >OU_ID: CLN753073 >REG_NUM: ZW1645TWUVZ     >TRAINER_NUM: 
>ACTIVITY_ID: 9A45I805AB
>temperror: Message sent to email address user@example.com was marked open

Insert Activity query: 
INSERT INTO yourdb.dbo.S_EVT_ACT (ACTIVITY_UID,ALARM_FLAG,APPT_REPT_FLG,APPT_START_DT,ASGN_MANL_FLG,ASGN_USR_EXCLD_FLG,BEST_ACTION_FLG,BILLABLE_FLG,CAL_DISP_FLG,COMMENTS_LONG,CONFLICT_ID,COST_CURCY_CD,COST_EXCH_DT,CREATED,CREATED_BY,CREATOR_LOGIN,DCKING_NUM,DURATION_HRS,EMAIL_ATT_FLG, EMAIL_FORWARD_FLG,EMAIL_RECIP_ADDR,EVT_PRIORITY_CD,EVT_STAT_CD,LAST_UPD,LAST_UPD_BY,MODIFICATION_NUM,NAME,OWNER_LOGIN,OWNER_PER_ID,PCT_COMPLETE,PRIV_FLG,ROW_ID,ROW_STATUS,TARGET_OU_ID,TARGET_PER_ID,TEMPLATE_FLG,TMSHT_RLTD_FLG,TODO_CD,TODO_ACTL_START_DT,TODO_ACTL_END_DT) VALUES ('9A45I805AB','N','N',GETDATE(),'Y','Y','N','N','N','Message sent to email address user@example.com was marked open',0,'USD',GETDATE(),GETDATE(),'1-3HIZ7','WEBUSER',0,0.00,'N','N','user@example.com','2-High','Done', GETDATE(),'1-3HIZ7',0,'Read message', 'WEBUSER', '',100,'N','9A45I805AB','Y','CLN753073','D204536YD3','N','N', 'Email read', '1/17/2020 3:31:14 PM', GETDATE())

ltemp: 
17/1/2020 15:32:03: OPEN for contact id 'D204536YD3' with address 'user@example.com' at 1/17/2020 3:31:14 PM stored to activity id 9A45I805AB

LogPerformanceDataAsync: CLOUDSVC6 : 1/17/2020 3:32:03 PM

17/1/2020 15:32:03: OPEN for contact id 'D204536YD3' with address 'user@example.com' at 1/17/2020 3:31:14 PM stored to activity id 9A45I805AB
Trace Log Ended 1/17/2020 3:32:03 PM
----------------------------------
```

If debug logging is disabled, transactions are logged to the SysLog server as in the following:

```
2020-01-17 15:33:31.867	your-server.example.com
GetTwilio : 17/1/2020 15:33:36: OPEN for contact id 'N3203611UQEK' with address 'user@example.com' at 1/17/2020 3:32:27 PM stored to activity id 3IR6NFWG4J3C
```

Finally, the JSON string provided to this service itself is logged to the file `GetTwilio-JSON.log` in the same directory.

## Results

When this service is executed, it creates activity records in the database. There is no other results provided other than the log file.

## Version History

- **v1.0.0** - Initial implementation with basic email event processing
- **v1.0.1** - Added comprehensive logging and error handling
- **v1.0.2** - Enhanced database schema with indexes and views
- **v1.0.3** - Added email suppression management features
