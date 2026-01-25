// Follows Supabase Edge Functions generic structure
// Deploy with: supabase functions deploy get-secure-keys

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

serve(async (req) => {
  // 1. Check for Authentication (Optional but recommended)
  // const authHeader = req.headers.get('Authorization')
  // if (!authHeader) return new Response('Unauthorized', { status: 401 })

  // 2. Retrieve Secrets from Vault (Environment Variables in Supabase Dashboard)
  // You must set these via: supabase secrets set GOOGLE_API_KEY=...
  const googleKey = Deno.env.get('GOOGLE_API_KEY')
  const vtKey = Deno.env.get('VT_API_KEY')

  if (!googleKey || !vtKey) {
    return new Response(
      JSON.stringify({ error: 'Server misconfiguration: Missing keys' }),
      { headers: { "Content-Type": "application/json" }, status: 500 }
    )
  }

  // 3. Return keys to the authenticated client
  // CLIENT-SIDE: Only store these in memory, never persist to disk!
  const data = {
    google: googleKey,
    virustotal: vtKey,
  }

  return new Response(
    JSON.stringify(data),
    { headers: { "Content-Type": "application/json" } },
  )
})
