(()=>{
  function waitReady(){
    if(typeof DB==='undefined'||typeof $==='undefined'||typeof insert==='undefined'||typeof updateRow==='undefined'||typeof req==='undefined'||typeof num==='undefined') return setTimeout(waitReady,150);
    install();
  }

  async function saveSaleCompat(){
    const d=saleDraft();
    if(!d.items.length) return msg('Adicione ao menos um produto.',true);
    let createdId=null;
    try{
      const c=(DB.clients||[]).find(x=>x.id===$('saleClient').value);
      const date=$('saleDate').value?new Date($('saleDate').value).toISOString():new Date().toISOString();
      const receipt=await uploadReceipt($('saleReceipt').files[0],'venda');
      const row={client_id:c?.id||null,client_name:c?.name||'Cliente balcão',payment_method:$('salePay').value,total:d.total,sold_at:date};
      const extras={discount:d.disc,discount_type:$('saleDiscountType').value,notes:$('saleNotes').value.trim()||null};
      if(receipt) extras.receipt_path=receipt;

      if(editingSale){
        for(const old of (DB.sale_items||[]).filter(i=>i.sale_id===editingSale)){
          const p=(DB.products||[]).find(x=>x.id===old.product_id);
          if(p) await updateRow('products',p.id,{stock:num(p.stock)+num(old.quantity)});
        }
        await req('/rest/v1/sale_items?sale_id=eq.'+encodeURIComponent(editingSale),{method:'DELETE'});
        try{await updateRow('sales',editingSale,{...row,...extras})}catch{await updateRow('sales',editingSale,row)}
        for(const i of d.items){
          const p=(DB.products||[]).find(x=>x.id===i.product_id);
          await insert('sale_items',{sale_id:editingSale,product_id:p.id,product_name:p.name,quantity:i.quantity,unit_price:i.unit_price});
          await updateRow('products',p.id,{stock:num(p.stock)-i.quantity});
        }
      }else{
        let created;
        try{created=(await insert('sales',{...row,...extras}))[0]}catch{created=(await insert('sales',row))[0]}
        createdId=created?.id;
        if(!createdId) throw new Error('A venda foi criada sem identificador.');
        for(const i of d.items){
          const p=(DB.products||[]).find(x=>x.id===i.product_id);
          await insert('sale_items',{sale_id:createdId,product_id:p.id,product_name:p.name,quantity:i.quantity,unit_price:i.unit_price});
          await updateRow('products',p.id,{stock:num(p.stock)-i.quantity});
        }
      }
      resetSale();
      await load();
      go('vendas');
      msg('Venda salva com sucesso.');
    }catch(e){
      if(createdId){
        try{await req('/rest/v1/sale_items?sale_id=eq.'+encodeURIComponent(createdId),{method:'DELETE'})}catch{}
        try{await del('sales',createdId)}catch{}
      }
      msg('Erro ao salvar venda: '+e.message,true);
    }
  }

  async function savePurchaseCompat(){
    const d=purchaseDraft();
    if(!d.items.length) return msg('Adicione ao menos um produto.',true);
    let createdId=null;
    try{
      const s=(DB.suppliers||[]).find(x=>x.id===$('purchaseSupplier').value);
      const date=$('purchaseDate').value?new Date($('purchaseDate').value).toISOString():new Date().toISOString();
      const receipt=await uploadReceipt($('purchaseReceipt').files[0],'compra');
      const row={supplier_id:s?.id||null,supplier_name:s?.name||null,payment_status:$('purchaseStatus').value,due_date:$('purchaseDue').value||null,total:d.total,purchased_at:date};
      if(receipt) row.receipt_path=receipt;

      if(editingPurchase){
        for(const old of (DB.purchase_items||[]).filter(i=>i.purchase_id===editingPurchase)){
          const p=(DB.products||[]).find(x=>x.id===old.product_id);
          if(p) await updateRow('products',p.id,{stock:num(p.stock)-num(old.quantity)});
        }
        await req('/rest/v1/purchase_items?purchase_id=eq.'+encodeURIComponent(editingPurchase),{method:'DELETE'});
        await updateRow('purchases',editingPurchase,row);
        for(const i of d.items){
          const p=(DB.products||[]).find(x=>x.id===i.product_id);
          await insert('purchase_items',{purchase_id:editingPurchase,product_id:p.id,product_name:p.name,quantity:i.quantity,unit_cost:i.unit_cost});
          await updateRow('products',p.id,{stock:num(p.stock)+i.quantity,cost:i.unit_cost});
        }
      }else{
        const created=(await insert('purchases',row))[0];
        createdId=created?.id;
        if(!createdId) throw new Error('A compra foi criada sem identificador.');
        for(const i of d.items){
          const p=(DB.products||[]).find(x=>x.id===i.product_id);
          await insert('purchase_items',{purchase_id:createdId,product_id:p.id,product_name:p.name,quantity:i.quantity,unit_cost:i.unit_cost});
          await updateRow('products',p.id,{stock:num(p.stock)+i.quantity,cost:i.unit_cost});
        }
      }
      resetPurchase();
      await load();
      go('compras');
      msg('Compra salva com sucesso.');
    }catch(e){
      if(createdId){
        try{await req('/rest/v1/purchase_items?purchase_id=eq.'+encodeURIComponent(createdId),{method:'DELETE'})}catch{}
        try{await del('purchases',createdId)}catch{}
      }
      msg('Erro ao salvar compra: '+e.message,true);
    }
  }

  function install(){
    const saleBtn=$('saveSale');
    const purchaseBtn=$('savePurchase');
    if(saleBtn) saleBtn.onclick=saveSaleCompat;
    if(purchaseBtn) purchaseBtn.onclick=savePurchaseCompat;
    window.saveSaleCompat=saveSaleCompat;
    window.savePurchaseCompat=savePurchaseCompat;
    console.log('V5 compatibilidade de schema instalada.');
  }

  waitReady();
})();