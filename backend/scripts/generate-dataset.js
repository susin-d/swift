require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const http = require('http');
const https = require('https');
const path = require('path');

const supabaseUrl = process.env.SUPABASE_URL || 'https://ncknhkowypkjvzleyaar.supabase.co';
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5ja25oa293eXBranZ6bGV5YWFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MjkxNDUwNiwiZXhwIjoyMDg4NDkwNTA2fQ.7hiYPKG0YYqG2gQdEAOOXspuuqX4b8jw8GhsSSlIygQ';
const supabase = createClient(supabaseUrl, supabaseKey);

const metadataPath = path.join(__dirname, '..', 'campus_food_images', 'metadata.json');
const imagesDir = path.join(__dirname, '..', 'campus_food_images');

if (!fs.existsSync(imagesDir)) fs.mkdirSync(imagesDir);

async function downloadImage(url, dest, redirectCount = 0) {
    const maxRedirects = 5;

    return new Promise((resolve, reject) => {
        const parsed = new URL(url);
        const transport = parsed.protocol === 'http:' ? http : https;

        const request = transport.get(url, (response) => {
            const statusCode = response.statusCode || 0;

            if ([301, 302, 303, 307, 308].includes(statusCode)) {
                if (redirectCount >= maxRedirects) {
                    response.resume();
                    reject(new Error(`Too many redirects for ${url}`));
                    return;
                }

                const location = response.headers.location;
                if (!location) {
                    response.resume();
                    reject(new Error(`Redirect without Location for ${url}`));
                    return;
                }

                const nextUrl = new URL(location, url).toString();
                response.resume();
                downloadImage(nextUrl, dest, redirectCount + 1).then(resolve).catch(reject);
                return;
            }

            if (statusCode !== 200) {
                response.resume();
                reject(new Error(`Failed to download ${url}: ${statusCode}`));
                return;
            }

            const file = fs.createWriteStream(dest);
            response.pipe(file);
            file.on('finish', () => {
                file.close();
                resolve();
            });
            file.on('error', (err) => {
                fs.unlink(dest, () => { });
                reject(err);
            });
        });

        request.on('error', (err) => {
            fs.unlink(dest, () => { });
            reject(err);
        });
    });
}

async function uploadToSupabase(fileName, localPath) {
    const fileContent = fs.readFileSync(localPath);
    const { data, error } = await supabase.storage.from('campus-food').upload(fileName, fileContent, {
        contentType: 'image/jpeg',
        upsert: true
    });
    if (error) throw error;
    const { data: { publicUrl } } = supabase.storage.from('campus-food').getPublicUrl(fileName);
    return publicUrl;
}

const tagMap = {
    "Burgers": "burger,food",
    "Pizzas": "pizza,food",
    "Sandwiches": "sandwich,food",
    "Wraps": "wrap,food",
    "Pasta": "pasta,food",
    "Noodles": "noodles,food",
    "Rice Bowls": "ricebowl,food",
    "Healthy": "salad,food",
    "Salads": "salad,food",
    "Street Food": "streetfood,food",
    "Sides": "sides,food",
    "Desserts": "dessert,sweet",
    "Beverages": "beverage,drink"
};

async function processDataset() {
    const metadata = JSON.parse(fs.readFileSync(metadataPath, 'utf8'));
    console.log(`Processing ${metadata.items.length} items...`);

    for (let i = 0; i < metadata.items.length; i++) {
        const item = metadata.items[i];
        if (item.status === 'uploaded') continue;

        const tag = tagMap[item.category] || "food";
        // Use i+200 to avoid conflicts with previous trials
        const url = `https://loremflickr.com/1024/1024/${tag}?lock=${i + 200}`;
        const localPath = path.join(imagesDir, item.file);

        try {
            console.log(`[${i + 1}/100] Sourcing image for ${item.name} (${item.category})...`);
            await downloadImage(url, localPath);
            console.log(`Uploaded to storage...`);
            const publicUrl = await uploadToSupabase(item.file, localPath);

            item.status = 'uploaded';
            item.publicUrl = publicUrl;

            // Save progress every 5 items
            if ((i + 1) % 5 === 0) {
                fs.writeFileSync(metadataPath, JSON.stringify(metadata, null, 2));
                console.log('--- Progress Saved ---');
            }
        } catch (err) {
            console.error(`Error processing ${item.name}:`, err.message);
        }
    }

    fs.writeFileSync(metadataPath, JSON.stringify(metadata, null, 2));
    console.log('DONE! All 100 images processed.');
}

processDataset().catch(console.error);
