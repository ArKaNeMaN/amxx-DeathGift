#include <amxmodx>
#include <json>
#include <DeathGift>

#pragma reqlib DeathGift
#if !defined AMXMODX_NOAUTOLOAD
	#pragma loadlib DeathGift
#endif

#pragma semicolon 1

// #define DEBUG

#define ParamType DG_ParamType

/*
    Разрешение добавления подарков после инициализации плагина.
    Если, после вылючения данной функции, добавлять подарки после инициализации, то они будут игнорироваться.
    Не рекомендуется включать без надобности, ибо будет лишняя нагрузка при поднятии подарков.
*/
//#define ALLOW_MANAGE_GIFTS_AFTER_INIT

enum {
    ERR_INVALID_BONUS_CALLBACK = 1,
}

enum _:E_BonusParam{
    BP_Key[32],
    ParamType:BP_Type,
}

enum _:E_BonusData{
    BD_Name[32],
    BD_Callback,
    Array:BD_Params,
}

enum _:E_GiftData{
    GD_Name[64],
    GD_Chance,
    GD_Bonus[32],
    Trie:GD_BonusParams,
}

new Trie:Bonuses;
new Array:Gifts;

#if !defined ALLOW_MANAGE_GIFTS_AFTER_INIT
new gChances = 0;
#endif

new const PLUG_NAME[] = "[DG] More Bonuses";
new const PLUG_VER[] = "2.0.0";

public plugin_natives(){
    register_native("DG_RegisterBonus", "@Native_RegisterBonus");
}

public plugin_init(){
    register_plugin(PLUG_NAME, PLUG_VER, "ArKaNeMaN");

    #if defined DEBUG
    log_amx("[DEBUG] [Init] [ParamType] [ptInteger: %d]", _:ptInteger);
    log_amx("[DEBUG] [Init] [ParamType] [ptFloat: %d]", _:ptFloat);
    log_amx("[DEBUG] [Init] [ParamType] [ptString: %d]", _:ptString);
    log_amx("[DEBUG] [Init] [ParamType] [ptBool: %d]", _:ptBool);
    #endif

    Bonuses = TrieCreate();
    Gifts = ArrayCreate(E_GiftData, 4);
    
    new ret;
    ExecuteForward(CreateMultiForward("DG_OnBonusesInit", ET_CONTINUE), ret);
    LoadGifts();

    server_print("[%s v%s] loaded %d bonuses & %d gifts.", PLUG_NAME, PLUG_VER, TrieGetSize(Bonuses), ArraySize(Gifts));
}

public DG_OnGiftTouch_Pre(const UserId, const GiftId){
    if(!ArraySize(Gifts))
        return DG_CONTINUE;

    new Gift = GetRandomGift();

    static GiftData[E_GiftData];
    ArrayGetArray(Gifts, Gift, GiftData);

    UseBonus(UserId, GiftData[GD_Bonus], GiftData[GD_BonusParams]);
    DG_SendGiftMsg(UserId, GiftData[GD_Name]);

    return DG_STOP;
}

GetRandomGift(){
    static GiftData[E_GiftData];

    #if defined ALLOW_MANAGE_GIFTS_AFTER_INIT
    new Chances = 0;
    for(new i = 0; i < ArraySize(Gifts); i++){
        ArrayGetArray(Gifts, i, GiftData);
        Chances += GiftData[GD_Chance];
    }
    new Rnd = random_num(1, Chances);
    #else
    new Rnd = random_num(1, gChances);
    #endif
    
    for(new i = 0; i < ArraySize(Gifts); i++){
        ArrayGetArray(Gifts, i, GiftData);
        Rnd -= GiftData[GD_Chance];
        if(Rnd <= 0)
            return i;
    }
    return -1;
}

UseBonus(const UserId, const BonusName[], const Trie:Params){
    static BonusData[E_BonusData];
    TrieGetArray(Bonuses, BonusName, BonusData, E_BonusData);

    new ret;
    ExecuteForward(BonusData[BD_Callback], ret, UserId, Params);
}

