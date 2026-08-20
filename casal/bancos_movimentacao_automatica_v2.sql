-- BANCOS V2 - MOVIMENTACAO AUTOMATICA
-- Execute no Supabase do projeto casal.

create extension if not exists pgcrypto;

alter table public.personal_bank_accounts
  add column if not exists opening_balance numeric(12,2);

update public.personal_bank_accounts
set opening_balance = current_balance
where opening_balance is null;

alter table public.personal_bank_accounts
  alter column opening_balance set default 0;

alter table public.personal_card_invoice_payments
  add column if not exists bank_account_id uuid references public.personal_bank_accounts(id) on delete set null;

create table if not exists public.personal_bank_transactions (
  id uuid primary key default gen_random_uuid(),
  bank_account_id uuid not null references public.personal_bank_accounts(id) on delete cascade,
  transaction_type text not null check (transaction_type in ('inflow','outflow')),
  amount numeric(12,2) not null check (amount >= 0),
  transaction_date date not null default current_date,
  description text,
  source_type text not null,
  source_id uuid not null,
  created_at timestamptz not null default now(),
  unique(source_type, source_id)
);

create index if not exists idx_personal_bank_transactions_account_date
  on public.personal_bank_transactions(bank_account_id, transaction_date desc);

alter table public.personal_bank_transactions enable row level security;

do $$ begin
  drop policy if exists personal_bank_transactions_admin on public.personal_bank_transactions;
  create policy personal_bank_transactions_admin
    on public.personal_bank_transactions
    for all to authenticated
    using (true) with check (true);
exception when others then null; end $$;

create or replace function public.recalc_personal_bank_balance(p_account uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_account is null then return; end if;
  update public.personal_bank_accounts b
  set current_balance = coalesce(b.opening_balance,0) + coalesce((
    select sum(case when t.transaction_type='inflow' then t.amount else -t.amount end)
    from public.personal_bank_transactions t
    where t.bank_account_id=b.id
  ),0)
  where b.id=p_account;
end;
$$;

create or replace function public.sync_bank_from_income()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare old_account uuid;
begin
  if tg_op in ('UPDATE','DELETE') then old_account := old.bank_account_id; end if;

  if tg_op='DELETE' then
    delete from public.personal_bank_transactions where source_type='income' and source_id=old.id;
    perform public.recalc_personal_bank_balance(old_account);
    return old;
  end if;

  delete from public.personal_bank_transactions where source_type='income' and source_id=new.id;
  if new.bank_account_id is not null and new.received_at is not null then
    insert into public.personal_bank_transactions(bank_account_id,transaction_type,amount,transaction_date,description,source_type,source_id)
    values(new.bank_account_id,'inflow',coalesce(new.amount,0),coalesce(new.received_at,new.income_date,current_date),new.description,'income',new.id);
  end if;
  perform public.recalc_personal_bank_balance(old_account);
  perform public.recalc_personal_bank_balance(new.bank_account_id);
  return new;
end;
$$;

create or replace function public.sync_bank_from_expense()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare old_account uuid;
begin
  if tg_op in ('UPDATE','DELETE') then old_account := old.bank_account_id; end if;

  if tg_op='DELETE' then
    delete from public.personal_bank_transactions where source_type='expense' and source_id=old.id;
    perform public.recalc_personal_bank_balance(old_account);
    return old;
  end if;

  delete from public.personal_bank_transactions where source_type='expense' and source_id=new.id;
  if new.bank_account_id is not null and coalesce(new.paid,false)=true then
    insert into public.personal_bank_transactions(bank_account_id,transaction_type,amount,transaction_date,description,source_type,source_id)
    values(new.bank_account_id,'outflow',coalesce(new.amount,0),coalesce(new.paid_at,new.expense_date,current_date),new.description,'expense',new.id);
  end if;
  perform public.recalc_personal_bank_balance(old_account);
  perform public.recalc_personal_bank_balance(new.bank_account_id);
  return new;
end;
$$;

create or replace function public.sync_bank_from_card_payment()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare old_account uuid;
begin
  if tg_op in ('UPDATE','DELETE') then old_account := old.bank_account_id; end if;

  if tg_op='DELETE' then
    delete from public.personal_bank_transactions where source_type='card_payment' and source_id=old.id;
    perform public.recalc_personal_bank_balance(old_account);
    return old;
  end if;

  delete from public.personal_bank_transactions where source_type='card_payment' and source_id=new.id;
  if new.bank_account_id is not null then
    insert into public.personal_bank_transactions(bank_account_id,transaction_type,amount,transaction_date,description,source_type,source_id)
    values(new.bank_account_id,'outflow',coalesce(new.amount,0),coalesce(new.paid_at,current_date),'Pagamento de fatura','card_payment',new.id);
  end if;
  perform public.recalc_personal_bank_balance(old_account);
  perform public.recalc_personal_bank_balance(new.bank_account_id);
  return new;
end;
$$;

drop trigger if exists trg_sync_bank_income on public.personal_income;
create trigger trg_sync_bank_income
after insert or update or delete on public.personal_income
for each row execute function public.sync_bank_from_income();

drop trigger if exists trg_sync_bank_expense on public.personal_expenses;
create trigger trg_sync_bank_expense
after insert or update or delete on public.personal_expenses
for each row execute function public.sync_bank_from_expense();

drop trigger if exists trg_sync_bank_card_payment on public.personal_card_invoice_payments;
create trigger trg_sync_bank_card_payment
after insert or update or delete on public.personal_card_invoice_payments
for each row execute function public.sync_bank_from_card_payment();

-- Gera o razão bancário para registros antigos já vinculados.
delete from public.personal_bank_transactions where source_type in ('income','expense','card_payment');

insert into public.personal_bank_transactions(bank_account_id,transaction_type,amount,transaction_date,description,source_type,source_id)
select bank_account_id,'inflow',amount,coalesce(received_at,income_date,current_date),description,'income',id
from public.personal_income
where bank_account_id is not null and received_at is not null
on conflict(source_type,source_id) do update set
 bank_account_id=excluded.bank_account_id, transaction_type=excluded.transaction_type,
 amount=excluded.amount, transaction_date=excluded.transaction_date, description=excluded.description;

insert into public.personal_bank_transactions(bank_account_id,transaction_type,amount,transaction_date,description,source_type,source_id)
select bank_account_id,'outflow',amount,coalesce(paid_at,expense_date,current_date),description,'expense',id
from public.personal_expenses
where bank_account_id is not null and paid=true
on conflict(source_type,source_id) do update set
 bank_account_id=excluded.bank_account_id, transaction_type=excluded.transaction_type,
 amount=excluded.amount, transaction_date=excluded.transaction_date, description=excluded.description;

insert into public.personal_bank_transactions(bank_account_id,transaction_type,amount,transaction_date,description,source_type,source_id)
select bank_account_id,'outflow',amount,coalesce(paid_at,current_date),'Pagamento de fatura','card_payment',id
from public.personal_card_invoice_payments
where bank_account_id is not null
on conflict(source_type,source_id) do update set
 bank_account_id=excluded.bank_account_id, transaction_type=excluded.transaction_type,
 amount=excluded.amount, transaction_date=excluded.transaction_date, description=excluded.description;

select public.recalc_personal_bank_balance(id) from public.personal_bank_accounts;

notify pgrst,'reload schema';
