require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseKey) {
    console.error('Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in environment variables.');
    process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

async function uploadToDataset(fileName, filePath) {
    try {
        const fileContent = fs.readFileSync(filePath);
        console.log(`Uploading ${fileName} to campus-food bucket...`);
        const { data, error } = await supabase.storage.from('campus-food').upload(fileName, fileContent, {
            contentType: 'image/png',
            upsert: true
        });

        if (error) throw error;
        const { data: { publicUrl } } = supabase.storage.from('campus-food').getPublicUrl(fileName);
        console.log(`Success! Public URL: ${publicUrl}`);
        return publicUrl;
    } catch (err) {
        console.error(`Upload failed for ${fileName}:`, err);
    }
}

const args = process.argv.slice(2);
if (args.length === 2) {
    uploadToDataset(args[0], args[1]);
} else {
    console.log('Usage: node upload-dataset.js <fileName> <filePath>');
}
