#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#tryinclude <reapi>
#include <DeathGift>

#pragma reqlib DeathGift
#if !defined AMXMODX_NOAUTOLOAD
    #pragma loadlib DeathGift
#endif

// Настройки:

#define USE_DOUBLE_JUMP // Двойной прыжок
#define USE_DAMAGE_MULT	// Умножение урона

// #define AES_EXP 		// Для опыта Advanced Exp. System [https://dev-cs.ru/threads/1462/ ]
// #define AES_BONUS 	// Для бонусов Advanced Exp. System [https://dev-cs.ru/threads/1462/ ]

#if defined AES_EXP || defined AES_BONUS
    #include <aes_v>
    #define aes_add_player_exp(%0,%1) aes_add_player_exp_f(%0, float(%1))
    #define aes_add_player_bonus(%0,%1) aes_add_player_bonus_f(%0, %1)
#endif

new const PLUG_NAME[] = "[DG] More Funcs";
new const PLUG_VER[] = "2.0.1";

public DG_OnBonusesInit() {
    register_plugin(PLUG_NAME, PLUG_VER, "ArKaNeMaN");

    #if defined _reapi_included
    DG_RegisterBonus("DropWeapon", "@Bonus_DropWeapon", "Slot", ptString);
    #endif

    #if defined AES_BONUS
    DG_RegisterBonus("AesBonuses", "@Bonus_AesBonuses", "Bonuses", ptInteger);
    #endif

    #if defined AES_EXP
    DG_RegisterBonus("AesExp", "@Bonus_AesExp", "Exp", ptFloat);
    #endif

    #if defined USE_DOUBLE_JUMP
    RegisterHam(Ham_Player_Jump, "player", "@Hook_PlayerJump", false);
    DG_RegisterBonus("DoubleJump", "@Bonus_DoubleJump", "Duration", ptFloat);
    #endif

    #if defined USE_DAMAGE_MULT
    RegisterHam(Ham_TakeDamage, "player", "@Hook_PlayerTakeDamage", false);
    DG_RegisterBonus(
        "DamageMult", "@Bonus_DamageMult",
        "Duration", ptFloat,
        "Multiplier", ptFloat
    );
    #endif

    DG_RegisterBonus("Test", "@Bonus_Test", "Param123", ptInteger);
    DG_RegisterBonus("Kill", "@Bonus_Kill");
    DG_RegisterBonus("Freeze", "@Bonus_Freeze", "Duration", ptFloat);
    DG_RegisterBonus(
        "Burn", "@Bonus_Burn",
        "Duration", ptFloat,
        "Interval", ptFloat,
        "Damage", ptInteger
    );
    DG_RegisterBonus(
        "Poison", "@Bonus_Poison",
        "Duration", ptFloat,
        "Interval", ptFloat,
        "Damage", ptInteger
    );
    DG_RegisterBonus(
        "ScreenShake", "@Bonus_ScreenShake",
        "Amplitude", ptInteger,
        "Duration", ptInteger,
        "Frequency", ptInteger
    );
    DG_RegisterBonus(
        "ScreenFade", "@Bonus_ScreenFade",
        "Duration", ptInteger,
        "HoldTime", ptInteger,
        "Red", ptInteger,
        "Green", ptInteger,
        "Blue", ptInteger,
        "Alpha", ptInteger
    );
}

// Тестовый бонус
@Bonus_Test(const UserId, const Trie:p) {
    log_amx("[TEST] UserId = %d", UserId);
    log_amx("[TEST] Param123 = %d", DG_ReadParamInt(p, "Param123"));
}

// Смерть :)
@Bonus_Kill(const UserId, const Trie:p) {
    user_kill(UserId);
}

#if defined _reapi_included
// Выпадение оружия
@Bonus_DropWeapon(const UserId, const Trie:p) {
    new strSlot[16];
    DG_ReadParamString(p, "Slot", strSlot, charsmax(strSlot), "primary");

    rg_drop_items_by_slot(UserId, GetSlot(strSlot));
}

