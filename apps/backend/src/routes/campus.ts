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

    app.register(async (adminApp) => {
        adminApp.addHook('preValidation', adminApp.authenticate);
        adminApp.addHook('preHandler', requireAdmin);

        adminApp.get('/admin/campus/buildings', adminListBuildings);
        adminApp.post('/admin/campus/buildings', adminCreateBuilding);
        adminApp.patch('/admin/campus/buildings/:id', adminUpdateBuilding);

        adminApp.get('/admin/campus/zones', adminListZones);
        adminApp.post('/admin/campus/zones', adminCreateZone);
        adminApp.patch('/admin/campus/zones/:id', adminUpdateZone);
    });
};
