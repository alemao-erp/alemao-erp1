-- CORREÇÃO DAS FATURAS DE SETEMBRO/2026
-- Igor & Larissa - app do casal
-- Objetivo: substituir SOMENTE os lançamentos importados pelo script anterior
-- e reconstruir setembro/2026 com as compras/parcelas e créditos/estornos.
-- NÃO mexe em receitas, despesas, dívidas, reserva, metas ou bancos.

begin;

-- 1) Localiza cartões e remove somente as importações anteriores feitas pelo script antigo.
--    Compras cadastradas manualmente com outras categorias são preservadas.
with cards_alvo as (
  select id from public.personal_cards
  where (lower(owner)='larissa' and (lower(name) like '%itaú%' or lower(name) like '%itau%' or lower(name) like '%nubank%'))
     or (lower(owner)='igor' and (lower(name) like '%igor%' or lower(name) like '%banco do brasil%' or lower(name) like '%bb%'))
), compras_antigas as (
  select p.id
  from public.personal_card_purchases p
  join cards_alvo c on c.id=p.card_id
  where p.category='Importado da fatura'
)
delete from public.personal_card_installments i
using compras_antigas a
where i.purchase_id=a.id;

with cards_alvo as (
  select id from public.personal_cards
  where (lower(owner)='larissa' and (lower(name) like '%itaú%' or lower(name) like '%itau%' or lower(name) like '%nubank%'))
     or (lower(owner)='igor' and (lower(name) like '%igor%' or lower(name) like '%banco do brasil%' or lower(name) like '%bb%'))
)
delete from public.personal_card_purchases p
using cards_alvo c
where p.card_id=c.id
  and p.category='Importado da fatura';

-- 2) Função auxiliar: adiciona compra/estorno e gera a parcela atual + parcelas futuras.
create or replace function pg_temp.add_fatura_line(
  p_owner text,
  p_card_hint text,
  p_desc text,
  p_date date,
  p_amount numeric,
  p_current int,
  p_total int,
  p_invoice date,
  p_category text default 'Fatura oficial 09/2026'
) returns void language plpgsql as $$
declare
  v_card uuid;
  v_purchase uuid;
  v_n int;
  v_invoice date;
  v_due_day int;
  v_due date;
begin
  select id, coalesce(due_day,10)
    into v_card, v_due_day
  from public.personal_cards
  where lower(owner)=lower(p_owner)
    and lower(name) like '%'||lower(p_card_hint)||'%'
  order by name
  limit 1;

  if v_card is null then
    select id, coalesce(due_day,10)
      into v_card, v_due_day
    from public.personal_cards
    where lower(owner)=lower(p_owner)
    order by name
    limit 1;
  end if;

  if v_card is null then
    raise exception 'Cartão não encontrado: % / %', p_owner, p_card_hint;
  end if;

  select id into v_purchase
  from public.personal_card_purchases
  where card_id=v_card
    and description=p_desc
    and purchase_date=p_date
    and abs(total_amount-(p_amount*p_total))<0.02
  limit 1;

  if v_purchase is null then
    insert into public.personal_card_purchases(
      card_id, description, category, purchase_date, total_amount, installments
    ) values (
      v_card, p_desc, p_category, p_date, round(p_amount*p_total,2), p_total
    ) returning id into v_purchase;
  end if;

  for v_n in p_current..p_total loop
    v_invoice := (p_invoice + ((v_n-p_current)||' months')::interval)::date;
    v_due := make_date(
      extract(year from v_invoice)::int,
      extract(month from v_invoice)::int,
      least(v_due_day, extract(day from (date_trunc('month',v_invoice)+interval '1 month - 1 day'))::int)
    );

    if not exists (
      select 1 from public.personal_card_installments
      where purchase_id=v_purchase and installment_number=v_n
    ) then
      insert into public.personal_card_installments(
        purchase_id, card_id, installment_number, installments_total,
        amount, invoice_month, due_date, paid
      ) values (
        v_purchase, v_card, v_n, p_total,
        p_amount, v_invoice, v_due, false
      );
    end if;
  end loop;
end $$;

-- ============================================================
-- ITAÚ LARISSA - FATURA OFICIAL SETEMBRO/2026
-- Total oficial da fatura: R$ 3.272,57
-- Inclui compras, parcelas e créditos/estornos que aparecem no PDF.
-- ============================================================

