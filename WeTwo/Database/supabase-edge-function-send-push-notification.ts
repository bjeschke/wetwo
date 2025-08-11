// Supabase Edge Function: send-push-notification
// This function should be deployed to your Supabase project

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { token, title, body, data, sound = 'default', badge = 1 } = await req.json()

    if (!token || !title || !body) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: token, title, body' }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Option 1: Send via Firebase Cloud Messaging (FCM)
    const fcmResult = await sendViaFCM(token, title, body, data, sound, badge)
    
    // Option 2: Send via Apple Push Notification Service (APNs)
    // const apnsResult = await sendViaAPNs(token, title, body, data, sound, badge)
    
    // Option 3: Send via OneSignal
    // const oneSignalResult = await sendViaOneSignal(token, title, body, data, sound, badge)

    return new Response(
      JSON.stringify({ success: true, result: fcmResult }),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    console.error('Error sending push notification:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})

async function sendViaFCM(token: string, title: string, body: string, data: any, sound: string, badge: number) {
  const FCM_SERVER_KEY = Deno.env.get('FCM_SERVER_KEY')
  const FCM_ENDPOINT = 'https://fcm.googleapis.com/fcm/send'

  const payload = {
    to: token,
    notification: {
      title: title,
      body: body,
      sound: sound,
      badge: badge.toString()
    },
    data: data,
    priority: 'high'
  }

  const response = await fetch(FCM_ENDPOINT, {
    method: 'POST',
    headers: {
      'Authorization': `key=${FCM_SERVER_KEY}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(payload)
  })

  const result = await response.json()
  console.log('FCM Response:', result)
  
  return result
}

async function sendViaAPNs(token: string, title: string, body: string, data: any, sound: string, badge: number) {
  // This would require APNs certificate/key setup
  // Implementation depends on your APNs configuration
  console.log('APNs implementation would go here')
  return { success: false, message: 'APNs not implemented' }
}

async function sendViaOneSignal(token: string, title: string, body: string, data: any, sound: string, badge: number) {
  const ONE_SIGNAL_APP_ID = Deno.env.get('ONE_SIGNAL_APP_ID')
  const ONE_SIGNAL_REST_API_KEY = Deno.env.get('ONE_SIGNAL_REST_API_KEY')
  const ONE_SIGNAL_ENDPOINT = 'https://onesignal.com/api/v1/notifications'

  const payload = {
    app_id: ONE_SIGNAL_APP_ID,
    include_player_ids: [token],
    headings: { en: title },
    contents: { en: body },
    data: data,
    sound: sound,
    badge: badge
  }

  const response = await fetch(ONE_SIGNAL_ENDPOINT, {
    method: 'POST',
    headers: {
      'Authorization': `Basic ${ONE_SIGNAL_REST_API_KEY}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(payload)
  })

  const result = await response.json()
  console.log('OneSignal Response:', result)
  
  return result
}


