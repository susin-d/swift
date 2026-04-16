require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseKey) {
    console.error('Error: SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY must be set in .env');
    process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

// Use the customer found during research
const CUSTOMER_ID = 'f9994a91-ca34-4f1f-8439-6b4c5268d26a';

async function seedRevenue() {
    console.log('--- Starting Revenue Seeding ---');

    // 1. Fetch all vendors
    const { data: vendors, error: vendorError } = await supabase
        .from('vendors')
        .select('id, name');

    if (vendorError || !vendors) {
        console.error('Error fetching vendors:', vendorError);
        return;
    }

    console.log(`Found ${vendors.length} vendors.`);

    // 2. Fetch menu items for these vendors
    const { data: allMenuItems, error: itemsError } = await supabase
        .from('menu_items')
        .select('id, name, price, menu:menus(vendor_id)');

    if (itemsError || !allMenuItems) {
        console.error('Error fetching menu items:', itemsError);
        return;
    }

    // Group items by vendor
    const vendorItems = {};
    for (const item of allMenuItems) {
        const vendorId = item.menu.vendor_id;
        if (!vendorItems[vendorId]) vendorItems[vendorId] = [];
        vendorItems[vendorId].push(item);
    }

    const now = new Date();
    const statuses = ['completed', 'delivered', 'pending', 'cancelled'];
    
    let totalOrdersInserted = 0;
    let totalPaymentsInserted = 0;

    for (const vendor of vendors) {
        const items = vendorItems[vendor.id];
        if (!items || items.length === 0) {
            console.log(`Skipping vendor ${vendor.name} (no menu items).`);
            continue;
        }

        console.log(`Seeding revenue for ${vendor.name}...`);

        // Create 50 orders per vendor
        for (let i = 0; i < 50; i++) {
            // Random date in the last 30 days
            const daysAgo = Math.floor(Math.random() * 30);
            const hour = 10 + Math.floor(Math.random() * 12); // Between 10 AM and 10 PM
            const minute = Math.floor(Math.random() * 60);
            const orderDate = new Date(now);
            orderDate.setDate(now.getDate() - daysAgo);
            orderDate.setHours(hour, minute, 0);

            // Random status (weighted)
            const r = Math.random();
            let status = 'completed'; // 85% (previously included delivered)
            if (r > 0.85 && r <= 0.95) status = 'cancelled'; // 10%
            else if (r > 0.95) status = 'pending'; // 5%

            // Random items (1-3)
            const numItems = 1 + Math.floor(Math.random() * 3);
            const selectedItems = [];
            let totalAmount = 0;
            for (let j = 0; j < numItems; j++) {
                const item = items[Math.floor(Math.random() * items.length)];
                selectedItems.push(item);
                totalAmount += item.price;
            }

            // Insert Order
            const { data: order, error: orderErr } = await supabase
                .from('orders')
                .insert({
                    user_id: CUSTOMER_ID,
                    vendor_id: vendor.id,
                    total_amount: totalAmount,
                    status: status,
                    created_at: orderDate.toISOString(),
                    updated_at: orderDate.toISOString()
                })
                .select()
                .single();

            if (orderErr) {
                console.error(`Error inserting order for ${vendor.name}:`, orderErr);
                continue;
            }

            totalOrdersInserted++;

            // Insert Order Items
            const orderItemsPayload = selectedItems.map(item => ({
                order_id: order.id,
                item_id: item.id,
                quantity: 1,
                unit_price: item.price
            }));

            const { error: itemsErr } = await supabase
                .from('order_items')
                .insert(orderItemsPayload);

            if (itemsErr) {
                console.error(`Error inserting order items for order ${order.id}:`, itemsErr);
            }

            // Insert Payment for non-cancelled
            if (status !== 'cancelled') {
                const { error: payErr } = await supabase
                    .from('payments')
                    .insert({
                        order_id: order.id,
                        amount: totalAmount,
                        status: status === 'pending' ? 'pending' : 'successful',
                        provider_ref: `demo_tx_${Math.random().toString(36).substring(7)}`
                    });

                if (payErr) {
                    console.error(`Error inserting payment for order ${order.id}:`, payErr);
                } else {
                    totalPaymentsInserted++;
                }
            }
        }
    }

    console.log('--- Seeding Completed ---');
    console.log(`Total Orders Inserted: ${totalOrdersInserted}`);
    console.log(`Total Payments Inserted: ${totalPaymentsInserted}`);
}

seedRevenue().catch(err => {
    console.error('Fatal seed error:', err);
    process.exit(1);
});
