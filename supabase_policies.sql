-- ALEMÃO PRODUTOS DA ROÇA
-- Políticas de segurança (RLS) para o usuário administrador atual
-- Execute este arquivo no SQL Editor do Supabase.

-- Usuário autorizado:
-- fd1121db-f0b6-4fee-9a8d-dcb23fcb0a69

DO $$
DECLARE
  t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'products','clients','suppliers','sales','sale_items','stock_moves',
    'cash_transactions','accounts_payable','accounts_receivable'
  ] LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t);
  END LOOP;
END $$;

-- Remove políticas antigas com os mesmos nomes para permitir reexecução segura.
DROP POLICY IF EXISTS "admin_products" ON public.products;
DROP POLICY IF EXISTS "admin_clients" ON public.clients;
DROP POLICY IF EXISTS "admin_suppliers" ON public.suppliers;
DROP POLICY IF EXISTS "admin_sales" ON public.sales;
DROP POLICY IF EXISTS "admin_sale_items" ON public.sale_items;
DROP POLICY IF EXISTS "admin_stock_moves" ON public.stock_moves;
DROP POLICY IF EXISTS "admin_cash_transactions" ON public.cash_transactions;
DROP POLICY IF EXISTS "admin_accounts_payable" ON public.accounts_payable;
DROP POLICY IF EXISTS "admin_accounts_receivable" ON public.accounts_receivable;

CREATE POLICY "admin_products" ON public.products
FOR ALL TO authenticated
USING (auth.uid() = 'fd1121db-f0b6-4fee-9a8d-dcb23fcb0a69'::uuid)
WITH CHECK (auth.uid() = 'fd1121db-f0b6-4fee-9a8d-dcb23fcb0a69'::uuid);

CREATE POLICY "admin_clients" ON public.clients
FOR ALL TO authenticated
USING (auth.uid() = 'fd1121db-f0b6-4fee-9a8d-dcb23fcb0a69'::uuid)
WITH CHECK (auth.uid() = 'fd1121db-f0b6-4fee-9a8d-dcb23fcb0a69'::uuid);

CREATE POLICY "admin_suppliers" ON public.suppliers
FOR ALL TO authenticated
USING (auth.uid() = 'fd1121db-f0b6-4fee-9a8d-dcb23fcb0a69'::uuid)
WITH CHECK (auth.uid() = 'fd1121db-f0b6-4fee-9a8d-dcb23fcb0a69'::uuid);

CREATE POLICY "admin_sales" ON public.sales
FOR ALL TO authenticated
USING (auth.uid() = 'fd1121db-f0b6-4fee-9a8d-dcb23fcb0a69'::uuid)
WITH CHECK (auth.uid() = 'fd1121db-f0b6-4fee-9a8d-dcb23fcb0a69'::uuid);

CREATE POLICY "admin_sale_items" ON public.sale_items
FOR ALL TO authenticated
USING (auth.uid() = 'fd1121db-f0b6-4fee-9a8d-dcb23fcb0a69'::uuid)
WITH CHECK (auth.uid() = 'fd1121db-f0b6-4fee-9a8d-dcb23fcb0a69'::uuid);

CREATE POLICY "admin_stock_moves" ON public.stock_moves
FOR ALL TO authenticated
USING (auth.uid() = 'fd1121db-f0b6-4fee-9a8d-dcb23fcb0a69'::uuid)
WITH CHECK (auth.uid() = 'fd1121db-f0b6-4fee-9a8d-dcb23fcb0a69'::uuid);

CREATE POLICY "admin_cash_transactions" ON public.cash_transactions
FOR ALL TO authenticated
USING (auth.uid() = 'fd1121db-f0b6-4fee-9a8d-dcb23fcb0a69'::uuid)
WITH CHECK (auth.uid() = 'fd1121db-f0b6-4fee-9a8d-dcb23fcb0a69'::uuid);

CREATE POLICY "admin_accounts_payable" ON public.accounts_payable
FOR ALL TO authenticated
USING (auth.uid() = 'fd1121db-f0b6-4fee-9a8d-dcb23fcb0a69'::uuid)
WITH CHECK (auth.uid() = 'fd1121db-f0b6-4fee-9a8d-dcb23fcb0a69'::uuid);

CREATE POLICY "admin_accounts_receivable" ON public.accounts_receivable
FOR ALL TO authenticated
USING (auth.uid() = 'fd1121db-f0b6-4fee-9a8d-dcb23fcb0a69'::uuid)
WITH CHECK (auth.uid() = 'fd1121db-f0b6-4fee-9a8d-dcb23fcb0a69'::uuid);
