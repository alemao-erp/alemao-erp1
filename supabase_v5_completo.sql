-- ALEMÃO PRODUTOS DA ROÇA - ERP V5 COMPLETO
-- Execute APENAS este arquivo no SQL Editor do Supabase.
-- Pode ser reexecutado com segurança e corrige estruturas antigas.

create extension if not exists pgcrypto;

-- =========================================================
-- COMPRAS E ITENS
-- =========================================================
create table if not exists public.purchases (
  id uuid primary key default gen_random_uuid(),
  supplier_id uuid references public.suppliers(id) on delete set null,
  supplier_name text,
  total numeric(12,2) not null default 0,
  payment_status text not null default 'paid',
  due_date date,
  purchased_at timestamptz not null default now(),
  notes text,
  receipt_path text
);

-- Garante colunas mesmo quando a tabela purchases já existia em versão antiga
alter table public.purchases add column if not exists supplier_id uuid;
alter table public.purchases add column if not exists supplier_name text;
alter table public.purchases add column if not exists total numeric(12,2) not null default 0;
alter table public.purchases add column if not exists payment_status text not null default 'paid';
alter table public.purchases add column if not exists due_date date;
alter table public.purchases add column if not exists purchased_at timestamptz not null default now();
alter table public.purchases add column if not exists notes text;
alter table public.purchases add column if not exists receipt_path text;

create table if not exists public.purchase_items (
  id uuid primary key default gen_random_uuid(),
  purchase_id uuid not null references public.purchases(id) on delete cascade,
  product_id uuid references public.products(id) on delete set null,
  product_name text not null,
  quantity numeric(12,3) not null default 0,
  unit_cost numeric(12,2) not null default 0,
  total numeric(12,2) not null default 0
);

-- Garante colunas em purchase_items de versões antigas
alter table public.purchase_items add column if not exists purchase_id uuid;
alter table public.purchase_items add column if not exists product_id uuid;
alter table public.purchase_items add column if not exists product_name text;
alter table public.purchase_items add column if not exists quantity numeric(12,3) not null default 0;
alter table public.purchase_items add column if not exists unit_cost numeric(12,2) not null default 0;
alter table public.purchase_items add column if not exists total numeric(12,2) not null default 0;

