;List of libraries

include Irvine32.inc
include Macros.inc

;List of macros

;.model flat,stdcall alewady included

endl equ <0dh,0ah> ; this is a macro 

ascii_d equ <64h>
ascii_e equ <65h>
ascii_fullStop equ <2eh>

; it goes like layer row column 
coded_a equ <010101b>
coded_b equ <011001b>
coded_c equ <011101b>
coded_d equ <010110b>
coded_e equ <011010b>
coded_f equ <011110b>
coded_g equ <010111b>
coded_h equ <011011b>
coded_i equ <011111b>
coded_j equ <100101b>
coded_k equ <101001b>
coded_l equ <101101b>
coded_m equ <100110b>
coded_n equ <101010b>
coded_o equ <101110b>
coded_p equ <100111b>
coded_q equ <101011b>
coded_r equ <101111b>
coded_s equ <110101b>
coded_t equ <111001b>
coded_u equ <111101b>
coded_v equ <110110b>
coded_w equ <111010b>
coded_x equ <111110b>
coded_y equ <110111b>
coded_z equ <111011b>
coded_fullStop equ <111111b>

; let's make buffer in buffer_size 

BUFFER_SIZE = 501	; this is max_size 
TRIPLE_BUFFER_SIZE = BUFFER_SIZE*3
BUFFER_SIZE_PLUS_THREE = BUFFER_SIZE+3

.data?
inFileHandle handle ?
outFileHandle handle ?
buffer byte BUFFER_SIZE dup(?)
inputFilename byte 80 dup(?) ; input txt file must be less than 80 characters long 
outputFilename byte 80 dup(?)
bytesToEnc dword ?
coded byte TRIPLE_BUFFER_SIZE dup (?)
code_to_output byte BUFFER_SIZE_PLUS_THREE dup (?)
output_string_len dword ?
bytesWritten dword ?


.data 
;outputFilename byte "outFile.txt",0 ; end of string 
error_outfile byte "Cannot create file",endl,0 ; line feed carriage return == CR 
error_infile byte "File not opened",endl,0
bytesWrittenstring byte "Bytes written to file : ",0
outputInterface byte "Enter name for output file [Enter]: ",endl,0
inputInterface byte "Enter name for input file [Enter]: ",endl,0
readError byte "Error reading a file ",endl,0
smallBuffer byte "Buffer too small for the input file",endl,0
fileSize byte endl,"Size of the file :  ", endl,0
doubleCR byte endl,endl,0
alphabet_iterator byte 60h
coded_alphas byte coded_a, coded_b, coded_c, coded_d, coded_e, coded_f, coded_g, coded_h, coded_i, coded_j, coded_k, coded_l, coded_m, coded_n, coded_o, coded_p, coded_q, coded_r, coded_s, coded_t, coded_u, coded_v, coded_w, coded_x, coded_y, coded_z
coded_fs byte coded_fullStop


.code

decryption proc c uses esi edi ecx edx,
			num_char_bytes:dword, iterator_decryption:dword

	mov eax,iterator_decryption
	mov eax,offset code_to_output
	mov eax,offset coded
	
	mov ecx,num_char_bytes
	xor esi,esi	; mov esi,0
	xor edi,edi

code_letters:
	xor eax,eax
	mov esi,iterator_decryption
	mov al,[esi]
	xor esi,esi
	cmp al,ascii_fullStop
	je full_stop_label_code

iterate_through_alphabet:
	inc esi
	inc alphabet_iterator
	cmp al,alphabet_iterator
	jne iterate_through_alphabet

	mov alphabet_iterator,60h	;resetting it for the next iteration
	mov al,coded_alphas[esi-1]

	jmp letter_found


full_stop_label_code:
	mov al,coded_fs
	;independent from the alphabet

letter_found:
	
	mov dl,al
	and al,30h
	shr al,4
	mov coded[edi],al
	inc edi
	mov al,dl
	and al,0ch
	shr al,2
	mov coded[edi],al
	inc edi 
	mov al,dl
	and al,03h
	mov coded[edi],al
	inc edi
	inc iterator_decryption
	; we are going to iterate through it just once
	loop code_letters
	;and of big loop

	xor esi,esi
	mov ecx,num_char_bytes
decode_loop:

	xor eax,eax
	xor edx,edx
	mov al,coded[esi]
	shl al,4
	or dl,al
	add esi,num_char_bytes
	mov al,coded[esi]
	shl al,2
	or dl,al
	add esi,num_char_bytes
	mov al, coded[esi]
	sub esi,num_char_bytes
	sub esi,num_char_bytes
	or dl,al
	mov al,dl
	;coded

	mov edi,-1
	cmp al,coded_fullStop
	je full_stop_label_decode
decode_alpha:
	inc edi	; here we change 
	cmp al,coded_alphas[edi]
	jne decode_alpha
	xor eax,eax
	mov al,61h
	add eax,edi
	jmp skip_full_stop
full_stop_label_decode:
	mov al,ascii_fullStop

skip_full_stop:
	mov code_to_output[esi+3],al

	inc esi
	loop decode_loop

	ret
decryption endp

encryption proc c uses esi edi ecx edx,
			 num_char_bytes:dword, iterator_encryption:dword
	mov eax,offset code_to_output
	mov eax,offset coded
	xor esi,esi
	xor edi,edi
	mov ecx,num_char_bytes
	
