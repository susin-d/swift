require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
const supabase = createClient(supabaseUrl, supabaseKey);

async function uploadCategory(catLabel, imagePath) {
    try {
        console.log(`Uploading ${catLabel} from ${imagePath}...`);
        const fileContent = fs.readFileSync(imagePath);
        const fileName = `cat_${catLabel}.webp`;

        const { data, error } = await supabase.storage.from('menu-images').upload(fileName, fileContent, {
            contentType: 'image/webp',
            upsert: true
        });
        if (error) throw error;

        const { data: { publicUrl } } = supabase.storage.from('menu-images').getPublicUrl(fileName);
        console.log(`Public URL for ${catLabel}: ${publicUrl}`);
        return publicUrl;
    } catch (err) {
        console.error(`Upload failed for ${catLabel}:`, err);
        return null;
    }
}

async function bulkAssign() {
    // 1. Upload/Get URLs
    const images = {
        breakfast: await uploadCategory('breakfast', "C:\\Users\\susin\\.gemini\\antigravity\\brain\\9ef091de-6d25-4038-b72b-f5b012d0a0d1\\breakfast_hero_1772945974733.png"),
        meals: await uploadCategory('meals', "C:\\Users\\susin\\.gemini\\antigravity\\brain\\9ef091de-6d25-4038-b72b-f5b012d0a0d1\\meals_hero_1772945997297.png"),
        biryani: await uploadCategory('biryani', "C:\\Users\\susin\\.gemini\\antigravity\\brain\\9ef091de-6d25-4038-b72b-f5b012d0a0d1\\biryani_hero_1772946021002.png"),
        snacks: await uploadCategory('snacks', "C:\\Users\\susin\\.gemini\\antigravity\\brain\\9ef091de-6d25-4038-b72b-f5b012d0a0d1\\snacks_hero_1772946043923.png"),
        parotta: await uploadCategory('parotta', "C:\\Users\\susin\\.gemini\\antigravity\\brain\\9ef091de-6d25-4038-b72b-f5b012d0a0d1\\parotta_hero_1772946096676.png"),
        gravy: await uploadCategory('gravy', "C:\\Users\\susin\\.gemini\\antigravity\\brain\\9ef091de-6d25-4038-b72b-f5b012d0a0d1\\gravy_hero_v2_1772946167770.png"),
        drinks: await uploadCategory('drinks', "C:\\Users\\susin\\.gemini\\antigravity\\brain\\9ef091de-6d25-4038-b72b-f5b012d0a0d1\\drinks_hero_1772946116916.png"),
        jigarthanda: await uploadCategory('jigarthanda', "C:\\Users\\susin\\.gemini\\antigravity\\brain\\9ef091de-6d25-4038-b72b-f5b012d0a0d1\\jigarthanda_hero_v2_1772946137762.png")
    };

    // 2. Fetch all menus (categories)
    const { data: menus, error: mError } = await supabase.from('menus').select('*');
    if (mError) throw mError;

    for (const menu of menus) {
        let url = null;
        const cn = menu.category_name.toLowerCase();

        if (cn.includes('breakfast')) url = images.breakfast;
        else if (cn.includes('meals') || cn.includes('main course')) url = images.meals;
        else if (cn.includes('biryani') || cn.includes('rice')) url = images.biryani;
        else if (cn.includes('parotta')) url = images.parotta;
        else if (cn.includes('gravy') || cn.includes('special')) url = images.gravy;
        else if (cn.includes('drink') || cn.includes('beverage')) url = images.drinks;
        else if (cn.includes('snack') || cn.includes('bite') || cn.includes('starter') || cn.includes('side')) url = images.snacks;

        if (url) {
            console.log(`Assigning ${url} to items in category ${menu.category_name} (menuId: ${menu.id})`);
            const { error: updateError } = await supabase.from('menu_items')
                .update({ image_url: url })
                .eq('menu_id', menu.id)
                .is('image_url', null);
            if (updateError) console.error(`Failed to assign for ${menu.category_name}:`, updateError);
        }
    }

    // Special Case: Madurai Jigarthanda
    await supabase.from('menu_items')
        .update({ image_url: images.jigarthanda })
        .eq('name', 'Madurai Jigarthanda');

    console.log('Bulk assignment completed.');
}

bulkAssign().catch(err => console.error(err));
