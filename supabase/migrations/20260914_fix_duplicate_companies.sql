-- Fix duplicate `companies` rows caused by a check-then-insert race in
-- CompanyRepository.getOrCreateCompany() (lib/repositories/company.dart).
--
-- Symptom: PostgrestException 406 "JSON Object requested, multiple (or no)
-- rows returned ... Results contain 2 rows" when the app queries
-- `companies` filtered by `owner_id` with `.maybeSingle()`.
--
-- Run the inspection query first and keep its output — it tells you which
-- rows are about to be merged. Then run the repair transaction. Both are
-- safe to run multiple times (idempotent).

-- ── 1. Inspect ───────────────────────────────────────────────────────────
-- select owner_id, count(*), array_agg(id order by created_at) as ids
-- from public.companies group by owner_id having count(*) > 1;

-- ── 2. Repair ────────────────────────────────────────────────────────────
begin;

-- Survivor per owner: prefer the onboarded row, then the oldest.
create temp table company_dupes on commit drop as
with ranked as (
  select id, owner_id,
         row_number() over (
           partition by owner_id
           order by (onboarded is true) desc, created_at asc, id asc
         ) as rn
  from public.companies
)
select r.id as dup_id, k.id as keep_id
from ranked r
join ranked k on k.owner_id = r.owner_id and k.rn = 1
where r.rn > 1;

-- Repoint every company_id-bearing table onto the survivor before deleting
-- the duplicate, so no invoice/customer/etc. row is orphaned.
-- (invoice_items follows automatically via invoice_id; monthly_revenue is
-- a view, not a table.)
update public.invoices               t set company_id = d.keep_id from company_dupes d where t.company_id = d.dup_id;
update public.customers              t set company_id = d.keep_id from company_dupes d where t.company_id = d.dup_id;
update public.services               t set company_id = d.keep_id from company_dupes d where t.company_id = d.dup_id;
update public.employees              t set company_id = d.keep_id from company_dupes d where t.company_id = d.dup_id;
update public.expenses               t set company_id = d.keep_id from company_dupes d where t.company_id = d.dup_id;
update public.recurring_invoices     t set company_id = d.keep_id from company_dupes d where t.company_id = d.dup_id;
update public.service_customer_links t set company_id = d.keep_id from company_dupes d where t.company_id = d.dup_id;
update public.invoice_events         t set company_id = d.keep_id from company_dupes d where t.company_id = d.dup_id;

delete from public.companies c using company_dupes d where c.id = d.dup_id;

-- Prevent this from ever happening again, and let the client use
-- upsert(..., onConflict: 'owner_id') / catch 23505 as a fast, safe path.
-- Guarded so re-running this script (e.g. after a partial earlier failure)
-- doesn't error with 42P07 "relation already exists" on a constraint that a
-- prior successful run already created.
do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'companies_owner_id_key'
  ) then
    alter table public.companies
      add constraint companies_owner_id_key unique (owner_id);
  end if;
end $$;

commit;

-- ── 3. Verify ────────────────────────────────────────────────────────────
-- select owner_id, count(*) from public.companies group by owner_id having count(*) > 1;
-- -- must return zero rows
