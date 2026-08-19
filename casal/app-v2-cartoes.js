import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm';

const sb=createClient('https://ldgitzsdefhkbkoohkcy.supabase.co','sb_publishable_WoVp2qlQ90hTItJaxmhwEg_PFSnwvIp',{auth:{persistSession:true,autoRefreshToken:true,detectSessionInUrl:true}});
const $=id=>document.getElementById(id);
const money=v=>Number(v||0).toLocaleString('pt-BR',{style:'currency',currency:'BRL'});
const today=()=>new Date().toISOString().slice(0,10);
const esc=v=>String(v??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
let cards=[],purchases=[],installments=[],invoicePayments=[];
let editingCardId=null;

function addMonths(base,n){const d=new Date(base+'T12:00:00');const day=d.getDate();d.setDate(1);d.setMonth(d.getMonth()+n);const last=new Date(d.getFullYear(),d.getMonth()+1,0).getDate();d.setDate(Math.min(day,last));return d.toISOString().slice(0,10)}
function invoiceForPurchase(purchaseDate,card){const d=new Date(purchaseDate+'T12:00:00');const closing=Number(card.closing_day||31);if(d.getDate()>closing)d.setMonth(d.getMonth()+1);d.setDate(1);return d.toISOString().slice(0,10)}
function dueForInvoice(invoiceMonth,card){const d=new Date(invoiceMonth+'T12:00:00');const due=Number(card.due_day||10);const last=new Date(d.getFullYear(),d.getMonth()+1,0).getDate();d.setDate(Math.min(due,last));return d.toISOString().slice(0,10)}
function status(t,e=false){const el=$('status');if(!el)return;el.textContent=t;el.style.color=e?'var(--bad)':'var(--ok)';el.classList.remove('hidden');setTimeout(()=>el.classList.add('hidden'),7000)}
function fmtDate(d){return d?new Date(d+'T12:00:00').toLocaleDateString('pt-BR'):'-'}
function monthLabel(ymd){return new Date(ymd+'T12:00:00').toLocaleDateString('pt-BR',{month:'long',year:'numeric'})}

function ensureUI(){
  if(!document.querySelector('.nav button[data-cards-v2]')){
    const b=document.createElement('button');b.dataset.cardsV2='1';b.textContent='💳 Cartões';b.onclick=()=>showCards();document.querySelector('.nav')?.appendChild(b);
  }
  if($('cartoes'))return;
  const sec=document.createElement('section');sec.id='cartoes';sec.className='page hidden';sec.innerHTML=`
  <div class="split">
    <div class="panel"><h3 id="cardFormTitle">Novo cartão</h3><form id="cardForm" class="grid">
      <div class="field"><label>Nome do cartão</label><input id="cardName" required placeholder="Ex.: Nubank Igor"></div>
      <div class="field"><label>Responsável</label><select id="cardOwner"><option>Igor</option><option>Larissa</option><option>Casal</option></select></div>
      <div class="field"><label>Dia de fechamento</label><input id="cardClosing" type="number" min="1" max="31"></div>
      <div class="field"><label>Dia de vencimento</label><input id="cardDue" type="number" min="1" max="31"></div>
      <div class="field"><label>Limite</label><input id="cardLimit" type="number" step=".01"></div>
      <div class="row"><button class="btn" id="cardSaveBtn">Salvar cartão</button><button type="button" class="btn alt hidden" id="cardCancelBtn">Cancelar edição</button></div>
    </form></div>
    <div class="panel"><h3>Cartões cadastrados</h3><div id="cardsList"></div></div>
  </div>
  <div class="panel"><h3>Resumo das próximas faturas</h3><div id="futureBills"></div></div>
  <div class="panel"><h3>Adicionar compra na fatura</h3><form id="purchaseForm" class="grid">
    <div class="field"><label>Cartão</label><select id="purchaseCard" required></select></div>
    <div class="field"><label>Compra</label><input id="purchaseDesc" required placeholder="Ex.: Supermercado"></div>
    <div class="field"><label>Categoria</label><input id="purchaseCat" placeholder="Mercado, Casa, Saúde..."></div>
    <div class="field"><label>Data da compra</label><input id="purchaseDate" type="date" required></div>
    <div class="field"><label>Valor total da compra</label><input id="purchaseAmount" type="number" step=".01" min="0" required></div>
    <div class="field"><label>Parcelas</label><input id="purchaseInstallments" type="number" min="1" max="120" value="1" required></div>
    <div><button class="btn">Adicionar compra</button></div>
  </form></div>
  <div class="panel"><h3>Faturas por cartão</h3><div class="row" style="margin-bottom:12px"><div class="field"><label>Cartão</label><select id="invoiceCard"></select></div><div class="field"><label>Mês</label><input id="invoiceMonth" type="month"></div><button class="btn alt" id="invoiceRefresh">Atualizar</button></div><div id="invoiceTable"></div></div>
  <div class="panel"><h3>Registrar pagamento da fatura</h3><form id="invoicePaymentForm" class="grid">
    <div class="field"><label>Cartão</label><select id="paymentCard" required></select></div>
    <div class="field"><label>Fatura do mês</label><input id="paymentMonth" type="month" required></div>
    <div class="field"><label>Valor pago</label><input id="paymentAmount" type="number" step=".01" min="0" required></div>
    <div class="field"><label>Dia em que foi pago</label><input id="paymentDate" type="date" required></div>
    <div class="field"><label>Comprovante</label><input id="paymentReceipt" type="file" accept="image/*,.pdf"></div>
    <div class="field"><label>Observação</label><input id="paymentNotes" placeholder="Opcional"></div>
    <div><button class="btn">Salvar pagamento</button></div>
  </form><div id="paymentsTable" style="margin-top:14px"></div></div>
  <div class="panel"><h3>Compras cadastradas</h3><div id="purchaseTable"></div></div>`;
  document.querySelector('.main')?.appendChild(sec);
  $('purchaseDate').value=today();
  const d=new Date();$('invoiceMonth').value=d.toISOString().slice(0,7);$('paymentMonth').value=d.toISOString().slice(0,7);$('paymentDate').value=today();
  $('cardForm').addEventListener('submit',saveCard);
  $('cardCancelBtn').addEventListener('click',resetCardForm);
  $('purchaseForm').addEventListener('submit',savePurchase);
  $('invoicePaymentForm').addEventListener('submit',saveInvoicePayment);
  $('invoiceRefresh').addEventListener('click',renderInvoice);
  $('invoiceCard').addEventListener('change',()=>{renderInvoice();syncPaymentFromInvoice()});
  $('invoiceMonth').addEventListener('change',()=>{renderInvoice();syncPaymentFromInvoice()});
}

async function loadCards(){
  const [c,p,i,pay]=await Promise.all([
    sb.from('personal_cards').select('*').order('name'),
    sb.from('personal_card_purchases').select('*').order('purchase_date',{ascending:false}),
    sb.from('personal_card_installments').select('*').order('invoice_month').order('installment_number'),
    sb.from('personal_card_invoice_payments').select('*').order('paid_at',{ascending:false})
  ]);
  const err=[c,p,i,pay].find(x=>x.error)?.error;if(err){status('Erro ao carregar cartões: '+err.message,true);return;}
  cards=c.data||[];purchases=p.data||[];installments=i.data||[];invoicePayments=pay.data||[];renderAll();
}

function renderAll(){
  const opts=cards.map(c=>`<option value="${c.id}">${esc(c.name)} (${esc(c.owner)})</option>`).join('');
  if($('purchaseCard'))$('purchaseCard').innerHTML=opts||'<option value="">Cadastre um cartão</option>';
  if($('invoiceCard'))$('invoiceCard').innerHTML='<option value="">Todos</option>'+opts;
  if($('paymentCard'))$('paymentCard').innerHTML=opts||'<option value="">Cadastre um cartão</option>';
  renderCardsList();renderFuture();renderInvoice();renderPayments();renderPurchases();
}

function renderCardsList(){
  if(!$('cardsList'))return;
  if(!cards.length){$('cardsList').innerHTML='<div class="muted">Nenhum cartão cadastrado.</div>';return;}
  $('cardsList').innerHTML=`<div class="tablewrap"><table class="table"><thead><tr><th>Cartão</th><th>Responsável</th><th>Fecha</th><th>Vence</th><th>Limite</th><th></th></tr></thead><tbody>${cards.map(c=>`<tr><td>${esc(c.name)}</td><td>${esc(c.owner)}</td><td>${c.closing_day||'-'}</td><td>${c.due_day||'-'}</td><td>${c.credit_limit?money(c.credit_limit):'-'}</td><td><button class="btn sm" onclick="window.editCard('${c.id}')">Editar</button></td></tr>`).join('')}</tbody></table></div>`;
}

function renderFuture(){
  const now=new Date();const rows=[];
  for(let m=0;m<6;m++){
    const d=new Date(now.getFullYear(),now.getMonth()+m,1);const key=d.toISOString().slice(0,10);
    const total=installments.filter(x=>x.invoice_month===key&&!x.paid).reduce((a,x)=>a+Number(x.amount||0),0);
    rows.push(`<div style="padding:8px 0;border-bottom:1px solid var(--line)"><b>${d.toLocaleDateString('pt-BR',{month:'long',year:'numeric'})}</b><span style="float:right">${money(total)}</span></div>`);
  }
  $('futureBills').innerHTML=rows.join('')||'<div class="muted">Sem parcelas futuras.</div>';
}

function renderInvoice(){
  if(!$('invoiceTable'))return;const cardId=$('invoiceCard').value;const month=$('invoiceMonth').value?$('invoiceMonth').value+'-01':new Date().toISOString().slice(0,7)+'-01';
  let rows=installments.filter(x=>x.invoice_month===month&&(cardId?x.card_id===cardId:true));
  rows=rows.sort((a,b)=>a.card_id.localeCompare(b.card_id)||a.installment_number-b.installment_number);
  if(!rows.length){$('invoiceTable').innerHTML='<div class="muted">Nenhuma parcela nesta fatura.</div>';return;}
  const total=rows.reduce((a,x)=>a+Number(x.amount||0),0);const paidInst=rows.filter(x=>x.paid).reduce((a,x)=>a+Number(x.amount||0),0);const paidInvoice=invoicePayments.filter(x=>x.invoice_month===month&&(cardId?x.card_id===cardId:true)).reduce((a,x)=>a+Number(x.amount||0),0);const paid=Math.max(paidInst,paidInvoice);
  $('invoiceTable').innerHTML=`<div class="cards" style="margin-bottom:12px"><div class="card"><div class="label">Total da fatura</div><div class="value">${money(total)}</div></div><div class="card"><div class="label">Pago</div><div class="value">${money(paid)}</div></div><div class="card"><div class="label">Em aberto</div><div class="value">${money(Math.max(0,total-paid))}</div></div></div><div class="tablewrap"><table class="table"><thead><tr><th>Cartão</th><th>Compra</th><th>Parcela</th><th>Valor</th><th>Vencimento</th><th>Status</th><th></th></tr></thead><tbody>${rows.map(x=>{const p=purchases.find(p=>p.id===x.purchase_id);const c=cards.find(c=>c.id===x.card_id);return `<tr><td>${esc(c?.name||'-')}</td><td>${esc(p?.description||'-')}</td><td>${x.installment_number}/${x.installments_total}</td><td>${money(x.amount)}</td><td>${fmtDate(x.due_date)}</td><td>${x.paid?'Pago':'Aberto'}</td><td><button class="btn sm ${x.paid?'alt':''}" onclick="window.toggleCardInstallment('${x.id}',${!x.paid})">${x.paid?'Reabrir':'Marcar pago'}</button></td></tr>`}).join('')}</tbody></table></div>`;
}

function renderPayments(){
  if(!$('paymentsTable'))return;
  if(!invoicePayments.length){$('paymentsTable').innerHTML='<div class="muted">Nenhum pagamento de fatura registrado.</div>';return;}
  $('paymentsTable').innerHTML=`<div class="tablewrap"><table class="table"><thead><tr><th>Cartão</th><th>Fatura</th><th>Valor pago</th><th>Pago em</th><th>Comprovante</th><th></th></tr></thead><tbody>${invoicePayments.map(p=>{const c=cards.find(c=>c.id===p.card_id);return `<tr><td>${esc(c?.name||'-')}</td><td>${monthLabel(p.invoice_month)}</td><td>${money(p.amount)}</td><td>${fmtDate(p.paid_at)}</td><td>${p.receipt_path?`<button class="btn alt sm" onclick="window.openReceipt('${esc(p.receipt_path)}')">Ver</button>`:'-'}</td><td><button class="btn bad sm" onclick="window.deleteInvoicePayment('${p.id}','${esc(p.receipt_path||'')}')">Excluir</button></td></tr>`}).join('')}</tbody></table></div>`;
}

function renderPurchases(){
  if(!$('purchaseTable'))return;if(!purchases.length){$('purchaseTable').innerHTML='<div class="muted">Nenhuma compra cadastrada.</div>';return;}
  $('purchaseTable').innerHTML=`<div class="tablewrap"><table class="table"><thead><tr><th>Data</th><th>Cartão</th><th>Compra</th><th>Valor</th><th>Parcelas</th><th></th></tr></thead><tbody>${purchases.map(p=>{const c=cards.find(c=>c.id===p.card_id);return `<tr><td>${fmtDate(p.purchase_date)}</td><td>${esc(c?.name||'-')}</td><td>${esc(p.description)}</td><td>${money(p.total_amount)}</td><td>${p.installments}x</td><td><button class="btn bad sm" onclick="window.deleteCardPurchase('${p.id}')">Excluir</button></td></tr>`}).join('')}</tbody></table></div>`;
}

function resetCardForm(){editingCardId=null;$('cardForm').reset();$('cardFormTitle').textContent='Novo cartão';$('cardSaveBtn').textContent='Salvar cartão';$('cardCancelBtn').classList.add('hidden')}
window.editCard=id=>{const c=cards.find(x=>x.id===id);if(!c)return;editingCardId=id;$('cardName').value=c.name||'';$('cardOwner').value=c.owner||'Casal';$('cardClosing').value=c.closing_day||'';$('cardDue').value=c.due_day||'';$('cardLimit').value=c.credit_limit||'';$('cardFormTitle').textContent='Editar cartão';$('cardSaveBtn').textContent='Salvar alterações';$('cardCancelBtn').classList.remove('hidden');$('cartoes').scrollIntoView({behavior:'smooth',block:'start'})};

async function saveCard(e){e.preventDefault();const payload={name:$('cardName').value.trim(),owner:$('cardOwner').value,closing_day:$('cardClosing').value?Number($('cardClosing').value):null,due_day:$('cardDue').value?Number($('cardDue').value):null,credit_limit:$('cardLimit').value?Number($('cardLimit').value):null};let q=editingCardId?sb.from('personal_cards').update(payload).eq('id',editingCardId):sb.from('personal_cards').insert(payload);const{error}=await q;if(error)return status(error.message,true);status(editingCardId?'Cartão atualizado.':'Cartão salvo.');resetCardForm();await loadCards()}

async function savePurchase(e){e.preventDefault();const card=cards.find(c=>c.id===$('purchaseCard').value);if(!card)return status('Escolha um cartão.',true);const desc=$('purchaseDesc').value.trim(),cat=$('purchaseCat').value.trim()||'Outros',date=$('purchaseDate').value,total=Number($('purchaseAmount').value||0),n=Number($('purchaseInstallments').value||1);const{data:p,error}=await sb.from('personal_card_purchases').insert({card_id:card.id,description:desc,category:cat,purchase_date:date,total_amount:total,installments:n}).select().single();if(error)return status(error.message,true);
  const firstMonth=invoiceForPurchase(date,card);const base=Math.floor((total/n)*100)/100;let allocated=0;const rows=[];for(let k=1;k<=n;k++){const amount=k===n?Math.round((total-allocated)*100)/100:base;allocated=Math.round((allocated+amount)*100)/100;const inv=addMonths(firstMonth,k-1).slice(0,7)+'-01';rows.push({purchase_id:p.id,card_id:card.id,installment_number:k,installments_total:n,amount,invoice_month:inv,due_date:dueForInvoice(inv,card)});}const ins=await sb.from('personal_card_installments').insert(rows);if(ins.error){await sb.from('personal_card_purchases').delete().eq('id',p.id);return status(ins.error.message,true);}e.target.reset();$('purchaseDate').value=today();$('purchaseInstallments').value=1;status(`Compra adicionada em ${n} parcela(s) e projetada nas próximas faturas.`);await loadCards()}

function syncPaymentFromInvoice(){if(!$('paymentMonth'))return;if($('invoiceMonth').value)$('paymentMonth').value=$('invoiceMonth').value;if($('invoiceCard').value)$('paymentCard').value=$('invoiceCard').value;const cardId=$('paymentCard').value,month=$('paymentMonth').value?$('paymentMonth').value+'-01':null;if(cardId&&month){const total=installments.filter(x=>x.card_id===cardId&&x.invoice_month===month).reduce((a,x)=>a+Number(x.amount||0),0);$('paymentAmount').value=total?total.toFixed(2):''}}

async function saveInvoicePayment(e){e.preventDefault();const cardId=$('paymentCard').value,month=$('paymentMonth').value+'-01',amount=Number($('paymentAmount').value||0),paidAt=$('paymentDate').value,notes=$('paymentNotes').value.trim()||null,file=$('paymentReceipt').files?.[0];if(!cardId)return status('Escolha um cartão.',true);let receiptPath=null;if(file){const safe=file.name.replace(/[^a-zA-Z0-9._-]/g,'_');receiptPath=`${cardId}/${month}/${Date.now()}_${safe}`;const up=await sb.storage.from('card-receipts').upload(receiptPath,file,{upsert:false});if(up.error)return status('Erro ao enviar comprovante: '+up.error.message,true)}const{error}=await sb.from('personal_card_invoice_payments').insert({card_id:cardId,invoice_month:month,amount,paid_at:paidAt,receipt_path:receiptPath,notes});if(error){if(receiptPath)await sb.storage.from('card-receipts').remove([receiptPath]);return status(error.message,true)}const ids=installments.filter(x=>x.card_id===cardId&&x.invoice_month===month).map(x=>x.id);if(ids.length)await sb.from('personal_card_installments').update({paid:true,paid_at:paidAt}).in('id',ids);e.target.reset();$('paymentDate').value=today();$('paymentMonth').value=new Date().toISOString().slice(0,7);status('Pagamento da fatura registrado.');await loadCards()}

window.toggleCardInstallment=async(id,paid)=>{const{error}=await sb.from('personal_card_installments').update({paid,paid_at:paid?today():null}).eq('id',id);if(error)return status(error.message,true);await loadCards()};
window.deleteCardPurchase=async id=>{if(!confirm('Excluir esta compra e todas as parcelas futuras?'))return;const{error}=await sb.from('personal_card_purchases').delete().eq('id',id);if(error)return status(error.message,true);await loadCards()};
window.openReceipt=async path=>{const{data,error}=await sb.storage.from('card-receipts').createSignedUrl(path,120);if(error)return status(error.message,true);window.open(data.signedUrl,'_blank','noopener')};
window.deleteInvoicePayment=async(id,path)=>{if(!confirm('Excluir este registro de pagamento?'))return;const{error}=await sb.from('personal_card_invoice_payments').delete().eq('id',id);if(error)return status(error.message,true);if(path)await sb.storage.from('card-receipts').remove([path]);await loadCards()};

function showCards(){document.querySelectorAll('.page').forEach(x=>x.classList.add('hidden'));$('cartoes').classList.remove('hidden');$('title').textContent='Cartões';loadCards()}

async function boot(){ensureUI();const{data:{session}}=await sb.auth.getSession();if(session)loadCards();sb.auth.onAuthStateChange((event,session)=>{if(session)loadCards()});}
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',boot);else boot();
