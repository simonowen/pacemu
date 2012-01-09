; Pac-Man hardware emulation for the SAM Coupe (v1.1)
;
; WWW: http://simonowen.com/sam/pacemu/

base:          equ &8000

; This value determines the number of steps the tiled background is drawn over
; Use 4 for normal 6MHz SAM, with 2 or 1 only suitable for Mayhem accelerator
tile_strips:   equ 4                ; default = 4 strips

lmpr:          equ 250              ; Low Memory Page Register
hmpr:          equ 251              ; High Memory Page Register
vmpr:          equ 252              ; Video Memory Page Register
border:        equ 254              ; Border colour in bits 6, 2-0
keyboard:      equ 254              ; Main keyboard matrix

wprot:         equ %10000000        ; LMPR bit to write-protect first 16K
rom0_off:      equ %00100000        ; LMPR bit to disable ROM 0
mode_4:        equ %01100000        ; VMPR bits for mode 4
pac_page:      equ 3+rom0_off+wprot
screen_1:      equ 8+rom0_off
screen_2:      equ 10+rom0_off
sound_page:    equ 6+rom0_off


pac_header:    equ &43c0            ; 64 bytes containing the score
pac_chars:     equ &4040            ; start of main Pac-Man display (skipping the score rows)
pac_footer:    equ &4000            ; credit and fruit display

bak_chars1:    equ &a040            ; copy of Pac-Man display for screen 1
bak_chars2:    equ &a440            ; copy of Pac-Man display for screen 2
tile_data:     equ &ac00            ; background tile graphics data
spr_data:      equ &be00            ; sprite graphics data
shift_data:    equ &db00            ; pre-shifted graphics data, built from spr_data

hook:          equ &391c            ; safe ROM location for our intrerrupt hook, to fix Hangly Man

; address of saved sprite block followed by the data itself

               autoexec

               org base
spr_save_2:    equ &6000
spr_save_3:    equ spr_save_2+2+7*12
spr_save_4:    equ spr_save_3+2+7*12
spr_save_5:    equ spr_save_4+2+7*12
spr_save_6:    equ spr_save_5+2+7*12
spr_save_7:    equ spr_save_6+2+7*12
spr_save_end:  equ spr_save_7+2+7*12
               dump $
               jr  start

dip_5000:      defb %11111111       ; c21tdrlu     c=credit, 2=coin2, 1=coin1, t=rack test on/off ; down, right, left, up
                                    ; rack test off, nothing else signalled
dip_5040:      defb %11111111       ; c--sdrlu     c=cocktail/upright ; s=service mode on/off ; down, right, left, up (player 2)
                                    ; upright mode, service mode off, no controls pressed
dip_5080:      defb %11001001       ; -dbbllcc      d=hard/normal bb=bonus life at 10K/15K/20K/none ; ll=1/2/3/5 lives ; cc=freeplay/1coin1credit/1coin2credits/2coins1credit
                                    ; normal, bonus life at 10K, 3 lives, 1 coin 1 credit

start:         di

               call patch_rom       ; patch DIP fixed and hook us into the interrupt handling
               call mk_lookups      ; create all the look-up tables
               call sound_init      ; enable sound chip

               ld  a,pac_page
               out (lmpr),a

               ld  a,(dip_5000)
               ld  (&5000),a
               ld  a,(dip_5040)
               ld  (&5040),a
               ld  a,(dip_5080)
               ld  (&5080),a

               ld  hl,palette+15
               ld  bc,&10f8
               defb &ed,&bb         ; set palette (this should be OTDR but Assembly Studio 8x gets it wrong!)

               ld  hl,bak_chars1
               ld  bc,&0840
space_lp:      ld  (hl),c           ; fill tile copy with spaces
               inc l
               jr  nz,space_lp
               inc h
               djnz space_lp

               jp  0                ; start the Pac-Man ROM!

palette:       defb 0,127,34,123,85,106,110,96,6,68,29,25,99,122,122,119


patch_rom:     ld  a,(&3019)
               cp  &af
               ret z                ; return if ROM already patched

               in  a,(lmpr)
               ex  af,af'
               ld  a,pac_page-wprot
               out (lmpr),a

               ld  hl,&0000         ; copy 8K of Pac-Man ROM code
               ld  de,&6000         ; to last 8K of page 4
               ld  bc,&2000
               ldir

               inc a
               out (lmpr),a         ; move up 16K

               ld  hl,&2000         ; copy the copied block
               ld  de,&6000         ; forward another 16K
               ld  bc,&2000
               ldir

               dec a
               out (lmpr),a         ; restore Pac-Man ROM

               ld  hl,hook_block
               ld  de,hook
               ld  bc,hook_end-hook_block
               ldir

               ld  a,&56
               ld  (&233c),a        ; change IM 2 to IM 1
               ld  hl,&47ed
               ld  (&233f),hl       ; change OUT (&00),A to LD I,A
               ld  (&3183),hl
               ld  a,&cd            ; CALL nn
               ld  (&0038),a
               ld  hl,hook
               ld  (&0039),hl
               ld  a,&c3            ; JP nn  (address completed by interrupt handler)
               ld  (&003b),a
               ld  hl,&04d6         ; SUB 4 - restore original instruction in patched bootleg ROMs
               ld  (&3181),hl

               ld  a,&01            ; to change &5000 writes to &5001, which is unused
               ld  (&0093),a
               ld  (&01d7),a
               ld  (&2347),a
               ld  (&238a),a
               ld  (&3194),a
               ld  (&3248),a
               ld  a,&af            ; xor a, to disable ROM checksum check
               ld  (&3019),a
               ld  a,1              ; start clearing at &5001, to avoid DIP overwrite
               ld  (&2353),a
               ld  (&230c),a
               ld  (&2353),a
               ld  a,7              ; shorten block clear after start adjustment above
               ld  (&230f),a
               ld  (&2357),a
               ld  a,&41            ; start clearing at &5041, to avoid DIP overwrite
               ld  (&2363),a
               ld  a,&3f            ; shorten block clear after start adjustment above
               ld  (&2366),a

               ld  a,6              ; LD B,n
               ld  (&30cf),a        ; prevent RAM being completely wiped

               ld  hl,&e0f6         ; OR %11100000, so random numbers are sourced from a clean 8K copy of the ROM
               ld  (&2a2d),hl       ; (failure to do this breaks known maze patterns as the blue ghosts use it!)

               ex  af,af'
               out (lmpr),a
               ret

