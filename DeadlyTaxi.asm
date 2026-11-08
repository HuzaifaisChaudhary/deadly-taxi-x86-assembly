include irvine32.inc

.data
equal_sign byte '='
wall       byte '|'              
space      byte ' '

board      byte 400 dup(0)              ;Board of 20*20
Tree       byte 182                     ; Obstacles
boxes      byte 208

CarIndex     DWORD 0                    ; --- Game State Variables ---
pass_pick    DWORD 0                    ; 0 = Empty 1 = Has Passenger
DestIndex    DWORD 0 
score        SDWORD 0                   ; Score counter


; ====== Leaderboard variables ======
LB_Scores    SDWORD 10 DUP(-200)      ; Array of scores to display on leaderboard(initially declared by value -200)
LB_Names     BYTE   10 * 30 DUP(0)    ; 10 names, 30 chars each

;====== Player car
TaxiColor    BYTE 14    
PlayerName   BYTE 30 DUP(0) 
NamePrompt   BYTE "Enter your Name: ", 0
ColorPrompt  BYTE "Select Taxi Color: (1). Yellow  (2) Red : ", 0

; ==== By default mode varibles of obstacles ====
CountBuildings DWORD 75
CountTrees     DWORD 30
CountBoxes     DWORD 15

; ==== Menu off front page ====
title_str      byte "==== Deadly TAXI GAME ====", 0
menu_1         byte "1] Start New Game", 0
menu_2         byte "2] Change Difficulty", 0
menu_3         byte "3] Instructions", 0
menu_4         byte "4] Leaderboard", 0      
menu_5         byte "5] Exit", 0             
opt_prompt     byte "Select an Option: ", 0

; Leaderboard Strings
lb_title       byte "=== HALL OF FAME ===", 0
lb_header      byte "RANK    SCORE     NAME", 0
lb_dot         byte ".      ", 0
lb_empty_msg   byte "No records yet.", 0

diff_title     byte "[==== SELECT DIFFICULTY ====]", 0
diff_1         byte "1] Easy ", 0
diff_2         byte "2] Medium ", 0
diff_3         byte "3] High ", 0

inst_title     byte "==== INSTRUCTIONS ====", 0
inst_1         byte "- Use W, A, S, D to move the taxi.", 0
inst_2         byte "- Pick up Passengers 'H' and drop them at Green Destinations.", 0
inst_4         byte "- Avoid Buildings (B), Trees, and Boxes. Score will deduct if you hit any obstacle", 0
inst_5         byte "- Do NOT try to pick up a second passenger while full (-5 Pts).", 0
inst_back      byte "Press '0' to go back...", 0

score_str      byte "Score: ", 0
player_lbl     byte "Driver: ", 0
drop_str       byte "[-]",0

lose_msg       byte "GAME OVER! YOU CRASHED.", 0
win_msg        byte "VICTORY! CAREER GOAL REACHED!", 0
final_score_msg byte "Final Score for ", 0 

; --- NEW VARIABLES FOR MODES & OBSTACLES ---
ModePrompt     byte "Select Mode: (1) Score Mode  (2) Endless Mode : ", 0
GameMode       DWORD 1    ; 1 = Score Mode (+/- 100), 2 = Endless
CountNPCs      DWORD 5    ; Number of static obstacle cars

.code
main proc
    call Randomize
                        ;=====================================================================================================================================
ShowMainMenu:           ;=======================================================> Main Menu page <============================================================
    mov eax, 128        ;=====================================================================================================================================
    call SetTextColor
    call Clrscr               

    mov dh, 5
    mov dl, 25
    call Gotoxy
    mov edx, offset title_str
    call WriteString

    mov dh, 8
    mov dl, 25
    call Gotoxy
    mov edx, offset menu_1
    call WriteString

    mov dh, 9
    mov dl, 25                ; Difficulty levoool
    call Gotoxy
    mov edx, offset menu_2
    call WriteString

    mov dh, 10
    mov dl, 25
    call Gotoxy               ; INstructions
    mov edx, offset menu_3
    call WriteString
    
    mov dh, 11
    mov dl, 25
    call Gotoxy
    mov edx, offset menu_4    ; Leaderboard
    call WriteString

    mov dh, 12
    mov dl, 25
    call Gotoxy
    mov edx, offset menu_5    ; Exit (escape the matrix)
    call WriteString

    mov dh, 15
    mov dl, 25
    call Gotoxy                ; writing (select an option) 
    mov edx, offset opt_prompt
    call WriteString

    call ReadChar
    cmp al, '1'
    je TaxiSelectionMenu    
    cmp al, '2'
    je DifficultyMenu
    cmp al, '3'
    je InstructionsMenu
    cmp al, '4'
    je ShowLeaderboardMenu  
    cmp al, '5'
    je QuitProgramFull
    jmp ShowMainMenu


