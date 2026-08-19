-- DADOS INICIAIS IGOR & LARISSA
-- Execute DEPOIS de casal/supabase_financas_casal.sql
-- Evita duplicar registros principais ao reexecutar.

-- RECEITAS RECORRENTES
insert into public.personal_income(person,description,amount,income_date,recurring,notes)
select 'Igor','Salário líquido Igor',3000,current_date,true,'Valor informado em 13/08/2026'
where not exists(select 1 from public.personal_income where description='Salário líquido Igor');

insert into public.personal_income(person,description,amount,income_date,recurring,notes)
select 'Larissa','Salário líquido Larissa',2000,current_date,true,'Valor informado em 13/08/2026'
where not exists(select 1 from public.personal_income where description='Salário líquido Larissa');

insert into public.personal_income(person,description,amount,income_date,recurring,notes)
select 'Casal','Prestação da casa vendida',1000,current_date,true,'Receita temporária prevista até agosto de 2027'
where not exists(select 1 from public.personal_income where description='Prestação da casa vendida');

-- DESPESAS MENSAIS CONHECIDAS
insert into public.personal_expenses(person,description,category,amount,expense_date,paid,recurring,notes)
select 'Casal','Seguro do carro','Transporte',256.21,current_date,true,true,'Valor de referência informado anteriormente; confirmar valor atual'
where not exists(select 1 from public.personal_expenses where description='Seguro do carro');

insert into public.personal_expenses(person,description,category,amount,expense_date,paid,recurring)
select 'Casal','Celulares','Comunicação',90.27,current_date,true,true
where not exists(select 1 from public.personal_expenses where description='Celulares');

insert into public.personal_expenses(person,description,category,amount,expense_date,paid,recurring)
select 'Casal','Água e luz','Casa',315,current_date,true,true
where not exists(select 1 from public.personal_expenses where description='Água e luz');

insert into public.personal_expenses(person,description,category,amount,expense_date,paid,recurring)
select 'Casal','Internet','Casa',100,current_date,true,true
where not exists(select 1 from public.personal_expenses where description='Internet');

insert into public.personal_expenses(person,description,category,amount,expense_date,paid,recurring)
select 'Larissa','Plano de saúde Larissa','Saúde',400,current_date,true,true
where not exists(select 1 from public.personal_expenses where description='Plano de saúde Larissa');

insert into public.personal_expenses(person,description,category,amount,expense_date,paid,recurring,notes)
select 'Casal','Combustível','Transporte',200,current_date,true,true,'Valor de referência anterior; ajustar se necessário'
where not exists(select 1 from public.personal_expenses where description='Combustível');

insert into public.personal_expenses(person,description,category,amount,expense_date,paid,recurring,notes)
select 'Casal','Dízimo','Religioso',450,current_date,true,true,'Estimativa anterior. Regra informada: 10% da renda líquida. Confirmar valor atual.'
where not exists(select 1 from public.personal_expenses where description='Dízimo');

-- DÍVIDAS / FINANCIAMENTOS
insert into public.personal_debts(name,owner,debt_type,installment_amount,installments_left,active,notes)
select 'Financiamento do carro','Casal','Veículo',1042,45,true,'Parcela aproximada informada em 13/08/2026'
where not exists(select 1 from public.personal_debts where name='Financiamento do carro');

insert into public.personal_debts(name,owner,debt_type,installment_amount,installments_left,active,notes)
select 'Financiamento da casa','Casal','Imóvel',960,399,true,'Quantidade de parcelas conforme informação de 13/08/2026'
where not exists(select 1 from public.personal_debts where name='Financiamento da casa');

insert into public.personal_debts(name,owner,debt_type,installment_amount,current_balance,active,notes)
select 'Cartão Igor','Igor','Cartão de crédito',0,1031,true,'Saldo informado em 13/08/2026'
where not exists(select 1 from public.personal_debts where name='Cartão Igor');

insert into public.personal_debts(name,owner,debt_type,installment_amount,current_balance,active,notes)
select 'Cartão Larissa Itaú','Larissa','Cartão de crédito',0,2500,true,'Saldo informado em 13/08/2026'
where not exists(select 1 from public.personal_debts where name='Cartão Larissa Itaú');

insert into public.personal_debts(name,owner,debt_type,installment_amount,current_balance,active,notes)
select 'Cartão Larissa Nubank','Larissa','Cartão de crédito',0,1000,true,'Saldo informado em 13/08/2026'
where not exists(select 1 from public.personal_debts where name='Cartão Larissa Nubank');

-- RESERVA
insert into public.personal_assets(name,asset_type,amount,owner,liquidity,notes)
select 'Reserva financeira','Reserva',120000,'Casal','Alta','Valor informado em 13/08/2026'
where not exists(select 1 from public.personal_assets where name='Reserva financeira');

notify pgrst,'reload schema';
