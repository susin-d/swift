const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseKey) {
  console.error('Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

const buildings = [
  { name: 'Main Admin Block', code: 'ADM', address: 'Main Gate, Campus North', delivery_notes: 'Enter through the main reception.' },
  { name: 'Science & Technology Center', code: 'STC', address: 'Academic Quad, West', delivery_notes: 'Delivery allowed up to the lobby.' },
  { name: 'Library & Learning Hub', code: 'LLH', address: 'Central Campus', delivery_notes: 'Quiet zone. Keep phone on silent.' },
  { name: 'Hostel Complex A', code: 'HCA', address: 'Residential Area, East', delivery_notes: 'Deliver to security desk.' },
  { name: 'Arts & Humanities Building', code: 'AHB', address: 'Campus South', delivery_notes: 'First floor common area.' }
];

async function seed() {
  console.log('Seeding campus buildings and zones...');

  for (const bData of buildings) {
    console.log(`\nProcessing Building: ${bData.name}`);
    
    // Check if exists
    let { data: building, error: fetchError } = await supabase
      .from('campus_buildings')
      .select('*')
      .eq('name', bData.name)
      .maybeSingle();

    if (!building) {
      console.log(`  Creating new building: ${bData.name}`);
      const { data: newBuilding, error: bError } = await supabase
        .from('campus_buildings')
        .insert({
          name: bData.name,
          code: bData.code,
          address: bData.address,
          delivery_notes: bData.delivery_notes,
          is_active: true
        })
        .select()
        .single();

      if (bError) {
        console.error(`  Error creating building ${bData.name}: ${bError.message}`);
        continue;
      }
      building = newBuilding;
      console.log(`  ✓ Building created: ${building.id}`);
    } else {
      console.log(`  ✓ Building already exists: ${building.id}`);
    }

    // Seed some zones for each building
    const zones = [
      { name: 'Main Entrance', building_id: building.id },
      { name: 'Ground Floor Lobby', building_id: building.id },
      { name: 'Faculty Lounge', building_id: building.id }
    ];

    for (const zData of zones) {
        const { data: existingZone } = await supabase
            .from('delivery_zones')
            .select('*')
            .eq('name', zData.name)
            .eq('building_id', zData.building_id)
            .maybeSingle();
        
        if (!existingZone) {
            const { error: zError } = await supabase
                .from('delivery_zones')
                .insert({ ...zData, is_active: true });
            if (zError) console.error(`  Error creating zone ${zData.name}: ${zError.message}`);
            else console.log(`  ✓ Zone created: ${zData.name}`);
        } else {
            console.log(`  ✓ Zone exists: ${zData.name}`);
        }
    }
  }

  console.log('\nCampus data seeding completed.');
}

seed().catch(err => {
  console.error('Seed error:', err);
  process.exit(1);
});
