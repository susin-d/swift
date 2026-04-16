import { uploadMenuItemImage, validateImageFile } from '../../../src/services/storageService';

/**
 * Tests for storageService.ts
 * Validates file size and MIME type guards
 */
describe('storageService', () => {
  describe('validateImageFile', () => {
    it('should accept valid JPEG image', () => {
      // 1KB of base64 data
      const base64 = Buffer.alloc(1000).toString('base64');
      const result = validateImageFile(base64, 'image/jpeg');
      expect(result.sizeBytes).toBe(1000);
    });

    it('should accept valid PNG image', () => {
      const base64 = Buffer.alloc(500).toString('base64');
      const result = validateImageFile(base64, 'image/png');
      expect(result.sizeBytes).toBe(500);
    });

    it('should accept valid WebP image', () => {
      const base64 = Buffer.alloc(2000).toString('base64');
      const result = validateImageFile(base64, 'image/webp');
      expect(result.sizeBytes).toBe(2000);
    });

    it('should accept valid GIF image', () => {
      const base64 = Buffer.alloc(1500).toString('base64');
      const result = validateImageFile(base64, 'image/gif');
      expect(result.sizeBytes).toBe(1500);
    });

    it('should reject invalid MIME type', () => {
      const base64 = Buffer.alloc(1000).toString('base64');
      expect(() => {
        validateImageFile(base64, 'image/svg+xml');
      }).toThrow(/Invalid MIME type/);
    });

    it('should reject MIME type: text/plain', () => {
      const base64 = Buffer.alloc(1000).toString('base64');
      expect(() => {
        validateImageFile(base64, 'text/plain');
      }).toThrow(/Invalid MIME type/);
    });

    it('should reject MIME type: application/pdf', () => {
      const base64 = Buffer.alloc(1000).toString('base64');
      expect(() => {
        validateImageFile(base64, 'application/pdf');
      }).toThrow(/Invalid MIME type/);
    });

    it('should reject file larger than 5MB', () => {
      // 6 MB of data
      const largeBuffer = Buffer.alloc(6 * 1024 * 1024);
      const base64 = largeBuffer.toString('base64');
      
      expect(() => {
        validateImageFile(base64, 'image/jpeg');
      }).toThrow(/File too large/);
    });

    it('should accept file exactly 5MB', () => {
      // Exactly 5 MB (max allowed size)
      const maxBuffer = Buffer.alloc(5 * 1024 * 1024);
      const base64 = maxBuffer.toString('base64');
      
      const result = validateImageFile(base64, 'image/png');
      expect(result.sizeBytes).toBe(5 * 1024 * 1024);
    });

    it('should reject file 5.1MB', () => {
      // Just over 5 MB
      const overBuffer = Buffer.alloc(5 * 1024 * 1024 + 1000);
      const base64 = overBuffer.toString('base64');
      
      expect(() => {
        validateImageFile(base64, 'image/jpeg');
      }).toThrow(/File too large/);
    });

    it('should accept buffer input (not just base64)', () => {
      const buffer = Buffer.alloc(2000);
      const result = validateImageFile(buffer, 'image/png');
      expect(result.sizeBytes).toBe(2000);
    });
  });
});
