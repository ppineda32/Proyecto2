;// AddTwo.asm - adds two 32-bit integers.
;// Chapter 3 example

.386
.model flat, stdcall
.stack 4096

include \masm32\include\masm32rt.inc

.data?
kb1	db 256 dup(? )
kb2	db 256 dup(? )

ExitProcess proto,dwExitCode:dword

.code
main proc
     mov esi, offset kb1
     mov edi, offset kb2
     .Repeat
          invoke GetKeyboardState, esi
               .Repeat
               invoke Sleep, 1
               invoke GetKeyState, VK_SHIFT
               invoke GetKeyboardState, edi
               mov ecx, 255
               push esi
               push edi
               repe cmpsb
               pop edi
               pop esi
               .Until sdword ptr ecx > 0
          neg cl
          sub cl, 2
          .Break .if ecx == VK_ESCAPE
          print str$(ecx), " was pressed", 13, 10
     .Until 0
     print "bye"

	invoke ExitProcess,0
main endp
end main