;
; Our interrupt hook handler, to gain control each frame
;
hook_block:    push af
               ld  a,1
               out (hmpr),a
               call do_stuff
               ld  a,pac_page-rom0_off-wprot+1
               out (hmpr),a
               pop af
               ret
hook_end:


;
; Do everything we need to update video/sound/input
;
do_stuff:      ld  (old_stack+1),sp
               ld  sp,new_stack

               push bc
               call do_flip
               push de
               push hl
               push ix
               push iy
               ex  af,af'
               push af
               exx
               push bc
               push de
               push hl

               ld  a,&ff
               in  a,(keyboard)
               rra
               jr  c,no_border
               ld  a,1
               out (border),a
no_border:
               call do_inthndlr     ; prepare Pac-Man interrupt handler address
;              call do_flip         ; show last frame, prepare for new one
               call flash_maze      ; flash the end of level maze
               call flash_pills     ; flash the power pills

               ld  hl,&5062
               ld  a,(hl)
               ld  (sprite2_x+1),a  ; save sprite 1 x-coord
               inc (hl)             ; offset 1 pixel to the left (mirrored)
               ld  hl,&5064
               ld  a,(hl)
               ld  (sprite3_x+1),a  ; save sprite 2 x-coord
               inc (hl)             ; offset 1 pixel to the left

               call do_restore      ; restore under the old sprites
               call do_tiles        ; update a portion of the background tiles
               call do_save         ; save under the new sprite positions
               call do_sprites      ; draw the 6 new masked sprites
               call do_input        ; scan the joystick and DIP switches
               call do_sound        ; convert the sound to the SAA chip

sprite2_x:     ld  a,0              ; (self-modified value)
               ld  (&5062),a        ; restore sprite 1 x-coord
sprite3_x:     ld  a,0              ; (self-modified value)
               ld  (&5064),a        ; restore sprite 2 x-coord

               xor a
               out (border),a


               pop hl
               pop de
               pop bc
               exx
               pop af
               ex  af,af'
               pop iy
               pop ix
               pop hl
               pop de
               pop bc

old_stack:     ld  sp,0
               ret                  ; return to the normal interrupt processing


; Prepare the Pac-Man interrupt handler address for our return - does an IM2-style
; lookup to determine the address for normal Pac-Man interrupt processing
;
do_inthndlr:   ld  a,pac_page-wprot
               out (lmpr),a

               ld  a,i              ; bus value originally written to port &00
               ld  l,a
               ld  h,&3f            ; normal I value
               ld  a,(hl)           ; handler low
               inc hl
               ld  h,(hl)           ; handler high
               ld  l,a
               ld  (&003c),hl       ; write into JP in interrupt handler

               ret

;
; Flip to show the screen prepared during the last frame, and prepare to draw the next
;
do_flip:       ld  a,(scr_page)     ; current back-screen page
               and %00011111        ; keep only page number
               ld  c,a
               or  mode_4           ; mode 4
               out (vmpr),a         ; view last frame

               ld  a,c
               xor screen_1 ^ screen_2  ; flip
               or  rom0_off         ; disable ROM 0
               ld  (scr_page),a     ; set new back page
               ret

scr_page:      defb screen_1

;
; Set the maze palette colour by detecting the attrbute used for the maze white
; We also need to remove the crypt, as the real attribute wipe does.
;
flash_maze:    ld  a,(&4440)        ; attribute of maze top-right
               cp  &1f
               ld  a,25             ; blue
               jr  nz,maze_blue

               ld  a,64             ; blank tile
               ld  (&420d),a        ; clear left of crypt door
               ld  (&41ed),a        ; clear right of crypt door

               ld  a,119            ; white
maze_blue:     ld  bc,&0bf8
               out (c),a
               ret

;
; Set the power pill palette colour to the correct state by reading the 6 known
; pill locations, and checking the current attribute setting.
;
flash_pills:   ld  de,&1410         ; &14=pill, &10=pill-on colour
               ld  hl,&9f7a         ; &9f=alternative pill-on colour, &7a=SAM pill colour

               ld  a,(&4064)        ; top-right
               cp  d
               jr  nz,pill_2
               ld  a,(&4464)
               cp  e
               jr  z,pill_on

pill_2:        ld  a,(&4078)        ; bottom-right
               cp  d
               jr  nz,pill_3
               ld  a,(&4478)
               cp  e
               jr  z,pill_on

pill_3:        ld  a,(&4384)        ; top-left
               cp  d
               jr  nz,pill_4
               ld  a,(&4784)
               cp  e
               jr  z,pill_on

pill_4:        ld  a,(&4398)        ; bottom-left
               cp  d
               jr  nz,pill_5
               ld  a,(&4798)
               cp  e
               jr  z,pill_on

pill_5:        ld  a,(&4332)        ; top attract pill
               cp  d
               jr  nz,pill_6
               ld  a,(&4732)
               cp  e
               jr  z,pill_on

pill_6:        ld  a,(&4278)        ; bottom attract pill
               cp  d
               jr  nz,pill_off
               ld  a,(&4678)
               cp  e
               jr  z,pill_on
               cp  h                ; alternative static colour
               jr  z,pill_on

pill_off:      ld  l,0              ; black (hidden)
pill_on:       ld  bc,&0ef8
               out (c),l
               ret

;
; Scan the input DIP switches for joystick movement and button presses
;
do_input:      ld  de,&ffff
               ld  a,&f7
               in  a,(keyboard)
               rra
               jr  c,not_1
               res 5,e              ; 1 = start 1
not_1:         rra
               jr  c,not_2
               res 6,e              ; 2 = start 2
not_2:         rra
               jr  c,not_3
               res 5,d              ; 3 = coin 1
               jr  do_arrows
not_3:         rra
               rra
               jr  c,do_arrows
               res 5,d              ; 5 = coin 1

do_arrows:     ld  a,&ff
               in  a,(keyboard)
               rra
               jr  c,not_cntrl
               nop                  ; Cntrl = speed-up cheat, soon?
not_cntrl:     rra
               jr  c,not_up
               res 0,d              ; up
not_up:        rra
               jr  c,not_down
               res 3,d              ; down
not_down:      rra
               jr  c,not_left
               res 1,d              ; left
not_left:      rra
               jr  c,not_right
               res 2,d              ; right

not_right:     ld  a,&fb
               in  a,(249)
               rla
               jr  c,not_f9
               res 4,d              ; f9 = rack test

