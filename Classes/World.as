
#include "Blocks.as"

const int chunk_width = 10;
const int chunk_depth = 10;
const int chunk_height = 10;

int world_width = 12;
int world_depth = 12;
int world_height = 6;
int world_width_depth = world_width * world_depth;
int world_size = world_width_depth * world_height;

int map_width = world_width * chunk_width;
int map_depth = world_depth * chunk_depth;
int map_height = world_height * chunk_height;
int map_width_depth = map_width * map_depth;
int map_size = map_width_depth * map_height;

class World
{
    u8[] map;
    u8[] faces_bits;
    Chunk@[] chunks;
    bool poop = false;

    void GenerateMap()
    {
        map.clear();
        map.resize(map_size);

        for(int y = 0; y < map_height; y++)
        {
            for(int z = 0; z < map_depth; z++)
            {
                for(int x = 0; x < map_width; x++)
                {
                    int index = y*map_width_depth + z*map_width + x;
                    /*if(y<10)
                    {
                        map[index] = block_hard_stone;
                        continue;
                    }
                    else if(y<14)
                    {
                        map[index] = block_stone;
                        continue;
                    }
                    else if(y<16)
                    {
                        map[index] = block_dirt;
                        continue;
                    }
                    else if(y<17)
                    {
                        map[index] = block_grass_dirt;
                        continue;
                    }
                    else
                    {
                        map[index] = block_air;
                        continue;
                    }*/
                    if(index % 2 == 1) map[index] = block_stone;
                    else map[index] = block_air;
                }
            }
        }
        Debug("Map generated");
    }

    void SetUpChunks()
    {
        chunks.clear();
        for(int i = 0; i < world_size; i++)
        {
            Chunk chunk;
            @chunk._world = @this;
            chunk.index = i;
            chunk.x = i % world_width; chunk.z = (i / world_width) % world_depth; chunk.y = i / world_width_depth;
            //print("chunk: "+chunk.x+","+chunk.y+","+chunk.z);
            chunk.world_x = chunk.x*chunk_width; chunk.world_z = chunk.z*chunk_depth; chunk.world_y = chunk.y*chunk_height;
            chunk.world_x_bounds = chunk.world_x+chunk_width; chunk.world_z_bounds = chunk.world_z+chunk_depth; chunk.world_y_bounds = chunk.world_y+chunk_height;
            chunk.visible = false; chunk.rebuild = true;
            chunks.push_back(@chunk);
        }
        poop = false;
    }

    void GenerateBlockFaces()
    {
        faces_bits.clear();
        faces_bits.resize(map_size);

        for(int y = 0; y < map_height; y++)
        {
            for(int z = 0; z < map_depth; z++)
            {
                for(int x = 0; x < map_width; x++)
                {
                    UpdateBlockFaces(x, y, z);
                }
            }
        }
    }

    void UpdateBlockFaces(int x, int y, int z)
    {
        u8 faces = 0;

        if(x > 0) if(!Blocks[map[getIndex(x-1, y, z)]].see_through) faces += 1;
        if(x < map_width-1) if(!Blocks[map[getIndex(x+1, y, z)]].see_through) faces += 2;
        if(z > 0) if(!Blocks[map[getIndex(x, y, z-1)]].see_through) faces += 4;
        if(z < map_depth-1) if(!Blocks[map[getIndex(x, y, z+1)]].see_through) faces += 8;
        if(y > 0) if(!Blocks[map[getIndex(x, y-1, z)]].see_through) faces += 16;
        if(y < map_height-1) if(!Blocks[map[getIndex(x, y+1, z)]].see_through) faces += 32;

        faces_bits[getIndex(x, y, z)] = faces;
    }

    int getIndex(int x, int y, int z)
    {
        int index = y*map_width_depth + z*map_width + x;
        return index;
    }