code_encryption:
	xor eax,eax
	mov esi,iterator_encryption
	inc iterator_encryption
	mov al, [esi]
	xor esi,esi
	cmp al,ascii_fullStop	; it's not similar to the ascii for the alphas, so special treatment
	je fullStoplabel

iterate_through_alphabet:
	inc esi	; here we change 
	inc alphabet_iterator
	cmp al,alphabet_iterator
	jne iterate_through_alphabet
	mov alphabet_iterator,60h	;reset the iterator on -1 state 
	mov al,coded_alphas[esi-1]
	jmp skip_full_stop_code

fullStopLabel:
	mov al,coded_fs

skip_full_stop_code:

	mov dl,al
	and al,30h
	shr al,4
	mov coded[edi],al
	add edi,num_char_bytes
	mov al,dl
	and al,0ch
	shr al,2
	mov coded[edi],al
	add edi,num_char_bytes
	mov al,dl
	and al, 03h
	mov coded[edi],al
	sub edi,num_char_bytes
	sub edi,num_char_bytes

	inc edi
	loop code_encryption

	xor esi,esi
	xor edi,edi
	mov ecx,num_char_bytes
decode_loop:
	xor eax,eax
	xor edx,edx
	mov al, coded[esi]
	shl al,4
	or dl,al
	inc esi
	mov al,coded[esi]
	shl al,2
	or dl,al
	inc esi
	mov al,coded[esi]
	inc esi
	or dl,al
	mov al,dl
	push esi 
	mov esi,-1
	cmp al,coded_fullStop
	je full_stop_decode
decode_alphas:
	inc esi	; here we change 
	cmp al,coded_alphas[esi]
	jne decode_alphas
	xor eax,eax
	mov al,61h	; ascii code for a
	add eax,esi
	jmp skip_full_stop_decode
full_stop_decode:
	mov al,ascii_fullStop

skip_full_stop_decode:
	pop esi
	mov code_to_output[edi+3],al
	inc edi
	;add iterator_encryption,1
	loop decode_loop; ecx should decrement

	; code to output is going to be used, we left 3 bytes at the start purposefully...
	ret
encryption endp

main proc 

	mov edx, offset outputInterface
	call WriteString
	mov edx, offset outputFilename
	mov ecx, sizeof outputFilename
	call ReadString

	mov edx, offset inputInterface
	call WriteString
	mov edx, offset inputFilename
	mov ecx, sizeof inputFilename ; sizeof and lengthof should be the same if the quantity is a byte
	call ReadString

	mov edx, offset inputFilename
	call OpenInputFile
	mov infileHandle, eax 

	; check if there was an error opening the file 
	cmp eax,INVALID_HANDLE_VALUE
	jne no_error1
	mov eax, offset readError 
	;call WriteString
	call WriteWindowsMsg
	jmp quit 

no_error1:

	mov edx, offset buffer ; where should it be written
	mov ecx, BUFFER_SIZE
	call ReadFromFile	; this is the actual READ CALL 
	jnc check_buffer_size ; checks how? if the carry flag is zero
	mov eax, offset readError
	call WriteString
	call WriteWindowsMsg
	jmp close_file

check_buffer_size:
	push eax
	sub eax,3
	mov bytesToEnc,eax
	pop eax
	cmp eax, BUFFER_SIZE
	jb buffSizeOK ; guess BUFFER_SIZE > eax than jump
	mov edx, offset smallBuffer
	call WriteString
	jmp quit ; this shall be a label at the end of the file 

buffSizeOK:
	mov buffer[eax],0 ; string terminator 
	mov edx, offset fileSize
	call WriteString
	call WriteDec
	call Crlf
	mov edx, offset doubleCR
	call WriteString
	mov edx, offset buffer
	call WriteString 
	call Crlf
	mov edx, offset doubleCR
	call WriteString

	mov eax, offset buffer
	add eax, 3
	push eax 
	push bytesToEnc
	
	xor eax,eax
	mov al, byte ptr buffer[0]
	cmp al,ascii_e
	je encrypt
	cmp al,ascii_d
	je decrypt 
	jmp close_file

decrypt:

	call decryption
	mov code_to_output, ascii_e
	jmp skip_encryption 

encrypt:
	
	call encryption
	mov code_to_output, ascii_d

skip_encryption:

	mov esi,1
	mov code_to_output[esi], 0dh
	inc esi
	mov code_to_output[esi], 0ah

	mov edx, offset outputFilename
	call CreateOutputFile
	mov outFileHandle,eax
	cmp eax,INVALID_HANDLE_VALUE
	jne file_ok
	mov edx, offset error_outfile
	call WriteString
	jmp quit
	
file_ok:
	mov eax,bytesToEnc
	add eax,3
	mov output_string_len,eax

	;Write the buffer to the output file.
	mov eax,outFileHandle
	mov edx,OFFSET code_to_output
	mov ecx,output_string_len
	call WriteToFile
	mov bytesWritten,eax ; save return value
	call CloseFile

	; Display the return value.
	mov edx,offset bytesWrittenstring ; "Bytes written"
	call WriteString
	mov eax,bytesWritten
	call WriteDec
	call Crlf
	call Crlf

close_file:
	mov eax,inFileHandle
	call CloseFile

quit:
	invoke ExitProcess,0

main endp
end main
