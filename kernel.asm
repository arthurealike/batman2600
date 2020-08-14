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
    
StartNewFrame:
; init bg & pf
    lda #%01
    sta COLUBK             ; bg
    lda #$A0
    sta COLUPF             ; pf
    lda #1
    sta CTRLPF             ; pf reflection
    lda #%00000000
    sta PF0                
    lda #%00000000
    sta PF1               
    lda #0
    sta PF2  

Vsync
    lda #2 
    sta VBLANK
    sta VSYNC ;3  
    sta WSYNC            
    sta WSYNC            
    sta WSYNC            
    lda #0
    sta VSYNC               
    sta VBLANK   

    ldx #37
VBlank:
    sta WSYNC
    dex
    bne VBlank
    
    sta WSYNC
    
    lda #0 
    sta VBLANK 	; Enable TIA Output
    
; visible 192 lines
GameVisibleLine:

    ldx #192        ; visible scanlines
.GameLineLoop:     ; . local

        lda Screen_PF0-1,X
	sta PF0
	lda Screen_PF1-1,X
	sta PF1
	lda Screen_PF2-1,X
	sta PF2
        
        SLEEP 12
        lda #$E7
        sta COLUPF 
        
	lda Screen_PF3-1,X
	sta PF0
	lda Screen_PF4-1,X
	sta PF1
	lda Screen_PF5-1,X
	sta PF2

; Reserved for left side of pf
;.IsP0Visible:       ; check if should render p0
;      txa                      ; get line
;      sec                      ; carry flag is set
;      sbc P0PosY               ; subtract sprite Y coordinate
;      cmp BAT_HEIGHT           ; sprite inside height bounds?
;      bcc .DrawSpriteP0        ; if result < SpriteHeight, call subroutine
;      lda #0
;                                  ; else, set lookup index to 0
;.DrawSpriteP0:
;      clc                      ; clear carry flag 
;      adc 200                  ; jump to sprite frame 
;      tay                      ; load Y so we can work with pointer
;
;      ; not strecthed
;      lda #%0000000
;      sta NUSIZ0
;	
;      lda (BatSpritePtr),Y     ; load player bitmap slice of data
;     
;      ; sta WSYNC                ; halt cpu
;      sta GRP0                 ; player 0 graphic
;      lda (BatColorPtr),Y      ; correct color from table
;     
;      sta COLUP0               ; set color

;; Reserved for right side of pf
;.IsP1Visible:                  ; same shit as p0
;      txa                      
;      sec                      
;      sbc P1PosY               
;      cmp J_HEIGHT             
;      bcc .DrawSpriteP1        
;      lda #0 
;.DrawSpriteP1:
;      tay
;      lda #%0
;      sta NUSIZ1
;      lda (JSpritePtr),Y  
;      sta GRP1            
;      lda (JColorPtr),Y   
;      sta COLUP1          

     lda #$A3
     sta COLUPF
     dex 
     sta WSYNC
     
     bne .GameLineLoop   

     lda #%01000010 		; Disable VIA Output
     sta VBLANK       

; overscan
Overscan:
    lda #2
    sta VBLANK               
    REPEAT 30
        sta WSYNC            
    REPEND
    lda #0
    sta VBLANK               ; turn off VBLANK

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

