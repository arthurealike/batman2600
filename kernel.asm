  processor 6502

  include "vcs.h"
  include "macro.h"

  SEG.U Variables
  org $80

P0PosX         byte        
P0PosY         byte        
P1PosX         byte        
P1PosY         byte   

BatSpritePtr   word        ; pointer to p0 sprite table
BatColorPtr    word        ; pointer to p0 color lookup table
JSpritePtr     word        ; pointer to p1 sprite lookup table
JColorPtr      word        ; pointer to p1 color lookup table

;TODO
;anim, scrolling, enemies,score

; for scoreboard
Second ds
Minute ds
FontBuf ds

; constants
BAT_HEIGHT = #$10          	     
J_HEIGHT = #$10          
Temp = $8D
CurrentFrame = $8F
Counter = #$0
ScrollSpeed = #1
AnimOffset = #0
IsJumping ds
IsGround ds
IsFalling = $90
IsAnimating = #1

    SEG code
    org $F000

Reset:  ldx #0
        txa

Clear   dex
        txs
        pha
        bne Clear  

Init        
; init ram & tia registers
    lda #0
    sta IsFalling
    sta IsJumping
 
    lda #25
    sta P0PosY          
    lda #25
    sta P0PosX         
    lda #10
    sta P1PosY
    lda #54
    sta P1PosX       
    
    lda #00
    sta Temp
    
InitPointers

    lda #<BatSprite
    sta BatSpritePtr         ; lo-byte ptr for sprite
    lda #>BatSprite
    sta BatSpritePtr+1       ; hi-byte ptr for  " 

    lda #<BatColor
    sta BatColorPtr          
    lda #>BatColor
    sta BatColorPtr+1        

    lda #<JSprite
    sta JSpritePtr      
    lda #>JSprite
    sta JSpritePtr+1    

    lda #<JColor
    sta JColorPtr       
    lda #>JColor
    sta JColorPtr+1
    
    jmp StartNewFrame
    ;channel 0

; Make sound subroutines

;pass a, x ,y
MakeSoundC0
  sta AUDV0
  stx AUDF0
  sty AUDC0 
  rts

    ;channel 1
MakeSoundC1
  sta AUDV1
  stx AUDF1
  sty AUDC1 
  rts
  
GetBCDBitmap subroutine
; First fetch the bytes for the 1st digit
  pha
  and #$0F 
  sta Temp 
  asl
  asl
  adc Temp 
  tay
  lda #5 
  sta Temp
; save original BCD number
; mask out the least significant digit
; multiply by 5 ;->Y
; count down from 5
.loop1
  lda DigitsBitmap,y
  and #$0F
  sta FontBuf,x 
  iny
  inx
  dec Temp
  bne .loop1
; Now do the 2nd digit
        pla
        lsr
        lsr
        lsr
; mask out leftmost digit
; store leftmost digit
; restore original BCD number
 rts

StartNewFrame
  lda Counter+1
  sta Counter  
  
Vsync
  lda #2 
  sta VSYNC ;3
  sta WSYNC            
  sta WSYNC            
  sta WSYNC            
  lda #0
  sta VSYNC               

  lda  #43          ; 2 cycles
  sta  TIM64T       ; 4 cycles 
 ;; 2785 cycles Free   

 ;; START ;;  
  inc Temp          ; Scroll Speed
  lda Temp
  cmp #ScrollSpeed     
  bne Scroll_End
  lda #$00
  sta Temp 

  ldx #30
  ;jmp Scroll_End
  
  ;lda #1
  ;cmp IsJumping

CheckJumping
  lda IsJumping
  cmp #1
  bcc .ApplyGravity
.ApplyJumpForce
  lda #40
  cmp P0PosY
  beq .ApplyGravity
  inc P0PosY
  jmp VBlank

.ApplyGravity
  lda #0
  sta IsJumping
  lda #0
  sta IsFalling
  lda #25
  cmp P0PosY
  beq VBlank
  dec P0PosY   
  lda #1
  sta IsFalling
  
  
Scroll
  lsr #Screen_PF2-1,X   ; Scroll Line X-1 (= 3-0)
  rol #Screen_PF1-1,X
  ror #Screen_PF0-1,X
  lda #Screen_PF0-1,X
  and #%00001000
  beq Scroll_1   
  lda #Screen_PF2-1,X            
  ora #%10000000      
  sta #Screen_PF2-1,X
