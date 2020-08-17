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

; constants
BAT_HEIGHT = #$10          	     
J_HEIGHT = #$10          

      SEG code
      org $F000

Reset:
        ldx #0
        txa

Clear   dex
        txs
        pha
        bne Clear              
  ; init ram & tia registers
      lda #10
      sta P0PosY          
      lda #0
      sta P0PosX         
      lda #10
      sta P1PosY        
      lda #54
      sta P1PosX       

  ; init pointers
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
    
    
    ; init bg & pf
    lda #$A1
    sta COLUBK             ; bg
    lda #$A4
    sta COLUPF             ; pf
    lda #1
    sta CTRLPF             ; pf reflection
    lda #0
    sta PF0                
    lda #0
    sta PF1               
    lda #0
    sta PF2  
    
    ;lda #10
    ;pha
StartNewFrame
    
   ; lda #$0+1
   ; sta COLUBK
Vsync
    lda #2 
    sta VSYNC ;3  
    sta WSYNC            
    sta WSYNC            
    sta WSYNC            
    lda #0
    sta VSYNC               

    ldx #37
VBlank
    lda #2
    sta VBLANK
    sta WSYNC
    dex
    bne VBlank
    
    sta WSYNC
    
    
    lda #0 
    sta VBLANK 	; Enable TIA Output
     
; visible 192 lines
GameVisibleLine

    lda #$00          ; Clear Playfield
    sta PF0
    sta PF1
    sta PF2	
   
    sta WSYNC
    
    ldx #191        ; visible scanlines
.GameLineLoop:     ; . local
    txa
    asl
   
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
        
        cpx #26
        ;SLEEP 6
        beq .DrawRoad
; TODO
	jmp .RightSidePF
.DrawRoad
        sta WSYNC
       ; lda #$01
       ; sta COLUBK
        lda #$09
        sta COLUPF
        lda #$01
        sta COLUBK             ; bg
       ; lda Screen_Road-1,X
       ; sta PF0
       ; sta PF1
       ; sta PF2

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
.IsP0Visible:                  ; check if should render p0
;      txa                      ; X to A
;      sec                      ; carry flag is set
;      sbc P0PosY               ; subtract sprite Y coordinate
;      cmp BAT_HEIGHT           ; sprite inside height bounds?
;      bcc .DrawSpriteP0        ; if result < SpriteHeight, call subroutine
;      lda #0                   ; else, set lookup index to 0
.DrawSpriteP0:
   ;  clc                      ; clear carry flag 
      ;adc AnimOffset          ; jump to sprite frame 
   ;   tay                      ; load Y so we can work with pointer

    ;  lda (BatSpritePtr),Y     ; load player bitmap slice of data
    ;  sta GRP0                 ; set graphics for player 0
    ;  lda (BatColorPtr),Y      ; load player color from lookup table
    ;  sta COLUP0               ; set color for player 0 slice       bne .RightSidePF
    ;  sta WSYNC                ; wait for next scanline

     dex 
     
     sta WSYNC
     bne .GameLineLoop   
     
     lda #%00000010 		; Disable VIA Output
     sta VBLANK       
; overscan
Overscan:
    
    lda #$00
    sta COLUPF
    
    lda #$A0
    sta COLUBK

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
    inc P0PosY 
    ;; write here

CheckP0Down:
    lda #%00100000
    bit SWCHA
    bne CheckP0Left
    dec P0PosY 
    ;; write here

CheckP0Left:
    lda #%01000000
    bit SWCHA
    bne CheckP0Right
    dec P0PosX
    lda #%11111111
    sta REFP0 
    ;; write here

CheckP0Right:
    lda #%10000000
    bit SWCHA
    bne Nil
    inc P0PosX
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

; pass A, Y registers to subroutine
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

