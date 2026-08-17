import './app.js';
import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm';

const sbV6=createClient('https://gtwvtgynnguiizepzfpu.supabase.co','sb_publishable_wM7la1ds3BUugE634awmHg_Tcpe4wF-',{auth:{persistSession:true,autoRefreshToken:true,detectSessionInUrl:true}});
const $v=id=>document.getElementById(id);
const moneyV=v=>Number(v||0).toLocaleString('pt-BR',{style:'currency',currency:'BRL'});
const numV=v=>Number(v||0);

function statusV6(text,error=false){
  const el=$v('status');
  if(!el){alert(text);return;}
  el.textContent=text;
  el.style.color=error?'var(--bad)':'var(--ok)';
  el.classList.remove('hidden');
  setTimeout(()=>el.classList.add('hidden'),7000);
}

function ensureV6Styles(){
  if($v('v6Styles'))return;
  const s=document.createElement('style');
  s.id='v6Styles';
  s.textContent=`
  .product-photo{width:46px;height:46px;object-fit:cover;border-radius:9px;border:1px solid #e5e7eb;margin-right:9px;vertical-align:middle;background:#fff}
  .product-name-wrap{display:flex;align-items:center;min-width:260px}
  .v6-modal-backdrop{position:fixed;inset:0;background:rgba(15,23,42,.52);z-index:9998;display:grid;place-items:center;padding:16px}
  .v6-modal{background:white;border-radius:16px;width:min(720px,100%);max-height:92vh;overflow:auto;padding:20px;box-shadow:0 20px 50px rgba(0,0,0,.25)}
  .v6-modal h2{margin-top:0}.v6-grid{display:grid;grid-template-columns:1fr 1fr;gap:12px}.v6-actions{display:flex;gap:8px;justify-content:flex-end;margin-top:16px;flex-wrap:wrap}.v6-preview{width:120px;height:120px;object-fit:cover;border-radius:12px;border:1px solid #e5e7eb;background:#f8fafc}
  @media(max-width:600px){.v6-grid{grid-template-columns:1fr}}
  `;
  document.head.appendChild(s);
}

async function uploadProductImage(file,productId='produto'){
  if(!file)return null;
  if(file.size>5*1024*1024)throw new Error('A foto deve ter no máximo 5 MB.');
  if(!String(file.type||'').startsWith('image/'))throw new Error('Escolha um arquivo de imagem.');
  const {data:{user}}=await sbV6.auth.getUser();
  if(!user)throw new Error('Sessão não encontrada. Entre novamente no sistema.');
  const ext=(file.name.split('.').pop()||'jpg').replace(/[^a-z0-9]/gi,'').toLowerCase();
  const path=`${user.id}/${productId}-${Date.now()}.${ext||'jpg'}`;
  const {error}=await sbV6.storage.from('product-images').upload(path,file,{upsert:false,contentType:file.type});
  if(error)throw error;
  return path;
}

function productImageUrl(path){
  if(!path)return '';
  return sbV6.storage.from('product-images').getPublicUrl(path).data.publicUrl||'';
}

function injectProductPhotoField(){
  const form=document.querySelector('#produtos form');
  if(!form||$v('pImage'))return;
  const wrap=document.createElement('div');
  wrap.className='field';
  wrap.innerHTML='<label>Foto do produto</label><input id="pImage" type="file" accept="image/*"><div class="muted" style="font-size:12px;margin-top:4px">JPG, PNG, WEBP ou GIF · até 5 MB</div>';
  const buttonBox=form.querySelector('button')?.parentElement;
  if(buttonBox)form.insertBefore(wrap,buttonBox); else form.appendChild(wrap);
}

window.addProduct=async function(e){
  e.preventDefault();
  const row={
    name:$v('pName').value.trim(),
    category:$v('pCategory').value.trim()||null,
    cost:numV($v('pCost').value),
    price:numV($v('pPrice').value),
    stock:numV($v('pStock').value),
    min_stock:numV($v('pMin').value)
  };
  if(!row.name)return statusV6('Informe o nome do produto.',true);
  try{
    const {data,error}=await sbV6.from('products').insert(row).select().single();
    if(error)throw error;
    const file=$v('pImage')?.files?.[0];
    if(file){
      const imagePath=await uploadProductImage(file,data.id);
      const {error:imgErr}=await sbV6.from('products').update({image_path:imagePath}).eq('id',data.id);
      if(imgErr)throw imgErr;
    }
    if(row.stock)await sbV6.from('stock_moves').insert({product_id:data.id,move_type:'in',quantity:row.stock,reason:'Estoque inicial'});
    e.target.reset();
    statusV6('Produto cadastrado com sucesso.');
    setTimeout(()=>location.reload(),350);
  }catch(err){statusV6('Erro ao cadastrar produto: '+err.message,true);}
};

