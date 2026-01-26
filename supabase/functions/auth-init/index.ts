import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
    try {
        const supabaseUrl = Deno.env.get('SUPABASE_URL') || '';
        const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';
        const supabase = createClient(supabaseUrl, supabaseServiceKey);

        // 1. Fetch Secure Keys
        const googleKeyAndroid = Deno.env.get('GOOGLE_API_KEY_ANDROID');
        const googleKeyIos = Deno.env.get('GOOGLE_API_KEY_APPLE');
        const whoisKey = Deno.env.get('WHOIS_API_KEY');

        // 2. Fetch Table Counts
        const { data: tableCounts, error: dbError } = await supabase
            .from('table_counts')
            .select('table_name, row_count');

        if (dbError) throw dbError;

        const counts: Record<string, number> = {};
        tableCounts.forEach((item: any) => {
            counts[item.table_name] = item.row_count;
        });

        const responseData = {
            keys: {
                google_android: googleKeyAndroid,
                google_ios: googleKeyIos,
                whois_key: whoisKey,
            },
            counts: counts,
        };

        return new Response(
            JSON.stringify(responseData),
            { headers: { "Content-Type": "application/json" }, status: 200 }
        );
    } catch (error) {
        return new Response(
            JSON.stringify({ error: error.message }),
            { headers: { "Content-Type": "application/json" }, status: 500 }
        );
    }
})
