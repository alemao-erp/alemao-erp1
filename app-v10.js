// Loader do ERP completo com correção do login.
// Preserva todos os dados do Supabase e usa o app completo existente.
import './app.js';

const SUPABASE_URL = 'https://gtwvtgynnguiizepzfpu.supabase.co';
const SUPABASE_KEY = 'sb_publishable_wM7la1ds3BUugE634awmHg_Tcpe4wF-';
const STORAGE_KEY = 'sb-gtwvtgynnguiizepzfpu-auth-token';

// O app principal tinha um bloqueio durante o evento de autenticação.
// Este login autentica diretamente, grava a sessão no formato do supabase-js
// e recarrega o ERP. No reload, o app principal encontra a sessão e abre o painel.
window.loginPassword = async function (event) {
  event.preventDefault();
  const email = document.getElementById('loginEmail')?.value?.trim();
  const password = document.getElementById('loginPassword')?.value || '';
  const status = document.getElementById('loginStatus');

  if (status) {
    status.textContent = 'Entrando...';
    status.classList.remove('hidden');
  }

  try {
    const response = await fetch(`${SUPABASE_URL}/auth/v1/token?grant_type=password`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'apikey': SUPABASE_KEY
      },
      body: JSON.stringify({ email, password })
    });

    const data = await response.json();
    if (!response.ok || !data.access_token) {
      throw new Error(data.msg || data.message || data.error_description || 'Não foi possível entrar.');
    }

    const session = {
      access_token: data.access_token,
      refresh_token: data.refresh_token,
      token_type: data.token_type || 'bearer',
      expires_in: data.expires_in,
      expires_at: data.expires_at || Math.floor(Date.now() / 1000) + Number(data.expires_in || 3600),
      user: data.user
    };

    localStorage.setItem(STORAGE_KEY, JSON.stringify(session));
    location.replace('./?login=ok');
  } catch (err) {
    if (status) {
      status.textContent = 'Erro ao entrar: ' + (err?.message || String(err));
      status.classList.remove('hidden');
    }
  }
};
