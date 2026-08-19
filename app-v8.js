import './app-v7.js';
import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm';

const sbV8=createClient('https://gtwvtgynnguiizepzfpu.supabase.co','sb_publishable_wM7la1ds3BUugE634awmHg_Tcpe4wF-',{auth:{persistSession:true,autoRefreshToken:true,detectSessionInUrl:true}});
const $8=id=>document.getElementById(id);
const n8=v=>Number(v||0);
let editingPurchaseV8=null;
let oldItemsV8=[];
let legacyPurchaseV8=false;
const baseSavePurchaseV8=window.savePurchase;

function msg8(text,error=false){
  const el=$8('status');
  if(!el){alert(text);return;}
  el.textContent=text;
  el.style.color=error?'var(--bad)':'var(--ok)';
  el.classList.remove('hidden');
  setTimeout(()=>el.classList.add('hidden'),9000);
}

function setEditUi8(on){
  const btn=[...document.querySelectorAll('#compras button')].find(b=>b.textContent.includes('Salvar compra')||b.textContent.includes('Salvar alterações'));
  if(btn)btn.textContent=on?'Salvar alterações':'Salvar compra';
  let cancel=$8('cancelPurchaseEdit');
  if(!cancel&&btn){
    cancel=document.createElement('button');cancel.id='cancelPurchaseEdit';cancel.className='btn alt';cancel.type='button';cancel.textContent='Cancelar edição';btn.after(cancel);
  }
  if(cancel){cancel.onclick=window.cancelPurchaseEdit;cancel.classList.toggle('hidden',!on);}
}

function clearPurchaseForm8(){
  if($8('purchaseLines'))$8('purchaseLines').innerHTML='';
  if($8('purchaseSupplier'))$8('purchaseSupplier').value='';
  if($8('purchaseStatus'))$8('purchaseStatus').value='paid';
  if($8('purchaseDue'))$8('purchaseDue').value='';
  if($8('purchaseReceipt'))$8('purchaseReceipt').value='';
  document.getElementById('legacyPurchaseWarningV8')?.remove();
}

window.cancelPurchaseEdit=function(){
  editingPurchaseV8=null;oldItemsV8=[];legacyPurchaseV8=false;
  clearPurchaseForm8();
  window.addPurchaseLine?.();
  setEditUi8(false);
  window.calcPurchase?.();
};

function showLegacyWarning8(total){
  document.getElementById('legacyPurchaseWarningV8')?.remove();
  const box=document.createElement('div');
  box.id='legacyPurchaseWarningV8';box.className='note';box.style.margin='12px 0';
  box.innerHTML=`<b>Compra antiga sem itens vinculados.</b><br>O sistema guardou o total anterior (${Number(total||0).toLocaleString('pt-BR',{style:'currency',currency:'BRL'})}), mas não guardou produto e quantidade. Adicione os itens abaixo. Ao salvar pela primeira vez, eles serão vinculados sem alterar o estoque atual, evitando duplicidade.`;
  $8('purchaseLines')?.before(box);
}

window.startEditPurchase=async function(id){
  try{
    const [{data:p,error:pe},{data:items,error:ie}]=await Promise.all([
      sbV8.from('purchases').select('*').eq('id',id).single(),
      sbV8.from('purchase_items').select('*').eq('purchase_id',id).order('id',{ascending:true})
    ]);
    if(pe)throw pe;if(ie)throw ie;if(!p)throw new Error('Compra não encontrada.');
    editingPurchaseV8=id;oldItemsV8=items||[];legacyPurchaseV8=oldItemsV8.length===0;
    window.show?.('compras');
    if($8('purchaseSupplier'))$8('purchaseSupplier').value=p.supplier_id||'';
    if($8('purchaseStatus'))$8('purchaseStatus').value=p.payment_status||'paid';
    if($8('purchaseDue'))$8('purchaseDue').value=p.due_date||'';
    if($8('purchaseLines'))$8('purchaseLines').innerHTML='';
    document.getElementById('legacyPurchaseWarningV8')?.remove();
    if(oldItemsV8.length){oldItemsV8.forEach(i=>window.addPurchaseLine?.(i));}
    else{window.addPurchaseLine?.();showLegacyWarning8(p.total);}
    setEditUi8(true);
    window.calcPurchase?.();
    window.scrollTo({top:0,behavior:'smooth'});
  }catch(err){msg8('Erro ao abrir a compra para edição: '+err.message,true);}
};

function formLines8(){
  return [...document.querySelectorAll('#purchaseLines .itemline')].map(l=>({
    product_id:l.querySelector('.purchase-prod')?.value||'',
    quantity:n8(l.querySelector('.purchase-qty')?.value),
    unit_cost:n8(l.querySelector('.purchase-cost')?.value)
  })).filter(x=>x.product_id&&x.quantity>0);
}

