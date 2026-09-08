-- DIAGNÓSTICO DETALHADO - UMA ÚNICA TABELA DE RESULTADO
-- SOMENTE LEITURA. NÃO ALTERA NENHUM DADO.
-- Mostra todas as linhas que compõem setembro/2026 no Igor e Itaú.

select
  c.name as cartao,
  p.purchase_date as data_compra,
  p.description as descricao,
  coalesce(p.category,'') as categoria,
  p.total_amount as valor_total_compra,
  p.installments as parcelas_total,
  i.installment_number as parcela_atual,
  i.amount as valor_em_setembro,
  p.id as purchase_id,
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
order by c.name,p.purchase_date,p.description,p.created_at;