
#include "Blocks.as"

const uint32 chunk_width = 16;
const uint32 chunk_depth = 16;
const uint32 chunk_height = 14;

uint32 world_width = 8;
uint32 world_depth = 8;
uint32 world_height = 4;
uint32 world_width_depth = world_width * world_depth;
uint32 world_size = world_width_depth * world_height;

uint32 map_width = world_width * chunk_width;
uint32 map_depth = world_depth * chunk_depth;
uint32 map_height = world_height * chunk_height;
uint32 map_width_depth = map_width * map_depth;
uint32 map_size = map_width_depth * map_height;

float sample_frequency = 0.02f;
float fractal_frequency = 0.02f;
float add_height = 0.16f;
float dirt_start = 0.16f;
float tree_frequency = 0.06f;
float grass_frequency = 0.04f;

class World
{
    // y z x
    uint8[][][] map;
    uint8[][][] faces_bits;
    Chunk@[] chunks;
    bool poop = true;

    void GenerateMap()
    {
        Debug("Generating map.");
        map.clear();
        Debug("map_size: "+map_size, 2);

        uint32 seed = (1147483646*Time_Local()) % 500000;

        Debug("map seed: "+seed, 2);

        Noise noise(seed);
        Random rand(seed);
        
        float something = 1.0f/map_height;
    
        Vec3f[] trees;
        trees.clear();
        
        uint8[][][] _map(map_height, uint8[][](map_depth, uint8[](map_width, 0)));
        map = _map;
        for(float y = 0.0f; y < map_height; y += 1.0f)
        {
            float h_diff = y/float(map_height);
            for(float z = 0.0f; z < map_depth; z += 1.0f)
            {
                for(float x = 0.0f; x < map_width; x += 1.0f)
                {
                    bool make_tree = noise.Sample((map_width+x)*tree_frequency, z*tree_frequency) > 0.7;
                    if(make_tree && rand.NextRanged(50) > 2) make_tree = false;

                    bool make_grass = noise.Sample(x*grass_frequency, (map_depth+z)*grass_frequency) > 0.5;
                    if(make_grass && rand.NextRanged(50) > 40) make_grass = false;
                    bool make_flower = rand.NextRanged(24) == 1;
                    bool flower_type = rand.NextRanged(4) >= 2;
                    
                    float h = noise.Sample(x * sample_frequency, z * sample_frequency) * (noise.Fractal(x * fractal_frequency, z * fractal_frequency)/2.0f) + add_height;//+Maths::Pow(y / float(map_height), 1.1024f)-0.5;
                    if(y == 0)
                    {
                        map[y][z][x] = block_bedrock;
                    }
                    else if(h > h_diff)
                    {
                        if(h-h_diff <= dirt_start)
                        {
                            if(h-something > h_diff)
                                map[y][z][x] = block_dirt;
                            else
                            {
                                if(make_tree)
                                {
                                    trees.push_back(Vec3f(x,y+1,z));
                                    map[y][z][x] = block_dirt;
                                }
                                else if(make_grass)
                                {
                                    if(make_flower)
                                    {
                                        if(flower_type)
                                        {
                                            map[y+1][z][x] = block_tulip;
                                        }
                                        else
                                        {
                                            map[y+1][z][x] = block_edelweiss;
                                        }
                                    }
                                    else
                                    {
                                        map[y+1][z][x] = block_grass;
                                    }
                                    map[y][z][x] = block_grass_dirt;
                                }
                                else map[y][z][x] = block_grass_dirt;
                            }
                        }
                        else
                        {
                            if(h-h_diff > dirt_start+0.06)
                            {
                                map[y][z][x] = block_hard_stone;
                            }
                            else
                            {
                                map[y][z][x] = block_stone;
                            }
                        }
                    }
                    getNet().server_KeepConnectionsAlive();
                }
            }
        }
        Debug("Making trees...", 2);
        for(int i = 0; i < trees.size(); i++)
        {
            MakeTree(trees[i]);
        }
        Debug("Map generated.");
    }

    void ClientMapSetUp()
    {
        uint8[][][] _map(map_height, uint8[][](map_depth, uint8[](map_width, 0)));
        map = _map;
    }
    
    void FacesSetUp()
    {
        uint8[][][] _faces_bits(map_height, uint8[][](map_depth, uint8[](map_width, 0)));
        faces_bits = _faces_bits;
    }

