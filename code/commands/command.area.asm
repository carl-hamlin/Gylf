;==================================================================================================================================================================================================================
;
;   command.area.asm
;
;   This function creates an area. Syntax: area <name> <quoted description>
;
;   Assumptions:      eax - Length of received data.
;                     esi - Pointer to descriptor associated with target socket.
;
;   Returns:          None.
;

    command.area:                       push esi                                                                          ; Preserve index to connection entry.
                                        push eax                                                                          ; Preserve length of received data.

                                        call check.admin                                                                  ; See if the calling socket is controlled by an admin.
                                        jc   command.area.admin                                                           ; If so, go create the area. Otherwise...

                                        pop  eax                                                                          ; Restore length of received data.

;------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    command.area.bad:                   pop  esi                                                                          ; Restore index to connection entry.

                                        mov  ecx, local.data.area.bad.syntax.message                                      ; Pointer to local message indicating an admin bounced on syntax.
                                        mov  edx, local.data.area.bad.syntax.message.l                                    ; Length of message.
                                        call write.descriptor                                                             ; Tell the admin there's someone online with admin priviledges that needs an education.

                                        mov  ebx, dword [esi+connection.descriptor.index]                                 ; ebx - Descriptor associated with current connection.
                                        mov  dword [socket.data.send.socket.descriptor], ebx                              ; Store socket descriptor for send function.
                                        mov  dword [socket.data.send.buffer.pointer], socket.data.area.bad.syntax.message ; Point send function to message indicating that the command was bad.
                                        mov  dword [socket.data.send.buffer.l], socket.data.area.bad.syntax.message.l     ; Store length of message for send function.
                                        call socket.send                                                                  ; Tell the user that the command doesn't have a current analogue.

                                        mov  eax, [esi+connection.descriptor.index]                                       ; eax - Descriptor associated with active connection.
                                        call write.prompt                                                                 ; Restore the user's prompt.

                                        ret                                                                               ; Return to caller.

;------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    command.area.admin:                 pop  eax                                                                          ; Restore length of received data.

                                        mov  esi, buffer.1                                                                ; ecx - Pointer to received command string.
                                        add  esi, command.area.l                                                          ; ecx - Potential pointer to argument for command.

;------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    command.area.find.first.argument:   cmp  byte [esi], 020h                                                             ; Did the user put a space between the command and the first argument?
                                        jnz  command.area.start                                                           ; Nope. Let's get started. Otherwise...

                                        cmp  byte [esi], 00h                                                              ; Have we hit the end of the command string?
                                        jz   command.area.bad                                                             ; Yes. Go give the user a lesson on syntax.

                                        inc  esi                                                                          ; esi - Potential pointer to argument for command.

                                        jmp  command.area.find.first.argument                                             ; Go see if we've hit the argument yet.

;------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    command.area.start:                 mov  edi, area.name                                                               ; edi - Pointer to placeholder for area name.
                                        sub  edx, edx                                                                     ; edx - Prepared to count bytes.
                                        mov  ecx, area.name.field.l                                                       ; ecx - Size of area name field. Used as loop counter.

;------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    command.area.loop.1:                cmp  byte [esi], "|"                                                              ; Have we hit the argument demarcator?
                                        jz   command.area.name.l                                                          ; Yes. Go process the name and go on to the second argument.

                                        cmp  byte [esi], 00h                                                              ; Have we hit the end of the command string?
                                        jz   command.area.bad                                                             ; Yes. Go give the user a lesson on syntax.

                                        movsb                                                                             ; Move a byte of the first argument over to the name field in the area header.
                                        inc  edx                                                                          ; edx - Count of how many bytes we've moved so far.

                                        loop command.area.loop.1                                                          ; Go move the rest of the first argument.

                                        jmp  command.area.bad                                                             ; Looks like the argument is longer than the field to which it is to be stored. Go educate the user on the fine points of syntax.

;------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    command.area.name.l:                mov  dword [area.name.l], edx                                                     ; Store the length of the first argument.
                                        sub  edx, edx                                                                     ; edx - Prepared to count bytes again...

                                        inc  esi                                                                          ; esi - Potential pointer to second argument.
                                        mov  edi, area.description                                                        ; edi - Pointer to storage for area description.

                                        mov  ecx, area.description.field.l                                                ; ecx - Size of description field. Used as loop counter.

