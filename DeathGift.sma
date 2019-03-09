#include <amxmodx>
#include <cstrike>
#include <hamsandwich>
#include <fakemeta>
#include <engine>
#include <awDeathGift>

#if !defined client_print_color
    #include <colorchat>
#endif

#define PDATA_SAFE 2

new const MODEL_PATH[] = "models/awDeathGift/gift.mdl";
new const TAKE_SOUND[] = "awDeathGift/take.wav";
#define SOUND_VOL 0.8
new const CHAT_PREFIX[] = "DeathGift";
#define FLY_SPEED 5.0
#define ROTATE_SPEED 5.0
#define THINK_DELAY 1.0

enum fwds{
	fTouchPre,
	fTouchPost,
	fCreatePre,
	fCreatePost
}

enum cvars{
	cDropRarity,
	cLifeTime,
	cMoneyMin,
	cMoneyMax
}

enum minMax{
	mMin,
	mMax
}

new const Float:fMaxs[3] = {10.0, 10.0, 30.0};
new const Float:fMins[3] = {-1.0, -10.0, -30.0};

new pFwds[fwds];

new Float:dropRarity;
new giftLifeTime;
new giftMoney[minMax];

new const PLUG_VER[] = "1.2.1";
new const PLUG_NAME[] = "DeathGift";

public plugin_init(){
	register_dictionary("awDeathGift.txt");
	cfgExec();
	RegisterHam(Ham_Killed, "player", "pDeath", false);
	register_think("gift", "giftThink");
	register_touch("gift", "player", "giftTouch");
	pFwds[fTouchPre] = CreateMultiForward("awDgFwdTouchPre", ET_CONTINUE, FP_CELL, FP_CELL);
	pFwds[fTouchPost] = CreateMultiForward("awDgFwdTouchPost", ET_CONTINUE, FP_CELL, FP_CELL);
	pFwds[fCreatePre] = CreateMultiForward("awDgFwdCreatePre", ET_CONTINUE);
	pFwds[fCreatePost] = CreateMultiForward("awDgFwdCreatePost", ET_CONTINUE, FP_CELL);
	server_print("[%s v%s] loaded.", PLUG_NAME, PLUG_VER);
}

cfgExec(){
	new pCvars[cvars];
	pCvars[cDropRarity] = create_cvar("awDgDropRarity", "0.1", FCVAR_NONE, "Редкость выпадения подарка");
	pCvars[cLifeTime] = create_cvar("awDgLifeTime", "15", FCVAR_NONE, "Время жизни подарка (0 - бесконечно)");
	pCvars[cMoneyMin] = create_cvar("awDgMoneyMin", "500", FCVAR_NONE, "Минимальная сумма получаемая за подарок");
	pCvars[cMoneyMax] = create_cvar("awDgMoneyMax", "5000", FCVAR_NONE, "Максимальная сумма получаемая за подарок");
	
	bind_pcvar_float(pCvars[cDropRarity], dropRarity);
	bind_pcvar_num(pCvars[cLifeTime], giftLifeTime);
	bind_pcvar_num(pCvars[cMoneyMin], giftMoney[mMin]);
	bind_pcvar_num(pCvars[cMoneyMax], giftMoney[mMax]);
	
	AutoExecConfig(true, "Main", "DeathGift");
}

public plugin_natives(){
	register_native("awDgSendGiftMsg", "_awDgSendGiftMsg");
}

public plugin_precache(){
	register_plugin(PLUG_NAME, PLUG_VER, "ArKaNeMaN");
	
	if(file_exists(MODEL_PATH)) precache_model(MODEL_PATH);
	else{
		server_print("[%s v%s] [Error] [Model file not found (%s)] [Plugin stopped]", PLUG_NAME, PLUG_VER, MODEL_PATH);
		set_fail_state("[Model file not found (%s)]", MODEL_PATH);
	}
	
	static sndFullPath[PLATFORM_MAX_PATH]; formatex(sndFullPath, charsmax(sndFullPath), "sound/%s", TAKE_SOUND);
	if(file_exists(sndFullPath)) precache_sound(TAKE_SOUND);
	else{
		server_print("[%s v%s] [Error] [Take sound file not found (%s)] [Plugin stopped]", PLUG_NAME, PLUG_VER, TAKE_SOUND);
		set_fail_state("[Take sound file not found (%s)]", TAKE_SOUND);
	}
}

