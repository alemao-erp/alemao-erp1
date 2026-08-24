const SUPABASE_URL='https://gtwvtgynnguiizepzfpu.supabase.co';
const SUPABASE_KEY='sb_publishable_wM7la1ds3BUugE634awmHg_Tcpe4wF-';
const STORAGE_KEY='sb-gtwvtgynnguiizepzfpu-auth-token';
let loadingApp=false;

function statusMsg(text,bad=false){
  const el=document.getElementById('loginStatus');
  if(!el)return;
  el.textContent=text;
  el.style.color=bad?'#b42318':'#067647';
  el.classList.remove('hidden');
}

function readStoredSession(){
  try{return JSON.parse(localStorage.getItem(STORAGE_KEY)||'null')}catch(e){return null}
}

async function tokenIsValid(token){
  if(!token)return false;
  try{
    const r=await fetch(SUPABASE_URL+'/auth/v1/user',{headers:{apikey:SUPABASE_KEY,Authorization:'Bearer '+token}});
    return r.ok;
  }catch(e){return false}
}

async function loadFullApp(){
  if(loadingApp)return;
  loadingApp=true;
  try{
    await import('./app.js?v=20260824-2');
  }catch(e){
    loadingApp=false;
    statusMsg('Login aceito, mas o módulo principal não carregou: '+(e?.message||String(e)),true);
  }
}

window.loginPassword=async function(event){
  event.preventDefault();
  const email=document.getElementById('loginEmail')?.value.trim();
  const password=document.getElementById('loginPassword')?.value||'';
  if(!email||!password)return statusMsg('Preencha e-mail e senha.',true);
  statusMsg('Entrando...');
  try{
    const r=await fetch(SUPABASE_URL+'/auth/v1/token?grant_type=password',{
      method:'POST',
      headers:{apikey:SUPABASE_KEY,'Content-Type':'application/json'},
      body:JSON.stringify({email,password})
    });
    const d=await r.json().catch(()=>({}));
    if(!r.ok||!d.access_token){
      throw new Error(d.error_description||d.msg||d.message||('HTTP '+r.status));
    }
    const session={
      access_token:d.access_token,
      refresh_token:d.refresh_token,
      token_type:d.token_type||'bearer',
      expires_in:d.expires_in||3600,
      expires_at:d.expires_at||Math.floor(Date.now()/1000)+Number(d.expires_in||3600),
      user:d.user
    };
    localStorage.setItem(STORAGE_KEY,JSON.stringify(session));
    localStorage.setItem('erp_access_token',d.access_token);
    localStorage.setItem('erp_user_email',d.user?.email||email);
    statusMsg('Login aceito. Abrindo sistema...');
    await loadFullApp();
  }catch(err){
    statusMsg('Erro ao entrar: '+(err?.message||String(err)),true);
  }
};

window.sendMagicLink=async function(){
  const email=document.getElementById('loginEmail')?.value.trim();
  if(!email)return statusMsg('Informe o e-mail.',true);
  statusMsg('Enviando link...');
  try{
    const r=await fetch(SUPABASE_URL+'/auth/v1/otp',{
      method:'POST',
      headers:{apikey:SUPABASE_KEY,'Content-Type':'application/json'},
      body:JSON.stringify({email,create_user:false,options:{email_redirect_to:'https://alemao-erp.github.io/alemao-erp1/'}})
    });
    if(!r.ok){const d=await r.json().catch(()=>({}));throw new Error(d.msg||d.message||('HTTP '+r.status));}
    statusMsg('Link enviado para o e-mail.');
  }catch(e){statusMsg('Erro: '+(e?.message||String(e)),true)}
};

(async()=>{
  const s=readStoredSession();
  if(s?.access_token&&await tokenIsValid(s.access_token)){
    statusMsg('Sessão encontrada. Abrindo sistema...');
    await loadFullApp();
  }
})();
