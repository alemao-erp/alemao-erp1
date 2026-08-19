-- BANCOS + COMPROVANTES V1 - IGOR & LARISSA
-- Execute no Supabase do projeto casal.
create extension if not exists pgcrypto;

create table if not exists public.personal_bank_accounts (
  id uuid primary key default gen_random_uuid(),
  bank_name text not null,
  account_name text not null,
  owner text not null default 'Casal' check (owner in ('Igor','Larissa','Casal')),
  account_type text not null default 'Conta corrente',
  agency text,
  account_number text,
  current_balance numeric(12,2) not null default 0,
  active boolean not null default true,
  notes text,
  created_at timestamptz not null default now()
);

alter table public.personal_income add column if not exists bank_account_id uuid references public.personal_bank_accounts(id) on delete set null;
alter table public.personal_income add column if not exists receipt_path text;
alter table public.personal_income add column if not exists received_at date;

alter table public.personal_expenses add column if not exists bank_account_id uuid references public.personal_bank_accounts(id) on delete set null;
alter table public.personal_expenses add column if not exists receipt_path text;

create index if not exists idx_personal_income_bank on public.personal_income(bank_account_id);
create index if not exists idx_personal_expenses_bank on public.personal_expenses(bank_account_id);

alter table public.personal_bank_accounts enable row level security;
do $$ begin
  drop policy if exists personal_bank_accounts_admin on public.personal_bank_accounts;
  create policy personal_bank_accounts_admin on public.personal_bank_accounts for all to authenticated using (true) with check (true);
exception when others then null; end $$;

insert into storage.buckets(id,name,public)
values('personal-receipts','personal-receipts',false)
on conflict(id) do nothing;

drop policy if exists personal_receipts_select on storage.objects;
drop policy if exists personal_receipts_insert on storage.objects;
drop policy if exists personal_receipts_update on storage.objects;
drop policy if exists personal_receipts_delete on storage.objects;
create policy personal_receipts_select on storage.objects for select to authenticated using (bucket_id='personal-receipts');
create policy personal_receipts_insert on storage.objects for insert to authenticated with check (bucket_id='personal-receipts');
create policy personal_receipts_update on storage.objects for update to authenticated using (bucket_id='personal-receipts') with check (bucket_id='personal-receipts');
create policy personal_receipts_delete on storage.objects for delete to authenticated using (bucket_id='personal-receipts');

notify pgrst,'reload schema';
