-- REMOÇÃO SEGURA DE DUPLICADOS DAS FATURAS 09/2026
-- Mantém uma única compra por cartão + data + descrição normalizada + valor + nº de parcelas.
-- Quando houver duplicata, prioriza manter a linha da categoria 'Fatura oficial 09/2026'
-- ou 'Crédito/Estorno' e remove a cópia antiga/importada junto com TODAS as parcelas dela.
-- Não altera receitas, despesas, dívidas, reserva, metas, bancos ou pagamentos de fatura.

begin;

create temporary table _dups_keep on commit drop as
with base as (
  select
    p.id,
    p.card_id,
    p.purchase_date,
    p.total_amount,
    p.installments,
    p.category,
    lower(regexp_replace(trim(coalesce(p.description,'')), '[^a-zA-Z0-9]+', '', 'g')) as desc_norm,
    row_number() over (
      partition by
        p.card_id,
        p.purchase_date,
        round(p.total_amount::numeric,2),
        p.installments,
        lower(regexp_replace(trim(coalesce(p.description,'')), '[^a-zA-Z0-9]+', '', 'g'))
      order by
        case
          when p.category='Fatura oficial 09/2026' then 1
          when p.category='Crédito/Estorno' then 2
          when p.category='Importado da fatura' then 3
          else 4
        end,
        p.created_at desc nulls last,
        p.id
    ) as rn,
    count(*) over (
      partition by
        p.card_id,
        p.purchase_date,
        round(p.total_amount::numeric,2),
        p.installments,
        lower(regexp_replace(trim(coalesce(p.description,'')), '[^a-zA-Z0-9]+', '', 'g'))
    ) as qtd
  from public.personal_card_purchases p
  join public.personal_cards c on c.id=p.card_id
  where (
      (lower(c.owner)='larissa' and (lower(c.name) like '%itaú%' or lower(c.name) like '%itau%' or lower(c.name) like '%nubank%'))
      or (lower(c.owner)='igor' and (lower(c.name) like '%igor%' or lower(c.name) like '%banco do brasil%' or lower(c.name) like '%bb%'))
    )
    and exists (
      select 1
      from public.personal_card_installments i
      where i.purchase_id=p.id
        and i.invoice_month >= date '2026-09-01'
        and i.invoice_month <  date '2027-09-01'
    )
)
select id
from base
where qtd>1 and rn>1;

-- Apaga primeiro as parcelas ligadas às compras duplicadas.
delete from public.personal_card_installments i
using _dups_keep d
where i.purchase_id=d.id;

-- Depois apaga somente as compras duplicadas.
delete from public.personal_card_purchases p
using _dups_keep d
where p.id=d.id;

commit;

notify pgrst, 'reload schema';

-- CONFERÊNCIA 1: totais de setembro por cartão
select
  c.name as cartao,
  c.owner as responsavel,
  round(sum(i.amount)::numeric,2) as total_setembro
from public.personal_card_installments i
join public.personal_cards c on c.id=i.card_id
where i.invoice_month=date '2026-09-01'
group by c.name,c.owner
order by c.owner,c.name;

-- CONFERÊNCIA 2: deve retornar ZERO linhas de duplicatas exatas restantes
with base as (
  select
    p.card_id,
    p.purchase_date,
    round(p.total_amount::numeric,2) as total_amount,
    p.installments,
    lower(regexp_replace(trim(coalesce(p.description,'')), '[^a-zA-Z0-9]+', '', 'g')) as desc_norm,
    count(*) as qtd
  from public.personal_card_purchases p
  join public.personal_cards c on c.id=p.card_id
  where (
      (lower(c.owner)='larissa' and (lower(c.name) like '%itaú%' or lower(c.name) like '%itau%' or lower(c.name) like '%nubank%'))
      or (lower(c.owner)='igor' and (lower(c.name) like '%igor%' or lower(c.name) like '%banco do brasil%' or lower(c.name) like '%bb%'))
    )
  group by p.card_id,p.purchase_date,round(p.total_amount::numeric,2),p.installments,
           lower(regexp_replace(trim(coalesce(p.description,'')), '[^a-zA-Z0-9]+', '', 'g'))
)
select * from base where qtd>1 order by qtd desc;