    void Serialize(CBitStream@ params)
    {
        uint similars = 1;
        u8 similar_block_id = 0;
        u8 block_id = 0;
        for(int i = 0; i < map_size; i++)
        {
            if(i == 0)
            {
                similar_block_id = map[i];
                block_id = similar_block_id;
                continue;
            }
            else
            {
                block_id = map[i];
                if(similar_block_id != block_id)
                {
                    params.write_u32(similars);
                    params.write_u8(similar_block_id);
                    similar_block_id = block_id;
                    similars = 1;
                }
                else
                {
                    similars++;
                }
            }
        }
    }

    void UnSerialize(CBitStream params)
    {
        map.clear();
        map.resize(map_size);
        int index = 0;
        while(!params.isBufferEnd())
        {
            u32 amount = params.read_u32();
            u8 block_id = params.read_u8();
            for(int i = 0; i < amount; i++)
            {
                map[index+i] = block_id;
                index++;
            }
        }
    }

    Chunk@ getChunk(int x, int y, int z)
    {
        if(!inChunkBounds(x, y, z)) return null;
        int index = y*world_width_depth + z*world_width + x;
        Chunk@ chunk = @chunks[index];
        return @chunk;
    }

    bool inChunkBounds(int x, int y, int z)
    {
        //print("---pos: "+x+","+y+","+z);
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
}

class Chunk
{
    World@ _world;
    int x, y, z, world_x, world_y, world_z, world_x_bounds, world_y_bounds, world_z_bounds;
    int index, world_index;
    bool visible, rebuild;
    Vertex[] mesh;

    Chunk(){}

    void GenerateMesh()
    {
        print("generating.");
        rebuild = false;
        mesh.clear();
        //Vec3f(x,y,z).Print();
        //Vec3f(world_x,world_y,world_z).Print();
        //Vec3f(world_x_bounds,world_y_bounds,world_z_bounds).Print();

        for (int i = 0; i < 500; i++)
        {
            print("block: "+_world.map[i]);
        }

        /*for (int _y = world_y; _y < world_y_bounds; _y++)
		{
			for (int _z = world_z; _z < world_z_bounds; _z++)
			{
				for (int _x = world_x; _x < world_x_bounds; _x++)
				{
                    //print("pos: "+x+","+y+","+z);
                    //Vec3f(_x,_y,_z).Print();
                    int index = _world.getIndex(_x, _y, _z);
                    //print("i: "+index);
                    u8 block = _world.map[index];
                    //print("block: "+_world.map[index]);
                    //if(block == block_air) continue;

                    Block@ b = Blocks[block];
                    addFaces(@b, _world.faces_bits[index], Vec3f(_x,_y,_z));
                }
            }
        }*/
    }

    void SetVisible()
    {
        visible = true;
    }

    void addFaces(Block@ b, u8 face_info, Vec3f pos)//, AmbientOcclusion@ block_ao)
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
	
	void addFrontFace(Block@ b, Vec3f pos)
	{
		mesh.push_back(Vertex(pos.x,	pos.y+1,	pos.z,	b.sides_start_u,	b.sides_start_v,	front_scol));
		mesh.push_back(Vertex(pos.x+1,	pos.y+1,	pos.z,	b.sides_end_u,	    b.sides_start_v,	front_scol));
		mesh.push_back(Vertex(pos.x+1,	pos.y,		pos.z,	b.sides_end_u,	    b.sides_end_v,	    front_scol));
		mesh.push_back(Vertex(pos.x,	pos.y,		pos.z,	b.sides_start_u,	b.sides_end_v,	    front_scol));
	}
	
	void addBackFace(Block@ b, Vec3f pos)
	{
		mesh.push_back(Vertex(pos.x+1,	pos.y+1,	pos.z+1,	b.sides_start_u,	b.sides_start_v,	back_scol));
		mesh.push_back(Vertex(pos.x,	pos.y+1,	pos.z+1,	b.sides_end_u,	    b.sides_start_v,	back_scol));
		mesh.push_back(Vertex(pos.x,	pos.y,		pos.z+1,	b.sides_end_u,	    b.sides_end_v,		back_scol));
		mesh.push_back(Vertex(pos.x+1,	pos.y,		pos.z+1,	b.sides_start_u,	b.sides_end_v,		back_scol));
	}
	