InventorySlotType:GetSlot(const slotName[]) {
    if (equali(slotName, "primary") || equali(slotName, "prim")) {
        return PRIMARY_WEAPON_SLOT; 
    } else if(equali(slotName, "secondary") || equali(slotName, "sec") || equali(slotName, "pistol")) {
        return PISTOL_SLOT;
    } else if(equali(slotName, "knife")) {
        return KNIFE_SLOT;
    } else if(equali(slotName, "gren") || equali(slotName, "grenade")) {
        return GRENADE_SLOT;
    } else if(equali(slotName, "c4") || equali(slotName, "bomb")) {
        return C4_SLOT;
    }

    log_amx("[Error] Undefined slot name '%s'", slotName);
    return NONE_SLOT;
}
#endif

// Заморозка
#define FROZEN_TASK_OFSET 12354
@Bonus_Freeze(const UserId, const Trie:p) {
    set_pev(UserId, pev_flags, pev(UserId, pev_flags) | FL_FROZEN);
    set_task(DG_ReadParamFloat(p, "Duration"), "@Task_FrozenRemove", UserId + FROZEN_TASK_OFSET);
}

@Task_FrozenRemove(const TaskId) {
    new UserId = TaskId - FROZEN_TASK_OFSET;
    new Flags; Flags = pev(UserId, pev_flags);
    Flags &= ~FL_FROZEN;
    set_pev(UserId, pev_flags, Flags);
}

// Поджог
#define BURN_TASK_OFSET 31154
#define RM_BURN_TASK_OFSET 31654
new pBurnDmg[MAX_PLAYERS+1];
@Bonus_Burn(const UserId, const Trie:p) {
    pBurnDmg[UserId] = DG_ReadParamInt(p, "Damage");
    set_task(DG_ReadParamFloat(p, "Interval"), "@Task_BurnHurt", UserId + BURN_TASK_OFSET, _, _, "b");
    set_task(DG_ReadParamFloat(p, "Duration"), "@Task_BurnRemove", UserId + RM_BURN_TASK_OFSET);
}

@Task_BurnHurt(id) {
    id -= BURN_TASK_OFSET;
    ExecuteHam(Ham_TakeDamage, id, 0, 0, float(pBurnDmg[id]), DMG_BURN);
}

@Task_BurnRemove(id) {
    id -= RM_BURN_TASK_OFSET;
    remove_task(id + BURN_TASK_OFSET);
}

// Тряска экрана
@Bonus_ScreenShake(const UserId, const Trie:p) {
    message_begin(MSG_ONE, get_user_msgid("ScreenShake"), {0, 0, 0}, UserId);
    write_short(DG_ReadParamInt(p, "Amplitude")*4096);
    write_short(DG_ReadParamInt(p, "Duration")*4096);
    write_short(DG_ReadParamInt(p, "Frequency")*4096);
    message_end();
}

// Ослепление
#define SF_FADE_OUT 0x0000
@Bonus_ScreenFade(const UserId, const Trie:p) {
    message_begin(MSG_ONE, get_user_msgid("ScreenFade"), {0, 0, 0}, UserId);
    write_short(DG_ReadParamInt(p, "Duration") * 4096);
    write_short(DG_ReadParamInt(p, "HoldTime") * 4096);
    write_short(SF_FADE_OUT);
    write_byte(DG_ReadParamInt(p, "Red", 255));
    write_byte(DG_ReadParamInt(p, "Green", 255));
    write_byte(DG_ReadParamInt(p, "Blue", 255));
    write_byte(DG_ReadParamInt(p, "Alpha", 255));
    message_end();
}

// Опыт и бонусы AES
#if defined AES_EXP
@Bonus_AesExp(const UserId, const Trie:p) {
    aes_add_player_exp_f(UserId, DG_ReadParamFloat(p, "Exp", 1.0));
}
#endif
#if defined AES_BONUS
@Bonus_AesBonuses(const UserId, const Trie:p) {
    aes_add_player_bonus_f(UserId, DG_ReadParamInt(p, "Bonuses", 1));
}
#endif

