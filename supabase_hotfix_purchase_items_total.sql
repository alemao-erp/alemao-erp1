-- HOTFIX: permite que o ERP grave o total dos itens de compra.
-- O app.js atual envia o campo total ao salvar/editar uma compra.
-- Se purchase_items.total estiver como coluna GENERATED, o PostgreSQL rejeita o INSERT.

begin;

alter table public.purchase_items
  alter column total drop expression;

-- Garante total preenchido para registros existentes e futuros enviados pelo ERP.
update public.purchase_items
set total = coalesce(quantity, 0) * coalesce(unit_cost, 0)
where total is null;

commit;
