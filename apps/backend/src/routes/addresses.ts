import { FastifyInstance } from 'fastify';
import { getAddresses, addAddress, deleteAddress, setDefaultAddress } from '../controllers/addressController';
import { requireUser } from '../middleware/rbac';

export const addressRoutes = async (app: FastifyInstance) => {
    app.addHook('preValidation', app.authenticate);
    app.addHook('preHandler', requireUser);

    app.get('/', getAddresses);
    app.post('/', addAddress);
    app.delete('/:id', deleteAddress);
    app.patch('/:id/default', setDefaultAddress);
};
