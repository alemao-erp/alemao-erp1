import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm';
const sb=createClient('https://ldgitzsdefhkbkoohkcy.supabase.co','sb_publishable_WoVp2qlQ90hTItJaxmhwEg_PFSnwvIp',{auth:{persistSession:true,autoRefreshToken:true,detectSessionInUrl:true}});
const $=id=>document.getElementById(id);
const money=v=>Number(v||0).toLocaleString('pt-BR',{style:'currency',currency:'BRL'});
const fmt=d=>d?new Date(d+'T12:00:00').toLocaleDateString('pt-BR'):'-';
const esc=v=>String(v??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
let banks=[],transactions=[];
function status(t,e=false){const el=$('status');if(!el)return;el.textContent=t;el.style.color=e?'var(--bad)':'var(--ok)';el.classList.remove('hidden');setTimeout(()=>el.classList.add('hidden'),6000)}
function ensureBankUI(){
  const nav=document.querySelector('.nav');
  if(nav&&!nav.querySelector('[data-banks-safe]')){const b=document.createElement('button');b.dataset.banksSafe='1';b.textContent='🏦 Bancos';b.onclick=showBanks;nav.appendChild(b)}
  if($('bancos'))return;
  const sec=document.createElement('section');sec.id='bancos';sec.className='page hidden';sec.innerHTML=`<div class="panel"><h3>🏦 Contas bancárias</h3><div id="bankSummary"></div></div><div class="panel"><h3>Contas cadastradas</h3><div id="bankTable"></div></div><div class="panel"><h3>📒 Extrato automático</h3><div id="bankStatement"></div></div>`;
  document.querySelector('.main')?.appendChild(sec);
}
async function loadBanks(){
  ensureBankUI();
  const [b,t]=await Promise.all([
    sb.from('personal_bank_accounts').select('*').order('bank_name').order('account_name'),
    sb.from('personal_bank_transactions').select('*').order('transaction_date',{ascending:false}).order('created_at',{ascending:false})
  ]);
  const er=b.error||t.error;if(er){status('Erro ao carregar bancos: '+er.message,true);return;}
  banks=b.data||[];transactions=t.data||[];renderBanks();
}
function renderBanks(){
  if(!$('bankSummary'))return;
  const active=banks.filter(x=>x.active!==false),total=active.reduce((a,x)=>a+Number(x.current_balance||0),0);
  $('bankSummary').innerHTML=`<div class="cards"><div class="card"><div class="label">Saldo total atual</div><div class="value">${money(total)}</div></div><div class="card"><div class="label">Contas ativas</div><div class="value">${active.length}</div></div></div>`;
  $('bankTable').innerHTML=banks.length?`<div class="tablewrap"><table class="table"><thead><tr><th>Banco</th><th>Conta</th><th>Responsável</th><th>Tipo</th><th>Saldo atual</th></tr></thead><tbody>${banks.map(b=>`<tr><td>${esc(b.bank_name)}</td><td>${esc(b.account_name)}</td><td>${esc(b.owner)}</td><td>${esc(b.account_type||'-')}</td><td><b>${money(b.current_balance)}</b></td></tr>`).join('')}</tbody></table></div>`:'<div class="muted">Nenhuma conta cadastrada.</div>';
  $('bankStatement').innerHTML=transactions.length?`<div class="tablewrap"><table class="table"><thead><tr><th>Data</th><th>Conta</th><th>Descrição</th><th>Entrada</th><th>Saída</th><th>Origem</th></tr></thead><tbody>${transactions.map(t=>{const b=banks.find(x=>x.id===t.bank_account_id),inn=t.transaction_type==='inflow';return `<tr><td>${fmt(t.transaction_date)}</td><td>${esc(b?.bank_name||'-')} — ${esc(b?.account_name||'')}</td><td>${esc(t.description||'-')}</td><td class="ok">${inn?money(t.amount):'-'}</td><td class="badtext">${inn?'-':money(t.amount)}</td><td>${esc(t.source_type||'-')}</td></tr>`}).join('')}</tbody></table></div>`:'<div class="muted">Nenhuma movimentação registrada.</div>';
}
function showBanks(){document.querySelectorAll('.page').forEach(x=>x.classList.add('hidden'));$('bancos')?.classList.remove('hidden');if($('title'))$('title').textContent='Bancos';loadBanks()}
async function boot(){ensureBankUI();const{data:{session}}=await sb.auth.getSession();if(session)loadBanks()}
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',boot,{once:true});else boot();