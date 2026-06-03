-- Add reminder_sent_at to prevent duplicate booking reminder notifications
ALTER TABLE bookings.bookings
  ADD COLUMN IF NOT EXISTS reminder_sent_at timestamptz;

CREATE INDEX IF NOT EXISTS bookings_reminder_pending_idx
  ON bookings.bookings (starts_at)
  WHERE status = 'confirmed'
    AND payment_status = 'paid'
    AND reminder_sent_at IS NULL;
