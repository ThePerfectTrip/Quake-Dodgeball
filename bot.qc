/*
bot.qc
*/

float() CheckForGap =
{
	local vector dir, src;
	
	dir = vectoangles(self.velocity);
	dir_x = 0;
	makevectors (dir);
	
	src = self.origin + v_forward*60;
	traceline (src, src - '0 0 10000', TRUE, self);
	if (pointcontents(trace_endpos + '0 0 1') <= CONTENT_SLIME)
		return TRUE;
	
	return FALSE;
};

void() BotStrafe =
{
	if (self.fb_time < time)
	{
		if (self.move_mode == 0)
			self.move_mode = 1;
		else
			self.move_mode = 0;
		self.fb_time = time + 1 + random();
	}
	
	if (self.move_mode == 0)
	{
		if (self.strafe_time < time)
		{
			if (self.movement == '0 320 0')
				self.movement = '0 -320 0';
			else
				self.movement = '0 320 0';
			self.strafe_time = time + 0.5 + 0.6*random();
		}
	}
	else
	{
		if (self.strafe_time < time)
		{
			if (self.movement == '320 0 0')
				self.movement = '-320 0 0';
			else
				self.movement = '320 0 0';
			self.strafe_time = time + 0.5 + 0.6*random();
		}
	}
	
	if (CheckForGap())
	{
		if (self.move_mode == 0)
		{
			if (self.movement == '0 320 0')
				self.movement = '0 -320 0';
			else
				self.movement = '0 320 0';
		}
		else
		{
			if (self.movement == '320 0 0')
				self.movement = '-320 0 0';
			else
				self.movement = '320 0 0';
		}
	}
};


void() BotFindTarget =
{
	local entity targ, targs;
	local float numtargs;
	
	targ = findradius(self.origin, 10000);
	while (targ)
	{
		if (targ != self)
		if (targ.health > 0)
		if (targ.team_no != self.team_no)
		if (!targ.died)
		if (visible(targ))
		{
			numtargs = numtargs + 1;
			targ.linked = targs;
			targs = targ;
		}
		targ = targ.chain;
	}
	
	numtargs = numtargs - 1;
	numtargs = rint(random()*numtargs);
	
	targ = targs;
	while (numtargs > 0)
	{
		targ = targ.linked;
		numtargs = numtargs - 1;
	}
	
	self.enemy = targ;
};

float(entity ent) type_check =
{
	if (ent.special && ent.solid == SOLID_TRIGGER)
		return TRUE;
	if (!ent.special)
		return TRUE;
	
	return FALSE;
};

void() BotFindBall =
{
	local entity targ;
	local float dist, ofs;
	
	targ = find(world, classname, "dodgeball");
	while (targ)
	{
		if (visible(targ))
		if (targ.search_time < time)
		if (type_check(targ))
		{
			if (vlen(targ.velocity) > 0)
			{
				dist = 100;
				ofs = 9999;
			}
			else
			{
				dist = 1000;
				ofs = 22;
			}
			
			if (vlen(targ.origin - self.origin) < dist && targ.origin_z < self.origin_z + ofs)
			{
				self.goalentity = targ;
				self.search_time = time + 2;
			}
		}
		targ = find(targ, classname, "dodgeball");
	}
};

void(entity ent) bot_face =
{
	local vector dir, vel;
	
	if (self.has_ball)
	{
		vel = ent.velocity;
		if (ent.velocity_z > 0)
			vel_z = 0;
		dir = ent.origin + vel * (random()*0.4);
	}
	else
		dir = ent.origin;
	dir = normalize(dir - self.origin);
	
	self.v_angle = vectoangles(dir);
	self.v_angle_x = self.v_angle_x * -1;
	while (self.v_angle_x < -180)
		self.v_angle_x = self.v_angle_x + 360;
	while (self.v_angle_x > 180)
		self.v_angle_x = self.v_angle_x - 360;
};

void() BotAI =
{
	if (!self.ingame)
	{
		self.impulse = self.teampulse;
		return;
	}
	
	if (self.health < 1)
	{
		self.button0 = rint(random()*2);
		self.button1 = 0;
		self.button2 = 0;
		return;
	}
	
	if (self.frozen > time)
	{
		self.movement = '0 0 0';
		return;	// hack!
	}
	
	if (!self.enemy)
	{
		self.button0 = 0;
		self.v_angle_x = 0;
		
		if (self.sprinting)
			self.impulse = 17;
		
		if (self.died)
		{
			self.movement = '0 0 0';
			return;
		}
		
		if (self.has_ball)
			BotFindTarget ();
		else
			BotFindBall ();
		
		if (self.search_time < time)
		{
			if (self.goalentity != world && !self.goalentity.special)
				self.goalentity.search_time = time + 7;
			self.goalentity = world;
		}
		
		if (self.goalentity)
		{
			if (CheckForGap())
			{
				self.goalentity.search_time = time + 5;
				self.goalentity = world;
				return;
			}
			
			bot_face (self.goalentity);
			self.movement = '320 0 0';
			if (random() <= 0.02)
				self.impulse = 15;
		}
		else
			BotStrafe ();
	}
	
	if (self.enemy)
	{
		if (self.enemy.health <= 0 || !visible(self.enemy) || !self.has_ball)
		{
			self.enemy = world;
			return;
		}
		
		if (self.stamina > 5 && !self.sprinting)
			self.impulse = 17;
		
		bot_face (self.enemy);
		BotStrafe ();
		if (random() < 0.5)
		{
			self.button0 = 0;
			self.impulse = 16;
		}
		else
			self.button0 = 1;
	}
};

