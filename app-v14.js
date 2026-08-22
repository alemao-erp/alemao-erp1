// V14 - descontos em vendas, compras e desconto padrao por cliente
import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm';

const sb14=createClient('https://gtwvtgynnguiizepzfpu.supabase.co','sb_publishable_wM7la1ds3BUugE634awmHg_Tcpe4wF-',{auth:{persistSession:true,autoRefreshToken:true,detectSessionInUrl:true}});
const q14=id=>document.getElementById(id);
const n14=v=>Number(v||0);
const brl14=v=>n14(v).toLocaleString('pt-BR',{style:'currency',currency:'BRL'});
const MARK14=/\s*\[#DESCONTO:(percent|fixed):([0-9.]+)\]\s*/gi;

function cleanNotes14(notes){return String(notes||'').replace(MARK14,' ').replace(/\s{2,}/g,' ').trim();}
function discountFromNotes14(notes){
  const text=String(notes||''); let m,last=null; MARK14.lastIndex=0;
  while((m=MARK14.exec(text))) last={type:m[1],value:n14(m[2])};
  MARK14.lastIndex=0; return last||{type:'percent',value:0};
}
function notesWithDiscount14(notes,type,value){
  const clean=cleanNotes14(notes),v=Math.max(0,n14(value));
  return v?`${clean}${clean?' ':''}[#DESCONTO:${type==='fixed'?'fixed':'percent'}:${v}]`:clean;
}
function discountAmount14(subtotal,type,value){
  const v=Math.max(0,n14(value));
  if(subtotal<=0||v<=0)return 0;
  return type==='fixed'?Math.min(v,subtotal):Math.min(subtotal,subtotal*Math.min(v,100)/100);
}
function labelDiscount14(type,value){
  const v=n14(value); if(!v)return 'Sem desconto';
  return type==='fixed'?brl14(v):`${v.toLocaleString('pt-BR',{maximumFractionDigits:2})}%`;
}
function status14(text,error=false){
  const el=q14('status'); if(!el)return;
  el.textContent=text;el.style.color=error?'var(--bad)':'var(--ok)';el.classList.remove('hidden');
  setTimeout(()=>el.classList.add('hidden'),7000);
}

function style14(){
  if(q14('v14styles'))return;
  const s=document.createElement('style');s.id='v14styles';
  s.textContent=`.discount14{margin-top:12px;padding:12px;border:1px solid var(--line);border-radius:10px;background:#fffaf0}.discount14 .grid{margin:0}.discount14summary{margin-top:8px;font-size:13px}.discount14badge{display:inline-block;padding:3px 7px;border-radius:999px;background:#fff4e5;color:#9a6700;font-size:12px;font-weight:700}.discount14hint{font-size:12px;color:var(--muted);margin-top:5px}`;
  document.head.appendChild(s);
}
function discountBox14(prefix,title){
  const box=document.createElement('div');box.className='discount14';box.id=prefix+'DiscountBox';
  box.innerHTML=`<div class="grid"><div class="field"><label>${title} - tipo</label><select id="${prefix}DiscountType"><option value="percent">Percentual (%)</option><option value="fixed">Valor (R$)</option></select></div><div class="field"><label>${title} - valor</label><input id="${prefix}DiscountValue" type="number" min="0" step="0.01" value="0"></div></div><div id="${prefix}DiscountSummary" class="discount14summary"></div>`;
  return box;
}
function injectSale14(){
  if(q14('saleDiscountBox'))return;
  const panel=q14('saleLines')?.closest('.panel');if(!panel)return;
  const head=panel.querySelector('.itemhead');const box=discountBox14('sale','Desconto da venda');
  if(head)panel.insertBefore(box,head);else panel.appendChild(box);
  q14('saleDiscountType').addEventListener('change',renderSale14);
  q14('saleDiscountValue').addEventListener('input',renderSale14);
}
function injectPurchase14(){
  if(q14('purchaseDiscountBox'))return;
  const panel=q14('purchaseLines')?.closest('.panel');if(!panel)return;
  const head=panel.querySelector('.itemhead');const box=discountBox14('purchase','Desconto da compra');
  if(head)panel.insertBefore(box,head);else panel.appendChild(box);
  q14('purchaseDiscountType').addEventListener('change',renderPurchase14);
  q14('purchaseDiscountValue').addEventListener('input',renderPurchase14);
}
function injectClient14(){
  if(q14('cDiscountType'))return;
  const form=q14('cName')?.closest('form');if(!form)return;
  const submit=[...form.children].find(x=>x.querySelector?.('button'));
  const t=document.createElement('div');t.className='field';t.innerHTML='<label>Desconto padrão do cliente</label><select id="cDiscountType"><option value="percent">Percentual (%)</option><option value="fixed">Valor (R$)</option></select>';
  const v=document.createElement('div');v.className='field';v.innerHTML='<label>Valor do desconto</label><input id="cDiscountValue" type="number" min="0" step="0.01" value="0"><div class="discount14hint">Será sugerido automaticamente quando este cliente for escolhido na venda.</div>';
  if(submit){form.insertBefore(t,submit);form.insertBefore(v,submit);}else{form.append(t,v);}
}
function inject14(){style14();injectSale14();injectPurchase14();injectClient14();}

function saleSubtotal14(){let t=0;document.querySelectorAll('#saleLines .itemline').forEach(l=>t+=n14(l.querySelector('.sale-qty')?.value)*n14(l.querySelector('.sale-price')?.value));return t;}
function purchaseSubtotal14(){let t=0;document.querySelectorAll('#purchaseLines .itemline').forEach(l=>t+=n14(l.querySelector('.purchase-qty')?.value)*n14(l.querySelector('.purchase-cost')?.value));return t;}
function renderSale14(){
  if(!q14('saleDiscountValue'))return;
  const sub=saleSubtotal14(),type=q14('saleDiscountType').value,val=n14(q14('saleDiscountValue').value),disc=discountAmount14(sub,type,val),total=Math.max(0,sub-disc);
  if(q14('saleDiscountSummary'))q14('saleDiscountSummary').innerHTML=`Subtotal: <b>${brl14(sub)}</b> · Desconto: <b>${brl14(disc)}</b> · Total final: <b>${brl14(total)}</b>`;
  const totalEl=q14('saleTotal');if(totalEl)totalEl.textContent=`Total: ${brl14(total)}`;
}
function renderPurchase14(){
  if(!q14('purchaseDiscountValue'))return;
  const sub=purchaseSubtotal14(),type=q14('purchaseDiscountType').value,val=n14(q14('purchaseDiscountValue').value),disc=discountAmount14(sub,type,val),total=Math.max(0,sub-disc);
  if(q14('purchaseDiscountSummary'))q14('purchaseDiscountSummary').innerHTML=`Subtotal: <b>${brl14(sub)}</b> · Desconto: <b>${brl14(disc)}</b> · Total final: <b>${brl14(total)}</b>`;
  const totalEl=q14('purchaseTotal');if(totalEl)totalEl.textContent=`Total: ${brl14(total)}`;
}
function resetSaleDiscount14(){if(q14('saleDiscountType'))q14('saleDiscountType').value='percent';if(q14('saleDiscountValue'))q14('saleDiscountValue').value='0';renderSale14();}
function resetPurchaseDiscount14(){if(q14('purchaseDiscountType'))q14('purchaseDiscountType').value='percent';if(q14('purchaseDiscountValue'))q14('purchaseDiscountValue').value='0';renderPurchase14();}

async function applyClientDefault14(){
  const id=q14('saleClient')?.value;inject14();
  if(!id){resetSaleDiscount14();return;}
  const {data,error}=await sb14.from('clients').select('notes').eq('id',id).maybeSingle();
  if(error)return console.warn('V14 desconto cliente',error);
  const d=discountFromNotes14(data?.notes);
  q14('saleDiscountType').value=d.type;q14('saleDiscountValue').value=d.value||0;renderSale14();
  if(d.value)status14(`Desconto padrão do cliente aplicado: ${labelDiscount14(d.type,d.value)}.`);
}

function proportionallyDiscount14(container,qtySel,priceSel,type,value){
  const lines=[...document.querySelectorAll(`${container} .itemline`)];
  const subtotal=lines.reduce((a,l)=>a+n14(l.querySelector(qtySel)?.value)*n14(l.querySelector(priceSel)?.value),0);
  const disc=discountAmount14(subtotal,type,value);
  if(!disc)return {subtotal,discount:0,total:subtotal,changed:[]};
  if(disc>=subtotal)return {error:'O desconto não pode deixar o total da operação em R$ 0,00.'};
  const factor=(subtotal-disc)/subtotal,changed=[];
  for(const l of lines){const input=l.querySelector(priceSel);if(!input)continue;changed.push([input,input.value]);input.value=(n14(input.value)*factor).toFixed(6);}
  return {subtotal,discount:disc,total:subtotal-disc,changed};
}
function restore14(changed){for(const [el,value] of changed||[])if(document.body.contains(el))el.value=value;}

const oldCalcSale14=window.calcSale;
window.calcSale=function(){const r=oldCalcSale14?.apply(this,arguments);setTimeout(renderSale14,0);return r;};
const oldCalcPurchase14=window.calcPurchase;
window.calcPurchase=function(){const r=oldCalcPurchase14?.apply(this,arguments);setTimeout(renderPurchase14,0);return r;};

const oldSaveSale14=window.saveSale;
window.saveSale=async function(){
  inject14();const type=q14('saleDiscountType')?.value||'percent',value=n14(q14('saleDiscountValue')?.value),applied=proportionallyDiscount14('#saleLines','.sale-qty','.sale-price',type,value);
  if(applied.error)return status14(applied.error,true);
  try{return await oldSaveSale14?.();}catch(e){restore14(applied.changed);renderSale14();throw e;}
};
const oldStartSale14=window.startEditSale;
window.startEditSale=async function(id){const r=await oldStartSale14?.(id);setTimeout(()=>{resetSaleDiscount14();if(q14('saleDiscountSummary'))q14('saleDiscountSummary').innerHTML+='<div class="discount14hint">Edição: o valor carregado já é o valor registrado na venda. Informe novo desconto somente se quiser dar outro abatimento.</div>';},180);return r;};
const oldCancelSale14=window.cancelSaleEdit;
window.cancelSaleEdit=function(){const r=oldCancelSale14?.();setTimeout(resetSaleDiscount14,0);return r;};

const oldSavePurchase14=window.savePurchase;
window.savePurchase=async function(){
  inject14();const type=q14('purchaseDiscountType')?.value||'percent',value=n14(q14('purchaseDiscountValue')?.value),applied=proportionallyDiscount14('#purchaseLines','.purchase-qty','.purchase-cost',type,value);
  if(applied.error)return status14(applied.error,true);
  try{const r=await oldSavePurchase14?.();setTimeout(resetPurchaseDiscount14,250);return r;}catch(e){restore14(applied.changed);renderPurchase14();throw e;}
};
const oldStartPurchase14=window.startEditPurchase;
window.startEditPurchase=async function(id){const r=await oldStartPurchase14?.(id);setTimeout(()=>{resetPurchaseDiscount14();if(q14('purchaseDiscountSummary'))q14('purchaseDiscountSummary').innerHTML+='<div class="discount14hint">Edição: os custos carregados já são os valores registrados.</div>';},180);return r;};
const oldCancelPurchase14=window.cancelPurchaseEdit;
window.cancelPurchaseEdit=function(){const r=oldCancelPurchase14?.();setTimeout(resetPurchaseDiscount14,0);return r;};

const oldAddClient14=window.addClient;
window.addClient=async function(e){
  inject14();const notes=q14('cNotes');if(notes)notes.value=notesWithDiscount14(notes.value,q14('cDiscountType')?.value||'percent',q14('cDiscountValue')?.value||0);
  const r=await oldAddClient14?.(e);
  setTimeout(()=>{if(q14('cNotes'))q14('cNotes').value=cleanNotes14(q14('cNotes').value);if(q14('cDiscountType'))q14('cDiscountType').value='percent';if(q14('cDiscountValue'))q14('cDiscountValue').value='0';},120);
  return r;
};
window.editClient=async function(id){
  try{
    const {data:c,error}=await sb14.from('clients').select('*').eq('id',id).single();if(error)throw error;
    const d=discountFromNotes14(c.notes),name=prompt('Nome',c.name||'');if(name===null)return;
    const phone=prompt('Telefone',c.phone||'');if(phone===null)return;
    const location=prompt('Bairro/Cidade',c.location||'');if(location===null)return;
    const notes=prompt('Observações',cleanNotes14(c.notes));if(notes===null)return;
    const typeText=prompt('Tipo de desconto padrão: digite % para percentual ou R$ para valor fixo',d.type==='fixed'?'R$':'%');if(typeText===null)return;
    const type=String(typeText).toLowerCase().includes('r')?'fixed':'percent';
    const valueText=prompt(type==='fixed'?'Desconto padrão em R$':'Desconto padrão em %',String(d.value||0));if(valueText===null)return;
    const value=Math.max(0,n14(String(valueText).replace(',','.')));
    if(type==='percent'&&value>100)return status14('O desconto percentual não pode passar de 100%.',true);
    const {error:uErr}=await sb14.from('clients').update({name:name.trim(),phone:phone||null,location:location||null,notes:notesWithDiscount14(notes,type,value)}).eq('id',id);if(uErr)throw uErr;
    await sb14.from('sales').update({client_name:name.trim()}).eq('client_id',id);
    status14(`Cliente atualizado. Desconto padrão: ${labelDiscount14(type,value)}.`);setTimeout(()=>location.reload(),500);
  }catch(e){console.error('V14 editar cliente',e);status14('Erro ao atualizar cliente: '+(e?.message||e),true);}
};

document.addEventListener('change',e=>{if(e.target?.id==='saleClient')applyClientDefault14();if(e.target?.matches('#saleLines input,#saleLines select'))setTimeout(renderSale14,0);if(e.target?.matches('#purchaseLines input,#purchaseLines select'))setTimeout(renderPurchase14,0);});
document.addEventListener('input',e=>{if(e.target?.closest('#saleLines'))setTimeout(renderSale14,0);if(e.target?.closest('#purchaseLines'))setTimeout(renderPurchase14,0);});

function boot14(){inject14();renderSale14();renderPurchase14();}
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',()=>setTimeout(boot14,700));else setTimeout(boot14,700);
const observer14=new MutationObserver(()=>{inject14();});observer14.observe(document.documentElement,{subtree:true,childList:true});
