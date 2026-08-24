import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm';

const sb = createClient(
  'https://gtwvtgynnguiizepzfpu.supabase.co',
  'sb_publishable_wM7la1ds3BUugE634awmHg_Tcpe4wF-',
  { auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: true } }
);

const $ = id => document.getElementById(id);
const num = v => Number(v || 0);
const money = v => num(v).toLocaleString('pt-BR',{style:'currency',currency:'BRL'});
const esc = v => String(v ?? '').replace(/[&<>"']/g,m=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#039;'}[m]));
let db = { products:[], clients:[], sales:[], saleItems:[] };

function loginMsg(text, error=false){
  const el=$('loginStatus'); if(!el) return;
  el.textContent=text; el.style.color=error?'#b42318':'#067647'; el.classList.remove('hidden');
}
function appMsg(text,error=false){
  const el=$('status'); if(!el) return alert(text);
  el.textContent=text; el.style.color=error?'#b42318':'#067647'; el.classList.remove('hidden');
  setTimeout(()=>el.classList.add('hidden'),7000);
}

async function loginPassword(e){
  e.preventDefault();
  const email=$('loginEmail')?.value?.trim();
  const password=$('loginPassword')?.value || '';
  loginMsg('Entrando...');
  try{
    const {data,error}=await sb.auth.signInWithPassword({email,password});
    if(error) throw error;
    if(!data?.session) throw new Error('Login não retornou uma sessão válida.');
    await openApp(data.session);
  }catch(err){
    loginMsg('Não foi possível entrar: '+(err?.message||err),true);
  }
}

async function sendMagicLink(){
  const email=$('loginEmail')?.value?.trim();
  if(!email) return loginMsg('Digite seu e-mail primeiro.',true);
  const {error}=await sb.auth.signInWithOtp({email,options:{emailRedirectTo:'https://alemao-erp.github.io/alemao-erp1/',shouldCreateUser:false}});
  loginMsg(error?'Erro: '+error.message:'Link enviado para seu e-mail.',!!error);
}

async function logout(){ await sb.auth.signOut(); location.reload(); }

async function openApp(session){
  $('loginView')?.classList.add('hidden');
  $('appView')?.classList.remove('hidden');
  if($('userEmail')) $('userEmail').textContent=session.user?.email||'';
  if($('today')) $('today').textContent=new Date().toLocaleDateString('pt-BR');
  await loadCore();
  show('dashboard');
}

async function loadCore(){
  const [p,c,s,i]=await Promise.all([
    sb.from('products').select('*').order('name'),
    sb.from('clients').select('*').order('name'),
    sb.from('sales').select('*').order('sold_at',{ascending:false}),
    sb.from('sale_items').select('*')
  ]);
  const err=[p,c,s,i].find(x=>x.error)?.error;
  if(err) throw err;
  db.products=p.data||[]; db.clients=c.data||[]; db.sales=s.data||[]; db.saleItems=i.data||[];
  refreshSelects(); renderCore();
}

function show(id){
  document.querySelectorAll('.page').forEach(x=>x.classList.add('hidden'));
  $(id)?.classList.remove('hidden');
  if($('title')) $('title').textContent={dashboard:'Dashboard',vendas:'Vendas',produtos:'Produtos',estoque:'Estoque',clientes:'Clientes',fornecedores:'Fornecedores',compras:'Compras',caixa:'Caixa',contas:'Contas',banco:'Banco',relatorios:'Relatórios'}[id]||id;
  if(id==='vendas' && !$('saleLines')?.children.length) addSaleLine();
}

function refreshSelects(){
  if($('saleClient')) $('saleClient').innerHTML='<option value="">Cliente balcão</option>'+db.clients.map(c=>`<option value="${c.id}">${esc(c.name)}</option>`).join('');
  document.querySelectorAll('.sale-prod').forEach(sel=>{
    const old=sel.value;
    sel.innerHTML=db.products.map(p=>`<option value="${p.id}">${esc(p.name)} — estoque ${num(p.stock)}</option>`).join('');
    if(old) sel.value=old;
  });
}

function addSaleLine(){
  const d=document.createElement('div'); d.className='itemline';
  d.innerHTML='<select class="sale-prod" onchange="saleChanged(this)"></select><input class="sale-qty" type="number" step=".001" min=".001" value="1" oninput="calcSale()"><input class="sale-price" type="number" step=".01" min="0" oninput="calcSale()"><strong class="sale-sub">R$ 0,00</strong><button class="btn bad sm" type="button" onclick="this.parentElement.remove();calcSale()">X</button>';
  $('saleLines')?.appendChild(d); refreshSelects(); saleChanged(d.querySelector('.sale-prod'));
}
function saleChanged(sel){
  const line=sel.closest('.itemline'); const p=db.products.find(x=>x.id===sel.value);
  if(line?.querySelector('.sale-price')) line.querySelector('.sale-price').value=num(p?.price).toFixed(2);
  calcSale();
}
function calcSale(){
  let total=0;
  document.querySelectorAll('#saleLines .itemline').forEach(l=>{
    const q=num(l.querySelector('.sale-qty')?.value), price=num(l.querySelector('.sale-price')?.value), sub=q*price; total+=sub;
    const out=l.querySelector('.sale-sub'); if(out) out.textContent=money(sub);
  });
  if($('saleTotal')) $('saleTotal').textContent='Total: '+money(total);
}

async function saveSale(){
  const lines=[...document.querySelectorAll('#saleLines .itemline')].map(l=>({
    product_id:l.querySelector('.sale-prod')?.value,
    quantity:num(l.querySelector('.sale-qty')?.value),
    unit_price:num(l.querySelector('.sale-price')?.value)
  })).filter(x=>x.product_id&&x.quantity>0);
  if(!lines.length) return appMsg('Adicione pelo menos um produto.',true);
  try{
    const ids=[...new Set(lines.map(x=>x.product_id))];
    const {data:products,error:pe}=await sb.from('products').select('*').in('id',ids); if(pe) throw pe;
    const map=new Map((products||[]).map(p=>[p.id,p]));
    let total=0,totalCost=0;
    for(const l of lines){ const p=map.get(l.product_id); if(!p) throw new Error('Produto não encontrado.'); if(l.quantity>num(p.stock)) throw new Error(`Estoque insuficiente para ${p.name}.`); total+=l.quantity*l.unit_price; totalCost+=l.quantity*num(p.cost); }
    const clientId=$('saleClient')?.value||null; const client=db.clients.find(c=>c.id===clientId); const payment=$('salePayment')?.value||'pix';
    const {data:sale,error:se}=await sb.from('sales').insert({client_id:clientId,client_name:client?.name||'Cliente balcão',payment_method:payment,total,total_cost:totalCost,status:'completed',sold_at:new Date().toISOString()}).select().single(); if(se) throw se;
    for(const l of lines){
      const p=map.get(l.product_id);
      const {error:ie}=await sb.from('sale_items').insert({sale_id:sale.id,product_id:p.id,product_name:p.name,quantity:l.quantity,unit_price:l.unit_price,unit_cost:num(p.cost),total:l.quantity*l.unit_price,total_cost:l.quantity*num(p.cost)}); if(ie) throw ie;
      const {error:ue}=await sb.from('products').update({stock:num(p.stock)-l.quantity}).eq('id',p.id); if(ue) throw ue;
      await sb.from('stock_moves').insert({product_id:p.id,move_type:'out',quantity:l.quantity,reason:'Venda '+sale.id});
    }
    if(payment==='other') await sb.from('accounts_receivable').insert({client_id:clientId,description:'Venda '+sale.id,amount:total,status:'open',sale_id:sale.id,payment_method:'other'});
    else await sb.from('cash_transactions').insert({type:'in',amount:total,description:'Venda '+sale.id,payment_method:payment,reference_id:sale.id});
    $('saleLines').innerHTML=''; addSaleLine(); await loadCore(); show('vendas'); appMsg('Venda salva com sucesso.');
  }catch(err){ appMsg('Erro ao salvar venda: '+(err?.message||err),true); }
}

function renderCore(){
  const now=new Date(), start=new Date(now.getFullYear(),now.getMonth(),1);
  const month=db.sales.filter(s=>new Date(s.sold_at)>=start);
  const revenue=month.reduce((a,s)=>a+num(s.total),0), profit=month.reduce((a,s)=>a+num(s.total)-num(s.total_cost),0);
  if($('kSales')) $('kSales').textContent=money(revenue);
  if($('kProfit')) $('kProfit').textContent=money(profit);
  if($('kTicket')) $('kTicket').textContent=money(month.length?revenue/month.length:0);
  if($('kStockValue')) $('kStockValue').textContent=money(db.products.reduce((a,p)=>a+num(p.stock)*num(p.cost),0));
  if($('recentSales')) $('recentSales').innerHTML=month.slice(0,10).map(s=>`<div style="padding:8px 0;border-bottom:1px solid #eee"><b>${esc(s.client_name||'Cliente balcão')}</b> — ${money(s.total)} <span class="muted">${new Date(s.sold_at).toLocaleDateString('pt-BR')}</span></div>`).join('')||'<div class="muted">Sem vendas no mês.</div>';
  if($('salesTable')) $('salesTable').innerHTML='<div class="tablewrap"><table class="table"><thead><tr><th>Data</th><th>Cliente</th><th>Pagamento</th><th>Total</th></tr></thead><tbody>'+db.sales.map(s=>`<tr><td>${new Date(s.sold_at).toLocaleDateString('pt-BR')}</td><td>${esc(s.client_name||'Cliente balcão')}</td><td>${esc(s.payment_method||'-')}</td><td>${money(s.total)}</td></tr>`).join('')+'</tbody></table></div>';
}

function enableNotifications(){ appMsg('Lembretes avançados serão reativados após estabilizarmos o acesso.'); }
function unavailable(){ appMsg('Este módulo está temporariamente em manutenção. Vendas, produtos já cadastrados, clientes e dashboard continuam disponíveis.',true); }

Object.assign(window,{loginPassword,sendMagicLink,logout,show,addSaleLine,saleChanged,calcSale,saveSale,enableNotifications,
  addProduct:unavailable,editProduct:unavailable,deleteProduct:unavailable,stockMove:unavailable,pickContacts:unavailable,addClient:unavailable,editClient:unavailable,deleteClient:unavailable,clientHistory:unavailable,addSupplier:unavailable,editSupplier:unavailable,deleteSupplier:unavailable,supplierHistory:unavailable,addPurchaseLine:unavailable,purchaseChanged:unavailable,calcPurchase:()=>{},savePurchase:unavailable,addExpense:unavailable,addFixedCost:unavailable,addBankTransaction:unavailable,importBankCsv:unavailable,render:renderCore});

try{
  const {data:{session}}=await sb.auth.getSession();
  if(session) await openApp(session);
}catch(err){ loginMsg('Erro ao iniciar: '+(err?.message||err),true); }
