import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm';

const SUPABASE_URL='https://gtwvtgynnguiizepzfpu.supabase.co';
const SUPABASE_KEY='sb_publishable_wM7la1ds3BUugE634awmHg_Tcpe4wF-';
const sb=createClient(SUPABASE_URL,SUPABASE_KEY,{auth:{persistSession:true,autoRefreshToken:true,detectSessionInUrl:true}});
let appLoaded=false;

function statusMsg(text,bad=false){
  const el=document.getElementById('loginStatus');
  if(!el)return;
  el.textContent=text;
  el.style.color=bad?'#b42318':'#067647';
  el.classList.remove('hidden');
}

async function loadFullApp(){
  if(appLoaded)return;
  appLoaded=true;
  await import('./app.js');
}

window.loginPassword=async function(event){
  event.preventDefault();
  const email=document.getElementById('loginEmail')?.value.trim();
  const password=document.getElementById('loginPassword')?.value||'';
  if(!email||!password)return statusMsg('Preencha e-mail e senha.',true);
  statusMsg('Entrando...');
  try{
    await sb.auth.signOut({scope:'local'}).catch(()=>{});
    const r=await fetch(SUPABASE_URL+'/auth/v1/token?grant_type=password',{
      method:'POST',
      headers:{apikey:SUPABASE_KEY,'Content-Type':'application/json'},
      body:JSON.stringify({email,password})
    });
    const d=await r.json().catch(()=>({}));
    if(!r.ok||!d.access_token||!d.refresh_token){
      throw new Error(d.error_description||d.msg||d.message||('HTTP '+r.status));
    }
    const {data,error}=await sb.auth.setSession({access_token:d.access_token,refresh_token:d.refresh_token});
    if(error||!data.session)throw new Error(error?.message||'A sessão não pôde ser criada.');
    localStorage.setItem('erp_access_token',d.access_token);
    localStorage.setItem('erp_user_email',d.user?.email||email);
    statusMsg('Login aceito. Abrindo sistema...');
    await loadFullApp();
  }catch(err){
    appLoaded=false;
    statusMsg('Erro ao entrar: '+(err?.message||String(err)),true);
  }
};

window.sendMagicLink=async function(){
  const email=document.getElementById('loginEmail')?.value.trim();
  if(!email)return statusMsg('Informe o e-mail.',true);
  const {error}=await sb.auth.signInWithOtp({email,options:{emailRedirectTo:'https://alemao-erp.github.io/alemao-erp1/',shouldCreateUser:false}});
  statusMsg(error?'Erro: '+error.message:'Link enviado para o e-mail.',!!error);
};

try{
  const {data:{session},error}=await sb.auth.getSession();
  if(!error&&session){
    await loadFullApp();
  }
}catch(e){
  statusMsg('Informe e-mail e senha para entrar.',false);
}