ShowLeaderboardMenu:           ;======================================= Leaderboard page ================================================
    mov eax, 95                ; purple Background
    call SetTextColor
    call Clrscr

    mov dh, 3
    mov dl, 25                 
    call Gotoxy
    mov edx, offset lb_title   ; displaying title
    call WriteString

    mov dh, 5
    mov dl, 15
    call Gotoxy
    mov edx, offset lb_header
    call WriteString

    ; ==== SCORES LOOP =====
    mov ecx, 10         ; Loop 10 times
    mov ebx, 0          ; Array Index (0 to 9)
    mov dh, 7           ; Start printing at Row 7

PrintLBLoop:
    push ecx            ; Save loop counter
    
    ; Check if score is empty (-200)
    mov eax, LB_Scores[ebx*4]
    cmp eax, -200
    je SkipPrint        

    ; 1. Print Rank (ebx + 1)
    mov dl, 15
    call Gotoxy
    mov eax, ebx
    inc eax
    call WriteDec
    mov edx, offset lb_dot
    call WriteString
    call crlf

    ;==> 2. Print Score
    mov dl, 22
    call Gotoxy
    mov eax, LB_Scores[ebx*4]
    call WriteInt
    ;==> printing space
    ;==> 3. Print Name
    mov dl, 35
    call Gotoxy
    
    mov eax, 30          ; ==> Size of one name
    mul ebx             
    mov esi, offset LB_Names
    add esi, eax        ; ESI points to the name string
    mov edx, esi
    call WriteString
   
    inc dh              
SkipPrint:
    inc ebx            
    pop ecx             
    loop PrintLBLoop

    mov dh, 20          ;==> ending index of the page
    mov dl, 20
    call Gotoxy
    mov edx, offset inst_back
    call WriteString

WaitLB:
    call ReadChar
    cmp al, '0'
    je ShowMainMenu
    jmp WaitLB
                                         ;=====================================
                                         ;=====================================
TaxiSelectionMenu:                       ;============ Taxi Menu ==============
                                         ;=====================================
    mov eax, 47                          ;=====================================
    call SetTextColor
    call Clrscr

    mov dh, 5
    mov dl, 20
    call Gotoxy
    mov edx, offset NamePrompt
    call WriteString
    mov edx, offset PlayerName
    mov ecx, 29        ;  =-=-=->            Taking name data from the user
    call ReadString

    mov dh, 7
    mov dl, 20
    call Gotoxy
    mov edx, offset ColorPrompt
    call WriteString
WaitColor:
    call ReadChar
    cmp al, '1'
    je SetYellow
    cmp al, '2'
    je SetRed
    jmp WaitColor

SetYellow:
    mov TaxiColor, 14 
    jmp SelectModeMenu
SetRed:
    mov TaxiColor, 12  
    jmp SelectModeMenu

SelectModeMenu:
    mov dh, 9
    mov dl, 20
    call Gotoxy
    mov edx, offset ModePrompt
    call WriteString
WaitMode:
    call ReadChar
    cmp al, '1'
    je SetScoreMode
    cmp al, '2'
    je SetEndlessMode
    jmp WaitMode

SetScoreMode:
    mov GameMode, 1
    jmp StartNewGame
SetEndlessMode:
    mov GameMode, 2
    jmp StartNewGame

                                    ; =================================================================================================================
                                    ;             ==================================== DIFFICULTY LEV00L MENU =============================
                                    ; =================================================================================================================
