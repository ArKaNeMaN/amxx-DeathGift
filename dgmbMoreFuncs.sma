#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#tryinclude <reapi>

// Настройки:

//#define AES_EXP 			// Для опыта Advanced Exp. System [https://dev-cs.ru/threads/1462/ ]
//#define AES_BONUS 		// Для бонусов Advanced Exp. System [https://dev-cs.ru/threads/1462/ ]
//#define AES_V4 			// Поддержка старой версии AES

//#define AW_COINS			// Для ArKaNaCoins (Моё)



#if defined AES_EXP || defined AES_BONUS
	#if defined AES_V4
		#include <aes_main>
	#else
		#include <aes_v>
		#define aes_add_player_exp(%0,%1) aes_add_player_exp_f(%0,float(%1))
		#define aes_add_player_bonus(%0,%1) aes_add_player_bonus_f(%0,%1)
	#endif
#endif

#if defined AW_COINS
	#include <awCoins>
#endif

new const PLUG_NAME[] = "[DG][MB] More Functions";
new const PLUG_VER[] = "1.1";

public plugin_init(){
	register_plugin(PLUG_NAME, PLUG_VER, "ArKaNeMaN");
	RegisterHam(Ham_Player_Jump, "player", "pJump", false);
	RegisterHam(Ham_TakeDamage, "player", "pTakeDamage", false);
	server_print("[%s v%s] loaded.", PLUG_NAME, PLUG_VER);
}


// Убийство игрока

public amx_kill(id, const strExplode[]){
	static bool:explode; explode = bool:str_to_num(strExplode);
	if(explode){
		
	}
	user_kill(id);
}


#if defined _reapi_included
// Выпадение оружия

public reapi_dropWeapon(id, const strSlot[]){
	rg_drop_items_by_slot(id, getSlot(strSlot));
}

InventorySlotType:getSlot(const slotName[]){
	if(equal(slotName, "primary") || equal(slotName, "prim")) return PRIMARY_WEAPON_SLOT;
	else if(equal(slotName, "secondary") || equal(slotName, "sec") || equal(slotName, "pistol")) return PISTOL_SLOT;
	else if(equal(slotName, "knife")) return KNIFE_SLOT;
	else if(equal(slotName, "gren") || equal(slotName, "grenade")) return GRENADE_SLOT;
	else if(equal(slotName, "c4") || equal(slotName, "bomb")) return C4_SLOT;
	log_amx("[Error] Undefined slot name '%s'", slotName);
	return NONE_SLOT;
}
#endif


// Заморозка

#define FROZEN_TASK_OFSET 12354

public amx_frozen(id, const strDur[]){
	static Float:dur; dur = str_to_float(strDur);
	
	set_pev(id, pev_flags, pev(id, pev_flags)|FL_FROZEN);
	//engfunc(EngFunc_DropToFloor, id);
	set_task(dur, "rmFrozen", id+FROZEN_TASK_OFSET);
}

public rmFrozen(id){
	id -= FROZEN_TASK_OFSET;
	static flags; flags = pev(id, pev_flags);
	flags &= ~FL_FROZEN;
	set_pev(id, pev_flags, flags);
}


// Поджог

#define BURN_TASK_OFSET 31154
#define RM_BURN_TASK_OFSET 31654

new pBurnDmg[MAX_PLAYERS+1];

public amx_burn(id, const strDmg[], const strDur[], const strInterval[]){
	static dmg; dmg = str_to_num(strDmg);
	static Float:dur; dur = str_to_float(strDur);
	static Float:interval; interval = str_to_float(strInterval);
	
	pBurnDmg[id] = dmg;
	set_task(interval, "burnHurt", id+BURN_TASK_OFSET, _, _, "b");
	set_task(dur, "rmBurn", id+RM_BURN_TASK_OFSET);
}

public burnHurt(id){
	id -= BURN_TASK_OFSET;
	ExecuteHam(Ham_TakeDamage, id, 0, 0, float(pBurnDmg[id]), DMG_BURN);
}

public rmBurn(id){
	id -= RM_BURN_TASK_OFSET;
	remove_task(id+BURN_TASK_OFSET);
}


// Тряска экрана

// <Амплитуда> <Длительность> <Частота>
public amx_screenShake(id, const strAmp[], const strDur[], const strFreq[]){
	static amp; amp = str_to_num(strAmp);
	static dur; dur = str_to_num(strDur);
	static freq; freq = str_to_num(strFreq);
	
	message_begin(MSG_ONE, get_user_msgid("ScreenShake"), {0, 0, 0}, id);
	write_short(amp*4096);
	write_short(dur*4096);
	write_short(freq*4096);
	message_end();
}


// Ослепление

#define SF_FADE_OUT 0x0000

public amx_screenFade(id, const strDur[], const strHold[]){
	static dur; dur = str_to_num(strDur);
	static hold; hold = str_to_num(strHold);
	
	message_begin(MSG_ONE, get_user_msgid("ScreenFade"), {0, 0, 0}, id);
	write_short(dur*4096);
	write_short(hold*4096);
	write_short(SF_FADE_OUT);
	write_byte(255);
	write_byte(255);
	write_byte(255);
	write_byte(255);
	message_end();
}


