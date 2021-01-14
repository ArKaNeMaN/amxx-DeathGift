#include <amxmodx>
#include <cstrike>
#include <hamsandwich>
#include <fakemeta>
#include <engine>
#include <DeathGift>

#pragma semicolon 1

// #define DEBUG

new const PLAYER_CLASSNAME[] = "player";
new const LANG_STR[] = "%L";
#define Lang(%1) fmt(LANG_STR,LANG_SERVER,%1)
#define PDATA_SAFE 2
#define ENT_VALID(%1) (pev_valid(%1)==PDATA_SAFE)

new const Float:GIFT_SIZE[2][3] = {
	{-10.0, -10.0, -30.0},
	{10.0, 10.0, 30.0},
};

new const GIFT_CLASSNAME[] = "DeathGift";
new const CHAT_PREFIX[] = "DeathGift";
new const MODEL_PATH[] = "models/DeathGift/gift.mdl";
new const TAKE_SOUND[] = "DeathGift/take.wav";
#define FLY_SPEED 5.0
#define ROTATE_SPEED 5.0
#define THINK_DELAY 1.0

enum E_Cvars{
	Float:Cvar_DropRarity,
	Cvar_LifeTime,
	Cvar_Money[2],
	Float:Cvar_SoundVolume,
}
new Cvars[E_Cvars];
#define Cvar(%1) Cvars[Cvar_%1]

enum E_Fwds{
	Fwd_GiftTouch_Pre,
	Fwd_GiftTouch_Post,

	Fwd_GiftCreate_Pre,
	Fwd_GiftCreate_Post,
}
new Fwds[E_Fwds];
#define FwdExecP(%1,%2,[%3]) ExecuteForward(Fwds[Fwd_%1],%2,%3)
#define FwdRegP(%1,%2,[%3]) Fwds[Fwd_%1]=CreateMultiForward(%2,ET_STOP2,%3)
// #define FwdExec(%1,%2) ExecuteForward(Fwds[Fwd_%1],%2)
// #define FwdReg(%1,%2) Fwds[Fwd_%1]=CreateMultiForward(%2,ET_STOP2)

new const PLUG_VER[] = "2.0.0";
new const PLUG_NAME[] = "Death Gift";

public plugin_natives(){
	register_library("DeathGift");

	register_native("DG_SendGiftMsg", "@Native_SendGiftMsg");
}

public plugin_precache(){
	register_plugin(PLUG_NAME, PLUG_VER, "ArKaNeMaN");
	
	if(file_exists(MODEL_PATH))
		precache_model(MODEL_PATH);
	else set_fail_state("[Model file not found (%s)]", MODEL_PATH);
	
	if(file_exists(fmt("sound/%s", TAKE_SOUND)))
		precache_sound(TAKE_SOUND);
	else set_fail_state("[Take sound file not found (%s)]", TAKE_SOUND);
}

public plugin_init(){
	register_dictionary("DeathGift.ini");

	InitCvars();
	InitFwds();

	RegisterHam(Ham_Killed, PLAYER_CLASSNAME, "@Hook_PlayerKilled", false, true);

	register_think(GIFT_CLASSNAME, "@Hook_GiftThink");
	register_touch(GIFT_CLASSNAME, PLAYER_CLASSNAME, "@Hook_GiftTouch");

	server_print("[%s v%s] loaded.", PLUG_NAME, PLUG_VER);
}

InitCvars(){
	bind_pcvar_float(create_cvar(
        "DG_DropRarity", "0.1",
        FCVAR_NONE, Lang("CVAR_DROP_RARITY"),
        true, 0.000001,  true, 1.0
    ), Cvar(DropRarity));

	bind_pcvar_num(create_cvar(
        "DG_LifeTime", "15",
        FCVAR_NONE, Lang("CVAR_LIFE_TIME"),
        true, 0.0
    ), Cvar(LifeTime));

	bind_pcvar_num(create_cvar(
        "DG_Money_Min", "500",
        FCVAR_NONE, Lang("CVAR_MONEY_MIN")
    ), Cvar(Money)[0]);

	bind_pcvar_num(create_cvar(
        "DG_Money_Max", "5000",
        FCVAR_NONE, Lang("CVAR_MONEY_MAX")
    ), Cvar(Money)[1]);

	bind_pcvar_float(create_cvar(
        "DG_SoundVolume", "0.8",
        FCVAR_NONE, Lang("CVAR_SOUND_VOLUME"),
        true, 0.0,  true, 1.0
    ), Cvar(SoundVolume));
	
	AutoExecConfig(true, "Main", "DeathGift");
}

