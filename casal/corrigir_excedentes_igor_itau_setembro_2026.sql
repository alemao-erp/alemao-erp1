-- CORREÇÃO SEGURA DOS EXCEDENTES - SETEMBRO/2026
-- Remove somente lançamentos ANTIGOS que têm uma linha oficial equivalente.
-- Segurança extra: só prossegue se os candidatos somarem EXATAMENTE
-- R$ 905,11 no Cartão Igor e R$ 982,68 no Itaú Larissa.
-- Nubank não é alterado.

begin;

create temporary table _remover_excedentes as
select distinct antigo.id as purchase_id, c.name as cartao
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
  );

-- Valida o valor a remover antes de qualquer DELETE.
do $$
declare
  v_igor numeric;
  v_itau numeric;
begin
  select coalesce(round(sum(i.amount)::numeric,2),0)
    into v_igor
  from public.personal_card_installments i
  join _remover_excedentes r on r.purchase_id=i.purchase_id
  join public.personal_cards c on c.id=i.card_id
  where i.invoice_month=date '2026-09-01'
    and lower(c.owner)='igor';

  select coalesce(round(sum(i.amount)::numeric,2),0)
    into v_itau
  from public.personal_card_installments i
  join _remover_excedentes r on r.purchase_id=i.purchase_id
  join public.personal_cards c on c.id=i.card_id
  where i.invoice_month=date '2026-09-01'
    and lower(c.owner)='larissa'
    and (lower(c.name) like '%itaú%' or lower(c.name) like '%itau%');

  if v_igor <> 905.11 then
    raise exception 'SEGURANÇA: candidatos do Igor somam %, esperado 905.11. Nada foi apagado.', v_igor;
  end if;

  if v_itau <> 982.68 then
    raise exception 'SEGURANÇA: candidatos do Itaú somam %, esperado 982.68. Nada foi apagado.', v_itau;
  end if;
end $$;

-- Apaga todas as parcelas (inclusive futuras) ligadas SOMENTE às compras antigas equivalentes.
delete from public.personal_card_installments i
using _remover_excedentes r
where i.purchase_id=r.purchase_id;

-- Apaga as compras antigas equivalentes.
delete from public.personal_card_purchases p
using _remover_excedentes r
where p.id=r.purchase_id;

commit;

notify pgrst, 'reload schema';

-- RESULTADO FINAL: deve mostrar Igor 1030.11 e Itaú 3272.57.
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