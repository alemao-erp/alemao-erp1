-- CARTOES V2 - IGOR & LARISSA
-- Execute no Supabase do projeto casal.
create extension if not exists pgcrypto;

create table if not exists public.personal_cards (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  owner text not null default 'Casal' check (owner in ('Igor','Larissa','Casal')),
  closing_day integer check (closing_day between 1 and 31),
  due_day integer check (due_day between 1 and 31),
  credit_limit numeric(12,2),
  active boolean not null default true,
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists public.personal_card_purchases (
  id uuid primary key default gen_random_uuid(),
  card_id uuid not null references public.personal_cards(id) on delete cascade,
  description text not null,
  category text not null default 'Outros',
  purchase_date date not null default current_date,
  total_amount numeric(12,2) not null check (total_amount >= 0),
  installments integer not null default 1 check (installments >= 1 and installments <= 120),
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists public.personal_card_installments (
  id uuid primary key default gen_random_uuid(),
  purchase_id uuid not null references public.personal_card_purchases(id) on delete cascade,
  card_id uuid not null references public.personal_cards(id) on delete cascade,
  installment_number integer not null,
  installments_total integer not null,
  amount numeric(12,2) not null,
  invoice_month date not null,
  due_date date,
  paid boolean not null default false,
  paid_at date,
  created_at timestamptz not null default now(),
  unique(purchase_id,installment_number)
);

create index if not exists idx_card_installments_month on public.personal_card_installments(invoice_month);
create index if not exists idx_card_installments_card on public.personal_card_installments(card_id);
create index if not exists idx_card_purchases_card on public.personal_card_purchases(card_id);

alter table public.personal_cards enable row level security;
alter table public.personal_card_purchases enable row level security;
alter table public.personal_card_installments enable row level security;

do $$ begin
  drop policy if exists personal_cards_admin on public.personal_cards;
  create policy personal_cards_admin on public.personal_cards for all to authenticated using (true) with check (true);
exception when others then null; end $$;

do $$ begin
  drop policy if exists personal_card_purchases_admin on public.personal_card_purchases;
  create policy personal_card_purchases_admin on public.personal_card_purchases for all to authenticated using (true) with check (true);
exception when others then null; end $$;

do $$ begin
  drop policy if exists personal_card_installments_admin on public.personal_card_installments;
  create policy personal_card_installments_admin on public.personal_card_installments for all to authenticated using (true) with check (true);
exception when others then null; end $$;

-- Cartoes iniciais conhecidos. Pode alterar depois pelo sistema.
insert into public.personal_cards(name,owner,notes)
select 'Cartão Igor','Igor','Cartão informado anteriormente'
where not exists(select 1 from public.personal_cards where lower(name)=lower('Cartão Igor'));

insert into public.personal_cards(name,owner,notes)
select 'Cartão Larissa Itaú','Larissa','Cartão informado anteriormente'
where not exists(select 1 from public.personal_cards where lower(name)=lower('Cartão Larissa Itaú'));

insert into public.personal_cards(name,owner,notes)
select 'Cartão Larissa Nubank','Larissa','Cartão informado anteriormente'
where not exists(select 1 from public.personal_cards where lower(name)=lower('Cartão Larissa Nubank'));

notify pgrst,'reload schema';