DifficultyMenu:
    mov eax, 48 
    call SetTextColor
    call Clrscr
                                    ; Containing all the instructions regarding difficulty level menu ie: drawing function as awell as cout functionality
    mov dh, 5
    mov dl, 25
    call Gotoxy
    mov edx, offset diff_title
    call WriteString

    mov dh, 7
    mov dl, 25
    call Gotoxy
    mov edx, offset diff_1
    call WriteString

    mov dh, 8
    mov dl, 25
    call Gotoxy
    mov edx, offset diff_2
    call WriteString

    mov dh, 9
    mov dl, 25
    call Gotoxy
    mov edx, offset diff_3
    call WriteString

    call ReadChar
    cmp al, '1'
    je SetEasy
    cmp al, '2'
    je SetMedium
    cmp al, '3'
    je SetHard
    jmp DifficultyMenu

SetEasy:
    mov CountBuildings, 30    
    mov CountTrees, 15
    mov CountBoxes, 10
    mov CountNPCs, 3          
    jmp ShowMainMenu
SetMedium:
    mov CountBuildings, 55    
    mov CountTrees, 27
    mov CountBoxes, 15
    mov CountNPCs, 5          
    jmp ShowMainMenu
SetHard:
    mov CountBuildings, 100   
    mov CountTrees, 40
    mov CountBoxes, 25
    mov CountNPCs, 8          
    jmp ShowMainMenu

; =========================================================================================================================================================
; ===========================================================> INSTRUCTIONS MENU <=========================================================================
; =========================================================================================================================================================

InstructionsMenu:                            ; This function is showing the instruction menu containing all the instructions
    mov eax, 16 + 15   
    call SetTextColor
    call Clrscr
    mov dh, 5
    mov dl, 20
    call Gotoxy
    mov edx, offset inst_title
    call WriteString
    mov dh, 7
    mov dl, 10
    call Gotoxy
    mov edx, offset inst_1
    call WriteString
    mov dh, 8
    mov dl, 10
    call Gotoxy
    mov edx, offset inst_2
    call WriteString
    mov dh, 9
    mov dl, 10
    call Gotoxy
    mov dh, 10
    mov dl, 10
    call Gotoxy
    mov edx, offset inst_4
    call WriteString
    mov dh, 11
    mov dl, 10
    call Gotoxy
    mov edx, offset inst_5
    call WriteString
    mov dh, 14
    mov dl, 10
    call Gotoxy
    mov edx, offset inst_back
    call WriteString
WaitBack:
    call ReadChar
    cmp al, '0'
    je ShowMainMenu
    jmp WaitBack

; =========================================================================================================================================================
; ======================================================================> THE GAME <=======================================================================
; =========================================================================================================================================================
StartNewGame:
    mov score, 0
    mov pass_pick, 0
    mov CarIndex, 0 
    
    mov ecx, 400
    mov esi, offset board
ClearLoop:
    mov byte ptr [esi], 0
    inc esi
    loop ClearLoop

    mov ecx, CountBuildings
gen_build:
    call randomizing              
    mov esi , offset board       ; ==> generating all the values in the array to further draw according to this final array which initially 0.
    add esi , eax
    mov byte ptr [esi] , 1    
    loop gen_build

    mov ecx, CountTrees
gen_tree:
    call randomizing
    mov esi , offset board
    add esi , eax
    cmp byte ptr [esi] , 0 
    jne gen_tree
    mov byte ptr [esi] , 2    
    loop gen_tree

    mov ecx, CountBoxes
gen_box:
    call randomizing
    mov esi , offset board
    add esi , eax
    cmp byte ptr [esi] , 0    
    jne gen_box                         
    mov byte ptr [esi] , 3
    loop gen_box

    mov ecx, CountNPCs
gen_npc:
    call randomizing
    mov esi, offset board
    add esi, eax
    cmp byte ptr [esi], 0
    jne gen_npc
    mov byte ptr [esi], 5     
    loop gen_npc

    mov ecx , 5
