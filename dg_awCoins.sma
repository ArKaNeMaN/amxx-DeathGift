#include <amxmodx>
#include <awDeathGift>
#include <awCoins>

#define PLUG_VER "1.0"
#define PLUG_NAME "[DG] awCoins"

public plugin_init(){
	register_plugin(PLUG_NAME, PLUG_VER, "ArKaNeMaN");
	server_print("[%s v%s] loaded.", PLUG_NAME, PLUG_VER);
}

public awDgFwdTouchPre(id, ent){
	static newCoins; newCoins = random_num(0, 5);
	if(newCoins){
		awAddUserCoins(id, newCoins);
		static msg[64]; formatex(msg, charsmax(msg), "%d Coins", newCoins);
		awDgSendGiftMsg(id, msg);
	}
	else awDgSendGiftMsg(id);
	return AW_DG_STOP;
}