    void MakeTree(Vec3f pos)
	{
		uint8 tree_type = block_log;
		if(XORRandom(3) == 0)
			tree_type = block_log_birch;
		if(inWorldBounds(pos.x, pos.y, pos.z))
		{
			SetBlock(pos.x, pos.y, pos.z, tree_type);
			pos.y += 1;
			if(inWorldBounds(pos.x, pos.y, pos.z))
			{
				SetBlock(pos.x, pos.y, pos.z, tree_type);
				pos.y += 1;
				if(inWorldBounds(pos.x, pos.y, pos.z))
				{
					SetBlock(pos.x, pos.y, pos.z, tree_type);
					
					for(int _z = -2; _z <= 2; _z++)
						for(int _x = -2; _x <= 2; _x++)
							if(!(_x == 0 && _z == 0))
								SetBlock(pos.x+_x, pos.y, pos.z+_z, block_leaves);
					
					pos.y += 1;
					if(inWorldBounds(pos.x, pos.y, pos.z))
					{
						SetBlock(pos.x, pos.y, pos.z, tree_type);
						
						for(int _z = -2; _z <= 2; _z++)
							for(int _x = -2; _x <= 2; _x++)
								if(!(_x == 0 && _z == 0))
									SetBlock(pos.x+_x, pos.y, pos.z+_z, block_leaves);
						
						pos.y += 1;
						if(inWorldBounds(pos.x, pos.y, pos.z))
						{
							SetBlock(pos.x, pos.y, pos.z, tree_type);
							
							for(int _z = -1; _z <= 1; _z++)
								for(int _x = -1; _x <= 1; _x++)
									if(!(_x == 0 && _z == 0))
										SetBlock(pos.x+_x, pos.y, pos.z+_z, block_leaves);
							
							pos.y += 1;
							if(inWorldBounds(pos.x, pos.y, pos.z))
							{
								SetBlock(pos.x+1, pos.y, pos.z, block_leaves);
								SetBlock(pos.x-1, pos.y, pos.z, block_leaves);
								SetBlock(pos.x, pos.y, pos.z, block_leaves);
								SetBlock(pos.x, pos.y, pos.z+1, block_leaves);
								SetBlock(pos.x, pos.y, pos.z-1, block_leaves);
								getNet().server_KeepConnectionsAlive();
							}
						}
					}
					getNet().server_KeepConnectionsAlive();
				}
			}
		}
		getNet().server_KeepConnectionsAlive();
	}

    void SetBlock(int x, int y, int z, uint8 block_id)
    {
        if(inWorldBounds(x, y, z)) map[y][z][x] = block_id;
    }

    void SetUpChunks()
    {
        chunks.clear();
        for(int i = 0; i < world_size; i++)
        {
            Chunk chunk(this, i);
            chunks.push_back(@chunk);
        }
    }

    void GenerateBlockFaces(uint32 _gf_packet)
    {
        uint32 start = _gf_packet*gf_packet_size;
        uint32 end = start+gf_packet_size;
        Vec3f pos;
        uint8 block_id;

        for(uint32 i = start; i < end; i++)
        {
            pos = getPosFromWorldIndex(i);
            UpdateBlockFaces(pos.x, pos.y, pos.z);
            getNet().server_KeepConnectionsAlive();
        }
    }

    void UpdateBlockFaces(int x, int y, int z)
    {
        if(map[y][z][x] == block_air || Blocks[map[y][z][x]].plant)
        {
            faces_bits[y][z][x] = 64;
            return;
        }
        
        uint8 faces = 0;

        if(z > 0 && Blocks[map[y][z-1][x]].see_through) faces += 1;
        if(z < map_depth-1 && Blocks[map[y][z+1][x]].see_through) faces += 2;
        if(y < map_height-1 && Blocks[map[y+1][z][x]].see_through) faces += 4;
        if(y > 0 && Blocks[map[y-1][z][x]].see_through) faces += 8;
        if(x < map_width-1 && Blocks[map[y][z][x+1]].see_through) faces += 16;
        if(x > 0 && Blocks[map[y][z][x-1]].see_through) faces += 32;

        faces_bits[y][z][x] = faces;
    }

    int getIndex(int x, int y, int z)
    {
        int index = y*map_width_depth + z*map_width + x;
        return index;
    }

