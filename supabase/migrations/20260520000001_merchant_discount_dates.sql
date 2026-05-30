-- Adds an array of specific calendar dates a merchant discount applies to.
-- When non-empty, the discount applies ONLY on those exact dates (intersected
-- with starts_at/expires_at). Empty array preserves legacy behaviour: the
-- discount applies for every day within starts_at..expires_at.

ALTER TABLE business.merchant_discounts
  ADD COLUMN IF NOT EXISTS discount_dates date[] NOT NULL DEFAULT '{}'::date[];

COMMENT ON COLUMN business.merchant_discounts.discount_dates IS
  'When non-empty: discount applies only on these calendar dates (date-only, merchant local). When empty: legacy range-only mode using starts_at/expires_at.';
