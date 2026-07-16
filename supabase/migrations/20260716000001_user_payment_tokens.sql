-- HyperPay tokenization for app users: saved card registrations per user.
-- Mirrors the dashboard's business.merchant_payment_tokens, keyed by auth user.
-- Inserts happen only via edge functions using the service role; users can
-- read and delete their own cards directly (RLS below).
create table if not exists bookings.user_payment_tokens (
  id                     uuid primary key default gen_random_uuid(),
  user_id                uuid not null references auth.users(id) on delete cascade,
  registration_id        text not null unique,   -- OPPWA registrationId (the token)
  brand                  text,                   -- VISA / MASTER
  last4                  text,
  exp_month              text,
  exp_year               text,
  holder                 text,
  initial_transaction_id text,                   -- payment id of the initial CIT, for MIT standingInstruction
  created_at             timestamptz not null default now()
);

create index if not exists idx_upt_user
  on bookings.user_payment_tokens(user_id);

-- Re-tokenizing the same physical card yields a NEW registrationId; this
-- prevents duplicate rows for the same card (nulls not distinct so partial
-- card metadata still dedupes). Upserts merge on this key.
create unique index if not exists idx_upt_user_card
  on bookings.user_payment_tokens(user_id, brand, last4, exp_month, exp_year)
  nulls not distinct;

alter table bookings.user_payment_tokens enable row level security;

drop policy if exists upt_select_own on bookings.user_payment_tokens;
create policy upt_select_own on bookings.user_payment_tokens
  for select to authenticated
  using (user_id = auth.uid());

drop policy if exists upt_delete_own on bookings.user_payment_tokens;
create policy upt_delete_own on bookings.user_payment_tokens
  for delete to authenticated
  using (user_id = auth.uid());

grant select, delete on bookings.user_payment_tokens to authenticated;
