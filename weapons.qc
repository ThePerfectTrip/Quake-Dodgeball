/*
*/
void (entity targ, entity inflictor, entity attacker, float damage) T_Damage;
void () player_run;
void(entity bomb, entity attacker, float rad, entity ignore, string dtype) T_RadiusDamage;
void(vector org, vector vel, float damage) SpawnBlood;
void() SuperDamageSound;
void() BecomeExplosion;
void(string gibname, float dm) ThrowGib;
entity(float tno) SelectTeamSpawn;
entity() SelectBallSpot;


// called by worldspawn
void() W_Precache =
{
	precache_sound ("weapons/r_exp3.wav");	// new rocket explosion
	precache_sound ("weapons/rocket1i.wav");	// spike gun
	precache_sound ("weapons/sgun1.wav");
	precache_sound ("weapons/guncock.wav");	// player shotgun
	precache_sound ("weapons/ric1.wav");	// ricochet (used in c code)
	precache_sound ("weapons/ric2.wav");	// ricochet (used in c code)
	precache_sound ("weapons/ric3.wav");	// ricochet (used in c code)
	precache_sound ("weapons/spike2.wav");	// super spikes
	precache_sound ("weapons/tink1.wav");	// spikes tink (used in c code)
	precache_sound ("weapons/grenade.wav");	// grenade launcher
	precache_sound ("weapons/bounce.wav");		// grenade bounce
	precache_sound ("weapons/shotgn2.wav");	// super shotgun
	
	// dodgeball sounds/models
	precache_sound ("dodgeball/bounce_db.wav");
	precache_sound ("dodgeball/catch_db.wav");
	precache_sound ("dodgeball/deflect_woosh_db.wav");
	precache_sound ("dodgeball/icehit_db.wav");
	precache_sound ("dodgeball/hit1_db.wav");
	precache_sound ("dodgeball/hit2_db.wav");
	precache_sound ("dodgeball/powerthrow_db.wav");
	precache_sound ("dodgeball/prison_door_db.wav");
	precache_sound ("dodgeball/sprinting_db.wav");
	precache_sound ("speech/headshot_db.wav");
	precache_sound ("speech/fight_db.wav");
	precache_sound ("speech/roflcopter_db.wav");
	precache_sound ("speech/takesome_db.wav");
	precache_sound ("speech/coptergoes_db.wav");
	precache_sound ("zombie/z_shot1.wav");
	precache_sound ("hknight/attack1.wav");
	
	precache_model ("progs/ball_db.mdl");
	precache_model ("progs/ball2_db.mdl");
	precache_model ("progs/ball3_db.mdl");
	precache_model ("progs/player_db.mdl");
	precache_model ("progs/player_db2.mdl");
	precache_model ("progs/headless_db.mdl");
	precache_model ("progs/v_catch.mdl");
        precache_model ("progs/v_deflect.mdl");
	precache_model ("progs/v_dodgeball.mdl");
	precache_model ("progs/v_dodgeball2.mdl");
	precache_model ("progs/v_dodgeball3.mdl");
	precache_model ("progs/v_dodgeball4.mdl");
        precache_model ("progs/v_hdodgeball.mdl");
	precache_model ("progs/v_nododgeball.mdl");
        precache_model ("progs/v_roflcopterball.mdl");
        precache_model ("progs/v_spanner_ball.mdl");
	precache_model ("progs/flame2.mdl");
	precache_model ("progs/ice_db.mdl");
	precache_model ("progs/bigball_db.mdl");
	precache_model ("progs/prop_db.mdl");
	precache_model ("progs/sentry_stand_db.mdl");
	precache_model ("progs/sentry_top_db.mdl");
        precache_model ("progs/ball_roflcopter_db.mdl");
	precache_model ("progs/ball_spanner_db.mdl");
};

float() crandom =
{
	return 2*(random() - 0.5);
};

/*
================
W_FireAxe
================
*/
void() W_FireAxe =
{
	local	vector	source;
	local	vector	org;

	makevectors (self.v_angle);
	source = self.origin + '0 0 16';
	traceline (source, source + v_forward*64, FALSE, self);
	if (trace_fraction == 1.0)
		return;
	
	org = trace_endpos - v_forward*4;

	if (trace_ent.takedamage)
	{
		trace_ent.axhitme = 1;
		SpawnBlood (org, '0 0 0', 20);
		T_Damage (trace_ent, self, self, 20);
	}
	else
	{	// hit wall
		sound (self, CHAN_WEAPON, "player/axhit2.wav", 1, ATTN_NORM);
		WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
		WriteByte (MSG_BROADCAST, TE_GUNSHOT);
		WriteCoord (MSG_BROADCAST, org_x);
		WriteCoord (MSG_BROADCAST, org_y);
		WriteCoord (MSG_BROADCAST, org_z);
	}
};


entity(float tno) BringBackTeammate =
{
	local entity plr, player;
	local float nummates;
	
	plr = find(world, classname, "player");
	while (plr)
	{
		if (plr.died)
		if (plr.health > 0)
		if (plr.team_no == tno)
		{
			nummates = nummates + 1;
			plr.linked_list = player;
			player = plr;
		}
		plr = find(plr, classname, "player");
	}
	
	if (!nummates)
		return world;
	
	nummates = rint(random()*nummates);
	plr = player;
	while (nummates > 0)
	{
		plr = plr.linked_list;
		nummates = nummates - 1;
	}
	
	return plr;
};

void() player_catch2;
void() s_explode1;
void() ball_touch =
{
	local float damage, chance, headshot;
	local entity oself, exp, mate, spot;
	
	self.numbounces = self.numbounces + 1;
	if (self.numbounces > 1)
		self.owner = world;
	
	if (self.model != "progs/ball_db.mdl")
	{
		setmodel (self, "progs/ball_db.mdl");
		setsize (self, '-5 -5 -5', '5 5 5');
	}
	
	if (classic_mode)
	{
		damage = 100;
		chance = -1;
	}
	else
	{
		if (self.cnt == 1)	// power throw
		{
			damage = 80 + 20*random();	// 80-100
			chance = 0.15;
		}
		else if (self.cnt == 2)
		{
			damage = 40 + 35*random();	// 40-75
			chance = 0.1;
		}
		else if (self.cnt == 3)
		{
			damage = 100 + 50*random();	// 100-150
			chance = 0.25;
		}
		else
		{
			damage = 20 + 30*random();	// 20-50
			chance = 0.05;
		}
	}
	
	if (other.takedamage == DAMAGE_AIM)
	{
		if (self.flags & FL_ONGROUND && !other.has_ball && other.frozen < time)
		{
			sound (other, CHAN_BODY, "dodgeball/catch_db.wav", 1, ATTN_NORM);
			other.has_ball = 1;
			other.weaponmodel = "progs/v_dodgeball.mdl";
			remove(self);
			return;
		}
		
		if (other.catching && other.frozen < time && other.health > 0)
		{
			if (in_front(other, self))
			{
				if ((self.cnt == 1 || self.cnt == 3) && self.numbounces == 1)
				{
					damage = damage * 0.1;
					other.deathtype = "catching";
					T_Damage (other, self, self.owner, damage);
				}
				
				if (classic_mode && deathmatch == 2 && self.numbounces == 1 && other.team_no != self.owner.team_no)
				{
					mate = BringBackTeammate (other.team_no);
					if (mate)
					{
						if (mate.team_no == 1)
							team1_dead = team1_dead - 1;
						else if (mate.team_no == 2)
							team2_dead = team2_dead - 1;
						
						bprint (mate.netname);
						bprint (" is back!\n");
						
						spot = SelectTeamSpawn (mate.team_no);
						mate.died = 0;
						mate.health = 100;
						spawn_tfog (mate.origin);
						setorigin (mate, spot.origin + '0 0 1');
						spawn_tfog (mate.origin);
						spawn_tdeath (mate.origin, mate);
					}
				}
				
				sound (other, CHAN_BODY, "dodgeball/catch_db.wav", 1, ATTN_NORM);
				other.has_ball = 1;
				other.weaponmodel = "progs/v_catch.mdl";
				oself = self;
				self = other;
				player_catch2 ();
				self = oself;
				remove(self);
				return;
			}
		}
		
		if (other.deflecting && other.health > 0)
		{
			sound (self, CHAN_WEAPON, "dodgeball/bounce_db.wav", 1, ATTN_NORM);
			return;
		}
		
		if (other.team_no != self.owner.team_no && self.numbounces == 1 && self.dmgtime < time)
		{
			self.dmgtime = time + 0.5;
			
			if (random() <= chance)
			{	// critical hit!
				damage = damage * 3;
				sprint (self.owner, "Critical!!\n");
				WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
				WriteByte (MSG_BROADCAST, TE_TAREXPLOSION);
				WriteCoord (MSG_BROADCAST, self.origin_x);
				WriteCoord (MSG_BROADCAST, self.origin_y);
				WriteCoord (MSG_BROADCAST, self.origin_z);
				
				exp = spawn ();
				exp.nextthink = time;
				exp.think = s_explode1;
				setmodel (exp, "progs/s_explod.spr");
				setorigin (exp, self.origin);
			}
			
			if (self.cnt == 1 || self.cnt == 3)
			{
				if (other.classname == "player")
				{
					other.velocity = normalize(self.velocity) * 1500;
					if (other.velocity_z < 10)
						other.velocity_z = other.velocity_z + 300;
				}
				
				other.deathtype = "power";
				if (self.origin_z >= other.origin_z + 20 && other.classname == "player")
				{
					headshot = 1;
					other.deathtype = "headshot";
					damage = damage * 2;
				}
			}
			else
				other.deathtype = "normal";
			
			SpawnBlood (self.origin, self.velocity*0.2, damage);
			T_Damage (other, self, self.owner, damage);
			if (headshot && other.health <= 0)
			{
				centerprint (self.owner, "Head shot!\n");
				stuffcmd (self.owner, "play speech/headshot_db.wav\n");
			}
			
			if (self.cnt == 1 || self.cnt == 3)
				sound (self, CHAN_WEAPON, "dodgeball/hit2_db.wav", 1, ATTN_NORM);
			else
				sound (self, CHAN_WEAPON, "dodgeball/hit1_db.wav", 1, ATTN_NORM);
			return;
		}
	}
	
	sound (self, CHAN_WEAPON, "dodgeball/bounce_db.wav", 1, ATTN_NORM);
	if (self.velocity == '0 0 0')
		self.avelocity = '0 0 0';
};

