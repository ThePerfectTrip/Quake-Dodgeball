/*
sentry.qc
*/

void() SentryFindTarget;
void() lvl2_sentry_stand;
void() lvl3_sentry_stand;
void() lvl1_sentry_stand = [0, lvl1_sentry_stand] {SentryFindTarget();
if (self.frags >= 2)
{
	self.level = 1;
	self.health = 180;
	lvl2_sentry_stand ();
}
};
void() lvl2_sentry_stand = [2, lvl2_sentry_stand] {SentryFindTarget();
if (self.frags >= 4)
{
	self.level = 2;
	self.health = 216;
	lvl3_sentry_stand ();
}
};
void() lvl3_sentry_stand = [5, lvl3_sentry_stand] {SentryFindTarget();};

void() lvl1_sentry_atk1;
void() lvl2_sentry_atk1;
void() lvl3_sentry_atk1;
void() SentryFindTarget =
{
	local entity head, found;
	local float best, dist;
	
	if (self.builder.has_disconnected)
	{
		spawn_tfog (self.origin + '0 0 32');
		remove(self);
		return;
	}
	
	best = 1000;
	head = findradius(self.origin, best);
	while (head)
	{
		if (head.health > 0)
		if (!head.died)
		if (!countdown)
		if (head.team_no != self.team_no)
		if (visible(head))
		{
			dist = vlen(head.origin - self.origin);
			if (dist < best)
			{
				best = dist;
				found = head;
			}
		}
		head = head.chain;
	}
	
	if (found)
	{
		self.enemy = found;
		self.nextthink = time + 0.1;
		if (self.level == 0)
			self.think = lvl1_sentry_atk1;
		else if (self.level == 1)
			self.think = lvl2_sentry_atk1;
		else if (self.level == 2)
			self.think = lvl3_sentry_atk1;
	}
};


void() sentry_ball_touch =
{
	local float damage, chance;
	local entity exp;
	
	if (!self.cnt)
	{
		damage = 20 + 30*random();	// 20-50
		chance = 0.05;
	}
	else
	{
		damage = 80 + 20*random();	// 80-100
		chance = 0.15;
	}
	
	if (other.takedamage == DAMAGE_AIM)
	{
		if (other.team_no != self.owner.team_no)
		{
			if (other.deflecting && other.health > 0)
			{
				if (self.cnt)
					sound (self, CHAN_WEAPON, "dodgeball/hit2_db.wav", 1, ATTN_NORM);
				else
					sound (self, CHAN_WEAPON, "dodgeball/hit1_db.wav", 1, ATTN_NORM);
				self.touch = SUB_Null;
				self.movetype = MOVETYPE_BOUNCE;
				self.nextthink = time + 1;
				self.think = SUB_Remove;
				return;
			}
			
			if (random() <= chance)
			{	// critical hit!
				damage = damage * 3;
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
			
			if (self.cnt)
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
					other.deathtype = "headshot";
					damage = damage * 2;
				}
			}
			else
				other.deathtype = "normal";
			
			SpawnBlood (self.origin, self.velocity*0.2, damage);
			T_Damage (other, self, self.owner, damage);
			
			if (self.cnt)
				sound (self, CHAN_WEAPON, "dodgeball/hit2_db.wav", 1, ATTN_NORM);
			else
				sound (self, CHAN_WEAPON, "dodgeball/hit1_db.wav", 1, ATTN_NORM);	
			remove(self);
			return;
		}
	}
	
	sound (self, CHAN_WEAPON, "dodgeball/bounce_db.wav", 1, ATTN_NORM);
	remove(self);
};

