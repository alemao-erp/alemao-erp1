-- Corrige vencimentos das parcelas usando o dia de vencimento cadastrado em cada cartão.
-- Seguro para executar mais de uma vez: apenas recalcula due_date.

update public.personal_card_installments i
set due_date = make_date(
  extract(year from i.invoice_month)::int,
  extract(month from i.invoice_month)::int,
  least(
    coalesce(c.due_day,1),
    extract(day from (date_trunc('month',i.invoice_month) + interval '1 month - 1 day'))::int
  )
)
from public.personal_cards c
where c.id=i.card_id;

notify pgrst, 'reload schema';
