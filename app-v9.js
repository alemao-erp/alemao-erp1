import './app-v8.js';
import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm';

const sbV9=createClient('https://gtwvtgynnguiizepzfpu.supabase.co','sb_publishable_wM7la1ds3BUugE634awmHg_Tcpe4wF-',{auth:{persistSession:true,autoRefreshToken:true,detectSessionInUrl:true}});
const $9=id=>document.getElementById(id);
const n9=v=>Number(v||0);
const brl9=v=>n9(v).toLocaleString('pt-BR',{style:'currency',currency:'BRL'});
let v9Busy=false;
let v9LastLoad=0;

function ensureV9Styles(){
  if($9('v9Styles'))return;
  const s=document.createElement('style');s.id='v9Styles';s.textContent=`
    .v9-card-sub{font-size:11px;color:var(--muted);margin-top:4px}
    .v9-grid{display:grid;grid-template-columns:repeat(2,1fr);gap:14px;margin-top:16px}
    .v9-list{display:grid;gap:8px}.v9-item{display:flex;justify-content:space-between;gap:12px;align-items:center;padding:9px 0;border-bottom:1px solid var(--line)}
    .v9-item:last-child{border-bottom:0}.v9-rank{font-weight:800;min-width:24px}.v9-main{min-width:0;flex:1}.v9-main b{display:block;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}.v9-meta{font-size:12px;color:var(--muted);margin-top:2px}.v9-right{text-align:right;white-space:nowrap}
    .v9-pill{display:inline-block;padding:3px 7px;border-radius:999px;font-size:11px;font-weight:700}.v9-pill.ok{background:#ecfdf3;color:#067647}.v9-pill.warn{background:#fffaeb;color:#b54708}.v9-pill.bad{background:#fef3f2;color:#b42318}
    @media(max-width:700px){.v9-grid{grid-template-columns:1fr}}
  `;document.head.appendChild(s);
}

function ensureCard(id,label,sub=''){
  const cards=$9('dashboard')?.querySelector('.cards');if(!cards)return null;
  let el=$9(id);if(el)return el;
  const card=document.createElement('div');card.className='card';card.innerHTML=`<div class="label">${label}</div><div id="${id}" class="value">—</div>${sub?`<div class="v9-card-sub">${sub}</div>`:''}`;cards.appendChild(card);return $9(id);
}

function ensurePanels(){
  const dash=$9('dashboard');if(!dash||$9('v9SmartPanels'))return;
  const wrap=document.createElement('div');wrap.id='v9SmartPanels';wrap.className='v9-grid';wrap.innerHTML=`
    <div class="panel" style="margin-top:0"><h3>🏆 Produtos com melhor desempenho</h3><div id="v9TopProducts" class="v9-list"><div class="muted">Carregando...</div></div></div>
    <div class="panel" style="margin-top:0"><h3>📦 Prioridade da próxima compra</h3><div id="v9Reorder" class="v9-list"><div class="muted">Carregando...</div></div></div>
  `;
  const recent=$9('recentSales')?.closest('.panel');if(recent)dash.insertBefore(wrap,recent);else dash.appendChild(wrap);
}

