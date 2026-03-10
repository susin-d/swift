require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');
const crypto = require('crypto');

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

const supabase = createClient(supabaseUrl, supabaseKey);

const vendors = [
    {
        name: 'Annapoorna Bhavan',
        description: 'Traditional South Indian vegetarian breakfast and meals.',
        categories: ['Breakfast', 'Quick Bites', 'Main Course', 'Beverages']
    },
    {
        name: 'Karaikudi Spice',
        description: 'Authentic Chettinad non-vegetarian specialties.',
        categories: ['Starters', 'Chettinad Specials', 'Rice & Biryani', 'Sides']
    },
    {
        name: 'Madurai Bun Parotta',
        description: 'Famous Madurai street food and parotta varieties.',
        categories: ['Parotta Specials', 'Street Snacks', 'Non-Veg Gravies', 'Drinks']
    }
];

const menuItemsData = [
    // Annapoorna Bhavan - Breakfast (25 items)
    { v: 0, c: 'Breakfast', name: 'Sambar Idli', price: 60, desc: 'Pair of soft idlis soaked in traditional sambar.' },
    { v: 0, c: 'Breakfast', name: 'Ghee Roast Dosa', price: 90, desc: 'Crispy thin dosa roasted with pure cow ghee.' },
    { v: 0, c: 'Breakfast', name: 'Medhu Vada', price: 40, desc: 'Golden crispy lentil donuts served with chutney.' },
    { v: 0, c: 'Breakfast', name: 'Pongal', price: 70, desc: 'Creamy rice and lentil mash tempered with pepper and cumin.' },
    { v: 0, c: 'Breakfast', name: 'Onion Uthappam', price: 85, desc: 'Thick pancake topped with fresh onions and green chilies.' },
    { v: 0, c: 'Breakfast', name: 'Poori Masala', price: 75, desc: 'Fluffy deep-fried pooris served with potato masala.' },
    { v: 0, c: 'Breakfast', name: 'Rava Dosa', price: 95, desc: 'Lacy, crispy semolina dosa with peppercorns.' },
    { v: 0, c: 'Breakfast', name: 'Masala Dosa', price: 100, desc: 'Classic dosa stuffed with spiced potato filling.' },
    { v: 0, c: 'Breakfast', name: 'Podi Idli', price: 70, desc: 'Mini idlis tossed in spicy lentil powder.' },
    { v: 0, c: 'Breakfast', name: 'Appam with Coconut Milk', price: 80, desc: 'Fermented rice pancakes with sweet coconut milk.' },
    { v: 0, c: 'Breakfast', name: 'Vada Sambar', price: 50, desc: 'Crispy vada dipped in hot aromatic sambar.' },
    { v: 0, c: 'Breakfast', name: 'Ada Pradhaman', price: 90, desc: 'Traditional kheer with rice flakes and jaggery.' },
    { v: 0, c: 'Breakfast', name: 'Kuzhi Paniyaram', price: 75, desc: 'Small steamed and fried dumplings.' },
    { v: 0, c: 'Breakfast', name: 'Pineapple Sheera', price: 60, desc: 'Sweet semolina pudding with pineapple chunks.' },
    { v: 0, c: 'Breakfast', name: 'Filter Coffee', price: 30, desc: 'Authentic South Indian decoction coffee.' },
    { v: 0, c: 'Breakfast', name: 'Badam Milk', price: 50, desc: 'Hot milk with almond paste and saffron.' },
    { v: 0, c: 'Breakfast', name: 'Mini Tiffin', price: 150, desc: 'Assorted breakfast sampler platter.' },
    { v: 0, c: 'Breakfast', name: 'Set Dosa', price: 80, desc: 'Spongy dosa served in a set of three.' },
    { v: 0, c: 'Breakfast', name: 'Ragi Dosa', price: 90, desc: 'Nutritious finger millet crepe.' },
    { v: 0, c: 'Breakfast', name: 'Kal Dosa', price: 70, desc: 'Traditional soft handmade dosa.' },
    { v: 0, c: 'Breakfast', name: 'Pesarattu', price: 110, desc: 'Green gram crepe from Andhra origin.' },
    { v: 0, c: 'Breakfast', name: 'Upma', price: 60, desc: 'Savory semolina porridge with vegetables.' },
    { v: 0, c: 'Breakfast', name: 'Idiyappam', price: 70, desc: 'String hoppers served with coconut milk.' },
    { v: 0, c: 'Breakfast', name: 'Wheat Parotta', price: 80, desc: 'Healthier whole wheat version of parotta.' },
    { v: 0, c: 'Breakfast', name: 'Adai Avial', price: 120, desc: 'Multi-lentil crepe with mixed vegetable stew.' },

    // Karaikudi Spice - Chettinad (35 items)
    { v: 1, c: 'Starters', name: 'Chicken 65', price: 180, desc: 'Spicy deep-fried chicken cubes.' },
    { v: 1, c: 'Starters', name: 'Mutton Sukka', price: 280, desc: 'Slow-cooked lamb with Karaikudi spices.' },
    { v: 1, c: 'Starters', name: 'Pepper Fry Prawns', price: 320, desc: 'Juicy prawns tossed in black pepper masala.' },
    { v: 1, c: 'Starters', name: 'Fish Fry', price: 220, desc: 'Tawa fried fish marinated in village spices.' },
    { v: 1, c: 'Starters', name: 'Chilli Chicken', price: 200, desc: 'Indo-Chinese style spicy chicken.' },
    { v: 1, c: 'Starters', name: 'Vanjaram Tawa Fry', price: 450, desc: 'Premium Seer fish steak fry.' },
    { v: 1, c: 'Starters', name: 'Egg Bonda', price: 60, desc: 'Deep-fried boiled eggs with besan coating.' },
    { v: 1, c: 'Starters', name: 'Crab Lollipop', price: 350, desc: 'Spiced crab meat shaped into lollipops.' },
    { v: 1, c: 'Chettinad Specials', name: 'Chicken Chettinad', price: 250, desc: 'Classic fiery roasted spice chicken curry.' },
    { v: 1, c: 'Chettinad Specials', name: 'Mutton Curry', price: 350, desc: 'Tender mutton pieces in rich gravy.' },
    { v: 1, c: 'Chettinad Specials', name: 'Fish Pulikuzhambu', price: 280, desc: 'Tangy tamarind based fish curry.' },
    { v: 1, c: 'Chettinad Specials', name: 'Chicken Chinthamani', price: 240, desc: 'Dry red chili based spicy chicken.' },
    { v: 1, c: 'Chettinad Specials', name: 'Nethili Fry', price: 180, desc: 'Crispy fried anchovies.' },
    { v: 1, c: 'Chettinad Specials', name: 'Brain Fry', price: 300, desc: 'Goat brain sautéed with spices.' },
    { v: 1, c: 'Chettinad Specials', name: 'Liver Masala', price: 260, desc: 'Goat liver cooked in spicy semi-gravy.' },
    { v: 1, c: 'Chettinad Specials', name: 'Quail Fry', price: 220, desc: 'Marinated and deep-fried quail.' },
    { v: 1, c: 'Rice & Biryani', name: 'Dindigul Thalappakatti Biryani', price: 320, desc: 'Fragrant Seeraga Samba mutton biryani.' },
    { v: 1, c: 'Rice & Biryani', name: 'Ambur Chicken Biryani', price: 280, desc: 'Nawal style flavorful chicken biryani.' },
    { v: 1, c: 'Rice & Biryani', name: 'Egg Biryani', price: 180, desc: 'Biryani rice served with boiled eggs.' },
    { v: 1, c: 'Rice & Biryani', name: 'Prawn Biryani', price: 380, desc: 'Aromatic rice with spiced prawns.' },
    { v: 1, c: 'Rice & Biryani', name: 'Fish Biryani', price: 350, desc: 'Delicate fish pieces layered with rice.' },
    { v: 1, c: 'Rice & Biryani', name: 'Veg Biryani', price: 160, desc: 'Fresh garden vegetables cooked with biryani rice.' },
    { v: 1, c: 'Rice & Biryani', name: 'Jeera Rice', price: 140, desc: 'Basmati rice tempered with cumin.' },
    { v: 1, c: 'Sides', name: 'Omelette', price: 40, desc: 'Classic double egg omelette.' },
    { v: 1, c: 'Sides', name: 'Egg Podimas', price: 60, desc: 'Scrambled eggs with onions and chilies.' },
    { v: 1, c: 'Sides', name: 'Kaadai Gravy', price: 240, desc: 'Quail meat in spicy gravy.' },
    { v: 1, c: 'Sides', name: 'Boneless Chicken Fry', price: 220, desc: 'Crunchy boneless chicken strips.' },
    { v: 1, c: 'Sides', name: 'Karandi Omelette', price: 50, desc: 'Ladle-shaped deep fried omelette.' },
    { v: 1, c: 'Sides', name: 'Plain Gravy', price: 60, desc: 'Aromatic biryani side gravy.' },
    { v: 1, c: 'Sides', name: 'Curd Rice', price: 80, desc: 'Tempered yogurt rice with pomegranate.' },
    { v: 1, c: 'Sides', name: 'Raita', price: 30, desc: 'Cooling yogurt with onions.' },
    { v: 1, c: 'Sides', name: 'Nalli Fry', price: 400, desc: 'Mutton marrow bones spiced and fried.' },
    { v: 1, c: 'Sides', name: 'Turkey Roast', price: 380, desc: 'Spiced and roasted turkey meat.' },
    { v: 1, c: 'Sides', name: 'Crab Masala', price: 360, desc: 'Whole crabs in fiery Chettinad sauce.' },
    { v: 1, c: 'Sides', name: 'Pepper Chicken Soup', price: 80, desc: 'Spicy and clear chicken broth.' },

    // Madurai Bun Parotta - Street Food (40 items)
    { v: 2, c: 'Parotta Specials', name: 'Bun Parotta', price: 40, desc: 'Soft, flaky, bun-shaped parotta.' },
    { v: 2, c: 'Parotta Specials', name: 'Muttai Parotta', price: 120, desc: 'Egg-laden shredded parotta medley.' },
    { v: 2, c: 'Parotta Specials', name: 'Kothu Parotta - Chicken', price: 180, desc: 'Beaten parotta with chicken and gravy.' },
    { v: 2, c: 'Parotta Specials', name: 'Ceylone Parotta', price: 100, desc: 'Square stuffed parotta with minced meat.' },
    { v: 2, c: 'Parotta Specials', name: 'Veechu Parotta', price: 50, desc: 'Large, paper-thin hand-thrown parotta.' },
    { v: 2, c: 'Parotta Specials', name: 'Chilli Parotta', price: 140, desc: 'Crispy parotta pieces in spicy sauce.' },
    { v: 2, c: 'Parotta Specials', name: 'Nool Parotta', price: 60, desc: 'Stringy, layered flaky parotta.' },
    { v: 2, c: 'Parotta Specials', name: 'Coin Parotta', price: 70, desc: 'Small coin-sized crispy parottas.' },
    { v: 2, c: 'Parotta Specials', name: 'Veg Kothu Parotta', price: 110, desc: 'Shredded parotta with vegetables.' },
    { v: 2, c: 'Street Snacks', name: 'Madurai Jigarthanda', price: 80, desc: 'Famous cold desert with hand-churned milk.' },
    { v: 2, c: 'Street Snacks', name: 'Kaalaan Fry', price: 60, desc: 'Roadside mushroom masala.' },
    { v: 2, c: 'Street Snacks', name: 'Vazhaipoo Vadai', price: 50, desc: 'Banana flower lentil fritters.' },
    { v: 2, c: 'Street Snacks', name: 'Mirchi Bajji', price: 40, desc: 'Spicy chili fritters with chutney.' },
    { v: 2, c: 'Street Snacks', name: 'Onion Pakoda', price: 50, desc: 'Crispy onion fitters.' },
    { v: 2, c: 'Street Snacks', name: 'Masala Sundal', price: 45, desc: 'Spiced chickpeas snack.' },
    { v: 2, c: 'Street Snacks', name: 'Sweet Poli', price: 30, desc: 'Stuffed sweet flatbread.' },
    { v: 2, c: 'Street Snacks', name: 'Samosa - Set of 2', price: 30, desc: 'Classic tea-time snack.' },
    { v: 2, c: 'Non-Veg Gravies', name: 'Mutton Paya', price: 320, desc: 'Lamb trotters soup/gravy.' },
    { v: 2, c: 'Non-Veg Gravies', name: 'Blood Fry', price: 150, desc: 'Goat blood stir-fry with onions.' },
    { v: 2, c: 'Non-Veg Gravies', name: 'Boti Fry', price: 200, desc: 'Spiced goat intestine fry.' },
    { v: 2, c: 'Non-Veg Gravies', name: 'Chicken Salna', price: 120, desc: 'Watery flavorful parotta gravy.' },
    { v: 2, c: 'Non-Veg Gravies', name: 'Egg Salna', price: 100, desc: 'Gravy with boiled egg halves.' },
    { v: 2, c: 'Non-Veg Gravies', name: 'Butter Chicken', price: 260, desc: 'Creamy tomato-based chicken gravy.' },
    { v: 2, c: 'Non-Veg Gravies', name: 'Garlic Chicken', price: 240, desc: 'Garlic infused chicken stir fry.' },
    { v: 2, c: 'Drinks', name: 'Lemon Juice', price: 30, desc: 'Freshly squeezed lemon drink.' },
    { v: 2, c: 'Drinks', name: 'Rose Milk', price: 40, desc: 'Chilled milk with rose syrup.' },
    { v: 2, c: 'Drinks', name: 'Nannari Sarbath', price: 50, desc: 'Root extract cool drink.' },
    { v: 2, c: 'Drinks', name: 'Panakam', price: 40, desc: 'Jaggery and pepper holy drink.' },
    { v: 2, c: 'Drinks', name: 'Butter Milk', price: 30, desc: 'Chilled spiced buttermilk.' },
    { v: 2, c: 'Non-Veg Gravies', name: 'Chicken Kari Dosa', price: 220, desc: 'Special thick dosa with chicken curry top.' },
    { v: 2, c: 'Non-Veg Gravies', name: 'Mutton Kari Dosa', price: 300, desc: 'Madurai style mutton stuffed dosa.' },
    { v: 2, c: 'Street Snacks', name: 'Keema Samosa', price: 60, desc: 'Mutton mince stuffed samosas.' },
    { v: 2, c: 'Parotta Specials', name: 'Egg Veechu Parotta', price: 80, desc: 'Large veechu folded with an egg.' },
    { v: 2, c: 'Parotta Specials', name: 'Chicken Keema Parotta', price: 200, desc: 'Parotta stuffed with minced chicken.' },
    { v: 2, c: 'Drinks', name: 'Mango Lassi', price: 90, desc: 'Creamy mango yogurt drink.' },
    { v: 2, c: 'Street Snacks', name: 'Chicken Lollipops', price: 240, desc: 'Deep fried chicken wingets.' },
    { v: 2, c: 'Parotta Specials', name: 'Malabar Parotta', price: 50, desc: 'Classic multi-layered Kerala style.' },
    { v: 2, c: 'Drinks', name: 'Falooda', price: 150, desc: 'Multi-layered ice cream desert.' },
    { v: 2, c: 'Street Snacks', name: 'Paneer 65', price: 160, desc: 'Spiced fried cottage cheese.' },
    { v: 2, c: 'Street Snacks', name: 'Cauliflower Gobi 65', price: 120, desc: 'Deep fried spiced cauliflower.' }
];

