require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');

const supabaseUrl = process.env.SUPABASE_URL || 'https://ncknhkowypkjvzleyaar.supabase.co';
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5ja25oa293eXBranZ6bGV5YWFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MjkxNDUwNiwiZXhwIjoyMDg4NDkwNTA2fQ.7hiYPKG0YYqG2gQdEAOOXspuuqX4b8jw8GhsSSlIygQ';
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
