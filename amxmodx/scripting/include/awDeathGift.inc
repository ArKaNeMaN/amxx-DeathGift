#define AW_DG_CONT 0 /* Continue function execution */
#define AW_DG_STOP 1 /* abort function */

/**
* Called after the creation of entity gift
* 
* @param id		ID of the player
* @param ent	ID entity gift
*
* @return		AW_DG_CONT to continue issuing a standard gift
* 				AW_DG_STOP to cancel the results of standard gift
*/
forward awDgFwdTouchPre(id, ent);

/**
* Called after the creation of entity gift
* 
* @param id		ID of the player
* @param ent	ID entity gift
*
* @noreturn
*/
forward awDgFwdTouchPost(id, ent);

/**
* Called after the creation of entity gift
*
* @param ent	ID entity gift
*
* @return		AW_DG_CONT to proceed with the creation of entity
* 				AW_DG_STOP to cancel the creation of entity
*/
forward awDgFwdCreatePre();

/**
* Called after the creation of entity gift
*
* @param ent	ID entity gift
*
* @noreturn
*/
forward awDgFwdCreatePost(ent);

/**
* Sends a message about raising a gift
*
* @param id		ID of the player who raised the gift
* @param str[]	what the player picked up (for Example: if str = "123", it Will be like this: you picked up a gift and got 123). If the line is empty it will be written that the gift is empty
*
* @noreturn
*/
native awDgSendGiftMsg(id, const str [] = "");