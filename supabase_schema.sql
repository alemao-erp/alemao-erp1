-- ALEMÃO PRODUTOS DA ROÇA
-- Banco inicial para Supabase/PostgreSQL
-- Execute este arquivo no SQL Editor do Supabase.

create extension if not exists pgcrypto;

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category text,
  cost numeric(12,2) not null default 0,
  price numeric(12,2) not null default 0,
  stock numeric(12,3) not null default 0,
  min_stock numeric(12,3) not null default 0,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.clients (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  phone text,
  location text,
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists public.suppliers (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  phone text,
  document text,
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists public.sales (
  id uuid primary key default gen_random_uuid(),
  client_id uuid references public.clients(id) on delete set null,
  client_name text,
  payment_method text not null default 'Pix',
  total numeric(12,2) not null default 0,
  total_cost numeric(12,2) not null default 0,
  status text not null default 'completed',
  sold_at timestamptz not null default now(),
  notes text
);

create table if not exists public.sale_items (
  id uuid primary key default gen_random_uuid(),
  sale_id uuid not null references public.sales(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete restrict,
  product_name text not null,
  quantity numeric(12,3) not null,
  unit_price numeric(12,2) not null,
  unit_cost numeric(12,2) not null,
  total numeric(12,2) not null,
  total_cost numeric(12,2) not null
);

create table if not exists public.stock_moves (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  move_type text not null check (move_type in ('in','out','adjust')),
  quantity numeric(12,3) not null,
  reason text,
  created_at timestamptz not null default now()
);

create table if not exists public.cash_transactions (
  id uuid primary key default gen_random_uuid(),
  type text not null check (type in ('in','out')),
  amount numeric(12,2) not null,
  description text not null,
  payment_method text,
  reference_id uuid,
  created_at timestamptz not null default now()
);

create table if not exists public.accounts_payable (
  id uuid primary key default gen_random_uuid(),
  supplier_id uuid references public.suppliers(id) on delete set null,
  description text not null,
  amount numeric(12,2) not null,
  due_date date,
  status text not null default 'open',
  paid_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.accounts_receivable (
  id uuid primary key default gen_random_uuid(),
  client_id uuid references public.clients(id) on delete set null,
  description text not null,
  amount numeric(12,2) not null,
  due_date date,
  status text not null default 'open',
  received_at timestamptz,
  created_at timestamptz not null default now()
);

-- Índices básicos para consultas do dashboard.
create index if not exists idx_products_name on public.products(name);
create index if not exists idx_clients_name on public.clients(name);
create index if not exists idx_sales_sold_at on public.sales(sold_at);
create index if not exists idx_sale_items_sale on public.sale_items(sale_id);
create index if not exists idx_stock_moves_product on public.stock_moves(product_id);
create index if not exists idx_cash_transactions_created_at on public.cash_transactions(created_at);

-- RLS: nesta primeira etapa deixamos as tabelas protegidas.
-- Na próxima etapa vamos criar autenticação e políticas para o usuário logado.
alter table public.products enable row level security;
alter table public.clients enable row level security;
alter table public.suppliers enable row level security;
alter table public.sales enable row level security;
alter table public.sale_items enable row level security;
alter table public.stock_moves enable row level security;
alter table public.cash_transactions enable row level security;
alter table public.accounts_payable enable row level security;
alter table public.accounts_receivable enable row level security;
