import { supabase } from './supabase';

// Configuration
const BUCKET_NAME = 'menu-items';
const MAX_FILE_SIZE = 5 * 1024 * 1024; // 5 MB
const ALLOWED_MIME_TYPES = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];

export interface UploadMenuImageOptions {
  vendorId: string;
  itemId?: string;
  fileName?: string;
}

export interface UploadResult {
  url: string;
  path: string;
  mimeType: string;
  sizeBytes: number;
}

/**
 * Validate file size and MIME type before upload.
 * Throws descriptive error if validation fails.
 */
export const validateImageFile = (
  bufferOrBase64: string | Buffer,
  mimeType: string
): { sizeBytes: number } => {
  // Convert base64 to buffer if needed
  let buffer: Buffer;
  if (typeof bufferOrBase64 === 'string') {
    buffer = Buffer.from(bufferOrBase64, 'base64');
  } else {
    buffer = bufferOrBase64;
  }

  const sizeBytes = buffer.length;

  // Validate MIME type
  if (!ALLOWED_MIME_TYPES.includes(mimeType)) {
    throw new Error(
      `Invalid MIME type. Allowed types: ${ALLOWED_MIME_TYPES.join(', ')}. Got: ${mimeType}`
    );
  }

  // Validate file size
  if (sizeBytes > MAX_FILE_SIZE) {
    const maxMB = MAX_FILE_SIZE / (1024 * 1024);
    throw new Error(
      `File too large. Maximum size: ${maxMB}MB. Got: ${(sizeBytes / (1024 * 1024)).toFixed(2)}MB`
    );
  }

  return { sizeBytes };
};

/**
 * Ensure storage bucket exists. Creates it if missing.
 * Should be idempotent and safe to call repeatedly.
 */
export const ensureBucketExists = async (): Promise<void> => {
  try {
    // Check if bucket exists
    const { data: buckets, error: listError } = await supabase.storage.listBuckets();
    
    if (listError) {
      console.warn(`Warning: could not list buckets - ${listError.message}`);
      return; // Assume bucket exists or is already configured
    }

    const bucketExists = buckets?.some((b) => b.name === BUCKET_NAME);
    
    if (!bucketExists) {
      console.log(`Creating storage bucket: ${BUCKET_NAME}`);
      const { data, error } = await supabase.storage.createBucket(BUCKET_NAME, {
        public: false, // Private by default; will use RLS policies
        fileSizeLimit: MAX_FILE_SIZE,
      });

      if (error) {
        console.error(`Error creating bucket: ${error.message}`);
        throw error;
      }
      console.log(`Bucket ${BUCKET_NAME} created successfully`);
    }
  } catch (err) {
    console.error(`Bucket initialization error: ${err instanceof Error ? err.message : String(err)}`);
    // Don't fail startup on storage bucket issues; continue with graceful degradation
  }
};

/**
 * Upload a base64-encoded image to Supabase Storage.
 * Returns a public HTTPS URL and details.
 *
 * Path structure: vendor/{vendorId}/items/{uniqueId}
 */
export const uploadMenuItemImage = async (
  base64Data: string,
  mimeType: string,
  options: UploadMenuImageOptions
): Promise<UploadResult> => {
  // Validate inputs
  const { sizeBytes } = validateImageFile(base64Data, mimeType);

  // Determine file extension from MIME type
  const mimeToExt: Record<string, string> = {
    'image/jpeg': 'jpg',
    'image/png': 'png',
    'image/webp': 'webp',
    'image/gif': 'gif',
  };
  const ext = mimeToExt[mimeType] || 'jpg';

  // Generate storage path: vendor/{vendorId}/items/{timestamp}-{randomId}.{ext}
  const timestamp = Date.now();
  const randomId = Math.random().toString(36).substring(2, 9);
  const fileName = options.fileName || `${timestamp}-${randomId}.${ext}`;
  const storagePath = `vendor/${options.vendorId}/items/${fileName}`;

  // Convert base64 to buffer
  const buffer = Buffer.from(base64Data, 'base64');

  // Upload to Supabase Storage
  const { data, error } = await supabase.storage
    .from(BUCKET_NAME)
    .upload(storagePath, buffer, {
      contentType: mimeType,
      cacheControl: '31536000', // 1 year
      upsert: false, // Don't overwrite existing files
    });

  if (error) {
    throw new Error(`Storage upload failed: ${error.message}`);
  }

  // Construct public HTTPS URL using Supabase CDN
  // Format: https://{project-id}.supabase.co/storage/v1/object/public/{bucket}/{path}
  const supabaseUrl = process.env.SUPABASE_URL || '';
  const projectId = supabaseUrl.split('.')[0].replace('https://', '');
  const publicUrl = `https://${projectId}.supabase.co/storage/v1/object/public/${BUCKET_NAME}/${storagePath}`;

  return {
    url: publicUrl,
    path: storagePath,
    mimeType,
    sizeBytes,
  };
};

/**
 * Delete an image from storage by path.
 * Safe to call even if file doesn't exist (idempotent).
 */
export const deleteMenuItemImage = async (storagePath: string): Promise<void> => {
  try {
    const { error } = await supabase.storage.from(BUCKET_NAME).remove([storagePath]);

    if (error && error.message !== 'Not found') {
      throw error;
    }
  } catch (err) {
    console.warn(`Warning: could not delete image ${storagePath}: ${err instanceof Error ? err.message : String(err)}`);
    // Don't fail the operation if deletion fails
  }
};
