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
