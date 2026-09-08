-- AJUSTE DO BANCO PARA CRÉDITOS/ESTORNOS EM FATURAS
-- App Igor & Larissa
-- Objetivo: permitir valores negativos somente nos campos financeiros das faturas,
-- mantendo a regra de que zero não é um lançamento válido.
-- Execute UMA VEZ no SQL Editor do Supabase.

begin;

-- personal_card_purchases.total_amount
-- Remove checks que impedem valores negativos nesse campo e recria uma regra segura: valor <> 0.
do $$
declare r record;
begin
  for r in
    select conname
    from pg_constraint
    where conrelid = 'public.personal_card_purchases'::regclass
      and contype = 'c'
      and pg_get_constraintdef(oid) ilike '%total_amount%'
  loop
    execute format('alter table public.personal_card_purchases drop constraint %I', r.conname);
  end loop;
end $$;

alter table public.personal_card_purchases
  add constraint personal_card_purchases_total_amount_check
  check (total_amount <> 0);

-- personal_card_installments.amount
-- Faz o mesmo para as parcelas, pois estorno/crédito precisa reduzir a fatura.
do $$
declare r record;
begin
  for r in
    select conname
    from pg_constraint
    where conrelid = 'public.personal_card_installments'::regclass
      and contype = 'c'
      and pg_get_constraintdef(oid) ilike '%amount%'
  loop
    execute format('alter table public.personal_card_installments drop constraint %I', r.conname);
  end loop;
end $$;

alter table public.personal_card_installments
  add constraint personal_card_installments_amount_check
  check (amount <> 0);

commit;

-- Conferência das regras finais
select
  conrelid::regclass as tabela,
  conname as restricao,
  pg_get_constraintdef(oid) as regra
from pg_constraint
where conrelid in (
  'public.personal_card_purchases'::regclass,
  'public.personal_card_installments'::regclass
)
and contype='c'
order by 1,2;
