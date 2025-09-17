# GetTwilio Webhook Service

## Overview

The GetTwilio webhook service is a C# ASP.NET web service that processes email delivery status notifications from Twilio/SendGrid. When emails are sent through Twilio's email service, delivery events (bounces, opens, clicks, spam reports, unsubscribes, etc.) are sent as webhook notifications to this service, which then updates the corresponding database records to track email engagement and manage email suppression lists.

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
    <add key="GetTwilio_debug" value="N" />
    
    <!-- Employee ID for activity records -->
    <add key="GetChat_EmpId" value="YOUR_EMP_ID" />
    
    <!-- Employee login for activity records -->
    <add key="GetChat_EmpLogin" value="YOUR_EMP_LOGIN" />
</appSettings>

<connectionStrings>
    <add name="YourConnectionStringName" 
         connectionString="server=YOUR_SERVER\YOUR_INSTANCE;uid=YOUR_USER;pwd=YOUR_PASSWORD;database=YOUR_DATABASE" 
         providerName="System.Data.SqlClient" />
</connectionStrings>
```

### log4net Configuration

The service uses log4net for logging. Configure in web.config:

```xml
<log4net>
    <appender name="EventLogAppender" type="log4net.Appender.EventLogAppender">
        <applicationName value="GetTwilio" />
        <layout type="log4net.Layout.PatternLayout">
            <conversionPattern value="%date [%thread] %-5level %logger - %message%newline" />
        </layout>
    </appender>
    
    <appender name="DebugLogAppender" type="log4net.Appender.RollingFileAppender">
        <file value="C:\Logs\GetTwilio.log" />
        <appendToFile value="true" />
        <rollingStyle value="Size" />
        <maxSizeRollBackups value="10" />
        <maximumFileSize value="10MB" />
        <staticLogFileName value="false" />
        <layout type="log4net.Layout.PatternLayout">
            <conversionPattern value="%date [%thread] %-5level %logger - %message%newline" />
        </layout>
    </appender>
    
    <logger name="EventLog">
        <level value="INFO" />
        <appender-ref ref="EventLogAppender" />
    </logger>
    
    <logger name="DebugLog">
        <level value="DEBUG" />
        <appender-ref ref="DebugLogAppender" />
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
- `root@yourdomain.com`
- `root@yourdomain2.com`

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

## Version History

- **v1.0.0** - Initial implementation with basic email event processing
- **v1.0.1** - Added comprehensive logging and error handling
- **v1.0.2** - Enhanced database schema with indexes and views
- **v1.0.3** - Added email suppression management features

## Support

For technical support or questions about this service, please refer to the application logs and database records. The service includes comprehensive logging to assist with troubleshooting.

## License

This software is proprietary and confidential. Unauthorized copying, distribution, or modification is prohibited.