async function seed() {
    console.log('Starting seed process...');

    const vendorEmails = ['anna@bhawan.com', 'karaikudi@spice.com', 'madurai@bun.com'];
    const createdUsers = [];

    for (const email of vendorEmails) {
        console.log(`Checking user: ${email}`);

        const { data: authUserResult, error: authError } = await supabase.auth.admin.listUsers();
        if (authError) {
            console.error('Error listing users:', authError);
            throw authError;
        }

        let existingAuthUser = authUserResult.users.find(u => u.email === email);
        let userId;

        if (!existingAuthUser) {
            console.log(`Creating auth user: ${email}`);
            const { data: newAuth, error: createAuthError } = await supabase.auth.admin.createUser({
                email,
                password: 'password123',
                email_confirm: true,
                user_metadata: { name: email.split('@')[0].toUpperCase(), role: 'vendor' }
            });
            if (createAuthError) throw createAuthError;
            userId = newAuth.user.id;
        } else {
            userId = existingAuthUser.id;
        }

        let { data: user, error: selectError } = await supabase.from('users').select('*').eq('id', userId).single();
        if (!user) {
            console.log(`Syncing public user for: ${email}`);
            const { data: newUser, error: insertError } = await supabase.from('users').insert({
                id: userId,
                name: email.split('@')[0].toUpperCase(),
                email,
                role: 'vendor'
            }).select().single();
            if (insertError) throw insertError;
            createdUsers.push(newUser);
        } else {
            createdUsers.push(user);
        }
    }

    const createdVendors = [];
    for (let i = 0; i < vendors.length; i++) {
        const { data: vendor, error: vSelectError } = await supabase.from('vendors').select('*').eq('name', vendors[i].name).single();
        if (vSelectError && vSelectError.code !== 'PGRST116') throw vSelectError;

        if (!vendor) {
            console.log(`Creating vendor: ${vendors[i].name}`);
            const { data, error } = await supabase.from('vendors').insert({
                owner_id: createdUsers[i].id,
                name: vendors[i].name,
                description: vendors[i].description,
                is_open: true
            }).select().single();
            if (error) throw error;
            createdVendors.push(data);
        } else {
            createdVendors.push(vendor);
        }
    }

    const menuMap = {};
    for (let i = 0; i < vendors.length; i++) {
        const vendor = createdVendors[i];
        for (const catName of vendors[i].categories) {
            const { data: menu, error: mSelectError } = await supabase.from('menus').select('*').eq('vendor_id', vendor.id).eq('category_name', catName).single();
            if (!menu) {
                console.log(`Creating menu ${catName} for vendor ${vendor.name}`);
                const { data, error } = await supabase.from('menus').insert({
                    vendor_id: vendor.id,
                    category_name: catName,
                    sort_order: vendors[i].categories.indexOf(catName)
                }).select().single();
                if (error) throw error;
                menuMap[`${i}_${catName}`] = data.id;
            } else {
                menuMap[`${i}_${catName}`] = menu.id;
            }
        }
    }

    console.log(`Inserting ${menuItemsData.length} menu items...`);
    for (const item of menuItemsData) {
        const menuId = menuMap[`${item.v}_${item.c}`];
        if (!menuId) continue;
        const { data: existing } = await supabase.from('menu_items').select('*').eq('menu_id', menuId).eq('name', item.name).single();
        if (existing) continue;
        const { error } = await supabase.from('menu_items').insert({
            menu_id: menuId,
            name: item.name,
            description: item.desc,
            price: item.price,
            is_available: true
        });
        if (error) console.error(`Error inserting ${item.name}:`, error);
    }
    console.log('Seed completed successfully.');
}

seed().catch(err => {
    console.error('Seed error:', err);
    process.exit(1);
});