window.editProduct=async function(id){
  ensureV6Styles();
  const {data:p,error}=await sbV6.from('products').select('*').eq('id',id).single();
  if(error||!p)return statusV6('Não consegui carregar este produto: '+(error?.message||'produto não encontrado'),true);
  document.querySelector('.v6-modal-backdrop')?.remove();
  const backdrop=document.createElement('div');
  backdrop.className='v6-modal-backdrop';
  const currentUrl=productImageUrl(p.image_path);
  backdrop.innerHTML=`<div class="v6-modal">
    <h2>Editar produto</h2>
    <div class="v6-grid">
      <div class="field"><label>Nome</label><input id="epName"></div>
      <div class="field"><label>Categoria</label><input id="epCategory"></div>
      <div class="field"><label>Custo</label><input id="epCost" type="number" step="0.01" min="0"></div>
      <div class="field"><label>Preço de venda</label><input id="epPrice" type="number" step="0.01" min="0"></div>
      <div class="field"><label>Estoque mínimo</label><input id="epMin" type="number" step="0.001" min="0"></div>
      <div class="field"><label>Nova foto</label><input id="epImage" type="file" accept="image/*"></div>
    </div>
    <div style="margin-top:14px;display:flex;gap:14px;align-items:center;flex-wrap:wrap">
      ${currentUrl?`<img id="epPreview" class="v6-preview" src="${currentUrl}" alt="Foto atual">`:'<div id="epPreviewEmpty" class="muted">Produto ainda sem foto.</div>'}
      ${p.image_path?'<label><input id="epRemoveImage" type="checkbox"> Remover foto atual</label>':''}
    </div>
    <div class="v6-actions"><button id="epCancel" class="btn alt" type="button">Cancelar</button><button id="epSave" class="btn" type="button">Salvar alterações</button></div>
  </div>`;
  document.body.appendChild(backdrop);
  $v('epName').value=p.name||'';$v('epCategory').value=p.category||'';$v('epCost').value=numV(p.cost);$v('epPrice').value=numV(p.price);$v('epMin').value=numV(p.min_stock);
  $v('epCancel').onclick=()=>backdrop.remove();
  backdrop.onclick=e=>{if(e.target===backdrop)backdrop.remove()};
  $v('epImage').onchange=()=>{
    const f=$v('epImage').files?.[0];if(!f)return;
    const u=URL.createObjectURL(f);let img=$v('epPreview');
    if(!img){$v('epPreviewEmpty')?.remove();img=document.createElement('img');img.id='epPreview';img.className='v6-preview';backdrop.querySelector('.v6-actions').before(img);}
    img.src=u;
  };
  $v('epSave').onclick=async()=>{
    const btn=$v('epSave');btn.disabled=true;btn.textContent='Salvando...';
    try{
      let imagePath=p.image_path||null;
      const remove=$v('epRemoveImage')?.checked;
      const file=$v('epImage').files?.[0];
      if(remove&&imagePath){await sbV6.storage.from('product-images').remove([imagePath]);imagePath=null;}
      if(file){const newPath=await uploadProductImage(file,p.id);if(imagePath)await sbV6.storage.from('product-images').remove([imagePath]);imagePath=newPath;}
      const updates={name:$v('epName').value.trim(),category:$v('epCategory').value.trim()||null,cost:numV($v('epCost').value),price:numV($v('epPrice').value),min_stock:numV($v('epMin').value),image_path:imagePath};
      if(!updates.name)throw new Error('O nome não pode ficar vazio.');
      const {error:uErr}=await sbV6.from('products').update(updates).eq('id',p.id);if(uErr)throw uErr;
      // Mantém os nomes históricos coerentes quando o produto for renomeado.
      if(updates.name!==p.name){await sbV6.from('sale_items').update({product_name:updates.name}).eq('product_id',p.id);await sbV6.from('purchase_items').update({product_name:updates.name}).eq('product_id',p.id);}
      backdrop.remove();statusV6('Produto atualizado: nome, custo, preço e foto salvos.');setTimeout(()=>location.reload(),350);
    }catch(err){statusV6('Erro ao editar produto: '+err.message,true);btn.disabled=false;btn.textContent='Salvar alterações';}
  };
};

