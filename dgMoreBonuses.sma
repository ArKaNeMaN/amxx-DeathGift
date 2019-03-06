#include <amxmodx>
#include <fun>
#include <cstrike>
#include <awDeathGift>

enum e_giftData{
	e_giftType:gd_type,
	gd_name[32],
	gd_iparam1,
	gd_iparam2,
	gd_sparam1[32],
	gd_sparam2[32],
}

enum e_giftType{
	gt_e_undefined,
	
	gt_money,
	gt_health,
	gt_armor,
	gt_item,
	gt_func, // Для кастомных бонусов
}

new Array:gifts;

#define PLUG_VER "in dev"
#define PLUG_NAME "[DG] MoreBonuses"

public plugin_init(){
	register_plugin(PLUG_NAME, PLUG_VER, "ArKaNeMaN");
	cfgExec();
	server_print("[%s v%s] loaded.", PLUG_NAME, PLUG_VER);
}

public plugin_eng() ArrayDestroy(gifts);

public plugin_natives(){
	register_native("dgmb_addGift", "_dgmb_addGift");
}

cfgExec(){
	
	register_srvcmd("dgmb_AddGift", "cmdAddGift");
	// dgmb_AddGift "Название" "тип" "Доп. параметры"...
	
	gifts = ArrayCreate(e_giftData);
	
	new cfgFilePath[PLATFORM_MAX_PATH];
	new const fileName[64] = "/awDgMoreBonuses.cfg";
	get_localinfo("amxx_configsdir", cfgFilePath, charsmax(cfgFilePath));
	add(cfgFilePath, charsmax(cfgFilePath), fileName);
	
	if(file_exists(cfgFilePath)){
		server_cmd("exec %s", cfgFilePath);
		server_exec();
	}
	else set_fail_state("[%s v%s] [Error] [Config file not found (%s)] [Plugin stopped]", PLUG_NAME, PLUG_VER, cfgFilePath);
}

public cmdAddGift(){
	static numParams; numParams = read_argc()-1;
	if(numParams < 2) return;
	
	static giftData[e_giftData];
	
	static strType[16]; read_argv(1, strType, charsmax(strType));
	giftData[gd_type] = getGiftType(strType);
	
	read_argv(2, giftData[gd_name], charsmax(giftData[gd_name]));
	
	switch(giftData[gd_type]){
		case gt_e_undefined: {
			log_amx("[Warning] [Gift %d] Undefined gift type", ArraySize(gifts)+1);
			return;
		}
		
		case gt_money: {
			if(numParams < 3) return;
			giftData[gd_iparam1] = read_argv_int(3);
		}
		case gt_health: {
			if(numParams < 4) return;
			giftData[gd_iparam1] = read_argv_int(3);
			giftData[gd_iparam2] = read_argv_int(4);
			
		}
		case gt_armor: {
			if(numParams < 3) return;
			giftData[gd_iparam1] = read_argv_int(3);
			giftData[gd_iparam2] = read_argv_int(4);
			
		}
		case gt_item: {
			if(numParams < 3) return;
			read_argv(3, giftData[gd_sparam1], charsmax(giftData[gd_sparam1]));
			
		}
		case gt_func: {
			if(numParams < 4) return;
			read_argv(3, giftData[gd_sparam1], charsmax(giftData[gd_sparam1]));
			read_argv(4, giftData[gd_sparam2], charsmax(giftData[gd_sparam2]));
		}
	}
	
	ArrayPushArray(gifts, giftData);
	
}

public awDgFwdTouchPre(id, ent){
	
	static giftData[e_giftData]; ArrayGetArray(gifts, random_num(0, ArraySize(gifts)-1), giftData);
	
	switch(giftData[gd_type]){
		case gt_money: {
			cs_set_user_money(id, cs_get_user_money()+giftData[gd_iparam1]);
			static giftMsg[64]; formatex(giftMsg, charsmax(giftMsg), "%s в кол-ве %dшт.", giftData[gd_name], giftData[gd_iparam1]);
			awDgSendGiftMsg(id, giftMsg);
		}
		case gt_health: {
			set_user_health(id, min(get_user_health()+giftData[gd_iparam1], giftData[gd_iparam2]));
			static giftMsg[64]; formatex(giftMsg, charsmax(giftMsg), "%s в кол-ве %dшт.", giftData[gd_name], giftData[gd_iparam1]);
			awDgSendGiftMsg(id, giftMsg);
		}
		case gt_armor: {
			set_user_armor(id, min(get_user_armor()+giftData[gd_iparam1], giftData[gd_iparam2]));
			static giftMsg[64]; formatex(giftMsg, charsmax(giftMsg), "%s в кол-ве %dшт.", giftData[gd_name], giftData[gd_iparam1]);
			awDgSendGiftMsg(id, giftMsg);
		}
		case gt_item: {
			give_item(id, giftData[dg_sparam1]);
			awDgSendGiftMsg(id, giftData[gd_name]);
		}
		case gt_func: {
			
		}
	}
	
	return AW_DG_STOP;
}

public _dgmb_addGift(){
	
}

e_giftType:getGiftType(const type[]){
	if(!strcmp("money", type)) return gt_money;
	else if(!strcmp("health", type)) return gt_health;
	else if(!strcmp("armor", type)) return gt_armor;
	else if(!strcmp("item", type)) return gt_item;
	else if(!strcmp("func", type)) return gt_func;
	return gt_e_undefined;
}