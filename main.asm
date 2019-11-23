.386
.model flat, stdcall
option casemap : none

; Includes
include \masm32\include\windows.inc
include \masm32\include\kernel32.inc
include \masm32\include\masm32.inc
include \masm32\include\masm32rt.inc

; librerias
includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\masm32.lib

.data
stringTamano DD 0
control DD 1
datosBuffer db 256 dup(0)
fileName DB "C:\Users\Akabane\Desktop\File.txt", 0
formatofecha db " dd/MM/yyyy ", 0
formatohora db "hh:mm:ss",13,10, 0
cadena DB 10, 13, "Ingrese texto para buscar", 10, 13, 0
Input1 db 10 DUP(0)
successCaption	DB "Done", 0

.data?
kb1	db 256 dup(? )
kb2	db 256 dup(? )
fechaBuf db 50 dup(? )
horaBuf db 50 dup(? )
fhandle DD ?
bytesWritten DD ?
bytesRead   DD ? 
bytesBuffer	BYTE 512 DUP(? )
cadenaLeida db 50 dup(?)

ExitProcess proto,dwExitCode:dword

.code
main proc
    ;//crear el archivo modo escritura
    push 0
    push FILE_ATTRIBUTE_NORMAL
    push CREATE_NEW
    push 0
    push 0
    push GENERIC_READ + GENERIC_WRITE
    push Offset fileName
    call CreateFile
    mov fhandle, eax ;//guardar apuntador al archivo

    ;// apuntar a buffer de datos
    lea esi, datosBuffer
    push esi                ;//guardar apuntador
    ;//apuntar a estado de teclado
    mov esi, offset kb1
    mov edi, offset kb2

    ;\\loop escuchar teclas
    .Repeat
        invoke GetKeyboardState, esi  ;//obtener tecla
            .Repeat
            invoke GetKeyState, VK_SHIFT ;//obtener estado de tecla
            invoke GetKeyboardState, edi
            mov ecx, 255
            push esi        ;//comparar esi y edi
            push edi
            repe cmpsb       ;//repeate until equal, compare string esi and edi store in ecx
            pop edi
            pop esi
            .Until sdword ptr ecx > 0    ;//repetir si tecla no ha sido presionada
        neg cl
        sub cl, 2
            ;// ignorar al soltar tecla
        mov ebx, control
        cmp ebx, 0
        je loop1
        .if ecx == VK_ESCAPE
            ;//escribir fin de archivo
            push fhandle
            call CloseHandle
            .break
        .elseif ecx == 1
            ;//ignorar la tecla mouse 1
        .elseif ecx == VK_SPACE || ecx == VK_RETURN
            ;//fecha
            INVOKE  GetDateFormat, 0, 0, \
            0, ADDR formatofecha, ADDR fechaBuf, 50
            MOV EBX, OFFSET fechaBuf
            MOV BYTE PTR[EBX - 1], " ";//Reemplazamos todo lo nulo con espacios
            INVOKE GetTimeFormat, 0, 0, \
            0, ADDR formatohora, ADDR horaBuf, 50
            ;//imprimir buffer
            invoke StdOut, addr datosBuffer
            INVOKE StdOut, ADDR fechaBuf
            INVOKE StdOut, ADDR horaBuf

                ;//escribir archivo
            push 0
            push Offset bytesWritten
            push stringTamano
            push Offset datosBuffer
            push fhandle
            call WriteFile

            push 0
            push Offset bytesWritten
            push 12
            push Offset fechaBuf
            push fhandle
            call WriteFile

            push 0
            push Offset bytesWritten
            push 10
            push Offset horaBuf
            push fhandle
            call WriteFile

                ;//reset index para iniciar buffer
            mov stringTamano, 0
            pop esi
            lea esi, datosBuffer;//resetear a la posicion inicial
            push esi

        .else
            ;//registrar tecla
            inc stringTamano ;//incremetar contador
            pop esi             ;//recuperar apuntador
            mov [esi], ecx      ;//guardar en buffer datos
            inc esi             ;//incrementar index
            mov eax, 0          
            mov [esi], eax      ;//limpiar el siguiente caracter en buffer datos
            push esi            ;guardar apuntador
            print str$(ecx), " fue presionado", 13, 10
        .endif
            ;// ignorar al soltar tecla
        jmp loop2
    loop1 :
        mov control, 2
    loop2 :
        dec control
    .Until 0

    ;//imprimir mensaje de busqueda
    INVOKE StdOut, addr cadena
    INVOKE StdIn, addr Input1, 10
    ;// cargar apuntadores a esi y edi
    lea esi, Input1
    lea edi, cadenaLeida

    ;// crear archivo en modo lectura
    push 0                              
    push FILE_ATTRIBUTE_NORMAL          
    push OPEN_EXISTING                  
    push 0                              
    push 0                              
    push GENERIC_READ                   
    push Offset fileName                
    call CreateFile                     
    mov  fhandle, Eax                   ;// guardar apuntador a archivo

    ;// continuar infinitamente
    mov Ecx, 1
    .while(Ecx != 0)

    ;// leer 1 caracter
    push 0                  
    lea  Eax, bytesRead     ;// apuntar a bytes read
    push Eax                ;// mandar a procedimiento		
    push 1                  ;// numero de caracteres a ller
    lea  Eax, bytesBuffer   ;// aputar a bytes buffer
    push Eax                ;// mandar a procedimiento
    push fhandle            ;// mandar apuntador de archivo
    call ReadFile           ;// llamar funcion
    cmp bytesRead, 0        ;// comparar
    je salir                ;// salir si los bytes leidos son 0
    lea Ebx, bytesBuffer    
    mov Ebx, [Ebx]          ;// cargar caracter en buffer a ebx

    .if Ebx == 10               ;// comparar si el valor es nueva linea
        ;//reset de index para comparar
        lea esi, Input1         
        lea edi, cadenaLeida
        comparar:    
            mov edx, [edi]
            cmp dl, 32          ;//comparar si es espacio
            je imprimir
            mov edx, [esi]
            mov ecx, [edi]
            cmp dl, cl          ;//comparar si los caracteres son iguales
            jne siguienteLinea
            inc esi
            inc edi
            jmp comparar
            ;//mostrar si la palabre fue encontrada
    imprimir:
        push MB_OK
        push Offset successCaption
        push Offset cadenaLeida
        push 0
        call MessageBox
        ;//continuar con la siguiente linea del archivo
    siguienteLinea :
        lea esi, Input1
        lea edi, cadenaLeida
    .else
        mov [edi], ebx  ;\\guardar caracter en buffer
        INC edi
    .endif

    .EndW

salir :
    ;// cerrar lectura
    push fhandle            
    call CloseHandle        
	invoke ExitProcess,0
main endp
end main