not_f9:        ld  a,d
               ld  (&5000),a
               ld  a,e
               ld  (&5040),a
               ret

;
; Draw the background tile changes, in 8 steps over the 2 double-buffered screens
;
do_tiles:
tile_state:    ld  a,0              ; (self-modified value)
               inc a
               ld  (tile_state+1),a

IF tile_strips == 1

               and %00000001
               jr  z,step_0
               jr  step_1
            
step_0:        ld  b,28
               ld  de,pac_chars
               ld  hl,bak_chars1
               call tile_comp
               ld  hl,bak_chars1
               call do_fruit
               ld  hl,bak_chars1
               call do_lives
               ld  hl,bak_chars1
               call do_score1
               ld  hl,bak_chars1
               jp  do_score2

step_1:        ld  b,28
               ld  de,pac_chars
               ld  hl,bak_chars2
               call tile_comp
               ld  hl,bak_chars2
               call do_fruit
               ld  hl,bak_chars2
               call do_lives
               ld  hl,bak_chars2
               call do_score1
               ld  hl,bak_chars2
               jp  do_score2

ELSE IF tile_strips == 2

               and %00000011
               jr  z,step_0
               dec a
               jr  z,step_1
               dec a
               jr  z,step_2
               jr  step_3
            
step_0:        ld  b,14
               ld  de,pac_chars
               ld  hl,bak_chars1
               call tile_comp
               ld  hl,bak_chars1
               call do_fruit
               ld  hl,bak_chars1
               jp  do_lives

step_1:        ld  b,14
               ld  de,pac_chars
               ld  hl,bak_chars2
               call tile_comp
               ld  hl,bak_chars2
               call do_fruit
               ld  hl,bak_chars2
               jp  do_lives

step_2:        ld  b,14
               ld  de,pac_chars+(32*14)
               ld  hl,bak_chars1+(32*14)
               call tile_comp
               ld  hl,bak_chars1
               call do_score1
               ld  hl,bak_chars1
               jp  do_score2

step_3:        ld  b,14
               ld  de,pac_chars+(32*14)
               ld  hl,bak_chars2+(32*14)
               call tile_comp
               ld  hl,bak_chars2
               call do_score1
               ld  hl,bak_chars2
               jp  do_score2

ELSE

               and %00000111
               jr  z,step_0
               dec a
               jr  z,step_1
               dec a
               jr  z,step_2
               dec a
               jr  z,step_3
               dec a
               jr  z,step_4
               dec a
               jr  z,step_5
               dec a
               jr  z,step_6
               jr  step_7

step_0:        ld  b,7
               ld  de,pac_chars
               ld  hl,&a040
               call tile_comp
               ld  hl,bak_chars1
               jp  do_fruit

step_1:        ld  b,7
               ld  de,pac_chars
               ld  hl,&a440
               call tile_comp
               ld  hl,bak_chars2
               jp  do_fruit

step_2:        ld  b,7
               ld  de,pac_chars+(32*7)
               ld  hl,&a040+(32*7)
               call tile_comp
               ld  hl,bak_chars1
               jp  do_lives

step_3:        ld  b,7
               ld  de,pac_chars+(32*7)
               ld  hl,&a440+(32*7)
               call tile_comp
               ld  hl,bak_chars2
               jp  do_lives

step_4:        ld  b,7
               ld  de,pac_chars+(32*14)
               ld  hl,&a040+(32*14)
               call tile_comp
               ld  hl,bak_chars1
               jp  do_score1

step_5:        ld  b,7
               ld  de,pac_chars+(32*14)
               ld  hl,&a440+(32*14)
               call tile_comp
               ld  hl,bak_chars2
               jp  do_score1

step_6:        ld  b,7
               ld  de,pac_chars+(32*21)
               ld  hl,&a040+(32*21)
               call tile_comp
               ld  hl,bak_chars1
               jp  do_score2

step_7:        ld  b,7
               ld  de,pac_chars+(32*21)
               ld  hl,&a440+(32*21)
               call tile_comp
               ld  hl,bak_chars2
               jp  do_score2
ENDIF

tile_comp:     call find_change
               dec sp               ; restore the same return address to here
               dec sp

               ld  c,a              ; keep the tile for later
               push bc
               push de
               push hl

               ex  af,af'           ; save tile number for later

               set 2,d              ; switch to attributes data
               ld  a,(de)           ; pick up current attribute
               ld  b,a              ; save for later
               res 2,d

               ld  a,e
               and %00011111        ; row is in bottom 5 bits
               ld  c,a
               add a,a
               add a,c              ; multiply by 3 to give high byte on screen
               ld  h,a

               ex  de,hl
               add hl,hl
               add hl,hl            ; overflow strips unwanted 2 top bits
               add hl,hl            ; H now holds the mirrored column number
               ld  a,28+2           ; 28 columns wide, offset 2 by additional rows
               sub h                ; unmirror the column number
               ld  c,a
               add a,a
               add a,c              ; multiply by 3 to give screen line offset
               add a,19             ; centre on screen
               ld  e,a

tile_cont:     ex  af,af'

               call draw_tile

               pop hl
               pop de
               pop bc

               jr  c,next_tile      ; skip deferred updates
               ld  (hl),c           ; update the changed tile in the copy

next_tile:     ld  a,e
               and %00011111
               ld  c,a
               add a,a
               add a,a
               add a,c
               add a,3

               ld  ixl,a
               ld  ixh,find_change/256
               jp  (ix)             ; restart where we were interrupted

draw_tile:     ld  c,a              ; save for later
               add a,a
               ld  l,a
               ld  a,tile_table/256
               adc a,0
               ld  h,a
               ld  a,(hl)
               inc l
               ld  h,(hl)
               ld  l,a

               ld  a,(scr_page)
               out (lmpr),a

               ld  a,c              ; tile char
               exx
               ld  l,a
               ld  h,special_tab/256
               cp  (hl)             ; needs colour?
               exx
               jr  z,special_tile

not_text:      ld  c,255            ; ensure B remains unchanged in LDIs below
               ld  b,e              ; low byte of even lines
               ld  a,b
               or  %10000000        ; low byte of odd lines

               ldi
               ldi
               ldi
               ld  e,a
               ldi
               ldi
               ldi
               inc d
               ld  e,b
               ldi
               ldi
               ldi
               ld  e,a
               ldi
               ldi
               ldi
               inc d
               ld  e,b
               ldi
               ldi
               ldi
               ld  e,a
               ldi
               ldi
               ldi