;------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    command.area.find.second.argument:  cmp  byte [esi], 020h                                                             ; Did the user put a space between the command and the first argument?
                                        jnz  command.area.loop.2                                                          ; Nope. Let's get started. Otherwise...

                                        cmp  byte [esi], 00h                                                              ; Have we hit the end of the command string?
                                        jz   command.area.bad                                                             ; Yes. Go give the user a lesson on syntax.

                                        inc  esi                                                                          ; esi - Potential pointer to argument for command.

                                        jmp  command.area.find.second.argument                                            ; Go see if we've hit the argument yet.

;------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    command.area.loop.2:                cmp  byte [esi], 00h                                                              ; Have we hit the end of the command string?
                                        jz   command.area.description.l                                                   ; Yes. Go process the description and get started finding a filename to which to store this data.

                                        movsb                                                                             ; Move a byte of the first argument over to the description field in the area header.
                                        inc  edx                                                                          ; edx - Count of how many bytes we've moved so far.

                                        loop command.area.loop.2                                                          ; Go move the rest of the second argument.

                                        jmp  command.area.bad                                                             ; Looks like the argument is longer than the field to which it is to be stored. Go educate the user on the finer points of syntax.

                                        ; *** Potentially unreachable code. Review when appropriate. ***

                                        mov  ecx, available.areas                                                         ; ecx - Number of areas available. Used as loop counter.

;------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    command.area.description.l:         mov  dword [area.description.l], edx                                              ; Store the length of the area description.

                                        pop  esi                                                                          ; Restore index to connection entry.

    command.area.filename.loop:         mov  ebx, area.filename                                                           ; ebx - Pointer to filename entry for area filenames.
                                        call open.descriptor                                                              ; Try the current filename.

                                        or   eax, eax                                                                     ; If eax is signed, the file doesn't exist, which means we've found a candidate.
                                        jns  command.area.next.file                                                       ; No candidate this time. Go check the next file.

                                        call create.file                                                                  ; Create the candidate file.

                                        mov  ebx, eax                                                                     ; ebx - Descriptor associated with candidate file.

                                        mov  [file.indicator], ebx                                                        ; Point write.descriptor to the candidate file.
                                        mov  ecx, area.name.l                                                             ; ecx - Pointer to area name length.
                                        mov  edx, dword.l                                                                 ; edx - Length of area name length.
                                        call write.descriptor                                                             ; Store the area header in the candidate file.

                                        mov  [file.indicator], ebx                                                        ; Point write.descriptor to the candidate file.
                                        mov  ecx, area.name                                                               ; ecx - Pointer to area name.
                                        mov  edx, dword [area.name.l]                                                     ; edx - Length of area name.
                                        call write.descriptor                                                             ; Store the area name in the candidate file.

                                        mov  [file.indicator], ebx                                                        ; Point write.descriptor to the candidate file.
                                        mov  ecx, area.description.l                                                      ; ecx - Pointer to area description length.
                                        mov  edx, dword.l                                                                 ; edx - Length of area description length.
                                        call write.descriptor                                                             ; Store the area description length in the candidate file.

                                        mov  [file.indicator], ebx                                                        ; Point write.descriptor to the candidate file.
                                        mov  ecx, area.description                                                        ; ecx - Pointer to area description.
                                        mov  edx, dword [area.description.l]                                              ; edx - Length of area description.
                                        call write.descriptor                                                             ; Store the area description in the candidate file.

                                        push eax                                                                          ; Preserve descriptor associated with the candidate file.
                                        sub  eax, eax                                                                     ; eax - number of items in new area.
                                        mov  dword [area.num.contained.items], eax                                        ; Set number of items in new area.
                                        pop  eax                                                                          ; Restore descriptor associated with the candidate file.

                                        mov  [file.indicator], ebx                                                        ; Point write.descriptor to the candidate file.
                                        mov  ecx, area.num.contained.items                                                ; ecx - Pointer to number of items contained within the new area.
                                        mov  edx, dword.l                                                                 ; edx - Length of number of items contained within the new area.
                                        call write.descriptor                                                             ; Store the number of items in the candidate file.

                                        call close.descriptor                                                             ; Disassociate the descriptor.

                                        mov  ecx, local.data.area.created.message                                         ; ecx - Pointer to message indicating the creation of an area.
                                        mov  edx, local.data.area.created.message.l                                       ; edx - Length of message.
                                        call write.descriptor                                                             ; Tell the admin a new area has been created.

                                        mov  ecx, area.name                                                               ; ecx - Pointer to stored area name.
                                        mov  edx, dword [area.name.l]                                                     ; edx - Length of stored area name.
                                        call write.descriptor                                                             ; Show the area name to the admin.

                                        mov  ecx, local.data.carriage.return                                              ; ecx - Pointer to carriage return.
                                        mov  edx, local.data.carriage.return.l                                            ; edx - Length of carriage return.
                                        call write.descriptor                                                             ; Send a carriage return to the local console.

                                        mov  ecx, area.description                                                        ; ecx - Pointer to area description.
                                        mov  edx, dword [area.description.l]                                              ; edx - Length of area description.
                                        call write.descriptor                                                             ; Show the area description to the admin.

                                        mov  ecx, local.data.carriage.return                                              ; ecx - Pointer to carriage return.
                                        mov  edx, local.data.carriage.return.l                                            ; edx - Length of carriage return.
                                        call write.descriptor                                                             ; Send a carriage return to the local console.

                                        mov  eax, [esi+connection.descriptor.index]                                       ; eax - Descriptor associated with active connection.
                                        mov  dword [socket.data.send.buffer.pointer], socket.data.area.created.message    ; Point socket.send to area creation success message.
                                        mov  dword [socket.data.send.buffer.l], socket.data.area.created.message.l        ; Provide length of message.
                                        call socket.send                                                                  ; Send the success message to the socket.

                                        mov  eax, [esi+connection.descriptor.index]                                       ; eax - Descriptor associated with active connection.
                                        call write.prompt                                                                 ; Restore the user's prompt.

                                        ret                                                                               ; Return to caller.