-- Parceladas / compras anteriores que caíram nesta fatura
select pg_temp.add_fatura_line('Larissa','Itaú','TEXTIL FLORENCA LT','2026-07-09',59.99,2,5,'2026-09-01');
select pg_temp.add_fatura_line('Larissa','Itaú','CREDITO TEXTIL FLORENCA','2026-07-09',-0.04,1,1,'2026-09-01','Crédito/Estorno');
select pg_temp.add_fatura_line('Larissa','Itaú','TOTEBAG','2026-07-16',69.34,2,3,'2026-09-01');
select pg_temp.add_fatura_line('Larissa','Itaú','CREDITO TOTEBAG','2026-07-16',-0.02,1,1,'2026-09-01','Crédito/Estorno');
select pg_temp.add_fatura_line('Larissa','Itaú','PRIVALIA 729970','2026-07-19',97.00,2,3,'2026-09-01');
select pg_temp.add_fatura_line('Larissa','Itaú','CREDITO PRIVALIA','2026-07-19',-0.02,1,1,'2026-09-01','Crédito/Estorno');

-- Compras de agosto
select pg_temp.add_fatura_line('Larissa','Itaú','FPB DE ITAPU-CT DA','2026-08-02',3.99,1,1,'2026-09-01');
select pg_temp.add_fatura_line('Larissa','Itaú','BAR E BAZAR -CT ENTO','2026-08-02',24.00,1,1,'2026-09-01');
select pg_temp.add_fatura_line('Larissa','Itaú','MP *ROCCO -CT','2026-08-02',154.89,1,1,'2026-09-01');
select pg_temp.add_fatura_line('Larissa','Itaú','PADARIA PAO -CT OZES 02AGO','2026-08-02',16.36,1,1,'2026-09-01');
select pg_temp.add_fatura_line('Larissa','Itaú','BACIO DI LAT-CT J0071','2026-08-02',33.95,1,1,'2026-09-01');
select pg_temp.add_fatura_line('Larissa','Itaú','DISTRIBUIDOR-CT PH 05AGO','2026-08-05',160.50,1,2,'2026-09-01');
select pg_temp.add_fatura_line('Larissa','Itaú','ANUIDADE DIFERENCI','2026-08-05',47.50,1,12,'2026-09-01');
select pg_temp.add_fatura_line('Larissa','Itaú','VERA LUIZA P-CT TEL T','2026-08-06',10.32,1,1,'2026-09-01');
select pg_temp.add_fatura_line('Larissa','Itaú','MP *ASMARIAS','2026-08-07',67.44,1,4,'2026-09-01');
select pg_temp.add_fatura_line('Larissa','Itaú','MP *ASMARIASSHOES','2026-08-07',55.00,1,2,'2026-09-01');
select pg_temp.add_fatura_line('Larissa','Itaú','PADARIA PAO -CT OZES 08AGO','2026-08-08',8.64,1,1,'2026-09-01');
select pg_temp.add_fatura_line('Larissa','Itaú','CACAU SHOW -CT','2026-08-08',6.45,1,1,'2026-09-01');
select pg_temp.add_fatura_line('Larissa','Itaú','SHOPEE *DELCARLLO','2026-08-08',60.96,1,7,'2026-09-01');
select pg_temp.add_fatura_line('Larissa','Itaú','DISTRIBUIDOR-CT PHIA 08AGO','2026-08-08',408.00,1,1,'2026-09-01');
select pg_temp.add_fatura_line('Larissa','Itaú','ESTORNO SHOPEE *DELCARLLO 1','2026-08-08',-213.08,1,1,'2026-09-01','Crédito/Estorno');
select pg_temp.add_fatura_line('Larissa','Itaú','ESTORNO SHOPEE *DELCARLLO 2','2026-08-08',-32.56,1,1,'2026-09-01','Crédito/Estorno');
select pg_temp.add_fatura_line('Larissa','Itaú','PADARIA PAO -CT OZES 09AGO','2026-08-09',20.72,1,1,'2026-09-01');
select pg_temp.add_fatura_line('Larissa','Itaú','NETFLIX.COM','2026-08-09',72.80,1,1,'2026-09-01');
select pg_temp.add_fatura_line('Larissa','Itaú','SHOPEE *DECOREVT3D','2026-08-09',19.99,1,1,'2026-09-01');
select pg_temp.add_fatura_line('Larissa','Itaú','SHOPEE *SEFORASTOR','2026-08-11',61.69,1,1,'2026-09-01');
select pg_temp.add_fatura_line('Larissa','Itaú','EXTRABOM SE-CT SEDE','2026-08-11',14.79,1,1,'2026-09-01');
select pg_temp.add_fatura_line('Larissa','Itaú','SUPERMERCADO-CT QUETO 12AGO','2026-08-12',40.97,1,1,'2026-09-01');
select pg_temp.add_fatura_line('Larissa','Itaú','PADARIA PAO -CT OZES 16AGO','2026-08-16',38.51,1,1,'2026-09-01');
select pg_temp.add_fatura_line('Larissa','Itaú','BARATAO','2026-08-18',169.22,1,1,'2026-09-01');
select pg_temp.add_fatura_line('Larissa','Itaú','ASSAI ATACAD-CT LJ324','2026-08-18',73.05,1,1,'2026-09-01');
select pg_temp.add_fatura_line('Larissa','Itaú','ATACADAO 670-CT','2026-08-18',30.75,1,1,'2026-09-01');
select pg_temp.add_fatura_line('Larissa','Itaú','AMAREN FARMACIA E','2026-08-19',327.00,1,3,'2026-09-01');
select pg_temp.add_fatura_line('Larissa','Itaú','PG *EDUZZ EDZPADREMARI','2026-08-21',79.91,1,1,'2026-09-01');
select pg_temp.add_fatura_line('Larissa','Itaú','MP *NEUZANEV-CT O','2026-08-21',3.20,1,1,'2026-09-01');
select pg_temp.add_fatura_line('Larissa','Itaú','DISTRIBUIDOR-CT PHIA 21AGO','2026-08-21',234.00,1,1,'2026-09-01');
select pg_temp.add_fatura_line('Larissa','Itaú','PADARIA PAO -CT OZES 22AGO','2026-08-22',6.59,1,1,'2026-09-01');
select pg_temp.add_fatura_line('Larissa','Itaú','FEIRA -CT','2026-08-22',5.00,1,1,'2026-09-01');
select pg_temp.add_fatura_line('Larissa','Itaú','DEVANIL -CT','2026-08-22',12.00,1,1,'2026-09-01');
select pg_temp.add_fatura_line('Larissa','Itaú','CLARO P*FATURA CLARO','2026-08-25',46.13,1,1,'2026-09-01');
select pg_temp.add_fatura_line('Larissa','Itaú','SUPERMERCADO-CT QUETO 28AGO','2026-08-28',5.99,1,1,'2026-09-01');
select pg_temp.add_fatura_line('Larissa','Itaú','FABIANA COME-CT DE AL 28AGO','2026-08-28',25.00,1,1,'2026-09-01');
select pg_temp.add_fatura_line('Larissa','Itaú','OPA ACAI E S-CT TE SER','2026-08-29',19.17,1,1,'2026-09-01');
select pg_temp.add_fatura_line('Larissa','Itaú','FABIANA COME-CT DE AL 29AGO','2026-08-29',43.00,1,1,'2026-09-01');
select pg_temp.add_fatura_line('Larissa','Itaú','FAZENDA RICO-CT PIRA 19270','2026-08-30',192.70,1,1,'2026-09-01');
select pg_temp.add_fatura_line('Larissa','Itaú','FAZENDA RICO-CT PIRA 5','2026-08-30',5.00,1,1,'2026-09-01');
select pg_temp.add_fatura_line('Larissa','Itaú','FAZENDA RICO-CT PIRA 280','2026-08-30',280.00,1,1,'2026-09-01');
select pg_temp.add_fatura_line('Larissa','Itaú','AMAZON BR *AMAZO','2026-08-31',48.42,1,6,'2026-09-01');
select pg_temp.add_fatura_line('Larissa','Itaú','DISTRIBUIDOR-CT PH 01SET','2026-09-01',160.50,1,2,'2026-09-01');

