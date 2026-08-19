-- CARTOES V3 - EDICAO, PAGAMENTO DE FATURA E COMPROVANTES
-- Execute uma vez no Supabase do projeto casal.

create extension if not exists pgcrypto;

create table if not exists public.personal_card_invoice_payments (
  id uuid primary key default gen_random_uuid(),
  card_id uuid not null references public.personal_cards(id) on delete cascade,
  invoice_month date not null,
  amount numeric(12,2) not null default 0 check (amount >= 0),
  paid_at date not null default current_date,
  receipt_path text,
  notes text,
  created_at timestamptz not null default now()
);

create index if not exists idx_card_invoice_payments_card_month
  on public.personal_card_invoice_payments(card_id, invoice_month);

alter table public.personal_card_invoice_payments enable row level security;

drop policy if exists personal_card_invoice_payments_admin on public.personal_card_invoice_payments;
create policy personal_card_invoice_payments_admin
on public.personal_card_invoice_payments
for all to authenticated
using (true)
with check (true);

-- Bucket privado para comprovantes de pagamento de faturas.
insert into storage.buckets (id, name, public)
values ('card-receipts','card-receipts',false)
on conflict (id) do nothing;

drop policy if exists card_receipts_select on storage.objects;
drop policy if exists card_receipts_insert on storage.objects;
drop policy if exists card_receipts_update on storage.objects;
drop policy if exists card_receipts_delete on storage.objects;

create policy card_receipts_select
on storage.objects for select to authenticated
using (bucket_id='card-receipts');

create policy card_receipts_insert
on storage.objects for insert to authenticated
with check (bucket_id='card-receipts');

create policy card_receipts_update
on storage.objects for update to authenticated
using (bucket_id='card-receipts')
with check (bucket_id='card-receipts');

create policy card_receipts_delete
on storage.objects for delete to authenticated
using (bucket_id='card-receipts');

notify pgrst,'reload schema';
