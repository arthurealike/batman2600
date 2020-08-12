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
BAT_HEIGHT = #15               
J_HEIGHT = #15            

      SEG code
      org $F000

Reset:
      CLEAN_START              

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
    lda #2
    sta VBLANK               
    sta VSYNC                
    sta WSYNC            
    sta WSYNC            
    sta WSYNC            
    lda #0
    sta VSYNC               
    sta VBLANK   
    ldx #37
VBlank:
    sta WSYNC
    sta VSYNC               
    dex
    bne VBlank
   ; REPEAT 37
   ;     sta WSYNC          
   ; REPEND
   ; sta VBLANK   
    
    jmp GameVisibleLine

; visible 192 lines
GameVisibleLine:
    lda #$01
    sta COLUBK             ; bg
    lda #$A0
    sta COLUPF             ; pf
    lda #%00000001
    sta CTRLPF             ; pf reflection
    lda #$F0
    sta PF0                
    lda #$FC
    sta PF1               
    lda #0
    sta PF2              

      ldx #96               ; visible scanlines
.GameLineLoop:
.IsP0Visible:       ; check if should render p0
      txa                      ; X to A
      sec                      ; carry flag is set
      sbc P0PosY               ; subtract sprite Y coordinate
      cmp BAT_HEIGHT           ; sprite inside height bounds?
      bcc .DrawSpriteP0        ; if result < SpriteHeight, call subroutine
      lda #0                   ; else, set lookup index to 0
.DrawSpriteP0:
      clc                      ; clear carry flag 
      ;adc AnimOffset          ; jump to sprite frame 

      tay                      ; load Y so we can work with pointer

      ; not strecthed
      lda #%0000000
      sta NUSIZ0

      lda (BatSpritePtr),Y     ; load player bitmap slice of data

      sta WSYNC                ; wait for next scanline
      sta GRP0                 ; set graphics for player 0
      lda (BatColorPtr),Y      ; load player color from lookup table
      sta COLUP0               ; set color for player 0 slice

.IsP1Visible:                  ; same shit as p0
      txa                      
      sec                      
      sbc P1PosY               
      cmp J_HEIGHT             
      bcc .DrawSpriteP1        
      lda #0                   
.DrawSpriteP1:
      tay

      lda (JSpritePtr),Y  
      sta WSYNC           
      sta GRP1            
      lda (JColorPtr),Y   
      sta COLUP1          

      dex                 
      bne .GameLineLoop   

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
  ; overscan
    lda #2
    sta VBLANK               
    REPEAT 30
        sta WSYNC            
    REPEND
    lda #0
    sta VBLANK               ; turn off VBLANK

    jmp StartNewFrame           ; next frame

  ; ROM lookup tables

BatSprite:
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
      .byte #%00100100
      .byte #%00100100

JSprite:
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
      .byte #$A5;
      .byte #$04;
      .byte #$04;
      .byte #$19;
      .byte #$04;
      .byte #$04;
      .byte #$04;
      .byte #$A5;
      .byte #$04;
      .byte #$F8;
      .byte #$04;
      .byte #$04;
      .byte #$04;
      .byte #$04;

JColor:
      .byte #$00;
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

      org $FFFA              ;move position
      .word Reset            
      .word Reset            
      .word Reset            
