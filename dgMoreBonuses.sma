#include <amxmodx>
#include <cstrike>
#include <awDeathGift>

enum cvars{
	
	cMoneyRarity,
	cMoneyMin,
	cMoneyMax,
	
	cHPRarity,
	cHPMin,
	cHPMax,
}

enum items{
	itMoney,
	itHP,
}

enum minMax{
	min,
	max,
}

#define PLUG_VER "1.0"
#define PLUG_NAME "[DG] MoreBonuses"

new Float:dropsRarity[items];

new moneyCount[minMax];
new hpCount[minMax];

public plugin_init(){
	register_plugin(PLUG_NAME, PLUG_VER, "ArKaNeMaN");
	cfgExec();
	server_print("[%s v%s] loaded.", PLUG_NAME, PLUG_VER);
}

public awDgFwdTouchPre(id, ent){
	switch(randBonus()){
		case 0:{ // Деньги
			static dropMoney; dropMoney = random_num(moneyCount[min], moneyCount[max])
			cs_set_user_money(id, cs_get_user_money()+dropMoney);
			static giftMsg[16]; formatex(giftMsg, charsmax(giftMsg), "%d$", dropMoney);
			awDgSendGiftMsg(id, giftMsg);
		}
		case 1:{ // HP
			static dropHp; dropHp = random_num(hpCount[min], hpCount[max])
			set_user_health(id, get_user_health()+dropHp);
			static giftMsg[16]; formatex(giftMsg, charsmax(giftMsg), "%dHP", dropHp);
			awDgSendGiftMsg(id, giftMsg);
		}
	}
	return AW_DG_STOP;
}

randBonus(){
	
}

cfgExec(){
	new pCvars[cvars];
	pCvars[cMoneyRarity] = create_cvar("awDgMbMoneyRarity", "0.1", FCVAR_NONE, "Редкость выпадения денег");
	pCvars[cMoneyMin] = create_cvar("awDgMbMoneyMin", "100", FCVAR_NONE, "Мин. кол-во денег в подарке");
	pCvars[cMoneyMax] = create_cvar("awDgMbMoneyMax", "3000", FCVAR_NONE, "Макс. кол-во денег в подарке");
	pCvars[cHPRarity] = create_cvar("awDgMbHPRarity", "0.1", FCVAR_NONE, "Редкость выпадения HP");
	pCvars[cHPMin] = create_cvar("awDgMbHPMin", "10", FCVAR_NONE, "Мин. кол-во HP в подарке");
	pCvars[cHPMax] = create_cvar("awDgMbHPMax", "30", FCVAR_NONE, "Макс. кол-во HP в подарке");
	
	new cfgFilePath[PLATFORM_MAX_PATH];
	new const fileName[64] = "/awDgMoreBonuses.cfg";
	get_localinfo("amxx_configsdir", cfgFilePath, charsmax(cfgFilePath));
	add(cfgFilePath, charsmax(cfgFilePath), fileName);
	
	if(file_exists(cfgFilePath)){
		server_cmd("exec %s", cfgFilePath);
		server_exec();
		
		bind_pcvar_float(pCvars[cMoneyRarity], dropsRarity[itMoney]);
		if(dropsRarity[itMoney] > 0.0){
			bind_pcvar_num(pCvars[cMoneyMin], moneyCount[min]);
			bind_pcvar_num(pCvars[cMoneyMax], moneyCount[max]);
		}
		
		bind_pcvar_float(pCvars[cHPRarity], dropsRarity[itHP]);
		if(dropsRarity[itHP] > 0.0){
			bind_pcvar_num(pCvars[cHPMin], hpCount[min]);
			bind_pcvar_num(pCvars[cHPMax], hpCount[max]);
		}
	}
	else set_fail_state("[%s v%s] [Error] [Config file not found (%s)] [Plugin stopped]", PLUG_NAME, PLUG_VER, cfgFilePath);
}
