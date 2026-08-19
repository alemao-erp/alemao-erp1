import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm';

const sb12=createClient('https://gtwvtgynnguiizepzfpu.supabase.co','sb_publishable_wM7la1ds3BUugE634awmHg_Tcpe4wF-',{auth:{persistSession:true,autoRefreshToken:true,detectSessionInUrl:true}});
const q12=id=>document.getElementById(id);
const n12=v=>Number(v||0);
const iso12=(d,time='12:00:00')=>d?`${d}T${time}-03:00`:new Date().toISOString();
let editSale12=null;

function note12(text,error=false){
  const el=q12('status');
  if(!el){alert(text);return;}
  el.textContent=text;el.style.color=error?'var(--bad)':'var(--ok)';el.classList.remove('hidden');
  setTimeout(()=>el.classList.add('hidden'),8000);
}

const originalStartSale12=window.startEditSale;
window.startEditSale=async function(id){
  editSale12=id;
  if(originalStartSale12) return originalStartSale12(id);
};

const originalCancel12=window.cancelSaleEdit;
window.cancelSaleEdit=function(){
  editSale12=null;
  return originalCancel12?.();
};

function lines12(){
  return [...document.querySelectorAll('#saleLines .itemline')].map(l=>({
    product_id:l.querySelector('.sale-prod')?.value,
    quantity:n12(l.querySelector('.sale-qty')?.value),
    unit_price:n12(l.querySelector('.sale-price')?.value)
  })).filter(x=>x.product_id&&x.quantity>0);
}

async function insertCash12(base){
  // O banco atual usa transaction_type = 'inflow' ou 'outflow'.
  const transaction_type=base.type==='in'?'inflow':'outflow';
  const {error}=await sb12.from('cash_transactions').insert({...base,transaction_type});
  if(error)throw error;
}

window.saveSale=async function(){
  const saleLines=lines12();
  if(!saleLines.length)return note12('Adicione pelo menos um produto.',true);
  const saleDate=q12('saleDate')?.value||new Date().toISOString().slice(0,10);
  const dueDate=q12('saleDueDate')?.value||null;
  const paidDate=q12('salePaidDate')?.value||saleDate;
  const payment=q12('salePayment')?.value||'pix';
  const clientId=q12('saleClient')?.value||null;

  try{
    const productIds=[...new Set(saleLines.map(x=>x.product_id))];
    const {data:products,error:pErr}=await sb12.from('products').select('*').in('id',productIds);
    if(pErr)throw pErr;
    const pmap=new Map((products||[]).map(p=>[p.id,p]));

    let oldItems=[];
    if(editSale12){
      const {data,error}=await sb12.from('sale_items').select('*').eq('sale_id',editSale12);
      if(error)throw error;oldItems=data||[];
    }
    const available={};
    for(const p of products||[])available[p.id]=n12(p.stock);
    if(editSale12){
      const oldIds=[...new Set(oldItems.map(x=>x.product_id).filter(Boolean))];
      if(oldIds.length){
        const {data:oldProducts,error}=await sb12.from('products').select('*').in('id',oldIds);
        if(error)throw error;
        for(const p of oldProducts||[])if(!pmap.has(p.id))pmap.set(p.id,p);
        for(const p of oldProducts||[])available[p.id]=n12(p.stock);
      }
      for(const i of oldItems)available[i.product_id]=(available[i.product_id]||0)+n12(i.quantity);
    }
    for(const i of saleLines){
      const p=pmap.get(i.product_id);
      if(!p||i.quantity>(available[i.product_id]||0))throw new Error('Estoque insuficiente para '+(p?.name||'produto'));
    }

    let clientName='Cliente balcão';
    if(clientId){const {data:c}=await sb12.from('clients').select('name').eq('id',clientId).maybeSingle();clientName=c?.name||clientName;}
    let total=0,totalCost=0;
    for(const i of saleLines){const p=pmap.get(i.product_id);total+=i.quantity*i.unit_price;totalCost+=i.quantity*n12(p.cost);}

    let saleId=editSale12;
    if(editSale12){
      for(const i of oldItems){
        const p=pmap.get(i.product_id);if(!p)continue;
        const {error}=await sb12.from('products').update({stock:n12(p.stock)+n12(i.quantity)}).eq('id',p.id);if(error)throw error;
        p.stock=n12(p.stock)+n12(i.quantity);
      }
      const deletions=await Promise.all([
        sb12.from('sale_items').delete().eq('sale_id',saleId),
        sb12.from('cash_transactions').delete().eq('reference_id',saleId),
        sb12.from('accounts_receivable').delete().eq('sale_id',saleId),
        sb12.from('stock_moves').delete().eq('reason','Venda '+saleId)
      ]);
      const dErr=deletions.find(x=>x.error)?.error;if(dErr)throw dErr;
      const {error}=await sb12.from('sales').update({client_id:clientId,client_name:clientName,payment_method:payment,total,total_cost:totalCost,status:'completed',sold_at:iso12(saleDate)}).eq('id',saleId);
      if(error)throw error;
    }else{
      const {data,error}=await sb12.from('sales').insert({client_id:clientId,client_name:clientName,payment_method:payment,total,total_cost:totalCost,status:'completed',sold_at:iso12(saleDate)}).select().single();
      if(error)throw error;saleId=data.id;
    }

    for(const i of saleLines){
      const {data:p,error:pLoad}=await sb12.from('products').select('*').eq('id',i.product_id).single();if(pLoad)throw pLoad;
      const item={sale_id:saleId,product_id:p.id,product_name:p.name,quantity:i.quantity,unit_price:i.unit_price,unit_cost:n12(p.cost),total:i.quantity*i.unit_price,total_cost:i.quantity*n12(p.cost),created_at:iso12(saleDate)};
      const {error:iErr}=await sb12.from('sale_items').insert(item);if(iErr)throw iErr;
      const {error:sErr}=await sb12.from('products').update({stock:n12(p.stock)-i.quantity}).eq('id',p.id);if(sErr)throw sErr;
      const {error:mErr}=await sb12.from('stock_moves').insert({product_id:p.id,move_type:'out',quantity:i.quantity,reason:'Venda '+saleId,created_at:iso12(saleDate)});if(mErr)throw mErr;
    }

    if(payment==='other'){
      const {error}=await sb12.from('accounts_receivable').insert({client_id:clientId,description:'Venda '+saleId,amount:total,status:'open',sale_id:saleId,payment_method:'other',due_date:dueDate,created_at:iso12(saleDate)});if(error)throw error;
    }else{
      await insertCash12({type:'in',amount:total,description:'Venda '+saleId,payment_method:payment,reference_id:saleId,created_at:iso12(paidDate)});
    }

    editSale12=null;
    note12('Venda salva corretamente na data escolhida e registrada no caixa.');
    setTimeout(()=>location.reload(),700);
  }catch(e){
    console.error('Hotfix V12 venda',e);
    note12('Erro ao salvar venda: '+(e?.message||e),true);
  }
};