let photoRefreshTimer=null;
async function decorateProductTable(){
  if(photoRefreshTimer)clearTimeout(photoRefreshTimer);
  photoRefreshTimer=setTimeout(async()=>{
    const table=$v('productsTable');if(!table)return;
    const {data}=await sbV6.from('products').select('id,name,image_path');if(!data)return;
    const byName=new Map(data.map(p=>[String(p.name||'').trim(),p]));
    table.querySelectorAll('tbody tr').forEach(tr=>{
      const td=tr.querySelector('td');if(!td||td.dataset.v6decorated==='1')return;
      const name=td.textContent.trim(),p=byName.get(name);if(!p)return;
      td.dataset.v6decorated='1';
      const original=td.textContent;td.textContent='';
      const wrap=document.createElement('div');wrap.className='product-name-wrap';
      if(p.image_path){const img=document.createElement('img');img.className='product-photo';img.src=productImageUrl(p.image_path);img.alt=original;wrap.appendChild(img);}
      const span=document.createElement('span');span.textContent=original;wrap.appendChild(span);td.appendChild(wrap);
    });
  },120);
}

function ensureDashboardCards(){
  const cards=$v('dashboard')?.querySelector('.cards');if(!cards)return;
  const defs=[['kNetV6','Lucro após custos fixos'],['kPayableV6','Contas a pagar'],['kReceivableV6','Contas a receber'],['kLowStockV6','Produtos em estoque baixo']];
  for(const [id,label] of defs)if(!$v(id)){const c=document.createElement('div');c.className='card';c.innerHTML=`<div class="label">${label}</div><div id="${id}" class="value">—</div>`;cards.appendChild(c);}
}

async function refreshSmartDashboard(){
  ensureDashboardCards();
  const ym=new Date().toISOString().slice(0,7);
  const [salesR,fixedR,payR,recR,prodR]=await Promise.all([
    sbV6.from('sales').select('total,total_cost,sold_at'),sbV6.from('fixed_costs').select('amount,active'),sbV6.from('accounts_payable').select('amount,status'),sbV6.from('accounts_receivable').select('amount,status'),sbV6.from('products').select('stock,min_stock')
  ]);
  if([salesR,fixedR,payR,recR,prodR].some(x=>x.error))return;
  const sales=(salesR.data||[]).filter(s=>String(s.sold_at||'').slice(0,7)===ym),gross=sales.reduce((a,s)=>a+numV(s.total)-numV(s.total_cost),0),fixed=(fixedR.data||[]).filter(x=>x.active!==false).reduce((a,x)=>a+numV(x.amount),0),pay=(payR.data||[]).filter(x=>x.status==='open').reduce((a,x)=>a+numV(x.amount),0),rec=(recR.data||[]).filter(x=>x.status==='open').reduce((a,x)=>a+numV(x.amount),0),low=(prodR.data||[]).filter(x=>numV(x.stock)<=numV(x.min_stock)).length;
  if($v('kNetV6'))$v('kNetV6').textContent=moneyV(gross-fixed);
  if($v('kPayableV6'))$v('kPayableV6').textContent=moneyV(pay);
  if($v('kReceivableV6'))$v('kReceivableV6').textContent=moneyV(rec);
  if($v('kLowStockV6'))$v('kLowStockV6').textContent=String(low);
}

ensureV6Styles();
const boot=()=>{injectProductPhotoField();ensureDashboardCards();decorateProductTable();refreshSmartDashboard();
  const target=$v('productsTable');if(target)new MutationObserver(()=>decorateProductTable()).observe(target,{childList:true,subtree:true});
  setInterval(refreshSmartDashboard,60000);
};
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',()=>setTimeout(boot,300));else setTimeout(boot,300);