Scroll_1               
  dex
  bne Scroll
Scroll_End           
  
  
  ;; END  ;;
  
  
VBlank
   lda INTIM        ; 4 cycles
   bpl VBlank       ; 3 cycles (2)
   sta WSYNC        ; 3 cycles  Total Amount = 21 cycles                         ; 2812-21 = 2791; 2791/64 = 43.60 (TIM64T)

   lda #0 
   sta VBLANK       ; Enable TIA Output

; visible 192 lines
GameVisibleLine
  lda #$00          ; Clear Playfield
  sta PF0
  sta PF1
  sta PF2	

  sta WSYNC

  ldx #96           ; visible scanlines
.GameLineLoop:      ; . local

.LeftSidePF	
      ; left side pf
      lda Screen_PF0-1,X
      sta PF0
      ; ror PF0
      lda Screen_PF1-1,X
      sta PF1
      ; rol PF1
      lda Screen_PF2-1,X
      sta PF2

.IsRoadVisible  
      cpx #26
      ;SLEEP 6
      beq .DrawRoad
      ; TODO
      jmp .RightSidePF
;once
.DrawRoad
      sta WSYNC

      lda #$09
      sta COLUPF
      lda #$02
      sta COLUBK             ; bg

; right side pf    
.RightSidePF
.YellowPF        
     ; lda #$E7
     ; sta COLUPF   

;	lda Screen_PF3-1,X
;	sta PF0
;	lda Screen_PF4-1,X
;	sta PF1
;	lda Screen_PF5-1,X
      ;sta PF2

  ; lda #$0
  ; sta COLUPF

;TODO
.IsP0Visible:                ; check if should render p0
    txa                      ; X to A
    sec                      ; carry flag is set
    sbc P0PosY               ; subtract sprite Y coordinate
    cmp BAT_HEIGHT           ; sprite inside height bounds?
    bcc .DrawSpriteP0        ; if result < SpriteHeight, call subroutine
    lda #0                   ; else, set lookup index to 0
.DrawSpriteP0:
   clc                       ; clear carry flag 
  ;adc AnimOffset           ; jump to sprite frame 
   tay                       ; load Y so we can work with pointer

   lda (BatSpritePtr),Y      ; load player bitmap slice of data
   sta GRP0                  ; set graphics for player 0
   lda (BatColorPtr),Y       ; load player color from lookup table
   sta COLUP0                ; set color for player 0 slice       bne .RightSidePF

   sta HMCLR
   sta WSYNC                 ; wait for next scanline

   dex 

   sta WSYNC
   bne .GameLineLoop   

   lda #%00000010 	     ; Disable VIA Output
   sta VBLANK 
   
; overscan
Overscan:

  lda #0
  sta CTRLPF
  lda #$01
  sta COLUPF

  lda #$A0
  sta COLUBK

  ; silent
  lda #0
  sta AUDV0
  sta AUDF0
  sta AUDC0

  REPEAT 30
    sta WSYNC            
  REPEND

  lda #0
  sta VBLANK 
  sta WSYNC
  lda #$A0
  ; turn off VBLANK

; handle Inputs
CheckP0Up:
  lda #%00010000
  bit SWCHA
  bne CheckP0Down
 
  ; make sound 
  lda #1
  sta AUDV0
  sta AUDF0
  sta AUDC0
  
  lda #1
  cmp IsFalling
  
  beq CheckP0Down
  sta IsJumping  
  
  ;inc P0PosY 
  ;; write here

CheckP0Down:
  lda #%00100000
  bit SWCHA
  bne CheckP0Left
  lda #25
  cmp P0PosY
  beq CheckP0Left
  dec P0PosY 
  ;; write here

CheckP0Left:
  lda #%01000000
  bit SWCHA
  bne CheckP0Right
  lda #20
  cmp P0PosX
  beq .MinX
  
  dec P0PosX
.MinX
  lda #%11111111
  sta REFP0 
  ;; write here

CheckP0Right:
  lda #%10000000
  bit SWCHA
  bne Nil
  lda #90
  cmp P0PosX
  beq .MaxX
  inc P0PosX
