const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
}

const jsonHeaders = { ...corsHeaders, 'Content-Type': 'application/json' }

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: jsonHeaders })
}

function extractErrorMessage(payload: unknown, fallback: string) {
  if (!payload || typeof payload !== 'object') return fallback
  const data = payload as Record<string, unknown>
  const value =
    data.error_description ??
    data.error ??
    data.message ??
    data.msg ??
    data.code
  return typeof value === 'string' && value.trim().length > 0
    ? value
    : fallback
}

async function requireSuperadmin(
  req: Request,
  supabaseUrl: string,
  anonKey: string,
  serviceRoleKey: string
) {
  const authHeader = req.headers.get('authorization')
  if (!authHeader) {
    return { error: jsonResponse({ error: 'Unauthorized' }, 401) }
  }

  const userRes = await fetch(`${supabaseUrl}/auth/v1/user`, {
    headers: {
      Authorization: authHeader,
      apikey: anonKey,
    },
  })

  if (!userRes.ok) {
    return { error: jsonResponse({ error: 'Sesi tidak valid' }, 401) }
  }

  const userData = await userRes.json()
  const userId = userData?.id as string | undefined
  if (!userId) {
    return { error: jsonResponse({ error: 'Sesi tidak valid' }, 401) }
  }

  const roleRes = await fetch(
    `${supabaseUrl}/rest/v1/profiles?id=eq.${userId}&select=role&limit=1`,
    {
      headers: {
        Authorization: `Bearer ${serviceRoleKey}`,
        apikey: serviceRoleKey,
      },
    }
  )

  if (!roleRes.ok) {
    return { error: jsonResponse({ error: 'Gagal memverifikasi role' }, 500) }
  }

  const roleRows = (await roleRes.json()) as Array<{ role?: string }>
  const role = (roleRows[0]?.role ?? '').toLowerCase().trim()
  if (role !== 'superadmin') {
    return {
      error: jsonResponse({ error: 'Hanya superadmin yang diizinkan' }, 403),
    }
  }

  return { userId }
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? ''

    if (!supabaseUrl || !serviceRoleKey || !anonKey) {
      return jsonResponse({ error: 'Supabase env belum lengkap' }, 500)
    }

    const guard = await requireSuperadmin(
      req,
      supabaseUrl,
      anonKey,
      serviceRoleKey
    )
    if ('error' in guard) return guard.error

    const { name, email, password } = await req.json()
    if (!name || !email || !password) {
      return jsonResponse(
        { error: 'Nama, email, dan password wajib diisi' },
        400
      )
    }

    const createUserRes = await fetch(`${supabaseUrl}/auth/v1/admin/users`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${serviceRoleKey}`,
        apikey: serviceRoleKey,
      },
      body: JSON.stringify({
        email,
        password,
        email_confirm: true,
        user_metadata: { full_name: name },
      }),
    })

    const createUserData = await createUserRes.json()
    if (!createUserRes.ok) {
      const fallbackMessage =
        createUserRes.status === 422
          ? 'Data admin tidak valid atau email sudah terdaftar'
          : 'Gagal membuat akun admin'
      return jsonResponse(
        {
          error: extractErrorMessage(createUserData, fallbackMessage),
          status: createUserRes.status,
          raw: createUserData,
        },
        createUserRes.status
      )
    }

    const createdUserId =
      (createUserData?.user as Record<string, unknown> | undefined)?.id ??
      createUserData?.id
    if (typeof createdUserId !== 'string' || createdUserId.trim() === '') {
      return jsonResponse(
        {
          error: 'Akun admin berhasil dibuat, tetapi ID user tidak ditemukan',
          raw: createUserData,
        },
        500
      )
    }

    const updateProfileRes = await fetch(
      `${supabaseUrl}/rest/v1/profiles?id=eq.${createdUserId}`,
      {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${serviceRoleKey}`,
          apikey: serviceRoleKey,
          Prefer: 'return=minimal',
        },
        body: JSON.stringify({
          full_name: name,
          email,
          role: 'admin',
          updated_at: new Date().toISOString(),
        }),
      }
    )

    if (!updateProfileRes.ok) {
      const updateError = await updateProfileRes.text()
      return jsonResponse(
        { error: `User dibuat, tapi profile gagal diperbarui: ${updateError}` },
        500
      )
    }

    return jsonResponse({ success: true, user: createUserData })
  } catch (error) {
    const message =
      error instanceof Error ? error.message : 'Terjadi kesalahan server'
    return jsonResponse({ error: message }, 500)
  }
})
