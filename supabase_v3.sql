-- ALEMÃO PRODUTOS DA ROÇA - ERP V3
-- Comprovantes de pagamento privados + campos auxiliares.
-- Execute no SQL Editor do Supabase. Pode ser reexecutado.

create extension if not exists pgcrypto;

alter table public.cash_transactions add column if not exists receipt_path text;
alter table public.purchases add column if not exists receipt_path text;
alter table public.accounts_payable add column if not exists receipt_path text;
alter table public.accounts_receivable add column if not exists receipt_path text;

-- Bucket PRIVADO para comprovantes (PDF, JPG, PNG etc.)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'receipts',
  'receipts',
  false,
  10485760,
  array['image/jpeg','image/png','image/webp','application/pdf']
)
on conflict (id) do update set
  public = false,
  file_size_limit = 10485760,
  allowed_mime_types = array['image/jpeg','image/png','image/webp','application/pdf'];

-- Políticas: somente o usuário administrador autenticado pode ver/enviar/alterar/apagar comprovantes.
drop policy if exists "admin_receipts_select" on storage.objects;
drop policy if exists "admin_receipts_insert" on storage.objects;
drop policy if exists "admin_receipts_update" on storage.objects;
drop policy if exists "admin_receipts_delete" on storage.objects;

create policy "admin_receipts_select" on storage.objects
for select to authenticated
using (
  bucket_id = 'receipts'
  and auth.uid() = 'fd1121db-f0b6-4fee-9a8d-dcb23fcb0a69'::uuid
);

create policy "admin_receipts_insert" on storage.objects
for insert to authenticated
with check (
  bucket_id = 'receipts'
  and auth.uid() = 'fd1121db-f0b6-4fee-9a8d-dcb23fcb0a69'::uuid
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "admin_receipts_update" on storage.objects
for update to authenticated
using (
  bucket_id = 'receipts'
  and auth.uid() = 'fd1121db-f0b6-4fee-9a8d-dcb23fcb0a69'::uuid
)
with check (
  bucket_id = 'receipts'
  and auth.uid() = 'fd1121db-f0b6-4fee-9a8d-dcb23fcb0a69'::uuid
);

create policy "admin_receipts_delete" on storage.objects
for delete to authenticated
using (
  bucket_id = 'receipts'
  and auth.uid() = 'fd1121db-f0b6-4fee-9a8d-dcb23fcb0a69'::uuid
);

notify pgrst, 'reload schema';