.MaxX
  lda #0
  sta REFP0
  ;; write here

Nil:    ; if input is nil
  lda P0PosX
  ldx #0
  jsr SetHorizontal

  ; move P0
  lda P0PosX
  ldx #1
  jsr SetHorizontal

  sta WSYNC
  sta HMOVE 

  jmp StartNewFrame           ; next frame

; pass A, X registers to subroutine
; A as destination, X as sprite
SetHorizontal subroutine
    sec
    sta WSYNC
.DivLoop
   sbc #15 ; #15
   bcs .DivLoop

   eor #7 ; #7
   asl
   asl
   asl
   asl
   sta HMP0,Y
   sta RESP0,Y
   rts

; ROM lookup tables

; pfx line by line
Screen_PF0
      .byte #%00000000	; Scanline 191
      .byte #%00000000	; Scanline 190
      .byte #%00000000	; Scanline 189
      .byte #%00000000	; Scanline 188
      .byte #%00000000	; Scanline 187
      .byte #%00000000	; Scanline 186
      .byte #%00000000	; Scanline 185
      .byte #%00000000	; Scanline 184
      .byte #%00000000	; Scanline 183
      .byte #%00000000	; Scanline 182
      .byte #%00000000	; Scanline 181
      .byte #%00000000	; Scanline 180
      .byte #%00000000	; Scanline 179
      .byte #%11000000	; Scanline 178
      .byte #%00000000	; Scanline 177
      .byte #%00000000	; Scanline 176
      .byte #%00000000	; Scanline 175
      .byte #%00000000	; Scanline 174
      .byte #%00000000	; Scanline 173
      .byte #%00000000	; Scanline 172
      .byte #%00000000	; Scanline 171
      .byte #%00000000	; Scanline 170
      .byte #%00000000	; Scanline 169
      .byte #%00000000	; Scanline 168
      .byte #%00000000	; Scanline 167
      .byte #%11110000	; Scanline 166
      .byte #%11110000	; Scanline 165
      .byte #%11110000	; Scanline 164
      .byte #%11110000	; Scanline 163
      .byte #%11110000	; Scanline 162
      .byte #%11110000	; Scanline 161
      .byte #%11110000	; Scanline 160
      .byte #%11110000	; Scanline 159
      .byte #%11110000	; Scanline 158
      .byte #%11110000	; Scanline 157
      .byte #%11110000	; Scanline 156
      .byte #%11110000	; Scanline 155
      .byte #%11110000	; Scanline 154
      .byte #%11110000	; Scanline 153
      .byte #%11110000	; Scanline 152
      .byte #%11110000	; Scanline 151
      .byte #%11110000	; Scanline 150
      .byte #%11110000	; Scanline 149
      .byte #%11110000	; Scanline 148
      .byte #%11110000	; Scanline 147
      .byte #%11110000	; Scanline 146
      .byte #%11110000	; Scanline 145
      .byte #%11110000	; Scanline 144
      .byte #%11110000	; Scanline 143
      .byte #%11110000	; Scanline 142
      .byte #%11110000	; Scanline 141
      .byte #%11110000	; Scanline 140
      .byte #%11110000	; Scanline 139
      .byte #%11110000	; Scanline 138
      .byte #%11110000	; Scanline 137
      .byte #%11110000	; Scanline 136
      .byte #%11110000	; Scanline 135
      .byte #%11110000	; Scanline 134
      .byte #%11110000	; Scanline 133
      .byte #%11110000	; Scanline 132
      .byte #%11110000	; Scanline 131
      .byte #%11110000	; Scanline 130
      .byte #%11110000	; Scanline 129
      .byte #%11110000	; Scanline 128
      .byte #%11110000	; Scanline 127
      .byte #%11110000	; Scanline 126
      .byte #%11110000	; Scanline 125
      .byte #%11110000	; Scanline 124
      .byte #%11110000	; Scanline 123
      .byte #%11110000	; Scanline 122
      .byte #%11110000	; Scanline 121
      .byte #%11110000	; Scanline 120
      .byte #%11110000	; Scanline 119
      .byte #%00110000	; Scanline 118
      .byte #%00110000	; Scanline 117
      .byte #%00110000	; Scanline 116
      .byte #%00110000	; Scanline 115
      .byte #%00110000	; Scanline 114
      .byte #%00110000	; Scanline 113
      .byte #%00110000	; Scanline 112
      .byte #%00000000	; Scanline 111
      .byte #%00000000	; Scanline 110
      .byte #%00000000	; Scanline 109
      .byte #%00000000	; Scanline 108
      .byte #%00000000	; Scanline 107
      .byte #%00000000	; Scanline 106
      .byte #%00000000	; Scanline 105
      .byte #%00000000	; Scanline 104
      .byte #%00000000	; Scanline 103
      .byte #%00000000	; Scanline 102
      .byte #%00000000	; Scanline 101
      .byte #%00000000	; Scanline 100
      .byte #%00000000	; Scanline 99
      .byte #%00000000	; Scanline 98
      .byte #%00000000	; Scanline 97
      .byte #%00000000	; Scanline 96