;------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    command.area.next.file:             mov  ebx, eax                                                                     ; ebx - Descriptor associated with an unusable area file.
                                        call close.descriptor                                                             ; Disassociate the descriptor.

                                        sub  eax, eax                                                                     ; eax - Prepared for counting places...
                                        mov  ebx, area.filename                                                           ; ebx - Pointer to current area filename.
                                        add  ebx, area.filename.l                                                         ; ebx - Pointer to byte immediately following area filename.
                                        sub  ebx, word.l                                                                  ; ebx - Pointer to least significant place in area filename.

                                        cmp  byte [ebx], char.9                                                           ; Is the byte at [ebx] a "9"?
                                        jz   command.area.filename.finder                                                 ; Yes. Go zero it out and address the next place up.

                                        jmp  command.area.prep.next                                                       ; Increment the byte at [ebx], restore ebx to the last place, and check the resulting filename.

;------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    command.area.filename.finder:       cmp  eax, 08h                                                                     ; Have we run out of areas?
                                        jz   command.area.filename.out.of.areas                                           ; Yes. Go take care of that.

                                        mov  byte [ebx], char.0                                                           ; Zero out the byte at [ebx].
                                        dec  ebx                                                                          ; ebx - Pointer to next place up.
                                        inc  eax                                                                          ; eax - Count of places.

                                        cmp  byte [ebx], char.9                                                           ; Is the byte at [ebx] a "9"?
                                        jz   command.area.filename.finder                                                 ; Yes. Go zero it out and address the next place up.

                                        jmp  command.area.prep.next                                                       ; Increment the byte at [ebx], restore ebx to the last place, and check the resulting filename.

;------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    command.area.filename.out.of.areas: mov  ecx, local.data.out.of.areas.message                                         ; ecx - Pointer to message indicating we're out of area files.
                                        mov  edx, local.data.out.of.areas.message.l                                       ; edx - Length of message.
                                        call write.descriptor                                                             ; Tell the admin we're out of area files.

                                        mov  eax, [esi+connection.descriptor.index]                                       ; eax - Descriptor associated with active socket.
                                        mov  dword [socket.data.send.buffer.pointer], socket.data.out.of.areas.message    ; Point socket.send to out of areas message.
                                        mov  dword [socket.data.send.buffer.l], socket.data.out.of.areas.message.l        ; Provide length of message.
                                        call socket.send                                                                  ; Send the out of areas message to the socket.

                                        call write.prompt                                                                 ; Restore the user's prompt.

                                        ret                                                                               ; Return to caller.

;------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    command.area.prep.next:             inc  byte [ebx]                                                                   ; Increment the byte at [ebx].
                                        add  ebx, eax                                                                     ; Restore ebx to the last place in the filename.
                                        dec  ecx                                                                          ; ecx - Number of filenames left to try.
                                        jcxz command.area.filename.out.of.areas                                           ; Go tell the admin that we're out of area files.

                                        jmp  command.area.filename.loop                                                   ; Go check the next file.