public giftTouch(ent, id){
	emit_sound(ent, CHAN_VOICE, TAKE_SOUND, SOUND_VOL, ATTN_NORM, 0, PITCH_NORM);
	giftDelete(ent);
	//server_print("[%s v%s] [Debug] [giftTouch] [%n]", PLUG_NAME, PLUG_VER, id);
	static ret; ExecuteForward(pFwds[fTouchPre], ret, id, ent);
	if(ret == AW_DG_CONT){
		//server_print("[%s v%s] [Debug] [giftTouch] [%n] [Fwd]", PLUG_NAME, PLUG_VER, id);
		static newMoney; newMoney = random_num(giftMoney[mMin], giftMoney[mMax]);
		cs_set_user_money(id, cs_get_user_money(id)+newMoney);
		client_print_color(id, print_team_default, "^4[^3%s^4] ^3%L ^4%d$^3.", CHAT_PREFIX, LANG_PLAYER, "GIFT_TAKE", newMoney);
		ExecuteForward(pFwds[fTouchPost], ret, id, ent);
	}
}

public pDeath(victim, attacker, corpse){
	//server_print("[%s v%s] [Debug] [pDeath] [%n]", PLUG_NAME, PLUG_VER, victim);
	if(dropRandom()){
		//server_print("[%s v%s] [Debug] [pDeath] [%n] [Drop]", PLUG_NAME, PLUG_VER, victim);
		giftCreate(victim);
	}
}

public giftDelete(ent){
	//server_print("[%s v%s] [Debug] [giftDelete]", PLUG_NAME, PLUG_VER);
	if(giftLifeTime && task_exists(ent)) remove_task(ent);
	if(ent) remove_entity(ent);
}

public giftCreate(id){
	//server_print("[%s v%s] [Debug] [giftCreate] [%n]", PLUG_NAME, PLUG_VER, id);
	static ret; ExecuteForward(pFwds[fCreatePre], ret);
	if(ret == AW_DG_CONT){
		//server_print("[%s v%s] [Debug] [giftCreate] [%n] [Fwd]", PLUG_NAME, PLUG_VER, id);
		static a;
		if(!a) a = engfunc(EngFunc_AllocString, "info_target");
		static ent; ent = engfunc(EngFunc_CreateNamedEntity, a);
		if(pev_valid(ent)){
			//server_print("[%s v%s] [Debug] [giftCreate] [%n] [Fwd] [Create] [%d]", PLUG_NAME, PLUG_VER, id, ent);
			set_pev(ent, pev_classname, "gift");
			
			static Float:f[3]; pev(id, pev_origin, f); f[2] -= 30.0;
			set_pev(ent, pev_origin, f);
			
			engfunc(EngFunc_SetModel, ent, MODEL_PATH);
			
			dllfunc(DLLFunc_Spawn,ent);
			
			set_pev(ent, pev_nextthink, get_gametime()+THINK_DELAY);
			
			set_pev(ent, pev_movetype, MOVETYPE_NOCLIP);
			
			static Float:vecAvelocity[3]; vecAvelocity[1] = ROTATE_SPEED * 10.0;
			set_pev(ent, pev_avelocity, vecAvelocity);
			
			static Float:vecVelocity[3]; vecVelocity[2] = FLY_SPEED;

			set_pev(ent, pev_velocity, vecVelocity);
			set_pev(ent, pev_maxspeed, FLY_SPEED);
			
			set_pev(ent, pev_solid, SOLID_TRIGGER);
			engfunc(EngFunc_SetSize, ent, fMins, fMaxs);
			
			if(giftLifeTime) set_task(float(giftLifeTime), "giftDelete", ent);
			
			ExecuteForward(pFwds[fCreatePost], ret, ent);
			//server_print("[%s v%s] [Debug] [giftCreate] [%n] [Fwd] [Created] [%d]", PLUG_NAME, PLUG_VER, id, ent);
		}
	}
}

public giftThink(ent){
	if(pev_valid(ent) != PDATA_SAFE) return;
	
	set_pev(ent, pev_nextthink, get_gametime()+THINK_DELAY);
	
	static Float:vecVelocity[3], Float:fFlyUp;
	pev(ent, pev_maxspeed, fFlyUp);
	vecVelocity[2] = fFlyUp;

	set_pev(ent, pev_velocity, vecVelocity);
	set_pev(ent, pev_maxspeed, -fFlyUp);
	
	//server_print("[%s v%s] [Debug] [giftThink] [%d]", PLUG_NAME, PLUG_VER, ent);
	
	return;
}

bool:dropRandom(){
	//server_print("[%s v%s] [Debug] [dropRandom]", PLUG_NAME, PLUG_VER);
	if(random_num(1, floatround(1.0/dropRarity)) == 1) return true;
	return false;
}

public _awDgSendGiftMsg(pluginId, params){
	static id; id = get_param(1);
	static str[64]; get_string(2, str, charsmax(str));
	if(equal(str, "")) client_print_color(id, print_team_default, "^4[^3%s^4] ^3%L.", CHAT_PREFIX, LANG_PLAYER, "GIFT_TAKE_EMPTY");
	else client_print_color(id, print_team_default, "^4[^3%s^4] ^3%L ^4%s^3.", CHAT_PREFIX, LANG_PLAYER, "GIFT_TAKE", str);
}