void() teleport_back =
{
	local entity spot;
	
	spot = SelectBallSpot ();
	
	if (self.model != "progs/ball_db.mdl")
	{
		setmodel (self, "progs/ball_db.mdl");
		setsize (self, '-5 -5 -5', '5 5 5');
	}
	
	spawn_tfog (self.origin);
	setorigin (self, spot.origin + '0 0 1');
	spawn_tfog (self.origin);
	
	if (self.flags & FL_ONGROUND)
		self.flags = self.flags - FL_ONGROUND;
	
	self.velocity_x = crandom()*250;
	self.velocity_y = crandom()*250;
	self.velocity_z = 500;
	
	self.nextthink = time + 20;
	self.think = teleport_back;
};

void() ThrowSpecialBall;
void() ThrowBall =
{
	local entity ball;
	local float vel;
	
	if (!self.has_ball)
		return;
	
	if (self.special)
	{
		ThrowSpecialBall ();
		return;
	}
	
	self.has_ball = 0;
	
	self.punchangle_x = -1;
	
	sound (self, CHAN_WEAPON, "zombie/z_shot1.wav", 1, ATTN_NORM);
	
	self.weaponmodel = "progs/v_nododgeball.mdl";
	
	ball = spawn ();
	ball.owner = self;
	ball.movetype = MOVETYPE_BOUNCE;
	ball.solid = SOLID_BBOX;
	ball.classname = "dodgeball";
	
	makevectors (self.v_angle);
	
	if (self.sprinting)
	{
		vel = 1150;
		ball.cnt = 2;
	}
	else
		vel = 850;
	
	if (self.v_angle_x)
		ball.velocity = v_forward * vel + v_up * 200 + crandom()*v_right*10 + crandom()*v_up*10;
	else
	{
		ball.velocity = aim(self, 10000);
		ball.velocity = ball.velocity * vel;
		ball.velocity_z = 200;
	}
	
	ball.avelocity = '300 300 300';
	
	ball.angles = vectoangles(ball.velocity);
	
	ball.touch = ball_touch;
	
	ball.nextthink = time + 10;
	ball.think = teleport_back;
	
	setmodel (ball, "progs/ball_db.mdl");
	setsize (ball, '-5 -5 -5', '5 5 5');
	setorigin (ball, self.origin);
};

void() player_axe3;
void() PowerThrow =
{
	local entity ball;
	local float vel;
	local string temp;
	
	if (ceasefire)
		return;
	if (!self.has_ball)
		return;
	if (classic_mode)
		return;
	if (self.special)
		return;
	if (self.throw_finished > time)
	{
		sprint (self, "Wait ");
		temp = ftos(rint(self.throw_finished - time));
		sprint (self, temp);
		sprint (self, " seconds...\n");
		return;
	}
	
	self.has_ball = 0;
	self.throw_finished = time + 20;
	player_axe3 ();
	
	self.punchangle_x = -2;
	
	sound (self, CHAN_WEAPON, "dodgeball/powerthrow_db.wav", 1, ATTN_NORM);
	
	self.weaponmodel = "progs/v_nododgeball.mdl";
	
	ball = spawn ();
	ball.owner = self;
	ball.movetype = MOVETYPE_BOUNCE;
	ball.solid = SOLID_BBOX;
	ball.classname = "dodgeball";
	ball.cnt = 1;
	
	makevectors (self.v_angle);
	
	if (self.sprinting)
	{
		vel = 1750;
		ball.cnt = 3;
	}
	else
		vel = 1300;
	
	if (self.v_angle_x)
		ball.velocity = v_forward * vel + v_up * 200 + crandom()*v_right*10 + crandom()*v_up*10;
	else
	{
		ball.velocity = aim(self, 10000);
		ball.velocity = ball.velocity * vel;
		ball.velocity_z = 200;
	}
	
	ball.avelocity = '400 400 400';
	
	ball.angles = vectoangles(ball.velocity);
	
	ball.touch = ball_touch;
	
	ball.nextthink = time + 10;
	ball.think = teleport_back;
	
	setmodel (ball, "progs/ball2_db.mdl");
	setsize (ball, '-5 -5 -5', '5 5 5');
	setorigin (ball, self.origin);
};


void() freeze_think =
{
	self.nextthink = time;
	if (self.enemy.frozen < time)
	{
		stuffcmd (self.enemy, "cl_movespeedkey 1\n");
		stuffcmd (self.enemy, "cl_forwardspeed 1000\n");
		stuffcmd (self.enemy, "cl_backspeed 1000\n");
		stuffcmd (self.enemy, "cl_sidespeed 1000\n");
		stuffcmd (self.enemy, "cl_upspeed 1000\n");
		
		if (self.enemy.health > 0)
		{
			centerprint (self.enemy, "Defrost...\n");
			self.enemy.nextthink = time;
			self.enemy.think = player_run;
		}
		
		remove(self);
		return;
	}
	
	stuffcmd (self.enemy, "cl_movespeedkey 1\n");
	stuffcmd (self.enemy, "cl_forwardspeed 0\n");
	stuffcmd (self.enemy, "cl_backspeed 0\n");
	stuffcmd (self.enemy, "cl_sidespeed 0\n");
	stuffcmd (self.enemy, "cl_upspeed 0\n");
	
	if (self.enemy.flags & FL_ONGROUND)
		self.enemy.velocity_x = self.enemy.velocity_y = 0;
};

void(entity ent) Freeze =
{
	local entity e;
	
	if (ent.frozen > time)
	{
		ent.frozen = time + 3;
		return;
	}
	
	ent.frozen = time + 3;
	centerprint (ent, "You are frozen!\n");
	
	e = spawn ();
	e.owner = self.owner;
	e.enemy = ent;
	e.nextthink = time;
	e.think = freeze_think;
};

