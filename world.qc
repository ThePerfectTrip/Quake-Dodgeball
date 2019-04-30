
void() InitBodyQue;


void() main =
{
	dprint ("main function\n");
	
// these are just commands the the prog compiler to copy these files

	precache_file ("progs.dat");
	precache_file ("gfx.wad");
	precache_file ("quake.rc");
	precache_file ("default.cfg");

	precache_file ("end1.bin");
	precache_file2 ("end2.bin");

	precache_file ("demo1.dem");
	precache_file ("demo2.dem");
	precache_file ("demo3.dem");

//
// these are all of the lumps from the cached.ls files
//
	precache_file ("gfx/palette.lmp");
	precache_file ("gfx/colormap.lmp");

	precache_file2 ("gfx/pop.lmp");

	precache_file ("gfx/complete.lmp");
	precache_file ("gfx/inter.lmp");

	precache_file ("gfx/ranking.lmp");
	precache_file ("gfx/vidmodes.lmp");
	precache_file ("gfx/finale.lmp");
	precache_file ("gfx/conback.lmp");
	precache_file ("gfx/qplaque.lmp");

	precache_file ("gfx/menudot1.lmp");
	precache_file ("gfx/menudot2.lmp");
	precache_file ("gfx/menudot3.lmp");
	precache_file ("gfx/menudot4.lmp");
	precache_file ("gfx/menudot5.lmp");
	precache_file ("gfx/menudot6.lmp");

	precache_file ("gfx/menuplyr.lmp");
	precache_file ("gfx/bigbox.lmp");
	precache_file ("gfx/dim_modm.lmp");
	precache_file ("gfx/dim_drct.lmp");
	precache_file ("gfx/dim_ipx.lmp");
	precache_file ("gfx/dim_tcp.lmp");
	precache_file ("gfx/dim_mult.lmp");
	precache_file ("gfx/mainmenu.lmp");
	
	precache_file ("gfx/box_tl.lmp");
	precache_file ("gfx/box_tm.lmp");
	precache_file ("gfx/box_tr.lmp");
	
	precache_file ("gfx/box_ml.lmp");
	precache_file ("gfx/box_mm.lmp");
	precache_file ("gfx/box_mm2.lmp");
	precache_file ("gfx/box_mr.lmp");
	
	precache_file ("gfx/box_bl.lmp");
	precache_file ("gfx/box_bm.lmp");
	precache_file ("gfx/box_br.lmp");
	
	precache_file ("gfx/sp_menu.lmp");
	precache_file ("gfx/ttl_sgl.lmp");
	precache_file ("gfx/ttl_main.lmp");
	precache_file ("gfx/ttl_cstm.lmp");
	
	precache_file ("gfx/mp_menu.lmp");
	
	precache_file ("gfx/netmen1.lmp");
	precache_file ("gfx/netmen2.lmp");
	precache_file ("gfx/netmen3.lmp");
	precache_file ("gfx/netmen4.lmp");
	precache_file ("gfx/netmen5.lmp");
	
	precache_file ("gfx/sell.lmp");
	
	precache_file ("gfx/help0.lmp");
	precache_file ("gfx/help1.lmp");
	precache_file ("gfx/help2.lmp");
	precache_file ("gfx/help3.lmp");
	precache_file ("gfx/help4.lmp");
	precache_file ("gfx/help5.lmp");

	precache_file ("gfx/pause.lmp");
	precache_file ("gfx/loading.lmp");

	precache_file ("gfx/p_option.lmp");
	precache_file ("gfx/p_load.lmp");
	precache_file ("gfx/p_save.lmp");
	precache_file ("gfx/p_multi.lmp");

// sounds loaded by C code
	precache_sound ("misc/menu1.wav");
	precache_sound ("misc/menu2.wav");
	precache_sound ("misc/menu3.wav");

	precache_sound ("ambience/water1.wav");
	precache_sound ("ambience/wind2.wav");

// shareware
	precache_file ("maps/start.bsp");

	precache_file ("maps/e1m1.bsp");
	precache_file ("maps/e1m2.bsp");
	precache_file ("maps/e1m3.bsp");
	precache_file ("maps/e1m4.bsp");
	precache_file ("maps/e1m5.bsp");
	precache_file ("maps/e1m6.bsp");
	precache_file ("maps/e1m7.bsp");
	precache_file ("maps/e1m8.bsp");

// registered
	precache_file2 ("gfx/pop.lmp");

	precache_file2 ("maps/e2m1.bsp");
	precache_file2 ("maps/e2m2.bsp");
	precache_file2 ("maps/e2m3.bsp");
	precache_file2 ("maps/e2m4.bsp");
	precache_file2 ("maps/e2m5.bsp");
	precache_file2 ("maps/e2m6.bsp");
	precache_file2 ("maps/e2m7.bsp");

	precache_file2 ("maps/e3m1.bsp");
	precache_file2 ("maps/e3m2.bsp");
	precache_file2 ("maps/e3m3.bsp");
	precache_file2 ("maps/e3m4.bsp");
	precache_file2 ("maps/e3m5.bsp");
	precache_file2 ("maps/e3m6.bsp");
	precache_file2 ("maps/e3m7.bsp");

	precache_file2 ("maps/e4m1.bsp");
	precache_file2 ("maps/e4m2.bsp");
	precache_file2 ("maps/e4m3.bsp");
	precache_file2 ("maps/e4m4.bsp");
	precache_file2 ("maps/e4m5.bsp");
	precache_file2 ("maps/e4m6.bsp");
	precache_file2 ("maps/e4m7.bsp");
	precache_file2 ("maps/e4m8.bsp");

	precache_file2 ("maps/end.bsp");

	precache_file2 ("maps/dm1.bsp");
	precache_file2 ("maps/dm2.bsp");
	precache_file2 ("maps/dm3.bsp");
	precache_file2 ("maps/dm4.bsp");
	precache_file2 ("maps/dm5.bsp");
	precache_file2 ("maps/dm6.bsp");
};


