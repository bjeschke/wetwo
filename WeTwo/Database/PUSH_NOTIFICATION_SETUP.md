# Push Notification Setup Guide for WeTwo

This guide explains how to set up push notifications for the WeTwo app using the implemented solution.

## Overview

The push notification system has been implemented with:
1. **Primary Method**: Supabase Edge Functions with Firebase Cloud Messaging (FCM)
2. **Fallback Method**: Direct HTTP requests to push services
3. **Local Notifications**: For immediate feedback when app is in foreground

## Implementation Details

### 1. Swift Implementation (`SupabaseService.swift`)

The `sendPushNotificationToPartner` function now:
- Retrieves the partner's push token from the database
- Sends the notification via Supabase Edge Function
- Falls back to direct HTTP requests if Edge Function fails
- Provides comprehensive error handling and logging

### 2. Supabase Edge Function (`supabase-edge-function-send-push-notification.ts`)

The Edge Function supports multiple push services:
- **Firebase Cloud Messaging (FCM)** - Recommended for cross-platform
- **Apple Push Notification Service (APNs)** - iOS-specific
- **OneSignal** - Third-party service

## Setup Instructions

### Step 1: Choose Your Push Service

#### Option A: Firebase Cloud Messaging (Recommended)

1. **Create Firebase Project**:
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Create a new project or use existing one
   - Add iOS app to the project

2. **Configure iOS App**:
   - Download `GoogleService-Info.plist`
   - Add to your Xcode project
   - Enable Cloud Messaging in Firebase Console

3. **Get Server Key**:
   - In Firebase Console → Project Settings → Cloud Messaging
   - Copy the Server Key

#### Option B: Apple Push Notification Service

1. **Create APNs Certificate**:
   - Go to Apple Developer Portal
   - Create Push Notification certificate
   - Download and configure in your server

#### Option C: OneSignal

1. **Create OneSignal Account**:
   - Sign up at [OneSignal](https://onesignal.com/)
   - Create a new app
   - Get App ID and REST API Key

### Step 2: Deploy Supabase Edge Function

1. **Install Supabase CLI**:
   ```bash
   npm install -g supabase
   ```

2. **Login to Supabase**:
   ```bash
   supabase login
   ```

3. **Link Your Project**:
   ```bash
   supabase link --project-ref YOUR_PROJECT_REF
   ```

4. **Deploy Edge Function**:
   ```bash
   supabase functions deploy send-push-notification
   ```

### Step 3: Configure Environment Variables

In your Supabase project dashboard:

1. Go to Settings → Edge Functions
2. Add environment variables:
   ```
   FCM_SERVER_KEY=your_fcm_server_key
   ONE_SIGNAL_APP_ID=your_onesignal_app_id
   ONE_SIGNAL_REST_API_KEY=your_onesignal_rest_api_key
   ```

### Step 4: Update iOS Configuration

1. **Add Push Notification Capability**:
   - In Xcode, select your target
   - Go to Signing & Capabilities
   - Add "Push Notifications" capability

2. **Configure Background Modes** (if needed):
   - Add "Remote notifications" background mode

3. **Update Info.plist**:
   ```xml
   <key>UIBackgroundModes</key>
   <array>
       <string>remote-notification</string>
   </array>
   ```

### Step 5: Test the Implementation

1. **Test Local Notifications**:
   ```swift
   NotificationService.shared.scheduleLocalNotification(
       title: "Test",
       body: "Local notification test",
       timeInterval: 2.0
   )
   ```

2. **Test Push Notifications**:
   ```swift
   try await supabaseService.sendPushNotificationToPartner(
       userId: currentUserId,
       partnerId: partnerId,
       title: "Test Push",
       body: "This is a test push notification",
       data: ["type": "test"]
   )
   ```

## Usage Examples

### Sending Love Message Notifications

```swift
// When a love message is sent
try await supabaseService.sendPushNotificationToPartner(
    userId: currentUserId,
    partnerId: partnerId,
    title: "💌 Neue Liebesnachricht",
    body: "Du hast eine neue Nachricht erhalten!",
    data: [
        "type": "love_message",
        "messageId": messageId.uuidString
    ]
)
```

### Sending Mood Update Notifications

```swift
// When mood is updated
try await supabaseService.sendPushNotificationToPartner(
    userId: currentUserId,
    partnerId: partnerId,
    title: "💕 Stimmungsupdate",
    body: "\(userName) hat seine Stimmung aktualisiert",
    data: [
        "type": "mood_update",
        "moodLevel": moodLevel
    ]
)
```

### Sending Memory Notifications

```swift
// When a new memory is added
try await supabaseService.sendPushNotificationToPartner(
    userId: currentUserId,
    partnerId: partnerId,
    title: "📸 Neue Erinnerung",
    body: "Eine neue Erinnerung wurde hinzugefügt",
    data: [
        "type": "new_memory",
        "memoryId": memoryId.uuidString
    ]
)
```

## Troubleshooting

### Common Issues

1. **"Partner has no push token"**:
   - Ensure push notifications are enabled
   - Check that the partner has granted notification permissions
   - Verify the push token is saved in the database

2. **Edge Function fails**:
   - Check Supabase logs for errors
   - Verify environment variables are set correctly
   - Ensure the function is deployed successfully

3. **Notifications not received**:
   - Check device notification settings
   - Verify push token is valid and not expired
   - Test with a simple notification first

### Debugging

1. **Enable Detailed Logging**:
   - Check Xcode console for detailed logs
   - Monitor Supabase Edge Function logs
   - Use Firebase Console to track FCM delivery

2. **Test with Different Scenarios**:
   - App in foreground
   - App in background
   - App terminated
   - Different iOS versions

## Security Considerations

1. **Token Validation**: Always validate push tokens server-side
2. **Rate Limiting**: Implement rate limiting to prevent abuse
3. **User Consent**: Ensure users have explicitly consented to notifications
4. **Data Privacy**: Only send necessary data in notifications

## Performance Optimization

1. **Batch Notifications**: Group multiple notifications when possible
2. **Token Management**: Regularly clean up invalid tokens
3. **Caching**: Cache partner information to reduce database calls
4. **Error Handling**: Implement exponential backoff for failed requests

## Next Steps

1. **Analytics**: Add notification delivery tracking
2. **Customization**: Allow users to customize notification preferences
3. **Rich Notifications**: Add images and actions to notifications
4. **Scheduling**: Implement scheduled notifications for reminders