    Vec3f getPosFromWorldIndex(int index)
    {
        return Vec3f(index % map_width, index / map_width_depth, (index / map_width) % map_depth);
    }

    void Serialize(CBitStream@ to_send, uint32 packet)
    {
        uint32 start = packet*ms_packet_size;
        uint32 end = start+ms_packet_size;
        Vec3f pos;
        uint8 block_id;

        uint32 similars = 0;
        uint8 similar_block_id = 0;

        for(uint32 i = start; i < end; i++)
        {
            pos = getPosFromWorldIndex(i);
            block_id = map[pos.y][pos.z][pos.x];
            if(i == start)
            {
                similar_block_id = block_id;
                similars++;
                continue;
            }
            else
            {
                if(similar_block_id == block_id)
                {
                    similars++;
                    continue;
                }
                else
                {
                    to_send.write_u32(similars);
                    to_send.write_u8(similar_block_id);
                    similar_block_id = block_id;
                    similars = 1;
                }
            }
            getNet().server_KeepConnectionsAlive();
        }
        to_send.write_u32(similars);
        to_send.write_u8(similar_block_id);
    }

    void UnSerialize(uint32 packet)
    {
        uint32 start = packet*ms_packet_size;
        uint32 end = start+ms_packet_size;
        Vec3f pos;
        uint8 block_id;

        uint32 index = 0;

        while(index < ms_packet_size)
        {
            uint32 amount = map_packet.read_u32();
            uint8 block_id = map_packet.read_u8();
            for(uint32 j = 0; j < amount; j++)
            {
                if(index == ms_packet_size)
                {
                    return;
                }
                pos = getPosFromWorldIndex(start+index);
                map[pos.y][pos.z][pos.x] = block_id;
                index++;
            }
        }
    }

    // old and slow way of map sending

    /*void Serialize(CBitStream@ to_send, uint32 packet)
    {
        uint32 start = packet*ms_packet_size;
        uint32 end = start+ms_packet_size;
        Vec3f pos;
        uint8 block_id;

        for(uint32 i = start; i < end; i++)
        {
            pos = getPosFromWorldIndex(i);
            block_id = map[pos.y][pos.z][pos.x];

            to_send.write_u8(block_id);
            getNet().server_KeepConnectionsAlive();
        }
    }

    void UnSerialize(uint32 packet)
    {
        uint32 start = packet*ms_packet_size;
        uint32 end = start+ms_packet_size;
        Vec3f pos;
        uint8 block_id;

        // skip 16 uint8's
        //map_packet.SetBitIndex(16*8*2);

        for(uint32 i = start; i < end; i++)
        {
            block_id = map_packet.read_uint8();
            pos = getPosFromWorldIndex(i);
            map[pos.y][pos.z][pos.x] = block_id;

            getNet().server_KeepConnectionsAlive();
        }
    }*/

    Chunk@ getChunk(int x, int y, int z)
    {
        if(!inChunkBounds(x, y, z)) return null;
        int index = y*world_width_depth + z*world_width + x;
        Chunk@ chunk = @chunks[index];
        return @chunk;
    }

    Chunk@ getChunkWorldPos(int x, int y, int z)
    {
        if(!inWorldBounds(x, y, z)) return null;
        x /= chunk_width; y /= chunk_height; x /= chunk_depth;
        int index = y*world_width_depth + z*world_width + x;
        Chunk@ chunk = @chunks[index];
        return @chunk;
    }

    bool inWorldBounds(int x, int y, int z)
    {
        if(x<0 || y<0 || z<0 || x>=map_width || y>=map_height || z>=map_depth) return false;
        return true;
    }
    
    bool inChunkBounds(int x, int y, int z)
    {
        if(x<0 || y<0 || z<0 || x>=world_width || y>=world_height || z>=world_depth) return false;
        return true;
    }

    void clearVisibility()
    {
        for(int i = 0; i < world_size; i++)
        {
            chunks[i].visible = false;
        }
    }

    bool isTileSolid(int x, int y, int z)
    {
        if(!inWorldBounds(x, y, z)) return false;
        return Blocks[map[y][z][x]].solid;
    }

    bool isTileSolidOrOOB(int x, int y, int z)
    {
        if(!inWorldBounds(x, y, z)) return true;
        return Blocks[map[y][z][x]].solid;
    }

