-- IGOR & LARISSA - GESTAO FINANCEIRA
-- Execute no SQL Editor do Supabase. Pode ser reexecutado com seguranca.
create extension if not exists pgcrypto;

create table if not exists public.personal_income (
  id uuid primary key default gen_random_uuid(),
  person text not null check (person in ('Igor','Larissa','Casal')),
  description text not null,
  amount numeric(12,2) not null default 0,
  income_date date not null default current_date,
  recurring boolean not null default false,
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists public.personal_expenses (
  id uuid primary key default gen_random_uuid(),
  person text not null default 'Casal' check (person in ('Igor','Larissa','Casal')),
  description text not null,
  category text not null default 'Outros',
  amount numeric(12,2) not null default 0,
  expense_date date not null default current_date,
  due_date date,
  paid boolean not null default true,
  paid_at date,
  recurring boolean not null default false,
  payment_method text,
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists public.personal_debts (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  owner text not null default 'Casal' check (owner in ('Igor','Larissa','Casal')),
  debt_type text not null default 'Outros',
  original_amount numeric(12,2),
  installment_amount numeric(12,2) not null default 0,
  installments_total integer,
  installments_left integer,
  due_day integer,
  interest_rate numeric(8,4),
  current_balance numeric(12,2),
  active boolean not null default true,
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists public.personal_goals (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  target_amount numeric(12,2) not null default 0,
  current_amount numeric(12,2) not null default 0,
  target_date date,
  priority text not null default 'media',
  notes text,
  completed boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.personal_assets (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  asset_type text not null default 'Reserva',
  amount numeric(12,2) not null default 0,
  owner text not null default 'Casal' check (owner in ('Igor','Larissa','Casal')),
  liquidity text,
  notes text,
  updated_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table if not exists public.personal_annual_plans (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  total_amount numeric(12,2) not null default 0,
  due_date date,
  saved_amount numeric(12,2) not null default 0,
  category text not null default 'Anual',
  notes text,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create index if not exists idx_personal_income_date on public.personal_income(income_date);
create index if not exists idx_personal_expenses_date on public.personal_expenses(expense_date);
create index if not exists idx_personal_expenses_due on public.personal_expenses(due_date);
create index if not exists idx_personal_goals_date on public.personal_goals(target_date);

alter table public.personal_income enable row level security;
alter table public.personal_expenses enable row level security;
alter table public.personal_debts enable row level security;
alter table public.personal_goals enable row level security;
alter table public.personal_assets enable row level security;
alter table public.personal_annual_plans enable row level security;

-- Politicas: mesmo usuario autenticado que ja usa o ERP.
do $$ begin
  drop policy if exists personal_income_admin on public.personal_income;
  drop policy if exists personal_expenses_admin on public.personal_expenses;
  drop policy if exists personal_debts_admin on public.personal_debts;
  drop policy if exists personal_goals_admin on public.personal_goals;
  drop policy if exists personal_assets_admin on public.personal_assets;
  drop policy if exists personal_annual_plans_admin on public.personal_annual_plans;
exception when others then null; end $$;

create policy personal_income_admin on public.personal_income for all to authenticated using (true) with check (true);
create policy personal_expenses_admin on public.personal_expenses for all to authenticated using (true) with check (true);
create policy personal_debts_admin on public.personal_debts for all to authenticated using (true) with check (true);
create policy personal_goals_admin on public.personal_goals for all to authenticated using (true) with check (true);
create policy personal_assets_admin on public.personal_assets for all to authenticated using (true) with check (true);
create policy personal_annual_plans_admin on public.personal_annual_plans for all to authenticated using (true) with check (true);

notify pgrst,'reload schema';
