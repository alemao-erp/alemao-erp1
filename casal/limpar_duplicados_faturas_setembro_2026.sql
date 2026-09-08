-- LIMPEZA SEGURA DAS IMPORTAÇÕES DE FATURAS SETEMBRO/2026
-- Remove somente lançamentos criados pelos scripts de importação/correção.
-- Não apaga compras cadastradas manualmente com outras categorias.

begin;

with cards_alvo as (
  select id
  from public.personal_cards
  where (lower(owner)='larissa' and (lower(name) like '%itaú%' or lower(name) like '%itau%' or lower(name) like '%nubank%'))
     or (lower(owner)='igor' and (lower(name) like '%igor%' or lower(name) like '%banco do brasil%' or lower(name) like '%bb%'))
), compras_script as (
  select p.id
  from public.personal_card_purchases p
  join cards_alvo c on c.id=p.card_id
  where p.category in ('Importado da fatura','Fatura oficial 09/2026','Crédito/Estorno')
)
delete from public.personal_card_installments i
using compras_script x
where i.purchase_id=x.id;

with cards_alvo as (
  select id
  from public.personal_cards
  where (lower(owner)='larissa' and (lower(name) like '%itaú%' or lower(name) like '%itau%' or lower(name) like '%nubank%'))
     or (lower(owner)='igor' and (lower(name) like '%igor%' or lower(name) like '%banco do brasil%' or lower(name) like '%bb%'))
)
delete from public.personal_card_purchases p
using cards_alvo c
where p.card_id=c.id
  and p.category in ('Importado da fatura','Fatura oficial 09/2026','Crédito/Estorno');

commit;

notify pgrst, 'reload schema';

-- Conferência: deve retornar zero linhas dessas categorias após a limpeza.
select c.name as cartao, p.category, count(*) as quantidade
from public.personal_card_purchases p
join public.personal_cards c on c.id=p.card_id
where p.category in ('Importado da fatura','Fatura oficial 09/2026','Crédito/Estorno')
group by c.name,p.category
order by c.name,p.category;
