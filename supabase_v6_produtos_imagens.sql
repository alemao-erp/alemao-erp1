-- ALEMÃO PRODUTOS DA ROÇA - V6
-- Fotos de produtos + estrutura segura para edição completa

alter table public.products
  add column if not exists image_path text;

-- Bucket público apenas para exibição das fotos dos produtos.
-- Escrita continua restrita a usuário autenticado pelas policies abaixo.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'product-images',
  'product-images',
  true,
  5242880,
  array['image/jpeg','image/png','image/webp','image/gif']
)
on conflict (id) do update
set public = true,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "product_images_insert" on storage.objects;
drop policy if exists "product_images_update" on storage.objects;
drop policy if exists "product_images_delete" on storage.objects;

create policy "product_images_insert"
on storage.objects for insert
to authenticated
with check (bucket_id = 'product-images');

create policy "product_images_update"
on storage.objects for update
to authenticated
using (bucket_id = 'product-images')
with check (bucket_id = 'product-images');

create policy "product_images_delete"
on storage.objects for delete
to authenticated
using (bucket_id = 'product-images');

notify pgrst, 'reload schema';
