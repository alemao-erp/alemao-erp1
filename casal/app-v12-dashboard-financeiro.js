import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm';
const sb=createClient('https://ldgitzsdefhkbkoohkcy.supabase.co','sb_publishable_WoVp2qlQ90hTItJaxmhwEg_PFSnwvIp',{auth:{persistSession:true,autoRefreshToken:true,detectSessionInUrl:true}});
const $=id=>document.getElementById(id);
const n=v=>Number(v||0);
const money=v=>n(v).toLocaleString('pt-BR',{style:'currency',currency:'BRL'});
const esc=v=>String(v??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const nowMonth=()=>{const d=new Date();return `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}`};
const monthOf=d=>String(d||'').slice(0,7);
const monthDate=m=>m+'-01';
const monthLabel=m=>new Date(m+'-01T12:00:00').toLocaleDateString('pt-BR',{month:'long',year:'numeric'});
let data={income:[],expenses:[],debts:[],cards:[],installments:[],payments:[]};

function ensure(){
  const dash=$('dashboard');
  if(!dash||$('dashboardFinanceiroV12'))return !!$('dashboardFinanceiroV12');
  const box=document.createElement('div');
  box.id='dashboardFinanceiroV12';
  box.innerHTML=`
  <div class="panel">
    <div class="row" style="justify-content:space-between;align-items:center">
      <div><h3 style="margin:0">📌 Visão financeira do mês</h3><div class="muted" style="margin-top:4px">Renda, despesas, cartões e saldo previsto no mesmo lugar.</div></div>
      <div class="field" style="min-width:170px"><label>Mês analisado</label><input id="dashMonthV12" type="month"></div>
    </div>
    <div id="dashCardsV12" class="cards" style="margin-top:14px"></div>
  </div>
  <div class="split">
    <div class="panel"><h3>👥 Igor x Larissa x Casa</h3><div id="dashPeopleV12"></div></div>
    <div class="panel"><h3>⏰ Contas a vencer</h3><div id="dashDueV12"></div></div>
  </div>
  <div class="panel"><h3>💳 Cartões — próximos 6 meses já comprometidos</h3><div id="dashFutureCardsV12"></div></div>`;
  const firstPanel=dash.querySelector('.split');
  if(firstPanel)dash.insertBefore(box,firstPanel);else dash.appendChild(box);
  $('dashMonthV12').value=nowMonth();
  $('dashMonthV12').addEventListener('change',render);
  return true;
}

async function load(){
  if(!ensure())return;
  const rs=await Promise.all([
    sb.from('personal_income').select('*'),
    sb.from('personal_expenses').select('*'),
    sb.from('personal_debts').select('*'),
    sb.from('personal_cards').select('*'),
    sb.from('personal_card_installments').select('*'),
    sb.from('personal_card_invoice_payments').select('*')
  ]);
  if(rs.some(r=>r.error))return;
  [data.income,data.expenses,data.debts,data.cards,data.installments,data.payments]=rs.map(r=>r.data||[]);
  render();
}

function personKey(v){const s=String(v||'Casal').toLowerCase();if(s.includes('igor'))return'Igor';if(s.includes('larissa'))return'Larissa';return'Casa'}
function recurringPlusMonth(rows,dateField,month){return rows.filter(x=>x.recurring||monthOf(x[dateField])===month)}
function sum(rows,field='amount'){return rows.reduce((a,x)=>a+n(x[field]),0)}

function render(){
  if(!$('dashCardsV12'))return;
  const month=$('dashMonthV12')?.value||nowMonth(),invoice=monthDate(month);
  const incomeRows=recurringPlusMonth(data.income,'income_date',month);
  const expenseRows=recurringPlusMonth(data.expenses,'expense_date',month);
  const income=sum(incomeRows);
  const expenses=sum(expenseRows);
  const debtRows=data.debts.filter(x=>x.active!==false);
  const debt=sum(debtRows,'installment_amount');
  const cardRows=data.installments.filter(x=>x.invoice_month===invoice);
  const cardTotal=sum(cardRows);
  const cardPaid=data.payments.filter(x=>x.invoice_month===invoice).reduce((a,x)=>a+n(x.amount),0);
  const cardOpen=Math.max(0,cardTotal-cardPaid);
  const planned=expenses+debt+cardTotal;
  const balance=income-planned;
  const commit=income?planned/income*100:0;
  const unpaidExpenses=data.expenses.filter(x=>!x.paid&&monthOf(x.due_date)===month);
  const unpaid=sum(unpaidExpenses);

  $('dashCardsV12').innerHTML=`
    <div class="card"><div class="label">Renda prevista · ${esc(monthLabel(month))}</div><div class="value">${money(income)}</div></div>
    <div class="card"><div class="label">Despesas cadastradas</div><div class="value">${money(expenses)}</div></div>
    <div class="card"><div class="label">Faturas dos cartões</div><div class="value">${money(cardTotal)}</div><div class="muted">Em aberto: ${money(cardOpen)}</div></div>
    <div class="card"><div class="label">Parcelas de dívidas</div><div class="value">${money(debt)}</div></div>
    <div class="card"><div class="label">Contas não pagas no mês</div><div class="value">${money(unpaid)}</div></div>
    <div class="card"><div class="label">Saldo previsto após compromissos</div><div class="value ${balance>=0?'ok':'badtext'}">${money(balance)}</div><div class="muted">Comprometimento: ${commit.toFixed(1)}%</div></div>`;

  const people=['Igor','Larissa','Casa'].map(person=>{
    const inc=sum(incomeRows.filter(x=>personKey(x.person)===person));
    const exp=sum(expenseRows.filter(x=>personKey(x.person)===person));
    const debts=sum(debtRows.filter(x=>personKey(x.owner)===person),'installment_amount');
    const ids=new Set(data.cards.filter(c=>personKey(c.owner)===person).map(c=>c.id));
    const cards=sum(cardRows.filter(x=>ids.has(x.card_id)));
    return {person,inc,exp,debts,cards,balance:inc-exp-debts-cards};
  });
  $('dashPeopleV12').innerHTML=`<div class="tablewrap"><table class="table"><thead><tr><th></th><th>Renda</th><th>Despesas</th><th>Cartões</th><th>Dívidas</th><th>Saldo</th></tr></thead><tbody>${people.map(x=>`<tr><td><b>${x.person}</b></td><td>${money(x.inc)}</td><td>${money(x.exp)}</td><td>${money(x.cards)}</td><td>${money(x.debts)}</td><td class="${x.balance>=0?'ok':'badtext'}">${money(x.balance)}</td></tr>`).join('')}</tbody></table></div>`;

  const due=unpaidExpenses.slice().sort((a,b)=>String(a.due_date).localeCompare(String(b.due_date))).slice(0,10);
  const cardDues=data.cards.map(c=>{const rows=cardRows.filter(x=>x.card_id===c.id),total=sum(rows);if(!rows.length||total===0)return null;const paid=data.payments.filter(p=>p.card_id===c.id&&p.invoice_month===invoice).reduce((a,x)=>a+n(x.amount),0);const open=Math.max(0,total-paid);const dueDate=rows.map(x=>x.due_date).filter(Boolean).sort()[0];return {description:`Fatura ${c.name}`,amount:open,due_date:dueDate};}).filter(x=>x&&x.amount>0);
  const allDue=[...due.map(x=>({description:x.description,amount:n(x.amount),due_date:x.due_date})),...cardDues].sort((a,b)=>String(a.due_date).localeCompare(String(b.due_date))).slice(0,12);
  $('dashDueV12').innerHTML=allDue.length?allDue.map(x=>`<div style="padding:8px 0;border-bottom:1px solid var(--line)"><b>${esc(x.description)}</b><br><span>${money(x.amount)}</span> <span class="muted">· ${x.due_date?new Date(x.due_date+'T12:00:00').toLocaleDateString('pt-BR'):'sem vencimento'}</span></div>`).join(''):'<div class="ok">Nenhuma conta em aberto neste mês.</div>';

  const base=new Date(month+'-01T12:00:00'),months=[];
  for(let k=0;k<6;k++){const d=new Date(base.getFullYear(),base.getMonth()+k,1),key=`${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}`,inv=key+'-01',total=sum(data.installments.filter(x=>x.invoice_month===inv));months.push({key,total});}
  const max=Math.max(...months.map(x=>Math.abs(x.total)),1);
  $('dashFutureCardsV12').innerHTML=months.map(x=>`<div style="margin:10px 0"><div class="row" style="justify-content:space-between"><b>${esc(monthLabel(x.key))}</b><b>${money(x.total)}</b></div><div class="bar" style="margin-top:5px"><div class="fill" style="width:${Math.min(100,Math.abs(x.total)/max*100)}%"></div></div></div>`).join('');
}

function watch(){
  document.addEventListener('click',e=>{const b=e.target?.closest?.('button');if(b&&String(b.textContent||'').includes('Dashboard'))setTimeout(load,120)});
  document.addEventListener('change',e=>{if(['invoiceMonth','paymentMonth'].includes(e.target?.id))setTimeout(load,150)});
  new MutationObserver(()=>{if($('dashboard')&&!$('dashboardFinanceiroV12'))load()}).observe(document.body,{childList:true,subtree:true});
}
async function boot(){watch();const{data:{session}}=await sb.auth.getSession();if(session)load();sb.auth.onAuthStateChange((_e,s)=>{if(s)setTimeout(load,100)})}
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',boot);else boot();