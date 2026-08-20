-- SALARIOS + EXTRAS V6 - IGOR & LARISSA
-- Execute uma vez no Supabase do projeto casal.
create extension if not exists pgcrypto;

create table if not exists public.personal_salary_profiles (
  id uuid primary key default gen_random_uuid(),
  person text not null unique check (person in ('Igor','Larissa')),
  base_salary numeric(12,2) not null default 0,
  full_shift_value numeric(12,2) not null default 0,
  half_shift_value numeric(12,2) not null default 0,
  weekend_value numeric(12,2) not null default 0,
  charges_percent numeric(7,3) not null default 0,
  fixed_deductions numeric(12,2) not null default 0,
  payment_day integer check (payment_day between 1 and 31),
  notes text,
  updated_at timestamptz not null default now()
);

create table if not exists public.personal_salary_extras (
  id uuid primary key default gen_random_uuid(),
  person text not null check (person in ('Igor','Larissa')),
  work_date date not null default current_date,
  extra_type text not null check (extra_type in ('plantao','meio_plantao','fim_semana','outro')),
  description text,
  quantity numeric(10,2) not null default 1 check (quantity > 0),
  unit_value numeric(12,2) not null default 0,
  gross_amount numeric(12,2) not null default 0,
  expected_payment_date date,
  received boolean not null default false,
  received_at date,
  income_id uuid references public.personal_income(id) on delete set null,
  created_at timestamptz not null default now()
);

create index if not exists idx_salary_extras_person_date on public.personal_salary_extras(person,work_date);

alter table public.personal_salary_profiles enable row level security;
alter table public.personal_salary_extras enable row level security;

drop policy if exists personal_salary_profiles_admin on public.personal_salary_profiles;
create policy personal_salary_profiles_admin on public.personal_salary_profiles for all to authenticated using (true) with check (true);

drop policy if exists personal_salary_extras_admin on public.personal_salary_extras;
create policy personal_salary_extras_admin on public.personal_salary_extras for all to authenticated using (true) with check (true);

notify pgrst,'reload schema';