InitFwds(){
	FwdRegP(GiftTouch_Pre, "DG_OnGiftTouch_Pre", [FP_CELL, FP_CELL]);
	FwdRegP(GiftTouch_Post, "DG_OnGiftTouch_Post", [FP_CELL, FP_CELL]);
	FwdRegP(GiftCreate_Pre, "DG_OnGiftCreate_Pre", [FP_CELL]);
	FwdRegP(GiftCreate_Post, "DG_OnGiftCreate_Post", [FP_CELL]);
}

@Hook_GiftTouch(const GiftId, const UserId){
	if(!is_user_alive(UserId))
		return;

	emit_sound(GiftId, CHAN_VOICE, TAKE_SOUND, Cvar(SoundVolume), ATTN_NORM, 0, PITCH_NORM);

	#if defined DEBUG
	log_amx("[DEBUG] [giftTouch] [%d]", PLUG_NAME, PLUG_VER, UserId);
	#endif

	new ret = DG_CONTINUE;
	FwdExecP(GiftTouch_Pre, ret, [UserId, GiftId]);

	if(ret == DG_STOP){
		GiftDelete(GiftId);
		return;
	}

	#if defined DEBUG
	log_amx("[DEBUG] [giftTouch] [%d] [Fwd]", PLUG_NAME, PLUG_VER, UserId);
	#endif

	new newMoney = RndRange(Cvar(Money));

	cs_set_user_money(UserId, cs_get_user_money(UserId)+newMoney);
	DG_SendGiftMsg(UserId, fmt("%d$", newMoney));

	FwdExecP(GiftTouch_Post, ret, [UserId, GiftId]);

	GiftDelete(GiftId);
}

@Hook_PlayerKilled(victim, attacker, corpse){
	#if defined DEBUG
	log_amx("[DEBUG] [pDeath] [%d]", PLUG_NAME, PLUG_VER, victim);
	#endif

	if(RndDrop()){
		#if defined DEBUG
		log_amx("[DEBUG] [pDeath] [%d] [Drop]", PLUG_NAME, PLUG_VER, victim);
		#endif

		new ret = DG_CONTINUE;
		FwdExecP(GiftCreate_Pre, ret, [victim]);

		if(ret == DG_STOP)
			return;

		static Float:origin[3];
		pev(victim, pev_origin, origin);
		origin[2] -= 25.0;

		GiftCreate(origin);
	}
	#if defined DEBUG
	else log_amx("[DEBUG] [pDeath] [%d] [Not Drop]", PLUG_NAME, PLUG_VER, victim);
	#endif
}

@Task_GiftDelete(const TaskId){GiftDelete(TaskId);}

GiftDelete(GiftId){
	if(!ENT_VALID(GiftId))
		return;

	#if defined DEBUG
	log_amx("[DEBUG] [giftDelete]", PLUG_NAME, PLUG_VER);
	#endif

	if(task_exists(GiftId))
		remove_task(GiftId);

	remove_entity(GiftId);
}

