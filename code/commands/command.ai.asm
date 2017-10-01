;================================================================================================================================================================================================
;
;   command.ai.asm
;
;   This function sets parameters for the offline ai.
;
;   Assumptions:      eax - Length of received data.
;                     esi - Pointer to descriptor associated with target socket.
;
;   Returns:          None.
;
;   Crossreferencing: Symbol Location
;
;                     none   none
;

    command.ai: call  write.bad.command.error ; Let the user know that they've entered a bad command and suggest HELP.
                ret                           ; Return to caller