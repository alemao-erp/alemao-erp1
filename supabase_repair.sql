-- ALEMÃO PRODUTOS DA ROÇA
-- REPARO COMPLETO DE COMPATIBILIDADE DO BANCO
-- Pode ser executado mais de uma vez com segurança.

create extension if not exists pgcrypto;

-- 1) PRODUTOS
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
alter table public.products add column if not exists name text;
alter table public.products add column if not exists category text;
alter table public.products add column if not exists cost numeric(12,2) default 0;
alter table public.products add column if not exists price numeric(12,2) default 0;
alter table public.products add column if not exists stock numeric(12,3) default 0;
alter table public.products add column if not exists min_stock numeric(12,3) default 0;
alter table public.products add column if not exists active boolean default true;
alter table public.products add column if not exists created_at timestamptz default now();

-- 2) CLIENTES
create table if not exists public.clients (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  phone text,
  location text,
  notes text,
  created_at timestamptz not null default now()
);
alter table public.clients add column if not exists name text;
alter table public.clients add column if not exists phone text;
alter table public.clients add column if not exists location text;
alter table public.clients add column if not exists notes text;
alter table public.clients add column if not exists created_at timestamptz default now();

-- 3) FORNECEDORES
create table if not exists public.suppliers (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  phone text,
  document text,
  notes text,
  created_at timestamptz not null default now()
);
alter table public.suppliers add column if not exists name text;
alter table public.suppliers add column if not exists phone text;
alter table public.suppliers add column if not exists document text;
alter table public.suppliers add column if not exists notes text;
alter table public.suppliers add column if not exists created_at timestamptz default now();

-- 4) VENDAS
create table if not exists public.sales (
  id uuid primary key default gen_random_uuid(),
  client_id uuid,
  client_name text,
  payment_method text,
  total numeric(12,2) default 0,
  total_cost numeric(12,2) default 0,
  status text default 'completed',
  sold_at timestamptz default now(),
  notes text
);
alter table public.sales add column if not exists client_id uuid;
alter table public.sales add column if not exists client_name text;
alter table public.sales add column if not exists payment_method text;
alter table public.sales add column if not exists total numeric(12,2) default 0;
alter table public.sales add column if not exists total_cost numeric(12,2) default 0;
alter table public.sales add column if not exists status text default 'completed';
alter table public.sales add column if not exists sold_at timestamptz default now();
alter table public.sales add column if not exists notes text;

-- 5) ITENS DA VENDA
create table if not exists public.sale_items (
  id uuid primary key default gen_random_uuid(),
  sale_id uuid,
  product_id uuid,
  product_name text,
  quantity numeric(12,3) default 0,
  unit_price numeric(12,2) default 0,
  unit_cost numeric(12,2) default 0,
  total numeric(12,2) default 0,
  total_cost numeric(12,2) default 0,
  created_at timestamptz default now()
);
alter table public.sale_items add column if not exists sale_id uuid;
alter table public.sale_items add column if not exists product_id uuid;
alter table public.sale_items add column if not exists product_name text;
alter table public.sale_items add column if not exists quantity numeric(12,3) default 0;
alter table public.sale_items add column if not exists unit_price numeric(12,2) default 0;
alter table public.sale_items add column if not exists unit_cost numeric(12,2) default 0;
alter table public.sale_items add column if not exists total numeric(12,2) default 0;
alter table public.sale_items add column if not exists total_cost numeric(12,2) default 0;
alter table public.sale_items add column if not exists created_at timestamptz default now();

-- 6) MOVIMENTAÇÕES DE ESTOQUE
create table if not exists public.stock_moves (
  id uuid primary key default gen_random_uuid(),
  product_id uuid,
  move_type text,
  quantity numeric(12,3) default 0,
  reason text,
  created_at timestamptz default now()
);
alter table public.stock_moves add column if not exists product_id uuid;
alter table public.stock_moves add column if not exists move_type text;
alter table public.stock_moves add column if not exists quantity numeric(12,3) default 0;
alter table public.stock_moves add column if not exists reason text;
alter table public.stock_moves add column if not exists created_at timestamptz default now();

-- 7) CAIXA
create table if not exists public.cash_transactions (
  id uuid primary key default gen_random_uuid(),
  type text,
  amount numeric(12,2) default 0,
  description text,
  payment_method text,
  reference_id uuid,
  created_at timestamptz default now()
);
alter table public.cash_transactions add column if not exists type text;
alter table public.cash_transactions add column if not exists amount numeric(12,2) default 0;
alter table public.cash_transactions add column if not exists description text;
alter table public.cash_transactions add column if not exists payment_method text;
alter table public.cash_transactions add column if not exists reference_id uuid;
alter table public.cash_transactions add column if not exists created_at timestamptz default now();

-- 8) CONTAS A PAGAR
create table if not exists public.accounts_payable (
  id uuid primary key default gen_random_uuid(),
  supplier_id uuid,
  description text,
  amount numeric(12,2) default 0,
  due_date date,
  status text default 'open',
  paid_at timestamptz,
  created_at timestamptz default now()
);
alter table public.accounts_payable add column if not exists supplier_id uuid;
alter table public.accounts_payable add column if not exists description text;
alter table public.accounts_payable add column if not exists amount numeric(12,2) default 0;
alter table public.accounts_payable add column if not exists due_date date;
alter table public.accounts_payable add column if not exists status text default 'open';
alter table public.accounts_payable add column if not exists paid_at timestamptz;
alter table public.accounts_payable add column if not exists created_at timestamptz default now();

-- 9) CONTAS A RECEBER
create table if not exists public.accounts_receivable (
  id uuid primary key default gen_random_uuid(),
  client_id uuid,
  description text,
  amount numeric(12,2) default 0,
  due_date date,
  status text default 'open',
  received_at timestamptz,
  created_at timestamptz default now()
);
alter table public.accounts_receivable add column if not exists client_id uuid;
alter table public.accounts_receivable add column if not exists description text;
alter table public.accounts_receivable add column if not exists amount numeric(12,2) default 0;
alter table public.accounts_receivable add column if not exists due_date date;
alter table public.accounts_receivable add column if not exists status text default 'open';
alter table public.accounts_receivable add column if not exists received_at timestamptz;
alter table public.accounts_receivable add column if not exists created_at timestamptz default now();

-- Índices usados pelo aplicativo
create index if not exists idx_products_name on public.products(name);
create index if not exists idx_clients_name on public.clients(name);
create index if not exists idx_sales_sold_at on public.sales(sold_at);
create index if not exists idx_sale_items_sale on public.sale_items(sale_id);
create index if not exists idx_stock_moves_product on public.stock_moves(product_id);
create index if not exists idx_cash_transactions_created_at on public.cash_transactions(created_at);

-- RLS
alter table public.products enable row level security;
alter table public.clients enable row level security;
alter table public.suppliers enable row level security;
alter table public.sales enable row level security;
alter table public.sale_items enable row level security;
alter table public.stock_moves enable row level security;
alter table public.cash_transactions enable row level security;
alter table public.accounts_payable enable row level security;
alter table public.accounts_receivable enable row level security;

-- Atualiza o cache da API do Supabase/PostgREST
notify pgrst, 'reload schema';
