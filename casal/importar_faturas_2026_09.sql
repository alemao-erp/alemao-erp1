-- IMPORTAÇÃO DE FATURAS - SETEMBRO/2026
-- Execute este arquivo no SQL Editor do Supabase.
-- Ele localiza os cartões por nome/responsável e evita duplicar compras idênticas.

create or replace function pg_temp.add_card_purchase(
  p_owner text, p_card_hint text, p_desc text, p_date date,
  p_amount numeric, p_current int, p_total int, p_invoice date
) returns void language plpgsql as $$
declare
  v_card uuid; v_purchase uuid; v_n int; v_amt numeric;
begin
  select id into v_card from public.personal_cards
   where lower(owner)=lower(p_owner) and lower(name) like '%'||lower(p_card_hint)||'%'
   order by name limit 1;
  if v_card is null then
    select id into v_card from public.personal_cards where lower(owner)=lower(p_owner) order by name limit 1;
  end if;
  if v_card is null then raise exception 'Cartão não encontrado: % / %',p_owner,p_card_hint; end if;

  select id into v_purchase from public.personal_card_purchases
   where card_id=v_card and description=p_desc and purchase_date=p_date
     and abs(total_amount-(p_amount*p_total))<0.02 limit 1;
  if v_purchase is null then
    insert into public.personal_card_purchases(card_id,description,category,purchase_date,total_amount,installments)
    values(v_card,p_desc,'Importado da fatura',p_date,round(p_amount*p_total,2),p_total)
    returning id into v_purchase;
  end if;

  for v_n in p_current..p_total loop
    v_amt:=p_amount;
    if not exists(select 1 from public.personal_card_installments where purchase_id=v_purchase and installment_number=v_n) then
      insert into public.personal_card_installments(purchase_id,card_id,installment_number,installments_total,amount,invoice_month,due_date,paid)
      values(v_purchase,v_card,v_n,p_total,v_amt,(p_invoice + ((v_n-p_current)||' months')::interval)::date,
        (p_invoice + ((v_n-p_current)||' months')::interval)::date,false);
    end if;
  end loop;
end $$;

-- ITAÚ LARISSA - fatura setembro/2026
select pg_temp.add_card_purchase('Larissa','Itaú','Mp *asmarias','2026-08-07',67.44,1,4,'2026-09-01');
select pg_temp.add_card_purchase('Larissa','Itaú','Mp *asmariasshoes','2026-08-07',55.00,1,2,'2026-09-01');
select pg_temp.add_card_purchase('Larissa','Itaú','Vera luiza p-ct tel t','2026-08-06',10.32,1,1,'2026-09-01');
select pg_temp.add_card_purchase('Larissa','Itaú','Distribuidor-ct pho','2026-08-05',160.50,1,2,'2026-09-01');
select pg_temp.add_card_purchase('Larissa','Itaú','Anuidade diferencio','2026-08-05',47.50,1,12,'2026-09-01');
select pg_temp.add_card_purchase('Larissa','Itaú','Shopee *vidalevsup','2026-08-04',94.50,1,2,'2026-09-01');
select pg_temp.add_card_purchase('Larissa','Itaú','Recargapay *igorthoma','2026-08-03',20.00,1,1,'2026-09-01');
select pg_temp.add_card_purchase('Larissa','Itaú','Mp *rocco -ct','2026-08-02',154.89,1,1,'2026-09-01');
select pg_temp.add_card_purchase('Larissa','Itaú','Bacio di lat-ct j0071','2026-08-02',33.95,1,1,'2026-09-01');
select pg_temp.add_card_purchase('Larissa','Itaú','Padaria pao -ct ozes','2026-08-01',16.36,1,1,'2026-09-01');
select pg_temp.add_card_purchase('Larissa','Itaú','Fpb de itapu-ct da','2026-08-01',3.99,1,1,'2026-09-01');
select pg_temp.add_card_purchase('Larissa','Itaú','Bar e bazar -ct ento','2026-08-01',24.00,1,1,'2026-09-01');
select pg_temp.add_card_purchase('Larissa','Itaú','Pagamento*paula br','2026-07-27',77.00,2,2,'2026-09-01');
select pg_temp.add_card_purchase('Larissa','Itaú','Pri*privalia 729970','2026-07-19',97.00,2,3,'2026-09-01');
select pg_temp.add_card_purchase('Larissa','Itaú','Totebag','2026-07-10',69.34,2,3,'2026-09-01');
select pg_temp.add_card_purchase('Larissa','Itaú','Textil florenca lt','2026-07-09',59.99,2,5,'2026-09-01');
select pg_temp.add_card_purchase('Larissa','Itaú','Amazon br','2026-07-07',54.06,2,6,'2026-09-01');
select pg_temp.add_card_purchase('Larissa','Itaú','Atacadao 670-ct','2026-08-18',30.75,1,1,'2026-09-01');
select pg_temp.add_card_purchase('Larissa','Itaú','Assai atacad-ct lj324','2026-08-18',73.05,1,1,'2026-09-01');
select pg_temp.add_card_purchase('Larissa','Itaú','Baratao','2026-08-18',169.22,1,1,'2026-09-01');
select pg_temp.add_card_purchase('Larissa','Itaú','Padaria pao -ct ozes 16ago','2026-08-16',38.51,1,1,'2026-09-01');
select pg_temp.add_card_purchase('Larissa','Itaú','Supermercado-ct queto','2026-08-12',40.97,1,1,'2026-09-01');
select pg_temp.add_card_purchase('Larissa','Itaú','Extrabom se-ct sede','2026-08-11',14.79,1,1,'2026-09-01');
select pg_temp.add_card_purchase('Larissa','Itaú','Shopee *seforastor','2026-08-11',61.69,1,1,'2026-09-01');
select pg_temp.add_card_purchase('Larissa','Itaú','Padaria pao -ct ozes 09ago','2026-08-09',20.72,1,1,'2026-09-01');
select pg_temp.add_card_purchase('Larissa','Itaú','Netflix.com','2026-08-09',72.80,1,1,'2026-09-01');
select pg_temp.add_card_purchase('Larissa','Itaú','Shopee *decorevt3d','2026-08-09',19.99,1,1,'2026-09-01');
select pg_temp.add_card_purchase('Larissa','Itaú','Distribuidor-ct phia','2026-08-08',408.00,1,1,'2026-09-01');
select pg_temp.add_card_purchase('Larissa','Itaú','Padaria pao -ct ozes 08ago','2026-08-08',8.64,1,1,'2026-09-01');
select pg_temp.add_card_purchase('Larissa','Itaú','Shopee *delcarlloto','2026-08-08',60.96,1,7,'2026-09-01');
select pg_temp.add_card_purchase('Larissa','Itaú','Cacau show -ct','2026-08-08',6.45,1,1,'2026-09-01');

