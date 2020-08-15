rm *.tap
./pasmo --bin roll.s roll.b
./pasmo --tapbas roll.s roll.tap
ls -lag *.b
