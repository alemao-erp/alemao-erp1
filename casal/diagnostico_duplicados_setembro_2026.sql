-- DIAGNÓSTICO SOMENTE LEITURA — FATURAS SETEMBRO/2026
-- NÃO altera nenhum dado.

-- 1) Totais por cartão e categoria
select
  c.name as cartao,
  c.owner as responsavel,
  coalesce(p.category,'(sem categoria)') as categoria,
  round(sum(i.amount)::numeric,2) as total_categoria,
  count(*) as qtd_parcelas
from public.personal_card_installments i
join public.personal_cards c on c.id=i.card_id
join public.personal_card_purchases p on p.id=i.purchase_id
where i.invoice_month='2026-09-01'
group by c.name,c.owner,coalesce(p.category,'(sem categoria)')
order by c.owner,c.name,categoria;

-- 2) Todas as linhas de setembro, para identificar duplicações
select
  c.name as cartao,
  c.owner as responsavel,
  p.id as purchase_id,
  p.purchase_date,
  p.description,
  coalesce(p.category,'(sem categoria)') as categoria,
  i.installment_number,
  i.installments_total,
  i.amount,
  i.invoice_month,
  i.due_date
from public.personal_card_installments i
join public.personal_cards c on c.id=i.card_id
join public.personal_card_purchases p on p.id=i.purchase_id
where i.invoice_month='2026-09-01'
order by c.owner,c.name,p.purchase_date,p.description,i.installment_number;

-- 3) Grupos com mesma descrição/data/valor no mesmo cartão
select
  c.name as cartao,
  p.purchase_date,
  lower(trim(p.description)) as descricao_normalizada,
  i.amount,
  count(*) as repeticoes,
  string_agg(p.id::text, ', ' order by p.id::text) as purchase_ids
from public.personal_card_installments i
join public.personal_cards c on c.id=i.card_id
join public.personal_card_purchases p on p.id=i.purchase_id
where i.invoice_month='2026-09-01'
group by c.name,p.purchase_date,lower(trim(p.description)),i.amount
having count(*) > 1
order by c.name,p.purchase_date,descricao_normalizada;
