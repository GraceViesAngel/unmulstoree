import { createClient } from 'jsr:@supabase/supabase-js@2'

interface NotificationPayload {
  title: string
  body: string
}

interface FcmResponse {
  success: number
  failed: number
  errors: string[]
}

async function getAccessToken(
  clientEmail: string,
  privateKey: string,
): Promise<string> {
  const jwt = await createJwt(clientEmail, privateKey)
  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  })
  const data = await res.json()
  return data.access_token as string
}

async function createJwt(
  clientEmail: string,
  privateKey: string,
): Promise<string> {
  const header = { alg: 'RS256', typ: 'JWT' }
  const now = Math.floor(Date.now() / 1000)
  const payload = {
    iss: clientEmail,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  }

  const encoder = new TextEncoder()
  const headerB64 = btoa(JSON.stringify(header))
  const payloadB64 = btoa(JSON.stringify(payload))
  const signatureInput = `${headerB64}.${payloadB64}`

  const key = await crypto.subtle.importKey(
    'pkcs8',
    pemToBinary(privateKey),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  )

  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    key,
    encoder.encode(signatureInput),
  )

  const signatureB64 = btoa(
    String.fromCharCode(...new Uint8Array(signature)),
  )

  return `${signatureInput}.${signatureB64}`
}

function pemToBinary(pem: string): ArrayBuffer {
  const cleaned = pem
    .replace(/\\n/g, '\n')
    .replace(/-----BEGIN [\w\s]+-----/g, '')
    .replace(/-----END [\w\s]+-----/g, '')
    .replace(/\s/g, '')
  const binary = atob(cleaned)
  const bytes = new Uint8Array(binary.length)
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i)
  }
  return bytes.buffer
}

async function sendFcmV1(
  projectId: string,
  accessToken: string,
  token: string,
  title: string,
  body: string,
): Promise<boolean> {
  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${accessToken}`,
      },
      body: JSON.stringify({
        message: {
          token,
          notification: { title, body },
        },
      }),
    },
  )
  return res.ok
}

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': '*',
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: corsHeaders })
  }

  try {
    const { title, body } = await req.json() as NotificationPayload

    if (!title || !body) {
      return new Response(
        JSON.stringify({ error: 'title and body are required' }),
        { status: 400, headers: { 'Content-Type': 'application/json', ...corsHeaders } },
      )
    }

    const projectId = Deno.env.get('FCM_PROJECT_ID')
    const clientEmail = Deno.env.get('FCM_CLIENT_EMAIL')
    const privateKey = Deno.env.get('FCM_PRIVATE_KEY')

    if (!projectId || !clientEmail || !privateKey) {
      return new Response(
        JSON.stringify({
          error: 'FCM credentials not configured. Set FCM_PROJECT_ID, FCM_CLIENT_EMAIL, FCM_PRIVATE_KEY secrets.',
        }),
        { status: 500, headers: { 'Content-Type': 'application/json', ...corsHeaders } },
      )
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseKey)

    const { data: profiles, error } = await supabase
      .from('profiles')
      .select('fcm_token')
      .not('fcm_token', 'is', null)

    if (error) {
      throw new Error(`Failed to fetch profiles: ${error.message}`)
    }

    const tokens = (profiles as { fcm_token: string }[])
      .map((p) => p.fcm_token)
      .filter((t) => t != null && t.length > 0)

    if (tokens.length === 0) {
      return new Response(
        JSON.stringify({ success: 0, failed: 0, errors: [] } satisfies FcmResponse),
        { headers: { 'Content-Type': 'application/json', ...corsHeaders } },
      )
    }

    const accessToken = await getAccessToken(clientEmail, privateKey)
    const result: FcmResponse = { success: 0, failed: 0, errors: [] }

    for (const token of tokens) {
      const ok = await sendFcmV1(projectId, accessToken, token, title, body)
      if (ok) {
        result.success++
      } else {
        result.failed++
        result.errors.push(`Failed for token: ${token.slice(0, 20)}...`)
      }
    }

    return new Response(JSON.stringify(result), {
      headers: { 'Content-Type': 'application/json', ...corsHeaders },
    })
  } catch (e) {
    return new Response(
      JSON.stringify({
        success: 0,
        failed: 0,
        errors: [(e as Error).message],
      } satisfies FcmResponse),
      { status: 500, headers: { 'Content-Type': 'application/json', ...corsHeaders } },
    )
  }
})