float(float ox, vector up, float power) SentryFire =
{
	local entity ball;
	local float vel;
	
	if (self.ideal_yaw - anglemod(self.angles_y) < -25 || self.ideal_yaw - anglemod(self.angles_y) > 25)
		return FALSE;
	
	self.effects = self.effects | EF_MUZZLEFLASH;
	
	sound (self, CHAN_WEAPON, "weapons/spike2.wav", 1, ATTN_NORM);
	
	ball = spawn ();
	ball.owner = self;
	ball.movetype = MOVETYPE_FLYMISSILE;
	ball.solid = SOLID_BBOX;
	ball.classname = "dodgeball";
	
	if (power)
		vel = 1300;
	else
		vel = 850;
	
	makevectors (self.angles);
	ball.velocity = normalize(self.enemy.origin - (self.origin + v_forward*32 + v_right*ox + up)) * vel;
	ball.avelocity = '300 300 300';
	ball.angles = vectoangles(ball.velocity);
	
	ball.cnt = power;
	ball.touch = sentry_ball_touch;
	
	ball.nextthink = time + 5;
	ball.think = SUB_Remove;
	
	if (power)
		setmodel (ball, "progs/ball2_db.mdl");
	else
		setmodel (ball, "progs/ball_db.mdl");
	setsize (ball, '-5 -5 -5', '5 5 5');
	setorigin (ball, self.origin + v_forward*32 + v_right*ox + up);
	
	return TRUE;
};

void() sentry_face =
{
	self.ideal_yaw = vectoyaw(self.enemy.origin - self.origin);
	ChangeYaw ();
};

void() lvl1_sentry_atk2;
void() lvl1_sentry_atk1 = [1, lvl1_sentry_atk2]
{
	self.nextthink = time + 0.25;
	sentry_face ();
	if (self.enemy.health <= 0 || !visible(self.enemy) || self.enemy.died || countdown)
		lvl1_sentry_stand ();
	else if (!SentryFire(0, '0 0 61', 0))
		lvl1_sentry_atk2 ();
};
void() lvl1_sentry_atk2 = [0, lvl1_sentry_atk1] {self.nextthink = time + 0.25;sentry_face();};

void() lvl2_sentry_atk3;
void() lvl2_sentry_atk1 = [3, lvl2_sentry_atk2]
{
	self.nextthink = time + 0.25;
	sentry_face ();
	if (self.enemy.health <= 0 || !visible(self.enemy) || self.enemy.died || countdown)
		lvl2_sentry_stand ();
	else if (!SentryFire(0, '0 0 61', 0))
		lvl2_sentry_atk3 ();
};
void() lvl2_sentry_atk2 = [4, lvl2_sentry_atk1]
{
	self.nextthink = time + 0.25;
	sentry_face ();
	if (self.enemy.health <= 0 || !visible(self.enemy) || self.enemy.died || countdown)
		lvl2_sentry_stand ();
	else if (!SentryFire(11, '0 0 46', 0))
		lvl2_sentry_atk3 ();
};
void() lvl2_sentry_atk3 = [2, lvl2_sentry_atk1] {self.nextthink = time + 0.25;sentry_face();};

void() lvl3_sentry_atk4;
void() lvl3_sentry_atk1 = [6, lvl3_sentry_atk2]
{
	local float pow;
	
	self.nextthink = time + 0.16;
	if (self.frags >= 6)
		pow = 1;
	
	sentry_face ();
	if (self.enemy.health <= 0 || !visible(self.enemy) || self.enemy.died || countdown)
		lvl3_sentry_stand ();
	else if (!SentryFire(0, '0 0 61', pow))
		lvl3_sentry_atk4 ();
};
void() lvl3_sentry_atk2 = [7, lvl3_sentry_atk3]
{
	local float pow;
	
	self.nextthink = time + 0.16;
	if (self.frags >= 6)
		pow = 1;
	
	sentry_face ();
	if (self.enemy.health <= 0 || !visible(self.enemy) || self.enemy.died || countdown)
		lvl3_sentry_stand ();
	else if (!SentryFire(11, '0 0 46', pow))
		lvl3_sentry_atk4 ();
};
void() lvl3_sentry_atk3 = [8, lvl3_sentry_atk1]
{
	local float pow;
	
	self.nextthink = time + 0.16;
	if (self.frags >= 6)
		pow = 1;
	
	sentry_face ();
	if (self.enemy.health <= 0 || !visible(self.enemy) || self.enemy.died || countdown)
		lvl3_sentry_stand ();
	else if (!SentryFire(-11, '0 0 46', pow))
		lvl3_sentry_atk4 ();
};
void() lvl3_sentry_atk4 = [5, lvl3_sentry_atk1] {self.nextthink = time + 0.16;sentry_face();};