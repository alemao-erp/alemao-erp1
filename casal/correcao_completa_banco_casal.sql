-- CORRECAO COMPLETA - IGOR & LARISSA
-- Execute no projeto Supabase "casal".
-- Pode ser reexecutado com seguranca.

create extension if not exists pgcrypto;

create table if not exists public.personal_income (
  id uuid primary key default gen_random_uuid(),
  person text not null default 'Casal',
  description text not null,
  amount numeric(12,2) not null default 0,
  income_date date not null default current_date,
  recurring boolean not null default false,
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists public.personal_expenses (
  id uuid primary key default gen_random_uuid(),
  person text not null default 'Casal',
  description text not null,
  category text not null default 'Outros',
  amount numeric(12,2) not null default 0,
  expense_date date not null default current_date,
  due_date date,
  paid boolean not null default false,
  paid_at date,
  recurring boolean not null default false,
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists public.personal_debts (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  owner text not null default 'Casal',
  debt_type text not null default 'Outros',
  installment_amount numeric(12,2) not null default 0,
  installments_total integer,
  installments_left integer,
  current_balance numeric(14,2),
  interest_rate numeric(8,4),
  due_day integer,
  active boolean not null default true,
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists public.personal_assets (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  asset_type text not null default 'Reserva',
  amount numeric(14,2) not null default 0,
  owner text not null default 'Casal',
  liquidity text,
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists public.personal_goals (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  target_amount numeric(14,2) not null default 0,
  current_amount numeric(14,2) not null default 0,
  target_date date,
  priority text not null default 'media',
  completed boolean not null default false,
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists public.personal_annual_plans (
  id uuid primary key default gen_random_uuid(),
  description text not null,
  category text not null default 'Outros',
  annual_amount numeric(14,2) not null default 0,
  monthly_reserve numeric(14,2) not null default 0,
  due_month integer,
  active boolean not null default true,
  notes text,
  created_at timestamptz not null default now()
);

alter table public.personal_income enable row level security;
alter table public.personal_expenses enable row level security;
alter table public.personal_debts enable row level security;
alter table public.personal_assets enable row level security;
alter table public.personal_goals enable row level security;
alter table public.personal_annual_plans enable row level security;

drop policy if exists personal_income_admin on public.personal_income;
drop policy if exists personal_expenses_admin on public.personal_expenses;
drop policy if exists personal_debts_admin on public.personal_debts;
drop policy if exists personal_assets_admin on public.personal_assets;
drop policy if exists personal_goals_admin on public.personal_goals;
drop policy if exists personal_annual_plans_admin on public.personal_annual_plans;

create policy personal_income_admin on public.personal_income for all to authenticated using (true) with check (true);
create policy personal_expenses_admin on public.personal_expenses for all to authenticated using (true) with check (true);
create policy personal_debts_admin on public.personal_debts for all to authenticated using (true) with check (true);
create policy personal_assets_admin on public.personal_assets for all to authenticated using (true) with check (true);
create policy personal_goals_admin on public.personal_goals for all to authenticated using (true) with check (true);
create policy personal_annual_plans_admin on public.personal_annual_plans for all to authenticated using (true) with check (true);

-- RECEITAS
insert into public.personal_income(person,description,amount,income_date,recurring,notes)
select 'Igor','Salário líquido Igor',3000,current_date,true,'Valor informado em 13/08/2026'
where not exists(select 1 from public.personal_income where description='Salário líquido Igor');
insert into public.personal_income(person,description,amount,income_date,recurring,notes)
select 'Larissa','Salário líquido Larissa',2000,current_date,true,'Valor informado em 13/08/2026'
where not exists(select 1 from public.personal_income where description='Salário líquido Larissa');
insert into public.personal_income(person,description,amount,income_date,recurring,notes)
select 'Casal','Prestação da casa vendida',1000,current_date,true,'Receita temporária prevista até agosto de 2027'
where not exists(select 1 from public.personal_income where description='Prestação da casa vendida');

-- DESPESAS
insert into public.personal_expenses(person,description,category,amount,expense_date,paid,recurring,notes)
select 'Casal','Seguro do carro','Transporte',256.21,current_date,true,true,'Valor de referência; confirmar valor atual'
where not exists(select 1 from public.personal_expenses where description='Seguro do carro');
insert into public.personal_expenses(person,description,category,amount,expense_date,paid,recurring)
select 'Casal','Celulares','Comunicação',90.27,current_date,true,true
where not exists(select 1 from public.personal_expenses where description='Celulares');
insert into public.personal_expenses(person,description,category,amount,expense_date,paid,recurring)
select 'Casal','Água e luz','Casa',315,current_date,true,true
where not exists(select 1 from public.personal_expenses where description='Água e luz');
insert into public.personal_expenses(person,description,category,amount,expense_date,paid,recurring)
select 'Casal','Internet','Casa',100,current_date,true,true
where not exists(select 1 from public.personal_expenses where description='Internet');
insert into public.personal_expenses(person,description,category,amount,expense_date,paid,recurring)
select 'Larissa','Plano de saúde Larissa','Saúde',400,current_date,true,true
where not exists(select 1 from public.personal_expenses where description='Plano de saúde Larissa');
insert into public.personal_expenses(person,description,category,amount,expense_date,paid,recurring,notes)
select 'Casal','Combustível','Transporte',200,current_date,true,true,'Valor de referência; ajustar se necessário'
where not exists(select 1 from public.personal_expenses where description='Combustível');
insert into public.personal_expenses(person,description,category,amount,expense_date,paid,recurring,notes)
select 'Casal','Dízimo','Religioso',450,current_date,true,true,'Estimativa; confirmar valor atual'
where not exists(select 1 from public.personal_expenses where description='Dízimo');

-- DIVIDAS
insert into public.personal_debts(name,owner,debt_type,installment_amount,installments_left,active,notes)
select 'Financiamento do carro','Casal','Veículo',1042,45,true,'Parcela aproximada informada em 13/08/2026'
where not exists(select 1 from public.personal_debts where name='Financiamento do carro');
insert into public.personal_debts(name,owner,debt_type,installment_amount,installments_left,active,notes)
select 'Financiamento da casa','Casal','Imóvel',960,399,true,'Parcelas restantes conforme informado em 13/08/2026'
where not exists(select 1 from public.personal_debts where name='Financiamento da casa');
insert into public.personal_debts(name,owner,debt_type,installment_amount,current_balance,active,notes)
select 'Cartão Igor','Igor','Cartão de crédito',0,1031,true,'Saldo informado em 13/08/2026'
where not exists(select 1 from public.personal_debts where name='Cartão Igor');
insert into public.personal_debts(name,owner,debt_type,installment_amount,current_balance,active,notes)
select 'Cartão Larissa Itaú','Larissa','Cartão de crédito',0,2500,true,'Saldo informado em 13/08/2026'
where not exists(select 1 from public.personal_debts where name='Cartão Larissa Itaú');
insert into public.personal_debts(name,owner,debt_type,installment_amount,current_balance,active,notes)
select 'Cartão Larissa Nubank','Larissa','Cartão de crédito',0,1000,true,'Saldo informado em 13/08/2026'
where not exists(select 1 from public.personal_debts where name='Cartão Larissa Nubank');

-- RESERVA
insert into public.personal_assets(name,asset_type,amount,owner,liquidity,notes)
select 'Reserva financeira','Reserva',120000,'Casal','Alta','Valor informado em 13/08/2026'
where not exists(select 1 from public.personal_assets where name='Reserva financeira');

notify pgrst,'reload schema';

select
  (select count(*) from public.personal_income) as receitas,
  (select count(*) from public.personal_expenses) as despesas,
  (select count(*) from public.personal_debts) as dividas,
  (select count(*) from public.personal_assets) as patrimonio;
