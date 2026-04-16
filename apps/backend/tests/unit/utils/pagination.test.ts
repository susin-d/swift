import { parsePagination, buildPaginationMeta } from '../../../src/utils/pagination';

describe('Pagination Utility — parsePagination', () => {
    it('returns defaults when no query params provided', () => {
        const result = parsePagination({});
        expect(result.page).toBe(1);
        expect(result.limit).toBe(20);
        expect(result.from).toBe(0);
        expect(result.to).toBe(19);
    });

    it('computes correct from/to for page 2 with default limit', () => {
        const result = parsePagination({ page: '2' });
        expect(result.page).toBe(2);
        expect(result.limit).toBe(20);
        expect(result.from).toBe(20);
        expect(result.to).toBe(39);
    });

    it('respects custom limit', () => {
        const result = parsePagination({ page: '1', limit: '10' });
        expect(result.limit).toBe(10);
        expect(result.from).toBe(0);
        expect(result.to).toBe(9);
    });

    it('caps limit at maxLimit option', () => {
        const result = parsePagination({ limit: '500' }, { maxLimit: 50 });
        expect(result.limit).toBe(50);
    });

    it('falls back to default for zero page', () => {
        const result = parsePagination({ page: '0' });
        expect(result.page).toBe(1);
    });

    it('falls back to default for negative page', () => {
        const result = parsePagination({ page: '-5' });
        expect(result.page).toBe(1);
    });

    it('falls back to default for non-numeric page', () => {
        const result = parsePagination({ page: 'abc' });
        expect(result.page).toBe(1);
    });

    it('falls back to default for non-numeric limit', () => {
        const result = parsePagination({ limit: 'xyz' });
        expect(result.limit).toBe(20);
    });

    it('accepts numeric (not string) values', () => {
        const result = parsePagination({ page: 3, limit: 5 });
        expect(result.page).toBe(3);
        expect(result.limit).toBe(5);
        expect(result.from).toBe(10);
        expect(result.to).toBe(14);
    });

    it('uses custom default page and limit from options', () => {
        const result = parsePagination({}, { defaultPage: 2, defaultLimit: 5 });
        expect(result.page).toBe(2);
        expect(result.limit).toBe(5);
    });
});

describe('Pagination Utility — buildPaginationMeta', () => {
    it('returns full meta for first page with multiple pages', () => {
        const meta = buildPaginationMeta(1, 20, 45);
        expect(meta.page).toBe(1);
        expect(meta.limit).toBe(20);
        expect(meta.total).toBe(45);
        expect(meta.totalPages).toBe(3);
        expect(meta.hasNextPage).toBe(true);
        expect(meta.hasPreviousPage).toBe(false);
    });

    it('indicates last page correctly', () => {
        const meta = buildPaginationMeta(3, 20, 45);
        expect(meta.hasNextPage).toBe(false);
        expect(meta.hasPreviousPage).toBe(true);
    });

    it('handles single-page result set', () => {
        const meta = buildPaginationMeta(1, 20, 5);
        expect(meta.totalPages).toBe(1);
        expect(meta.hasNextPage).toBe(false);
        expect(meta.hasPreviousPage).toBe(false);
    });

    it('handles empty result set (total = 0)', () => {
        const meta = buildPaginationMeta(1, 20, 0);
        expect(meta.total).toBe(0);
        expect(meta.totalPages).toBe(0);
        expect(meta.hasNextPage).toBe(false);
        expect(meta.hasPreviousPage).toBe(false);
    });

    it('handles exact multiple of limit', () => {
        const meta = buildPaginationMeta(2, 10, 20);
        expect(meta.totalPages).toBe(2);
        expect(meta.hasNextPage).toBe(false);
        expect(meta.hasPreviousPage).toBe(true);
    });

    it('clamps negative total to 0', () => {
        const meta = buildPaginationMeta(1, 10, -5);
        expect(meta.total).toBe(0);
        expect(meta.totalPages).toBe(0);
    });
});