void() DropBall;
void() iceball_touch =
{
	local float i;
	local entity oself;
	
	if (other.takedamage)
	{
		if (other.team_no != self.owner.team_no)
		{
			Freeze (other);
			oself = self;
			self = other;
			DropBall ();
			self = oself;
		}
		other.deathtype = "ice";
		T_Damage (other, self, self.owner, 10);
	}
	
	sound (self, CHAN_WEAPON, "dodgeball/icehit_db.wav", 1, ATTN_NORM);
	
	i = 5;
	while (i > 0)
	{
		ThrowGib ("progs/ice_db.mdl", -70);
		i = i - 1;
	}
	
	remove(self);
};


void() homingball_touch =
{
	if (other.health)
	{
		other.deathtype = "homing";
		T_Damage (other, self, self.owner, 50);
	}
	
	T_RadiusDamage (self, self.owner, 50, other, "homing");
	
	self.origin = self.origin - 8*normalize(self.velocity);
	
	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_EXPLOSION);
	WriteCoord (MSG_BROADCAST, self.origin_x);
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);
	
	BecomeExplosion ();
};

void() BallFindTarget =
{
	local entity head, selected;
	local float dist, best;
	
	best = 99999999;
	head = find(world, classname, "player");
	while (head)
	{
		if (head.health > 0)
		if (!head.died)
		if (head.team_no != self.owner.team_no)
		{
			traceline (self.origin, head.origin + '0 0 16', TRUE, self);
			if (trace_fraction == 1)
			{
				dist = vlen(head.origin - self.origin);
				if (dist < best)
				{
					best = dist;
					selected = head;
				}
			}
		}
		head = find(head, classname, "player");
	}
	
	if (selected)
		self.enemy = selected;
};

void() homingball_think =
{
	local vector dir, vtemp;
	
	self.nextthink = time + 0.2;
	
	if (!self.enemy)
		BallFindTarget ();
	else
	{
		if (self.enemy.health <= 0)
			self.enemy = world;
		
		vtemp = self.enemy.origin + '0 0 10';
		dir = normalize(vtemp - self.origin);
		self.velocity = dir * 350;
	}
	
	if (self.lifetime < time)
		self.touch ();
};


void() bombball_touch =
{
	T_RadiusDamage (self, self.owner, 160, world, "bomb");
	
	self.origin = self.origin - 8*normalize(self.velocity);
	
	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_EXPLOSION);
	WriteCoord (MSG_BROADCAST, self.origin_x);
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);
	
	BecomeExplosion ();
};


void() onfire_think =
{
	self.nextthink = time;
	if (self.enemy.onfire < time || self.enemy.health <= 0)
	{
		self.enemy.onfire = 0;
		remove(self);
		return;
	}
	
	setorigin (self, self.enemy.origin + '0 0 24');
	if (self.frags < time)
	{
		self.enemy.deathtype = "fire";
		T_Damage (self.enemy, self, self.owner, 3);
		self.frags = time + 0.3;
	}
};

void(entity ent) Onfire =
{
	local entity e;
	
	if (ent.onfire > time)
	{
		ent.onfire = time + 3;
		return;
	}
	
	ent.onfire = time + 3;
	centerprint (ent, "You are on fire!\n");
	
	e = spawn ();
	e.owner = self.owner;
	e.enemy = ent;
	e.effects = EF_DIMLIGHT;
	e.nextthink = time;
	e.think = onfire_think;
	setmodel (e, "progs/flame2.mdl");
};

void() fireball_touch =
{
	if (other.takedamage)
	{
		other.deathtype = "fire";
		T_Damage (other, self, self.owner, 20);
		if (other.team_no != self.owner.team_no)
			Onfire (other);
	}
	sound (self, CHAN_WEAPON, "hknight/attack1.wav", 1, ATTN_NORM);
	BecomeExplosion ();
};

void() roflcopter_explode =
{
	local entity ball;
	local float i;
	
	T_RadiusDamage (self, self.owner, 100, world, "roflcopter");
	
	i = 10;
	while (i > 0)
	{
		ball = spawn ();
		ball.owner = self.owner;
		ball.movetype = MOVETYPE_BOUNCE;
		ball.solid = SOLID_BBOX;
		ball.classname = "dodgeball";
		ball.special = 1;
		ball.velocity_x = crandom()*300;
		ball.velocity_y = crandom()*300;
		ball.avelocity = '300 300 300';
		ball.angles = vectoangles(ball.velocity);
		ball.nextthink = time + 5;
		ball.think = SUB_Remove;
		
		if (random() < 0.3)
		{
			setmodel (ball, "progs/ball_db.mdl");
			ball.skin = 1;
			ball.touch = iceball_touch;
		}
		else if (random() < 0.6)
		{
			setmodel (ball, "progs/ball3_db.mdl");
			ball.skin = 1;
			ball.touch = bombball_touch;
		}
		else
		{
			setmodel (ball, "progs/ball3_db.mdl");
			ball.skin = 2;
			ball.touch = fireball_touch;
		}
		
		setsize (ball, '0 0 0', '0 0 0');
		setorigin (ball, self.origin);
		
		i = i - 1;
	}
	
	if (self.propeller)
		remove(self.propeller);
	
	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_EXPLOSION);
	WriteCoord (MSG_BROADCAST, self.origin_x);
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);
	
	BecomeExplosion ();
};

void() roflcopter_explode2 =
{
	T_RadiusDamage (self, self.owner, 100, world, "roflcopter");
	if (self.propeller)
		remove(self.propeller);
	
	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_EXPLOSION);
	WriteCoord (MSG_BROADCAST, self.origin_x);
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);
	
	BecomeExplosion ();
};

void() roflcopter_think =
{
	self.nextthink = time;
	if (countdown)
	{
		roflcopter_explode2 ();
		return;
	}
	if (self.lifetime < time)
	{
		roflcopter_explode ();
		return;
	}
	
	
	if (self.lip < time)
	{
		sound (self, CHAN_WEAPON, "speech/takesome_db.wav", 1, ATTN_NORM);
		self.lip = 99999999;
	}
	
	if (self.t_width < time)
	{
		sound (self, CHAN_VOICE, "speech/roflcopter_db.wav", 1, ATTN_NORM);
		self.t_width = time + 0.45;
	}
	
	if (self.frags < time)
	{
		makevectors (self.angles);
		self.velocity = v_forward * 100;
	}
	else
		self.velocity = '0 0 100';
	
	setorigin (self.propeller, self.origin);
	if (self.flags & FL_ONGROUND)
		self.flags = self.flags - FL_ONGROUND;
};

void() roflcopter_touch =
{
	if (other.solid != SOLID_BSP)
		return;
	roflcopter_explode ();
};

void() propeller_touch = 
{
	if (other.classname != "player")
		return;
	if (other.health <= 0)
		return;
	if (other.team_no == self.owner.team_no)
		return;
	
	if (other.origin_z + 22 < self.origin_z)
		other.deathtype = "copter_bottom";
	else
		other.deathtype = "copter";
	T_Damage (other, self, self.owner.owner, 50000);
};

void() Launch_Roflcopter =
{
	local entity ball, prop;
	
	sound (self, CHAN_WEAPON, "speech/coptergoes_db.wav", 1, ATTN_NORM);
	
	ball = spawn ();
	ball.owner = self;
	ball.movetype = MOVETYPE_FLY;
	ball.solid = SOLID_BBOX;
	ball.classname = "roflcopter";
	ball.special = self.special;
	ball.team_no = self.team_no;
	
	ball.velocity = '0 0 100';
	ball.angles_y = self.angles_y;
	
	ball.health = 150;
	ball.takedamage = DAMAGE_AIM;
	ball.th_die = roflcopter_explode;
	
	ball.touch = roflcopter_touch;
	
	ball.lifetime = time + 5 + 2*random();
	ball.frags = time + 1 + random();
	ball.lip = time + (ball.lifetime - time - 1.5);
	ball.nextthink = time;
	ball.think = roflcopter_think;
	
	setmodel (ball, "progs/bigball_db.mdl");
	setsize (ball, '-16 -16 -24', '16 16 11');
	setorigin (ball, self.origin);
	
	
	prop = spawn ();
	prop.owner = ball;
	ball.propeller = prop;
	prop.solid = SOLID_BBOX;
	prop.classname = "propeller";
	prop.angles_y = self.angles_y;
	prop.touch = propeller_touch;
	setmodel (prop, "progs/prop_db.mdl");
	setsize (prop, '-32 -32 0', '32 32 20');
};