window.savePurchase=async function(){
  if(!editingPurchaseV8)return baseSavePurchaseV8?.();
  const lines=formLines8();
  if(!lines.length)return msg8('Adicione pelo menos um produto com quantidade maior que zero.',true);
  const btn=[...document.querySelectorAll('#compras button')].find(b=>b.textContent.includes('Salvar alterações'));
  if(btn){btn.disabled=true;btn.textContent='Salvando...';}
  try{
    const productIds=[...new Set([...oldItemsV8.map(i=>i.product_id),...lines.map(i=>i.product_id)])];
    const {data:products,error:prodErr}=await sbV8.from('products').select('*').in('id',productIds);
    if(prodErr)throw prodErr;
    const productMap=new Map((products||[]).map(p=>[p.id,p]));
    const oldMap={},newMap={};
    oldItemsV8.forEach(i=>oldMap[i.product_id]=(oldMap[i.product_id]||0)+n8(i.quantity));
    lines.forEach(i=>newMap[i.product_id]=(newMap[i.product_id]||0)+n8(i.quantity));

    // Compras normais: ajusta somente a diferença entre quantidade antiga e nova.
    // Compras legadas sem itens: não mexe no estoque nesta primeira vinculação para evitar duplicidade.
    if(!legacyPurchaseV8){
      for(const id of productIds){
        const p=productMap.get(id);if(!p)continue;
        const next=n8(p.stock)-(oldMap[id]||0)+(newMap[id]||0);
        if(next<0)throw new Error(`O estoque de ${p.name} ficaria negativo.`);
      }
      for(const id of productIds){
        const p=productMap.get(id);if(!p)continue;
        const next=n8(p.stock)-(oldMap[id]||0)+(newMap[id]||0);
        if(next!==n8(p.stock)){const {error}=await sbV8.from('products').update({stock:next}).eq('id',id);if(error)throw error;}
      }
    }

    const supplierId=$8('purchaseSupplier')?.value||null;
    let supplierName=null;
    if(supplierId){const {data:s}=await sbV8.from('suppliers').select('name').eq('id',supplierId).maybeSingle();supplierName=s?.name||null;}
    const total=lines.reduce((a,i)=>a+i.quantity*i.unit_cost,0);
    const status=$8('purchaseStatus')?.value||'paid';
    const due=$8('purchaseDue')?.value||null;

    const {data:oldPurchase}=await sbV8.from('purchases').select('receipt_path').eq('id',editingPurchaseV8).single();
    const update={supplier_id:supplierId,supplier_name:supplierName,total,payment_status:status,due_date:due};
    const file=$8('purchaseReceipt')?.files?.[0];
    if(file){
      const {data:{user}}=await sbV8.auth.getUser();
      const safe=(file.name||'arquivo').replace(/[^a-zA-Z0-9._-]/g,'_');
      const path=`${user.id}/compra-${Date.now()}-${safe}`;
      const {error:upErr}=await sbV8.storage.from('receipts').upload(path,file,{contentType:file.type||undefined});if(upErr)throw upErr;
      update.receipt_path=path;
    } else update.receipt_path=oldPurchase?.receipt_path||null;

    const {error:uErr}=await sbV8.from('purchases').update(update).eq('id',editingPurchaseV8);if(uErr)throw uErr;
    const {error:dErr}=await sbV8.from('purchase_items').delete().eq('purchase_id',editingPurchaseV8);if(dErr)throw dErr;
    for(const i of lines){
      const p=productMap.get(i.product_id);if(!p)throw new Error('Produto não encontrado.');
      const {error:iErr}=await sbV8.from('purchase_items').insert({purchase_id:editingPurchaseV8,product_id:p.id,product_name:p.name,quantity:i.quantity,unit_cost:i.unit_cost,total:i.quantity*i.unit_cost});if(iErr)throw iErr;
      await sbV8.from('products').update({cost:i.unit_cost}).eq('id',p.id);
    }

    await sbV8.from('cash_transactions').delete().eq('reference_id',editingPurchaseV8);
    await sbV8.from('accounts_payable').delete().eq('purchase_id',editingPurchaseV8);
    await sbV8.from('stock_moves').delete().eq('reason','Compra '+editingPurchaseV8);
    if(!legacyPurchaseV8){
      for(const i of lines)await sbV8.from('stock_moves').insert({product_id:i.product_id,move_type:'in',quantity:i.quantity,reason:'Compra '+editingPurchaseV8});
    }
    if(status==='paid')await sbV8.from('cash_transactions').insert({type:'out',amount:total,description:'Compra de mercadoria',payment_method:'other',reference_id:editingPurchaseV8,receipt_path:update.receipt_path});
    else await sbV8.from('accounts_payable').insert({supplier_id:supplierId,description:'Compra de mercadoria',amount:total,due_date:due,status:'open',purchase_id:editingPurchaseV8,receipt_path:update.receipt_path});

    const wasLegacy=legacyPurchaseV8;
    editingPurchaseV8=null;oldItemsV8=[];legacyPurchaseV8=false;
    clearPurchaseForm8();setEditUi8(false);
    msg8(wasLegacy?'Compra antiga corrigida e itens vinculados. O estoque atual foi preservado.':'Compra alterada. Quantidades, valores, estoque e financeiro foram recalculados.');
    setTimeout(()=>location.reload(),500);
  }catch(err){
    msg8('Erro ao salvar alterações: '+err.message,true);
    if(btn){btn.disabled=false;btn.textContent='Salvar alterações';}
  }
};
