import { render, screen } from '@testing-library/react';
import App from '../../App';
import { describe, it, expect } from 'vitest';

describe('Admin Dashboard - Main Layout', () => {
    it('renders the core metrics', () => {
        render(<App />);

        // Check header
        expect(screen.getByText('CampusAdmin')).toBeInTheDocument();

        // Check key metric cards
        expect(screen.getByText('Active Users')).toBeInTheDocument();
        expect(screen.getByText('Today\'s Orders')).toBeInTheDocument();
        expect(screen.getByText('1,240')).toBeInTheDocument();
    });

    it('renders the pending vendor approvals queue', () => {
        render(<App />);

        // Assert specific mock block content
        expect(screen.getByText('Pending Vendor Approvals')).toBeInTheDocument();
        expect(screen.getByText('Spice Route Canteen')).toBeInTheDocument();
        expect(screen.getByText('Approve')).toBeInTheDocument();
    });
});