    void UpdateBlocksAndChunks(int x, int y, int z)
    {
        world.UpdateBlockFaces(x, y, z);
        if(x > 0) world.UpdateBlockFaces(x-1, y, z);
        if(x+1 < map_width) world.UpdateBlockFaces(x+1, y, z);
        if(y > 0) world.UpdateBlockFaces(x, y-1, z);
        if(y+1 < map_height) world.UpdateBlockFaces(x, y+1, z);
        if(z > 0) world.UpdateBlockFaces(x, y, z-1);
        if(z+1 < map_depth) world.UpdateBlockFaces(x, y, z+1);

        Vec3f chunk_pos = Vec3f(int(x/chunk_width), int(y/chunk_height), int(z/chunk_depth));
        {Chunk@ chunk = world.getChunk(chunk_pos.x, chunk_pos.y, chunk_pos.z);if(chunk !is null){chunk.rebuild = true;chunk.empty = false;}}

        if(x % chunk_width == 0) {Chunk@ chunk = world.getChunk(chunk_pos.x-1, chunk_pos.y, chunk_pos.z); if(chunk !is null) {chunk.rebuild = true; chunk.empty = false;}}
        else if(x % chunk_width == chunk_width-1) {Chunk@ chunk = world.getChunk(chunk_pos.x+1, chunk_pos.y, chunk_pos.z); if(chunk !is null) {chunk.rebuild = true; chunk.empty = false;}}
        if(y % chunk_height == 0) {Chunk@ chunk = world.getChunk(chunk_pos.x, chunk_pos.y-1, chunk_pos.z); if(chunk !is null) {chunk.rebuild = true; chunk.empty = false;}}
        else if(y % chunk_height == chunk_height-1) {Chunk@ chunk = world.getChunk(chunk_pos.x, chunk_pos.y+1, chunk_pos.z); if(chunk !is null) {chunk.rebuild = true; chunk.empty = false;}}
        if(z % chunk_depth == 0) {Chunk@ chunk = world.getChunk(chunk_pos.x, chunk_pos.y, chunk_pos.z-1); if(chunk !is null) {chunk.rebuild = true; chunk.empty = false;}}
        else if(z % chunk_depth == chunk_depth-1) {Chunk@ chunk = world.getChunk(chunk_pos.x, chunk_pos.y, chunk_pos.z+1); if(chunk !is null) {chunk.rebuild = true; chunk.empty = false;}}
    }
}

class Chunk
{
    World@ _world;
    int x, y, z, world_x, world_y, world_z, world_x_bounds, world_y_bounds, world_z_bounds;
    int index, world_index;
    bool visible, rebuild, empty;
    Vertex[] verts;
    AABB box;

    Chunk(){}

    Chunk(World@ reference, int _index)
    {
        @_world = @reference;
        index = _index;
        x = _index % world_width; z = (_index / world_width) % world_depth; y = _index / world_width_depth;
        world_x = x*chunk_width; world_z = z*chunk_depth; world_y = y*chunk_height;
        world_x_bounds = world_x+chunk_width; world_z_bounds = world_z+chunk_depth; world_y_bounds = world_y+chunk_height;
        box = AABB(Vec3f(world_x, world_y, world_z), Vec3f(world_x_bounds, world_y_bounds, world_z_bounds));
        visible = false;
        rebuild = true;

        for (int _y = world_y; _y < world_y_bounds; _y++)
		{
			for (int _z = world_z; _z < world_z_bounds; _z++)
			{
				for (int _x = world_x; _x < world_x_bounds; _x++)
				{
                    //int index = _world.getIndex(_x, _y, _z);
                    //Vec3f(x,y,z).Print();
                    if(_world.faces_bits[_y][_z][_x] > 0)
                    {
                        empty = false;
                        return;
                    }
                }
            }
        }
        empty = true;
    }

    void GenerateMesh()
    {
        rebuild = false;
        verts.clear();

        for (int _y = world_y; _y < world_y_bounds; _y++)
		{
			for (int _z = world_z; _z < world_z_bounds; _z++)
			{
				for (int _x = world_x; _x < world_x_bounds; _x++)
				{
                    //int index = _world.getIndex(_x, _y, _z);

                    uint8 block = _world.map[_y][_z][_x];

                    if(block == block_air) continue;

                    int faces = _world.faces_bits[_y][_z][_x];

                    if(faces == 0) continue;

                    Block@ b = Blocks[block];
                    if(b.plant)
                    {
                        addPlantFaces(@b, Vec3f(_x,_y,_z));
                    }
                    else
                    {
                        addFaces(@b, faces, Vec3f(_x,_y,_z));
                    }
                }
            }
        }
        if(verts.size() == 0)
        {
            empty = true;
        }
    }

