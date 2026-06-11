-- Multi-device push notifications.
--
-- Previously profiles.app_users held a single `fcm_token` column, so when two
-- devices signed into the same account the last one to register overwrote the
-- other's token — only one device could receive notifications.
--
-- This migration introduces one row per device token so every signed-in device
-- gets its own token and all of them receive reminders/announcements.

create table if not exists profiles.user_fcm_tokens (
  token       text primary key,
  user_id     uuid not null references profiles.app_users (id) on delete cascade,
  platform    text,
  updated_at  timestamptz not null default now()
);

create index if not exists user_fcm_tokens_user_id_idx
  on profiles.user_fcm_tokens (user_id);

-- Carry existing single tokens over so no device loses delivery on deploy.
insert into profiles.user_fcm_tokens (token, user_id, updated_at)
select fcm_token, id, now()
from profiles.app_users
where fcm_token is not null
on conflict (token) do update
  set user_id = excluded.user_id,
      updated_at = now();

-- Lock the table down: only the SECURITY DEFINER RPCs below (for the app) and
-- the service role (for the edge function) may touch it.
alter table profiles.user_fcm_tokens enable row level security;

-- Upsert the calling user's device token. SECURITY DEFINER so it can re-point a
-- token to a new owner when a device switches accounts (same physical token).
create or replace function public.save_fcm_token(
  p_token text,
  p_platform text default null
)
returns void
language plpgsql
security definer
set search_path = profiles, public
as $$
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;

  insert into profiles.user_fcm_tokens (token, user_id, platform, updated_at)
  values (p_token, auth.uid(), p_platform, now())
  on conflict (token) do update
    set user_id    = excluded.user_id,
        platform   = coalesce(excluded.platform, profiles.user_fcm_tokens.platform),
        updated_at = now();
end;
$$;

-- Remove a device token (called on sign-out). Keyed on the token string itself,
-- which is a long random secret, so this does not require an active session.
create or replace function public.delete_fcm_token(p_token text)
returns void
language plpgsql
security definer
set search_path = profiles, public
as $$
begin
  delete from profiles.user_fcm_tokens where token = p_token;
end;
$$;

grant execute on function public.save_fcm_token(text, text) to authenticated;
grant execute on function public.delete_fcm_token(text) to authenticated, anon;
