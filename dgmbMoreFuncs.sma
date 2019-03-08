#include <amxmodx>



#define AES_EXP // Для опыта Advanced Exp. System [https://dev-cs.ru/threads/1462/]
#define AES_BONUS // Для бонусов Advanced Exp. System [https://dev-cs.ru/threads/1462/]
//#define AES_V4 // Поддержка старой версии AES

//#define AW_COINS // Для ArKaNaCoins (Моё)



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

#define PLUG_NAME "[DG][MB] More Functions"
#define PLUG_VER "1.0"

public plugin_init(){
	register_plugin(PLUG_NAME, PLUG_VER, "ArKaNeMaN");
}

#if defined AES_EXP
	public aes_addExp(id, exp){
		aes_add_player_exp(id, exp);
	}
#endif
#if defined AES_BONUS
	public aes_addBonuses(id, bonuses){
		aes_add_player_bonus(id, bonuses);
	}
#endif

#if defined AW_COINS
	public awCoins_addCoins(id, coins){
		awAddUserCoins(id, coins);
	}
#endif