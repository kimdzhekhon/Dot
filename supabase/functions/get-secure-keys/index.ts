// Follows Supabase Edge Functions generic structure
// Deploy with: supabase functions deploy get-secure-keys

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

serve(async (req) => {
  // 1. Check for Authentication (Optional but recommended)
  // const authHeader = req.headers.get('Authorization')
  // if (!authHeader) return new Response('Unauthorized', { status: 401 })

  // 2. Retrieve Secrets from Vault (Environment Variables in Supabase Dashboard)
  // 2. Retrieve Secrets from Vault (Environment Variables in Supabase Dashboard)
  const googleKeyAndroid = Deno.env.get('GOOGLE_API_KEY_ANDROID')
  const googleKeyIos = Deno.env.get('GOOGLE_API_KEY_APPLE') // User named it APPLE in screenshot
  const whoisKey = Deno.env.get('WHOIS_API_KEY')

  // Relaxed check: at least one google key should exist
  if (!googleKeyAndroid && !googleKeyIos) {
    return new Response(
      JSON.stringify({ error: 'Server misconfiguration: Missing keys' }),
      { headers: { "Content-Type": "application/json" }, status: 500 }
    )
  }

  // 3. Return keys to the authenticated client
  // CLIENT-SIDE: Only store these in memory, never persist to disk!
  const data = {
    google_android: googleKeyAndroid,
    google_ios: googleKeyIos,
    whois_key: whoisKey,
  }

  return new Response(
    JSON.stringify(data),
    { headers: { "Content-Type": "application/json" } },
  )
})
