-- ALEMÃO PRODUTOS DA ROÇA - ERP V4
-- Edição completa de vendas/compras + múltiplos comprovantes por cliente, fornecedor, caixa, compra e venda.
-- Execute no SQL Editor do Supabase. Pode ser reexecutado.

create extension if not exists pgcrypto;

-- Garante os campos antigos de comprovante.
alter table public.cash_transactions add column if not exists receipt_path text;
alter table public.purchases add column if not exists receipt_path text;
alter table public.accounts_payable add column if not exists receipt_path text;
alter table public.accounts_receivable add column if not exists receipt_path text;

-- Tabela genérica para vários comprovantes/anexos por registro.
create table if not exists public.attachments (
  id uuid primary key default gen_random_uuid(),
  entity_type text not null,
  entity_id uuid not null,
  file_path text not null,
  file_name text,
  note text,
  created_at timestamptz not null default now()
);

create index if not exists idx_attachments_entity on public.attachments(entity_type, entity_id);

alter table public.attachments enable row level security;
drop policy if exists "admin_attachments" on public.attachments;
create policy "admin_attachments" on public.attachments
for all to authenticated
using (auth.uid() = 'fd1121db-f0b6-4fee-9a8d-dcb23fcb0a69'::uuid)
with check (auth.uid() = 'fd1121db-f0b6-4fee-9a8d-dcb23fcb0a69'::uuid);

-- Bucket privado de comprovantes.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('receipts','receipts',false,10485760,array['image/jpeg','image/png','image/webp','application/pdf'])
on conflict (id) do update set
  public=false,
  file_size_limit=10485760,
  allowed_mime_types=array['image/jpeg','image/png','image/webp','application/pdf'];

drop policy if exists "admin_receipts_select" on storage.objects;
drop policy if exists "admin_receipts_insert" on storage.objects;
drop policy if exists "admin_receipts_update" on storage.objects;
drop policy if exists "admin_receipts_delete" on storage.objects;

create policy "admin_receipts_select" on storage.objects
for select to authenticated
using (bucket_id='receipts' and auth.uid()='fd1121db-f0b6-4fee-9a8d-dcb23fcb0a69'::uuid);

create policy "admin_receipts_insert" on storage.objects
for insert to authenticated
with check (
  bucket_id='receipts'
  and auth.uid()='fd1121db-f0b6-4fee-9a8d-dcb23fcb0a69'::uuid
  and (storage.foldername(name))[1]=auth.uid()::text
);

create policy "admin_receipts_update" on storage.objects
for update to authenticated
using (bucket_id='receipts' and auth.uid()='fd1121db-f0b6-4fee-9a8d-dcb23fcb0a69'::uuid)
with check (bucket_id='receipts' and auth.uid()='fd1121db-f0b6-4fee-9a8d-dcb23fcb0a69'::uuid);

create policy "admin_receipts_delete" on storage.objects
for delete to authenticated
using (bucket_id='receipts' and auth.uid()='fd1121db-f0b6-4fee-9a8d-dcb23fcb0a69'::uuid);

notify pgrst, 'reload schema';
