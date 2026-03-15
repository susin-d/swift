import { FastifyReply, FastifyRequest } from 'fastify';
import { CONTRACT_ENDPOINTS, CONTRACT_ERROR_ENVELOPE, CONTRACT_REGISTRY_VERSION } from '../contracts/registry';
import { CONTRACT_CHANGELOG } from '../contracts/changelog';
import { CONTRACT_FEATURE_FLAGS } from '../contracts/flags';

export const getContractsRegistryHandler = async (_request: FastifyRequest, reply: FastifyReply) => {
    return reply.send({
        version: CONTRACT_REGISTRY_VERSION,
        generatedAt: new Date().toISOString(),
        totalEndpoints: CONTRACT_ENDPOINTS.length,
        errorEnvelope: CONTRACT_ERROR_ENVELOPE,
        endpoints: CONTRACT_ENDPOINTS
    });
};

export const getContractsChangelogHandler = async (request: FastifyRequest, reply: FastifyReply) => {
    const { since } = (request.query as { since?: string }) || {};
    const filteredChanges = since
        ? CONTRACT_CHANGELOG.filter((change) => change.timestamp > since)
        : CONTRACT_CHANGELOG;

    return reply.send({
        version: CONTRACT_REGISTRY_VERSION,
        count: filteredChanges.length,
        changes: filteredChanges
    });
};

export const getContractFlagsHandler = async (_request: FastifyRequest, reply: FastifyReply) => {
    return reply.send({
        version: CONTRACT_REGISTRY_VERSION,
        count: CONTRACT_FEATURE_FLAGS.length,
        flags: CONTRACT_FEATURE_FLAGS
    });
};
