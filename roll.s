; R o l l  M e  G e n t l y
; 256b Intro
; ZX Spectrum 128kB
;
; Contribution to
; Flashparty  2020
;
; Tomasz Slanina
; Dox/Joker
; www.slanina.pl
; 

ZX128 equ 1

;set above to 0 for zx48 version (slower, bigger,  with tearing)

BANK_PORT equ $7ffd
BUFFER equ $b000

SCREEN equ $c000
ATTRS equ $d800

    org $b200

start:
    di
    ld l,4  ; used also as x coord (variable) , l
    out(254),a   
    ld a,29 
    ld bc,BANK_PORT
    exx

mainloop:
    ; fill buffer at BUFFER with '1'
    ld hl,BUFFER

fill:
    ld [hl],-1
    inc l
    djnz fill

    ld a,%11010001
    ld l,$20
    
    ld de,tube_data
    call put_data
   
    ld a,%01010001
    ld l,136
    inc e
    call put_data

    ; pack buffer (from BUFFER to SCREEN, from byte array to bit array )
    ld ix,SCREEN
    ld l,b ; hl = BUFFER
    exx
    ld a,e ; base offset
    exx

    ld b,32 ; 32
byteloop:    
    ld de,$8000 ; mask + byte

inner:
    add a, [hl]
   
    inc hl
    and %111111
    bit 5,a
    jr z,noput

    push af
    ld a,e
    or d
    ld e,a
    pop af

noput:   
    rr d
    jr nc, inner
    ld [ix],e
    inc ix
    djnz byteloop

    ; expand lines down
    ld de,SCREEN
    ld h,d
    ld a,d

copyline:
    ld l,0
    ld c,32   
    ldir
    dec a
    jr nz,copyline

    ; attributes = strips

    ld hl,ATTRS
    ld e,12
    ld a,%1111010

putloop:
    ld b, 128

putloopinner:
    ld [hl],a
    inc hl
    djnz putloopinner
    xor %101101
    dec e
    jr nz, putloop

    ld a,7
    ld hl,%001110*256+4 ; color<<8 + offset
    call strips

    ld a,5
    ld hl,%000111*256+17 ; color<<8 + offset
    call strips

    ld hl,attrdata-1
    ld c,4

attrloop:
    inc l
    bit 0,c
    jr nz,skip2
    ld a,(hl)
    inc l 

skip2:
    push hl
    ld l,(hl)

;b6 - res
;f6 - set

    ld [modme-1],a
    ld h,HIGH ATTRS
    ld b,e ;24, but 32 is ok too

amod:
    res 6,[hl]

modme:
    add hl,de
    djnz amod

    pop hl
    dec c
    jr nz, attrloop

    exx

IF ZX128
    ld a,d  ; bank
    xor 10  ; switch screens
    ld d,a
    out [c],a
ELSE
    push de
    ld hl,SCREEN
    ld de,$4000
    ld bc ,$1b00
    ldir
    pop de
ENDIF

    inc e   ;start offset (scroll)
    inc e
    exx

    jp  mainloop

attrdata:
    db $b6 ; opcode (modme)
    db $10
    db $03
    db $f6 ; opcode (modme)
    db $14
    db $08

;draw symmetrical 'tube' from start to 0, then backward, to start (or rather to 0 before start)

put_data:
    ld [tube_width],a

write_right:
    ld a,[de]
    or a
    jr z, write_left
    call unpack
    inc de
    jr write_right

write_left:
    dec de
    ld a,[de]
    or a
    ret z
    call unpack
    jr write_left

unpack:
    and %11111000
    out [254],a     ; drill a brainhole
    rra
    rra
    rra
    rra
    ld b,a
    ld a,[de]
    and $f
    add a,a

store:
    ld [hl],a
    inc l
    djnz store
    ret

strips:
    ld [double+1],a ; width
    ld a,h
    ld h,HIGH ATTRS
    ld de,32

widthdata:
    ld b,12

vloop:
    push bc
    ld b,2

double:
    ld c,5
    push hl

hloop:
    ld [hl],a
    inc hl
    dec c
    jr nz,hloop
    pop hl
    add hl,de   
    djnz double
    xor %111111 
    pop bc
    djnz vloop
    ret

    db 0 ; marker:
tube_data:
    db 2*16+13
    db 2*16+10
    db 2*16+7
    db 2*16+5
    db 2*16+4
    db 2*16+3
    db 3*16+2
tube_width:
    db %11010001
    db 0 ; marker

end start
