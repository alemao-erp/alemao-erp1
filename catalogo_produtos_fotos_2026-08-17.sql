-- Catálogo de produtos extraído das fotos enviadas em 17/08/2026
-- Seguro para reexecutar: não duplica produtos com o mesmo nome (ignorando maiúsculas/minúsculas e espaços nas pontas).
-- Valores de custo/preço começam em 0 para você preencher depois no ERP.

with catalogo(name, category, min_stock) as (
  values
    ('Biscoitos doces 400g ROSCA FLOCOS. Sabor de Minas', 'Biscoitos', 2::numeric),
    ('Biscoitos doces 400g FLORZINHA RECHEADA (Casadinho). Sabor de Minas', 'Biscoitos', 2::numeric),
    ('Biscoitos doces 400g ROSCA DE COCO. Sabor de Minas', 'Biscoitos', 2::numeric),
    ('Biscoitos doces 400g PALITO DE CHOCOLATE. Sabor de Minas', 'Biscoitos', 2::numeric),
    ('Biscoitos doces 400g ROSCA DE LEITE CONDENSADO. Sabor de Minas', 'Biscoitos', 2::numeric),
    ('Biscoitos doces 400g NATA RECHEADA. Sabor de Minas', 'Biscoitos', 2::numeric),
    ('Salgadinhos Petisco 360g SALSA COM CEBOLINHA. Mundial', 'Salgadinhos', 2::numeric),
    ('Salgadinhos Petisco 360g BACON. Mundial', 'Salgadinhos', 2::numeric),
    ('Salgadinhos Petisco 360g PIZZA. Mundial', 'Salgadinhos', 2::numeric),
    ('Salgadinhos Petisco 360g QUEIJO. Mundial', 'Salgadinhos', 2::numeric),
    ('Salgadinhos Petisco 360g COSTELINHA COM LIMÃO. Mundial', 'Salgadinhos', 2::numeric),
    ('Salgadinhos Petisco 360g PICANHA. Mundial', 'Salgadinhos', 2::numeric),
    ('Salgadinhos Petisco 360g Pimentinha. Mundial', 'Salgadinhos', 2::numeric),
    ('Cocada cremosa com geleia de morango. Delícias de Minas', 'Doces', 2::numeric),
    ('Goiabada cremosa. Delícias de Minas', 'Doces', 2::numeric),
    ('Cocada cremosa. Delícias de Minas', 'Doces', 2::numeric),
    ('Doce de leite e coco. Delícias de Minas', 'Doces', 2::numeric),
    ('Doce de leite com geleia de abacaxi com hortelã. Delícias de Minas', 'Doces', 2::numeric),
    ('Doce de leite com geleia de abacaxi. Delícias de Minas', 'Doces', 2::numeric),
    ('Doce de leite com chocolate. Delícias de Minas', 'Doces', 2::numeric),
    ('Doce de leite com geleia de cereja. Delícias de Minas', 'Doces', 2::numeric),
    ('Doce de leite com geleia de Açaí. Delícias de Minas', 'Doces', 2::numeric),
    ('Doce de leite puro. Delícias de Minas', 'Doces', 2::numeric),
    ('Queijo Minas Artesanal', 'Queijos', 2::numeric),
    ('Linguiça caseira de porco (apimentada)', 'Linguiças', 2::numeric),
    ('Linguiça caseira de porco (defumada)', 'Linguiças', 2::numeric)
)
insert into public.products (name, category, cost, price, stock, min_stock, active)
select c.name, c.category, 0, 0, 0, c.min_stock, true
from catalogo c
where not exists (
  select 1
  from public.products p
  where lower(trim(p.name)) = lower(trim(c.name))
);

notify pgrst, 'reload schema';

-- Conferência dos itens inseridos/existentes
select name, category, cost, price, stock, min_stock
from public.products
where lower(trim(name)) in (
  select lower(trim(name)) from catalogo
)
order by category, name;