void() SentryDie =
{
	sprint (self.builder, "Your sentry gun was destroyed.\n");
	T_RadiusDamage (self, self, 80, world);
	if (self.trigger_field)
		remove(self.trigger_field);
	
	self.origin_z = self.origin_z + 32;
	
	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_EXPLOSION);
	WriteCoord (MSG_BROADCAST, self.origin_x);
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);
	
	BecomeExplosion ();
};

void() lvl1_sentry_stand;
void() SentryBuilt =
{
	local entity gun;
	
	if (self.builder.health <= 0)
	{
		remove(self);
		return;
	}
	
	self.solid = SOLID_NOT;
	
	gun = spawn ();
	gun.builder = self.builder;
	gun.trigger_field = self;
	gun.movetype = MOVETYPE_STEP;
	gun.solid = SOLID_SLIDEBOX;
	gun.classname = "sentry";
	
	gun.health = 150;
	gun.takedamage = DAMAGE_AIM;
	gun.th_die = SentryDie;
	
	gun.team_no = self.builder.team_no;
	gun.view_ofs = '0 0 35';
	gun.angles_y = self.angles_y;
	gun.yaw_speed = 25;
	
	gun.nextthink = time + 0.5;
	gun.think = lvl1_sentry_stand;
	
	setmodel (gun, "progs/sentry_top_db.mdl");
	setsize (gun, '-32 -32 -8', '32 32 74');
	setorigin (gun, self.origin + '0 0 25');
};

void() BuildSentry =
{
	local entity base, oself;
	local vector v;
	
	v = self.v_angle;
	v_x = 0;
	
	makevectors (v);
	
	base = spawn ();
	base.solid = SOLID_SLIDEBOX;
	setsize (base, '-32 -32 -8', '32 32 74');
	setorigin (base, self.origin + v_forward*64);
	
	oself = self;
	self = base;
	if (!droptofloor(0,0))
	{
		sprint (oself, "Not enough room!\n");
		oself.special = 6; // give ball back
		remove(self);
		self = oself;
		return;
	}
	
	remove(self);
	self = oself;
	
	base = spawn ();
	base.builder = self;
	base.movetype = MOVETYPE_TOSS;
	base.solid = SOLID_SLIDEBOX;
	base.classname = "base";
	base.angles_y = self.angles_y;
	base.nextthink = time + 3;
	base.think = SentryBuilt;
	setmodel (base, "progs/sentry_stand_db.mdl");
	setsize (base, '-32 -32 -8', '32 32 74');
	setorigin (base, self.origin + v_forward*64);
};

void() ThrowSpecialBall =
{
	local entity ball;
	local float vel;
	
	if (!self.special)
		return;
	
	self.has_ball = 0;
	if (self.special == 5)
	{
		Launch_Roflcopter ();
		self.special = 0;
		return;
	}
	if (self.special == 6)
	{
		self.special = 0;
		BuildSentry ();
		return;
	}
	
	self.punchangle_x = -1;
	
	sound (self, CHAN_WEAPON, "zombie/z_shot1.wav", 1, ATTN_NORM);
	
	self.weaponmodel = "progs/v_nododgeball.mdl";
	
	ball = spawn ();
	ball.owner = self;
	ball.movetype = MOVETYPE_BOUNCE;
	ball.solid = SOLID_BBOX;
	ball.classname = "dodgeball";
	ball.special = self.special;	// so bots don't follow'em
	
	makevectors (self.v_angle);
	
	if (self.sprinting)
	{
		vel = 1150;
		ball.cnt = 2;
	}
	else
		vel = 850;
	
	if (self.v_angle_x)
		ball.velocity = v_forward * vel + v_up * 200 + crandom()*v_right*10 + crandom()*v_up*10;
	else
	{
		ball.velocity = aim(self, 10000);
		ball.velocity = ball.velocity * vel;
		ball.velocity_z = 200;
	}
	
	ball.avelocity = '300 300 300';
	
	ball.angles = vectoangles(ball.velocity);
	
	ball.nextthink = time + 5;
	ball.think = SUB_Remove;
	
	if (self.special == 1)
	{	// ice
		setmodel (ball, "progs/ball_db.mdl");
		ball.skin = 1;
		ball.touch = iceball_touch;
	}
	else if (self.special == 2)
	{	// homing
		setmodel (ball, "progs/ball3_db.mdl");
		ball.movetype = MOVETYPE_FLYMISSILE;
		ball.velocity = aim(self, 10000);
		ball.velocity = ball.velocity * 400;
		ball.touch = homingball_touch;
		ball.lifetime = time + 10;
		ball.nextthink = time + 0.2;
		ball.think = homingball_think;
	}
	else if (self.special == 3)
	{	// bomb
		setmodel (ball, "progs/ball3_db.mdl");
		ball.skin = 1;
		ball.touch = bombball_touch;
	}
	else if (self.special == 4)
	{	// fire
		setmodel (ball, "progs/ball3_db.mdl");
		ball.skin = 2;
		ball.touch = fireball_touch;
	}
	
	self.special = 0;
	
	setsize (ball, '-5 -5 -5', '5 5 5');
	setorigin (ball, self.origin);
};


void() specialball_pickup =
{
	local entity oself;
	
	if (other.classname != "player")
		return;
	if (other.health <= 0)
		return;
	if (other.has_ball)
		return;
	if (other.frozen > time)
		return;
	
	sprint (other, "You got the ");
	sprint (other, self.netname);
	sprint (other, "\n");
	stuffcmd (other, "bf\n");
	
	sound (other, CHAN_ITEM, "weapons/lock4.wav", 1, ATTN_NORM);
	other.has_ball = 1;
	other.special = self.special;
	
	remove(self);
	
	self = other;
	W_SetCurrentAmmo ();
};

void() DropSpecialBall =
{
	local entity ball;
	
	if (!self.special)
		return;
	
	ball = spawn ();
	ball.owner = self;
	ball.movetype = MOVETYPE_BOUNCE;
	ball.solid = SOLID_TRIGGER;
	ball.classname = "dodgeball";
	
	ball.velocity_x = crandom()*100;
	ball.velocity_y = crandom()*100;
	ball.velocity_z = 300;
	
	ball.avelocity = '300 300 300';
	
	ball.angles = vectoangles(ball.velocity);
	
	ball.special = self.special;
	ball.touch = specialball_pickup;
	
	if (self.special == 1)
	{	// ice
		setmodel (ball, "progs/ball_db.mdl");
		ball.skin = 1;
		ball.netname = "Ice Ball";
		setsize (ball, '-5 -5 -5', '5 5 5');
	}
	else if (self.special == 2)
	{	// homing
		setmodel (ball, "progs/ball3_db.mdl");
		ball.netname = "Homing Ball";
		setsize (ball, '-5 -5 -5', '5 5 5');
	}
	else if (self.special == 3)
	{	// bomb
		setmodel (ball, "progs/ball3_db.mdl");
		ball.skin = 1;
		ball.netname = "Bomb Ball";
		setsize (ball, '-5 -5 -5', '5 5 5');
	}
	else if (self.special == 4)
	{	// fire
		setmodel (ball, "progs/ball3_db.mdl");
		ball.skin = 2;
		ball.netname = "Fire Ball";
		setsize (ball, '-5 -5 -5', '5 5 5');
	}
	else if (self.special == 5)
	{	// roflcopter
                setmodel (ball, "progs/ball_roflcopter_db.mdl");
		ball.netname = "Roflcopter";
                setsize (ball, '-5 -5 -5', '5 5 5');
	}
	else if (self.special == 6)
	{	// sentry ball
		setmodel (ball, "progs/ball_spanner_db.mdl");
		ball.netname = "Sentry Ball";
		setsize (ball, '-5 -5 -5', '5 5 5');
	}
	
	self.special = 0;
	
	setorigin (ball, self.origin);
};

void() DropBall =
{
	local entity ball;
	
	if (!self.has_ball)
		return;
	
	self.has_ball = 0;
	if (self.special)
	{
		DropSpecialBall ();
		return;
	}
	
	ball = spawn ();
	ball.movetype = MOVETYPE_BOUNCE;
	ball.solid = SOLID_BBOX;
	ball.classname = "dodgeball";
	
	ball.velocity_x = crandom()*100;
	ball.velocity_y = crandom()*100;
	ball.velocity_z = 300;
	
	ball.avelocity = '300 300 300';
	
	ball.angles = vectoangles(ball.velocity);
	
	ball.touch = ball_touch;
	
	ball.nextthink = time + 10;
	ball.think = teleport_back;
	
	setmodel (ball, "progs/ball_db.mdl");
	setsize (ball, '-5 -5 -5', '5 5 5');
	setorigin (ball, self.origin);
};