Screen_Road
        .byte #%11111111
        .byte #%11111111
        .byte #%11111111
        .byte #%11111111
        .byte #%11111111
        .byte #%11111111
        .byte #%11111111
        .byte #%11111111
        .byte #%11111111
        .byte #%11111111
        .byte #%11111111
        .byte #%11111111
        .byte #%11111111
        .byte #%11111111
        .byte #%11111111

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
	.byte #%11110000	; Scanline 167
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
	.byte #%11110000	; Scanline 118
	.byte #%11110000	; Scanline 117
	.byte #%11110000	; Scanline 116
	.byte #%11110000	; Scanline 115
	.byte #%11110000	; Scanline 114
	.byte #%11110000	; Scanline 113
	.byte #%11110000	; Scanline 112
	.byte #%11110000	; Scanline 111
	.byte #%11110000	; Scanline 110
	.byte #%11110000	; Scanline 109
	.byte #%11110000	; Scanline 108
	.byte #%11110000	; Scanline 107
	.byte #%11110000	; Scanline 106
	.byte #%11110000	; Scanline 105
	.byte #%11110000	; Scanline 104
	.byte #%11110000	; Scanline 103
	.byte #%11110000	; Scanline 102
	.byte #%11110000	; Scanline 101
	.byte #%11110000	; Scanline 100
	.byte #%11110000	; Scanline 99
	.byte #%11110000	; Scanline 98
	.byte #%11110000	; Scanline 97
	.byte #%11110000	; Scanline 96
	.byte #%11110000	; Scanline 95
	.byte #%11110000	; Scanline 94
	.byte #%11110000	; Scanline 93
	.byte #%11110000	; Scanline 92
	.byte #%11110000	; Scanline 91
	.byte #%11110000	; Scanline 90
	.byte #%11110000	; Scanline 89
	.byte #%11110000	; Scanline 88
	.byte #%11110000	; Scanline 87
	.byte #%11110000	; Scanline 86
	.byte #%11110000	; Scanline 85
	.byte #%11110000	; Scanline 84
	.byte #%11110000	; Scanline 83
	.byte #%11110000	; Scanline 82
	.byte #%11110000	; Scanline 81
	.byte #%11110000	; Scanline 80
	.byte #%11110000	; Scanline 79
	.byte #%11110000	; Scanline 78
	.byte #%11110000	; Scanline 77
	.byte #%11110000	; Scanline 76
	.byte #%01110000	; Scanline 75
	.byte #%01110000	; Scanline 74
	.byte #%01110000	; Scanline 73
	.byte #%01110000	; Scanline 72
	.byte #%01110000	; Scanline 71
	.byte #%01110000	; Scanline 70
	.byte #%00110000	; Scanline 69
	.byte #%00010000	; Scanline 68
	.byte #%00010000	; Scanline 67
	.byte #%00010000	; Scanline 66
	.byte #%00010000	; Scanline 65
	.byte #%00010000	; Scanline 64
	.byte #%00010000	; Scanline 63
	.byte #%00010000	; Scanline 62
	.byte #%00010000	; Scanline 61
	.byte #%00010000	; Scanline 60
	.byte #%00010000	; Scanline 59
	.byte #%00010000	; Scanline 58
	.byte #%00010000	; Scanline 57
	.byte #%00010000	; Scanline 56
	.byte #%00000000	; Scanline 55
	.byte #%00000000	; Scanline 54
	.byte #%00000000	; Scanline 53
	.byte #%00000000	; Scanline 52
	.byte #%00000000	; Scanline 51
	.byte #%00000000	; Scanline 50
	.byte #%00000000	; Scanline 49
	.byte #%00000000	; Scanline 48
	.byte #%00000000	; Scanline 47
	.byte #%00000000	; Scanline 46
	.byte #%00000000	; Scanline 45
	.byte #%00000000	; Scanline 44
	.byte #%00000000	; Scanline 43
	.byte #%00000000	; Scanline 42
	.byte #%00000000	; Scanline 41
	.byte #%00000000	; Scanline 40
	.byte #%00000000	; Scanline 39
	.byte #%00000000	; Scanline 38
	.byte #%00000000	; Scanline 37
	.byte #%00000000	; Scanline 36
	.byte #%00000000	; Scanline 35
	.byte #%00000000	; Scanline 34
	.byte #%00000000	; Scanline 33
	.byte #%00000000	; Scanline 32
	.byte #%00000000	; Scanline 31
	.byte #%00000000	; Scanline 30
	.byte #%00000000	; Scanline 29
	.byte #%00000000	; Scanline 28
	.byte #%00000000	; Scanline 27
	.byte #%00000000	; Scanline 26
	.byte #%00000000	; Scanline 25
	.byte #%00000000	; Scanline 24
	.byte #%00000000	; Scanline 23
	.byte #%00000000	; Scanline 22
	.byte #%00000000	; Scanline 21
	.byte #%00000000	; Scanline 20
	.byte #%00000000	; Scanline 19
	.byte #%00000000	; Scanline 18
	.byte #%00000000	; Scanline 17
	.byte #%00000000	; Scanline 16
	.byte #%00000000	; Scanline 15
	.byte #%00000000	; Scanline 14
	.byte #%00000000	; Scanline 13
	.byte #%00000000	; Scanline 12
	.byte #%00000000	; Scanline 11
	.byte #%00000000	; Scanline 10
	.byte #%00000000	; Scanline 9
	.byte #%00000000	; Scanline 8
	.byte #%00000000	; Scanline 7
	.byte #%00000000	; Scanline 6
	.byte #%00000000	; Scanline 5
	.byte #%00000000	; Scanline 4
	.byte #%00000000	; Scanline 3
	.byte #%00000000	; Scanline 2
	.byte #%00000000	; Scanline 1
	.byte #%00000000	; Scanline 0

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
	.byte #%11111111	; Scanline 167
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
	.byte #%11111111	; Scanline 117
	.byte #%11111111	; Scanline 116
	.byte #%11111111	; Scanline 115
	.byte #%11111111	; Scanline 114
	.byte #%11111111	; Scanline 113
	.byte #%11111111	; Scanline 112
	.byte #%11111111	; Scanline 111
	.byte #%11111111	; Scanline 110
	.byte #%11111111	; Scanline 109
	.byte #%11111111	; Scanline 108
	.byte #%11111111	; Scanline 107
	.byte #%11111111	; Scanline 106
	.byte #%11111111	; Scanline 105
	.byte #%11111111	; Scanline 104
	.byte #%11111111	; Scanline 103
	.byte #%11111111	; Scanline 102
	.byte #%11111111	; Scanline 101
	.byte #%11111111	; Scanline 100
	.byte #%11111111	; Scanline 99
	.byte #%11111111	; Scanline 98
	.byte #%11111111	; Scanline 97
	.byte #%11111111	; Scanline 96
	.byte #%11111111	; Scanline 95
	.byte #%11111111	; Scanline 94
	.byte #%11111111	; Scanline 93
	.byte #%11111111	; Scanline 92
	.byte #%11111111	; Scanline 91
	.byte #%11111111	; Scanline 90
	.byte #%11111111	; Scanline 89
	.byte #%11111111	; Scanline 88
	.byte #%11111111	; Scanline 87
	.byte #%11111111	; Scanline 86
	.byte #%11111111	; Scanline 85
	.byte #%11111111	; Scanline 84
	.byte #%11111111	; Scanline 83
	.byte #%11111111	; Scanline 82
	.byte #%11111111	; Scanline 81
	.byte #%11111111	; Scanline 80
	.byte #%11011111	; Scanline 79
	.byte #%11011111	; Scanline 78
	.byte #%11011111	; Scanline 77
	.byte #%11011111	; Scanline 76
	.byte #%11011111	; Scanline 75
	.byte #%11000111	; Scanline 74
	.byte #%11000111	; Scanline 73
	.byte #%11000111	; Scanline 72
	.byte #%10000111	; Scanline 71
	.byte #%10000111	; Scanline 70
	.byte #%10000111	; Scanline 69
	.byte #%10000111	; Scanline 68
	.byte #%10000110	; Scanline 67
	.byte #%10000110	; Scanline 66
	.byte #%10000110	; Scanline 65
	.byte #%00000110	; Scanline 64
	.byte #%00000010	; Scanline 63
	.byte #%00000010	; Scanline 62
	.byte #%00000010	; Scanline 61
	.byte #%00000010	; Scanline 60
	.byte #%00000000	; Scanline 59
	.byte #%00000000	; Scanline 58
	.byte #%00000000	; Scanline 57
	.byte #%00000000	; Scanline 56
	.byte #%00000000	; Scanline 55
	.byte #%00000000	; Scanline 54
	.byte #%00000000	; Scanline 53
	.byte #%00000000	; Scanline 52
	.byte #%00000000	; Scanline 51
	.byte #%00000000	; Scanline 50
	.byte #%00000000	; Scanline 49
	.byte #%00000000	; Scanline 48
	.byte #%00000000	; Scanline 47
	.byte #%00000000	; Scanline 46
	.byte #%00000000	; Scanline 45
	.byte #%00000000	; Scanline 44
	.byte #%00000000	; Scanline 43
	.byte #%00000000	; Scanline 42
	.byte #%00000000	; Scanline 41
	.byte #%00000000	; Scanline 40
	.byte #%00000000	; Scanline 39
	.byte #%00000000	; Scanline 38
	.byte #%00000000	; Scanline 37
	.byte #%00000000	; Scanline 36
	.byte #%00000000	; Scanline 35
	.byte #%00000000	; Scanline 34
	.byte #%00000000	; Scanline 33
	.byte #%00000000	; Scanline 32
	.byte #%00000000	; Scanline 31
	.byte #%00000000	; Scanline 30
	.byte #%00000000	; Scanline 29
	.byte #%00000000	; Scanline 28
	.byte #%00000000	; Scanline 27
	.byte #%00000000	; Scanline 26
	.byte #%00000000	; Scanline 25
	.byte #%00000000	; Scanline 24
	.byte #%00000000	; Scanline 23
	.byte #%00000000	; Scanline 22
	.byte #%00000000	; Scanline 21
	.byte #%00000000	; Scanline 20
	.byte #%00000000	; Scanline 19
	.byte #%00000000	; Scanline 18
	.byte #%00000000	; Scanline 17
	.byte #%00000000	; Scanline 16
	.byte #%00000000	; Scanline 15
	.byte #%00000000	; Scanline 14
	.byte #%00000000	; Scanline 13
	.byte #%00000000	; Scanline 12
	.byte #%00000000	; Scanline 11
	.byte #%00000000	; Scanline 10
	.byte #%00000000	; Scanline 9
	.byte #%00000000	; Scanline 8
	.byte #%00000000	; Scanline 7
	.byte #%00000000	; Scanline 6
	.byte #%00000000	; Scanline 5
	.byte #%00000000	; Scanline 4
	.byte #%00000000	; Scanline 3
	.byte #%00000000	; Scanline 2
	.byte #%00000000	; Scanline 1
	.byte #%00000000	; Scanline 0

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
	.byte #%11111111	; Scanline 167
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
	.byte #%11111111	; Scanline 117
	.byte #%11111111	; Scanline 116
	.byte #%11111111	; Scanline 115
	.byte #%11111111	; Scanline 114
	.byte #%11111111	; Scanline 113
	.byte #%11111111	; Scanline 112
	.byte #%11111111	; Scanline 111
	.byte #%11111111	; Scanline 110
	.byte #%11111111	; Scanline 109
	.byte #%11111111	; Scanline 108
	.byte #%11111111	; Scanline 107
	.byte #%11111111	; Scanline 106
	.byte #%11111111	; Scanline 105
	.byte #%11111111	; Scanline 104
	.byte #%11111111	; Scanline 103
	.byte #%11111111	; Scanline 102
	.byte #%11111111	; Scanline 101
	.byte #%11111111	; Scanline 100
	.byte #%11111111	; Scanline 99
	.byte #%11111111	; Scanline 98
	.byte #%11111111	; Scanline 97
	.byte #%11111111	; Scanline 96
	.byte #%11111111	; Scanline 95
	.byte #%11111111	; Scanline 94
	.byte #%11111111	; Scanline 93
	.byte #%11111111	; Scanline 92
	.byte #%11111111	; Scanline 91
	.byte #%11111111	; Scanline 90
	.byte #%11111111	; Scanline 89
	.byte #%11111111	; Scanline 88
	.byte #%11111111	; Scanline 87
	.byte #%11111111	; Scanline 86
	.byte #%11111111	; Scanline 85
	.byte #%11111111	; Scanline 84
	.byte #%11111111	; Scanline 83
	.byte #%11111111	; Scanline 82
	.byte #%11111111	; Scanline 81
	.byte #%11111111	; Scanline 80
	.byte #%11111111	; Scanline 79
	.byte #%11111111	; Scanline 78
	.byte #%11111111	; Scanline 77
	.byte #%11111111	; Scanline 76
	.byte #%10111111	; Scanline 75
	.byte #%10111111	; Scanline 74
	.byte #%10111111	; Scanline 73
	.byte #%10111111	; Scanline 72
	.byte #%10011111	; Scanline 71
	.byte #%10011011	; Scanline 70
	.byte #%10011011	; Scanline 69
	.byte #%10011011	; Scanline 68
	.byte #%00011011	; Scanline 67
	.byte #%00011010	; Scanline 66
	.byte #%00011010	; Scanline 65
	.byte #%00011010	; Scanline 64
	.byte #%00010010	; Scanline 63
	.byte #%00010010	; Scanline 62
	.byte #%00010010	; Scanline 61
	.byte #%00010010	; Scanline 60
	.byte #%00010010	; Scanline 59
	.byte #%00010010	; Scanline 58
	.byte #%00010010	; Scanline 57
	.byte #%00010010	; Scanline 56
	.byte #%00010010	; Scanline 55
	.byte #%00010010	; Scanline 54
	.byte #%00010010	; Scanline 53
	.byte #%00010010	; Scanline 52
	.byte #%00010010	; Scanline 51
	.byte #%00010010	; Scanline 50
	.byte #%00010010	; Scanline 49
	.byte #%00000010	; Scanline 48
	.byte #%00000010	; Scanline 47
	.byte #%00000010	; Scanline 46
	.byte #%00000000	; Scanline 45
	.byte #%00000000	; Scanline 44
	.byte #%00000000	; Scanline 43
	.byte #%00000000	; Scanline 42
	.byte #%00000000	; Scanline 41
	.byte #%00000000	; Scanline 40
	.byte #%00000000	; Scanline 39
	.byte #%00000000	; Scanline 38
	.byte #%00000000	; Scanline 37
	.byte #%00000000	; Scanline 36
	.byte #%00000000	; Scanline 35
	.byte #%00000000	; Scanline 34
	.byte #%00000000	; Scanline 33
	.byte #%00000000	; Scanline 32
	.byte #%00000000	; Scanline 31
	.byte #%00000000	; Scanline 30
	.byte #%00000000	; Scanline 29
	.byte #%00000000	; Scanline 28
	.byte #%00000000	; Scanline 27
	.byte #%00000000	; Scanline 26
	.byte #%00000000	; Scanline 25
	.byte #%00000000	; Scanline 24
	.byte #%00000000	; Scanline 23
	.byte #%00000000	; Scanline 22
	.byte #%00000000	; Scanline 21
	.byte #%00000000	; Scanline 20
	.byte #%00000000	; Scanline 19
	.byte #%00000000	; Scanline 18
	.byte #%00000000	; Scanline 17
	.byte #%00000000	; Scanline 16
	.byte #%00000000	; Scanline 15
	.byte #%00000000	; Scanline 14
	.byte #%00000000	; Scanline 13
	.byte #%00000000	; Scanline 12
	.byte #%00000000	; Scanline 11
	.byte #%00000000	; Scanline 10
	.byte #%00000000	; Scanline 9
	.byte #%00000000	; Scanline 8
	.byte #%00000000	; Scanline 7
	.byte #%00000000	; Scanline 6
	.byte #%00000000	; Scanline 5
	.byte #%00000000	; Scanline 4
	.byte #%00000000	; Scanline 3
	.byte #%00000000	; Scanline 2
	.byte #%00000000	; Scanline 1
	.byte #%00000000	; Scanline 0