tile_drawn:    and a                ; clear carry to indicate we drew the tile

tile_exit:     ld  a,pac_page
               out (lmpr),a
               ret

; Handle coloured tiles: text and ghost tiles in different colours
special_tile:  cp  176
               jr  nc,ghost_tile

               ld  a,b
               and %00001111
               ld  c,a
               ld  b,textcol_tab/256
               ld  a,(bc)
               ld  c,a

               and a                ; black attribute?
               scf                  ; set carry to signal a deferred update
               jr  z,tile_exit      ; wait until a colour is present

               ld  b,3
colour_lp:     ld  a,(hl)
               and c
               ld  (de),a  ; 0
               inc hl
               inc e

               ld  a,(hl)
               and c
               ld  (de),a  ; 1
               inc hl
               inc e

               ld  a,(hl)
               and c
               ld  (de),a  ; 2
               inc hl

               ld  a,e
               add a,128-2          ; down a line
               ld  e,a

               ld  a,(hl)
               and c
               ld  (de),a  ; 3
               inc hl
               inc e

               ld  a,(hl)
               and c
               ld  (de),a  ; 4
               inc hl
               inc e

               ld  a,(hl)
               and c
               ld  (de),a  ; 5
               inc hl

               ld  a,e
               add a,128-2 ; down a line
               ld  e,a
               inc d

               djnz colour_lp
               jr  tile_drawn

; Look-up masks used to give the correct colour from a Pac-Man attribute
text_cols:     defb &00,&22,&99,&33,&99,&44,&99,&55,&99,&66,&99,&99,&99,&99,&cc,&ff

; The colour of ghost tiles depends on the attribute used
ghost_tile:    ld  a,b
               dec a
               jp  z,not_text       ; red ghost - no change needed
               ld  bc,18*6
               add hl,bc
               rra
               dec a
               jp  z,not_text       ; pink ghost
               add hl,bc
               dec a
               jp  z,not_text       ; cyan ghost
               add hl,bc
               jp  not_text         ; orange ghost

;
; Draw a 12x12 mask sprite
;
draw_spr:      ld  a,h
               cp  16
               ret c                ; off bottom of screen
               ld  a,l
               cp  16
               ret c                ; off right of screen

               ld  a,d
               and a
               ret z                ; sprite palette all black

               call xy_to_addr
               push hl
               jr  c,draw_shift

               call map_spr         ; map sprites to the correct orientation/colour

draw_spr2:     ex  de,hl
               add a,a
               ld  l,a
               ld  h,spr_table/256
               ld  a,(hl)
               inc l
               ld  h,(hl)
               ld  l,a
               ex  de,hl

               exx
               ld  b,12

               ld  a,(scr_page)
               out (lmpr),a

spr_loop:      exx
               ld  b,mask_table/256

               ld  a,(de)
               ld  c,a
               ld  a,(bc)
               and (hl)
               or  c
               ld  (hl),a
               inc l
               inc de

               ld  a,(de)
               ld  c,a
               ld  a,(bc)
               and (hl)
               or  c
               ld  (hl),a
               inc l
               inc de

               ld  a,(de)
               ld  c,a
               ld  a,(bc)
               and (hl)
               or  c
               ld  (hl),a
               inc l
               inc de

               ld  a,(de)
               ld  c,a
               ld  a,(bc)
               and (hl)
               or  c
               ld  (hl),a
               inc l
               inc de

               ld  a,(de)
               ld  c,a
               ld  a,(bc)
               and (hl)
               or  c
               ld  (hl),a
               inc l
               inc de

               ld  a,(de)
               ld  c,a
               ld  a,(bc)
               and (hl)
               or  c
               ld  (hl),a
               inc de

               ld  bc,128-5
               add hl,bc

               exx
               djnz spr_loop

post_trim:     pop hl

               ld  a,l
               cp  128
               jr  c,draw_exit      ; sprites are never vertically even-aligned in the tunnels
               cp  128+16+6
               ld  l,16
               call c,trim_tunnel   ; trim sprite against left tunnel
               cp  128+106-6
               ld  l,106
               call nc,trim_tunnel  ; trim sprite against right tunnel

draw_exit:     ld  a,pac_page
               out (lmpr),a
               ret

;
; Draw a sprite at a an odd x-coordinate, using pre-shifted graphics data
;
draw_shift:    call map_spr         ; map sprites to the correct orientation/colour

               ex  de,hl
               add a,a
               ld  l,a
               ld  h,shift_table/256
               ld  a,(hl)
               inc l
               ld  h,(hl)
               ld  l,a
               ex  de,hl

               exx
               ld  b,12

               ld  a,(scr_page)
               out (lmpr),a

spr_loop2:     exx
               ld  b,mask_table/256

               ld  a,(de)      ; 1
               ld  c,a
               ld  a,(bc)
               and (hl)
               or  c
               ld  (hl),a
               inc l
               inc de

               ld  a,(de)      ; 2
               ld  c,a
               ld  a,(bc)
               and (hl)
               or  c
               ld  (hl),a
               inc l
               inc de

               ld  a,(de)      ; 3
               ld  c,a
               ld  a,(bc)
               and (hl)
               or  c
               ld  (hl),a
               inc l
               inc de

               ld  a,(de)      ; 4
               ld  c,a
               ld  a,(bc)
               and (hl)
               or  c
               ld  (hl),a
               inc l
               inc de

               ld  a,(de)      ; 5
               ld  c,a
               ld  a,(bc)
               and (hl)
               or  c
               ld  (hl),a
               inc l
               inc de

               ld  a,(de)      ; 6
               ld  c,a
               ld  a,(bc)
               and (hl)
               or  c
               ld  (hl),a
               inc l
               inc de

               ld  a,(de)      ; 7
               ld  c,a
               ld  a,(bc)
               and (hl)
               or  c
               ld  (hl),a
               inc de

               ld  bc,128-6
               add hl,bc

               exx
               djnz spr_loop2
               jr  post_trim


map_spr:       ld  b,0
               ld  a,e
               srl a
               rl  b
               rra
               rl  b
               cp  32
               jr  nc,maybe_ghost
               cp  28               ; static images
               ret c
               cp  30
               ret nc               ; unknown blanks
               ld  c,a
               ld  a,d
               cp  &11              ; blue ghost
               ld  a,c
               ret z
               add a,72             ; white flashing ghost
               ret