// Опыт и бонусы AES

#if defined AES_EXP
public aes_addExp(id, const strExp[]){
	static exp; exp = str_to_num(strExp);
	aes_add_player_exp(id, exp);
}
#endif
#if defined AES_BONUS
public aes_addBonuses(id, const strBonuses[]){
	static bonuses; bonuses = str_to_num(strBonuses);
	aes_add_player_bonus(id, bonuses);
}
#endif


// Коины

#if defined AW_COINS
public awCoins_addCoins(id, const strCoins[]){
	static coins; coins = str_to_num(strCoins);
	awAddUserCoins(id, coins);
}
#endif


// Выдача флагов

#define DROP_FLAGS_TASK_OFSET 56431

new pDropFlags[MAX_PLAYERS+1];

public amx_addFlags(id, const strDropFlags[], const strDur[]){
	
	static Float:dur; dur = str_to_float(strDur);
	static dropFlags; dropFlags = read_flags(strDropFlags);
	
	static flags; flags = get_user_flags(id);
	
	if(!(flags & dropFlags)){
		if(pDropFlags[id]) rmDropFlags(id);
		
		set_user_flags(id, flags|dropFlags);
		
		set_task(dur, "rmDropFlags", id+DROP_FLAGS_TASK_OFSET);
	}
}

public rmDropFlags(id){
	id -= DROP_FLAGS_TASK_OFSET;
	
	static flags; flags = get_user_flags(id);
	flags &= ~pDropFlags[id];
	
	set_user_flags(id, flags);
	pDropFlags[id] = 0;
}


// Отравление

#define POISON_TASK_OFSET 86723
#define RM_POISON_TASK_OFSET 86323

new pPoisonDmg[MAX_PLAYERS+1];

public amx_poison(id, const strDmg[], const strDur[], const strInterval[]){
	static dmg; dmg = str_to_num(strDmg);
	static Float:dur; dur = str_to_float(strDur);
	static Float:interval; interval = str_to_float(strInterval);
	
	pPoisonDmg[id] = dmg;
	set_task(interval, "poisonHurt", id+POISON_TASK_OFSET, _, _, "b");
	set_task(dur, "rmPoison", id+RM_POISON_TASK_OFSET);
}

public poisonHurt(id){
	id -= POISON_TASK_OFSET;
	ExecuteHam(Ham_TakeDamage, id, 0, 0, float(pPoisonDmg[id]), DMG_POISON);
}

public rmPoison(id){
	id -= RM_POISON_TASK_OFSET;
	remove_task(id+POISON_TASK_OFSET);
}

// Двойной прыжок

#define DOUBLE_JUMP_TASK_OFSET 14315

new bool:szTwoJump[MAX_PLAYERS+1];
new szTwoJumpNum[MAX_PLAYERS+1];
new bool:szDoTwoJump[MAX_PLAYERS+1];

public amx_doubleJump(id, const strDur[]){
	static Float:dur; dur = str_to_float(strDur);
	szTwoJump[id] = true;
	set_task(dur, "rmDoubleJump", id+DOUBLE_JUMP_TASK_OFSET);
}

public rmDoubleJump(id){
	id -= DOUBLE_JUMP_TASK_OFSET;
	szTwoJump[id] = false;
}

public pJump(id){
	if(szTwoJump[id]){
		new szButton = pev(id, pev_button);
		new szOldButton = pev(id, pev_oldbuttons);
		if((szButton & IN_JUMP) && !(pev(id, pev_flags) & FL_ONGROUND) && !(szOldButton & IN_JUMP)){
			if(szTwoJumpNum[id] < 1){
				szDoTwoJump[id] = true;
				szTwoJumpNum[id]++;
				PostTwoJump(id);
				return HAM_IGNORED;
			}
		}
		if((szButton & IN_JUMP) && (pev(id, pev_flags) & FL_ONGROUND)) szTwoJumpNum[id] = 0;
	}
	return HAM_IGNORED;
}

public PostTwoJump(id){
	if(szTwoJump[id]){
		if(!is_user_alive(id)) return;
		if(szDoTwoJump[id]){
			new Float:szVelocity[3];
			pev(id, pev_velocity, szVelocity);
			szVelocity[2] = random_float(295.0,305.0);
			set_pev(id, pev_velocity, szVelocity);
			szDoTwoJump[id] = false;
			return;
		}
	}
	return;
}


// Больше урона

#define MULT_DAMAGE_TASK_OFSET 41546

new Float:pMultDmg[MAX_PLAYERS+1];

public amx_multDamage(id, const strDur[], const strMult[]){
	static Float:dur; dur = str_to_float(strDur);
	static Float:mult; mult = str_to_float(strMult);
	
	pMultDmg[id] = mult;
	set_task(dur, "rmMutlDamage", id+MULT_DAMAGE_TASK_OFSET);
}

public rmMutlDamage(id){
	id -= MULT_DAMAGE_TASK_OFSET;
	pMultDmg[id] = 0.0;
}

public pTakeDamage(victim, inflictor, attacker, damage, damagebits){
	if(pMultDmg[attacker] != 0.0){
		SetHamParamFloat(4, damage*pMultDmg[attacker]);
	}
	return HAM_IGNORED;
}
	