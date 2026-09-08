-- CORREÇÃO FINAL VALIDADA - IGOR + ITAÚ - SETEMBRO/2026
-- Objetivo final:
--   Cartão Igor = R$ 1.030,11
--   Cartão Larissa Itaú = R$ 3.272,57
--   Nubank NÃO é alterado.
--
-- A correção remove SOMENTE:
-- 1) lançamentos antigos que têm uma linha oficial equivalente em setembro/2026;
-- 2) quatro lançamentos antigos do Itaú sem equivalente oficial, já diagnosticados,
--    que somam exatamente R$ 113,69 em setembro.
--
-- Há validações antes de qualquer DELETE. Se qualquer soma não bater, o SQL para
-- e nada é apagado.

begin;

create temporary table _final_remover (
  purchase_id uuid primary key,
  origem text not null
);

-- A) Lançamentos antigos com equivalente oficial.
insert into _final_remover(purchase_id, origem)
select distinct antigo.id, 'equivalente_oficial'
from public.personal_card_purchases antigo
join public.personal_cards c on c.id=antigo.card_id
join public.personal_card_installments ia
  on ia.purchase_id=antigo.id
 and ia.invoice_month=date '2026-09-01'
where antigo.category not in ('Fatura oficial 09/2026','Crédito/Estorno')
  and (
    (lower(c.owner)='igor' and (lower(c.name) like '%igor%' or lower(c.name) like '%banco do brasil%' or lower(c.name) like '%bb%'))
    or
    (lower(c.owner)='larissa' and (lower(c.name) like '%itaú%' or lower(c.name) like '%itau%'))
  )
  and exists (
    select 1
    from public.personal_card_purchases oficial
    join public.personal_card_installments io
      on io.purchase_id=oficial.id
     and io.invoice_month=date '2026-09-01'
    where oficial.card_id=antigo.card_id
      and oficial.category in ('Fatura oficial 09/2026','Crédito/Estorno')
      and oficial.purchase_date=antigo.purchase_date
      and round(oficial.total_amount::numeric,2)=round(antigo.total_amount::numeric,2)
      and oficial.installments=antigo.installments
      and io.installment_number=ia.installment_number
      and round(io.amount::numeric,2)=round(ia.amount::numeric,2)
  )
on conflict (purchase_id) do nothing;

-- B) Quatro lançamentos antigos do Itaú sem equivalente oficial,
-- diagnosticados na consulta anterior e que somam R$ 113,69 em setembro.
insert into _final_remover(purchase_id, origem) values
  ('dacf3606-4788-4ab8-b465-635e8e4c7d17'::uuid,'itau_sem_equivalente'), -- Totebag 69,34
  ('886cb42e-5d40-4ec9-8a3f-8427659821f5'::uuid,'itau_sem_equivalente'), -- Bar e bazar 24,00
  ('b4fdbdbd-f1f3-4116-83cd-d714bb7cdb98'::uuid,'itau_sem_equivalente'), -- FPB 3,99
  ('550e76f0-683e-43f4-b04e-d53c4433c711'::uuid,'itau_sem_equivalente')  -- Padaria 16,36
on conflict (purchase_id) do nothing;

-- VALIDAÇÃO FORTE ANTES DE APAGAR.
do $$
declare
  v_igor numeric;
  v_itau numeric;
  v_itau_extra numeric;
  v_total_igor_atual numeric;
  v_total_itau_atual numeric;
