
const float u_step = 1.0f/16.0f;
const float v_step = 1.0f/16.0f;
const float uv_fix = 0.0002f;

enum block_id
{
    block_air = 0,
    block_grass_dirt,
    block_dirt,
    block_stone,
    block_hard_stone,
    block_stone_wall,
    block_gold,
    block_crate,
    
    block_log_birch,
    block_log,
    block_leaves,
    block_planks_birch,
    block_planks,
    block_bricks,
    block_glass,
    block_wool_red,
    
    block_wool_orange,
    block_wool_yellow,
    block_wool_green,
    block_wool_cyan,
    block_wool_blue,
    block_wool_darkblue,
    block_wool_purple,
    block_wool_white,
    
    block_wool_gray,
    block_wool_black,
    block_wool_brown,
    block_wool_pink,
    block_metal_shiny,
    block_metal,
    block_gearbox,
    block_bedrock,
    
    block_fence,
    block_grass,
    block_tulip,
    block_edelweiss,
    block_log_palm,
    block_sand,
    block_water,
    block_watersecond,
    
    blocks_count
}


Block@[] Blocks;

int block_counter = 0;
void InitBlocks()
{
    block_counter = 0;
    Blocks.clear();
    AddBlock("Air", false, true, 0);
    AddBlock("Grass dirt", true, false, 1, 2, 3);
    AddBlock("Dirt", true, false, 3);
    AddBlock("Stone", true, false, 4);
    AddBlock("Hard stone", true, false, 5);
    AddBlock("Stone wall", true, false, 6);
    AddBlock("Gold", true, false, 7);
    AddBlock("Crate", true, false, 8);
    AddBlock("Birch log", true, false, 81, 80);
    AddBlock("Log", true, false, 83, 82);
    AddBlock("Leaves", true, true, 19);
    AddBlock("Birch planks", true, false, 9);
    AddBlock("Planks", true, false, 10);
    AddBlock("Bricks", true, false, 11);
    AddBlock("Glass", true, true, 12);
    AddBlock("Red wool", true, false, 64);
    AddBlock("Orange wool", true, false, 65);
    AddBlock("Yellow wool", true, false, 66);
    AddBlock("Green wool", true, false, 67);
    AddBlock("Cyan wool", true, false, 68);
    AddBlock("Blue wool", true, false, 69); // nice
    AddBlock("Dark-blue wool", true, false, 70);
    AddBlock("Purple wool", true, false, 71);
    AddBlock("White wool", true, false, 74);
    AddBlock("Gray wool", true, false, 75);
    AddBlock("Black wool", true, false, 76);
    AddBlock("Brown wool", true, false, 73);
    AddBlock("Pink wool", true, false, 72);
    AddBlock("Shiny metal", true, false, 13);
    AddBlock("Metal", true, false, 14);
    AddBlock("Gearbox", true, false, 16);
    AddBlock("Bedrock", true, false, 240);
    AddBlock("Fence", true, true, 241);
    AddPlantBlock("Grass", 112);
    AddPlantBlock("Tulip", 113);
    AddPlantBlock("Edelweiss", 114);
    AddBlock("Palm log", true, false, 85, 84);
    AddBlock("Sand", true, false, 15);
    AddBlock("Water", true, false, 17);
    AddBlock("Deep water", true, false, 18);

    Blocks[block_bedrock].dig_speed = 0;
    Blocks[block_fence].dig_speed = 2.2;
    Blocks[block_leaves].dig_speed = 13;
    Blocks[block_stone].dig_speed = 3;
    Blocks[block_hard_stone].dig_speed = 3;

    Blocks[block_air].allowed_to_build = false;
    Blocks[block_bedrock].allowed_to_build = false;

    Debug("Blocks are created.");
}

class Block
{
    int id;
    string name;
    bool solid;
    bool see_through;
    bool plant;
    float dig_speed; // 100 - instant, 0 - dont break
    bool allowed_to_build;

    float sides_start_u;
    float sides_start_v;
    float sides_end_u;
    float sides_end_v;

    float top_start_u;
    float top_start_v;
    float top_end_u;
    float top_end_v;

    float bottom_start_u;
    float bottom_start_v;
    float bottom_end_u;
    float bottom_end_v;

    Block(){}

    void MakeUVs(int sides, int top, int bottom)
    {
        sides_start_u = float(sides % 16) / 16.0f + uv_fix;
        sides_start_v = float(sides / 16) / 16.0f + uv_fix;
        sides_end_u = sides_start_u + u_step - uv_fix*2.0f;
        sides_end_v = sides_start_v + v_step - uv_fix*2.0f;

        top_start_u = float(top % 16) / 16.0f + uv_fix;
        top_start_v = float(top / 16) / 16.0f + uv_fix;
        top_end_u = top_start_u + u_step - uv_fix*2.0f;
        top_end_v = top_start_v + v_step - uv_fix*2.0f;

        bottom_start_u = float(bottom % 16) / 16.0f + uv_fix;
        bottom_start_v = float(bottom / 16) / 16.0f + uv_fix;
        bottom_end_u = bottom_start_u + u_step - uv_fix*2.0f;
        bottom_end_v = bottom_start_v + v_step - uv_fix*2.0f;

        AddIconToken(name+"_Icon", "Textures/Blocks_Jenny.png", Vec2f(16,16), sides);
    }
}

void AddBlock(const string&in name, bool solid, bool see_through, int allsides)
{
    Debug("name: "+name, 2);
    Block newblock;
    newblock.id = block_counter;
    newblock.name = name;
    newblock.solid = solid;
    newblock.plant = false;
    newblock.dig_speed = 5;
    newblock.see_through = see_through;
    newblock.allowed_to_build = true;
    newblock.MakeUVs(allsides, allsides, allsides);

    Blocks.push_back(@newblock);

    block_counter++;
}

void AddBlock(const string&in name, bool solid, bool see_through, int sides, int top_and_bottom)
{
    Debug("name: "+name, 2);
    Block newblock;
    newblock.id = block_counter;
    newblock.name = name;
    newblock.solid = solid;
    newblock.plant = false;
    newblock.dig_speed = 5;
    newblock.see_through = see_through;
    newblock.allowed_to_build = true;
    newblock.MakeUVs(sides, top_and_bottom, top_and_bottom);

    Blocks.push_back(@newblock);

    block_counter++;
}

void AddBlock(const string&in name, bool solid, bool see_through, int sides, int top, int bottom)
{
    Debug("name: "+name, 2);
    Block newblock;
    newblock.id = block_counter;
    newblock.name = name;
    newblock.solid = solid;
    newblock.plant = false;
    newblock.dig_speed = 5;
    newblock.see_through = see_through;
    newblock.allowed_to_build = true;
    newblock.MakeUVs(sides, top, bottom);

    Blocks.push_back(@newblock);

    block_counter++;
}

void AddPlantBlock(const string&in name, int sides)
{
    Block newblock;
    newblock.id = block_counter;
    newblock.name = name;
    newblock.solid = false;
    newblock.see_through = true;
    newblock.plant = true;
    newblock.dig_speed = 100;
    newblock.allowed_to_build = true;
    newblock.MakeUVs(sides, sides, sides);

    Blocks.push_back(@newblock);

    block_counter++;
}