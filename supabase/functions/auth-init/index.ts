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
