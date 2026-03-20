import { FastifyInstance } from 'fastify';
import {
    adminCreateBuilding,
    adminCreateZone,
    adminListBuildings,
    adminListZones,
    adminUpdateBuilding,
    adminUpdateZone,
    listPublicBuildings,
    listPublicZones,
} from '../controllers/campusController';
import { requireAdmin } from '../middleware/rbac';

export const campusRoutes = async (app: FastifyInstance) => {
    app.get('/public/buildings', listPublicBuildings);
    app.get('/public/zones', listPublicZones);

    app.addHook('preValidation', app.authenticate);
    app.addHook('preHandler', requireAdmin);

    app.get('/admin/campus/buildings', adminListBuildings);
    app.post('/admin/campus/buildings', adminCreateBuilding);
    app.patch('/admin/campus/buildings/:id', adminUpdateBuilding);

    app.get('/admin/campus/zones', adminListZones);
    app.post('/admin/campus/zones', adminCreateZone);
    app.patch('/admin/campus/zones/:id', adminUpdateZone);
};
