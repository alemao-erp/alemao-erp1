-- DIAGNÓSTICO DO RESTANTE R$ 113,69 - ITAÚ LARISSA - SETEMBRO/2026
-- SOMENTE LEITURA. NÃO ALTERA NADA.
-- Mostra somente linhas do Itaú que NÃO são oficiais/créditos e que ainda entram em setembro.

select
  p.id as purchase_id,
  p.purchase_date as data_compra,
  p.description as descricao,
  p.category as categoria,
  round(p.total_amount::numeric,2) as valor_total_compra,
  p.installments as parcelas_total,
  i.installment_number as parcela_atual,
  round(i.amount::numeric,2) as valor_em_setembro,
  p.created_at
from public.personal_card_installments i
join public.personal_card_purchases p on p.id=i.purchase_id
join public.personal_cards c on c.id=i.card_id
where i.invoice_month=date '2026-09-01'
  and lower(c.owner)='larissa'
  and (lower(c.name) like '%itaú%' or lower(c.name) like '%itau%')
  and coalesce(p.category,'') not in ('Fatura oficial 09/2026','Crédito/Estorno')
order by p.purchase_date,p.description,p.created_at;