    void SetVisible()
    {
        visible = true;
    }

    void addFaces(Block@ b, uint8 face_info, const Vec3f&in pos)
	{
		switch(face_info)
		{
			case 0:{ break;}
			case 1:{ addFrontFace(@b, pos); break;}
			case 2:{ addBackFace(@b, pos); break;}
			case 3:{ addFrontFace(@b, pos); addBackFace(@b, pos); break;}
			case 4:{ addUpFace(@b, pos); break;}
			case 5:{ addFrontFace(@b, pos); addUpFace(@b, pos); break;}
			case 6:{ addBackFace(@b, pos); addUpFace(@b, pos); break;}
			case 7:{ addFrontFace(@b, pos); addBackFace(@b, pos); addUpFace(@b, pos); break;}
			case 8:{ addDownFace(@b, pos); break;}
			case 9:{ addFrontFace(@b, pos); addDownFace(@b, pos); break;}
			case 10:{ addBackFace(@b, pos); addDownFace(@b, pos); break;}
			case 11:{ addFrontFace(@b, pos); addBackFace(@b, pos); addDownFace(@b, pos); break;}
			case 12:{ addUpFace(@b, pos); addDownFace(@b, pos); break;}
			case 13:{ addFrontFace(@b, pos); addUpFace(@b, pos); addDownFace(@b, pos); break;}
			case 14:{ addBackFace(@b, pos); addUpFace(@b, pos); addDownFace(@b, pos); break;}
			case 15:{ addFrontFace(@b, pos); addBackFace(@b, pos); addUpFace(@b, pos); addDownFace(@b, pos); break;}
			case 16:{ addRightFace(@b, pos); break;}
			case 17:{ addFrontFace(@b, pos); addRightFace(@b, pos); break;}
			case 18:{ addBackFace(@b, pos); addRightFace(@b, pos); break;}
			case 19:{ addFrontFace(@b, pos); addBackFace(@b, pos); addRightFace(@b, pos); break;}
			case 20:{ addUpFace(@b, pos); addRightFace(@b, pos); break;}
			case 21:{ addFrontFace(@b, pos); addUpFace(@b, pos); addRightFace(@b, pos); break;}
			case 22:{ addBackFace(@b, pos); addUpFace(@b, pos); addRightFace(@b, pos); break;}
			case 23:{ addFrontFace(@b, pos); addBackFace(@b, pos); addUpFace(@b, pos); addRightFace(@b, pos); break;}
			case 24:{ addDownFace(@b, pos); addRightFace(@b, pos); break;}
			case 25:{ addFrontFace(@b, pos); addDownFace(@b, pos); addRightFace(@b, pos); break;}
			case 26:{ addBackFace(@b, pos); addDownFace(@b, pos); addRightFace(@b, pos); break;}
			case 27:{ addFrontFace(@b, pos); addBackFace(@b, pos); addDownFace(@b, pos); addRightFace(@b, pos); break;}
			case 28:{ addUpFace(@b, pos); addDownFace(@b, pos); addRightFace(@b, pos); break;}
			case 29:{ addFrontFace(@b, pos); addUpFace(@b, pos); addDownFace(@b, pos); addRightFace(@b, pos); break;}
			case 30:{ addBackFace(@b, pos); addUpFace(@b, pos); addDownFace(@b, pos); addRightFace(@b, pos); break;}
			case 31:{ addFrontFace(@b, pos); addBackFace(@b, pos); addUpFace(@b, pos); addDownFace(@b, pos); addRightFace(@b, pos); break;}
			case 32:{ addLeftFace(@b, pos); break;}
			case 33:{ addFrontFace(@b, pos); addLeftFace(@b, pos); break;}
			case 34:{ addBackFace(@b, pos); addLeftFace(@b, pos); break;}
			case 35:{ addFrontFace(@b, pos); addBackFace(@b, pos); addLeftFace(@b, pos); break;}
			case 36:{ addUpFace(@b, pos); addLeftFace(@b, pos); break;}
			case 37:{ addFrontFace(@b, pos); addUpFace(@b, pos); addLeftFace(@b, pos); break;}
			case 38:{ addBackFace(@b, pos); addUpFace(@b, pos); addLeftFace(@b, pos); break;}
			case 39:{ addFrontFace(@b, pos); addBackFace(@b, pos); addUpFace(@b, pos); addLeftFace(@b, pos); break;}
			case 40:{ addDownFace(@b, pos); addLeftFace(@b, pos); break;}
			case 41:{ addFrontFace(@b, pos); addDownFace(@b, pos); addLeftFace(@b, pos); break;}
			case 42:{ addBackFace(@b, pos); addDownFace(@b, pos); addLeftFace(@b, pos); break;}
			case 43:{ addFrontFace(@b, pos); addBackFace(@b, pos); addDownFace(@b, pos); addLeftFace(@b, pos); break;}
			case 44:{ addUpFace(@b, pos); addDownFace(@b, pos); addLeftFace(@b, pos); break;}
			case 45:{ addFrontFace(@b, pos); addUpFace(@b, pos); addDownFace(@b, pos); addLeftFace(@b, pos); break;}
			case 46:{ addBackFace(@b, pos); addUpFace(@b, pos); addDownFace(@b, pos); addLeftFace(@b, pos); break;}
			case 47:{ addFrontFace(@b, pos); addBackFace(@b, pos); addUpFace(@b, pos); addDownFace(@b, pos); addLeftFace(@b, pos); break;}
			case 48:{ addRightFace(@b, pos); addLeftFace(@b, pos); break;}
			case 49:{ addFrontFace(@b, pos); addRightFace(@b, pos); addLeftFace(@b, pos); break;}
			case 50:{ addBackFace(@b, pos); addRightFace(@b, pos); addLeftFace(@b, pos); break;}
			case 51:{ addFrontFace(@b, pos); addBackFace(@b, pos); addRightFace(@b, pos); addLeftFace(@b, pos); break;}
			case 52:{ addUpFace(@b, pos); addRightFace(@b, pos); addLeftFace(@b, pos); break;}
			case 53:{ addFrontFace(@b, pos); addUpFace(@b, pos); addRightFace(@b, pos); addLeftFace(@b, pos); break;}
			case 54:{ addBackFace(@b, pos); addUpFace(@b, pos); addRightFace(@b, pos); addLeftFace(@b, pos); break;}
			case 55:{ addFrontFace(@b, pos); addBackFace(@b, pos); addUpFace(@b, pos); addRightFace(@b, pos); addLeftFace(@b, pos); break;}
			case 56:{ addDownFace(@b, pos); addRightFace(@b, pos); addLeftFace(@b, pos); break;}
			case 57:{ addFrontFace(@b, pos); addDownFace(@b, pos); addRightFace(@b, pos); addLeftFace(@b, pos); break;}
			case 58:{ addBackFace(@b, pos); addDownFace(@b, pos); addRightFace(@b, pos); addLeftFace(@b, pos); break;}
			case 59:{ addFrontFace(@b, pos); addBackFace(@b, pos); addDownFace(@b, pos); addRightFace(@b, pos); addLeftFace(@b, pos); break;}
			case 60:{ addUpFace(@b, pos); addDownFace(@b, pos); addRightFace(@b, pos); addLeftFace(@b, pos); break;}
			case 61:{ addFrontFace(@b, pos); addUpFace(@b, pos); addDownFace(@b, pos); addRightFace(@b, pos); addLeftFace(@b, pos); break;}
			case 62:{ addBackFace(@b, pos); addUpFace(@b, pos); addDownFace(@b, pos); addRightFace(@b, pos); addLeftFace(@b, pos); break;}
			case 63:{ addFrontFace(@b, pos); addBackFace(@b, pos); addUpFace(@b, pos); addDownFace(@b, pos); addRightFace(@b, pos); addLeftFace(@b, pos); break;}
		}
	}
	
