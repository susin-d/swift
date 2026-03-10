import { FastifyInstance } from 'fastify';
import { getAddresses, addAddress, deleteAddress, setDefaultAddress } from '../controllers/addressController';

export const addressRoutes = async (app: FastifyInstance) => {
    app.addHook('preValidation', app.authenticate);

    app.get('/', getAddresses);
    app.post('/', addAddress);
    app.delete('/:id', deleteAddress);
    app.patch('/:id/default', setDefaultAddress);
};
