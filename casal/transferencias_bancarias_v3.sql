-- BANCOS V3 - TRANSFERENCIAS ENTRE CONTAS
-- Execute no Supabase do projeto casal.
create extension if not exists pgcrypto;

create table if not exists public.personal_bank_transfers (
  id uuid primary key default gen_random_uuid(),
  from_account_id uuid not null references public.personal_bank_accounts(id) on delete restrict,
  to_account_id uuid not null references public.personal_bank_accounts(id) on delete restrict,
  amount numeric(12,2) not null check (amount > 0),
  transfer_date date not null default current_date,
  description text,
  receipt_path text,
  created_at timestamptz not null default now(),
  check (from_account_id <> to_account_id)
);

alter table public.personal_bank_transfers enable row level security;
drop policy if exists personal_bank_transfers_admin on public.personal_bank_transfers;
create policy personal_bank_transfers_admin on public.personal_bank_transfers for all to authenticated using (true) with check (true);

create or replace function public.sync_bank_from_transfer()
returns trigger language plpgsql security definer set search_path=public as $$
declare old_from uuid; old_to uuid;
begin
  if tg_op in ('UPDATE','DELETE') then old_from:=old.from_account_id; old_to:=old.to_account_id; end if;
  if tg_op='DELETE' then
    delete from public.personal_bank_transactions where source_type in ('transfer_out','transfer_in') and source_id=old.id;
    perform public.recalc_personal_bank_balance(old_from); perform public.recalc_personal_bank_balance(old_to);
    return old;
  end if;
  delete from public.personal_bank_transactions where source_type in ('transfer_out','transfer_in') and source_id=new.id;
  insert into public.personal_bank_transactions(bank_account_id,transaction_type,amount,transaction_date,description,source_type,source_id)
  values(new.from_account_id,'outflow',new.amount,new.transfer_date,coalesce(new.description,'Transferência entre contas'),'transfer_out',new.id),
        (new.to_account_id,'inflow',new.amount,new.transfer_date,coalesce(new.description,'Transferência entre contas'),'transfer_in',new.id);
  perform public.recalc_personal_bank_balance(old_from); perform public.recalc_personal_bank_balance(old_to);
  perform public.recalc_personal_bank_balance(new.from_account_id); perform public.recalc_personal_bank_balance(new.to_account_id);
  return new;
end;$$;

drop trigger if exists trg_sync_bank_transfer on public.personal_bank_transfers;
create trigger trg_sync_bank_transfer after insert or update or delete on public.personal_bank_transfers for each row execute function public.sync_bank_from_transfer();
notify pgrst,'reload schema';