; pfx line by line
Screen_PF0
	.byte #%11111111	; Scanline 191
	.byte #%11111111	; Scanline 190
	.byte #%11111111	; Scanline 189
	.byte #%11111111	; Scanline 188
	.byte #%11111111	; Scanline 187
	.byte #%11111111	; Scanline 186
	.byte #%11111111	; Scanline 185
	.byte #%11111111	; Scanline 184
	.byte #%11111111	; Scanline 183
	.byte #%11111111	; Scanline 182
	.byte #%11111111	; Scanline 181
	.byte #%11111111	; Scanline 180
	.byte #%11111111	; Scanline 179
	.byte #%11111111	; Scanline 178
	.byte #%11111111	; Scanline 177
	.byte #%11111111	; Scanline 176
	.byte #%11111111	; Scanline 175
	.byte #%11111111	; Scanline 174
	.byte #%11111111	; Scanline 173
	.byte #%11111111	; Scanline 172
	.byte #%11111111	; Scanline 171
	.byte #%11111111	; Scanline 170
	.byte #%11111111	; Scanline 169
	.byte #%11111111	; Scanline 168
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
	.byte #%10011111	; Scanline 141
	.byte #%10011111	; Scanline 140
	.byte #%10011111	; Scanline 139
	.byte #%10011111	; Scanline 138
	.byte #%10011111	; Scanline 137
	.byte #%10011111	; Scanline 136
	.byte #%10011111	; Scanline 135
	.byte #%10011111	; Scanline 134
	.byte #%10011111	; Scanline 133
	.byte #%10011111	; Scanline 132
	.byte #%10011111	; Scanline 131
	.byte #%10011111	; Scanline 130
	.byte #%10011111	; Scanline 129
	.byte #%10011111	; Scanline 128
	.byte #%10011111	; Scanline 127
	.byte #%10011111	; Scanline 126
	.byte #%10011111	; Scanline 125
	.byte #%11111111	; Scanline 124
	.byte #%11111111	; Scanline 123
	.byte #%11111111	; Scanline 122
	.byte #%11111111	; Scanline 121
	.byte #%11111111	; Scanline 120
	.byte #%10011111	; Scanline 119
	.byte #%10011111	; Scanline 118
	.byte #%10011111	; Scanline 117
	.byte #%10011111	; Scanline 116
	.byte #%10011111	; Scanline 115
	.byte #%10011111	; Scanline 114
	.byte #%10011111	; Scanline 113
	.byte #%10011111	; Scanline 112
	.byte #%10011111	; Scanline 111
	.byte #%10011111	; Scanline 110
	.byte #%10011111	; Scanline 109
	.byte #%10011111	; Scanline 108
	.byte #%10011111	; Scanline 107
	.byte #%10011111	; Scanline 106
	.byte #%10011111	; Scanline 105
	.byte #%10011111	; Scanline 104
	.byte #%10011111	; Scanline 103
	.byte #%11111111	; Scanline 102
	.byte #%11111111	; Scanline 101
	.byte #%11111111	; Scanline 100
	.byte #%11111111	; Scanline 99
	.byte #%11111111	; Scanline 98
	.byte #%10011111	; Scanline 97
	.byte #%10011111	; Scanline 96
	.byte #%10011111	; Scanline 95
	.byte #%10011111	; Scanline 94
	.byte #%10011111	; Scanline 93
	.byte #%10011111	; Scanline 92
	.byte #%10011111	; Scanline 91
	.byte #%10011111	; Scanline 90
	.byte #%10011111	; Scanline 89
	.byte #%10011111	; Scanline 88
	.byte #%10011111	; Scanline 87
	.byte #%10011111	; Scanline 86
	.byte #%10011111	; Scanline 85
	.byte #%10011111	; Scanline 84
	.byte #%10011111	; Scanline 83
	.byte #%10011111	; Scanline 82
	.byte #%10011111	; Scanline 81
	.byte #%11111111	; Scanline 80
	.byte #%11111111	; Scanline 79
	.byte #%11111111	; Scanline 78
	.byte #%11111111	; Scanline 77
	.byte #%11111111	; Scanline 76
	.byte #%10011111	; Scanline 75
	.byte #%10011111	; Scanline 74
	.byte #%10011111	; Scanline 73
	.byte #%10011111	; Scanline 72
	.byte #%10011111	; Scanline 71
	.byte #%10011111	; Scanline 70
	.byte #%10011111	; Scanline 69
	.byte #%10011111	; Scanline 68
	.byte #%10011111	; Scanline 67
	.byte #%10011111	; Scanline 66
	.byte #%10011111	; Scanline 65
	.byte #%10011111	; Scanline 64
	.byte #%10011111	; Scanline 63
	.byte #%10011111	; Scanline 62
	.byte #%10011111	; Scanline 61
	.byte #%10011111	; Scanline 60
	.byte #%10011111	; Scanline 59
	.byte #%11111111	; Scanline 58
	.byte #%11111111	; Scanline 57
	.byte #%11111111	; Scanline 56
	.byte #%11111111	; Scanline 55
	.byte #%11111111	; Scanline 54
	.byte #%10011111	; Scanline 53
	.byte #%10011111	; Scanline 52
	.byte #%10011111	; Scanline 51
	.byte #%10011111	; Scanline 50
	.byte #%10011111	; Scanline 49
	.byte #%10011111	; Scanline 48
	.byte #%10011111	; Scanline 47
	.byte #%10011111	; Scanline 46
	.byte #%10011111	; Scanline 45
	.byte #%10011111	; Scanline 44
	.byte #%10011111	; Scanline 43
	.byte #%10011111	; Scanline 42
	.byte #%10011111	; Scanline 41
	.byte #%10011111	; Scanline 40
	.byte #%10011111	; Scanline 39
	.byte #%10011111	; Scanline 38
	.byte #%10011111	; Scanline 37
	.byte #%11111111	; Scanline 36
	.byte #%11111111	; Scanline 35
	.byte #%11111111	; Scanline 34
	.byte #%11111111	; Scanline 33
	.byte #%11111111	; Scanline 32
	.byte #%10011111	; Scanline 31
	.byte #%10011111	; Scanline 30
	.byte #%10011111	; Scanline 29
	.byte #%10011111	; Scanline 28
	.byte #%10011111	; Scanline 27
	.byte #%10011111	; Scanline 26
	.byte #%10011111	; Scanline 25
	.byte #%10011111	; Scanline 24
	.byte #%10011111	; Scanline 23
	.byte #%10011111	; Scanline 22
	.byte #%10011111	; Scanline 21
	.byte #%10011111	; Scanline 20
	.byte #%10011111	; Scanline 19
	.byte #%10011111	; Scanline 18
	.byte #%10011111	; Scanline 17
	.byte #%10011111	; Scanline 16
	.byte #%10011111	; Scanline 15
	.byte #%11111111	; Scanline 14
	.byte #%11111111	; Scanline 13
	.byte #%11111111	; Scanline 12
	.byte #%11111111	; Scanline 11
	.byte #%11111111	; Scanline 10
	.byte #%11111111	; Scanline 9
	.byte #%11111111	; Scanline 8
	.byte #%11111111	; Scanline 7
	.byte #%11111111	; Scanline 6
	.byte #%11111111	; Scanline 5
	.byte #%11111111	; Scanline 4
	.byte #%11111111	; Scanline 3
	.byte #%11111111	; Scanline 2
	.byte #%11111111	; Scanline 1
	.byte #%11111111	; Scanline 0