-- Outros cartões Itaú vinculados à mesma fatura
select pg_temp.add_fatura_line('Larissa','Itaú','SHOPEE *VIDALEVSUP','2026-08-04',94.50,1,2,'2026-09-01');
select pg_temp.add_fatura_line('Larissa','Itaú','RECARGAPAY *IGORTHOMA','2026-08-03',20.00,1,1,'2026-09-01');
select pg_temp.add_fatura_line('Larissa','Itaú','PAGAMENTO*PAULA BR','2026-07-27',77.00,2,2,'2026-09-01');
select pg_temp.add_fatura_line('Larissa','Itaú','AMAZON BR 07JUL','2026-07-07',54.06,2,6,'2026-09-01');
select pg_temp.add_fatura_line('Larissa','Itaú','CREDITO AMAZON BR','2026-07-07',-0.20,1,1,'2026-09-01','Crédito/Estorno');
select pg_temp.add_fatura_line('Larissa','Itaú','ESTORNO DE ANUIDADE DIF','2026-09-02',-47.50,1,1,'2026-09-01','Crédito/Estorno');

-- ============================================================
-- NUBANK LARISSA - conforme lançamentos já transcritos do comprovante enviado.
-- Não há PDF do Nubank disponível neste repositório; portanto este bloco preserva
-- os lançamentos previamente transcritos. Se houver novo estorno/adiantamento,
-- ele deve ser acrescentado como valor negativo.
-- ============================================================
select pg_temp.add_fatura_line('Larissa','Nubank','Cartao de Todos Ago','2026-08-19',33.40,1,1,'2026-09-01');
select pg_temp.add_fatura_line('Larissa','Nubank','Conta Vivo','2026-08-18',60.00,1,1,'2026-09-01');
select pg_temp.add_fatura_line('Larissa','Nubank','Asa*Academia Naturalis','2026-08-16',152.80,1,5,'2026-09-01');
select pg_temp.add_fatura_line('Larissa','Nubank','Raia Drogasil - NuPay','2026-08-09',51.70,1,1,'2026-09-01');
select pg_temp.add_fatura_line('Larissa','Nubank','Amazon','2026-08-04',93.44,10,12,'2026-09-01');
select pg_temp.add_fatura_line('Larissa','Nubank','030 - Es Vila Velha Pr','2026-08-04',56.66,3,3,'2026-09-01');
select pg_temp.add_fatura_line('Larissa','Nubank','Magalu *Magalu','2026-08-04',47.08,3,5,'2026-09-01');
select pg_temp.add_fatura_line('Larissa','Nubank','Amaren Farmacia e Mani','2026-08-04',251.66,3,3,'2026-09-01');
select pg_temp.add_fatura_line('Larissa','Nubank','Sennaveiculos','2026-08-04',178.00,4,5,'2026-09-01');
select pg_temp.add_fatura_line('Larissa','Nubank','Greenn**Nutriconecta C','2026-08-04',61.68,10,12,'2026-09-01');
select pg_temp.add_fatura_line('Larissa','Nubank','Paula Breder Tower A','2026-08-04',178.06,3,3,'2026-09-01');
select pg_temp.add_fatura_line('Larissa','Nubank','Paula Breder Tower B','2026-08-04',108.40,3,3,'2026-09-01');
select pg_temp.add_fatura_line('Larissa','Nubank','Htm*Teresinha Marcia D','2026-08-04',29.64,10,12,'2026-09-01');
select pg_temp.add_fatura_line('Larissa','Nubank','Mp *Wepink','2026-08-04',67.67,4,6,'2026-09-01');