async function refreshV9(force=false){
  if(v9Busy)return;
  if(!force&&Date.now()-v9LastLoad<90000)return;
  const {data:{session}}=await sbV9.auth.getSession();if(!session)return;
  v9Busy=true;
  try{
    ensureV9Styles();ensurePanels();
    ensureCard('kNetSmartV9','Lucro líquido estimado','Lucro bruto − custos fixos');
    ensureCard('kMarginV9','Margem bruta');
    ensureCard('kPayableSmartV9','Contas a pagar','Somente contas em aberto');
    ensureCard('kReceivableSmartV9','Contas a receber','Somente contas em aberto');
    ensureCard('kLowV9','Estoque baixo','Produtos no mínimo ou abaixo');
    ensureCard('kBestV9','Produto campeão','Maior faturamento no mês');

    const start=new Date();start.setDate(1);start.setHours(0,0,0,0);
    const since30=new Date(Date.now()-30*86400000).toISOString();
    const [salesR,itemsR,productsR,fixedR,payR,recR]=await Promise.all([
      sbV9.from('sales').select('id,total,total_cost,sold_at').gte('sold_at',start.toISOString()),
      sbV9.from('sale_items').select('sale_id,product_id,product_name,quantity,total').gte('created_at',since30),
      sbV9.from('products').select('id,name,stock,min_stock,cost,price'),
      sbV9.from('fixed_costs').select('amount,active'),
      sbV9.from('accounts_payable').select('amount,status,due_date'),
      sbV9.from('accounts_receivable').select('amount,status,due_date')
    ]);
    const err=[salesR,itemsR,productsR,fixedR,payR,recR].find(x=>x.error)?.error;if(err)throw err;

    const sales=salesR.data||[],products=productsR.data||[],items=itemsR.data||[];
    const revenue=sales.reduce((a,s)=>a+n9(s.total),0),cmv=sales.reduce((a,s)=>a+n9(s.total_cost),0),gross=revenue-cmv;
    const fixed=(fixedR.data||[]).filter(x=>x.active!==false).reduce((a,x)=>a+n9(x.amount),0),net=gross-fixed,margin=revenue?gross/revenue:0;
    const payable=(payR.data||[]).filter(x=>x.status==='open').reduce((a,x)=>a+n9(x.amount),0),receivable=(recR.data||[]).filter(x=>x.status==='open').reduce((a,x)=>a+n9(x.amount),0);
    const low=products.filter(p=>n9(p.stock)<=n9(p.min_stock)).length;

    $9('kNetSmartV9').textContent=brl9(net);$9('kNetSmartV9').style.color=net>=0?'var(--ok)':'var(--bad)';
    $9('kMarginV9').textContent=(margin*100).toFixed(1)+'%';
    $9('kPayableSmartV9').textContent=brl9(payable);$9('kReceivableSmartV9').textContent=brl9(receivable);$9('kLowV9').textContent=String(low);

    const saleIds=new Set(sales.map(s=>s.id));
    const monthItems=items.filter(i=>saleIds.has(i.sale_id));
    const perf=new Map();
    for(const i of monthItems){const key=i.product_id||i.product_name;const r=perf.get(key)||{name:i.product_name||'Produto',qty:0,revenue:0};r.qty+=n9(i.quantity);r.revenue+=n9(i.total);perf.set(key,r);}
    const top=[...perf.values()].sort((a,b)=>b.revenue-a.revenue);
    $9('kBestV9').textContent=top[0]?.name||'—';
    const topBox=$9('v9TopProducts');
    topBox.innerHTML=top.slice(0,6).map((x,i)=>`<div class="v9-item"><span class="v9-rank">${i+1}º</span><div class="v9-main"><b>${x.name}</b><div class="v9-meta">${x.qty.toFixed(1)} unidade(s) vendida(s)</div></div><div class="v9-right"><b>${brl9(x.revenue)}</b></div></div>`).join('')||'<div class="muted">Ainda não há vendas suficientes neste mês.</div>';

    const qty30=new Map();for(const i of items)qty30.set(i.product_id,(qty30.get(i.product_id)||0)+n9(i.quantity));
    const reorder=products.map(p=>{const sold=qty30.get(p.id)||0,daily=sold/30,days=daily>0?n9(p.stock)/daily:Infinity,suggest=Math.max(0,Math.ceil(daily*30+n9(p.min_stock)-n9(p.stock)));let priority=0;if(n9(p.stock)<=0)priority=3;else if(n9(p.stock)<=n9(p.min_stock)||days<=7)priority=2;else if(days<=14)priority=1;return{p,sold,days,suggest,priority};}).filter(x=>x.priority>0).sort((a,b)=>b.priority-a.priority||a.days-b.days).slice(0,8);
    const rBox=$9('v9Reorder');rBox.innerHTML=reorder.map(x=>{const cls=x.priority===3?'bad':x.priority===2?'warn':'ok';const label=x.priority===3?'SEM ESTOQUE':x.priority===2?'COMPRAR AGORA':'PLANEJAR';const days=Number.isFinite(x.days)?`~${Math.max(0,Math.floor(x.days))} dia(s)`:'sem previsão';return `<div class="v9-item"><div class="v9-main"><b>${x.p.name}</b><div class="v9-meta">Estoque ${n9(x.p.stock)} · ${days}</div></div><div class="v9-right"><span class="v9-pill ${cls}">${label}</span><div class="v9-meta">Sugerido: ${x.suggest||Math.max(1,n9(x.p.min_stock))}</div></div></div>`;}).join('')||'<div class="ok">Nenhuma reposição urgente calculada agora.</div>';
    v9LastLoad=Date.now();
  }catch(e){console.error('Dashboard V9',e);}
  finally{v9Busy=false;}
}

const bootV9=()=>{ensureV9Styles();ensurePanels();setTimeout(()=>refreshV9(true),900);document.addEventListener('visibilitychange',()=>{if(!document.hidden)refreshV9();});setInterval(()=>refreshV9(),120000);};
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',bootV9);else bootV9();