-- NUBANK - fatura setembro/2026
select pg_temp.add_card_purchase('Larissa','Nubank','Cartao de Todos Ago','2026-08-19',33.40,1,1,'2026-09-01');
select pg_temp.add_card_purchase('Larissa','Nubank','Conta Vivo','2026-08-18',60.00,1,1,'2026-09-01');
select pg_temp.add_card_purchase('Larissa','Nubank','Asa*Academia Naturalis','2026-08-16',152.80,1,5,'2026-09-01');
select pg_temp.add_card_purchase('Larissa','Nubank','Raia Drogasil - NuPay','2026-08-09',51.70,1,1,'2026-09-01');
select pg_temp.add_card_purchase('Larissa','Nubank','Amazon','2026-08-04',93.44,10,12,'2026-09-01');
select pg_temp.add_card_purchase('Larissa','Nubank','030 - Es Vila Velha Pr','2026-08-04',56.66,3,3,'2026-09-01');
select pg_temp.add_card_purchase('Larissa','Nubank','Magalu *Magalu','2026-08-04',47.08,3,5,'2026-09-01');
select pg_temp.add_card_purchase('Larissa','Nubank','Amaren Farmacia e Mani','2026-08-04',251.66,3,3,'2026-09-01');
select pg_temp.add_card_purchase('Larissa','Nubank','Sennaveiculos','2026-08-04',178.00,4,5,'2026-09-01');
select pg_temp.add_card_purchase('Larissa','Nubank','Greenn**Nutriconecta C','2026-08-04',61.68,10,12,'2026-09-01');
select pg_temp.add_card_purchase('Larissa','Nubank','Paula Breder Tower A','2026-08-04',178.06,3,3,'2026-09-01');
select pg_temp.add_card_purchase('Larissa','Nubank','Paula Breder Tower B','2026-08-04',108.40,3,3,'2026-09-01');
select pg_temp.add_card_purchase('Larissa','Nubank','Htm*Teresinha Marcia D','2026-08-04',29.64,10,12,'2026-09-01');
select pg_temp.add_card_purchase('Larissa','Nubank','Mp *Wepink','2026-08-04',67.67,4,6,'2026-09-01');

-- BANCO DO BRASIL IGOR - fatura setembro/2026
select pg_temp.add_card_purchase('Igor','Banco do Brasil','Autoglass','2026-06-24',85.00,3,3,'2026-09-01');
select pg_temp.add_card_purchase('Igor','Banco do Brasil','Zurich Seguros','2026-06-22',210.70,3,12,'2026-09-01');
select pg_temp.add_card_purchase('Igor','Banco do Brasil','Atacado Do Thor Utilid','2026-06-13',37.00,3,3,'2026-09-01');
select pg_temp.add_card_purchase('Igor','Banco do Brasil','Foco Aluguel De 30abr','2026-04-30',76.07,4,6,'2026-09-01');
select pg_temp.add_card_purchase('Igor','Banco do Brasil','Foco Aluguel De 03mar','2026-03-03',51.58,6,6,'2026-09-01');
select pg_temp.add_card_purchase('Igor','Banco do Brasil','Amazon Marketplace Cci','2025-12-06',130.76,9,10,'2026-09-01');
select pg_temp.add_card_purchase('Igor','Banco do Brasil','Htm*decadamilionari','2025-10-27',399.00,11,12,'2026-09-01');

notify pgrst, 'reload schema';