entity() SelectBallSpot =
{
	local entity spot, spots;
	local float numspots;
	
	spot = find(world, classname, "info_ball_spot");
	while (spot)
	{
		numspots = numspots + 1;
		spot.goalentity = spots;
		spots = spot;
		spot = find(spot, classname, "info_ball_spot");
	}
	
	numspots = numspots - 1;
	numspots = rint(random()*numspots);
	
	spot = spots;
	while (numspots > 0)
	{
		spot = spot.goalentity;
		numspots = numspots - 1;
	}
	
	return spot;
};

void() ball_touch;
void() teleport_back;
void() put_ball =
{
	local entity spot;
	
	spot = SelectBallSpot ();
	
	self.movetype = MOVETYPE_BOUNCE;
	self.solid = SOLID_BBOX;
	self.classname = "dodgeball";
	
	self.velocity_x = -100 + random()*200;
	self.velocity_y = -100 + random()*200;
	self.velocity_z = 300;
	
	self.avelocity = '300 300 300';
	
	self.angles = vectoangles(self.velocity);
	
	self.touch = ball_touch;
	
	self.nextthink = time + 20;
	self.think = teleport_back;
	
	setmodel (self, "progs/ball_db.mdl");
	setsize (self, '-5 -5 -5', '5 5 5');
	setorigin (self, spot.origin + '0 0 1');
	
	spawn_tfog (self.origin);
};

void() put_sball =
{
	local entity spot, plr;
	
	if (classic_mode)
	{
		remove(self);
		return;
	}
	
	plr = find(world, classname, "player");
	if (plr)
	{	// must have at least one player
		if (random() < 0.5)
			spot = SelectTeamSpawn (1);
		else
			spot = SelectTeamSpawn (2);
		
		setorigin (self, spot.origin + '0 0 1');
		spawn_tfog (self.origin);
		self.oldspecial = self.special;
		DropSpecialBall ();
	}
	
	if (self.oldspecial)
		self.special = self.oldspecial;
	self.nextthink = time + 30 + random()*30;
	self.think = put_sball;
};

void() put_copter =
{
	local entity spot, plr;
	
	plr = find(world, classname, "player");
	if (plr)
	{	// must have at least one player
		if (random() < 0.5)
			spot = SelectTeamSpawn (1);
		else
			spot = SelectTeamSpawn (2);
		
		setorigin (self, spot.origin + '0 0 1');
		spawn_tfog (self.origin);
		self.oldspecial = self.special;
		DropSpecialBall ();
	}
	
	if (self.oldspecial)
		self.special = self.oldspecial;
	self.nextthink = time + 60 + random()*60;
	self.think = put_copter;
};