Screen_PF1
      .byte #%00000000	; Scanline 191
      .byte #%00000000	; Scanline 190
      .byte #%00000000	; Scanline 189
      .byte #%00000000	; Scanline 188
      .byte #%00000000	; Scanline 187
      .byte #%00000000	; Scanline 186
      .byte #%00000000	; Scanline 185
      .byte #%00000000	; Scanline 184
      .byte #%00000000	; Scanline 183
      .byte #%00000000	; Scanline 182
      .byte #%00000000	; Scanline 181
      .byte #%00000000	; Scanline 180
      .byte #%00000000	; Scanline 179
      .byte #%11000111	; Scanline 178
      .byte #%00000000	; Scanline 177
      .byte #%00000000	; Scanline 176
      .byte #%00000000	; Scanline 175
      .byte #%00000000	; Scanline 174
      .byte #%00000000	; Scanline 173
      .byte #%00000000	; Scanline 172
      .byte #%00000000	; Scanline 171
      .byte #%00000000	; Scanline 170
      .byte #%00000000	; Scanline 169
      .byte #%00000000	; Scanline 168
      .byte #%00000000	; Scanline 167
      .byte #%11111111	; Scanline 166
      .byte #%11111111	; Scanline 165
      .byte #%11111111	; Scanline 164
      .byte #%11111111	; Scanline 163
      .byte #%11111111	; Scanline 162
      .byte #%11111111	; Scanline 161
      .byte #%11111111	; Scanline 160
      .byte #%11111111	; Scanline 159
      .byte #%11111111	; Scanline 158
      .byte #%11111111	; Scanline 157
      .byte #%11111111	; Scanline 156
      .byte #%11111111	; Scanline 155
      .byte #%11111111	; Scanline 154
      .byte #%11111111	; Scanline 153
      .byte #%11111111	; Scanline 152
      .byte #%11111111	; Scanline 151
      .byte #%11111111	; Scanline 150
      .byte #%11111111	; Scanline 149
      .byte #%11111111	; Scanline 148
      .byte #%11111111	; Scanline 147
      .byte #%11111111	; Scanline 146
      .byte #%11111111	; Scanline 145
      .byte #%11111111	; Scanline 144
      .byte #%11111111	; Scanline 143
      .byte #%11111111	; Scanline 142
      .byte #%11111111	; Scanline 141
      .byte #%11111111	; Scanline 140
      .byte #%11111111	; Scanline 139
      .byte #%11111111	; Scanline 138
      .byte #%11111111	; Scanline 137
      .byte #%11111111	; Scanline 136
      .byte #%11111111	; Scanline 135
      .byte #%11111111	; Scanline 134
      .byte #%11111111	; Scanline 133
      .byte #%11111111	; Scanline 132
      .byte #%11111111	; Scanline 131
      .byte #%11111111	; Scanline 130
      .byte #%11111111	; Scanline 129
      .byte #%00111111	; Scanline 128
      .byte #%00111111	; Scanline 127
      .byte #%00111111	; Scanline 126
      .byte #%00111111	; Scanline 125
      .byte #%00111111	; Scanline 124
      .byte #%00111111	; Scanline 123
      .byte #%00110011	; Scanline 122
      .byte #%00110011	; Scanline 121
      .byte #%00110011	; Scanline 120
      .byte #%00110011	; Scanline 119
      .byte #%00110011	; Scanline 118
      .byte #%00000011	; Scanline 117
      .byte #%00000011	; Scanline 116
      .byte #%00000011	; Scanline 115
      .byte #%00000011	; Scanline 114
      .byte #%00000000	; Scanline 113
      .byte #%00000000	; Scanline 112
      .byte #%00000000	; Scanline 111
      .byte #%00000000	; Scanline 110
      .byte #%00000000	; Scanline 109
      .byte #%00000000	; Scanline 108
      .byte #%00000000	; Scanline 107
      .byte #%00000000	; Scanline 106
      .byte #%00000000	; Scanline 105
      .byte #%00000000	; Scanline 104
      .byte #%00000000	; Scanline 103
      .byte #%00000000	; Scanline 102
      .byte #%00000000	; Scanline 101
      .byte #%00000000	; Scanline 100
      .byte #%00000000	; Scanline 99
      .byte #%00000000	; Scanline 98
      .byte #%00000000	; Scanline 97
      .byte #%00000000	; Scanline 96