//============================================================================


vector() wall_velocity =
{
	local vector	vel;
	
	vel = normalize (self.velocity);
	vel = normalize(vel + v_up*(random()- 0.5) + v_right*(random()- 0.5));
	vel = vel + 2*trace_plane_normal;
	vel = vel * 200;
	
	return vel;
};


/*
================
SpawnMeatSpray
================
*/
void(vector org, vector vel) SpawnMeatSpray =
{
	local	entity missile, mpuff;
	local	vector	org;

	missile = spawn ();
	missile.owner = self;
	missile.movetype = MOVETYPE_BOUNCE;
	missile.solid = SOLID_NOT;

	makevectors (self.angles);

	missile.velocity = vel;
	missile.velocity_z = missile.velocity_z + 250 + 50*random();

	missile.avelocity = '3000 1000 2000';
	
// set missile duration
	missile.nextthink = time + 1;
	missile.think = SUB_Remove;

	setmodel (missile, "progs/zom_gib.mdl");
	setsize (missile, '0 0 0', '0 0 0');		
	setorigin (missile, org);
};

/*
================
SpawnBlood
================
*/
void(vector org, vector vel, float damage) SpawnBlood =
{
	particle (org, vel*0.1, 73, damage*2);
};

/*
================
spawn_touchblood
================
*/
void(float damage) spawn_touchblood =
{
	local vector	vel;

	vel = wall_velocity () * 0.2;
	SpawnBlood (self.origin + vel*0.01, vel, damage);
};


/*
================
SpawnChunk
================
*/
void(vector org, vector vel) SpawnChunk =
{
	particle (org, vel*0.02, 0, 10);
};

/*
==============================================================================

MULTI-DAMAGE

Collects multiple small damages into a single damage

==============================================================================
*/

entity	multi_ent;
float	multi_damage;

void() ClearMultiDamage =
{
	multi_ent = world;
	multi_damage = 0;
};

void() ApplyMultiDamage =
{
	if (!multi_ent)
		return;
	T_Damage (multi_ent, self, self, multi_damage);
};

void(entity hit, float damage) AddMultiDamage =
{
	if (!hit)
		return;
	
	if (hit != multi_ent)
	{
		ApplyMultiDamage ();
		multi_damage = damage;
		multi_ent = hit;
	}
	else
		multi_damage = multi_damage + damage;
};

/*
==============================================================================

BULLETS

==============================================================================
*/

/*
================
TraceAttack
================
*/
void(float damage, vector dir) TraceAttack =
{
	local	vector	vel, org;
	
	vel = normalize(dir + v_up*crandom() + v_right*crandom());
	vel = vel + 2*trace_plane_normal;
	vel = vel * 200;

	org = trace_endpos - dir*4;

	if (trace_ent.takedamage)
	{
		SpawnBlood (org, vel*0.2, damage);
		AddMultiDamage (trace_ent, damage);
	}
	else
	{
		WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
		WriteByte (MSG_BROADCAST, TE_GUNSHOT);
		WriteCoord (MSG_BROADCAST, org_x);
		WriteCoord (MSG_BROADCAST, org_y);
		WriteCoord (MSG_BROADCAST, org_z);
	}
};

/*
================
FireBullets

Used by shotgun, super shotgun, and enemy soldier firing
Go to the trouble of combining multiple pellets into a single damage call.
================
*/
void(float shotcount, vector dir, vector spread) FireBullets =
{
	local	vector direction;
	local	vector	src;
	
	makevectors(self.v_angle);

	src = self.origin + v_forward*10;
	src_z = self.absmin_z + self.size_z * 0.7;

	ClearMultiDamage ();
	while (shotcount > 0)
	{
		direction = dir + crandom()*spread_x*v_right + crandom()*spread_y*v_up;

		traceline (src, src + direction*2048, FALSE, self);
		if (trace_fraction != 1.0)
			TraceAttack (4, direction);

		shotcount = shotcount - 1;
	}
	ApplyMultiDamage ();
};

/*
================
W_FireShotgun
================
*/
void() W_FireShotgun =
{
	local vector dir;

	sound (self, CHAN_WEAPON, "weapons/guncock.wav", 1, ATTN_NORM);	

	self.punchangle_x = -2;
	
	self.currentammo = self.ammo_shells = self.ammo_shells - 1;
	dir = aim (self, 100000);
	FireBullets (6, dir, '0.04 0.04 0');
};


/*
================
W_FireSuperShotgun
================
*/
void() W_FireSuperShotgun =
{
	local vector dir;

	if (self.currentammo == 1)
	{
		W_FireShotgun ();
		return;
	}
		
	sound (self ,CHAN_WEAPON, "weapons/shotgn2.wav", 1, ATTN_NORM);	

	self.punchangle_x = -4;
	
	self.currentammo = self.ammo_shells = self.ammo_shells - 2;
	dir = aim (self, 100000);
	FireBullets (14, dir, '0.14 0.08 0');
};


/*
==============================================================================

ROCKETS

==============================================================================
*/

void()	s_explode1	=	[0,		s_explode2] {};
void()	s_explode2	=	[1,		s_explode3] {};
void()	s_explode3	=	[2,		s_explode4] {};
void()	s_explode4	=	[3,		s_explode5] {};
void()	s_explode5	=	[4,		s_explode6] {};
void()	s_explode6	=	[5,		SUB_Remove] {};

void() BecomeExplosion =
{
	self.movetype = MOVETYPE_NONE;
	self.velocity = '0 0 0';
	self.touch = SUB_Null;
	setmodel (self, "progs/s_explod.spr");
	self.solid = SOLID_NOT;
	s_explode1 ();
};

void() T_MissileTouch =
{
	local float	damg;

	if (other == self.owner)
		return;		// don't explode on owner

	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return;
	}

	damg = 100 + random()*20;
	
	if (other.health)
	{
		if (other.classname == "monster_shambler")
			damg = damg * 0.5;	// mostly immune
		T_Damage (other, self, self.owner, damg );
	}

	// don't do radius damage to the other, because all the damage
	// was done in the impact
	T_RadiusDamage (self, self.owner, 120, other, "");

//	sound (self, CHAN_WEAPON, "weapons/r_exp3.wav", 1, ATTN_NORM);
	self.origin = self.origin - 8*normalize(self.velocity);

	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_EXPLOSION);
	WriteCoord (MSG_BROADCAST, self.origin_x);
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);

	BecomeExplosion ();
};



/*
================
W_FireRocket
================
*/
void() W_FireRocket =
{
	local	entity missile, mpuff;
	
	self.currentammo = self.ammo_rockets = self.ammo_rockets - 1;
	
	sound (self, CHAN_WEAPON, "weapons/sgun1.wav", 1, ATTN_NORM);

	self.punchangle_x = -2;

	missile = spawn ();
	missile.owner = self;
	missile.movetype = MOVETYPE_FLYMISSILE;
	missile.solid = SOLID_BBOX;
	missile.classname = "missile";
		
// set missile speed	

	makevectors (self.v_angle);
	missile.velocity = aim(self, 1000);
	missile.velocity = missile.velocity * 1000;
	missile.angles = vectoangles(missile.velocity);
	
	missile.touch = T_MissileTouch;
	
// set missile duration
	missile.nextthink = time + 5;
	missile.think = SUB_Remove;

	setmodel (missile, "progs/missile.mdl");
	setsize (missile, '0 0 0', '0 0 0');		
	setorigin (missile, self.origin + v_forward*8 + '0 0 16');
};

/*
===============================================================================

LIGHTNING

===============================================================================
*/

