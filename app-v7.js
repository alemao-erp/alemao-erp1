import './app-v6.js';
import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm';

const sbV7=createClient('https://gtwvtgynnguiizepzfpu.supabase.co','sb_publishable_wM7la1ds3BUugE634awmHg_Tcpe4wF-',{auth:{persistSession:true,autoRefreshToken:true,detectSessionInUrl:true}});
const $7=id=>document.getElementById(id);
let productCacheV7=[];

function imageUrlV7(path){
  if(!path)return '';
  return sbV7.storage.from('product-images').getPublicUrl(path).data.publicUrl||'';
}

async function loadProductsV7(){
  const {data,error}=await sbV7.from('products').select('id,name,image_path');
  if(!error)productCacheV7=data||[];
  return productCacheV7;
}

function ensureStylesV7(){
  if($7('v7Styles'))return;
  const s=document.createElement('style');
  s.id='v7Styles';
  s.textContent=`
    .v7-product-picker{display:flex;gap:10px;align-items:center;min-width:0}
    .v7-product-picker select{flex:1;min-width:0}
    .v7-line-photo,.v7-stock-photo{width:48px;height:48px;object-fit:cover;border-radius:10px;border:1px solid #e5e7eb;background:#f8fafc;flex:0 0 auto}
    .v7-line-placeholder,.v7-stock-placeholder{width:48px;height:48px;border-radius:10px;border:1px dashed #d0d5dd;display:grid;place-items:center;background:#f8fafc;font-size:22px;flex:0 0 auto}
    .v7-stock-name{display:flex;gap:10px;align-items:center;min-width:240px}
    .v7-stock-preview{display:flex;align-items:center;gap:10px;margin-top:10px;padding:10px;border:1px solid #e5e7eb;border-radius:10px;background:#fff;max-width:520px}
    .v7-stock-preview img{width:64px;height:64px;object-fit:cover;border-radius:10px;border:1px solid #e5e7eb}
    @media(max-width:600px){.v7-line-photo,.v7-line-placeholder{width:64px;height:64px}.v7-product-picker{align-items:flex-start}}
  `;
  document.head.appendChild(s);
}

function photoNodeV7(product,cls='v7-line-photo'){
  if(product?.image_path){
    const img=document.createElement('img');
    img.className=cls;
    img.src=imageUrlV7(product.image_path);
    img.alt=product.name||'Produto';
    img.loading='lazy';
    return img;
  }
  const ph=document.createElement('div');
  ph.className=cls==='v7-stock-photo'?'v7-stock-placeholder':'v7-line-placeholder';
  ph.textContent='📦';
  ph.title='Produto sem foto';
  return ph;
}

function decorateItemLineV7(line,selector){
  const sel=line.querySelector(selector);
  if(!sel)return;
  let wrap=sel.parentElement?.classList.contains('v7-product-picker')?sel.parentElement:null;
  if(!wrap){
    wrap=document.createElement('div');
    wrap.className='v7-product-picker';
    sel.parentNode.insertBefore(wrap,sel);
    wrap.appendChild(sel);
  }
  const old=wrap.querySelector('.v7-line-photo,.v7-line-placeholder');
  if(old)old.remove();
  const product=productCacheV7.find(p=>p.id===sel.value);
  wrap.insertBefore(photoNodeV7(product),sel);
  if(sel.dataset.v7bound!=='1'){
    sel.dataset.v7bound='1';
    sel.addEventListener('change',()=>decorateItemLineV7(line,selector));
  }
}

function decorateSaleAndPurchaseLinesV7(){
  document.querySelectorAll('#saleLines .itemline').forEach(line=>decorateItemLineV7(line,'.sale-prod'));
  document.querySelectorAll('#purchaseLines .itemline').forEach(line=>decorateItemLineV7(line,'.purchase-prod'));
}

function decorateStockTableV7(){
  const table=$7('stockTable');
  if(!table)return;
  table.querySelectorAll('tbody tr').forEach(tr=>{
    const td=tr.querySelector('td');
    if(!td||td.dataset.v7photo==='1')return;
    const name=td.textContent.trim();
    const p=productCacheV7.find(x=>String(x.name||'').trim()===name);
    if(!p)return;
    td.dataset.v7photo='1';
    td.textContent='';
    const wrap=document.createElement('div');
    wrap.className='v7-stock-name';
    wrap.appendChild(photoNodeV7(p,'v7-stock-photo'));
    const span=document.createElement('span');span.textContent=name;wrap.appendChild(span);
    td.appendChild(wrap);
  });
}

function renderStockPreviewV7(){
  const sel=$7('stockProduct');
  if(!sel)return;
  let box=$7('v7StockPreview');
  if(!box){
    box=document.createElement('div');
    box.id='v7StockPreview';
    box.className='v7-stock-preview';
    sel.closest('.field')?.appendChild(box);
  }
  const p=productCacheV7.find(x=>x.id===sel.value);
  if(!p){box.innerHTML='<span class="muted">Selecione um produto.</span>';return;}
  const u=imageUrlV7(p.image_path);
  box.innerHTML=`${u?`<img src="${u}" alt="${String(p.name||'').replace(/"/g,'&quot;')}">`:'<div class="v7-line-placeholder">📦</div>'}<div><b>${p.name}</b><div class="muted">Foto vinculada ao cadastro do produto</div></div>`;
  if(sel.dataset.v7bound!=='1'){
    sel.dataset.v7bound='1';
    sel.addEventListener('change',renderStockPreviewV7);
  }
}

function observeV7(){
  const watch=(id,fn)=>{
    const el=$7(id);if(!el)return;
    new MutationObserver(()=>fn()).observe(el,{childList:true,subtree:true});
  };
  watch('saleLines',decorateSaleAndPurchaseLinesV7);
  watch('purchaseLines',decorateSaleAndPurchaseLinesV7);
  watch('stockTable',decorateStockTableV7);
}

async function bootV7(){
  ensureStylesV7();
  await loadProductsV7();
  decorateSaleAndPurchaseLinesV7();
  decorateStockTableV7();
  renderStockPreviewV7();
  observeV7();
  setInterval(async()=>{await loadProductsV7();decorateSaleAndPurchaseLinesV7();decorateStockTableV7();renderStockPreviewV7();},30000);
}

if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',()=>setTimeout(bootV7,700));
else setTimeout(bootV7,700);