void() BotFrame =
{
	local entity bot, uself;
	
	bot = find(world, classname, "player");
	while (bot)
	{
		if (clienttype(bot) == CLIENTTYPE_BOT)
		{
			uself = self;
			self = bot;
			PlayerPhysics ();
			BotAI ();
			self = uself;
		}
		
		bot = find(bot, classname, "player");
	}
};

string()      Names =
{
    local float ran;
    ran = random() * 64;
     if(ran < 1)  return "�onke�";  else if(ran < 2)  return "�urcielag�";
else if(ran < 3)  return "�G������O�";  else if(ran < 4)  return "������";
else if(ran < 5)  return "��A�E�I�";  else if(ran < 6)  return "a�d�c�eĔ�����";
else if(ran < 7)  return "�C�mitiere";  else if(ran < 8)  return "Crash��verride";
else if(ran < 9)  return "���Croix";  else if(ran < 10) return "�run�en������";
else if(ran < 11) return "Cornelius���"; else if(ran < 12) return "di��y";
else if(ran < 13) return "�Hi�Man�"; else if(ran < 14) return "������";
else if(ran < 15) return "�"; else if(ran < 16) return "dude";
else if(ran < 17) return "��Z�����idane��"; else if(ran < 18) return "f�Aǜg�d";
else if(ran < 19) return "��nd�tt�"; else if(ran < 20) return "������̜f��lU�e";
else if(ran < 21) return "The�Project"; else if(ran < 22) return "girlie";
else if(ran < 23) return "Soul�������"; else if(ran < 24) return "������boy";
else if(ran < 25) return "D�m�tr�"; else if(ran < 26) return "������";
else if(ran < 27) return "��u�o��atu���"; else if(ran < 28) return "������ǜ�������";
else if(ran < 29) return "H�k������uro"; else if(ran < 30) return "���tile";
else if(ran < 31) return "Wa���i"; else if(ran < 32) return "S�������";
else if(ran < 33) return "�Rollerball�"; else if(ran < 34) return "�hres�";
else if(ran < 35) return "So��y"; else if(ran < 36) return "�����";
else if(ran < 37) return "Cut��hroat"; else if(ran < 38) return "�a�";
else if(ran < 39) return "�azor"; else if(ran < 40) return "orion";
else if(ran < 41) return "Nasrudin"; else if(ran < 42) return "����";
else if(ran < 43) return "��irate�"; else if(ran < 44) return "die ߡ�";
else if(ran < 45) return "���aribbea"; else if(ran < 46) return "� u �";
else if(ran < 47) return "��armack ȓm��lƄ"; else if(ran < 48) return "� u � f������";
else if(ran < 49) return "� Failure"; else if(ran < 50) return "vege���s";
else if(ran < 51) return "���Ԑdaftpunk"; else if(ran < 52) return "�iker";
else if(ran < 53) return "����"; else if(ran < 54) return "�autico";
else if(ran < 55) return "Bill Gates���"; else if(ran < 56) return "�fudencio�";
else if(ran < 57) return "Q�Q"; else if(ran < 58) return "�����������";
else if(ran < 59) return "furunco"; else if(ran < 60) return "����� ^^";
else if(ran < 61) return "����-���������"; else if(ran < 62) return "�e�b�";
else if(ran < 63) return "cruise� �����"; else return "�YYY��ӓL��r��";
};

float(string name) UsedName =
{
	local entity client;
	local float used;
	
	client = find(world, classname, "player");
	while (client)
	{
		if (client != self)
		if (client.netname == self.netname)
			used = 1;
		client = find(client, classname, "player");
	}
	
	return used;
};

void() BotSetName =
{
	do
	{
		self.netname = Names ();
	} while (UsedName(self.netname));
};

void(float tno) SpawnBot =
{
	local entity oldself;
	
	if (!has_bots)
		return;
	
	oldself = self;
	self = spawnclient();
	if (!self)
	{
		bprint ("Can not add bot, server full.\n");
		self = oldself;
		return;
	}
	BotSetName ();
	self.teampulse = tno;
	if (tno == 1)
		self.clientcolors = 6*16 + 6;
	else if (tno == 2)
		self.clientcolors = 11*16 + 11;
	ClientConnect();
	PutClientInServer();
	self = oldself;
};

void(float tno) DropBot =
{
	local entity bot;
	
	if (!has_bots)
		return;
	
	bot = find(world, classname, "player");
	while (bot)
	{
		if (clienttype(bot) == CLIENTTYPE_BOT && bot.team_no == tno)
		{
			dropclient (bot);
			bot = world;
		}
		else
			bot = find(bot, classname, "player");
	}
};