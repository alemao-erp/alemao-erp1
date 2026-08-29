-- Atualização de custos e preços informados em 29/08/2026
-- Usa correspondência por nome/categoria para atualizar os produtos existentes.

-- Linguiças
update public.products set cost = 24.00, price = 45.00
where lower(name) like '%lingui%';

-- Cocadas cremosas (antes da regra geral de doces)
update public.products set cost = 9.60, price = 25.00
where lower(name) like '%cocada%' and lower(name) like '%cremos%';

-- Goiabada
update public.products set cost = 7.75, price = 20.00
where lower(name) like '%goiabada%';

-- Queijos
update public.products set cost = 30.00, price = 50.00
where lower(name) like '%queijo%';

-- Biscoitos doces 400g: produtos classificados/nomeados como biscoito, rosquinha ou nata recheada
update public.products set cost = 7.25, price = 20.00
where (
  lower(coalesce(category,'')) like '%biscoit%'
  or lower(name) like '%biscoit%'
  or lower(name) like '%rosquinha%'
  or lower(name) like '%nata recheada%'
);

-- Salgadinhos 400g
update public.products set cost = 7.50, price = 20.00
where (
  lower(coalesce(category,'')) like '%salgad%'
  or lower(name) like '%salgad%'
  or lower(name) like '%presunto e queijo%'
);

-- Doces em geral; exclui goiabada e cocada cremosa para preservar as regras específicas acima
update public.products set cost = 9.60, price = 25.00
where (
  lower(coalesce(category,'')) like '%doce%'
  or lower(name) like '%doce%'
  or lower(name) like '%cocada%'
)
and lower(name) not like '%goiabada%'
and not (lower(name) like '%cocada%' and lower(name) like '%cremos%');

-- Conferência
select name, category, cost, price, stock
from public.products
order by name;
