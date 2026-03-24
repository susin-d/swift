type VendorOrderEvent = {
    type: string;
    [key: string]: unknown;
};

type VendorOrderEventListener = (event: VendorOrderEvent & { ts: string }) => void;

class VendorOrderEvents {
    private listeners = new Map<string, Set<VendorOrderEventListener>>();

    subscribe(vendorId: string, listener: VendorOrderEventListener) {
        const existing = this.listeners.get(vendorId) ?? new Set<VendorOrderEventListener>();
        existing.add(listener);
        this.listeners.set(vendorId, existing);

        return () => {
            const current = this.listeners.get(vendorId);
            if (!current) return;
            current.delete(listener);
            if (current.size === 0) {
                this.listeners.delete(vendorId);
            }
        };
    }

    publish(vendorId: string, event: VendorOrderEvent) {
        const current = this.listeners.get(vendorId);
        if (!current || current.size === 0) return;

        const payload = {
            ...event,
            ts: new Date().toISOString(),
        };

        for (const listener of current) {
            try {
                listener(payload);
            } catch {
                // Non-blocking event fan-out.
            }
        }
    }
}

export const vendorOrderEvents = new VendorOrderEvents();
