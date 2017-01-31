;====================================================================================================================================================================================================
;
;   send.to.player
;
;   This function sends a provided message out to a provided area.
;
;   Assumptions:    eax - Connection ID to which to broadcast.
;                   ebx - Area from which broadcast is being generated.
;                   ecx - Pointer to message to be broadcast.
;                   edx - Length of message to be broadcast.
;
;   Returns:        eax - 0 on success
;                   eax - out of area indicator if target recipient is out of area
;

    send.to.player:                   push esi                                             ; Preserve caller's esi.

                                      mov  dword [socket.data.send.buffer.pointer], ecx    ; Point send function to provided message.
                                      mov  dword [socket.data.send.buffer.l], edx          ; Provide length of message to send function.

                                      mov  esi, connection.table                           ; esi - pointer to table of handles associated with active connections.
                                      mov  ecx, socket.number                              ; ecx - number of connections to poll.

    send.to.player.connection.poll:   cmp  dword [esi+connection.area.id.index], ebx       ; Does the area id associated with this connection match the area id to be broadcast?
                                      jnz  send.to.player.out.of.area.error                ; No - Return out of area indicator.

                                      cmp  dword [esi+connection.number.index], eax        ; Does this description correspond to the target recipient's ID?
                                      jz   send.to.player.broadcast                        ; Yes - Go broadcast the message.

    send.to.player.broadcast.done:    add  esi, connection.entry.size                      ; esi - pointer to next connection handle in table.
                                      loop send.to.area.connection.poll                    ; Go check the next connection.

                                      pop  esi                                             ; Restore caller's esi.

                                      ret                                                  ; Return to caller.

    send.to.player.broadcast:         push eax                                             ; Preserve area id to be broadcast.
                                      mov  eax, dword [esi+connection.descriptor.index]    ; eax - descriptor to be broadcast to.
                                      mov  dword [socket.data.send.socket.descriptor], eax ; Point send function to descriptor to which the message is to be sent.
                                      pop  eax                                             ; Restore area id to be broadcast.
                                      call socket.send                                     ; Send the message to the indicated descriptor.

                                      ret                                                  ; Return to caller.

    send.to.player.out.of.area.error: mov  eax, 0FFFFh                                     ; eax - Out of area indicator

                                      ret                                                  ; Return to caller.