Screen_PF3
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
	.byte #%00000000	; Scanline 178
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
	.byte #%00000000	; Scanline 166
	.byte #%00000000	; Scanline 165
	.byte #%00000000	; Scanline 164
	.byte #%00000000	; Scanline 163
	.byte #%00000000	; Scanline 162
	.byte #%00000000	; Scanline 161
	.byte #%00000000	; Scanline 160
	.byte #%00000000	; Scanline 159
	.byte #%00000000	; Scanline 158
	.byte #%00000000	; Scanline 157
	.byte #%00000000	; Scanline 156
	.byte #%00000000	; Scanline 155
	.byte #%00000000	; Scanline 154
	.byte #%00000000	; Scanline 153
	.byte #%00000000	; Scanline 152
	.byte #%00000000	; Scanline 151
	.byte #%00000000	; Scanline 150
	.byte #%00000000	; Scanline 149
	.byte #%00000000	; Scanline 148
	.byte #%00000000	; Scanline 147
	.byte #%00000000	; Scanline 146
	.byte #%00000000	; Scanline 145
	.byte #%00000000	; Scanline 144
	.byte #%00000000	; Scanline 143
	.byte #%00000000	; Scanline 142
	.byte #%00000000	; Scanline 141
	.byte #%00000000	; Scanline 140
	.byte #%00000000	; Scanline 139
	.byte #%00000000	; Scanline 138
	.byte #%00000000	; Scanline 137
	.byte #%00000000	; Scanline 136
	.byte #%00000000	; Scanline 135
	.byte #%00000000	; Scanline 134
	.byte #%00000000	; Scanline 133
	.byte #%00000000	; Scanline 132
	.byte #%00000000	; Scanline 131
	.byte #%00000000	; Scanline 130
	.byte #%00000000	; Scanline 129
	.byte #%00000000	; Scanline 128
	.byte #%00000000	; Scanline 127
	.byte #%00000000	; Scanline 126
	.byte #%00000000	; Scanline 125
	.byte #%00000000	; Scanline 124
	.byte #%00000000	; Scanline 123
	.byte #%00000000	; Scanline 122
	.byte #%00000000	; Scanline 121
	.byte #%00000000	; Scanline 120
	.byte #%00000000	; Scanline 119
	.byte #%00000000	; Scanline 118
	.byte #%00000000	; Scanline 117
	.byte #%00000000	; Scanline 116
	.byte #%00000000	; Scanline 115
	.byte #%00000000	; Scanline 114
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
	.byte #%00000000	; Scanline 95
	.byte #%00000000	; Scanline 94
	.byte #%00000000	; Scanline 93
	.byte #%00000000	; Scanline 92
	.byte #%00000000	; Scanline 91
	.byte #%00000000	; Scanline 90
	.byte #%00000000	; Scanline 89
	.byte #%00000000	; Scanline 88
	.byte #%00000000	; Scanline 87
	.byte #%00000000	; Scanline 86
	.byte #%00000000	; Scanline 85
	.byte #%00000000	; Scanline 84
	.byte #%00000000	; Scanline 83
	.byte #%00000000	; Scanline 82
	.byte #%00000000	; Scanline 81
	.byte #%00000000	; Scanline 80
	.byte #%00000000	; Scanline 79
	.byte #%00000000	; Scanline 78
	.byte #%00000000	; Scanline 77
	.byte #%00000000	; Scanline 76
	.byte #%00000000	; Scanline 75
	.byte #%00000000	; Scanline 74
	.byte #%00000000	; Scanline 73
	.byte #%00000000	; Scanline 72
	.byte #%00000000	; Scanline 71
	.byte #%00000000	; Scanline 70
	.byte #%00000000	; Scanline 69
	.byte #%00000000	; Scanline 68
	.byte #%00000000	; Scanline 67
	.byte #%00000000	; Scanline 66
	.byte #%00000000	; Scanline 65
	.byte #%00000000	; Scanline 64
	.byte #%00000000	; Scanline 63
	.byte #%00000000	; Scanline 62
	.byte #%00000000	; Scanline 61
	.byte #%00000000	; Scanline 60
	.byte #%00000000	; Scanline 59
	.byte #%00000000	; Scanline 58
	.byte #%00000000	; Scanline 57
	.byte #%00000000	; Scanline 56
	.byte #%00000000	; Scanline 55
	.byte #%00000000	; Scanline 54
	.byte #%00000000	; Scanline 53
	.byte #%00000000	; Scanline 52
	.byte #%00000000	; Scanline 51
	.byte #%00000000	; Scanline 50
	.byte #%00000000	; Scanline 49
	.byte #%00000000	; Scanline 48
	.byte #%00000000	; Scanline 47
	.byte #%00000000	; Scanline 46
	.byte #%00000000	; Scanline 45
	.byte #%00000000	; Scanline 44
	.byte #%00000000	; Scanline 43
	.byte #%00000000	; Scanline 42
	.byte #%00000000	; Scanline 41
	.byte #%00000000	; Scanline 40
	.byte #%00000000	; Scanline 39
	.byte #%00000000	; Scanline 38
	.byte #%00000000	; Scanline 37
	.byte #%00000000	; Scanline 36
	.byte #%00000000	; Scanline 35
	.byte #%00000000	; Scanline 34
	.byte #%00000000	; Scanline 33
	.byte #%00000000	; Scanline 32
	.byte #%00000000	; Scanline 31
	.byte #%00000000	; Scanline 30
	.byte #%00000000	; Scanline 29
	.byte #%00000000	; Scanline 28
	.byte #%00000000	; Scanline 27
	.byte #%00000000	; Scanline 26
	.byte #%00000000	; Scanline 25
	.byte #%00000000	; Scanline 24
	.byte #%00000000	; Scanline 23
	.byte #%00000000	; Scanline 22
	.byte #%00000000	; Scanline 21
	.byte #%00000000	; Scanline 20
	.byte #%00000000	; Scanline 19
	.byte #%00000000	; Scanline 18
	.byte #%00000000	; Scanline 17
	.byte #%00000000	; Scanline 16
	.byte #%00000000	; Scanline 15
	.byte #%00000000	; Scanline 14
	.byte #%00000000	; Scanline 13
	.byte #%00000000	; Scanline 12
	.byte #%00000000	; Scanline 11
	.byte #%00000000	; Scanline 10
	.byte #%00000000	; Scanline 9
	.byte #%00000000	; Scanline 8
	.byte #%00000000	; Scanline 7
	.byte #%00000000	; Scanline 6
	.byte #%00000000	; Scanline 5
	.byte #%00000000	; Scanline 4
	.byte #%00000000	; Scanline 3
	.byte #%00000000	; Scanline 2
	.byte #%00000000	; Scanline 1
	.byte #%00000000	; Scanline 0

