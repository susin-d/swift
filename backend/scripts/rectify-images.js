require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const https = require('https');
const path = require('path');
const url = require('url');

const supabaseUrl = process.env.SUPABASE_URL || 'https://ncknhkowypkjvzleyaar.supabase.co';
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5ja25oa293eXBranZ6bGV5YWFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MjkxNDUwNiwiZXhwIjoyMDg4NDkwNTA2fQ.7hiYPKG0YYqG2gQdEAOOXspuuqX4b8jw8GhsSSlIygQ';
const supabase = createClient(supabaseUrl, supabaseKey);

const rectDir = path.join(__dirname, '..', 'campus_food_images', 'rectified');
if (!fs.existsSync(rectDir)) fs.mkdirSync(rectDir, { recursive: true });

async function downloadImage(imageUrl, dest) {
    return new Promise((resolve, reject) => {
        https.get(imageUrl, (response) => {
            if (response.statusCode === 301 || response.statusCode === 302) {
                let location = response.headers.location;
                if (!location.startsWith('http')) {
                    const parsed = url.parse(imageUrl);
                    location = `${parsed.protocol}//${parsed.host}${location}`;
                }
                return downloadImage(location, dest).then(resolve).catch(reject);
            }
            if (response.statusCode !== 200) {
                reject(new Error(`Failed: ${response.statusCode}`));
                return;
            }
            const file = fs.createWriteStream(dest);
            response.pipe(file);
            file.on('finish', () => {
                file.close();
                resolve();
            });
        }).on('error', (err) => {
            if (fs.existsSync(dest)) fs.unlink(dest, () => { });
            reject(err);
        });
    });
}

async function uploadAndGetUrl(fileName, localPath) {
    const fileContent = fs.readFileSync(localPath);
    const { data, error } = await supabase.storage.from('campus-food').upload(`rectified/${fileName}`, fileContent, {
        contentType: 'image/jpeg',
        upsert: true
    });
    if (error) throw error;
    const { data: { publicUrl } } = supabase.storage.from('campus-food').getPublicUrl(`rectified/${fileName}`);
    return publicUrl;
}

const getSourceUrl = (name, index, fallback = false) => {
    const n = name.toLowerCase();
    if (fallback) {
        const tags = n.includes('mutton') || n.includes('vada') || n.includes('parotta') || n.includes('rice')
            ? `indian,food,${n.split(' ').join(',')}`
            : `food,indian`;
        return `https://loremflickr.com/1024/1024/${tags.replace(/ /g, '')}?lock=${index + 1000}`;
    }

    if (n.includes('biryani')) return `https://foodish-api.com/images/biryani/biryani${(index % 50) + 1}.jpg`;
    if (n.includes('burger')) return `https://foodish-api.com/images/burger/burger${(index % 50) + 1}.jpg`;
    if (n.includes('dosa')) return `https://foodish-api.com/images/dosa/dosa${(index % 50) + 1}.jpg`;
    if (n.includes('idli')) return `https://foodish-api.com/images/idli/idli${(index % 50) + 1}.jpg`;
    if (n.includes('pizza')) return `https://foodish-api.com/images/pizza/pizza${(index % 50) + 1}.jpg`;
    if (n.includes('pasta')) return `https://foodish-api.com/images/pasta/pasta${(index % 50) + 1}.jpg`;
    if (n.includes('sandwich')) return `https://foodish-api.com/images/sandwich/sandwich${(index % 50) + 1}.jpg`;
    if (n.includes('dessert') || n.includes('cake') || n.includes('sweet')) return `https://foodish-api.com/images/dessert/dessert${(index % 50) + 1}.jpg`;
    if (n.includes('rice')) return `https://foodish-api.com/images/rice/rice${(index % 20) + 1}.jpg`; // Lowered to 20 for rice
    if (n.includes('chicken') || n.includes('curry')) return `https://foodish-api.com/images/butter-chicken/butter-chicken${(index % 20) + 1}.jpg`;

    return getSourceUrl(name, index, true);
};

async function rectify() {
    console.log('Fetching menu items from Supabase...');
    const { data: items, error } = await supabase.from('menu_items').select('id, name');
    if (error) throw error;

    console.log('Fetching existing files from Storage...');
    const { data: storageFiles } = await supabase.storage.from('campus-food').list('rectified', { limit: 1000 });
    const existingFileNames = storageFiles ? storageFiles.map(f => f.name) : [];

    console.log(`Found ${items.length} items. Starting rectification...`);

    for (let i = 0; i < items.length; i++) {
        const item = items[i];
        const fileName = `item_${item.id.slice(0, 8)}.jpg`;
        const localPath = path.join(rectDir, fileName);

        if (existingFileNames.includes(fileName)) {
            // console.log(`[${i+1}/${items.length}] Skipping ${item.name} (file exists)`);
            continue;
        }

        let searchUrl = getSourceUrl(item.name, i);
        try {
            console.log(`[${i + 1}/${items.length}] Sourcing ${item.name}...`);
            await downloadImage(searchUrl, localPath).catch(async (e) => {
                console.log(`   - Secondary fallback for ${item.name}`);
                searchUrl = getSourceUrl(item.name, i, true);
                await downloadImage(searchUrl, localPath);
            });
            const publicUrl = await uploadAndGetUrl(fileName, localPath);
            await supabase.from('menu_items').update({ image_url: publicUrl }).eq('id', item.id);
            console.log(`   - Success: ${publicUrl}`);
        } catch (err) {
            console.error(`   - Error for ${item.name}:`, err.message);
        }
    }
    console.log('Rectification complete!');
}

rectify().catch(console.error);