maybe_ghost:   cp  40
               jr  nc,not_ghost

               dec d
               ret z                ; red
               srl d
               add a,32
               dec d
               ret z                ; pink
               add a,8
               dec d
               ret z                ; cyan
               add a,8
               dec d
               ret z                ; orange
               add a,8
               ret                  ; eyes

not_ghost:     cp  48               ; static images and SAM images
               ret nc
               cp  44               ; ghost scores
               ret c

               inc b
               dec b
               ret z                ; pacman right/down
               add a,52             ; offset to flipped set
               ret                  ; pacman left/up

;
; Trim sprites that overlap the maze edges, as the real hardware does automatically
;
trim_tunnel:   ex  af,af'
               ld  a,l
               and %01111111
               ld  e,a              ; even line position
               or  %10000000
               ld  d,a              ; odd line position
               xor a
               ld  b,7

trim_lp:       ld  (hl),a
               inc l
               ld  (hl),a
               inc l
               ld  (hl),a
               inc l
               ld  (hl),a
               inc l
               ld  (hl),a
               inc l
               ld  (hl),a
               ld  l,d
               ld  (hl),a
               inc l
               ld  (hl),a
               inc l
               ld  (hl),a
               inc l
               ld  (hl),a
               inc l
               ld  (hl),a
               inc l
               ld  (hl),a
               inc h
               ld  l,e

               djnz trim_lp
               ex  af,af'
               ret

;
; Clear a sprite-sized hole, used for blank tiles in our fruit and lives display
;
blank_sprite:  ld  a,(scr_page)
               out (lmpr),a

               ld  a,l
               and %01111111
               ld  e,a              ; even line position
               or  %10000000
               ld  d,a              ; odd line position
               xor a
               ld  b,6

blank_lp:      ld  (hl),a
               inc l
               ld  (hl),a
               inc l
               ld  (hl),a
               inc l
               ld  (hl),a
               inc l
               ld  (hl),a
               inc l
               ld  (hl),a
               ld  l,d
               ld  (hl),a
               inc l
               ld  (hl),a
               inc l
               ld  (hl),a
               inc l
               ld  (hl),a
               inc l
               ld  (hl),a
               inc l
               ld  (hl),a
               inc h
               ld  l,e

               djnz blank_lp

               ld  a,pac_page
               out (lmpr),a

               ret

; Save the background screen behind locations we're about to draw active sprites
;
do_save:       ld  hl,(&5062)
               push hl
               ld  hl,(&5064)
               push hl
               ld  hl,(&5066)
               push hl
               ld  hl,(&5068)
               push hl
               ld  hl,(&506a)
               push hl
               ld  hl,(&506c)

               ld  a,(scr_page)
               out (lmpr),a

               ld  de,spr_save_7
               call spr_save

               pop hl
               ld  de,spr_save_6
               call spr_save

               pop hl
               ld  de,spr_save_5
               call spr_save

               pop hl
               ld  de,spr_save_4
               call spr_save

               pop hl
               ld  de,spr_save_3
               call spr_save

               pop hl
               ld  de,spr_save_2
               call spr_save

               ld  a,pac_page
               out (lmpr),a
               ret

; Save a single sprite-sized block, if visible
spr_save:      ld  a,h
               cp  &10              ; off bottom?
               ret c
               ld  a,l
               inc a                ; catch 255 as invalid
               cp  &11              ; off right?
               ret c

               call xy_to_addr      ; convert to SAM coords

               ex  de,hl
               ld  (hl),e           ; save address low
               inc l
               ld  (hl),d           ; save address high
               inc l
               ex  de,hl

               ld  c,7*12           ; 7 bytes for each 12 lines

               ld  a,l              ; assume even for now
               ld  b,l
               set 7,b              ; force odd
               cp  b                ; same as other?
               jr  nz,save_even     ; jump if even start
               and %01111111        ; force even
               jp  save_odd         ; odd start

save_even:     ldi      ; 0
               ldi
               ldi
               ldi
               ldi
               ldi
               ldi
               ld  l,b
save_odd:      ldi      ; 1
               ldi
               ldi
               ldi
               ldi
               ldi
               ldi
               inc h
               ld  l,a
               ldi      ; 2
               ldi
               ldi
               ldi
               ldi
               ldi
               ldi
               ld  l,b
               ldi      ; 3
               ldi
               ldi
               ldi
               ldi
               ldi
               ldi
               inc h
               ld  l,a
               ldi      ; 4
               ldi
               ldi
               ldi
               ldi
               ldi
               ldi
               ld  l,b
               ldi      ; 5
               ldi
               ldi
               ldi
               ldi
               ldi
               ldi
               inc h
               ld  l,a
               ldi      ; 6
               ldi
               ldi
               ldi
               ldi
               ldi
               ldi
               ld  l,b
               ldi      ; 7
               ldi
               ldi
               ldi
               ldi
               ldi
               ldi
               inc h
               ld  l,a
               ldi      ; 8
               ldi
               ldi
               ldi
               ldi
               ldi
               ldi
               ld  l,b
               ldi      ; 9
               ldi
               ldi
               ldi
               ldi
               ldi
               ldi
               inc h
               ld  l,a
               ldi      ; 10
               ldi
               ldi
               ldi
               ldi
               ldi
               ldi
               ld  l,b
               ld  b,0  ; BC is now the remaining count
               ldi      ; 11
               ldi
               ldi
               ldi
               ldi
               ldi
               ldi
               ret po   ; skip last line if even start
               inc h
               ld  l,a
               ldi      ; 12
               ldi
               ldi
               ldi
               ldi
               ldi
               ldi
               ret

;
; Remove the previous sprites by restoring the image that was underneath them
;
do_restore:    ld  a,(scr_page)
               out (lmpr),a

               ld  hl,spr_save_2
               call spr_restore
               ld  hl,spr_save_3
               call spr_restore
               ld  hl,spr_save_4
               call spr_restore
               ld  hl,spr_save_5
               call spr_restore
               ld  hl,spr_save_6
               call spr_restore
               ld  hl,spr_save_7
               call spr_restore

               ld  a,pac_page
               out (lmpr),a
               ret

