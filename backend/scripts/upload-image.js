require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');

const supabaseUrl = process.env.SUPABASE_URL || 'https://ncknhkowypkjvzleyaar.supabase.co';
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5ja25oa293eXBranZ6bGV5YWFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MjkxNDUwNiwiZXhwIjoyMDg4NDkwNTA2fQ.7hiYPKG0YYqG2gQdEAOOXspuuqX4b8jw8GhsSSlIygQ';
const supabase = createClient(supabaseUrl, supabaseKey);

async function upload(itemId, imagePath) {
    try {
        const fileContent = fs.readFileSync(imagePath);
        const fileName = `${itemId}.webp`;

        console.log(`Uploading ${fileName}...`);
        const { data, error } = await supabase.storage.from('menu-images').upload(fileName, fileContent, {
            contentType: 'image/webp',
            upsert: true
        });

        if (error) throw error;

        const { data: { publicUrl } } = supabase.storage.from('menu-images').getPublicUrl(fileName);

        console.log(`DEBUG: itemId='${itemId}' type=${typeof itemId}`);
        console.log(`DEBUG: publicUrl='${publicUrl}' type=${typeof publicUrl}`);

        console.log(`Updating item ${itemId} with URL ${publicUrl}...`);
        const { error: updateError } = await supabase.from('menu_items')
            .update({ image_url: publicUrl })
            .eq('id', itemId);

        if (updateError) throw updateError;
        console.log('Success!');
    } catch (err) {
        console.error('Upload failed:', err);
        process.exit(1);
    }
}

const args = process.argv.slice(2);
if (args.length < 2) {
    console.log('Usage: node upload-image.js <itemId> <imagePath>');
    process.exit(1);
}

upload(args[0], args[1]);
