import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req: Request) => {
    // Handle CORS preflight
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders })
    }

    try {
        const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
        const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
        const supabase = createClient(supabaseUrl, supabaseServiceKey);

        console.log("Fetching secure keys...");
        const googleKey = Deno.env.get('SAFE_BROWSING_KEY');
        const whoisKey = Deno.env.get('WHOIS_API_KEY');
        // Retrieve Gemini Key (User likely set this env var or wants us to use one of the google keys)
        // User previously used GOOGLE_API_KEY_ANDROID/APPLE in get-secure-keys.
        // I will attempt to fetch 'GEMINI_API_KEY' first, then fall back to 'GOOGLE_API_KEY_ANDROID' if not set, or as requested.
        // Given user asked "make it bring Gemini key", I'll assume they might set GEMINI_API_KEY or I should use one of the existing.
        // I will use 'GEMINI_API_KEY' as the dedicated env var for clarity, or reuse if they are same.
        // Let's rely on GEMINI_API_KEY being present or added.
        const geminiKey = Deno.env.get('GEMINI_API_KEY') ?? Deno.env.get('GOOGLE_API_KEY_ANDROID');

        console.log("Fetching table counts...");
        const { data: tableCounts, error: dbError } = await supabase
            .from('table_counts')
            .select('table_name, row_count');

        if (dbError) {
            console.error("Database Error:", dbError);
            throw dbError;
        }

        const counts: Record<string, number> = {};
        if (tableCounts) {
            tableCounts.forEach((item: any) => {
                counts[item.table_name] = item.row_count;
            });
        }

        console.log("Success! Returning data for tables:", Object.keys(counts));

        const responseData = {
            keys: {
                google_key: googleKey,
                whois_key: whoisKey,
                gemini_key: geminiKey,
            },
            counts: counts,
            timestamp: new Date().toISOString(),
            status: "success"
        };

        return new Response(
            JSON.stringify(responseData),
            {
                headers: { ...corsHeaders, "Content-Type": "application/json" },
                status: 200
            }
        );
    } catch (error: any) {
        console.error("Function Error:", error.message);
        return new Response(
            JSON.stringify({ error: error.message, status: "error" }),
            {
                headers: { ...corsHeaders, "Content-Type": "application/json" },
                status: 500
            }
        );
    }
})