gen_pass:                   ;==> generating passenger
    call randomizing
    mov esi , offset board
    add esi , eax
    cmp byte ptr [esi] , 0
    jne gen_pass                        
    mov byte ptr [esi] , 8    
    loop gen_pass

    mov edi , offset board
    mov byte ptr [edi] , 0
    mov byte ptr [edi + 1] , 0
    mov byte ptr [edi + 21] , 0
    mov byte ptr [edi + 22] , 0
    mov ebx, 0                      

    mov eax, 0 ; Black Background
    call SetTextColor
    call Clrscr 


    mov edi , offset board
    mov ecx , 400
starting:                                   ;==================================================
    mov al , [edi]                          ;||                   Drawing Board              ||
    mov edx , 3                             ;==================================================
    cmp al , 0
    je empty
    cmp al , 1
    je buildings_draw
    cmp al , 2
    je tree_draw
    cmp al , 3
    je box_draw
    cmp al , 5
    je npc_draw
    cmp al , 8
    je passenger_draw
    cmp al , 9          
    je destination_draw

empty:
    mov eax , 176
    call setTextcolor
    mov al , space                
    call writechar
    dec edx
    cmp edx , 0
    jnz empty
    jmp check
buildings_draw:
    mov eax , 16
    call setTextcolor
    mov al , 'B'                  
    call writechar
    dec edx
    cmp edx , 0
    jnz buildings_draw
    jmp check
tree_draw:
    mov eax , 32
    call setTextcolor
    mov al , tree
    call writechar
    dec edx
    cmp edx , 0
    jnz tree_draw
    jmp check
box_draw:
    mov eax , 48
    call setTextcolor
    mov al , boxes
    call writechar
    dec edx
    cmp edx , 0
    jnz box_draw
    jmp check
npc_draw:
    mov eax , 100 
    call setTextcolor
    mov al , 'o'
    call writechar
    mov al , 'M'
    call writechar
    mov al , 'o'
    call writechar
    jmp check
passenger_draw:
    mov eax, 13         
    call SetTextColor
    mov al , '-'
    call writechar
    mov al , 'H'
    call writechar
    mov al , '-'
    call writechar
    mov edx , 0
    jmp check
destination_draw:       
    mov eax, 34         
    call SetTextColor
    mov al, 178         
    call WriteChar
    mov al, 178
    call WriteChar
    mov al, 178
    call WriteChar
    mov edx, 0
    jmp check

check:
    mov eax, 7          
    call SetTextColor
    mov al , wall                 
    call writechar
    inc edi
    inc bl
    cmp bl, 20                    
    je row_inc
back:
    dec ecx         
    jnz starting
    jmp game_loop              

row_inc:
    inc bh
    mov bl , 0
    mov eax , 78
    call settextcolor
    call crlf
    jmp back
    
; ===========================================================================================================================================================
; ===================================================================>> GAME LOOP <<=========================================================================
; ===========================================================================================================================================================
game_loop:
    mov dh , 22  
    mov dl , 32  
    call gotoxy
    mov eax, 15        
    call SetTextColor
    mov edx , offset score_str
    call writestring
    mov eax , score
    call writeint

    mov dh, 23
    mov dl, 32
    call Gotoxy
    mov edx, offset player_lbl
    call WriteString
    mov edx, offset PlayerName
    call WriteString

    mov dh , 0
    mov dl , 0
    call gotoxy
    call drawcar
    
InputLoop:
    call ReadChar       
    mov ebx, CarIndex   

    cmp al, 'w'
    je MoveUp
    cmp al, 's'
    je MoveDown
    cmp al, 'a'
    je MoveLeft
    cmp al, 'd'
    je MoveRight
    cmp al, 'x'         
    je quit_to_menu_manual
    cmp al , 'p'
    je pause_game
    jmp InputLoop       
pause_game:
    call readchar
    cmp al , 'p'
    jne pause_game
    jmp inputloop
MoveUp:                               ;====> movement of the game
    sub ebx, 20         
    cmp ebx, 0          
    jl InputLoop        
    jmp CheckCollision
MoveDown:
    add ebx, 20         
    cmp ebx, 399
    jg InputLoop        
    jmp CheckCollision
MoveLeft:
    mov eax, CarIndex
    mov edx, 0
    mov ecx, 20
    div ecx             
    cmp edx, 0          
    je InputLoop
    sub ebx, 1          
    jmp CheckCollision