/*
=================
LightningDamage
=================
*/
void(vector p1, vector p2, entity from, float damage) LightningDamage =
{
	local entity		e1, e2;
	local vector		f;
	
	f = p2 - p1;
	normalize (f);
	f_x = 0 - f_y;
	f_y = f_x;
	f_z = 0;
	f = f*16;

	e1 = e2 = world;

	traceline (p1, p2, FALSE, self);
	if (trace_ent.takedamage)
	{
		particle (trace_endpos, '0 0 100', 225, damage*4);
		T_Damage (trace_ent, from, from, damage);
		if (self.classname == "player")
		{
			if (other.classname == "player")
				trace_ent.velocity_z = trace_ent.velocity_z + 400;
		}
	}
	e1 = trace_ent;

	traceline (p1 + f, p2 + f, FALSE, self);
	if (trace_ent != e1 && trace_ent.takedamage)
	{
		particle (trace_endpos, '0 0 100', 225, damage*4);
		T_Damage (trace_ent, from, from, damage);
	}
	e2 = trace_ent;

	traceline (p1 - f, p2 - f, FALSE, self);
	if (trace_ent != e1 && trace_ent != e2 && trace_ent.takedamage)
	{
		particle (trace_endpos, '0 0 100', 225, damage*4);
		T_Damage (trace_ent, from, from, damage);
	}
};


void() W_FireLightning =
{
	local	vector		org;
	local	float		cells;

	if (self.ammo_cells < 1)
	{
		self.weapon = W_BestWeapon ();
		W_SetCurrentAmmo ();
		return;
	}

// explode if under water
	if (self.waterlevel > 1)
	{
		cells = self.ammo_cells;
		self.ammo_cells = 0;
		W_SetCurrentAmmo ();
		T_RadiusDamage (self, self, 35*cells, world, "");
		return;
	}

	if (self.t_width < time)
	{
		sound (self, CHAN_WEAPON, "weapons/lhit.wav", 1, ATTN_NORM);
		self.t_width = time + 0.6;
	}
	self.punchangle_x = -2;

	self.currentammo = self.ammo_cells = self.ammo_cells - 1;

	org = self.origin + '0 0 16';
	
	traceline (org, org + v_forward*600, TRUE, self);

	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_LIGHTNING2);
	WriteEntity (MSG_BROADCAST, self);
	WriteCoord (MSG_BROADCAST, org_x);
	WriteCoord (MSG_BROADCAST, org_y);
	WriteCoord (MSG_BROADCAST, org_z);
	WriteCoord (MSG_BROADCAST, trace_endpos_x);
	WriteCoord (MSG_BROADCAST, trace_endpos_y);
	WriteCoord (MSG_BROADCAST, trace_endpos_z);

	LightningDamage (self.origin, trace_endpos + v_forward*4, self, 30);
};


//=============================================================================


void() GrenadeExplode =
{
	T_RadiusDamage (self, self.owner, 120, world, "");

	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_EXPLOSION);
	WriteCoord (MSG_BROADCAST, self.origin_x);
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);

	BecomeExplosion ();
};

void() GrenadeTouch =
{
	if (other == self.owner)
		return;		// don't explode on owner
	if (other.takedamage == DAMAGE_AIM)
	{
		GrenadeExplode();
		return;
	}
	sound (self, CHAN_WEAPON, "weapons/bounce.wav", 1, ATTN_NORM);	// bounce sound
	if (self.velocity == '0 0 0')
		self.avelocity = '0 0 0';
};

/*
================
W_FireGrenade
================
*/
void() W_FireGrenade =
{
	local	entity missile, mpuff;
	
	self.currentammo = self.ammo_rockets = self.ammo_rockets - 1;
	
	sound (self, CHAN_WEAPON, "weapons/grenade.wav", 1, ATTN_NORM);

	self.punchangle_x = -2;

	missile = spawn ();
	missile.owner = self;
	missile.movetype = MOVETYPE_BOUNCE;
	missile.solid = SOLID_BBOX;
	missile.classname = "grenade";
		
// set missile speed	

	makevectors (self.v_angle);

	if (self.v_angle_x)
		missile.velocity = v_forward*600 + v_up * 200 + crandom()*v_right*10 + crandom()*v_up*10;
	else
	{
		missile.velocity = aim(self, 10000);
		missile.velocity = missile.velocity * 600;
		missile.velocity_z = 200;
	}

	missile.avelocity = '300 300 300';

	missile.angles = vectoangles(missile.velocity);
	
	missile.touch = GrenadeTouch;
	
// set missile duration
	missile.nextthink = time + 2.5;
	missile.think = GrenadeExplode;

	setmodel (missile, "progs/grenade.mdl");
	setsize (missile, '0 0 0', '0 0 0');		
	setorigin (missile, self.origin);
};


//=============================================================================

void() spike_touch;
void() superspike_touch;


/*
===============
launch_spike

Used for both the player and the ogre
===============
*/
void(vector org, vector dir) launch_spike =
{
	newmis = spawn ();
	newmis.owner = self;
	newmis.movetype = MOVETYPE_FLYMISSILE;
	newmis.solid = SOLID_BBOX;

	newmis.angles = vectoangles(dir);
	
	newmis.touch = spike_touch;
	newmis.classname = "spike";
	newmis.think = SUB_Remove;
	newmis.nextthink = time + 6;
	setmodel (newmis, "progs/spike.mdl");
	setsize (newmis, VEC_ORIGIN, VEC_ORIGIN);		
	setorigin (newmis, org);

	newmis.velocity = dir * 1000;
};

void() W_FireSuperSpikes =
{
	local vector	dir;
	local entity	old;
	
	sound (self, CHAN_WEAPON, "weapons/spike2.wav", 1, ATTN_NORM);
	self.attack_finished = time + 0.2;
	self.currentammo = self.ammo_nails = self.ammo_nails - 2;
	dir = aim (self, 1000);
	launch_spike (self.origin + '0 0 16', dir);
	newmis.touch = superspike_touch;
	setmodel (newmis, "progs/s_spike.mdl");
	setsize (newmis, VEC_ORIGIN, VEC_ORIGIN);		
	self.punchangle_x = -2;
};

void(float ox) W_FireSpikes =
{
	local vector	dir;
	local entity	old;
	
	makevectors (self.v_angle);
	
	if (self.ammo_nails >= 2 && self.weapon == IT_SUPER_NAILGUN)
	{
		W_FireSuperSpikes ();
		return;
	}

	if (self.ammo_nails < 1)
	{
		self.weapon = W_BestWeapon ();
		W_SetCurrentAmmo ();
		return;
	}

	sound (self, CHAN_WEAPON, "weapons/rocket1i.wav", 1, ATTN_NORM);
	self.attack_finished = time + 0.2;
	self.currentammo = self.ammo_nails = self.ammo_nails - 1;
	dir = aim (self, 1000);
	launch_spike (self.origin + '0 0 16' + v_right*ox, dir);

	self.punchangle_x = -2;
};



.float hit_z;
void() spike_touch =
{
local float rand;
	if (other == self.owner)
		return;

	if (other.solid == SOLID_TRIGGER)
		return;	// trigger field, do nothing

	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return;
	}
	
// hit something that bleeds
	if (other.takedamage)
	{
		spawn_touchblood (9);
		T_Damage (other, self, self.owner, 9);
	}
	else
	{
		WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
		
		if (self.classname == "wizspike")
			WriteByte (MSG_BROADCAST, TE_WIZSPIKE);
		else if (self.classname == "knightspike")
			WriteByte (MSG_BROADCAST, TE_KNIGHTSPIKE);
		else
			WriteByte (MSG_BROADCAST, TE_SPIKE);
		WriteCoord (MSG_BROADCAST, self.origin_x);
		WriteCoord (MSG_BROADCAST, self.origin_y);
		WriteCoord (MSG_BROADCAST, self.origin_z);
	}

	remove(self);

};

void() superspike_touch =
{
local float rand;
	if (other == self.owner)
		return;

	if (other.solid == SOLID_TRIGGER)
		return;	// trigger field, do nothing

	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return;
	}
	
// hit something that bleeds
	if (other.takedamage)
	{
		spawn_touchblood (18);
		T_Damage (other, self, self.owner, 18);
	}
	else
	{
		WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
		WriteByte (MSG_BROADCAST, TE_SUPERSPIKE);
		WriteCoord (MSG_BROADCAST, self.origin_x);
		WriteCoord (MSG_BROADCAST, self.origin_y);
		WriteCoord (MSG_BROADCAST, self.origin_z);
	}

	remove(self);

};


/*
===============================================================================

PLAYER WEAPON USE

===============================================================================
*/

