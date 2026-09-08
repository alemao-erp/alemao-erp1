-- DIAGNÓSTICO DOS LANÇAMENTOS ANTIGOS SEM EQUIVALENTE OFICIAL
-- ITAÚ LARISSA - SETEMBRO/2026
-- SOMENTE LEITURA. NÃO ALTERA NADA.

with antigos as (
  select
    p.id as purchase_id,
    p.purchase_date,
    p.description,
    p.category,
    p.total_amount,
    p.installments,
    i.installment_number,
    i.amount as valor_setembro,
    p.created_at,
    p.card_id
  from public.personal_card_purchases p
  join public.personal_card_installments i on i.purchase_id=p.id
  join public.personal_cards c on c.id=p.card_id
  where i.invoice_month=date '2026-09-01'
    and lower(c.owner)='larissa'
    and (lower(c.name) like '%itaú%' or lower(c.name) like '%itau%')
    and coalesce(p.category,'') not in ('Fatura oficial 09/2026','Crédito/Estorno')
),
sem_equivalente as (
  select a.*
  from antigos a
  where not exists (
    select 1
    from public.personal_card_purchases o
    join public.personal_card_installments io on io.purchase_id=o.id
    where o.card_id=a.card_id
      and io.invoice_month=date '2026-09-01'
      and o.category in ('Fatura oficial 09/2026','Crédito/Estorno')
      and o.purchase_date=a.purchase_date
      and round(o.total_amount::numeric,2)=round(a.total_amount::numeric,2)
      and o.installments=a.installments
      and io.installment_number=a.installment_number
      and round(io.amount::numeric,2)=round(a.valor_setembro::numeric,2)
  )
)
select
  purchase_id,
  purchase_date as data_compra,
  description as descricao,
  category as categoria,
  round(total_amount::numeric,2) as valor_total_compra,
  installments as parcelas_total,
  installment_number as parcela_atual,
  round(valor_setembro::numeric,2) as valor_em_setembro,
  round(sum(valor_setembro) over ()::numeric,2) as soma_sem_equivalente,
  created_at
from sem_equivalente
order by purchase_date,description,created_at;