; Restore a single sprite-sized block, if data was saved
spr_restore:   ld  a,(hl)
               and a
               ret z                ; no data saved
               ld  (hl),0           ; flag 'no restore data'

               ld  e,a              ; restore address low
               inc l
               ld  d,(hl)           ; restore address high
               inc l

               ld  c,7*12           ; 7 bytes for each 12 lines

               ld  a,e              ; assume even for now
               ld  b,e
               set 7,b              ; force odd
               cp  b                ; same as other?
               jr  nz,restore_even  ; jump if even start
               and %01111111        ; force even
               jp  restore_odd      ; odd start

restore_even:  ldi      ; 0
               ldi
               ldi
               ldi
               ldi
               ldi
               ldi
               ld  e,b
restore_odd:   ldi      ; 1
               ldi
               ldi
               ldi
               ldi
               ldi
               ldi
               inc d
               ld  e,a
               ldi      ; 2
               ldi
               ldi
               ldi
               ldi
               ldi
               ldi
               ld  e,b
               ldi      ; 3
               ldi
               ldi
               ldi
               ldi
               ldi
               ldi
               inc d
               ld  e,a
               ldi      ; 4
               ldi
               ldi
               ldi
               ldi
               ldi
               ldi
               ld  e,b
               ldi      ; 5
               ldi
               ldi
               ldi
               ldi
               ldi
               ldi
               inc d
               ld  e,a
               ldi      ; 6
               ldi
               ldi
               ldi
               ldi
               ldi
               ldi
               ld  e,b
               ldi      ; 7
               ldi
               ldi
               ldi
               ldi
               ldi
               ldi
               inc d
               ld  e,a
               ldi      ; 8
               ldi
               ldi
               ldi
               ldi
               ldi
               ldi
               ld  e,b
               ldi      ; 9
               ldi
               ldi
               ldi
               ldi
               ldi
               ldi
               inc d
               ld  e,a
               ldi      ; 10
               ldi
               ldi
               ldi
               ldi
               ldi
               ldi
               ld  e,b
               ld  b,0  ; BC is now the remaining count
               ldi      ; 11
               ldi
               ldi
               ldi
               ldi
               ldi
               ldi
               ret po   ; skip last line if even start
               inc d
               ld  e,a
               ldi      ; 12
               ldi
               ldi
               ldi
               ldi
               ldi
               ldi
               ret


; Draw the currently visible sprites, in the correct order for overlaps
;
do_sprites:    ld  hl,(&506c)
               ld  de,(&4ffc)
               call draw_spr        ; fruit

               ld  hl,(&506a)
               ld  de,(&4ffa)
               call draw_spr        ; pacman

               ld  hl,(&5068)
               ld  de,(&4ff8)
               call draw_spr        ; orange ghost

               ld  hl,(&5066)
               ld  de,(&4ff6)
               call draw_spr        ; cyan ghost

               ld  hl,(&5064)
               ld  de,(&4ff4)
               call draw_spr        ; pink ghost

               ld  hl,(&5062)
               ld  de,(&4ff2)
               call draw_spr        ; red ghost

               ret


do_score1:     inc h
               inc h
               inc h                ; advance to header area containing score

               ld  l,&da
               ld  de,&0009
               call chk_digit       ; 1

               ld  l,&d9
               ld  de,&000c
               call chk_digit       ; U

               ld  l,&d8
               ld  de,&000f
               call chk_digit       ; P


               ld  l,&fc
               ld  de,&0300
               call chk_digit       ; 100,000s

               ld  l,&fb
               ld  de,&0303
               call chk_digit       ; 10,000s

               ld  l,&fa
               ld  de,&0306
               call chk_digit       ; 1,000s

               ld  l,&f9
               ld  de,&0309
               call chk_digit       ; 100s

               ld  l,&f8
               ld  de,&030c
               call chk_digit       ; 10s

               ld  l,&f7
               ld  de,&030f
               call chk_digit       ; 1s

               ret

;
do_score2:     inc h
               inc h
               inc h                ; advance to header area containing score

               ld  l,&c7
               ld  de,&0072
               call chk_digit       ; 2

               ld  l,&c6
               ld  de,&0075
               call chk_digit       ; U

               ld  l,&c5
               ld  de,&0078
               call chk_digit       ; P


               ld  l,&e9
               ld  de,&036c
               call chk_digit       ; 100,000s

               ld  l,&e8
               ld  de,&036f
               call chk_digit       ; 10,000s

               ld  l,&e7
               ld  de,&0372
               call chk_digit       ; 1,000s

               ld  l,&e6
               ld  de,&0375
               call chk_digit       ; 100s

               ld  l,&e5
               ld  de,&0378
               call chk_digit       ; 10s

               ld  l,&e4
               ld  de,&037b
               call chk_digit       ; 1s

               ret



chk_digit:     ld  b,&43
               ld  c,l
               ld  a,(bc)
               cp  (hl)
               ret z
               ld  (hl),a

               push hl
               call draw_tile
               pop hl
               ret

;
; Draw changes to the fruit display, which is remapped to a vertical layout
; We use the sprite versions of the tiles, for easier drawing :-)
;
do_fruit:      ld  l,5
               ld  d,&5a
               push hl
               call chk_fruit
               pop hl

               ld  l,7
               ld  d,&54
               push hl
               call chk_fruit
               pop hl

               ld  l,9
               ld  d,&4e
               push hl
               call chk_fruit
               pop hl

               ld  l,11
               ld  d,&48
               push hl
               call chk_fruit
               pop hl

               ld  l,13
               ld  d,&42
               push hl
               call chk_fruit
               pop hl

               ld  l,15
               ld  d,&3c
               push hl
               call chk_fruit
               pop hl

               ld  l,17
               ld  d,&36
               push hl
               call chk_fruit
               pop hl

               ret

chk_fruit:     ld  e,&70            ; screen offset for fruit column
               ld  b,&40
               ld  c,l
               ld  a,(bc)
               cp  (hl)
               ret z
               ld  (hl),a
               ex  de,hl

               ex  af,af'
               push hl
               call blank_sprite
               pop hl
               ex  af,af'
               cp  64               ; blank?
               ret z

               sub &91
               srl a
               srl a
               push hl
               jp  draw_spr2

;
; Draw changes to the number of remaining lives
;
do_lives:      ld  l,&1b
               ld  de,&5a0a
               push hl
               call chk_life
               pop hl

               ld  l,&19
               ld  de,&540a
               push hl
               call chk_life
               pop hl

               ld  l,&17
               ld  de,&4e0a
               push hl
               call chk_life
               pop hl

               ld  l,&15
               ld  de,&480a
               push hl
               call chk_life
               pop hl

               ld  l,&13
               ld  de,&420a
               push hl
               call chk_life
               pop hl

               ret