void() put_sentryball =
{
	local entity spot, plr;
	
	plr = find(world, classname, "player");
	if (plr)
	{	// must have at least one player
		if (random() < 0.5)
			spot = SelectTeamSpawn (1);
		else
			spot = SelectTeamSpawn (2);
		
		setorigin (self, spot.origin + '0 0 1');
		spawn_tfog (self.origin);
		self.oldspecial = self.special;
		DropSpecialBall ();
	}
	
	if (self.oldspecial)
		self.special = self.oldspecial;
	self.nextthink = time + 60 + random()*60;
	self.think = put_sentryball;
};
	

entity	lastspawn;

//=======================
/*QUAKED worldspawn (0 0 0) ?
Only used for the world entity.
Set message to the level name.
Set sounds to the cd track to play.

World Types:
0: medieval
1: metal
2: base
*/
//=======================
void() worldspawn =
{
	local entity ball, sball, copter, sentryball;
	local float i;
	
	lastspawn = world;
	InitBodyQue ();

// custom map attributes
	if (self.model == "maps/e1m8.bsp")
		cvar_set ("sv_gravity", "100");
	else
		cvar_set ("sv_gravity", "800");
	
	if (cvar("pr_checkextension"))
	{
		if (checkextension("DP_SV_BOTCLIENT"))
			has_bots = TRUE;
	}
	
	ceasefire = 1;

// the area based ambient sounds MUST be the first precache_sounds

// player precaches	
	W_Precache ();			// get weapon precaches

// sounds used from C physics code
	precache_sound ("demon/dland2.wav");		// landing thud
	precache_sound ("misc/h2ohit1.wav");		// landing splash

// setup precaches allways needed
	precache_sound ("items/itembk2.wav");		// item respawn sound
	precache_sound ("player/plyrjmp8.wav");		// player jump
	precache_sound ("player/land.wav");			// player landing
	precache_sound ("player/land2.wav");		// player hurt landing
	precache_sound ("player/drown1.wav");		// drowning pain
	precache_sound ("player/drown2.wav");		// drowning pain
	precache_sound ("player/gasp1.wav");		// gasping for air
	precache_sound ("player/gasp2.wav");		// taking breath
	precache_sound ("player/h2odeath.wav");		// drowning death

	precache_sound ("misc/talk.wav");			// talk
	precache_sound ("player/teledth1.wav");		// telefrag
	precache_sound ("misc/r_tele1.wav");		// teleport sounds
	precache_sound ("misc/r_tele2.wav");
	precache_sound ("misc/r_tele3.wav");
	precache_sound ("misc/r_tele4.wav");
	precache_sound ("misc/r_tele5.wav");
	precache_sound ("weapons/lock4.wav");		// ammo pick up
	precache_sound ("weapons/pkup.wav");		// weapon up
	precache_sound ("items/armor1.wav");		// armor up
	precache_sound ("weapons/lhit.wav");		//lightning
	precache_sound ("weapons/lstart.wav");		//lightning start
	precache_sound ("items/damage3.wav");

	precache_sound ("misc/power.wav");			//lightning for boss

// player gib sounds
	precache_sound ("player/gib.wav");			// player gib sound
	precache_sound ("player/udeath.wav");		// player gib sound
	precache_sound ("player/tornoff2.wav");		// gib sound

// player pain sounds

	precache_sound ("player/pain1.wav");
	precache_sound ("player/pain2.wav");
	precache_sound ("player/pain3.wav");
	precache_sound ("player/pain4.wav");
	precache_sound ("player/pain5.wav");
	precache_sound ("player/pain6.wav");

// player death sounds
	precache_sound ("player/death1.wav");
	precache_sound ("player/death2.wav");
	precache_sound ("player/death3.wav");
	precache_sound ("player/death4.wav");
	precache_sound ("player/death5.wav");

// ax sounds	
	precache_sound ("weapons/ax1.wav");			// ax swoosh
	precache_sound ("player/axhit1.wav");		// ax hit meat
	precache_sound ("player/axhit2.wav");		// ax hit world

	precache_sound ("player/h2ojump.wav");		// player jumping into water
	precache_sound ("player/slimbrn2.wav");		// player enter slime
	precache_sound ("player/inh2o.wav");		// player enter water
	precache_sound ("player/inlava.wav");		// player enter lava
	precache_sound ("misc/outwater.wav");		// leaving water sound

	precache_sound ("player/lburn1.wav");		// lava burn
	precache_sound ("player/lburn2.wav");		// lava burn

	precache_sound ("misc/water1.wav");			// swimming
	precache_sound ("misc/water2.wav");			// swimming

	precache_model ("progs/player.mdl");
	precache_model ("progs/eyes.mdl");
	precache_model ("progs/h_player.mdl");
	precache_model ("progs/gib1.mdl");
	precache_model ("progs/gib2.mdl");
	precache_model ("progs/gib3.mdl");

	precache_model ("progs/s_bubble.spr");	// drowning bubbles
	precache_model ("progs/s_explod.spr");	// sprite explosion

	precache_model ("progs/v_axe.mdl");
	precache_model ("progs/v_shot.mdl");
	precache_model ("progs/v_nail.mdl");
	precache_model ("progs/v_rock.mdl");
	precache_model ("progs/v_shot2.mdl");
	precache_model ("progs/v_nail2.mdl");
	precache_model ("progs/v_rock2.mdl");

	precache_model ("progs/bolt.mdl");		// for lightning gun
	precache_model ("progs/bolt2.mdl");		// for lightning gun
	precache_model ("progs/bolt3.mdl");		// for boss shock
	precache_model ("progs/lavaball.mdl");	// for testing
	
	precache_model ("progs/missile.mdl");
	precache_model ("progs/grenade.mdl");
	precache_model ("progs/spike.mdl");
	precache_model ("progs/s_spike.mdl");

	precache_model ("progs/backpack.mdl");

	precache_model ("progs/zom_gib.mdl");

	precache_model ("progs/v_light.mdl");

// dodgeball

        precache_sound ("music/db_gold_wins.wav");
        precache_sound ("music/db_green_wins.wav");
	
	
	if (cvar("scratch1") <= 0)
		i = 1;
	else
		i = cvar("scratch1");
	
	if (i > 10)
		i = 10;
	
	while (i > 0)
	{
		ball = spawn ();
		ball.nextthink = time + 1 + random();
		ball.think = put_ball;
		i = i - 1;
	}
	
	if (deathmatch == 2 && cvar("temp1") != 1)
	{
		i = 4;
		while (i > 0)
		{
			sball = spawn ();
			sball.special = i;
			sball.nextthink = time + 20 + random()*10;
			sball.think = put_sball;
			i = i - 1;
		}
		
		copter = spawn ();
		copter.special = 5;
		copter.nextthink = time + 60;
		copter.think = put_copter;
		
		sentryball = spawn ();
		sentryball.special = 6;
		sentryball.nextthink = time + 60;
		sentryball.think = put_sentryball;
	}
	

//
// Setup light animation tables. 'a' is total darkness, 'z' is maxbright.
//

	// 0 normal
	lightstyle(0, "m");
	
	// 1 FLICKER (first variety)
	lightstyle(1, "mmnmmommommnonmmonqnmmo");
	
	// 2 SLOW STRONG PULSE
	lightstyle(2, "abcdefghijklmnopqrstuvwxyzyxwvutsrqponmlkjihgfedcba");
	
	// 3 CANDLE (first variety)
	lightstyle(3, "mmmmmaaaaammmmmaaaaaabcdefgabcdefg");
	
	// 4 FAST STROBE
	lightstyle(4, "mamamamamama");
	
	// 5 GENTLE PULSE 1
	lightstyle(5,"jklmnopqrstuvwxyzyxwvutsrqponmlkj");
	
	// 6 FLICKER (second variety)
	lightstyle(6, "nmonqnmomnmomomno");
	
	// 7 CANDLE (second variety)
	lightstyle(7, "mmmaaaabcdefgmmmmaaaammmaamm");
	
	// 8 CANDLE (third variety)
	lightstyle(8, "mmmaaammmaaammmabcdefaaaammmmabcdefmmmaaaa");
	
	// 9 SLOW STROBE (fourth variety)
	lightstyle(9, "aaaaaaaazzzzzzzz");
	
	// 10 FLUORESCENT FLICKER
	lightstyle(10, "mmamammmmammamamaaamammma");

	// 11 SLOW PULSE NOT FADE TO BLACK
	lightstyle(11, "abcdefghijklmnopqrrqponmlkjihgfedcba");
	
	// styles 32-62 are assigned by the light program for switchable lights

	// 63 testing
	lightstyle(63, "a");
};