// Отравление
#define POISON_TASK_OFSET 86723
#define RM_POISON_TASK_OFSET 86323
new pPoisonDmg[MAX_PLAYERS+1];

@Bonus_Poison(const UserId, const Trie:p) {
    pPoisonDmg[UserId] = DG_ReadParamInt(p, "Damage");
    set_task(DG_ReadParamFloat(p, "Interval"), "@Task_PoisonHurt", UserId + POISON_TASK_OFSET, _, _, "b");
    set_task(DG_ReadParamFloat(p, "Duration"), "@Task_PoisonRemove", UserId + RM_POISON_TASK_OFSET);
}

@Task_PoisonHurt(id) {
    id -= POISON_TASK_OFSET;
    ExecuteHam(Ham_TakeDamage, id, 0, 0, float(pPoisonDmg[id]), DMG_POISON);
}

@Task_PoisonRemove(id) {
    id -= RM_POISON_TASK_OFSET;
    remove_task(id + POISON_TASK_OFSET);
}

// Двойной прыжок
#if defined USE_DOUBLE_JUMP
#define DOUBLE_JUMP_TASK_OFSET 14315
new bool:szTwoJump[MAX_PLAYERS+1];
new szTwoJumpNum[MAX_PLAYERS+1];
new bool:szDoTwoJump[MAX_PLAYERS+1];

@Bonus_DoubleJump(const UserId, const Trie:p) {
    szTwoJump[UserId] = true;
    set_task(DG_ReadParamFloat(p, "Duration"), "@Task_DoubleJumpRemove", UserId + DOUBLE_JUMP_TASK_OFSET);
}

@Task_DoubleJumpRemove(id) {
    id -= DOUBLE_JUMP_TASK_OFSET;
    szTwoJump[id] = false;
}

@Hook_PlayerJump(id) {
    if (!szTwoJump[id]) {
        return HAM_IGNORED;
    }

    new szButton = pev(id, pev_button);
    new szOldButton = pev(id, pev_oldbuttons);
    if (
        (szButton & IN_JUMP)
        && !(pev(id, pev_flags) & FL_ONGROUND)
        && !(szOldButton & IN_JUMP)
    ) {
        if (szTwoJumpNum[id] < 1) {
            szDoTwoJump[id] = true;
            szTwoJumpNum[id]++;
            PostTwoJump(id);
            return HAM_IGNORED;
        }
    }

    if (
        (szButton & IN_JUMP)
        && (pev(id, pev_flags) & FL_ONGROUND)
    ) {
        szTwoJumpNum[id] = 0;
    }

    return HAM_IGNORED;
}

PostTwoJump(id){
    if (
        !szTwoJump[id]
        || !is_user_alive(id)
        || !szDoTwoJump[id]
    ) {
        return;
    }
    
    new Float:szVelocity[3];
    pev(id, pev_velocity, szVelocity);

    szVelocity[2] = random_float(295.0,305.0);
    set_pev(id, pev_velocity, szVelocity);

    szDoTwoJump[id] = false;
}
#endif


// Больше урона
#if defined USE_DAMAGE_MULT
#define MULT_DAMAGE_TASK_OFSET 41546
new Float:pMultDmg[MAX_PLAYERS+1];

@Bonus_DamageMult(const UserId, const Trie:p) {
    pMultDmg[UserId] = DG_ReadParamFloat(p, "Multiplier", 1.25);
    set_task(DG_ReadParamFloat(p, "Duration"), "@Task_MultDamageRemove", UserId + MULT_DAMAGE_TASK_OFSET);
}

@Task_MultDamageRemove(id) {
    id -= MULT_DAMAGE_TASK_OFSET;
    pMultDmg[id] = 0.0;
}

@Hook_PlayerTakeDamage(victim, inflictor, attacker, Float:damage, damagebits) {
    if (attacker < 1 || attacker > 32) {
        return HAM_IGNORED;
    }

    if (pMultDmg[attacker] > 0.0) {
        SetHamParamFloat(4, damage * pMultDmg[attacker]);
    }

    return HAM_IGNORED;
}
#endif