; Draw either a blank or a left-facing Pac-Man sprite
chk_life:      ld  b,&40
               ld  c,l
               ld  a,(bc)
               cp  (hl)
               ret z
               ld  (hl),a
               ex  de,hl

               ex  af,af'
               push hl
               call blank_sprite
               pop hl
               ex  af,af'
               cp  64               ; blank?
               ret z
               ld  a,96
               push hl
               jp  draw_spr2

;
; Initialise the SAA 1099 chip, enabling the voices we need (silent initially)
;
sound_init:    ld  bc,&1ff

               ld  a,28
               out (c),a
               ld  a,b
               dec b
               out (c),a
               inc b

               ld  a,20
               out (c),a
               ld  a,%00010101      ; enable voices 0, 2 and 4
               dec b
               out (c),a
               inc b

               xor a
               ld  e,a
               out (c),e
               dec b
               out (c),a
               inc b

               ld  e,2
               out (c),e
               dec b
               out (c),a
               inc b

               ld  e,4
               out (c),e
               dec b
               out (c),a

               ret

;
; Map the current sound chip frequencies to the SAA
;
do_sound:      ld  hl,&5051         ; voice 0 freq and volume
               ld  a,(&5045)        ; voice 0 waveform
               call map_sound
               ld  de,&1008         ; register 0 for volume, register 8 for note
               xor a
               call play_sound

               ld  hl,&5051+5       ; voice 1 freq and volume
               ld  a,(&504a)        ; voice 1 waveform
               call map_sound
               ld  de,&110a         ; register 2 for volume, register 10 for note
               ld  a,2
               call play_sound

               ld  hl,&5051+5+5     ; voice 2 freq and volume
               ld  a,(&504f)        ; voice 2 waveform
               call map_sound
               ld  de,&120c         ; register 4 for volume, register 12 for note
               ld  a,4
               call play_sound

               ret

; Convert the Pac-Man frequency nibbles to a SAM octave and note number
; uses a 16K look-up table, as I couldn't think of a better way!
map_sound:     ld  b,a              ; save waveform

               ld  a,(hl)
               and %00001111
               add a,a
               add a,a
               add a,a
               add a,a
               ld  e,a
               inc hl
               ld  a,(hl)
               and %00001111
               ld  d,a
               inc hl
               ld  a,(hl)
               add a,a
               add a,a
               add a,a
               add a,a
               or  d
               ld  d,a
               or  e                ; check for zero frequency
               inc hl
               inc hl
               ld  a,(hl)           ; volume
               ex  de,hl

               jr  nz,not_silent
               xor a                ; zero frequency gives silence
not_silent:    ld  c,a
               add a,a
               add a,a
               add a,a
               add a,a
               or  c                ; mirror left-right channels
               ex  af,af'

               ld  a,b
               cp  5                ; waveform used when eating ghost?
               jr  z,eat_sound      ; don't divide freq by 8

               srl h
               rr  l
               srl h
               rr  l
               srl h
               rr  l

eat_sound:     ld  a,sound_page
               out (lmpr),a

               add hl,hl            ; 2 bytes per entry
               ld  a,(hl)           ; pick up octave
               inc hl
               ld  l,(hl)           ; pick up note number
               ld  h,a

               ld  a,pac_page
               out (lmpr),a

               ret

; Update a single voice, setting the volume, note and octave
play_sound:    ld  bc,&1ff          ; sound register port

               out (c),a            ; volume register
               dec b
               ex  af,af'
               out (c),a            ; volume data
               inc b

               out (c),e            ; note register
               dec b
               out (c),l            ; note data
               inc b

               out (c),d            ; octave register
               dec b
               out (c),h            ; octave data

               ret


;
; Create the look-up tables used to speed up various calculations
;
mk_lookups:    ld  bc,conv_8_6
               xor a

conv_loop:     ld  (bc),a           ; 0
               inc a
               inc c
               ld  (bc),a           ; 1
               inc a
               inc c
               ld  (bc),a           ; 2
               inc c
               ld  (bc),a           ; 2, etc. (repeating pattern)
               inc a
               inc c
               jr  nz,conv_loop

               ld  hl,x_conv
               ld  de,y_conv

mklookup:      xor a
               sub l                ; mirror y-axis
               ld  c,a
               ld  a,(bc)           ; map to SAM coords
               ld  (de),a
               inc e

               xor a
               sub e                ; mirror x-axis
               ld  c,a
               ld  a,(bc)           ; map to SAM coords
               add a,32             ; centre on SAM display
               ld  (hl),a
               inc l

               jr  nz,mklookup


               ld  hl,mask_table+1
               xor a
mask_lp:       ld  (hl),a
               inc l
               jr  nz,mask_lp

               ld  (hl),&ff         ; keep both pixels

               ld  l,&0f
mask_low:      ld  (hl),&f0         ; keep left pixel
               dec l
               jr  nz,mask_low

               ld  l,&f0
mask_high:     ld  (hl),&0f         ; keep right pixel
               ld  a,l
               sub &10
               ld  l,a
               jr  nz,mask_high

               xor a
               ld  hl,tile_data
               ld  de,tile_table
               ld  bc,3*6
tile_tab_lp:   ex  de,hl
               ld  (hl),e
               inc l
               ld  (hl),d
               inc hl
               ex  de,hl
               add hl,bc
               dec a
               jr  nz,tile_tab_lp

               ld  a,102
               ld  hl,spr_data
               ld  de,spr_table
               ld  bc,6*12
spr_tab_lp:    ex  de,hl
               ld  (hl),e
               inc l
               ld  (hl),d
               inc l
               ex  de,hl
               add hl,bc
               dec a
               jr  nz,spr_tab_lp

               ld  a,102
               ld  hl,shift_data
               ld  de,shift_table
               ld  bc,7*12
shf_tab_lp:    ex  de,hl
               ld  (hl),e
               inc l
               ld  (hl),d
               inc l
               ex  de,hl
               add hl,bc
               dec a
               jr  nz,shf_tab_lp

               ld  hl,spr_data
               ld  de,shift_data
               ld  bc,102*6*12
