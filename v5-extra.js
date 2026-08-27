(()=>{
  function waitReady(){
    if(typeof DB==='undefined'||typeof money==='undefined'||typeof num==='undefined'||typeof inRange==='undefined'||!document.getElementById('dashboard')){
      return setTimeout(waitReady,150);
    }
    setupV5();
  }

  function addCard(id,label){
    if(document.getElementById(id)) return;
    const cards=document.querySelector('#dashboard .cards');
    if(!cards) return;
    const d=document.createElement('div');
    d.className='card';
    d.innerHTML='<div class="label">'+label+'</div><div id="'+id+'" class="value">—</div>';
    cards.appendChild(d);
  }

  function ensureFinancialPanel(){
    if(document.getElementById('v5FinancePanel')) return;
    const recent=document.getElementById('recent');
    if(!recent) return;
    const panel=document.createElement('div');
    panel.id='v5FinancePanel';
    panel.className='panel';
    panel.innerHTML='<h3>⚙ Configuração financeira</h3><div class="grid3"><div class="field"><label>Custos fixos mensais (R$)</label><input id="fixedCosts" type="number" min="0" step="0.01" placeholder="Ex.: 800"></div><div class="field"><label>Como funciona</label><div class="notice">Informe os custos fixos do mês para calcular lucro líquido e ponto de equilíbrio.</div></div><div><button class="btn alt" id="saveFixedCosts">Salvar custos fixos</button></div></div>';
    const recentPanel=recent.closest('.panel');
    recentPanel.parentNode.insertBefore(panel,recentPanel);
    const f=document.getElementById('fixedCosts');
    f.value=localStorage.getItem('erp_fixed_costs')||'';
    document.getElementById('saveFixedCosts').onclick=()=>{
      localStorage.setItem('erp_fixed_costs',String(num(f.value)));
      updateMetrics();
      if(typeof msg==='function') msg('Custos fixos salvos.');
    };
  }

  function updateMetrics(){
    try{
      addCard('kNet','Lucro líquido período');
      addCard('kNetMargin','Margem líquida');
      addCard('kBreakEven','Ponto de equilíbrio mensal');
      addCard('kToBreak','Falta vender para empatar');
      ensureFinancialPanel();

      const from=document.getElementById('dashFrom')?.value||'';
      const to=document.getElementById('dashTo')?.value||'';
      const sales=(DB.sales||[]).filter(s=>inRange(s.sold_at||s.created_at,from,to));
      const rev=sales.reduce((a,s)=>a+num(s.total),0);
      const cmv=sales.reduce((a,s)=>a+(typeof saleCost==='function'?saleCost(s):0),0);
      const expenses=(DB.cash_transactions||[])
        .filter(x=>x.type==='out'&&inRange(x.created_at,from,to))
        .reduce((a,x)=>a+num(x.amount),0);
      const gross=rev-cmv;
      const net=gross-expenses;
      const contribution=rev>0?gross/rev:0;
      const fixed=num(localStorage.getItem('erp_fixed_costs')||0);
      const breakEven=contribution>0?fixed/contribution:0;
      const toBreak=Math.max(0,breakEven-rev);

      const set=(id,val)=>{const e=document.getElementById(id);if(e)e.textContent=val};
      set('kNet',money(net));
      set('kNetMargin',rev?((net/rev)*100).toFixed(1)+'%':'0%');
      set('kBreakEven',money(breakEven));
      set('kToBreak',money(toBreak));
    }catch(e){console.warn('V5 métricas:',e)}
  }

  window.printSale=function(id){
    const s=(DB.sales||[]).find(x=>String(x.id)===String(id));
    if(!s) return typeof msg==='function'&&msg('Venda não encontrada.',true);
    const items=(DB.sale_items||[]).filter(i=>String(i.sale_id)===String(id));
    const lines=items.map(i=>'<tr><td>'+esc(i.product_name||'Produto')+'</td><td>'+num(i.quantity)+'</td><td>'+money(i.unit_price)+'</td><td>'+money(i.subtotal||num(i.quantity)*num(i.unit_price))+'</td></tr>').join('');
    const w=window.open('','_blank','width=820,height=720');
    if(!w) return typeof msg==='function'&&msg('Permita pop-ups para imprimir.',true);
    w.document.write('<!doctype html><html><head><meta charset="utf-8"><title>Comprovante de venda</title><style>body{font-family:Arial;padding:28px;color:#172033}h1{margin-bottom:4px}.muted{color:#667085}table{width:100%;border-collapse:collapse;margin-top:18px}th,td{padding:9px;border-bottom:1px solid #ddd;text-align:left}.total{font-size:20px;font-weight:700;margin-top:18px}.box{border:1px solid #ddd;border-radius:10px;padding:14px;margin-top:12px}@media print{button{display:none}}</style></head><body><h1>Alemão Produtos da Roça</h1><div class="muted">Comprovante de venda</div><div class="box"><b>Data:</b> '+dateBR(s.sold_at||s.created_at)+'<br><b>Cliente:</b> '+esc(s.client_name||'Cliente balcão')+'<br><b>Pagamento:</b> '+esc(s.payment_method||'-')+'<br><b>Observação:</b> '+esc(s.notes||s.observation||'-')+'</div><table><thead><tr><th>Produto</th><th>Qtd.</th><th>Unitário</th><th>Subtotal</th></tr></thead><tbody>'+lines+'</tbody></table><div class="total">Total: '+money(s.total)+'</div><p>Obrigado pela preferência!</p><button onclick="window.print()">Imprimir / Salvar em PDF</button></body></html>');
    w.document.close();
  };

  function addPrintButtons(){
    const table=document.querySelector('#salesTable table tbody');
    if(!table) return;
    const q=(document.getElementById('saleSearch')?.value||'').toLowerCase();
    const rows=(DB.sales||[]).filter(s=>(String(s.client_name||'')+' '+String(s.payment_method||'')).toLowerCase().includes(q)).slice().sort((a,b)=>new Date(b.sold_at||0)-new Date(a.sold_at||0));
    [...table.querySelectorAll('tr')].forEach((tr,i)=>{
      const s=rows[i]; if(!s) return;
      const cell=tr.lastElementChild; if(!cell||cell.querySelector('.v5-print')) return;
      const b=document.createElement('button');
      b.className='btn alt sm v5-print';
      b.textContent='Imprimir';
      b.onclick=()=>window.printSale(s.id);
      const actions=cell.querySelector('.actions')||cell;
      actions.insertBefore(b,actions.firstChild);
    });
  }

  function setupV5(){
    addCard('kNet','Lucro líquido período');
    addCard('kNetMargin','Margem líquida');
    addCard('kBreakEven','Ponto de equilíbrio mensal');
    addCard('kToBreak','Falta vender para empatar');
    ensureFinancialPanel();
    updateMetrics();
    addPrintButtons();

    if(typeof dashboard==='function'){
      const oldDash=dashboard;
      dashboard=function(){const r=oldDash.apply(this,arguments);setTimeout(updateMetrics,0);return r};
    }
    if(typeof renderSales==='function'){
      const oldSales=renderSales;
      renderSales=function(){const r=oldSales.apply(this,arguments);setTimeout(addPrintButtons,0);return r};
    }
    setInterval(()=>{updateMetrics();addPrintButtons()},2000);
  }

  waitReady();
})();