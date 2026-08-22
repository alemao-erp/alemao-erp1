// V13 - ordenacao alfabetica de produtos, clientes e fornecedores

function key13(text){
  return String(text||'').trim().normalize('NFD').replace(/[\u0300-\u036f]/g,'').toLocaleLowerCase('pt-BR');
}

function sortSelect13(select, keepFirst=false){
  if(!select || select.dataset.sorted13==='working') return;
  const current=select.value;
  const opts=[...select.options];
  if(opts.length<2) return;
  const fixed=keepFirst?[opts.shift()]:[];
  opts.sort((a,b)=>key13(a.textContent).localeCompare(key13(b.textContent),'pt-BR',{sensitivity:'base',numeric:true}));
  select.dataset.sorted13='working';
  select.replaceChildren(...fixed,...opts);
  if(current && [...select.options].some(o=>o.value===current)) select.value=current;
  delete select.dataset.sorted13;
}

function sortTable13(containerId){
  const box=document.getElementById(containerId);
  const tbody=box?.querySelector('tbody');
  if(!tbody) return;
  const rows=[...tbody.querySelectorAll(':scope > tr')];
  if(rows.length<2) return;
  rows.sort((a,b)=>{
    // Procura a primeira celula textual relevante, ignorando coluna que contenha apenas foto/botoes.
    const textA=[...a.cells].map(c=>c.innerText.trim()).find(t=>t && !/^editar|excluir|ações|acoes$/i.test(t))||'';
    const textB=[...b.cells].map(c=>c.innerText.trim()).find(t=>t && !/^editar|excluir|ações|acoes$/i.test(t))||'';
    return key13(textA).localeCompare(key13(textB),'pt-BR',{sensitivity:'base',numeric:true});
  });
  rows.forEach(r=>tbody.appendChild(r));
}

function applyAlphabetical13(){
  sortSelect13(document.getElementById('saleClient'),true);
  sortSelect13(document.getElementById('purchaseSupplier'),true);
  sortSelect13(document.getElementById('stockProduct'),false);
  document.querySelectorAll('.sale-prod,.purchase-prod').forEach(s=>sortSelect13(s,false));

  sortTable13('productsTable');
  sortTable13('clientsTable');
  sortTable13('suppliersTable');
}

let timer13=null;
function schedule13(){
  clearTimeout(timer13);
  timer13=setTimeout(applyAlphabetical13,80);
}

if(document.readyState==='loading') document.addEventListener('DOMContentLoaded',()=>setTimeout(applyAlphabetical13,500));
else setTimeout(applyAlphabetical13,500);

const observer13=new MutationObserver(schedule13);
observer13.observe(document.documentElement,{subtree:true,childList:true});

document.addEventListener('input',e=>{
  if(['productSearch','clientSearch','supplierSearch'].includes(e.target?.id)) setTimeout(applyAlphabetical13,30);
});

import './app-v14.js';