	void addFrontFace(Block@ b, const Vec3f&in pos)
	{
		verts.push_back(Vertex(pos.x,	pos.y+1,	pos.z,	b.sides_start_u,	b.sides_start_v,	front_scol));
		verts.push_back(Vertex(pos.x+1,	pos.y+1,	pos.z,	b.sides_end_u,	    b.sides_start_v,	front_scol));
		verts.push_back(Vertex(pos.x+1,	pos.y,		pos.z,	b.sides_end_u,	    b.sides_end_v,	    front_scol));
		verts.push_back(Vertex(pos.x,	pos.y,		pos.z,	b.sides_start_u,	b.sides_end_v,	    front_scol));
	}
	
	void addBackFace(Block@ b, const Vec3f&in pos)
	{
		verts.push_back(Vertex(pos.x+1,	pos.y+1,	pos.z+1,	b.sides_start_u,	b.sides_start_v,	back_scol));
		verts.push_back(Vertex(pos.x,	pos.y+1,	pos.z+1,	b.sides_end_u,	    b.sides_start_v,	back_scol));
		verts.push_back(Vertex(pos.x,	pos.y,		pos.z+1,	b.sides_end_u,	    b.sides_end_v,		back_scol));
		verts.push_back(Vertex(pos.x+1,	pos.y,		pos.z+1,	b.sides_start_u,	b.sides_end_v,		back_scol));
	}
	