Screen_PF2
      .byte #%00000000	; Scanline 191
      .byte #%00000000	; Scanline 190
      .byte #%00000000	; Scanline 189
      .byte #%00000000	; Scanline 188
      .byte #%00000000	; Scanline 187
      .byte #%00000000	; Scanline 186
      .byte #%00000000	; Scanline 185
      .byte #%00000000	; Scanline 184
      .byte #%00000000	; Scanline 183
      .byte #%00000000	; Scanline 182
      .byte #%00000000	; Scanline 181
      .byte #%00000000	; Scanline 180
      .byte #%00000000	; Scanline 179
      .byte #%00111000	; Scanline 178
      .byte #%00000000	; Scanline 177
      .byte #%00000000	; Scanline 176
      .byte #%00000000	; Scanline 175
      .byte #%00000000	; Scanline 174
      .byte #%00000000	; Scanline 173
      .byte #%00000000	; Scanline 172
      .byte #%00000000	; Scanline 171
      .byte #%00000000	; Scanline 170
      .byte #%00000000	; Scanline 169
      .byte #%00000000	; Scanline 168
      .byte #%00000000	; Scanline 167
      .byte #%11111111	; Scanline 166
      .byte #%11111111	; Scanline 165
      .byte #%11111111	; Scanline 164
      .byte #%11111111	; Scanline 163
      .byte #%11111111	; Scanline 162
      .byte #%11111111	; Scanline 161
      .byte #%11111111	; Scanline 160
      .byte #%11111111	; Scanline 159
      .byte #%11111111	; Scanline 158
      .byte #%11111111	; Scanline 157
      .byte #%11111111	; Scanline 156
      .byte #%11111111	; Scanline 155
      .byte #%11111111	; Scanline 154
      .byte #%11111111	; Scanline 153
      .byte #%11111111	; Scanline 152
      .byte #%11111111	; Scanline 151
      .byte #%11111111	; Scanline 150
      .byte #%11111111	; Scanline 149
      .byte #%11111111	; Scanline 148
      .byte #%11111111	; Scanline 147
      .byte #%11111111	; Scanline 146
      .byte #%11111111	; Scanline 145
      .byte #%11111111	; Scanline 144
      .byte #%11111111	; Scanline 143
      .byte #%11111111	; Scanline 142
      .byte #%11111111	; Scanline 141
      .byte #%11111111	; Scanline 140
      .byte #%11111111	; Scanline 139
      .byte #%11111111	; Scanline 138
      .byte #%11111111	; Scanline 137
      .byte #%11111111	; Scanline 136
      .byte #%11111111	; Scanline 135
      .byte #%11111111	; Scanline 134
      .byte #%11111111	; Scanline 133
      .byte #%11111111	; Scanline 132
      .byte #%11111111	; Scanline 131
      .byte #%11111111	; Scanline 130
      .byte #%11111111	; Scanline 129
      .byte #%11111111	; Scanline 128
      .byte #%11111111	; Scanline 127
      .byte #%11111111	; Scanline 126
      .byte #%11111111	; Scanline 125
      .byte #%11111111	; Scanline 124
      .byte #%11111111	; Scanline 123
      .byte #%11111111	; Scanline 122
      .byte #%11111111	; Scanline 121
      .byte #%11111111	; Scanline 120
      .byte #%11111111	; Scanline 119
      .byte #%11111111	; Scanline 118
      .byte #%00111111	; Scanline 117
      .byte #%00111111	; Scanline 116
      .byte #%00111111	; Scanline 115
      .byte #%00110011	; Scanline 114
      .byte #%00110011	; Scanline 113
      .byte #%00110011	; Scanline 112
      .byte #%00110011	; Scanline 111
      .byte #%00110011	; Scanline 110
      .byte #%00110000	; Scanline 109
      .byte #%00110000	; Scanline 108
      .byte #%00110000	; Scanline 107
      .byte #%00110000	; Scanline 106
      .byte #%00000000	; Scanline 105
      .byte #%00000000	; Scanline 104
      .byte #%00000000	; Scanline 103
      .byte #%00000000	; Scanline 102
      .byte #%00000000	; Scanline 101
      .byte #%00000000	; Scanline 100
      .byte #%00000000	; Scanline 99
      .byte #%00000000	; Scanline 98
      .byte #%00000000	; Scanline 97
      .byte #%00000000	; Scanline 96