begin
  -- Total atual de setembro antes da correção.
  select coalesce(round(sum(i.amount)::numeric,2),0)
    into v_total_igor_atual
  from public.personal_card_installments i
  join public.personal_cards c on c.id=i.card_id
  where i.invoice_month=date '2026-09-01'
    and lower(c.owner)='igor';

  select coalesce(round(sum(i.amount)::numeric,2),0)
    into v_total_itau_atual
  from public.personal_card_installments i
  join public.personal_cards c on c.id=i.card_id
  where i.invoice_month=date '2026-09-01'
    and lower(c.owner)='larissa'
    and (lower(c.name) like '%itaú%' or lower(c.name) like '%itau%');

  if v_total_igor_atual <> 1935.22 then
    raise exception 'SEGURANÇA: total atual do Igor é %, esperado 1935.22. Nada foi apagado.', v_total_igor_atual;
  end if;

  if v_total_itau_atual <> 4255.25 then
    raise exception 'SEGURANÇA: total atual do Itaú é %, esperado 4255.25. Nada foi apagado.', v_total_itau_atual;
  end if;

  -- Quanto será removido de setembro.
  select coalesce(round(sum(i.amount)::numeric,2),0)
    into v_igor
  from public.personal_card_installments i
  join _final_remover r on r.purchase_id=i.purchase_id
  join public.personal_cards c on c.id=i.card_id
  where i.invoice_month=date '2026-09-01'
    and lower(c.owner)='igor';

  select coalesce(round(sum(i.amount)::numeric,2),0)
    into v_itau
  from public.personal_card_installments i
  join _final_remover r on r.purchase_id=i.purchase_id
  join public.personal_cards c on c.id=i.card_id
  where i.invoice_month=date '2026-09-01'
    and lower(c.owner)='larissa'
    and (lower(c.name) like '%itaú%' or lower(c.name) like '%itau%');

  select coalesce(round(sum(i.amount)::numeric,2),0)
    into v_itau_extra
  from public.personal_card_installments i
  join _final_remover r on r.purchase_id=i.purchase_id and r.origem='itau_sem_equivalente'
  join public.personal_cards c on c.id=i.card_id
  where i.invoice_month=date '2026-09-01'
    and lower(c.owner)='larissa'
    and (lower(c.name) like '%itaú%' or lower(c.name) like '%itau%');

  if v_igor <> 905.11 then
    raise exception 'SEGURANÇA: remoção do Igor soma %, esperado 905.11. Nada foi apagado.', v_igor;
  end if;

  if v_itau_extra <> 113.69 then
    raise exception 'SEGURANÇA: quatro extras do Itaú somam %, esperado 113.69. Nada foi apagado.', v_itau_extra;
  end if;

  if v_itau <> 982.68 then
    raise exception 'SEGURANÇA: remoção total do Itaú soma %, esperado 982.68. Nada foi apagado.', v_itau;
  end if;
end $$;

-- Remove todas as parcelas (inclusive futuras) ligadas SOMENTE às compras selecionadas.
delete from public.personal_card_installments i
using _final_remover r
where i.purchase_id=r.purchase_id;

-- Remove as compras antigas selecionadas.
delete from public.personal_card_purchases p
using _final_remover r
where p.id=r.purchase_id;

-- VALIDAÇÃO FINAL ainda dentro da transação.
do $$
declare
  v_igor_final numeric;
  v_itau_final numeric;
begin
  select coalesce(round(sum(i.amount)::numeric,2),0)
    into v_igor_final
  from public.personal_card_installments i
  join public.personal_cards c on c.id=i.card_id
  where i.invoice_month=date '2026-09-01'
    and lower(c.owner)='igor';

  select coalesce(round(sum(i.amount)::numeric,2),0)
    into v_itau_final
  from public.personal_card_installments i
  join public.personal_cards c on c.id=i.card_id
  where i.invoice_month=date '2026-09-01'
    and lower(c.owner)='larissa'
    and (lower(c.name) like '%itaú%' or lower(c.name) like '%itau%');

  if v_igor_final <> 1030.11 then
    raise exception 'SEGURANÇA FINAL: Igor ficou %, esperado 1030.11. Transação será revertida.', v_igor_final;
  end if;

  if v_itau_final <> 3272.57 then
    raise exception 'SEGURANÇA FINAL: Itaú ficou %, esperado 3272.57. Transação será revertida.', v_itau_final;
  end if;
end $$;

commit;

notify pgrst, 'reload schema';

-- RESULTADO FINAL PARA CONFERÊNCIA.
select
  c.name as cartao,
  round(sum(i.amount)::numeric,2) as total_setembro
from public.personal_card_installments i
join public.personal_cards c on c.id=i.card_id
where i.invoice_month=date '2026-09-01'
  and (
    lower(c.owner)='igor'
    or (lower(c.owner)='larissa' and (lower(c.name) like '%itaú%' or lower(c.name) like '%itau%'))
  )
group by c.name
order by c.name;