	void addUpFace(Block@ b, const Vec3f&in pos)
	{
		verts.push_back(Vertex(pos.x,	pos.y+1,	pos.z+1,	b.top_start_u,	b.top_start_v,	top_scol));
		verts.push_back(Vertex(pos.x+1,	pos.y+1,	pos.z+1,	b.top_end_u,    b.top_start_v,	top_scol));
		verts.push_back(Vertex(pos.x+1,	pos.y+1,	pos.z,		b.top_end_u,    b.top_end_v,    top_scol));
		verts.push_back(Vertex(pos.x,	pos.y+1,	pos.z,		b.top_start_u,	b.top_end_v,    top_scol));
	}
	
	void addDownFace(Block@ b, const Vec3f&in pos)
	{
		verts.push_back(Vertex(pos.x,	pos.y,		pos.z,		b.bottom_start_u,	b.bottom_start_v,	bottom_scol));
		verts.push_back(Vertex(pos.x+1,	pos.y,		pos.z,		b.bottom_end_u,	    b.bottom_start_v,	bottom_scol));
		verts.push_back(Vertex(pos.x+1,	pos.y,		pos.z+1,	b.bottom_end_u,	    b.bottom_end_v,		bottom_scol));
		verts.push_back(Vertex(pos.x,	pos.y,		pos.z+1,	b.bottom_start_u,	b.bottom_end_v,		bottom_scol));
	}
	
	void addRightFace(Block@ b, const Vec3f&in pos)
	{
		verts.push_back(Vertex(pos.x+1,	pos.y+1,	pos.z,		b.sides_start_u,	b.sides_start_v,	right_scol));
		verts.push_back(Vertex(pos.x+1,	pos.y+1,	pos.z+1,	b.sides_end_u,	    b.sides_start_v,	right_scol));
		verts.push_back(Vertex(pos.x+1,	pos.y,		pos.z+1,	b.sides_end_u,	    b.sides_end_v,		right_scol));
		verts.push_back(Vertex(pos.x+1,	pos.y,		pos.z,		b.sides_start_u,	b.sides_end_v,		right_scol));
	}
	
	void addLeftFace(Block@ b, const Vec3f&in pos)
	{
		verts.push_back(Vertex(pos.x,	pos.y+1,	pos.z+1,	b.sides_start_u,	b.sides_start_v,	left_scol));
        verts.push_back(Vertex(pos.x,	pos.y+1,	pos.z,		b.sides_end_u,	    b.sides_start_v,	left_scol));
        verts.push_back(Vertex(pos.x,	pos.y,		pos.z,		b.sides_end_u,	    b.sides_end_v,		left_scol));
        verts.push_back(Vertex(pos.x,	pos.y,		pos.z+1,	b.sides_start_u,	b.sides_end_v,		left_scol));
	}