-- =========================================================
-- CUSTOS FIXOS / PONTO DE EQUILÍBRIO
-- =========================================================
create table if not exists public.fixed_costs (
  id uuid primary key default gen_random_uuid(),
  description text not null,
  amount numeric(12,2) not null default 0,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.fixed_costs add column if not exists description text;
alter table public.fixed_costs add column if not exists amount numeric(12,2) not null default 0;
alter table public.fixed_costs add column if not exists active boolean not null default true;
alter table public.fixed_costs add column if not exists created_at timestamptz not null default now();

-- =========================================================
-- CAMPOS AUXILIARES E COMPROVANTES
-- =========================================================
alter table public.cash_transactions add column if not exists receipt_path text;
alter table public.purchases add column if not exists receipt_path text;
alter table public.accounts_payable add column if not exists receipt_path text;
alter table public.accounts_receivable add column if not exists receipt_path text;
alter table public.accounts_payable add column if not exists payment_method text;
alter table public.accounts_receivable add column if not exists payment_method text;
alter table public.accounts_receivable add column if not exists sale_id uuid;
alter table public.accounts_payable add column if not exists purchase_id uuid;

create table if not exists public.attachments (
  id uuid primary key default gen_random_uuid(),
  entity_type text not null,
  entity_id uuid not null,
  file_path text not null,
  file_name text,
  note text,
  created_at timestamptz not null default now()
);

-- =========================================================
-- EXTRATO BANCÁRIO / CONCILIAÇÃO
-- =========================================================
create table if not exists public.bank_transactions (
  id uuid primary key default gen_random_uuid(),
  txn_date date not null default current_date,
  description text not null,
  amount numeric(12,2) not null default 0,
  type text not null check (type in ('in','out')),
  source text not null default 'manual',
  external_id text,
  matched boolean not null default false,
  created_at timestamptz not null default now()
);

-- Garante colunas em caso de tabela antiga
alter table public.bank_transactions add column if not exists txn_date date not null default current_date;
alter table public.bank_transactions add column if not exists description text;
alter table public.bank_transactions add column if not exists amount numeric(12,2) not null default 0;
alter table public.bank_transactions add column if not exists type text;
alter table public.bank_transactions add column if not exists source text not null default 'manual';
alter table public.bank_transactions add column if not exists external_id text;
alter table public.bank_transactions add column if not exists matched boolean not null default false;
alter table public.bank_transactions add column if not exists created_at timestamptz not null default now();

-- =========================================================
-- ÍNDICES - SOMENTE DEPOIS DE GARANTIR AS COLUNAS
-- =========================================================
create unique index if not exists idx_bank_external_id on public.bank_transactions(external_id) where external_id is not null;
create index if not exists idx_bank_date on public.bank_transactions(txn_date);
create index if not exists idx_attachments_entity on public.attachments(entity_type,entity_id);
create index if not exists idx_purchases_date on public.purchases(purchased_at);
create index if not exists idx_purchase_items_purchase on public.purchase_items(purchase_id);
create index if not exists idx_accounts_payable_due on public.accounts_payable(due_date);
create index if not exists idx_accounts_receivable_due on public.accounts_receivable(due_date);

-- =========================================================
-- RLS
-- =========================================================
alter table public.purchases enable row level security;
alter table public.purchase_items enable row level security;
alter table public.fixed_costs enable row level security;
alter table public.attachments enable row level security;
alter table public.bank_transactions enable row level security;

drop policy if exists "admin_purchases" on public.purchases;
drop policy if exists "admin_purchase_items" on public.purchase_items;
drop policy if exists "admin_fixed_costs" on public.fixed_costs;
drop policy if exists "admin_attachments" on public.attachments;
drop policy if exists "admin_bank_transactions" on public.bank_transactions;

create policy "admin_purchases" on public.purchases for all to authenticated
using (auth.uid()='fd1121db-f0b6-4fee-9a8d-dcb23fcb0a69'::uuid)
with check (auth.uid()='fd1121db-f0b6-4fee-9a8d-dcb23fcb0a69'::uuid);

create policy "admin_purchase_items" on public.purchase_items for all to authenticated
using (auth.uid()='fd1121db-f0b6-4fee-9a8d-dcb23fcb0a69'::uuid)
with check (auth.uid()='fd1121db-f0b6-4fee-9a8d-dcb23fcb0a69'::uuid);

create policy "admin_fixed_costs" on public.fixed_costs for all to authenticated
using (auth.uid()='fd1121db-f0b6-4fee-9a8d-dcb23fcb0a69'::uuid)
with check (auth.uid()='fd1121db-f0b6-4fee-9a8d-dcb23fcb0a69'::uuid);

create policy "admin_attachments" on public.attachments for all to authenticated
using (auth.uid()='fd1121db-f0b6-4fee-9a8d-dcb23fcb0a69'::uuid)
with check (auth.uid()='fd1121db-f0b6-4fee-9a8d-dcb23fcb0a69'::uuid);

create policy "admin_bank_transactions" on public.bank_transactions for all to authenticated
using (auth.uid()='fd1121db-f0b6-4fee-9a8d-dcb23fcb0a69'::uuid)
with check (auth.uid()='fd1121db-f0b6-4fee-9a8d-dcb23fcb0a69'::uuid);

-- =========================================================
-- BUCKET PRIVADO DE COMPROVANTES
-- =========================================================
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('receipts','receipts',false,10485760,array['image/jpeg','image/png','image/webp','application/pdf'])
on conflict(id) do update set
  public=false,
  file_size_limit=10485760,
  allowed_mime_types=array['image/jpeg','image/png','image/webp','application/pdf'];

drop policy if exists "admin_receipts_select" on storage.objects;
drop policy if exists "admin_receipts_insert" on storage.objects;
drop policy if exists "admin_receipts_update" on storage.objects;
drop policy if exists "admin_receipts_delete" on storage.objects;

create policy "admin_receipts_select" on storage.objects for select to authenticated
using(bucket_id='receipts' and auth.uid()='fd1121db-f0b6-4fee-9a8d-dcb23fcb0a69'::uuid);

create policy "admin_receipts_insert" on storage.objects for insert to authenticated
with check(bucket_id='receipts' and auth.uid()='fd1121db-f0b6-4fee-9a8d-dcb23fcb0a69'::uuid and (storage.foldername(name))[1]=auth.uid()::text);

create policy "admin_receipts_update" on storage.objects for update to authenticated
using(bucket_id='receipts' and auth.uid()='fd1121db-f0b6-4fee-9a8d-dcb23fcb0a69'::uuid)
with check(bucket_id='receipts' and auth.uid()='fd1121db-f0b6-4fee-9a8d-dcb23fcb0a69'::uuid);

create policy "admin_receipts_delete" on storage.objects for delete to authenticated
using(bucket_id='receipts' and auth.uid()='fd1121db-f0b6-4fee-9a8d-dcb23fcb0a69'::uuid);

-- Atualiza o cache da API do Supabase
notify pgrst,'reload schema';
