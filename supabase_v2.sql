-- ALEMÃO PRODUTOS DA ROÇA - ERP V2
-- Execute no SQL Editor do Supabase. Pode ser reexecutado com segurança.

create extension if not exists pgcrypto;

-- Compras / entradas de mercadorias
create table if not exists public.purchases (
  id uuid primary key default gen_random_uuid(),
  supplier_id uuid references public.suppliers(id) on delete set null,
  supplier_name text,
  total numeric(12,2) not null default 0,
  payment_status text not null default 'paid',
  due_date date,
  purchased_at timestamptz not null default now(),
  notes text
);

create table if not exists public.purchase_items (
  id uuid primary key default gen_random_uuid(),
  purchase_id uuid not null references public.purchases(id) on delete cascade,
  product_id uuid references public.products(id) on delete set null,
  product_name text not null,
  quantity numeric(12,3) not null default 0,
  unit_cost numeric(12,2) not null default 0,
  total numeric(12,2) not null default 0
);

-- Custos fixos para cálculo do ponto de equilíbrio
create table if not exists public.fixed_costs (
  id uuid primary key default gen_random_uuid(),
  description text not null,
  amount numeric(12,2) not null default 0,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

-- Campos extras úteis
alter table public.accounts_payable add column if not exists payment_method text;
alter table public.accounts_receivable add column if not exists payment_method text;
alter table public.accounts_receivable add column if not exists sale_id uuid;
alter table public.accounts_payable add column if not exists purchase_id uuid;

create index if not exists idx_purchases_date on public.purchases(purchased_at);
create index if not exists idx_purchase_items_purchase on public.purchase_items(purchase_id);
create index if not exists idx_accounts_payable_due on public.accounts_payable(due_date);
create index if not exists idx_accounts_receivable_due on public.accounts_receivable(due_date);

-- RLS
alter table public.purchases enable row level security;
alter table public.purchase_items enable row level security;
alter table public.fixed_costs enable row level security;

-- Políticas para o usuário administrador atual
DROP POLICY IF EXISTS "admin_purchases" ON public.purchases;
DROP POLICY IF EXISTS "admin_purchase_items" ON public.purchase_items;
DROP POLICY IF EXISTS "admin_fixed_costs" ON public.fixed_costs;

CREATE POLICY "admin_purchases" ON public.purchases
FOR ALL TO authenticated
USING (auth.uid() = 'fd1121db-f0b6-4fee-9a8d-dcb23fcb0a69'::uuid)
WITH CHECK (auth.uid() = 'fd1121db-f0b6-4fee-9a8d-dcb23fcb0a69'::uuid);

CREATE POLICY "admin_purchase_items" ON public.purchase_items
FOR ALL TO authenticated
USING (auth.uid() = 'fd1121db-f0b6-4fee-9a8d-dcb23fcb0a69'::uuid)
WITH CHECK (auth.uid() = 'fd1121db-f0b6-4fee-9a8d-dcb23fcb0a69'::uuid);

CREATE POLICY "admin_fixed_costs" ON public.fixed_costs
FOR ALL TO authenticated
USING (auth.uid() = 'fd1121db-f0b6-4fee-9a8d-dcb23fcb0a69'::uuid)
WITH CHECK (auth.uid() = 'fd1121db-f0b6-4fee-9a8d-dcb23fcb0a69'::uuid);

notify pgrst, 'reload schema';
