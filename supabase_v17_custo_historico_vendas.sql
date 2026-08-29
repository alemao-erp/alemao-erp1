-- V17 - custo histórico dos itens vendidos
-- Execute no SQL Editor do Supabase para preservar o custo do produto no momento de cada venda.
alter table public.sale_items
add column if not exists unit_cost numeric;

create index if not exists sale_items_sale_id_idx on public.sale_items(sale_id);
create index if not exists sale_items_product_id_idx on public.sale_items(product_id);
