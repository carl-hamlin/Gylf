;=================================================================================================================================================================================================
;
;   get.external.data
;
;   This function reads data from external files.
;
;   Assumptions:    ebx - Pointer to filename from which to read.
;
;   Returns:        external.data.buffer - Read data.
;                   edx - Length of data read.
;

    get.external.data: push eax                             ; Preserve caller's eax register.
                       push ebx                             ; Preserve caller's ebx register.
                       push ecx                             ; Preserve caller's ecx register.

                       call open.descriptor                 ; Associate a descriptor with the external data file.
            
                       mov  ebx, eax                        ; ebx - Descriptor associated with the file.

                       mov  ecx, external.data.buffer       ; ecx - pointer to buffer into which to read the length of the external data.
                       mov  edx, byte.l                     ; edx - length of data to be read.
                       call read.descriptor                 ; Read the length of the external data.

                       mov  ecx, external.data.buffer       ; ecx - Pointer to buffer into which to read the escape sequence.
                       sub  edx, edx                        ; edx - Prepared for length of external data.
                       mov  dl, byte [external.data.buffer] ; edx - Length of external data.
                       call read.descriptor                 ; Read the external data into the external data buffer.

                       call close.descriptor                ; Disassociate the descriptor.

                       pop  ecx                             ; Restore caller's ecx register.
                       pop  ebx                             ; Restore caller's ebx register.
                       pop  eax                             ; Restore caller's eax register.

                       ret                                  ; Return to caller.
