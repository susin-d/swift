import { FastifyInstance } from 'fastify';
import { createMenu, getVendorMenus, createMenuItem, updateMenuItem, updateMenu, deleteMenu, deleteMenuItem } from '../controllers/menuController';
import { requireVendor } from '../middleware/rbac';

export const menuRoutes = async (app: FastifyInstance) => {
    // Public routes
    app.get('/vendor/:vendorId', getVendorMenus);

    // Vendor only routes
    app.post('/', {
        preValidation: [app.authenticate],
        preHandler: [requireVendor]
    }, createMenu);

    app.patch('/:id', {
        preValidation: [app.authenticate],
        preHandler: [requireVendor]
    }, updateMenu);

    app.delete('/:id', {
        preValidation: [app.authenticate],
        preHandler: [requireVendor]
    }, deleteMenu);

    app.post('/items', {
        preValidation: [app.authenticate],
        preHandler: [requireVendor]
    }, createMenuItem);

    app.patch('/items/:id', {
        preValidation: [app.authenticate],
        preHandler: [requireVendor]
    }, updateMenuItem);

    app.delete('/items/:id', {
        preValidation: [app.authenticate],
        preHandler: [requireVendor]
    }, deleteMenuItem);
};