void() PrintScores =
{
	local string t;
	
	bprint ("Gold ");
	t = ftos(team1_score);
	bprint (t);
	bprint (" x ");
	t = ftos(team2_score);
	bprint (t);
	bprint (" Green\n");
};

void() PutClientInServer;
void() th_respawn =
{
	local entity oself;
	
	oself = self;
	self = self.owner;
	PutClientInServer ();
	self = oself;
	remove(self);
};

void() CheckRounds =
{
	local entity plr, temp;
	
	if (!team1_players || !team2_players)
		return;
	if (team1_dead < team1_players && team2_dead < team2_players)
		return;
	
	if (team1_dead == team1_players)
	{
		team2_score = team2_score + 1;
		bprint ("Green team has won!\n");
                sound (world, CHAN_AUTO, "music/db_green_wins.wav", 1 , ATTN_NONE);
	}
	if (team2_dead == team2_players)
	{
		team1_score = team1_score + 1;
		bprint ("Gold team has won!\n");
                sound (world, CHAN_AUTO, "music/db_gold_wins.wav", 1 , ATTN_NONE);
	}
	
        
	ceasefire = countdown = 1;
	countdown_time = time + 7;
	
	PrintScores ();
	plr = find(world, classname, "player");
	while (plr)
	{
		if (!plr.has_disconnected)
		{
			if (plr.died)
			{
				plr.died = 0;
				temp = spawn ();
				temp.owner = plr;
				temp.nextthink = time + 0.4 + 0.4*random();
				temp.think = th_respawn;
			}
			else
				plr.health = 100;	// reset health
		}
		
		if (team1_dead == team1_players)
			centerprint (plr, "Green team wins!\n");
		if (team2_dead == team2_players)
			centerprint (plr, "Gold team wins!\n");
		
		team1_dead = team2_dead = 0;
		
		plr = find(plr, classname, "player");
	}
};