GiftCreate(Float:origin[3]){
	#if defined DEBUG
	log_amx("[DEBUG] [giftCreate]", PLUG_NAME, PLUG_VER);
	#endif

	#if defined DEBUG
	log_amx("[DEBUG] [giftCreate] [Fwd]", PLUG_NAME, PLUG_VER);
	#endif

	static a;
	if(!a)
		a = engfunc(EngFunc_AllocString, "info_target");
	static GiftId; GiftId = engfunc(EngFunc_CreateNamedEntity, a);

	if(!pev_valid(GiftId))
		return;
		
	#if defined DEBUG
	log_amx("[DEBUG] [giftCreate] [Fwd] [Create] [%d]", PLUG_NAME, PLUG_VER, GiftId);
	#endif

	set_pev(GiftId, pev_classname, GIFT_CLASSNAME);
	engfunc(EngFunc_SetModel, GiftId, MODEL_PATH);
	set_pev(GiftId, pev_origin, origin);

	ExecuteHam(Ham_Spawn, GiftId);

	set_pev(GiftId, pev_nextthink, get_gametime()+THINK_DELAY);

	set_pev(GiftId, pev_movetype, MOVETYPE_NOCLIP);
	set_pev(GiftId, pev_solid, SOLID_TRIGGER);
	SetEntSize(GiftId, GIFT_SIZE[0], GIFT_SIZE[1]);
	
	static Float:vecAvelocity[3];				//
	vecAvelocity[1] = ROTATE_SPEED * 10.0;		// Установка скорости вращения
	set_pev(GiftId, pev_avelocity, vecAvelocity);	//

	//static Float:vecVelocity[3];
	//vecVelocity[2] = FLY_SPEED;
	set_pev(GiftId, pev_velocity, {0.0, 0.0, FLY_SPEED});

	set_pev(GiftId, pev_maxspeed, FLY_SPEED);


	if(Cvar(LifeTime))
		set_task(float(Cvar(LifeTime)), "@Task_GiftDelete", GiftId);
	
	new ret;
	FwdExecP(GiftCreate_Post, ret, [GiftId]);
	
	#if defined DEBUG
	log_amx("[DEBUG] [giftCreate] [Fwd] [Created] [%d]", PLUG_NAME, PLUG_VER, GiftId);
	#endif
}

@Hook_GiftThink(const GiftId){
	if(!ENT_VALID(GiftId))
		return;
	
	set_pev(GiftId, pev_nextthink, get_gametime()+THINK_DELAY);
	
	static Float:vecVelocity[3], Float:fFlyUp;
	pev(GiftId, pev_maxspeed, fFlyUp);
	vecVelocity[2] = fFlyUp;

	set_pev(GiftId, pev_velocity, vecVelocity);
	set_pev(GiftId, pev_maxspeed, -fFlyUp);
	
	#if defined DEBUG
	log_amx("[DEBUG] [giftThink] [%d]", PLUG_NAME, PLUG_VER, GiftId);
	#endif
	
	return;
}

@Native_SendGiftMsg(pluginId, params){
	enum {Arg_UserId = 1, Arg_GiftName}

	new UserId; UserId = get_param(Arg_UserId);
	new GiftName[64]; get_string(Arg_GiftName, GiftName, charsmax(GiftName));

	if(equal(GiftName, ""))
		client_print_color(UserId, print_team_default, "^4[^3%s^4] ^1%L", CHAT_PREFIX, LANG_PLAYER, "GIFT_TAKE_EMPTY");
	else client_print_color(UserId, print_team_default, "^4[^3%s^4] ^1%L", CHAT_PREFIX, LANG_PLAYER, "GIFT_TAKE", GiftName);
}

SetEntSize(const Ent, const Float:Mins[3], const Float:Maxs[3]){
	set_pev(Ent, pev_mins, Mins);
	set_pev(Ent, pev_maxs, Maxs);
	new Float:Size[3];
	Size[0] = Mins[0] + Maxs[0];
	Size[1] = Mins[1] + Maxs[1];
	Size[2] = Mins[2] + Maxs[2];
	set_pev(Ent, pev_size, Size);
}

RndRange(const Range[]){
	return random_num(Range[0], Range[1]);
}

bool:RndDrop(){
	new rnd = random_num(1, floatround(1.0/Cvar(DropRarity)));

	#if defined DEBUG
	log_amx("[DEBUG] [RndDrop] [1, %d] [%d]", PLUG_NAME, PLUG_VER, floatround(1.0/Cvar(DropRarity)), rnd);
	#endif

	return (rnd == 1);
}