MoveRight:
    mov eax, CarIndex
    mov edx, 0
    mov ecx, 20
    div ecx             
    cmp edx, 19         
    je InputLoop
    add ebx, 1          
    jmp CheckCollision

CheckCollision:                            ;===> collision check function
    mov esi, offset board
    add esi, ebx        
    mov al, [esi]       

    cmp al, 1
    je score_deduc_build
    cmp al, 2
    je score_deduc_tree
    cmp al, 3
    je score_deduc_box
    cmp al, 5
    je score_deduc_npc
    cmp al, 9
    je passenger_droped
    cmp al, 8
    je PickUpPassenger
    jmp MoveValid

score_deduc_build:
    sub score , 4
    jmp CheckLossCondition
score_deduc_box:
    sub score , 2
    jmp CheckLossCondition
score_deduc_tree:
    sub score , 5
    jmp CheckLossCondition
score_deduc_npc:
    sub score , 10       
    jmp CheckLossCondition

CheckLossCondition:
    
    cmp score, -100
    jle quit_game_lose
    jmp InputLoop           

passenger_droped:
    cmp pass_pick, 1
    jne MoveValid           
    add score , 10          
    mov pass_pick, 0        
    mov byte ptr [esi], 0   
    
    cmp GameMode, 2
    je RespawnPass
    
    cmp score, 100          
    jge quit_game_win
    
RespawnPass:
    call SpawnNewPassenger
    jmp MoveValid

PickUpPassenger:
    cmp pass_pick, 1        
    je FullPassengerPenalty 
    mov byte ptr [esi], 0   
    mov pass_pick , 1       
    call GenerateDestination
    jmp MoveValid

FullPassengerPenalty:
    sub score, 5            
    jmp CheckLossCondition

MoveValid:
    call EraseCar       
    mov CarIndex, ebx   
    call DrawCar        
    jmp game_loop       

; ===========================================================================================================================================================
; ==================================================================>ENDING SCREENS<=========================================================================
; ===========================================================================================================================================================

quit_to_menu_manual:
    call UpdateLeaderboard
    jmp ShowMainMenu

quit_game_lose:
    mov eax, 79
    mov edx, offset lose_msg 
    jmp display_end_screen

quit_game_win:
    mov eax, 31
    mov edx, offset win_msg  
    jmp display_end_screen

display_end_screen:
    call UpdateLeaderboard

    call SetTextColor
    call Clrscr              

    mov dh, 10
    mov dl, 20
    call Gotoxy
    call WriteString 

    mov dh, 12
    mov dl, 15
    call Gotoxy
    
    push edx            
    mov edx, offset final_score_msg
    call WriteString
    
    mov edx, offset PlayerName
    call WriteString
    
    mov al, ':'
    call WriteChar
    mov al, ' '
    call WriteChar

    mov eax, score
    call WriteInt
    pop edx             
    
    call ReadChar
    jmp ShowMainMenu

QuitProgramFull:
    exit
main endp                            ;=========================================================================================================
                                     ;                =======================================================================
                                     ;                           ================= PROCEDURES =================
                                     ;                =======================================================================
                                     ;=========================================================================================================
; --- LEADERBOARD UPDATE & SORT ---
UpdateLeaderboard PROC
    pushad
    
    ; 1. Find Empty Slot
    mov ecx, 10
    mov ebx, 0
FindSlot:
    cmp LB_Scores[ebx*4], -200
    je FoundSlot
    inc ebx
    loop FindSlot
    mov ebx, 9  ; If full, replace last one
FoundSlot:
    ; 2. Save Score
    mov eax, score
    mov LB_Scores[ebx*4], eax

    ; 3. Save Name
    mov eax, 30
    mul ebx
    mov edi, offset LB_Names
    add edi, eax        
    mov esi, offset PlayerName
    mov ecx, 29         
CopyName:
    mov al, [esi]
    mov [edi], al
    inc esi
    inc edi
    loop CopyName
    
    call SortLeaderboard
    popad
    ret
UpdateLeaderboard ENDP

