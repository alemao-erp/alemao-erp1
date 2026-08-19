-- ALEMÃO PRODUTOS DA ROÇA
-- Atualização de preços + novos produtos
-- Data: 2026-08-19
-- Seguro para reexecução: atualiza preços sem mexer no estoque e evita duplicar os novos produtos.

begin;

-- =========================================================
-- 1) ATUALIZAÇÃO DOS PRODUTOS JÁ EXISTENTES
-- =========================================================

-- Salgadinhos: custo 7,50 / venda 20,00
update public.products
set cost = 7.50, price = 20.00
where lower(coalesce(category,'')) like '%salgad%'
   or lower(name) like '%salgadinho%'
   or lower(name) like '%petisco%';

-- Doces / cocadas / goiabadas / doce de leite: custo 9,60 / venda 25,00
update public.products
set cost = 9.60, price = 25.00
where lower(coalesce(category,'')) like '%doce%'
   or lower(name) like '%cocada%'
   or lower(name) like '%goiabada%'
   or lower(name) like '%doce de leite%';

-- Biscoitos já cadastrados (exceto os 6 novos abaixo): custo 7,25 / venda 20,00
update public.products
set cost = 7.25, price = 20.00
where (
       lower(coalesce(category,'')) like '%biscoit%'
       or lower(name) like '%biscoito%'
      )
  and lower(trim(name)) not in (
    'biscoito amanteigado',
    'biscoito raspas de limao',
    'biscoito raspas de limão',
    'biscoito rosquinha de nata',
    'biscoito leite condensado',
    'biscoito casadinho',
    'biscoito canela'
  );

-- Linguiças: custo 24,00 / venda 45,00
update public.products
set cost = 24.00, price = 45.00
where lower(coalesce(category,'')) like '%lingui%'
   or lower(name) like '%lingui%';

-- Queijos: custo total 30,00 (28 + 2 transporte) / venda 50,00
update public.products
set cost = 30.00, price = 50.00
where lower(coalesce(category,'')) like '%queijo%'
   or lower(name) like '%queijo%';

-- =========================================================
-- 2) NOVOS PRODUTOS
-- Estoque inicial = 0; estoque mínimo = 2
-- =========================================================

with novos(name, category, cost, price) as (
  values
    ('AMENDOIM CROCANTE 400g JAPONES Delicias de Minas', 'Amendoim', 7.50::numeric, 20.00::numeric),
    ('AMENDOIM CROCANTE 400g CHURRASCO Delicias de Minas', 'Amendoim', 7.50, 20.00),
    ('AMENDOIM CROCANTE 400g CEBOLA E SALSA Delicias de Minas', 'Amendoim', 7.50, 20.00),
    ('AMENDOIM CROCANTE 400g NATURAL Delicias de Minas', 'Amendoim', 7.50, 20.00),

    ('FAROFA sabor alho Delicias de Minas', 'Farofa', 5.20, 12.00),
    ('FAROFA sabor churrasco Delicias de Minas', 'Farofa', 5.20, 12.00),
    ('FAROFA sabor costelinha com limao Delicias de Minas', 'Farofa', 5.20, 12.00),
    ('FAROFA sabor costela Delicias de Minas', 'Farofa', 5.20, 12.00),
    ('FAROFA sabor picanha Delicias de Minas', 'Farofa', 5.20, 12.00),
    ('FAROFA sabor bacon Delicias de Minas', 'Farofa', 5.20, 12.00),

    ('BISCOITO AMANTEIGADO', 'Biscoitos', 5.55, 12.00),
    ('BISCOITO RASPAS DE LIMAO', 'Biscoitos', 5.55, 12.00),
    ('BISCOITO ROSQUINHA DE NATA', 'Biscoitos', 5.55, 12.00),
    ('BISCOITO LEITE CONDENSADO', 'Biscoitos', 5.55, 12.00),
    ('BISCOITO CASADINHO', 'Biscoitos', 5.55, 12.00),
    ('BISCOITO CANELA', 'Biscoitos', 5.55, 12.00)
)
insert into public.products(name, category, cost, price, stock, min_stock, active)
select n.name, n.category, n.cost, n.price, 0, 2, true
from novos n
where not exists (
  select 1
  from public.products p
  where lower(trim(p.name)) = lower(trim(n.name))
);

-- Se algum dos novos produtos já existia, padroniza os preços sem mexer no estoque.
with novos(name, category, cost, price) as (
  values
    ('AMENDOIM CROCANTE 400g JAPONES Delicias de Minas', 'Amendoim', 7.50::numeric, 20.00::numeric),
    ('AMENDOIM CROCANTE 400g CHURRASCO Delicias de Minas', 'Amendoim', 7.50, 20.00),
    ('AMENDOIM CROCANTE 400g CEBOLA E SALSA Delicias de Minas', 'Amendoim', 7.50, 20.00),
    ('AMENDOIM CROCANTE 400g NATURAL Delicias de Minas', 'Amendoim', 7.50, 20.00),
    ('FAROFA sabor alho Delicias de Minas', 'Farofa', 5.20, 12.00),
    ('FAROFA sabor churrasco Delicias de Minas', 'Farofa', 5.20, 12.00),
    ('FAROFA sabor costelinha com limao Delicias de Minas', 'Farofa', 5.20, 12.00),
    ('FAROFA sabor costela Delicias de Minas', 'Farofa', 5.20, 12.00),
    ('FAROFA sabor picanha Delicias de Minas', 'Farofa', 5.20, 12.00),
    ('FAROFA sabor bacon Delicias de Minas', 'Farofa', 5.20, 12.00),
    ('BISCOITO AMANTEIGADO', 'Biscoitos', 5.55, 12.00),
    ('BISCOITO RASPAS DE LIMAO', 'Biscoitos', 5.55, 12.00),
    ('BISCOITO ROSQUINHA DE NATA', 'Biscoitos', 5.55, 12.00),
    ('BISCOITO LEITE CONDENSADO', 'Biscoitos', 5.55, 12.00),
    ('BISCOITO CASADINHO', 'Biscoitos', 5.55, 12.00),
    ('BISCOITO CANELA', 'Biscoitos', 5.55, 12.00)
)
update public.products p
set category = n.category,
    cost = n.cost,
    price = n.price,
    active = true
from novos n
where lower(trim(p.name)) = lower(trim(n.name));

notify pgrst, 'reload schema';

commit;

-- Conferência final
select name, category, cost, price, stock, min_stock
from public.products
order by category, name;
