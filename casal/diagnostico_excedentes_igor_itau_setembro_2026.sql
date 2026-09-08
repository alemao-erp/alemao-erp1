-- DIAGNÓSTICO FINAL - EXCEDENTES SETEMBRO/2026
-- SOMENTE LEITURA. NÃO ALTERA NENHUM DADO.
-- Mostra cada compra que está contribuindo para a fatura de setembro,
-- inclusive purchase_id, categoria e valor da parcela de setembro.

select
  c.name as cartao,
  c.owner as responsavel,
  p.id as purchase_id,
  p.purchase_date,
  p.description,
  p.category,
  p.total_amount,
  p.installments,
  i.id as installment_id,
  i.installment_number,
  i.invoice_month,
  i.amount as valor_em_setembro,
  p.created_at
from public.personal_card_installments i
join public.personal_card_purchases p on p.id=i.purchase_id
join public.personal_cards c on c.id=i.card_id
where i.invoice_month=date '2026-09-01'
  and (
    (lower(c.owner)='igor' and (lower(c.name) like '%igor%' or lower(c.name) like '%banco do brasil%' or lower(c.name) like '%bb%'))
    or
    (lower(c.owner)='larissa' and (lower(c.name) like '%itaú%' or lower(c.name) like '%itau%'))
  )
order by c.owner,c.name,p.purchase_date,p.description,p.created_at;

-- Totais atuais para conferência.
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