copy_lp:       xor a
               ldi
               ldi
               ldi
               ldi
               ldi
               ldi
               ld  (de),a           ; clear shift byte
               inc de
               ld  a,b
               or  c
               jr  nz,copy_lp

               ld  hl,shift_data
               ld  bc,102*6
shift_lp:      xor a
               rrd      ; 1
               inc hl
               rrd      ; 2
               inc hl
               rrd      ; 3
               inc hl
               rrd      ; 4
               inc hl
               rrd      ; 5
               inc hl
               rrd      ; 6
               inc hl
               rrd      ; 7
               inc hl
               rrd      ; 8
               inc hl
               rrd      ; 9
               inc hl
               rrd      ; 10
               inc hl
               rrd      ; 11
               inc hl
               rrd      ; 12
               inc hl
               rrd      ; 13
               inc hl
               rrd      ; 14
               inc hl

               dec bc
               ld  a,b
               or  c
               jr  nz,shift_lp


               ld  hl,special_tab
               xor a
spec_clear:    ld  (hl),a
               inc l
               jr  nz,spec_clear
               dec (hl)             ; the first entry shouldn't match later

               ld  l,"0"
               ld  b,12             ; 0-9 / -
text_1:        ld  (hl),l
               inc l
               djnz text_1

               ld  l,"A"
               ld  b,31             ; A-Z ! (c) PTS
text_2:        ld  (hl),l
               inc l
               djnz text_2

               ld  l,38             ; "
               ld  (hl),l
               inc l
               ld  (hl),l

               ld  l,176            ; red ghost
               ld  b,6
text_3:        ld  (hl),l
               inc l
               djnz text_3

               ld  hl,text_cols
               ld  de,textcol_tab
               ld  bc,16
               ldir                 ; copy text colour table to page boundary

               ret

;
; Map a Pac-Man screen coordinate to a SAM display address, scaling down from 8x8 to 6x6 as we go
;
xy_to_addr:    ld  b,y_conv/256
               ld  c,h
               ld  a,(bc)           ; look up y coord

               ld  h,x_conv/256
               ld  l,(hl)           ; look up x coord
               ld  h,a

               srl h                ; convert to SAM display address
               rr  l
               ret


               defs -$\256          ; align to next 256-byte boundary
;
; Scan a 32-byte block for changes, used for fast scanning of the Pac-Man display
; Aligned on a 256-byte boundary for easy resuming of the scanning
find_change:   ld  a,(de)   ; 0
               cp  (hl)
               ret nz
               inc e
               inc l

               ld  a,(de)   ; 1
               cp  (hl)
               ret nz
               inc e
               inc l

               ld  a,(de)   ; 2
               cp  (hl)
               ret nz
               inc e
               inc l

               ld  a,(de)   ; 3
               cp  (hl)
               ret nz
               inc e
               inc l

               ld  a,(de)   ; 4
               cp  (hl)
               ret nz
               inc e
               inc l

               ld  a,(de)   ; 5
               cp  (hl)
               ret nz
               inc e
               inc l

               ld  a,(de)   ; 6
               cp  (hl)
               ret nz
               inc e
               inc l

               ld  a,(de)   ; 7
               cp  (hl)
               ret nz
               inc e
               inc l

               ld  a,(de)   ; 8
               cp  (hl)
               ret nz
               inc e
               inc l

               ld  a,(de)   ; 9
               cp  (hl)
               ret nz
               inc e
               inc l

               ld  a,(de)   ; 10
               cp  (hl)
               ret nz
               inc e
               inc l

               ld  a,(de)   ; 11
               cp  (hl)
               ret nz
               inc e
               inc l

               ld  a,(de)   ; 12
               cp  (hl)
               ret nz
               inc e
               inc l

               ld  a,(de)   ; 13
               cp  (hl)
               ret nz
               inc e
               inc l

               ld  a,(de)   ; 14
               cp  (hl)
               ret nz
               inc e
               inc l

               ld  a,(de)   ; 15
               cp  (hl)
               ret nz
               inc e
               inc l

               ld  a,(de)   ; 16
               cp  (hl)
               ret nz
               inc e
               inc l

               ld  a,(de)   ; 17
               cp  (hl)
               ret nz
               inc e
               inc l

               ld  a,(de)   ; 18
               cp  (hl)
               ret nz
               inc e
               inc l

               ld  a,(de)   ; 19
               cp  (hl)
               ret nz
               inc e
               inc l

               ld  a,(de)   ; 20
               cp  (hl)
               ret nz
               inc e
               inc l

               ld  a,(de)   ; 21
               cp  (hl)
               ret nz
               inc e
               inc l

               ld  a,(de)   ; 22
               cp  (hl)
               ret nz
               inc e
               inc l

               ld  a,(de)   ; 23
               cp  (hl)
               ret nz
               inc e
               inc l

               ld  a,(de)   ; 24
               cp  (hl)
               ret nz
               inc e
               inc l

               ld  a,(de)   ; 25
               cp  (hl)
               ret nz
               inc e
               inc l

               ld  a,(de)   ; 26
               cp  (hl)
               ret nz
               inc e
               inc l

               ld  a,(de)   ; 27
               cp  (hl)
               ret nz
              inc e
               inc l

               ld  a,(de)   ; 28
               cp  (hl)
               ret nz
               inc e
               inc l

               ld  a,(de)   ; 29
               cp  (hl)
               ret nz
               inc e
               inc l

               ld  a,(de)   ; 30
               cp  (hl)
               ret nz
               inc e
               inc l

               ld  a,(de)   ; 31
               cp  (hl)
               ret nz
               inc de       ; 16-bit increment as we may be at 256-byte boundary
               inc hl

               dec b
               jp  nz,find_change   ; jump too big for DJNZ

               pop hl               ; junk return to update
               ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

length:        equ $ - base         ; code length

               defs -$\256          ; the tables below must be 256-byte aligned

conv_8_6:      defs &100
x_conv:        defs &100
y_conv:        defs &100
mask_table:    defs &100
spr_table:     defs &100
shift_table:   defs &100
special_tab:   defs &100
fruit:         defs &100

tile_table:    defs &200

textcol_tab:   defs &10

               defs &80             ; 128 bytes of stack space - should be plenty
new_stack:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

               dump 1,&2c00
mdat "tiles.bin"

               dump 1,&3e00
mdat "sprites.bin"

               dump 3,0
mdat "pacman.6e"
mdat "pacman.6f"
mdat "pacman.6h"
mdat "pacman.6j"

               dump 6,0
mdat "sound.bin"