void() W_SetCurrentAmmo =
{
	if (self.health > 0)
		player_run ();		// get out of any weapon firing states

	self.items = self.items - ( self.items & (IT_SHELLS | IT_NAILS | IT_ROCKETS | IT_CELLS) );
	
	if (self.weapon == IT_AXE)
	{
		self.currentammo = self.stamina;
		if (self.has_ball)
		{
			if (self.special == 1)
				self.weaponmodel = "progs/v_dodgeball2.mdl";
                        else if (self.special == 2)
                                self.weaponmodel = "progs/v_hdodgeball.mdl";
			else if (self.special == 3)
				self.weaponmodel = "progs/v_dodgeball3.mdl";
			else if (self.special == 4)
				self.weaponmodel = "progs/v_dodgeball4.mdl";
			else if (self.special == 5)
				self.weaponmodel = "progs/v_roflcopterball.mdl";
                        else if (self.special == 6)
                                self.weaponmodel = "progs/v_spanner_ball.mdl";
			else
				self.weaponmodel = "progs/v_dodgeball.mdl";
		}
		else
			self.weaponmodel = "";
		self.weaponframe = 0;
	}
	else if (self.weapon == IT_SHOTGUN)
	{
		self.currentammo = self.ammo_shells;
		self.weaponmodel = "progs/v_shot.mdl";
		self.weaponframe = 0;
		self.items = self.items | IT_SHELLS;
	}
	else if (self.weapon == IT_SUPER_SHOTGUN)
	{
		self.currentammo = self.ammo_shells;
		self.weaponmodel = "progs/v_shot2.mdl";
		self.weaponframe = 0;
		self.items = self.items | IT_SHELLS;
	}
	else if (self.weapon == IT_NAILGUN)
	{
		self.currentammo = self.ammo_nails;
		self.weaponmodel = "progs/v_nail.mdl";
		self.weaponframe = 0;
		self.items = self.items | IT_NAILS;
	}
	else if (self.weapon == IT_SUPER_NAILGUN)
	{
		self.currentammo = self.ammo_nails;
		self.weaponmodel = "progs/v_nail2.mdl";
		self.weaponframe = 0;
		self.items = self.items | IT_NAILS;
	}
	else if (self.weapon == IT_GRENADE_LAUNCHER)
	{
		self.currentammo = self.ammo_rockets;
		self.weaponmodel = "progs/v_rock.mdl";
		self.weaponframe = 0;
		self.items = self.items | IT_ROCKETS;
	}
	else if (self.weapon == IT_ROCKET_LAUNCHER)
	{
		self.currentammo = self.ammo_rockets;
		self.weaponmodel = "progs/v_rock2.mdl";
		self.weaponframe = 0;
		self.items = self.items | IT_ROCKETS;
	}
	else if (self.weapon == IT_LIGHTNING)
	{
		self.currentammo = self.ammo_cells;
		self.weaponmodel = "progs/v_light.mdl";
		self.weaponframe = 0;
		self.items = self.items | IT_CELLS;
	}
	else
	{
		self.currentammo = 0;
		self.weaponmodel = "";
		self.weaponframe = 0;
	}
};

float() W_BestWeapon =
{
	local	float	it;
	
	it = self.items;

	if (self.waterlevel <= 1 && self.ammo_cells >= 1 && (it & IT_LIGHTNING) )
			return IT_LIGHTNING;
	if(self.ammo_nails >= 2 && (it & IT_SUPER_NAILGUN) )
		return IT_SUPER_NAILGUN;
	if(self.ammo_shells >= 2 && (it & IT_SUPER_SHOTGUN) )
		return IT_SUPER_SHOTGUN;
	if(self.ammo_nails >= 1 && (it & IT_NAILGUN) )
		return IT_NAILGUN;
	if(self.ammo_shells >= 1 && (it & IT_SHOTGUN) )
		return IT_SHOTGUN;
	return IT_AXE;
};

float() W_CheckNoAmmo =
{
	if (self.currentammo > 0)
		return TRUE;

	if (self.weapon == IT_AXE)
		return TRUE;
	
	self.weapon = W_BestWeapon ();

	W_SetCurrentAmmo ();
	
// drop the weapon down
	return FALSE;
};

/*
============
W_Attack

An attack impulse can be triggered now
============
*/
void()	player_axe1;
void()	player_axeb1;
void()	player_axec1;
void()	player_axed1;
void()	player_shot1;
void()	player_nail1;
void()	player_light1;
void()	player_rocket1;

void() W_Attack =
{
	if (ceasefire)
		return;
	if (!W_CheckNoAmmo ())
		return;

	makevectors	(self.v_angle);			// calculate forward angle for velocity
	self.show_hostile = time + 1;	// wake monsters up

	if (self.weapon == IT_AXE)
	{
		if (!self.has_ball)
			return;
		
		player_axe1 ();
		self.attack_finished = time + 0.4;
	}
	else if (self.weapon == IT_SHOTGUN)
	{
		player_shot1 ();
		W_FireShotgun ();
		self.attack_finished = time + 0.5;
	}
	else if (self.weapon == IT_SUPER_SHOTGUN)
	{
		player_shot1 ();
		W_FireSuperShotgun ();
		self.attack_finished = time + 0.7;
	}
	else if (self.weapon == IT_NAILGUN)
	{
		player_nail1 ();
	}
	else if (self.weapon == IT_SUPER_NAILGUN)
	{
		player_nail1 ();
	}
	else if (self.weapon == IT_GRENADE_LAUNCHER)
	{
		player_rocket1();
		W_FireGrenade();
		self.attack_finished = time + 0.6;
	}
	else if (self.weapon == IT_ROCKET_LAUNCHER)
	{
		player_rocket1();
		W_FireRocket();
		self.attack_finished = time + 0.8;
	}
	else if (self.weapon == IT_LIGHTNING)
	{
		player_light1();
		self.attack_finished = time + 0.1;
		sound (self, CHAN_AUTO, "weapons/lstart.wav", 1, ATTN_NORM);
	}
};

/*
============
W_ChangeWeapon

============
*/
void() W_ChangeWeapon =
{
	local	float	it, am, fl;
	
	it = self.items;
	am = 0;
	
	if (self.impulse == 1)
	{
		fl = IT_AXE;
	}
	else if (self.impulse == 2)
	{
		fl = IT_SHOTGUN;
		if (self.ammo_shells < 1)
			am = 1;
	}
	else if (self.impulse == 3)
	{
		fl = IT_SUPER_SHOTGUN;
		if (self.ammo_shells < 2)
			am = 1;
	}		
	else if (self.impulse == 4)
	{
		fl = IT_NAILGUN;
		if (self.ammo_nails < 1)
			am = 1;
	}
	else if (self.impulse == 5)
	{
		fl = IT_SUPER_NAILGUN;
		if (self.ammo_nails < 2)
			am = 1;
	}
	else if (self.impulse == 6)
	{
		fl = IT_GRENADE_LAUNCHER;
		if (self.ammo_rockets < 1)
			am = 1;
	}
	else if (self.impulse == 7)
	{
		fl = IT_ROCKET_LAUNCHER;
		if (self.ammo_rockets < 1)
			am = 1;
	}
	else if (self.impulse == 8)
	{
		fl = IT_LIGHTNING;
		if (self.ammo_cells < 1)
			am = 1;
	}

	self.impulse = 0;
	
	if (!(self.items & fl))
	{	// don't have the weapon or the ammo
		sprint (self, "no weapon.\n");
		return;
	}
	
	if (am)
	{	// don't have the ammo
		sprint (self, "not enough ammo.\n");
		return;
	}

//
// set weapon, set ammo
//
	self.weapon = fl;		
	W_SetCurrentAmmo ();
};

/*
============
CheatCommand
============
*/
void() CheatCommand =
{
	if (deathmatch || coop)
		return;

	self.ammo_rockets = 100;
	self.ammo_nails = 200;
	self.ammo_shells = 100;
	self.items = self.items | 
		IT_AXE |
		IT_SHOTGUN |
		IT_SUPER_SHOTGUN |
		IT_NAILGUN |
		IT_SUPER_NAILGUN |
		IT_GRENADE_LAUNCHER |
		IT_ROCKET_LAUNCHER |
		IT_KEY1 | IT_KEY2;

	self.ammo_cells = 200;
	self.items = self.items | IT_LIGHTNING;

	self.weapon = IT_ROCKET_LAUNCHER;
	self.impulse = 0;
	W_SetCurrentAmmo ();
};