Screen_PF4
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
	.byte #%00000000	; Scanline 178
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
	.byte #%00000000	; Scanline 166
	.byte #%00000000	; Scanline 165
	.byte #%00000000	; Scanline 164
	.byte #%00000000	; Scanline 163
	.byte #%00000000	; Scanline 162
	.byte #%00000000	; Scanline 161
	.byte #%00000000	; Scanline 160
	.byte #%00000000	; Scanline 159
	.byte #%00000000	; Scanline 158
	.byte #%00000000	; Scanline 157
	.byte #%00000000	; Scanline 156
	.byte #%00000000	; Scanline 155
	.byte #%00000000	; Scanline 154
	.byte #%00000000	; Scanline 153
	.byte #%00000000	; Scanline 152
	.byte #%00000000	; Scanline 151
	.byte #%00000000	; Scanline 150
	.byte #%00000000	; Scanline 149
	.byte #%00000000	; Scanline 148
	.byte #%00000000	; Scanline 147
	.byte #%00000000	; Scanline 146
	.byte #%00000000	; Scanline 145
	.byte #%00000000	; Scanline 144
	.byte #%00000000	; Scanline 143
	.byte #%00000000	; Scanline 142
	.byte #%00000000	; Scanline 141
	.byte #%00000000	; Scanline 140
	.byte #%00000000	; Scanline 139
	.byte #%00000000	; Scanline 138
	.byte #%00000000	; Scanline 137
	.byte #%00000000	; Scanline 136
	.byte #%00000000	; Scanline 135
	.byte #%00000000	; Scanline 134
	.byte #%00000000	; Scanline 133
	.byte #%00000000	; Scanline 132
	.byte #%00000000	; Scanline 131
	.byte #%00000000	; Scanline 130
	.byte #%00000000	; Scanline 129
	.byte #%00000000	; Scanline 128
	.byte #%00000000	; Scanline 127
	.byte #%00000000	; Scanline 126
	.byte #%00000000	; Scanline 125
	.byte #%00000000	; Scanline 124
	.byte #%00000000	; Scanline 123
	.byte #%00000000	; Scanline 122
	.byte #%00000000	; Scanline 121
	.byte #%00000000	; Scanline 120
	.byte #%00000000	; Scanline 119
	.byte #%00000000	; Scanline 118
	.byte #%00000000	; Scanline 117
	.byte #%00000000	; Scanline 116
	.byte #%00000000	; Scanline 115
	.byte #%00000000	; Scanline 114
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
	.byte #%00000000	; Scanline 95
	.byte #%00000000	; Scanline 94
	.byte #%00000000	; Scanline 93
	.byte #%00000000	; Scanline 92
	.byte #%00000000	; Scanline 91
	.byte #%00000000	; Scanline 90
	.byte #%00000000	; Scanline 89
	.byte #%00000000	; Scanline 88
	.byte #%00000000	; Scanline 87
	.byte #%00000000	; Scanline 86
	.byte #%00000000	; Scanline 85
	.byte #%00000000	; Scanline 84
	.byte #%00000000	; Scanline 83
	.byte #%00000000	; Scanline 82
	.byte #%00000000	; Scanline 81
	.byte #%00000000	; Scanline 80
	.byte #%00000000	; Scanline 79
	.byte #%00000000	; Scanline 78
	.byte #%00000000	; Scanline 77
	.byte #%00000000	; Scanline 76
	.byte #%00000000	; Scanline 75
	.byte #%00000000	; Scanline 74
	.byte #%00000000	; Scanline 73
	.byte #%00000000	; Scanline 72
	.byte #%00000000	; Scanline 71
	.byte #%00000000	; Scanline 70
	.byte #%00000000	; Scanline 69
	.byte #%00000000	; Scanline 68
	.byte #%00000000	; Scanline 67
	.byte #%00000000	; Scanline 66
	.byte #%00000000	; Scanline 65
	.byte #%00000000	; Scanline 64
	.byte #%00000000	; Scanline 63
	.byte #%00000000	; Scanline 62
	.byte #%00000000	; Scanline 61
	.byte #%00000000	; Scanline 60
	.byte #%00000000	; Scanline 59
	.byte #%00000000	; Scanline 58
	.byte #%00000000	; Scanline 57
	.byte #%00000000	; Scanline 56
	.byte #%00000000	; Scanline 55
	.byte #%00000000	; Scanline 54
	.byte #%00000000	; Scanline 53
	.byte #%00000000	; Scanline 52
	.byte #%00000000	; Scanline 51
	.byte #%00000000	; Scanline 50
	.byte #%00000000	; Scanline 49
	.byte #%00000000	; Scanline 48
	.byte #%00000000	; Scanline 47
	.byte #%00000000	; Scanline 46
	.byte #%00000000	; Scanline 45
	.byte #%00000000	; Scanline 44
	.byte #%00000000	; Scanline 43
	.byte #%00000000	; Scanline 42
	.byte #%00000000	; Scanline 41
	.byte #%00000000	; Scanline 40
	.byte #%00000000	; Scanline 39
	.byte #%00000000	; Scanline 38
	.byte #%00000000	; Scanline 37
	.byte #%00000000	; Scanline 36
	.byte #%00000000	; Scanline 35
	.byte #%00000000	; Scanline 34
	.byte #%00000000	; Scanline 33
	.byte #%00000000	; Scanline 32
	.byte #%00011000	; Scanline 31
	.byte #%00011000	; Scanline 30
	.byte #%00011000	; Scanline 29
	.byte #%00111000	; Scanline 28
	.byte #%00100000	; Scanline 27
	.byte #%00100000	; Scanline 26
	.byte #%00100000	; Scanline 25
	.byte #%00100000	; Scanline 24
	.byte #%00100000	; Scanline 23
	.byte #%00100000	; Scanline 22
	.byte #%00100000	; Scanline 21
	.byte #%00100000	; Scanline 20
	.byte #%00100000	; Scanline 19
	.byte #%00100000	; Scanline 18
	.byte #%00100000	; Scanline 17
	.byte #%00100000	; Scanline 16
	.byte #%00100000        ; Scanline 15
	.byte #%00111000	; Scanline 14
	.byte #%00111000	; Scanline 13
	.byte #%00011000	; Scanline 12
	.byte #%00011000	; Scanline 11
	.byte #%00000000	; Scanline 10
	.byte #%00000000	; Scanline 9
	.byte #%00000000	; Scanline 8
	.byte #%00000000	; Scanline 7
	.byte #%00000000	; Scanline 6
	.byte #%00000000	; Scanline 5
	.byte #%00000000	; Scanline 4
	.byte #%00000000	; Scanline 3
	.byte #%00000000	; Scanline 2
	.byte #%00000000	; Scanline 1
	.byte #%00000000	; Scanline 0

