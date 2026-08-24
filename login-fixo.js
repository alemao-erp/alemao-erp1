const U='https://gtwvtgynnguiizepzfpu.supabase.co';
const K='sb_publishable_wM7la1ds3BUugE634awmHg_Tcpe4wF-';

window.loginPassword=async function(event){
  event.preventDefault();
  const email=document.getElementById('loginEmail')?.value.trim();
  const password=document.getElementById('loginPassword')?.value||'';
  const status=document.getElementById('loginStatus');
  const show=(t,bad=false)=>{if(status){status.textContent=t;status.style.color=bad?'#b42318':'#067647';status.classList.remove('hidden')}};
  if(!email||!password)return show('Preencha e-mail e senha.',true);
  show('Entrando...');
  try{
    const r=await fetch(U+'/auth/v1/token?grant_type=password',{method:'POST',headers:{apikey:K,'Content-Type':'application/json'},body:JSON.stringify({email,password})});
    const d=await r.json().catch(()=>({}));
    if(!r.ok||!d.access_token)throw new Error(d.error_description||d.msg||d.message||('HTTP '+r.status));
    const session={access_token:d.access_token,refresh_token:d.refresh_token,token_type:d.token_type||'bearer',expires_in:d.expires_in,expires_at:d.expires_at||Math.floor(Date.now()/1000)+Number(d.expires_in||3600),user:d.user};
    localStorage.setItem('sb-gtwvtgynnguiizepzfpu-auth-token',JSON.stringify(session));
    localStorage.setItem('erp_access_token',d.access_token);
    localStorage.setItem('erp_user_email',d.user?.email||email);
    show('Login aceito. Abrindo sistema...');
    setTimeout(()=>location.reload(),300);
  }catch(e){show('Erro ao entrar: '+(e?.message||String(e)),true)}
};