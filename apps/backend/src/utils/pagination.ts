type PaginationQuery = {
    page?: string | number;
    limit?: string | number;
};

type PaginationOptions = {
    defaultPage?: number;
    defaultLimit?: number;
    maxLimit?: number;
};

export type ParsedPagination = {
    page: number;
    limit: number;
    from: number;
    to: number;
};

export type PaginationMeta = {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
    hasNextPage: boolean;
    hasPreviousPage: boolean;
};

const toPositiveInt = (value: string | number | undefined, fallback: number) => {
    if (typeof value === 'number' && Number.isFinite(value)) {
        return Math.floor(value) > 0 ? Math.floor(value) : fallback;
    }

    if (typeof value === 'string') {
        const parsed = Number(value);
        if (Number.isFinite(parsed) && parsed > 0) {
            return Math.floor(parsed);
        }
    }

    return fallback;
};

export const parsePagination = (
    query: PaginationQuery,
    options?: PaginationOptions
): ParsedPagination => {
    const defaultPage = options?.defaultPage ?? 1;
    const defaultLimit = options?.defaultLimit ?? 20;
    const maxLimit = options?.maxLimit ?? 100;

    const page = toPositiveInt(query.page, defaultPage);
    const rawLimit = toPositiveInt(query.limit, defaultLimit);
    const limit = Math.min(maxLimit, rawLimit);
    const from = (page - 1) * limit;
    const to = from + limit - 1;

    return { page, limit, from, to };
};

export const buildPaginationMeta = (
    page: number,
    limit: number,
    total: number
): PaginationMeta => {
    const safeTotal = Math.max(0, Math.floor(total || 0));
    const totalPages = safeTotal === 0 ? 0 : Math.ceil(safeTotal / limit);

    return {
        page,
        limit,
        total: safeTotal,
        totalPages,
        hasNextPage: totalPages > 0 && page < totalPages,
        hasPreviousPage: page > 1 && totalPages > 0,
    };
};