Screen_PF5
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
	.byte #%00000000	; Scanline 178
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
	.byte #%00000000	; Scanline 166
	.byte #%00000000	; Scanline 165
	.byte #%00000000	; Scanline 164
	.byte #%00000000	; Scanline 163
	.byte #%00000000	; Scanline 162
	.byte #%00000000	; Scanline 161
	.byte #%00000000	; Scanline 160
	.byte #%00000000	; Scanline 159
	.byte #%00000000	; Scanline 158
	.byte #%00000000	; Scanline 157
	.byte #%00000000	; Scanline 156
	.byte #%00000000	; Scanline 155
	.byte #%00000000	; Scanline 154
	.byte #%00000000	; Scanline 153
	.byte #%00000000	; Scanline 152
	.byte #%00000000	; Scanline 151
	.byte #%00000000	; Scanline 150
	.byte #%00000000	; Scanline 149
	.byte #%00000000	; Scanline 148
	.byte #%00000000	; Scanline 147
	.byte #%00000000	; Scanline 146
	.byte #%00000000	; Scanline 145
	.byte #%00000000	; Scanline 144
	.byte #%00000000	; Scanline 143
	.byte #%00000000	; Scanline 142
	.byte #%00000000	; Scanline 141
	.byte #%00000000	; Scanline 140
	.byte #%00000000	; Scanline 139
	.byte #%00000000	; Scanline 138
	.byte #%00000000	; Scanline 137
	.byte #%00000000	; Scanline 136
	.byte #%00000000	; Scanline 135
	.byte #%00000000	; Scanline 134
	.byte #%00000000	; Scanline 133
	.byte #%00000000	; Scanline 132
	.byte #%00000000	; Scanline 131
	.byte #%00000000	; Scanline 130
	.byte #%00000000	; Scanline 129
	.byte #%00000000	; Scanline 128
	.byte #%00000000	; Scanline 127
	.byte #%00000000	; Scanline 126
	.byte #%00000000	; Scanline 125
	.byte #%00000000	; Scanline 124
	.byte #%00000000	; Scanline 123
	.byte #%00000000	; Scanline 122
	.byte #%00000000	; Scanline 121
	.byte #%00000000	; Scanline 120
	.byte #%00000000	; Scanline 119
	.byte #%00000000	; Scanline 118
	.byte #%00000000	; Scanline 117
	.byte #%00000000	; Scanline 116
	.byte #%00000000	; Scanline 115
	.byte #%00000000	; Scanline 114
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
	.byte #%00000000	; Scanline 95
	.byte #%00000000	; Scanline 94
	.byte #%00000000	; Scanline 93
	.byte #%00000000	; Scanline 92
	.byte #%00000000	; Scanline 91
	.byte #%00000000	; Scanline 90
	.byte #%00000000	; Scanline 89
	.byte #%00000000	; Scanline 88
	.byte #%00000000	; Scanline 87
	.byte #%00000000	; Scanline 86
	.byte #%00000000	; Scanline 85
	.byte #%00000000	; Scanline 84
	.byte #%00000000	; Scanline 83
	.byte #%00000000	; Scanline 82
	.byte #%00000000	; Scanline 81
	.byte #%00000000	; Scanline 80
	.byte #%00000000	; Scanline 79
	.byte #%00000000	; Scanline 78
	.byte #%00000000	; Scanline 77
	.byte #%00000000	; Scanline 76
	.byte #%00000000	; Scanline 75
	.byte #%00000000	; Scanline 74
	.byte #%00000000	; Scanline 73
	.byte #%00000000	; Scanline 72
	.byte #%00000000	; Scanline 71
	.byte #%00000000	; Scanline 70
	.byte #%00000000	; Scanline 69
	.byte #%00000000	; Scanline 68
	.byte #%00000000	; Scanline 67
	.byte #%00000000	; Scanline 66
	.byte #%00000000	; Scanline 65
	.byte #%00000000	; Scanline 64
	.byte #%00000000	; Scanline 63
	.byte #%00000000	; Scanline 62
	.byte #%00000000	; Scanline 61
	.byte #%00000000	; Scanline 60
	.byte #%00000000	; Scanline 59
	.byte #%00000000	; Scanline 58
	.byte #%00000000	; Scanline 57
	.byte #%00000000	; Scanline 56
	.byte #%00000000	; Scanline 55
	.byte #%00000000	; Scanline 54
	.byte #%00000000	; Scanline 53
	.byte #%00000000	; Scanline 52
	.byte #%00000000	; Scanline 51
	.byte #%00000000	; Scanline 50
	.byte #%00000000	; Scanline 49
	.byte #%00000000	; Scanline 48
	.byte #%00000000	; Scanline 47
	.byte #%00000000	; Scanline 46
	.byte #%00000000	; Scanline 45
	.byte #%00000000	; Scanline 44
	.byte #%00000000	; Scanline 43
	.byte #%00000000	; Scanline 42
	.byte #%00000000	; Scanline 41
	.byte #%00000000	; Scanline 40
	.byte #%00000000	; Scanline 39
	.byte #%00000000	; Scanline 38
	.byte #%00000000	; Scanline 37
	.byte #%00000000	; Scanline 36
	.byte #%00000000	; Scanline 35
	.byte #%00000000	; Scanline 34
	.byte #%00000000	; Scanline 33
	.byte #%00000000	; Scanline 32
	.byte #%00000000	; Scanline 31
	.byte #%00000000	; Scanline 30
	.byte #%00000000	; Scanline 29
	.byte #%00000000	; Scanline 28
	.byte #%00000000	; Scanline 27
	.byte #%00000000	; Scanline 26
	.byte #%00000000	; Scanline 25
	.byte #%00000000	; Scanline 24
	.byte #%00000000	; Scanline 23
	.byte #%00000000	; Scanline 22
	.byte #%00000000	; Scanline 21
	.byte #%00000000	; Scanline 20
	.byte #%00000000	; Scanline 19
	.byte #%00000000	; Scanline 18
	.byte #%00000000	; Scanline 17
	.byte #%00000000	; Scanline 16
	.byte #%00000000	; Scanline 15
	.byte #%00000000	; Scanline 14
	.byte #%00000000	; Scanline 13
	.byte #%00000000	; Scanline 12
	.byte #%00000000	; Scanline 11
	.byte #%00000000	; Scanline 10
	.byte #%00000000	; Scanline 9
	.byte #%00000000	; Scanline 8
	.byte #%00000000	; Scanline 7
	.byte #%00000000	; Scanline 6
	.byte #%00000000	; Scanline 5
	.byte #%00000000	; Scanline 4
	.byte #%00000000	; Scanline 3
	.byte #%00000000	; Scanline 2
	.byte #%00000000	; Scanline 1
	.byte #%00000000	; Scanline 0


  ; ROM lookup tables
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
      .byte #$00
      .byte #$00
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
      .byte #$00
      .byte #$00
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

      ORG $FFFA      ; move position
      .word Reset    ; NMI vector       
      .word Reset    ; RESET vector   
      .word Reset    ; IRQ vector      
