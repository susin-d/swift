-- Add media_items table to track uploaded files
-- This enables auditing, cleanup, and linking media to business entities

CREATE TABLE IF NOT EXISTS media_items (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  vendor_id UUID REFERENCES public.vendors(id) ON DELETE CASCADE NOT NULL,
  file_name TEXT NOT NULL,
  file_path TEXT NOT NULL UNIQUE,
  file_size_bytes BIGINT NOT NULL,
  mime_type TEXT NOT NULL,
  storage_url TEXT NOT NULL,
  entity_type TEXT NOT NULL CHECK (entity_type IN ('menu_item', 'vendor_profile', 'order_proof')),
  entity_id UUID,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Index for efficient lookups by vendor
CREATE INDEX IF NOT EXISTS idx_media_items_vendor_id ON media_items(vendor_id);

-- Index for efficient lookups by entity
CREATE INDEX IF NOT EXISTS idx_media_items_entity ON media_items(entity_type, entity_id);

-- Index for soft-delete queries
CREATE INDEX IF NOT EXISTS idx_media_items_active ON media_items(is_active) WHERE is_active = true;

-- Add storage_path column to menu_items for tracking original uploaded file
-- This allows us to delete orphaned uploads when items are deleted
ALTER TABLE menu_items ADD COLUMN IF NOT EXISTS storage_path TEXT;

-- Rollback instructions:
-- If you need to rollback this migration:
-- 1. DROP TABLE IF EXISTS media_items;
-- 2. ALTER TABLE menu_items DROP COLUMN IF EXISTS storage_path;
-- Note: This will delete all audit records; ensure backups are taken first.
