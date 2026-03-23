const dns = require('dns').promises;

async function checkDns() {
    const hostname = 'cluster0.ljhhxmm.mongodb.net';
    console.log(`Checking DNS for ${hostname}...`);
    try {
        const addresses = await dns.resolve4(hostname);
        console.log('IPv4 Addresses:', addresses);
    } catch (err) {
        console.error('DNS resolve4 failed:', err.message);
    }

    try {
        const srv = await dns.resolveSrv(`_mongodb._tcp.${hostname}`);
        console.log('SRV Records:', srv);
    } catch (err) {
        console.error('DNS resolveSrv failed:', err.message);
    }
}

checkDns();
