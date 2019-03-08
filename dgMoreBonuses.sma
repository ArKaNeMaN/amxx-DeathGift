#include <amxmodx>
#include <fun>
#include <cstrike>
#include <awDeathGift>

enum e_funcData{
	fd_name[32],
	fd_plugin[32],
	fd_param,
	bool:fd_hasParam,
}

enum e_giftData{
	e_giftType:gd_type,
	gd_name[32],
	gd_iparam1,
	gd_iparam2,
	gd_sparam1[32],
	//gd_sparam2[32],
}

enum e_giftType{
	gt_e_undefined,
	
	gt_empty,
	gt_money,
	gt_health,
	gt_armor,
	gt_item,
	gt_func, // Для кастомных бонусов
}

new Array:gifts;
new Array:giftFuncs;

#define PLUG_VER "1.0"
#define PLUG_NAME "[DG] MoreBonuses"

public plugin_init(){
	register_plugin(PLUG_NAME, PLUG_VER, "ArKaNeMaN");
	
	register_srvcmd("dgmb_AddGift", "cmdAddGift");
	
	gifts = ArrayCreate(e_giftData);
	giftFuncs = ArrayCreate(e_funcData);
	
	AutoExecConfig(true, "MoreBonuses", "DeathGift");
	
	server_print("[%s v%s] loaded.", PLUG_NAME, PLUG_VER);
}

public plugin_eng(){
	ArrayDestroy(gifts);
	ArrayDestroy(giftFuncs);
}

/* public plugin_natives(){
	register_native("dgmb_addGift", "_dgmb_addGift");
} */

public cmdAddGift(){
	static numParams; numParams = read_argc()-1;
	//log_amx("[Debug] [cmdAddGift] [Args: %d]", numParams);
	if(numParams < 1) return;
	
	static giftData[e_giftData];
	
	static strType[16]; read_argv(1, strType, charsmax(strType));
	giftData[gd_type] = getGiftType(strType);
	
	switch(giftData[gd_type]){
		case gt_e_undefined: {
			log_amx("[Warning] [Gift %d] Undefined gift type", ArraySize(gifts)+1);
			return;
		}
		
		case gt_empty: {}
		case gt_money: {
			if(numParams < 2) return;
			giftData[gd_iparam1] = read_argv_int(2);
		}
		case gt_health: {
			if(numParams < 3) return;
			giftData[gd_iparam1] = read_argv_int(2);
			giftData[gd_iparam2] = read_argv_int(3);
			
		}
		case gt_armor: {
			if(numParams < 3) return;
			giftData[gd_iparam1] = read_argv_int(2);
			giftData[gd_iparam2] = read_argv_int(3);
		}
		case gt_item: {
			if(numParams < 3) return;
			read_argv(2, giftData[gd_name], charsmax(giftData[gd_name]));
			read_argv(3, giftData[gd_sparam1], charsmax(giftData[gd_sparam1]));
		}
		case gt_func: {
			if(numParams < 4) return;
			read_argv(2, giftData[gd_name], charsmax(giftData[gd_name]));
			static funcData[e_funcData];
			read_argv(3, funcData[fd_name], charsmax(funcData[fd_name]));
			read_argv(4, funcData[fd_plugin], charsmax(funcData[fd_plugin]));
			if(numParams > 4){
				funcData[fd_param] = read_argv_int(5);
				funcData[fd_hasParam] = true;
			}
			//log_amx("[Debug] [Name: %s] [Plugin: %s] [hasParam: %d] [Param: %d]", funcData[fd_name], funcData[fd_plugin], funcData[fd_hasParam], funcData[fd_param]);
			giftData[gd_iparam1] = ArrayPushArray(giftFuncs, funcData);
		}
	}
	
	//log_amx("[Debug] [Type: %d] [iParam1: %d] [iParam2: %d] [sParam1: %s]", _:giftData[gd_type], giftData[gd_iparam1], giftData[gd_iparam2], giftData[gd_sparam1]);
	
	ArrayPushArray(gifts, giftData);
	
}

public awDgFwdTouchPre(id, ent){
	
	if(!ArraySize(gifts)) return AW_DG_CONT;
	
	static giftData[e_giftData]; ArrayGetArray(gifts, random_num(0, ArraySize(gifts)-1), giftData);
	
	//log_amx("[Debug] [Type: %d] [iParam1: %d] [iParam2: %d] [sParam1: %s]", _:giftData[gd_type], giftData[gd_iparam1], giftData[gd_iparam2], giftData[gd_sparam1]);
	
	switch(giftData[gd_type]){
		case gt_empty: {
			awDgSendGiftMsg(id);
		}
		case gt_money: {
			cs_set_user_money(id, cs_get_user_money(id)+giftData[gd_iparam1]);
			static giftMsg[64]; formatex(giftMsg, charsmax(giftMsg), "$%d", giftData[gd_iparam1]);
			awDgSendGiftMsg(id, giftMsg);
		}
		case gt_health: {
			set_user_health(id, min(get_user_health(id)+giftData[gd_iparam1], giftData[gd_iparam2]));
			static giftMsg[64]; formatex(giftMsg, charsmax(giftMsg), "%dHP", giftData[gd_iparam1]);
			awDgSendGiftMsg(id, giftMsg);
		}
		case gt_armor: {
			set_user_armor(id, min(get_user_armor(id)+giftData[gd_iparam1], giftData[gd_iparam2]));
			static giftMsg[64]; formatex(giftMsg, charsmax(giftMsg), "%dAP", giftData[gd_iparam1]);
			awDgSendGiftMsg(id, giftMsg);
		}
		case gt_item: {
			give_item(id, giftData[gd_sparam1]);
			awDgSendGiftMsg(id, giftData[gd_name]);
		}
		case gt_func: {
			static funcData[e_funcData]; ArrayGetArray(giftFuncs, giftData[gd_iparam1], funcData);
			//log_amx("[Debug] [Name: %s] [Plugin: %s] [hasParam: %d] [Param: %d]", funcData[fd_name], funcData[fd_plugin], funcData[fd_hasParam], funcData[fd_param]);
			switch(callfunc_begin(funcData[fd_name], funcData[fd_plugin])){
				case -1: {
					log_amx("[ERROR] Plugin '%s' not found", funcData[fd_plugin]);
					return AW_DG_STOP;
				}
				case -2: {
					log_amx("[ERROR] Function '%s' in '%s' not found", funcData[fd_name], funcData[fd_plugin]);
					return AW_DG_STOP;
				}
			}
			callfunc_push_int(id);
			if(funcData[fd_hasParam]) callfunc_push_int(funcData[fd_param]);
			callfunc_end();
			awDgSendGiftMsg(id, giftData[gd_name]);
		}
	}
	
	return AW_DG_STOP;
}

/* public _dgmb_addGift(){
	
} */

e_giftType:getGiftType(const type[]){
	if(equal("money", type)) return gt_money;
	if(equal("health", type) || equal("hp", type)) return gt_health;
	if(equal("armor", type) || equal("ap", type)) return gt_armor;
	if(equal("item", type)) return gt_item;
	if(equal("func", type) || equal("function", type)) return gt_func;
	return gt_e_undefined;
}