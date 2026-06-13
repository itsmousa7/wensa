-- Per-device notification language.
--
-- Previously the notification language lived in profiles.app_users.preferred_locale
-- (a single value per user). On a multi-device account, whichever device synced
-- its language last decided the language for EVERY device — so an English phone
-- and an Arabic phone on the same account both got the same language.
--
-- Store the language on each device token instead, so every device receives
-- pushes in its own app language. app_users.preferred_locale is kept as a
-- fallback for tokens that predate this column.

alter table profiles.user_fcm_tokens
  add column if not exists locale text;

-- save_fcm_token gains a p_locale argument. Drop the old 2-arg signature and
-- recreate with the extra defaulted parameter; PostgREST still resolves older
-- app builds that call it with only {p_token, p_platform}.
drop function if exists public.save_fcm_token(text, text);

create or replace function public.save_fcm_token(
  p_token text,
  p_platform text default null,
  p_locale text default null
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

  insert into profiles.user_fcm_tokens (token, user_id, platform, locale, updated_at)
  values (p_token, auth.uid(), p_platform, p_locale, now())
  on conflict (token) do update
    set user_id    = excluded.user_id,
        platform   = coalesce(excluded.platform, profiles.user_fcm_tokens.platform),
        locale     = coalesce(excluded.locale, profiles.user_fcm_tokens.locale),
        updated_at = now();
end;
$$;

grant execute on function public.save_fcm_token(text, text, text) to authenticated;
