-- Execute uma vez no SQL Editor do Supabase do app do casal.
create table if not exists public.personal_debt_payments (
  id uuid primary key default gen_random_uuid(),
  debt_id uuid not null references public.personal_debts(id) on delete cascade,
  amount numeric(12,2) not null check (amount > 0),
  paid_at date not null,
  installment_number integer,
  notes text,
  created_at timestamptz not null default now()
);

alter table public.personal_debt_payments enable row level security;

drop policy if exists "authenticated debt payments" on public.personal_debt_payments;
create policy "authenticated debt payments"
on public.personal_debt_payments
for all
to authenticated
using (true)
with check (true);

create index if not exists personal_debt_payments_debt_id_idx on public.personal_debt_payments(debt_id);
create index if not exists personal_debt_payments_paid_at_idx on public.personal_debt_payments(paid_at);