	void addUpFace(Block@ b, Vec3f pos)
	{
		mesh.push_back(Vertex(pos.x,	pos.y+1,	pos.z+1,	b.top_start_u,	b.top_start_v,	top_scol));
		mesh.push_back(Vertex(pos.x+1,	pos.y+1,	pos.z+1,	b.top_end_u,    b.top_start_v,	top_scol));
		mesh.push_back(Vertex(pos.x+1,	pos.y+1,	pos.z,		b.top_end_u,    b.top_end_v,    top_scol));
		mesh.push_back(Vertex(pos.x,	pos.y+1,	pos.z,		b.top_start_u,	b.top_end_v,    top_scol));
	}
	
	void addDownFace(Block@ b, Vec3f pos)
	{
		mesh.push_back(Vertex(pos.x,	pos.y,		pos.z,		b.bottom_start_u,	b.bottom_start_v,	bottom_scol));
		mesh.push_back(Vertex(pos.x+1,	pos.y,		pos.z,		b.bottom_end_u,	    b.bottom_start_v,	bottom_scol));
		mesh.push_back(Vertex(pos.x+1,	pos.y,		pos.z+1,	b.bottom_end_u,	    b.bottom_end_v,		bottom_scol));
		mesh.push_back(Vertex(pos.x,	pos.y,		pos.z+1,	b.bottom_start_u,	b.bottom_end_v,		bottom_scol));
	}
	
	void addRightFace(Block@ b, Vec3f pos)
	{
		mesh.push_back(Vertex(pos.x+1,	pos.y+1,	pos.z,		b.sides_start_u,	b.sides_start_v,	right_scol));
		mesh.push_back(Vertex(pos.x+1,	pos.y+1,	pos.z+1,	b.sides_end_u,	    b.sides_start_v,	right_scol));
		mesh.push_back(Vertex(pos.x+1,	pos.y,		pos.z+1,	b.sides_end_u,	    b.sides_end_v,		right_scol));
		mesh.push_back(Vertex(pos.x+1,	pos.y,		pos.z,		b.sides_start_u,	b.sides_end_v,		right_scol));
	}
	
	void addLeftFace(Block@ b, Vec3f pos)
	{
		mesh.push_back(Vertex(pos.x,	pos.y+1,	pos.z+1,	b.sides_start_u,	b.sides_start_v,	left_scol));
        mesh.push_back(Vertex(pos.x,	pos.y+1,	pos.z,		b.sides_end_u,	    b.sides_start_v,	left_scol));
        mesh.push_back(Vertex(pos.x,	pos.y,		pos.z,		b.sides_end_u,	    b.sides_end_v,		left_scol));
        mesh.push_back(Vertex(pos.x,	pos.y,		pos.z+1,	b.sides_start_u,	b.sides_end_v,		left_scol));
	}

    void Render()
    {
        Render::RawQuads("Blocks.png", mesh);
    }
}

const u8 debug_alpha =	255;
const u8 top_col =		255;
const u8 bottom_col =	166;
const u8 left_col =		191;
const u8 right_col =	191;
const u8 front_col =	230;
const u8 back_col =		230;

const SColor top_scol = SColor(debug_alpha, top_col, top_col, top_col);
const SColor bottom_scol = SColor(debug_alpha, bottom_col, bottom_col, bottom_col);
const SColor left_scol = SColor(debug_alpha, left_col, left_col, left_col);
const SColor right_scol = SColor(debug_alpha, right_col, right_col, right_col);
const SColor front_scol = SColor(debug_alpha, front_col, front_col, front_col);
const SColor back_scol = SColor(debug_alpha, back_col, back_col, back_col);