Screen_PF1
	.byte #%11111111	; Scanline 191
	.byte #%11111111	; Scanline 190
	.byte #%11111111	; Scanline 189
	.byte #%11111111	; Scanline 188
	.byte #%11111111	; Scanline 187
	.byte #%11111111	; Scanline 186
	.byte #%11111111	; Scanline 185
	.byte #%11111111	; Scanline 184
	.byte #%11111111	; Scanline 183
	.byte #%11111111	; Scanline 182
	.byte #%11111111	; Scanline 181
	.byte #%11111111	; Scanline 180
	.byte #%11111111	; Scanline 179
	.byte #%11111111	; Scanline 178
	.byte #%11111111	; Scanline 177
	.byte #%11111111	; Scanline 176
	.byte #%11111111	; Scanline 175
	.byte #%11111111	; Scanline 174
	.byte #%11111111	; Scanline 173
	.byte #%11111111	; Scanline 172
	.byte #%11111111	; Scanline 171
	.byte #%11111111	; Scanline 170
	.byte #%11111111	; Scanline 169
	.byte #%11111111	; Scanline 168
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
	.byte #%10011001	; Scanline 141
	.byte #%10011001	; Scanline 140
	.byte #%10011001	; Scanline 139
	.byte #%10011001	; Scanline 138
	.byte #%10011001	; Scanline 137
	.byte #%10011001	; Scanline 136
	.byte #%10011001	; Scanline 135
	.byte #%10011001	; Scanline 134
	.byte #%10011001	; Scanline 133
	.byte #%10011001	; Scanline 132
	.byte #%10011001	; Scanline 131
	.byte #%10011001	; Scanline 130
	.byte #%10011001	; Scanline 129
	.byte #%10011001	; Scanline 128
	.byte #%10011001	; Scanline 127
	.byte #%10011001	; Scanline 126
	.byte #%10011001	; Scanline 125
	.byte #%11111111	; Scanline 124
	.byte #%11111111	; Scanline 123
	.byte #%11111111	; Scanline 122
	.byte #%11111111	; Scanline 121
	.byte #%11111111	; Scanline 120
	.byte #%10011001	; Scanline 119
	.byte #%10011001	; Scanline 118
	.byte #%10011001	; Scanline 117
	.byte #%10011001	; Scanline 116
	.byte #%10011001	; Scanline 115
	.byte #%10011001	; Scanline 114
	.byte #%10011001	; Scanline 113
	.byte #%10011001	; Scanline 112
	.byte #%10011001	; Scanline 111
	.byte #%10011001	; Scanline 110
	.byte #%10011001	; Scanline 109
	.byte #%10011001	; Scanline 108
	.byte #%10011001	; Scanline 107
	.byte #%10011001	; Scanline 106
	.byte #%10011001	; Scanline 105
	.byte #%10011001	; Scanline 104
	.byte #%10011001	; Scanline 103
	.byte #%11111111	; Scanline 102
	.byte #%11111111	; Scanline 101
	.byte #%11111111	; Scanline 100
	.byte #%11111111	; Scanline 99
	.byte #%11111111	; Scanline 98
	.byte #%10011001	; Scanline 97
	.byte #%10011001	; Scanline 96
	.byte #%10011001	; Scanline 95
	.byte #%10011001	; Scanline 94
	.byte #%10011001	; Scanline 93
	.byte #%10011001	; Scanline 92
	.byte #%10011001	; Scanline 91
	.byte #%10011001	; Scanline 90
	.byte #%10011001	; Scanline 89
	.byte #%10011001	; Scanline 88
	.byte #%10011001	; Scanline 87
	.byte #%10011001	; Scanline 86
	.byte #%10011001	; Scanline 85
	.byte #%10011001	; Scanline 84
	.byte #%10011001	; Scanline 83
	.byte #%10011001	; Scanline 82
	.byte #%10011001	; Scanline 81
	.byte #%11111111	; Scanline 80
	.byte #%11111111	; Scanline 79
	.byte #%11111111	; Scanline 78
	.byte #%11111111	; Scanline 77
	.byte #%11111111	; Scanline 76
	.byte #%10011001	; Scanline 75
	.byte #%10011001	; Scanline 74
	.byte #%10011001	; Scanline 73
	.byte #%10011001	; Scanline 72
	.byte #%10011001	; Scanline 71
	.byte #%10011001	; Scanline 70
	.byte #%10011001	; Scanline 69
	.byte #%10011001	; Scanline 68
	.byte #%10011001	; Scanline 67
	.byte #%10011001	; Scanline 66
	.byte #%10011001	; Scanline 65
	.byte #%10011001	; Scanline 64
	.byte #%10011001	; Scanline 63
	.byte #%10011001	; Scanline 62
	.byte #%10011001	; Scanline 61
	.byte #%10011001	; Scanline 60
	.byte #%10011001	; Scanline 59
	.byte #%11111111	; Scanline 58
	.byte #%11111111	; Scanline 57
	.byte #%11111111	; Scanline 56
	.byte #%11111111	; Scanline 55
	.byte #%11111111	; Scanline 54
	.byte #%10011001	; Scanline 53
	.byte #%10011001	; Scanline 52
	.byte #%10011001	; Scanline 51
	.byte #%10011001	; Scanline 50
	.byte #%10011001	; Scanline 49
	.byte #%10011001	; Scanline 48
	.byte #%10011001	; Scanline 47
	.byte #%10011001	; Scanline 46
	.byte #%10011001	; Scanline 45
	.byte #%10011001	; Scanline 44
	.byte #%10011001	; Scanline 43
	.byte #%10011001	; Scanline 42
	.byte #%10011001	; Scanline 41
	.byte #%10011001	; Scanline 40
	.byte #%10011001	; Scanline 39
	.byte #%10011001	; Scanline 38
	.byte #%10011001	; Scanline 37
	.byte #%11111111	; Scanline 36
	.byte #%11111111	; Scanline 35
	.byte #%11111111	; Scanline 34
	.byte #%11111111	; Scanline 33
	.byte #%11111111	; Scanline 32
	.byte #%10011001	; Scanline 31
	.byte #%10011001	; Scanline 30
	.byte #%10011001	; Scanline 29
	.byte #%10011001	; Scanline 28
	.byte #%10011001	; Scanline 27
	.byte #%10011001	; Scanline 26
	.byte #%10011001	; Scanline 25
	.byte #%10011001	; Scanline 24
	.byte #%10011001	; Scanline 23
	.byte #%10011001	; Scanline 22
	.byte #%10011001	; Scanline 21
	.byte #%10011001	; Scanline 20
	.byte #%10011001	; Scanline 19
	.byte #%10011001	; Scanline 18
	.byte #%10011001	; Scanline 17
	.byte #%10011001	; Scanline 16
	.byte #%10011001	; Scanline 15
	.byte #%11111111	; Scanline 14
	.byte #%11111111	; Scanline 13
	.byte #%11111111	; Scanline 12
	.byte #%11111111	; Scanline 11
	.byte #%11111111	; Scanline 10
	.byte #%11111111	; Scanline 9
	.byte #%11111111	; Scanline 8
	.byte #%11111111	; Scanline 7
	.byte #%11111111	; Scanline 6
	.byte #%11111111	; Scanline 5
	.byte #%11111111	; Scanline 4
	.byte #%11111111	; Scanline 3
	.byte #%11111111	; Scanline 2
	.byte #%11111111	; Scanline 1
	.byte #%11111111	; Scanline 0

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
	.byte #%00111000	; Scanline 31
	.byte #%00111000	; Scanline 30
	.byte #%00111000	; Scanline 29
	.byte #%00111000	; Scanline 28
	.byte #%00111000	; Scanline 27
	.byte #%00111000	; Scanline 26
	.byte #%00111000	; Scanline 25
	.byte #%00111000	; Scanline 24
	.byte #%00111000	; Scanline 23
	.byte #%00111000	; Scanline 22
	.byte #%00111000	; Scanline 21
	.byte #%00111000	; Scanline 20
	.byte #%00111000	; Scanline 19
	.byte #%00111000	; Scanline 18
	.byte #%00111000	; Scanline 17
	.byte #%00111000	; Scanline 16
	.byte #%00111000	; Scanline 15
	.byte #%00111000	; Scanline 14
	.byte #%00111000	; Scanline 13
	.byte #%00111000	; Scanline 12
	.byte #%00111000	; Scanline 11
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