    void addPlantFaces(Block@ b, const Vec3f&in pos)
	{
		verts.push_back(Vertex(pos.x+0.84f,	pos.y+1,	pos.z+0.84f,	b.sides_start_u,	b.sides_start_v,	top_scol));
		verts.push_back(Vertex(pos.x+0.16f,	pos.y+1,	pos.z+0.16f,	b.sides_end_u,	    b.sides_start_v,	top_scol));
		verts.push_back(Vertex(pos.x+0.16f,	pos.y,		pos.z+0.16f,	b.sides_end_u,	    b.sides_end_v,		top_scol));
		verts.push_back(Vertex(pos.x+0.84f,	pos.y,		pos.z+0.84f,	b.sides_start_u,	b.sides_end_v,		top_scol));

		verts.push_back(Vertex(pos.x+0.84f,	pos.y+1,	pos.z+0.16f,	b.sides_start_u,	b.sides_start_v,	top_scol));
		verts.push_back(Vertex(pos.x+0.16f,	pos.y+1,	pos.z+0.84f,	b.sides_end_u,	    b.sides_start_v,	top_scol));
		verts.push_back(Vertex(pos.x+0.16f,	pos.y,		pos.z+0.84f,	b.sides_end_u,	    b.sides_end_v,		top_scol));
		verts.push_back(Vertex(pos.x+0.84f,	pos.y,		pos.z+0.16f,	b.sides_start_u,	b.sides_end_v,		top_scol));

		verts.push_back(Vertex(pos.x+0.16f,	pos.y+1,	pos.z+0.16f,	b.sides_start_u,	b.sides_start_v,	top_scol));
		verts.push_back(Vertex(pos.x+0.84f,	pos.y+1,	pos.z+0.84f,	b.sides_end_u,	    b.sides_start_v,	top_scol));
		verts.push_back(Vertex(pos.x+0.84f,	pos.y,		pos.z+0.84f,	b.sides_end_u,	    b.sides_end_v,		top_scol));
		verts.push_back(Vertex(pos.x+0.16f,	pos.y,		pos.z+0.16f,	b.sides_start_u,	b.sides_end_v,		top_scol));

		verts.push_back(Vertex(pos.x+0.16f,	pos.y+1,	pos.z+0.84f,	b.sides_start_u,	b.sides_start_v,    top_scol));
		verts.push_back(Vertex(pos.x+0.84f,	pos.y+1,	pos.z+0.16f,	b.sides_end_u,	    b.sides_start_v,	top_scol));
		verts.push_back(Vertex(pos.x+0.84f,	pos.y,		pos.z+0.16f,	b.sides_end_u,	    b.sides_end_v,		top_scol));
		verts.push_back(Vertex(pos.x+0.16f,	pos.y,		pos.z+0.84f,	b.sides_start_u,	b.sides_end_v,		top_scol));
	}

    void Render()
    {
        Render::RawQuads("Block_Textures", verts);
    }
}

const uint8 debug_alpha =	255;
const uint8 top_col =		255;
const uint8 bottom_col =	166;
const uint8 left_col =		191;
const uint8 right_col =	    191;
const uint8 front_col =	    230;
const uint8 back_col =		230;

const SColor top_scol = SColor(debug_alpha, top_col, top_col, top_col);
const SColor bottom_scol = SColor(debug_alpha, bottom_col, bottom_col, bottom_col);
const SColor left_scol = SColor(debug_alpha, left_col, left_col, left_col);
const SColor right_scol = SColor(debug_alpha, right_col, right_col, right_col);
const SColor front_scol = SColor(debug_alpha, front_col, front_col, front_col);
const SColor back_scol = SColor(debug_alpha, back_col, back_col, back_col);

void server_SetBlock(uint8 block, const Vec3f&in pos)
{
    if(!isServer())
    {
        CBitStream to_send;
        to_send.write_u8(block);
        to_send.write_f32(pos.x);
		to_send.write_f32(pos.y);
		to_send.write_f32(pos.z);
        getRules().SendCommand(getRules().getCommandID("C_ChangeBlock"), to_send, true);
        return;
    }
    
    world.map[pos.y][pos.z][pos.x] = block;
    world.UpdateBlocksAndChunks(pos.x, pos.y, pos.z);
}

// map sending and receiving

uint32 ms_packet_size = chunk_width*chunk_depth*chunk_height*16; // 16 chunks per packet
uint32 amount_of_packets = map_size / ms_packet_size;

// server

MapSender[] players_to_send;
class MapSender
{
    CPlayer@ player;
    uint32 packet_number = 0;

    MapSender(CPlayer@ _player, uint32 _packet_number)
    {
        @player = @_player;
        packet_number = _packet_number;
    }
}

// client

CBitStream map_packet;
uint32 got_packets;
bool ready_unser;

uint32 gf_amount_of_packets = amount_of_packets;
uint32 gf_packet_size = map_size / gf_amount_of_packets;
uint32 gf_packet;