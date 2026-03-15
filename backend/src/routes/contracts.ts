import { FastifyInstance } from 'fastify';
import {
    getContractFlagsHandler,
    getContractsChangelogHandler,
    getContractsRegistryHandler
} from '../controllers/contractsController';

export const contractsRoutes = async (app: FastifyInstance) => {
    app.get('/registry', getContractsRegistryHandler);
    app.get('/changelog', getContractsChangelogHandler);
    app.get('/flags', getContractFlagsHandler);
};
