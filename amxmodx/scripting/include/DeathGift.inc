#if defined _deathgift_included
	#endinput
#endif
#define _deathgift_included

#define DG_CONTINUE 0 /* Continue function execution */
#define DG_STOP 1 /* abort function */

/**
* Called before pick up gift
* 
* @param UserId		Player index
* @param GiftId		Gift entity index
*
* @return		DG_CONTINUE to continue issuing a standard gift
* 				DG_STOP to cancel the results of standard gift
*/
forward DG_OnGiftTouch_Pre(const UserId, const GiftId);

/**
* Called after pick up gift
* 
* @param UserId		Player index
* @param GiftId		Gift entity index
*
* @noreturn
*/
forward DG_OnGiftTouch_Post(const UserId, const GiftId);

/**
* Called before create gift entity
*
* @param UserId		Killed player index
*
* @return		DG_CONTINUE to proceed with the creation of entity
* 				DG_STOP to cancel the creation of entity
*/
forward DG_OnGiftCreate_Pre(const UserId);

/**
* Called after create gift entity
*
* @param GiftId		Gift entity index
*
* @noreturn
*/
forward DG_OnGiftCreate_Post(const GiftId);

/**
* Sends a message about raising a gift
*
* @param UserId		ID of the player who raised the gift
* @param GiftName[]	what the player picked up (for Example: if str = "123", it Will be like this: you picked up a gift and got 123). If the string is empty it will be written that the gift is empty
*
* @noreturn
*/
native DG_SendGiftMsg(const UserId, const GiftName[] = "");


// ============ [ More Bonuses ] ================== //


enum DG_ParamType{
    ptInteger = 1,
    ptFloat,
    ptString,
    ptBool,
}

/**
* Called when plugin more bonusees initialed
*
* @noreturn
*/
forward DG_OnBonusesInit();

/**
* Register bonus for gifts
*
* @note Callback function: @func(const UserId, const Trie:Params);
*
*
* @param Name 		Name of bonus
* @param Callback 	Name of callback function
* @param ... 		Names of params
*
* @return 1 on success, 0 otherwise
*/
native DG_RegisterBonus(const Name[], const Callback[], any:...);

/**
* Get bonus param as integer
*
* @param Params 	Array of params
* @param Key        Param`s key
* @param Default 	Default value
*
* @return Integer value
*/
stock DG_ReadParamInt(const Trie:Params, const Key[], const Default = 0) {
    new Val = Default;
    if (!TrieKeyExists(Params, Key)) {
        return Val;
    }
    
    TrieGetCell(Params, Key, Val);
    return Val;
}

/**
* Get bonus param as float
*
* @param Params 	Array of params
* @param Key        Param`s key
* @param Default 	Default value
*
* @return Float value
*/
stock Float:DG_ReadParamFloat(const Trie:Params, const Key[], const Float:Default = 0.0) {
    new Float:Val = Default;
    if (!TrieKeyExists(Params, Key)) {
        return Default;
    }

    TrieGetCell(Params, Key, Val);
    return Val;
}

/**
* Get bonus param as boolean
*
* @param Params 	Array of params
* @param Key        Param`s key
* @param Default 	Default value
*
* @return Boolean value
*/
stock bool:DG_ReadParamBool(const Trie:Params, const Key[], const bool:Default = false) {
    new bool:Val = Default;
    if (!TrieKeyExists(Params, Key)) {
        return Val;
    }

    TrieGetCell(Params, Key, Val);
    return Val;
}

/**
* Get bonus param as string
*
* @param Params 	Array of params
* @param Key        Param`s key
* @param Buff       Buffer for write value
* @param Len        Length of buffer
* @param Default 	Default value
*
* @return Number of cells written
*/
stock DG_ReadParamString(const Trie:Params, const Key[], Buff[], Len, const Default[] = "") {
    new Size = formatex(Buff, Len, Default);
    if (!TrieKeyExists(Params, Key)) {
        return Size;
    }

    TrieGetString(Params, Key, Buff, Len, Size);
    return Size;
}