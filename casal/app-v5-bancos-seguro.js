import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm';

const sb=createClient('https://ldgitzsdefhkbkoohkcy.supabase.co','sb_publishable_WoVp2qlQ90hTItJaxmhwEg_PFSnwvIp',{auth:{persistSession:true,autoRefreshToken:true,detectSessionInUrl:true}});
const $=id=>document.getElementById(id);
const money=v=>Number(v||0).toLocaleString('pt-BR',{style:'currency',currency:'BRL'});
const fmt=d=>d?new Date(d+'T12:00:00').toLocaleDateString('pt-BR'):'-';
const today=()=>new Date().toISOString().slice(0,10);
const esc=v=>String(v??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
let banks=[],transactions=[],transfers=[];

function status(t,e=false){const el=$('status');if(!el)return;el.textContent=t;el.style.color=e?'var(--bad)':'var(--ok)';el.classList.remove('hidden');setTimeout(()=>el.classList.add('hidden'),6000)}

function ensureUI(){
  const nav=document.querySelector('.nav');
  if(nav&&!nav.querySelector('[data-banks-v5]')){const b=document.createElement('button');b.dataset.banksV5='1';b.textContent='🏦 Bancos';b.onclick=showBanks;nav.appendChild(b)}
  if($('bancos'))return;
  const sec=document.createElement('section');sec.id='bancos';sec.className='page hidden';sec.innerHTML=`
  <div class="split">
    <div class="panel"><h3>Nova conta bancária</h3><form id="bankForm" class="grid">
      <div class="field"><label>Banco</label><input id="bankName" required></div>
      <div class="field"><label>Nome da conta</label><input id="bankAccountName" required placeholder="Ex.: Conta Igor"></div>
      <div class="field"><label>Responsável</label><select id="bankOwner"><option>Igor</option><option>Larissa</option><option>Casal</option></select></div>
      <div class="field"><label>Tipo</label><select id="bankType"><option>Conta corrente</option><option>Conta digital</option><option>Poupança</option><option>Carteira</option><option>Investimento</option></select></div>
      <div class="field"><label>Agência</label><input id="bankAgency"></div>
      <div class="field"><label>Conta</label><input id="bankNumber"></div>
      <div class="field"><label>Saldo inicial</label><input id="bankBalance" type="number" step=".01" value="0"></div>
      <div><button class="btn">Salvar conta</button></div>
    </form></div>
    <div class="panel"><h3>Resumo bancário</h3><div id="bankSummary"></div></div>
  </div>
  <div class="panel"><h3>Contas cadastradas</h3><div id="bankTable"></div></div>
  <div class="panel"><h3>🔄 Transferência entre contas</h3><form id="transferForm" class="grid">
    <div class="field"><label>Conta de origem</label><select id="transferFrom" required></select></div>
    <div class="field"><label>Conta de destino</label><select id="transferTo" required></select></div>
    <div class="field"><label>Valor</label><input id="transferAmount" type="number" step=".01" min=".01" required></div>
    <div class="field"><label>Data</label><input id="transferDate" type="date" required></div>
    <div class="field"><label>Descrição</label><input id="transferDesc" placeholder="Opcional"></div>
    <div><button class="btn">Transferir</button></div>
  </form><div id="transferTable" style="margin-top:14px"></div></div>
  <div class="panel"><h3>📒 Extrato automático</h3><div id="bankStatement"></div></div>`;
  document.querySelector('.main')?.appendChild(sec);
  $('bankForm')?.addEventListener('submit',saveBank);
  $('transferForm')?.addEventListener('submit',saveTransfer);
  if($('transferDate'))$('transferDate').value=today();
}

function optionList(){return banks.filter(b=>b.active!==false).map(b=>`<option value="${b.id}">${esc(b.bank_name)} — ${esc(b.account_name)} (${money(b.current_balance)})</option>`).join('')}

async function loadBanks(){
  try{
    const [b,t,tr]=await Promise.all([
      sb.from('personal_bank_accounts').select('*').order('bank_name').order('account_name'),
      sb.from('personal_bank_transactions').select('*').order('transaction_date',{ascending:false}).order('created_at',{ascending:false}),
      sb.from('personal_bank_transfers').select('*').order('transfer_date',{ascending:false}).order('created_at',{ascending:false})
    ]);
    if(b.error)throw b.error;
    banks=b.data||[];
    transactions=t.error?[]:(t.data||[]);
    transfers=tr.error?[]:(tr.data||[]);
    render();
  }catch(err){status('Erro na área Bancos: '+err.message,true)}
}

function render(){
  const active=banks.filter(b=>b.active!==false),total=active.reduce((a,b)=>a+Number(b.current_balance||0),0),opening=active.reduce((a,b)=>a+Number(b.opening_balance??0),0);
  if($('bankSummary'))$('bankSummary').innerHTML=`<div class="cards"><div class="card"><div class="label">Saldo atual</div><div class="value">${money(total)}</div></div><div class="card"><div class="label">Saldo inicial</div><div class="value">${money(opening)}</div></div><div class="card"><div class="label">Contas ativas</div><div class="value">${active.length}</div></div></div>`;
  if($('bankTable'))$('bankTable').innerHTML=banks.length?`<div class="tablewrap"><table class="table"><thead><tr><th>Banco</th><th>Conta</th><th>Responsável</th><th>Tipo</th><th>Saldo inicial</th><th>Saldo atual</th><th></th></tr></thead><tbody>${banks.map(b=>`<tr><td>${esc(b.bank_name)}</td><td>${esc(b.account_name)}</td><td>${esc(b.owner)}</td><td>${esc(b.account_type||'-')}</td><td>${money(b.opening_balance||0)}</td><td><b>${money(b.current_balance||0)}</b></td><td><button class="btn sm" onclick="window.editBankV5('${b.id}')">Editar</button></td></tr>`).join('')}</tbody></table></div>`:'<div class="muted">Nenhuma conta cadastrada.</div>';
  const opts='<option value="">Selecione</option>'+optionList();if($('transferFrom'))$('transferFrom').innerHTML=opts;if($('transferTo'))$('transferTo').innerHTML=opts;
  if($('transferTable'))$('transferTable').innerHTML=transfers.length?`<div class="tablewrap"><table class="table"><thead><tr><th>Data</th><th>Origem</th><th>Destino</th><th>Valor</th><th>Descrição</th></tr></thead><tbody>${transfers.map(x=>{const f=banks.find(b=>b.id===x.from_account_id),to=banks.find(b=>b.id===x.to_account_id);return `<tr><td>${fmt(x.transfer_date)}</td><td>${esc(f?.bank_name||'-')} — ${esc(f?.account_name||'')}</td><td>${esc(to?.bank_name||'-')} — ${esc(to?.account_name||'')}</td><td>${money(x.amount)}</td><td>${esc(x.description||'-')}</td></tr>`}).join('')}</tbody></table></div>`:'<div class="muted">Nenhuma transferência registrada.</div>';
  if($('bankStatement'))$('bankStatement').innerHTML=transactions.length?`<div class="tablewrap"><table class="table"><thead><tr><th>Data</th><th>Conta</th><th>Descrição</th><th>Entrada</th><th>Saída</th><th>Origem</th></tr></thead><tbody>${transactions.map(x=>{const b=banks.find(y=>y.id===x.bank_account_id),inn=x.transaction_type==='inflow';return `<tr><td>${fmt(x.transaction_date)}</td><td>${esc(b?.bank_name||'-')} — ${esc(b?.account_name||'')}</td><td>${esc(x.description||'-')}</td><td class="ok">${inn?money(x.amount):'-'}</td><td class="badtext">${inn?'-':money(x.amount)}</td><td>${esc(x.source_type||'-')}</td></tr>`}).join('')}</tbody></table></div>`:'<div class="muted">Nenhuma movimentação registrada.</div>';
}

async function saveBank(e){e.preventDefault();try{const initial=Number($('bankBalance').value||0);const{error}=await sb.from('personal_bank_accounts').insert({bank_name:$('bankName').value.trim(),account_name:$('bankAccountName').value.trim(),owner:$('bankOwner').value,account_type:$('bankType').value,agency:$('bankAgency').value.trim()||null,account_number:$('bankNumber').value.trim()||null,opening_balance:initial,current_balance:initial});if(error)throw error;e.target.reset();$('bankBalance').value=0;status('Conta bancária cadastrada.');await loadBanks()}catch(err){status(err.message,true)}}

async function saveTransfer(e){e.preventDefault();try{const from=$('transferFrom').value,to=$('transferTo').value;if(!from||!to)throw new Error('Selecione as duas contas.');if(from===to)throw new Error('Origem e destino precisam ser diferentes.');const{error}=await sb.from('personal_bank_transfers').insert({from_account_id:from,to_account_id:to,amount:Number($('transferAmount').value||0),transfer_date:$('transferDate').value||today(),description:$('transferDesc').value.trim()||null});if(error)throw error;e.target.reset();$('transferDate').value=today();status('Transferência registrada.');await loadBanks()}catch(err){status(err.message,true)}}

window.editBankV5=async id=>{try{const b=banks.find(x=>x.id===id);if(!b)return;const name=prompt('Banco',b.bank_name);if(name===null)return;const account=prompt('Nome da conta',b.account_name);if(account===null)return;const owner=prompt('Responsável: Igor, Larissa ou Casal',b.owner||'Casal');if(owner===null)return;const{error}=await sb.from('personal_bank_accounts').update({bank_name:name.trim(),account_name:account.trim(),owner:['Igor','Larissa','Casal'].includes(owner)?owner:b.owner}).eq('id',id);if(error)throw error;status('Conta atualizada.');await loadBanks()}catch(err){status(err.message,true)}};

function showBanks(){document.querySelectorAll('.page').forEach(x=>x.classList.add('hidden'));$('bancos')?.classList.remove('hidden');if($('title'))$('title').textContent='Bancos';loadBanks()}

async function boot(){try{ensureUI();const{data:{session}}=await sb.auth.getSession();if(session)await loadBanks();sb.auth.onAuthStateChange((_event,session)=>{if(session)loadBanks().catch(()=>{})})}catch(err){console.error('Módulo Bancos isolado:',err)}}

if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',boot,{once:true});else boot();

// Módulo separado para edição de receitas/despesas/dívidas e previsão salarial.
import('./app-v6-receitas-despesas-salario.js').catch(err=>console.error('Falha isolada no módulo financeiro V6:',err));