-- ============================================================
-- BANCO DO BRASIL / CARTÃO IGOR - FATURA OFICIAL SETEMBRO/2026
-- Total oficial da fatura: R$ 1.030,11
-- ============================================================
select pg_temp.add_fatura_line('Igor','Igor','MP*SHELLBOX','2026-08-06',40.00,1,1,'2026-09-01');
select pg_temp.add_fatura_line('Igor','Igor','HTM*DecadaMil','2025-10-27',399.00,11,12,'2026-09-01');
select pg_temp.add_fatura_line('Igor','Igor','AMAZON MARKET','2025-12-06',130.76,9,10,'2026-09-01');
select pg_temp.add_fatura_line('Igor','Igor','Foco Aluguel 03mar','2026-03-03',51.58,6,6,'2026-09-01');
select pg_temp.add_fatura_line('Igor','Igor','Foco Aluguel 30abr','2026-04-30',76.07,4,6,'2026-09-01');
select pg_temp.add_fatura_line('Igor','Igor','ATACADO DO TH','2026-06-13',37.00,3,3,'2026-09-01');
select pg_temp.add_fatura_line('Igor','Igor','ZURICH SEGURO','2026-06-22',210.70,3,12,'2026-09-01');
select pg_temp.add_fatura_line('Igor','Igor','AUTOGLASS','2026-06-24',85.00,3,3,'2026-09-01');

-- O pagamento/crédito de R$ 1.203,42 quitou a fatura anterior e não é nova despesa
-- de setembro; por isso não é somado às compras atuais. O total oficial desta
-- fatura permanece R$ 1.030,11.

-- 3) Verificação dos totais gravados para setembro/2026.
-- Itaú deve resultar em 3272.57 e Cartão Igor em 1030.11.
select
  c.name as cartao,
  c.owner as responsavel,
  i.invoice_month,
  round(sum(i.amount)::numeric,2) as total_setembro
from public.personal_card_installments i
join public.personal_cards c on c.id=i.card_id
where i.invoice_month='2026-09-01'
group by c.name,c.owner,i.invoice_month
order by c.owner,c.name;

commit;

notify pgrst, 'reload schema';