/*
============
CycleWeaponCommand

Go to the next weapon with ammo
============
*/
void() CycleWeaponCommand =
{
	local	float	it, am;
	
	it = self.items;
	self.impulse = 0;
	
	while (1)
	{
		am = 0;

		if (self.weapon == IT_LIGHTNING)
		{
			self.weapon = IT_AXE;
		}
		else if (self.weapon == IT_AXE)
		{
			self.weapon = IT_SHOTGUN;
			if (self.ammo_shells < 1)
				am = 1;
		}
		else if (self.weapon == IT_SHOTGUN)
		{
			self.weapon = IT_SUPER_SHOTGUN;
			if (self.ammo_shells < 2)
				am = 1;
		}		
		else if (self.weapon == IT_SUPER_SHOTGUN)
		{
			self.weapon = IT_NAILGUN;
			if (self.ammo_nails < 1)
				am = 1;
		}
		else if (self.weapon == IT_NAILGUN)
		{
			self.weapon = IT_SUPER_NAILGUN;
			if (self.ammo_nails < 2)
				am = 1;
		}
		else if (self.weapon == IT_SUPER_NAILGUN)
		{
			self.weapon = IT_GRENADE_LAUNCHER;
			if (self.ammo_rockets < 1)
				am = 1;
		}
		else if (self.weapon == IT_GRENADE_LAUNCHER)
		{
			self.weapon = IT_ROCKET_LAUNCHER;
			if (self.ammo_rockets < 1)
				am = 1;
		}
		else if (self.weapon == IT_ROCKET_LAUNCHER)
		{
			self.weapon = IT_LIGHTNING;
			if (self.ammo_cells < 1)
				am = 1;
		}
	
		if ( (it & self.weapon) && am == 0)
		{
			W_SetCurrentAmmo ();
			return;
		}
	}

};

/*
============
CycleWeaponReverseCommand

Go to the prev weapon with ammo
============
*/
void() CycleWeaponReverseCommand =
{
	local	float	it, am;
	
	it = self.items;
	self.impulse = 0;

	while (1)
	{
		am = 0;

		if (self.weapon == IT_LIGHTNING)
		{
			self.weapon = IT_ROCKET_LAUNCHER;
			if (self.ammo_rockets < 1)
				am = 1;
		}
		else if (self.weapon == IT_ROCKET_LAUNCHER)
		{
			self.weapon = IT_GRENADE_LAUNCHER;
			if (self.ammo_rockets < 1)
				am = 1;
		}
		else if (self.weapon == IT_GRENADE_LAUNCHER)
		{
			self.weapon = IT_SUPER_NAILGUN;
			if (self.ammo_nails < 2)
				am = 1;
		}
		else if (self.weapon == IT_SUPER_NAILGUN)
		{
			self.weapon = IT_NAILGUN;
			if (self.ammo_nails < 1)
				am = 1;
		}
		else if (self.weapon == IT_NAILGUN)
		{
			self.weapon = IT_SUPER_SHOTGUN;
			if (self.ammo_shells < 2)
				am = 1;
		}		
		else if (self.weapon == IT_SUPER_SHOTGUN)
		{
			self.weapon = IT_SHOTGUN;
			if (self.ammo_shells < 1)
				am = 1;
		}
		else if (self.weapon == IT_SHOTGUN)
		{
			self.weapon = IT_AXE;
		}
		else if (self.weapon == IT_AXE)
		{
			self.weapon = IT_LIGHTNING;
			if (self.ammo_cells < 1)
				am = 1;
		}
	
		if ( (it & self.weapon) && am == 0)
		{
			W_SetCurrentAmmo ();
			return;
		}
	}

};

/*
============
ServerflagsCommand

Just for development
============
*/
void() ServerflagsCommand =
{
	serverflags = serverflags * 2 + 1;
};

void() QuadCheat =
{
	if (deathmatch || coop)
		return;
	self.super_time = 1;
	self.super_damage_finished = time + 30;
	self.items = self.items | IT_QUAD;
	dprint ("quad cheat\n");
};


void() remove_catch =
{
	self.owner.catching = 0;
	remove(self);
};

void() player_catch1;
void() Catch =
{
	local entity e;
	
	if (self.health <= 0)
		return;
	if (self.has_ball)
		return;
	
	player_catch1 ();
	self.catching = 1;
	e = spawn ();
	e.owner = self;
	e.nextthink = time + 0.2;
	e.think = remove_catch;
};


void() SprintThink =
{
	local entity o;
	local vector dir;
	
	self.nextthink = time;
	
	o = self.owner;
	if (o.health <= 0 || !o.sprinting || o.stamina < 1 || o.frozen > time)
	{
		o.sprinting = 0;
		remove(self);
		return;
	}
	
	if (o.flags & FL_ONGROUND)
	{
		if (self.frags < time)
		{
			o.currentammo = o.stamina = o.stamina - 1;
			self.frags = time + 0.1;
		}
		
		dir = o.v_angle;
		dir_x = dir_z = 0;
		makevectors (dir);
		o.velocity = o.velocity + v_forward * 45;
		if (vlen(o.velocity) > 450)
			o.velocity = normalize(o.velocity) * 450;
	}
};

void() Sprint =
{
	local entity e;
	sound (other, CHAN_BODY, "dodgeball/sprinting_db.wav", 1, ATTN_NORM);
	
	if (self.stamina < 1)
	{
		sprint (self, "Not enough stamina!\n");
		return;
	}
	
	if (!self.sprinting)
	{
		sprint (self, "Sprint ON\n");
		self.sprinting = 1;
		e = spawn ();
		e.owner = self;
		e.nextthink = time;
		e.think = SprintThink;
	}
	else
	{
		sprint (self, "Sprint OFF\n");
		self.sprinting = 0;
	}
};

void() BeginGame =
{
	if (game_started)
		return;
	if (countdown)
		return;
	
	bprint ("Round will start in 5 seconds...\n");
	countdown = 1;
	countdown_time = time + 5.5;
};

void() player_deflect1;
void() Deflect =
{
        
	if (ceasefire)
		return;
	if (!self.has_ball)
		return;
	if (self.special)
		return;	// can only deflect if holding a normal ball

	sound (self, CHAN_WEAPON, "dodgeball/deflect_woosh_db.wav", 1, ATTN_NORM);
	self.weaponmodel = "progs/v_deflect.mdl";
	player_deflect1 ();
	self.attack_finished = time + 0.3;
};

/*
============
ImpulseCommands

============
*/
void() ImpulseCommands =
{
	if (self.impulse >= 1 && self.impulse <= 8)
		W_ChangeWeapon ();

	if (self.impulse == 9)
		CheatCommand ();
	if (self.impulse == 10)
		CycleWeaponCommand ();
	if (self.impulse == 11)
		ServerflagsCommand ();
	if (self.impulse == 12)
		CycleWeaponReverseCommand ();
	
	if (self.impulse == 15)
		Catch ();
	if (self.impulse == 16)
		PowerThrow ();
	if (self.impulse == 17)
		Sprint ();
	if (self.impulse == 18)
		BeginGame ();
	if (self.impulse == 19)
		Deflect ();
	
	if (self.impulse == 100)
		SpawnBot (1);
	if (self.impulse == 101)
		SpawnBot (2);
	if (self.impulse == 102)
		DropBot (1);
	if (self.impulse == 103)
		DropBot (2);

	if (self.impulse == 255)
		QuadCheat ();
		
	self.impulse = 0;
};

/*
============
W_WeaponFrame

Called every frame so impulse events can be handled as well as possible
============
*/
void() W_WeaponFrame =
{
	if (time < self.attack_finished)
		return;

	if (self.impulse)
		ImpulseCommands ();
	
// check for attack
	if (self.button0)
	{
		SuperDamageSound ();
		W_Attack ();
	}
};

/*
========
SuperDamageSound

Plays sound if needed
========
*/
void() SuperDamageSound =
{
	if (self.super_damage_finished > time)
	{
		if (self.super_sound < time)
		{
			self.super_sound = time + 1;
			sound (self, CHAN_BODY, "items/damage3.wav", 1, ATTN_NORM);
		}
	}
	return;
};


