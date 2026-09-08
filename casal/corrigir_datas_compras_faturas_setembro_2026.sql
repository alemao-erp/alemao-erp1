-- CORRIGIR DATAS DAS COMPRAS - FATURAS SETEMBRO/2026
-- NÃO altera valores, parcelas, cartões ou vencimentos.
-- Corrige purchase_date usando as datas reais já cadastradas no SQL oficial da fatura.
-- A data 10/09/2026 continua sendo vencimento quando aplicável, e NÃO data da compra.

begin;

-- ITAÚ LARISSA: corrige lançamentos oficiais pela descrição.
with dados(descricao,data_compra) as (values
('TEXTIL FLORENCA LT',date '2026-07-09'),('CREDITO TEXTIL FLORENCA',date '2026-07-09'),
('TOTEBAG',date '2026-07-16'),('CREDITO TOTEBAG',date '2026-07-16'),
('PRIVALIA 729970',date '2026-07-19'),('CREDITO PRIVALIA',date '2026-07-19'),
('PAGAMENTO*PAULA BR',date '2026-07-27'),('AMAZON BR 07JUL',date '2026-07-07'),
('FPB DE ITAPU-CT DA',date '2026-08-02'),('BAR E BAZAR -CT ENTO',date '2026-08-02'),
('MP *ROCCO -CT',date '2026-08-02'),('PADARIA PAO -CT OZES 02AGO',date '2026-08-02'),
('BACIO DI LAT-CT J0071',date '2026-08-02'),('RECARGAPAY *IGORTHOMA',date '2026-08-03'),
('SHOPEE *VIDALEVSUP',date '2026-08-04'),('DISTRIBUIDOR-CT PH 05AGO',date '2026-08-05'),
('ANUIDADE DIFERENCI',date '2026-08-05'),('VERA LUIZA P-CT TEL T',date '2026-08-06'),
('MP *ASMARIAS',date '2026-08-07'),('MP *ASMARIASSHOES',date '2026-08-07'),
('PADARIA PAO -CT OZES 08AGO',date '2026-08-08'),('CACAU SHOW -CT',date '2026-08-08'),
('SHOPEE *DELCARLLO',date '2026-08-08'),('DISTRIBUIDOR-CT PHIA 08AGO',date '2026-08-08'),
('ESTORNO SHOPEE *DELCARLLO 1',date '2026-08-08'),('ESTORNO SHOPEE *DELCARLLO 2',date '2026-08-08'),
('PADARIA PAO -CT OZES 09AGO',date '2026-08-09'),('NETFLIX.COM',date '2026-08-09'),
('SHOPEE *DECOREVT3D',date '2026-08-09'),('SHOPEE *SEFORASTOR',date '2026-08-11'),
('EXTRABOM SE-CT SEDE',date '2026-08-11'),('SUPERMERCADO-CT QUETO 12AGO',date '2026-08-12'),
('PADARIA PAO -CT OZES 16AGO',date '2026-08-16'),('BARATAO',date '2026-08-18'),
('ASSAI ATACAD-CT LJ324',date '2026-08-18'),('ATACADAO 670-CT',date '2026-08-18'),
('AMAREN FARMACIA E',date '2026-08-19'),('PG *EDUZZ EDZPADREMARI',date '2026-08-21'),
('MP *NEUZANEV-CT O',date '2026-08-21'),('DISTRIBUIDOR-CT PHIA 21AGO',date '2026-08-21'),
('PADARIA PAO -CT OZES 22AGO',date '2026-08-22'),('FEIRA -CT',date '2026-08-22'),
('DEVANIL -CT',date '2026-08-22'),('CLARO P*FATURA CLARO',date '2026-08-25'),
('SUPERMERCADO-CT QUETO 28AGO',date '2026-08-28'),('FABIANA COME-CT DE AL 28AGO',date '2026-08-28'),
('OPA ACAI E S-CT TE SER',date '2026-08-29'),('FABIANA COME-CT DE AL 29AGO',date '2026-08-29'),
('FAZENDA RICO-CT PIRA 19270',date '2026-08-30'),('FAZENDA RICO-CT PIRA 5',date '2026-08-30'),
('FAZENDA RICO-CT PIRA 280',date '2026-08-30'),('AMAZON BR *AMAZO',date '2026-08-31'),
('DISTRIBUIDOR-CT PH 01SET',date '2026-09-01')
)
update public.personal_card_purchases p
set purchase_date=d.data_compra
from dados d, public.personal_cards c
where p.card_id=c.id and p.description=d.descricao
  and lower(c.owner)='larissa' and (lower(c.name) like '%itaú%' or lower(c.name) like '%itau%')
  and p.category in ('Fatura oficial 09/2026','Crédito/Estorno');

-- IMPORTANTE: parcelas/vencimentos não são alterados.
commit;

-- Conferência: mostra data real da compra e vencimento da parcela lado a lado.
select c.name as cartao,p.purchase_date as data_compra,p.description,
       i.installment_number||'/'||i.installments_total as parcela,
       i.amount as valor,i.due_date as vencimento
from public.personal_card_installments i
join public.personal_card_purchases p on p.id=i.purchase_id
join public.personal_cards c on c.id=i.card_id
where i.invoice_month=date '2026-09-01'
  and lower(c.owner)='larissa'
  and (lower(c.name) like '%itaú%' or lower(c.name) like '%itau%')
order by p.purchase_date,p.description;