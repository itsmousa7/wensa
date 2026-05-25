-- Adds a 'pending' value to the membership_status enum so memberships can
-- start unpaid without being miscategorised as 'active'. Must run in its own
-- migration: PG17 forbids using a freshly-added enum value inside the same
-- transaction that adds it.
ALTER TYPE bookings.membership_status ADD VALUE IF NOT EXISTS 'pending' BEFORE 'active';