@Native_RegisterBonus(const PluginId, const ArgCnt){
    enum {Arg_Name = 1, Arg_Callback, Arg_Params}

    new BonusData[E_BonusData], CallbackName[64];
    get_string(Arg_Name, BonusData[BD_Name], charsmax(BonusData[BD_Name]));

    get_string(Arg_Callback, CallbackName, charsmax(CallbackName));
    BonusData[BD_Callback] = CreateOneForward(PluginId, CallbackName, FP_CELL, FP_CELL);
    if(BonusData[BD_Callback] < 0){
        log_error(ERR_INVALID_BONUS_CALLBACK, "Invalid bonus callback `%s`. Bonus `%s`.", CallbackName, BonusData[BD_Name]);
        return 0;
    }
    
    #if defined DEBUG
    log_amx("[DEBUG] [_RegisterBonus] [ArgCnt: %d] [>%d?]", ArgCnt, Arg_Params);
    #endif

    if(ArgCnt > Arg_Params){
        BonusData[BD_Params] = ArrayCreate(E_BonusParam, 1);
        new Param[E_BonusParam];

        #if defined DEBUG
        log_amx("[DEBUG] [_RegisterBonus] [i: %d -> %d] [i+2]", Arg_Params, ArgCnt);
        #endif

        for(new i = Arg_Params; i < ArgCnt; i += 2){
            get_string(i, Param[BP_Key], charsmax(Param[BP_Key]));
            Param[BP_Type] = ParamType:get_param_byref(i+1);

            #if defined DEBUG
            log_amx("[DEBUG] [_RegisterBonus] [i: %d] [%s instanceof %d]", i, Param[BP_Key], _:Param[BP_Type]);
            #endif

            ArrayPushArray(BonusData[BD_Params], Param);
        }
    }
    else BonusData[BD_Params] = Invalid_Array;

    return TrieSetArray(Bonuses, BonusData[BD_Name], BonusData, E_BonusData);
}

LoadGifts(){
    new File[PLATFORM_MAX_PATH];
    get_localinfo("amxx_configsdir", File, charsmax(File));
    add(File, charsmax(File), "/plugins/DeathGift/Gifts.json");
    if(!file_exists(File)){
        log_amx("[ERROR] Config file '%s' not found", File);
        return;
    }
    
    new JSON:List = json_parse(File, true);
    if(!json_is_array(List)){
        json_free(List);
        log_amx("[ERROR] Invalid config structure. File '%s'.", File);
        return;
    }

    new JSON:Item, JSON:Params;
    for(new i = 0; i < json_array_get_count(List); i++){
        Item = json_array_get_value(List, i);
        if(!json_is_object(Item)){
            json_free(Item);
            log_amx("[WARNING] Invalid config structure. File '%s', item %d.", File, i);
            continue;
        }
        
        new GiftData[E_GiftData];

        json_object_get_string(Item, "Name", GiftData[GD_Name], charsmax(GiftData[GD_Name]));
        GiftData[GD_Chance] = json_object_get_number(Item, "Chance");
        json_object_get_string(Item, "Bonus", GiftData[GD_Bonus], charsmax(GiftData[GD_Bonus]));
        if(!TrieKeyExists(Bonuses, GiftData[GD_Bonus])){
            log_amx("[WARNING] Undefined bonus `%s`. File `%s`, item %d.", GiftData[GD_Bonus], File, i);
            json_free(Item);
            continue;
        }

        new BonusData[E_BonusData];
        TrieGetArray(Bonuses, GiftData[GD_Bonus], BonusData, E_BonusData);
        GiftData[GD_BonusParams] = TrieCreate();

        if(BonusData[BD_Params] != Invalid_Array){
            Params = json_object_get_value(Item, "Params");
            for(new j = 0; j < ArraySize(BonusData[BD_Params]); j++){
                new ParamData[E_BonusParam];
                ArrayGetArray(BonusData[BD_Params], j, ParamData);

                switch(ParamData[BP_Type]){
                    case ptInteger: {
                        if(!json_object_has_value(Params, ParamData[BP_Key], JSONNumber))
                            continue;
                        TrieSetCell(GiftData[GD_BonusParams], ParamData[BP_Key], json_object_get_number(Params, ParamData[BP_Key]));
                    }
                    case ptFloat: {
                        if(!json_object_has_value(Params, ParamData[BP_Key], JSONNumber))
                            continue;
                        TrieSetCell(GiftData[GD_BonusParams], ParamData[BP_Key], json_object_get_real(Params, ParamData[BP_Key]));
                    }
                    case ptString: {
                        if(!json_object_has_value(Params, ParamData[BP_Key], JSONString))
                            continue;
                        new Str[128];
                        json_object_get_string(Params, ParamData[BP_Key], Str, charsmax(Str));
                        TrieSetString(GiftData[GD_BonusParams], ParamData[BP_Key], Str);
                    }
                    case ptBool: {
                        if(!json_object_has_value(Params, ParamData[BP_Key], JSONBoolean))
                            continue;
                        TrieSetCell(GiftData[GD_BonusParams], ParamData[BP_Key], json_object_get_bool(Params, ParamData[BP_Key]));
                    }
                }
            }
            json_free(Params);
        }

        ArrayPushArray(Gifts, GiftData);
        #if !defined ALLOW_MANAGE_GIFTS_AFTER_INIT
            gChances += GiftData[GD_Chance];
        #endif
        json_free(Item);
    }
    json_free(List);
}