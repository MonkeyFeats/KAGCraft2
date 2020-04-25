
#define CLIENT_ONLY

#include "Debug.as"
#include "World.as"
#include "Tree.as"
#include "Vec3f.as"
#include "ClientLoading.as"
#include "FrameTime.as"
#include "Raycast.as"
#include "Camera.as"
#include "Player.as"

World@ world;

Camera@ camera;

Player@ my_player;
Player@[] other_players;

void onInit(CRules@ this)
{
	Debug("Client init");
	Texture::createFromFile("Default_Textures", "Textures/Blocks_Jenny.png");
	Texture::createFromFile("MC_Textures", "Textures/Blocks_Minecraft.png");
	Texture::createFromFile("DEBUG", "Textures/Debug.png");
	Texture::createFromFile("refl", "Textures/refl.png");
	InitBlocks();

	Camera _camera;
	@camera = @_camera;

	if(this.exists("world"))
	{
		this.get("world", @world);
		world.SetUpMaterial();
		ask_map = true;
		map_ready = true;
	}
	else
	{
		World _world;
		@world = @_world;
		world.SetUpMaterial();
		world.ClientMapSetUp();
	}

	SMesh@ _grobber = SMesh();
    @grobber = @_grobber;
	grobber.LoadObjIntoMesh("BluGrobber.obj");
	grobber.SetHardwareMapping(SMesh::STATIC);
	SMaterial@ grobberMaterial = grobber.GetMaterial();
	grobberMaterial.DisableAllFlag();
	grobberMaterial.SetFlag(SMaterial::LIGHTING, true);
	grobberMaterial.SetFlag(SMaterial::COLOR_MASK, true);
	grobberMaterial.SetFlag(SMaterial::ZBUFFER, true);
	grobberMaterial.SetFlag(SMaterial::ZWRITE_ENABLE, true);
	grobberMaterial.SetFlag(SMaterial::BACK_FACE_CULLING, true);
	grobberMaterial.SetFlag(SMaterial::BLEND_OPERATION, true);
	grobberMaterial.SetMaterialType(SMaterial::TRANSPARENT_ALPHA_CHANNEL_REF);
	grobberMaterial.RegenMipMap(0);
	grobberMaterial.SetFlag(SMaterial::USE_MIP_MAPS, true);
	grobberMaterial.SetFlag(SMaterial::FOG_ENABLE, true);
	grobber.BuildMesh();
	
	Render::SetFog(0xFFA5BDC8, SMesh::LINEAR, camera.z_far*0.7f, camera.z_far, 0.01, true, true);

	//Render::SetAmbientLight(0xFFAABB11);
}

void onTick(CRules@ this)
{
	HitBoxes.clear();
	this.set_f32("interGameTime", getGameTime());
	this.set_f32("interFrameTime", 0);
	if(isLoading(this))
	{
		return;
	}
	else
	{
		// game here
		my_player.Update();
		if(!isServer())
		{
			CBitStream to_send;
			my_player.Serialize(@to_send);
			this.SendCommand(this.getCommandID("C_PlayerUpdate"), to_send, false);
		}

		tree.Check();
		//print("size: "+chunks_to_render.size());
	}
}

void onCommand(CRules@ this, u8 cmd, CBitStream@ params)
{
	//Debug("Command: "+cmd+" : "+this.getNameFromCommandID(cmd), 1);
	if(cmd == this.getCommandID("S_SendMapPacket"))
	{
		ready_unser = true;
		map_packet.Clear();
		map_packet = params;
		map_packet.SetBitIndex(params.getBitIndex());
	}
	else if(cmd == this.getCommandID("S_PlayerUpdate"))
	{
		u16 size = params.read_u16();
		for(int i = 0; i < size; i++)
		{
			u16 netid = params.read_netid();
			CPlayer@ _player = getPlayerByNetworkId(netid);
			if(_player !is null && _player !is getLocalPlayer())
			{
				bool exists = false;
				for(int i = 0; i < other_players.size(); i++)
				{
					Player@ __player = other_players[i];
					if(__player.player is _player)
					{
						__player.UnSerialize(params);
						exists = true;
						break;
					}
				}
				// doesnt exists
				if(!exists)
				{
					//print("lol");
					Player new_player();
					new_player.pos = Vec3f(map_width/2, map_height-4, map_depth/2);
					new_player.SetPlayer(_player);
					other_players.push_back(@new_player);
				}
				
			}
			else
			{
				f32 temp_float = params.read_f32();
				temp_float = params.read_f32();
				temp_float = params.read_f32();
				temp_float = params.read_f32();
				temp_float = params.read_f32();
				bool temp_bool = params.read_bool();
			}
		}
	}
	else if(cmd == this.getCommandID("C_RequestMap") || cmd == this.getCommandID("C_ReceivedMapPacket"))
	{
		return;
	}
}

