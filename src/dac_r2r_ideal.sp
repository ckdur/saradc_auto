* A DAC with R2R architecture ideal for making the performance verifications

.subckt dac_r2r_unit_ideal result vb0 vb1 refn refp R=1k
.model MYSW SW(Ron=1 Roff=1Meg Vt=vth Vh=-0.4)

Rh vb0  vb1 R=R
Rl sb1  vb1 R=2*R
*s1l result 0 sb1 refn ON
*s1h result 0 sb1 refp OFF
g1l  sb1 refn PWL(1) result 0 0v,100g 1.2v,1p
g1h  sb1 refp PWL(1) result 0 0v,1p 1.2v,100g
.ends

.subckt dac_r2r_ideal result_7 result_6 result_5 result_4 result_3 result_2 result_1 result_0 vb7 vth=0.6 vrefp=0.6 vrefn=-0.6 R=1k

Vvrefp refp 0 DC vrefp
Vvrefn refn 0 DC vrefn

Rh refn vbt R=R
xu0 result_0 vbt vb0 refn refp dac_r2r_unit_ideal R=R
xu1 result_1 vb0 vb1 refn refp dac_r2r_unit_ideal R=R
xu2 result_2 vb1 vb2 refn refp dac_r2r_unit_ideal R=R
xu3 result_3 vb2 vb3 refn refp dac_r2r_unit_ideal R=R
xu4 result_4 vb3 vb4 refn refp dac_r2r_unit_ideal R=R
xu5 result_5 vb4 vb5 refn refp dac_r2r_unit_ideal R=R
xu6 result_6 vb5 vb6 refn refp dac_r2r_unit_ideal R=R
xu7 result_7 vb6 vb7 refn refp dac_r2r_unit_ideal R=R

.ends

.subckt dac_ideal result_7 result_6 result_5 result_4 result_3 result_2 result_1 result_0 vb7 vth=0.6 vrefp=0.6 vrefn=-0.6 R=1k nbits=5

eu7 vb7 vb6 vol='v(result_7)>vth?((vrefp-vrefn)/(2**(nbits-7))):0'
eu6 vb6 vb5 vol='v(result_6)>vth?((vrefp-vrefn)/(2**(nbits-6))):0'
eu5 vb5 vb4 vol='v(result_5)>vth?((vrefp-vrefn)/(2**(nbits-5))):0'
eu4 vb4 vb3 vol='v(result_4)>vth?((vrefp-vrefn)/(2**(nbits-4))):0'
eu3 vb3 vb2 vol='v(result_3)>vth?((vrefp-vrefn)/(2**(nbits-3))):0'
eu2 vb2 vb1 vol='v(result_2)>vth?((vrefp-vrefn)/(2**(nbits-2))):0'
eu1 vb1 vb0 vol='v(result_1)>vth?((vrefp-vrefn)/(2**(nbits-1))):0'
eu0 vb0 rfn vol='v(result_0)>vth?((vrefp-vrefn)/(2**(nbits-0))):0'
Vvrefn rfn 0 DC {vrefn}

.ends