BatSprite:
    .byte #%00000000
    .byte #%01101100
    .byte #%01101100
    .byte #%01101100
    .byte #%01111100
    .byte #%01101100
    .byte #%11111100
    .byte #%11101110
    .byte #%11010110
    .byte #%11111110
    .byte #%00111000
    .byte #%00111100
    .byte #%00101000
    .byte #%00111100
    .byte #%00111100
    .byte #%00100100

BatSprite1:
    .byte #%00000000
    .byte #%00001100
    .byte #%01101100
    .byte #%01101100
    .byte #%01111100
    .byte #%01101100
    .byte #%11111100
    .byte #%11101110
    .byte #%11010110
    .byte #%11111110
    .byte #%00111000
    .byte #%00111100
    .byte #%00101000
    .byte #%00111100
    .byte #%00111100
    .byte #%00100100

BatSprite2:
    .byte #%00000000
    .byte #%01100000
    .byte #%01101100
    .byte #%01101100
    .byte #%01111100
    .byte #%01101100
    .byte #%11111100
    .byte #%11101110
    .byte #%11010110
    .byte #%11111110
    .byte #%00111000
    .byte #%00111100
    .byte #%00101000
    .byte #%00111100
    .byte #%00111100
    .byte #%00100100      

JSprite:
    .byte #%00000000
    .byte #%01001000
    .byte #%01001000
    .byte #%01001000
    .byte #%01001000
    .byte #%01111000
    .byte #%11001000
    .byte #%11101100
    .byte #%11101100
    .byte #%11101100
    .byte #%00110000
    .byte #%01111000
    .byte #%01111000
    .byte #%01010000
    .byte #%01111000
    .byte #%00111000      

BatColor:
    .byte #$04
    .byte #$04
    .byte #$A5
    .byte #$04
    .byte #$04
    .byte #$19
    .byte #$04
    .byte #$04
    .byte #$04
    .byte #$A5
    .byte #$04
    .byte #$F8
    .byte #$04
    .byte #$04
    .byte #$04
    .byte #$04
    .byte #$04

BatColor1:
    .byte #$04
    .byte #$04
    .byte #$A5
    .byte #$04
    .byte #$04
    .byte #$19
    .byte #$04
    .byte #$04
    .byte #$04
    .byte #$A5
    .byte #$04
    .byte #$F8
    .byte #$04
    .byte #$04
    .byte #$04
    .byte #$04
    .byte #$04

JColor:
    .byte #$00
    .byte #$00
    .byte #$64;
    .byte #$64;
    .byte #$64;
    .byte #$64;
    .byte #$54;
    .byte #$54;
    .byte #$54;
    .byte #$54;
    .byte #$FC;
    .byte #$42;
    .byte #$0E;
    .byte #$0E;
    .byte #$C2;
    .byte #$C2;


DigitsBitmap:
     .byte $EE 
     .byte $AA 
     .byte $EE 
     .byte $22 
     .byte $EE 
     

Interrupt_Vectors 

    ORG $FFFA      ; move position
    .word Reset    ; NMI vector       
    .word Reset    ; RESET vector   
    .word Reset    ; IRQ vector      