SortLeaderboard PROC
    ; Bubble Sort (High to Low)
    pushad
    mov ecx, 9          
OuterLoop:
    push ecx
    mov esi, 0          
InnerLoop:
    mov eax, LB_Scores[esi*4]
    mov ebx, LB_Scores[esi*4 + 4] 
    
    cmp eax, ebx        
    jge NoSwap          

    ; Swap Scores
    mov LB_Scores[esi*4], ebx
    mov LB_Scores[esi*4 + 4], eax

    ; Swap Names (30 bytes)
    push esi
    push ecx
    
    mov eax, 30
    mul esi
    mov edi, offset LB_Names
    add edi, eax        ; Name 1
    
    mov ebx, edi
    add ebx, 30         ; Name 2
    
    mov ecx, 30         
SwapBytes:
    mov al, [edi]
    mov dl, [ebx]
    mov [edi], dl
    mov [ebx], al
    inc edi
    inc ebx
    loop SwapBytes
    
    pop ecx
    pop esi

NoSwap:
    inc esi
    loop InnerLoop
    pop ecx             
    loop OuterLoop
    popad
    ret
SortLeaderboard ENDP

SpawnNewPassenger PROC
    pushad
SpawnLoop:
    mov eax, 400
    call RandomRange    
    mov edx, eax        
    mov esi, offset board
    add esi, eax
    cmp byte ptr [esi], 0
    jne SpawnLoop       
    cmp eax, CarIndex
    je SpawnLoop
    mov byte ptr [esi], 8   
    mov eax, edx
    mov ecx, 20
    mov edx, 0
    div ecx             
    mov dh, al          
    mov al, dl          
    mov bl, 4
    mul bl              
    mov dl, al          
    call Gotoxy
    mov eax, 13         
    call SetTextColor
    mov al , '-'
    call writechar
    mov al , 'H'
    call writechar
    mov al , '-'
    call writechar
    popad
    ret
SpawnNewPassenger ENDP

GenerateDestination PROC
    pushad
GenLoop:
    mov eax, 400
    call RandomRange    
    mov edx, eax        
    mov esi, offset board
    add esi, eax        
    cmp byte ptr [esi], 0
    jne GenLoop         
    cmp eax, CarIndex
    je GenLoop
    mov byte ptr [esi], 9   
    mov DestIndex, eax      
    mov eax, edx
    mov ecx, 20
    mov edx, 0
    div ecx             
    mov dh, al          
    mov al, dl          
    mov bl, 4
    mul bl              
    mov dl, al          
    call Gotoxy
    mov eax, 34         
    call SetTextColor
    mov edx, offset drop_str
    call WriteString
    popad
    ret
GenerateDestination ENDP

randomizing proc
    mov eax , 400                                     
    call randomrange
    ret
randomizing endp

DrawCar PROC
    pushad              
    mov edx, 0
    mov eax, CarIndex
    mov ecx, 20
    div ecx             
    mov dh, al          
    mov eax, edx        
    mov bl, 4           
    mul bl              
    mov dl, al          
    call Gotoxy         
    
    cmp pass_pick, 1
    je FullCar
    movzx eax, TaxiColor  
    add eax, 0            
    jmp DrawIt

FullCar:
    mov eax, 11 + (0*16) 

DrawIt:
    call SetTextColor
    mov al, 'o'
    call WriteChar
    mov al, 'M'
    call WriteChar
    mov al, 'o'
    call WriteChar
    popad               
    ret
DrawCar ENDP

EraseCar PROC
    pushad
    mov edx, 0
    mov eax, CarIndex
    mov ecx, 20
    div ecx 
    mov dh, al
    mov eax, edx
    mov bl, 4
    mul bl
    mov dl, al
    call Gotoxy
    mov esi, offset board
    add esi, CarIndex
    cmp byte ptr [esi], 9
    je RedrawDest
    mov eax, 176        
    call SetTextColor
    mov al, ' '         
    call WriteChar
    call WriteChar
    call WriteChar
    jmp FinishErase
RedrawDest:
    mov eax, 34         
    call SetTextColor
    mov edx, offset drop_str
    call WriteString
FinishErase:
    popad
    ret
EraseCar ENDP
end main