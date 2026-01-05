// Supabase Edge Function for fetching daily chemistry news
// This function is triggered by pg_cron scheduler

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

const BACKEND_URL = Deno.env.get('BACKEND_URL') || 'http://localhost:3006'

serve(async (req) => {
    try {
        console.log('🔄 Starting scheduled news fetch...')

        // Call backend news fetch endpoint
        const response = await fetch(`${BACKEND_URL}/api/news/fetch-daily`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
        })

        const data = await response.json()

        if (response.ok) {
            console.log('✅ News fetch completed successfully:', data)
            return new Response(
                JSON.stringify({
                    success: true,
                    message: 'Daily news fetch completed',
                    data: data,
                    timestamp: new Date().toISOString(),
                }),
                {
                    headers: { 'Content-Type': 'application/json' },
                    status: 200,
                }
            )
        } else {
            throw new Error(`Backend returned status ${response.status}: ${JSON.stringify(data)}`)
        }
    } catch (error) {
        console.error('❌ News fetch failed:', error)
        return new Response(
            JSON.stringify({
                success: false,
                error: error.message,
                timestamp: new Date().toISOString(),
            }),
            {
                headers: { 'Content-Type': 'application/json' },
                status: 500,
            }
        )
    }
})
