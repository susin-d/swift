type GeoJsonPolygon = {
    type: 'Polygon';
    coordinates: number[][][];
};

type GeoJsonMultiPolygon = {
    type: 'MultiPolygon';
    coordinates: number[][][][];
};

type GeoJson = GeoJsonPolygon | GeoJsonMultiPolygon;

const toGeoJson = (value: any): GeoJson | null => {
    if (!value) return null;
    if (typeof value === 'string') {
        try {
            const parsed = JSON.parse(value);
            return toGeoJson(parsed);
        } catch {
            return null;
        }
    }

    if (value?.type === 'Polygon' && Array.isArray(value?.coordinates)) {
        return {
            type: 'Polygon',
            coordinates: value.coordinates as number[][][],
        };
    }
    if (value?.type === 'MultiPolygon' && Array.isArray(value?.coordinates)) {
        return {
            type: 'MultiPolygon',
            coordinates: value.coordinates as number[][][][],
        };
    }

    return null;
};

const pointInRing = (lat: number, lng: number, ring: number[][]) => {
    let inside = false;
    for (let i = 0, j = ring.length - 1; i < ring.length; j = i++) {
        const [xi, yi] = ring[i];
        const [xj, yj] = ring[j];
        const intersects =
            yi > lat !== yj > lat &&
            lng < ((xj - xi) * (lat - yi)) / (yj - yi + Number.EPSILON) + xi;
        if (intersects) inside = !inside;
    }
    return inside;
};

const pointInPolygon = (lat: number, lng: number, polygon: number[][][]) => {
    if (!polygon.length) return false;
    const [outer, ...holes] = polygon;
    if (!pointInRing(lat, lng, outer)) return false;
    for (const hole of holes) {
        if (pointInRing(lat, lng, hole)) return false;
    }
    return true;
};

export const isPointInsideGeojson = (lat: number, lng: number, geojson: any) => {
    const parsed = toGeoJson(geojson);
    if (!parsed) return false;

    if (parsed.type === 'Polygon') {
        return pointInPolygon(lat, lng, parsed.coordinates);
    }

    return parsed.coordinates.some((polygon) => pointInPolygon(lat, lng, polygon));
};