void() StartFrame =
{
	teamplay = cvar("teamplay");
	skill = cvar("skill");
	classic_mode = cvar("temp1");
	framecount = framecount + 1;
	CheckRounds ();
	
	if (has_bots)
		BotFrame ();
};

/*
==============================================================================

BODY QUE

==============================================================================
*/

entity	bodyque_head;

void() bodyque =
{	// just here so spawn functions don't complain after the world
	// creates bodyques
};

void() InitBodyQue =
{
	local entity	e;
	
	bodyque_head = spawn();
	bodyque_head.classname = "bodyque";
	bodyque_head.owner = spawn();
	bodyque_head.owner.classname = "bodyque";
	bodyque_head.owner.owner = spawn();
	bodyque_head.owner.owner.classname = "bodyque";
	bodyque_head.owner.owner.owner = spawn();
	bodyque_head.owner.owner.owner.classname = "bodyque";
	bodyque_head.owner.owner.owner.owner = bodyque_head;
};


// make a body que entry for the given ent so the ent can be
// respawned elsewhere
void(entity ent) CopyToBodyQue =
{
	bodyque_head.angles = ent.angles;
	bodyque_head.model = ent.model;
	bodyque_head.skin = ent.skin;
	bodyque_head.modelindex = ent.modelindex;
	bodyque_head.frame = ent.frame;
	bodyque_head.colormap = ent.colormap;
	bodyque_head.movetype = ent.movetype;
	bodyque_head.velocity = ent.velocity;
	bodyque_head.flags = 0;
	setorigin (bodyque_head, ent.origin);
	setsize (bodyque_head, ent.mins, ent.maxs);
	bodyque_head = bodyque_head.owner;
};


