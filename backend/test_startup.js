const { buildApp } = require('./src/app');
(async () => {
    try {
        const app = await buildApp();
        console.log('App built successfully');
        process.exit(0);
    } catch (err) {
        console.error('App build failed:');
        console.error(err);
        process.exit(1);
    }
})();