float[] model;

SMesh@ grobber;

void Render(int id)
{
	CRules@ rules = getRules();
	rules.set_f32("interFrameTime", Maths::Clamp01(rules.get_f32("interFrameTime")+getRenderApproximateCorrectionFactor()));
	rules.add_f32("interGameTime", getRenderApproximateCorrectionFactor());

	Render::SetTransformWorldspace();
	
	camera.render_update();
	Matrix::MakeIdentity(model);
	Render::SetTransform(model, camera.view, camera.projection);

	Vertex[] verts = {
		Vertex(0, 0, 0, 0, 1, color_white),
		Vertex(0, 0, map_depth, 0, 0, color_white),
		Vertex(map_width,	0, map_depth,	1, 0, color_white),
		Vertex(map_width,	0, 0, 1, 1, color_white)
	};

	Render::ClearZ();
	Render::SetZBuffer(true, true);
	Render::SetAlphaBlend(false);
	Render::SetBackfaceCull(true);

	//Render::RawQuads("Default_Textures", verts);

	grobber.RenderMeshWithMaterial();

	world.mapMaterial.SetVideoMaterial();

	if(!getControls().isKeyPressed(KEY_KEY_Q))
	{
		int generated = 0;
		for(int i = 0; i < chunks_to_render.size(); i++)
		{
			Chunk@ chunk = chunks_to_render[i];
			if(chunk.rebuild)
			{
				if(generated < max_generate)
				{
					chunk.GenerateMesh();
					generated++;
				}
			}
			if(!chunk.empty)
			{
				chunks_to_render[i].Render();
				if(hold_frustum)
				{
					DrawHitbox(chunks_to_render[i].box, 0x880000FF);
				}
			}
		}
	}

	for(int i = 0; i < other_players.size(); i++)
	{
		Vec3f pos = other_players[i].pos;
		AABB _box(pos-Vec3f(player_radius,0,player_radius), pos+Vec3f(player_radius,player_height,player_radius));
		DrawHitbox(_box, 0x88FFFFFF);
	}

	Render::SetAlphaBlend(true);
	Render::RawQuads("DEBUG", HitBoxes);
	Render::SetAlphaBlend(false);

	GUI::SetFont("menu");
	GUI::DrawShadowedText("Pos: "+my_player.pos.IntString(), Vec2f(20,20), color_white);
	GUI::DrawShadowedText("Vel: "+my_player.vel.FloatString(), Vec2f(20,40), color_white);
	GUI::DrawShadowedText("Ang: "+my_player.look_dir.FloatString(), Vec2f(20,60), color_white);

	GUI::DrawShadowedText("dir_x: "+my_player.dir_x, Vec2f(20,80), color_white);
}

int max_generate = 2;

/*void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
	if(player is null || player is getLocalPlayer()) return;

	for(int i = 0; i < other_players.size(); i++)
	{
		Player@ _player = other_players[i];
		if(_player.player is player)
		{
			Debug("onNewPlayerJoin: Player already in list!", 3);
			return;
		}
	}

	Player new_player();
	new_player.pos = Vec3f(map_width/2, map_height-4, map_depth/2);
	new_player.SetPlayer(player);
	other_players.push_back(@new_player);
}*/

void onPlayerLeave(CRules@ this, CPlayer@ player)
{
	print("player left   "+other_players.size());
	if(player is null) return;

	for(int i = 0; i < other_players.size(); i++)
	{
		Player@ _player = other_players[i];
		if(_player.player is player)
		{
			other_players.removeAt(i);
			return;
		}
	}

	Debug("onPlayerLeave: Player was not on the list!", 3);
}