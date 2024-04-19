**************************************************************************
**************************************************************************
***                  Copyright Craig MT Johnston                       ***
***                    2751810 Ontario Limited                         ***
**************************************************************************
**************************************************************************
**************************************************************************
**************************************************************************

$if not setglobal SC  $setglobal SC SSP2

$if     %SC%=="SSP3" OPTION qcp=minos5
$if not %SC%=="SSP3" OPTION qcp=CPLEX
OPTION qcp = cplex;

*$OFFSYMLIST OFFSYMXREF
*$offlisting
 OPTION LIMROW = 0
 OPTION LIMCOL = 0
 OPTION RESLIM = 500000000
 OPTION ITERLIM = 10000000
 OPTION work = 50000000;

*******************************************************************************
* Beginning of set declarations
*******************************************************************************
$include FAOmap.map
*******************************************************************************
SETS
         k5(k)   *pulpwood products                       /MP, CP, OP, PB, FB, PEL/
         h(k)    *direct harvested products               /FWCI, FWNCI, FWC, FWNC, ORWC, ORWNC, IRC, IRNC/
         h1(k)   *direct harvested products               /FWCI, FWC, ORWC, IRC/
         h2(k)   *direct harvested products               /FWNCI, FWNC, ORWNC, IRNC/
         w(k)    *subset of inputs                        /FWCI, FWNCI, IRC, IRNC, MP, CP, OP, WP, CPR/
         j3(k)   subset of inputs 3                       /SWC, SWNC, PW/
         j4(k)   subset of inputs 4                       /IRC, IRNC/
         o2(k)   subset of outputs 2                      /News, PWP, Opap/
         e(k)    subset of recycled products              /WP/
         r(k)    subset of chips residuals residues       /CPR/
         c       region names
         g(c)    region names excluding US
         m(c)    region names excluding US & ROW
         mm(c)   region names excluding RPA
         t       time periods                            /2010, 2015, 2020, 2025, 2030, 2035, 2040, 2045, 2050, 2055, 2060, 2065, 2070, 2075, 2080, 2085, 2090, 2095, 2100/
         tt(t)                                           /2020,2025,2030,2035,2040,2045,2050,2055,2060,2065,2070/
         tinit(t) first time period
         scenario                                        /SSP1, SSP2, SSP3, SSP4, SSP5/
         SSP(scenario)                                   /%SC%/
         climate                                         /REF, RCP45, RCP85/
         RCP(climate)                                    /RCP85/
         species                                         /C, NC/
         type                                            /total, other, planted/
         regions                                         /'Region 1' * 'Region 16'/
;
tinit(t) = yes$(ord(t) eq 1);
ALIAS(k,n);
ALIAS(c,cc);

SCALAR
         period  number of 5yr steps (e.g. 19 is 2100 14 is 2070)  /14/
;

*******************************************************************************
* End of set declarations
*******************************************************************************

*******************************************************************************
* Beginning of data input
*******************************************************************************
*=== IMPORT DATA FROM SPREADSHEET ===*
* Build gdxxrw instructions file
$onecho > import.txt
par=Y rng=Supply!A1:W226 Rdim=1 Cdim=1
par=Q rng=Demand!A1:W226 Rdim=1 Cdim=1
par=ps rng=Manu_cost!A1:W226 Rdim=1 Cdim=1
par=pd rng=Price!A1:W226 Rdim=1 Cdim=1
par=ped rng=Elast.Demand.Price!A1:W226 Rdim=1 Cdim=1
par=ied rng=Elast.Demand.GDP!A1:W226 Rdim=1 Cdim=1
par=pes rng=Elast.Supply.Price!A1:W226 Rdim=1 Cdim=1
par=ies rng=Elast.Supply.GDP!A1:W226 Rdim=1 Cdim=1
par=trans rng=trans!A1:CF84 Rdim=1 Cdim=1
set=c rng=supply!A2:A226 Rdim=1 Cdim=0
$offecho

* Create and import GDX file with import data
$call gdxxrw.exe Results.xls o=ImportData.gdx @import.txt
$gdxin ImportData.gdx

* Declare parameters before loading them
PARAMETERS
         Y(c,*)          Supply
         Q(c,*)          Demand
         ps(c,*)         Marginal cost
         pd(c,*)         Price
         ped(c,*)        Price elasticity of demand
         ied(c,*)        Demand elasticity of GDP
         pes(c,*)        Price elasticity of supply
         ies(c,*)        Supply elasticity of GDP
         trans(c,cc)     Transportation costs

*Load parameters
$load c y Q ps pd ped ied pes ies trans
$gdxin
;

$onmulti
trans(c,cc)$(trans(c,cc) eq 0) = 30;

Table trans(c,cc)

                 "Pacific Coast"    "Rocky Mountain"   "North Central"   "North East"    "South Central"   "South East"
"Pacific Coast"            0                2.0             3.0              4.0                 6.0           5.0
"Rocky Mountain"         4.0                  0             6.6              5.3                 2.3           6.5
"North Central"          3.0                5.7               0              2.4                 4.0           2.3
"North East"             5.0                5.4             5.9                0                 6.7           6.8
"South Central"          2.0                1.3             7.3              3.4                   0           7.9
"South East"             1.0                4.5             3.4              1.1                 5.8             0

$ontext
                 "Pacific Coast"    "Rocky Mountain"        "North Central"         "North East"         "South Central"     "South East"
"Pacific Coast"        0.0                 54.0                    58.0                    62.0                    70.0            66.0
"Rocky Mountain"       62.0                0.0                     72.4                    67.2                    55.2            72.0
"North Central"        58.0                68.8                    0.0                     55.6                    62.0            55.2
"North East"           66.0                67.6                    69.6                    0.0                     72.8            73.2
"South Central"        54.0                51.2                    75.2                    59.6                    0.0             77.6
"South East"           50.0                64.0                    59.6                    50.4                    69.2            0.0
$offtext
;


trans(c,c)=0;

$onmulti
set c "US RPA regions" /"United States"/;

g(c) = yes;
g('United States') = no;
* Display parameters to ensure proper input
Alias(g,gg);
m(c) = yes;
m('United States') = no;

mm(c) = yes;
mm('United States') = no;
mm('Pacific Coast') = no;
mm('Rocky Mountain') = no;
mm('North Central') = no;
mm('North East') = no;
mm('South Central') = no;
mm('South East') = no;

set rpa(c) /"Pacific Coast", "Rocky Mountain", "North Central", "North East",
         "South Central", "South East"/;

*=== IMPORT DATA FROM SPREADSHEET ===*
* Build gdxxrw instructions file
$onecho > import.txt
par=IM rng=import!A1:CD26 Rdim=1 Cdim=1
par=EX rng=export!A1:CD26 Rdim=1 Cdim=1
$offecho


* Create and import GDX file with import data
$call gdxxrw.exe results2.xls o=ImportData.gdx @import.txt
$gdxin ImportData.gdx

* Declare parameters before loading them
PARAMETERS
         IM(k,c)          Supply
         EX(k,c)          Demand

*Load parameters
$load IM EX
$gdxin

DISPLAY c, regions, g, m, mm, rpa, gg, Y, Q, IM, EX, ps, pd, ped, ied, pes, ies, trans;

*=== IMPORT DATA FROM SPREADSHEET ===*
* Build gdxxrw instructions file
$onecho > import.txt
par=G1 rng=GDP1!A1:K226 Rdim=1 Cdim=1
par=G2 rng=GDP2!A1:K226 Rdim=1 Cdim=1
par=G3 rng=GDP3!A1:K226 Rdim=1 Cdim=1
par=G4 rng=GDP4!A1:K226 Rdim=1 Cdim=1
par=G5 rng=GDP5!A1:K226 Rdim=1 Cdim=1
par=P1 rng=POP1!A1:K226 Rdim=1 Cdim=1
par=P2 rng=POP2!A1:K226 Rdim=1 Cdim=1
par=P3 rng=POP3!A1:K226 Rdim=1 Cdim=1
par=P4 rng=POP4!A1:K226 Rdim=1 Cdim=1
par=P5 rng=POP5!A1:K226 Rdim=1 Cdim=1
par=Fordata rng=Forest!A1:AI226 Rdim=1 Cdim=1
par=Plant rng=Forest.Planted!A1:AI226 Rdim=1 Cdim=1
$offecho

* Create and import GDX file with import data
$call gdxxrw.exe countrydata_short.xlsx o=ImportData.gdx @import.txt
$gdxin ImportData.gdx

* Declare parameters before loading them
PARAMETERS
         G1(c,*)
         G2(c,*)
         G3(c,*)
         G4(c,*)
         G5(c,*)
         P1(c,*)
         P2(c,*)
         P3(c,*)
         P4(c,*)
         P5(c,*)
         Fordata(c,*)
         Plant(c,*)

*Load parameters
$load G1 G2 G3 G4 G5 P1 P2 P3 P4 P5 Fordata Plant
$gdxin

* Display parameters to ensure proper input
DISPLAY c, G1, G2, G3, G4, G5, P1, P2, P3, P4, P5, Fordata, Plant;

$kill

*----------- Input RPA proportions to disaggregate model ----------------
*=== IMPORT DATA FROM SPREADSHEET ===*
* Build gdxxrw instructions file
$onecho > import2.txt
par=RPApop rng=population!A1:B7 Rdim=1 Cdim=1
par=RPAgdp rng=GDP!A1:B7 Rdim=1 Cdim=1
par=RPAarea rng=Area!A1:J7 Rdim=1 Cdim=1
par=RPAstock rng=Stock!A1:C7 Rdim=1 Cdim=1
par=RPAgrowth rng=Growth!A1:C7 Rdim=1 Cdim=1
par=RPApop1 rng=POP.SSP1!A1:T7 Rdim=1 Cdim=1
par=RPApop2 rng=POP.SSP2!A1:T7 Rdim=1 Cdim=1
par=RPApop3 rng=POP.SSP3!A1:T7 Rdim=1 Cdim=1
par=RPApop4 rng=POP.SSP4!A1:T7 Rdim=1 Cdim=1
par=RPApop5 rng=POP.SSP5!A1:T7 Rdim=1 Cdim=1
par=RPAgdp1 rng=GDP.SSP1!A1:T7 Rdim=1 Cdim=1
par=RPAgdp2 rng=GDP.SSP2!A1:T7 Rdim=1 Cdim=1
par=RPAgdp3 rng=GDP.SSP3!A1:T7 Rdim=1 Cdim=1
par=RPAgdp4 rng=GDP.SSP4!A1:T7 Rdim=1 Cdim=1
par=RPAgdp5 rng=GDP.SSP5!A1:T7 Rdim=1 Cdim=1

$offecho

* Create and import GDX file with import data
$call gdxxrw.exe Dis_US.xlsx o=ImportData.gdx @import2.txt
$gdxin ImportData.gdx

PARAMETERS
         RPApop(rpa,*)            (million)
         RPApop1(rpa,*)           (million)
         RPApop2(rpa,*)           (million)
         RPApop3(rpa,*)           (million)
         RPApop4(rpa,*)           (million)
         RPApop5(rpa,*)           (million)
         RPAgdp(rpa,*)            (% of United States)
         RPAgdp1(rpa,*)           (% of United States)
         RPAgdp2(rpa,*)           (% of United States)
         RPAgdp3(rpa,*)           (% of United States)
         RPAgdp4(rpa,*)           (% of United States)
         RPAgdp5(rpa,*)           (% of United States)

         RPAarea(rpa,*)          ('000s ha)
         RPAstock(rpa,*)         (million m3)
         RPAgrowth(rpa,*)        (annual growth of forest stock)

$load RPApop RPAgdp RPAarea RPAstock RPAgrowth RPApop1 RPApop2 RPApop3 RPApop4 RPApop5 RPAgdp1 RPAgdp2 RPAgdp3 RPAgdp4 RPAgdp5
$gdxin


DISPLAY RPApop, RPApop, RPAgdp, RPAarea, RPAstock, RPAgrowth, RPApop1, RPApop2, RPApop3, RPApop4, RPApop5, RPAgdp1, RPAgdp2, RPAgdp3, RPAgdp4, RPAgdp5;

PARAMETERS
         GDP(c,t,scenario)               ('000s $US)
         POP(c,t,scenario)               (million)
         GDPP(c,t,scenario)              ($US per person)
         gGDP(c,t,scenario)              (five year change in GDP)
         gGDPP(c,t,scenario)             (five year change in GDP per capita)
         Area(c,species,scenario,type,t)      ('000s ha)
         Stock(c,species,t)              (million m3)
         a0(c)                           forest area EKC intercept
         g0(c)                           Planted forest area annual growth
         b0(c)                           Planted forest area EKC intercept
         gamma(c,species)                forest stock parameter
         gArea(c,species,scenario,type,t)     (five year change in '000s ha)
         RPApop_total
         RPAarea_total(species)
         RPAarea_plant
         RPAarea_prim
         RPAarea_nat
         gStock(c,species,type,t)
*         beta(c,species,t)               planted forest as proportion of total forest
         beta(c,t)
         other(c,t)
;

GDP(c,t,'SSP1') = G1(c,t);
GDP(c,t,'SSP2') = G2(c,t);
GDP(c,t,'SSP3') = G3(c,t);
GDP(c,t,'SSP4') = G4(c,t);
GDP(c,t,'SSP5') = G5(c,t);

POP(c,t,'SSP1') = P1(c,t);
POP(c,t,'SSP2') = P2(c,t);
POP(c,t,'SSP3') = P3(c,t);
POP(c,t,'SSP4') = P4(c,t);
POP(c,t,'SSP5') = P5(c,t);

GDP(c,'2015',scenario) = (GDP(c,'2010',scenario)+GDP(c,'2020',scenario))/2;
GDP(c,'2025',scenario) = (GDP(c,'2020',scenario)+GDP(c,'2030',scenario))/2;
GDP(c,'2035',scenario) = (GDP(c,'2030',scenario)+GDP(c,'2040',scenario))/2;
GDP(c,'2045',scenario) = (GDP(c,'2040',scenario)+GDP(c,'2050',scenario))/2;
GDP(c,'2055',scenario) = (GDP(c,'2050',scenario)+GDP(c,'2060',scenario))/2;
GDP(c,'2065',scenario) = (GDP(c,'2060',scenario)+GDP(c,'2070',scenario))/2;
GDP(c,'2075',scenario) = (GDP(c,'2070',scenario)+GDP(c,'2080',scenario))/2;
GDP(c,'2085',scenario) = (GDP(c,'2080',scenario)+GDP(c,'2090',scenario))/2;
GDP(c,'2095',scenario) = (GDP(c,'2090',scenario)+GDP(c,'2100',scenario))/2;

POP(c,'2015',scenario) = (POP(c,'2010',scenario)+POP(c,'2020',scenario))/2;
POP(c,'2025',scenario) = (POP(c,'2020',scenario)+POP(c,'2030',scenario))/2;
POP(c,'2035',scenario) = (POP(c,'2030',scenario)+POP(c,'2040',scenario))/2;
POP(c,'2045',scenario) = (POP(c,'2040',scenario)+POP(c,'2050',scenario))/2;
POP(c,'2055',scenario) = (POP(c,'2050',scenario)+POP(c,'2060',scenario))/2;
POP(c,'2065',scenario) = (POP(c,'2060',scenario)+POP(c,'2070',scenario))/2;
POP(c,'2075',scenario) = (POP(c,'2070',scenario)+POP(c,'2080',scenario))/2;
POP(c,'2085',scenario) = (POP(c,'2080',scenario)+POP(c,'2090',scenario))/2;
POP(c,'2095',scenario) = (POP(c,'2090',scenario)+POP(c,'2100',scenario))/2;

**********      RPA GDP and population from Prestemon and Wear    **************
GDP(rpa,t,'SSP1') = RPAgdp1(rpa,t)/1000;
GDP(rpa,t,'SSP2') = RPAgdp2(rpa,t)/1000;
GDP(rpa,t,'SSP3') = RPAgdp3(rpa,t)/1000;
GDP(rpa,t,'SSP4') = RPAgdp4(rpa,t)/1000;
GDP(rpa,t,'SSP5') = RPAgdp5(rpa,t)/1000;

POP(rpa,t,'SSP1') = RPApop1(rpa,t)/1000;
POP(rpa,t,'SSP2') = RPApop2(rpa,t)/1000;
POP(rpa,t,'SSP3') = RPApop3(rpa,t)/1000;
POP(rpa,t,'SSP4') = RPApop4(rpa,t)/1000;
POP(rpa,t,'SSP5') = RPApop5(rpa,t)/1000;

GDPP(c,t,scenario)$(POP(c,t,scenario) gt 0) = GDP(c,t,scenario)/POP(c,t,scenario)*1000;
GDPP('ROW',t,scenario) = sum(c, GDP(c,t,scenario))/sum(c, POP(c,t,scenario))*1000;
gGDP(c,t,scenario)$(NOT tinit(t) AND GDP(c,t,scenario) gt 0) = (GDP(c,t,scenario) - GDP(c,t-1,scenario)) / GDP(c,t-1,scenario);
gGDPP(c,t,scenario)$(NOT tinit(t) AND GDP(c,t,scenario) gt 0) = (GDPP(c,t,scenario) - GDPP(c,t-1,scenario)) / GDPP(c,t-1,scenario);





**************************************************************************
***                  Total forest area calculations                     ***
**************************************************************************
Area(c,'C',scenario,'total','2015')$(sum(h, Y(c,h)) gt 0) = Fordata(c,'2015')*sum(h1, Y(c,h1))/sum(h, Y(c,h));
Area(c,'NC',scenario,'total','2015')$(sum(h, Y(c,h)) gt 0) = Fordata(c,'2015')*sum(h2, Y(c,h2))/sum(h, Y(c,h));
RPAarea_total('C') = sum(rpa, RPAarea(rpa,'Coniferous'));
RPAarea_total('NC') = sum(rpa, RPAarea(rpa,'Non coniferous'));
Area(rpa,'C',scenario,'total','2015') = Fordata('United States','2015')*(RPAarea_total('C')/(sum(species, RPAarea_total(species))))*RPAarea(rpa,'Coniferous')/RPAarea_total('C');
Area(rpa,'NC',scenario,'total','2015') = Fordata('United States','2015')*(RPAarea_total('NC')/(sum(species, RPAarea_total(species))))*RPAarea(rpa,'Non coniferous')/RPAarea_total('NC');

**************************************************************************
***                  Planted forest area calculations                   ***
**************************************************************************
Area(c,'C',scenario,'Planted','2015')$(sum(h, Y(c,h)) gt 0) = Plant(c,'2015')*sum(h1, Y(c,h1))/sum(h, Y(c,h));
Area(c,'NC',scenario,'Planted','2015')$(sum(h, Y(c,h)) gt 0) = Plant(c,'2015')*sum(h2, Y(c,h2))/sum(h, Y(c,h));
RPAarea_plant = sum(rpa, RPAarea(rpa,'Planted17'));
Area(rpa,'C',scenario,'Planted','2015') = Plant('United States','2015')*(RPAarea_total('C')/(sum(species, RPAarea_total(species))))*(RPAarea(rpa,'Planted17')/RPAarea_plant);
Area(rpa,'NC',scenario,'Planted','2015') = Plant('United States','2015')*(RPAarea_total('NC')/(sum(species, RPAarea_total(species))))*(RPAarea(rpa,'Planted17')/RPAarea_plant);

**************************************************************************
***                  Other forest area calculations                   ***
**************************************************************************
Other(c,'2015') = Fordata(c,'2015') - plant(c,'2015');
Area(c,'C',scenario,'Other','2015')$(sum(h, Y(c,h)) gt 0) = other(c,'2015')*sum(h1, Y(c,h1))/sum(h, Y(c,h));
Area(c,'NC',scenario,'Other','2015')$(sum(h, Y(c,h)) gt 0) = other(c,'2015')*sum(h2, Y(c,h2))/sum(h, Y(c,h));
Area(rpa,'C',scenario,'other','2015') = Area(rpa,'C',scenario,'total','2015') - Area(rpa,'C',scenario,'planted','2015');
Area(rpa,'NC',scenario,'other','2015') = Area(rpa,'NC',scenario,'total','2015') - Area(rpa,'NC',scenario,'planted','2015');

Stock(g,'C','2015') = Fordata(g,'coniferous');
Stock(g,'NC','2015') = Fordata(g,'non Coniferous');
Stock(rpa,'C','2015') = RPAstock(rpa,'Coniferous');
Stock(rpa,'NC','2015') = RPAstock(rpa,'Non coniferous');
Stock(g,'C','2015')$(Stock(g,'C','2015') eq 0 AND sum((species,SSP), Area(g,species,SSP,'total','2015')) gt 0) = Fordata(g,'Stock')*sum(SSP, Area(g,'C',SSP,'total','2015'))/sum((species,SSP), Area(g,species,SSP,'total','2015'));
Stock(g,'NC','2015')$(Stock(g,'NC','2015') eq 0 AND sum((species,SSP), Area(g,species,SSP,'total','2015')) gt 0) = Fordata(g,'Stock')*sum(SSP, Area(g,'NC',SSP,'total','2015'))/sum((species,SSP), Area(g,species,SSP,'total','2015'));

**********
* ROW
**********
**Note:  divivided by 50 to make the based year stock close to the FAO data
Stock('ROW','C','2015')=sum(h1, Y('ROW',h1))/50;
Stock('ROW','NC','2015')=sum(h2, Y('ROW',h2))/50;
Area('ROW','C',scenario,'total','2015') = Stock('ROW','C','2015')/50;
Area('ROW','NC',scenario,'total','2015') = Stock('ROW','NC','2015')/50;
**********
* ROW
**********

Fordata(rpa,'linear')                            = Fordata('United States','linear');
Fordata(rpa,'exponential')                       = Fordata('United States','exponential');
Fordata(rpa,'Area growth')                       = Fordata('United States','Area growth');

Plant(rpa,'GDP')                                 = Plant('United States','GDP');
Plant(rpa,'RWD')                                 = Plant('United States','RWD');

g0(mm)$(Plant(mm,'2014') gt 0)                   = (Plant(mm,'2015')-Plant(mm,'2014'))/Plant(mm,'2014');
g0(rpa)                                          = RPAarea(rpa,'gPlant');

b0(c)                                            = (g0(c)/(exp(Fordata(c,'exponential')*sum(SSP, GDPP(c,'2015',SSP))/1000)))
                                                         -Fordata(c,'linear')*sum(SSP, GDPP(c,'2015',SSP))/1000;

a0(c)                                            = (Fordata(c,'Area growth')/(exp(Fordata(c,'exponential')*sum(SSP, GDPP(c,'2015',SSP))/1000)))
                                                         -Fordata(c,'linear')*sum(SSP, GDPP(c,'2015',SSP))/1000;

gArea(c,species,scenario,'total',t)$(NOT tinit(t))       = (a0(c)+Fordata(c,'linear')*GDPP(c,t,scenario)/1000)*exp(Fordata(c,'exponential')*GDPP(c,t,scenario)/1000);
gArea(c,species,scenario,'total',t)$(NOT tinit(t))       = (1+ gArea(c,species,scenario,'total',t)$(NOT tinit(t)))**5-1;

*gArea(c,species,scenario,'planted',t)$(NOT tinit(t))       = b0(c)+Plant(c,'GDP')*gGDP(c,t,scenario);
gArea(c,species,scenario,'planted',t)$(NOT tinit(t))       = (b0(c)+Fordata(c,'linear')*GDPP(c,t,scenario)/1000)*exp(Fordata(c,'exponential')*GDPP(c,t,scenario)/1000);
gArea(c,species,scenario,'planted',t)$(NOT tinit(t))       = (1+ gArea(c,species,scenario,'planted',t)$(NOT tinit(t)))**5-1;

LOOP(t$(ord(t) ge 3),
         Area(c,species,scenario,'total',t) = Area(c,species,scenario,'total',t-1)*(1+gArea(c,species,scenario,'total',t));
         Area(c,species,scenario,'planted',t) = Area(c,species,scenario,'planted',t-1)*(1+gArea(c,species,scenario,'planted',t));
         Area(c,species,scenario,'other',t) = Area(c,species,scenario,'total',t) - Area(c,species,scenario,'planted',t);
)
;
gStock(g,species,type,'2015') = Fordata(g,'Stock growth');
gStock(rpa,'C',type,'2015') = RPAgrowth(rpa,'Coniferous');
gStock(rpa,'NC',type,'2015') = RPAgrowth(rpa,'Non coniferous');
Fordata(rpa,'sigma') = Fordata('United States','sigma');
gamma(g,'C')$(sum(SSP, Area(g,'C',SSP,'total','2015')) gt 0) = gStock(g,'C','total','2015')/((Stock(g,'C','2015')/sum(SSP, Area(g,'C',SSP,'total','2015')))**Fordata(g,'sigma'));
gamma(g,'NC')$(sum(SSP, Area(g,'NC',SSP,'total','2015')) gt 0) = gStock(g,'NC','total','2015')/((Stock(g,'NC','2015')/sum(SSP, Area(g,'NC',SSP,'total','2015')))**Fordata(g,'sigma'));

**Note: beta represents the share of planted forests in the total forest area
beta(g,'2015')=  (sum(SSP, Area(g,'NC',SSP,'planted','2015'))+sum(SSP, Area(g,'C',SSP,'planted','2015')))/(sum(SSP, Area(g,'NC',SSP,'total','2015')) +sum(SSP, Area(g,'C',SSP,'total','2015')));


DISPLAY GDP, POP, GDPP, gGDPP, gGDP, plant, RPAarea, RPAarea_total, RPAarea_plant, Area, Stock, a0, g0, b0, gArea, gamma, gStock, beta;

Table coef(*,k,n)     3 dimensional table
$ONDELIM
$INCLUDE IO.csv
$OFFDELIM
display  coef;

Table recov(*,k,n)     3 dimensional table
$ONDELIM
$INCLUDE IO4.csv
$OFFDELIM
display  recov;

*=== IMPORT TRADE DATA FROM SPREADSHEET AS INITIAL VALUE ===*
* Build gdxxrw instructions file
$onecho > data.txt
par=trade rng=flow!A1:X1601 Rdim=2 Cdim=1
par=Johnremoval rng=John!A1:J1601 Rdim=2 Cdim=1
par=Afterharvest rng=AfterHarvest!A1:J1601 Rdim=2 Cdim=1
par=Noharvest rng=Grow!A1:J1601 Rdim=2 Cdim=1
$offecho

$call gdxxrw.exe Tradedata.xls o=Tradedata.gdx @data.txt
$gdxin Tradedata.gdx

*******************************John's resutls    *******************************

parameter
          trade(*,*,*)
          Johnremoval(t,rpa,h)
          Afterharvest(t,rpa,species)
          Noharvest(t,rpa,species)
          Johngrow(t,rpa,species);
$load trade Johnremoval Afterharvest Noharvest
$gdxin

Johngrow(t,rpa,species)$(Afterharvest(t-1,rpa,species) gt 0) = Noharvest(t,rpa,species)/Afterharvest(t-1,rpa,species)-1;

display trade,Johnremoval,Afterharvest,Noharvest,Johngrow;

*******************************************************************************
* Beginning of data input
*******************************************************************************

*=== IMPORT DATA FROM SPREADSHEET ===*
* Build gdxxrw instructions file
$onecho > import.txt
par=lambdad rng=pmpd!A1:W226 Rdim=1 Cdim=1
par=lambdas rng=pmps!A1:W226 Rdim=1 Cdim=1
$offecho

* Create and import GDX file with import data
$call gdxxrw.exe Results2.xls o=ImportData.gdx @import.txt
$gdxin ImportData.gdx


* Declare parameters before loading them
PARAMETERS
         lambdas(c,*)          Supply
         lambdad(c,*)          Demand

*Load parameters
$load lambdas lambdad
$gdxin

* Display parameters to ensure proper input
DISPLAY lambdas, lambdad;


*=== IMPORT NPP DATA FROM SPREADSHEET ===***************************************************************************************************************************************************************
* Build gdxxrw instructions file
$onecho > importNPP.txt
par=RCP45 rng=N45!A1:Q21  Rdim=1 Cdim=1
par=RCP85 rng=N85!A1:Q21  Rdim=1 Cdim=1
par=CTR   rng=Match!A1:Q230 Rdim=1 Cdim=1
par=Gscale rng=Growthscale!A1:B229 Rdim=1
$offecho

$call gdxxrw.exe NPP.xls o=importNPP.gdx @importNPP.txt
$gdxin importNPP.gdx





PARAMETERS
         RCP45(t,regions)          Net Primary Productivity 45
         RCP85(t,regions)          Net Primary Productivity 85
         CTR(c,regions)            Country to Region
         Gscale(c)
*Load parameters
$load RCP45 RCP85 CTR Gscale
$gdxin



parameter NPP(t,climate,regions);
NPP(t+1,'REF',regions)=0;
NPP(t+1,'RCP45',regions)$(RCP45(t,regions) ne 0)=(RCP45(t+1,regions)-RCP45(t,regions))/RCP45(t,regions);
NPP(t+1,'RCP85',regions)$(RCP85(t,regions) ne 0)=(RCP85(t+1,regions)-RCP85(t,regions))/RCP85(t,regions);

DISPLAY RCP45, RCP85, CTR, NPP, Gscale;




sets ch countries of high incomes
     cl countires of low incomes
     clm countires of low middle
     cum countires of upper middle
;

parameter Bdemand(*,*);
parameter BTdemand(*,*);

*=== IMPORT Income DATA FROM SPREADSHEET ===***************************************************************************************************************************************************************
* Build gdxxrw instructions file
$onecho > importIncome.txt
set=ch rng=High!A2:A226 Rdim=1 Cdim=0
set=cl rng=Low!A2:A226 Rdim=1 Cdim=0
set=clm rng=Lowmiddle!A2:A226 Rdim=1 Cdim=0
set=cum rng=Uppermiddle!A2:A226 Rdim=1 Cdim=0
par=Bdemand rng=Bdemand!A1:T6 Rdim=1 Cdim=1
par=BTdemand rng=BTdemand!A1:T6 Rdim=1 Cdim=1
$offecho

**Note: Import the Income data
$call gdxxrw.exe Income.xls o=importIncome.gdx @importIncome.txt
$gdxin importIncome.gdx

*Load sets
$load ch cl clm cum Bdemand BTdemand
$gdxin
Display Bdemand, BTdemand;


PARAMETERS Income(*,*);

Income(ch,'SSP1')=1; Income(cl,'SSP1')=1.04; Income(clm,'SSP1')=1.03; Income(cum,'SSP1')=1.02;
Income(ch,'SSP2')=1; Income(cl,'SSP2')=1.04; Income(clm,'SSP2')=1.03; Income(cum,'SSP2')=1.02;
Income(ch,'SSP3')=1; Income(cl,'SSP3')=1.04; Income(clm,'SSP3')=1.03; Income(cum,'SSP3')=1.02;
Income(ch,'SSP4')=1; Income(cl,'SSP4')=1.04; Income(clm,'SSP4')=1.03; Income(cum,'SSP4')=1.02;
Income(ch,'SSP5')=1; Income(cl,'SSP5')=1.04; Income(clm,'SSP5')=1.03; Income(cum,'SSP5')=1.02;

Set world /set.ch, set.cl, set.clm, set.cum/;

*=== End IMPORT Carbon Price DATA  ===***************************************************************************************************************************************************************

* Parameter pcarbon: prices for carbon sequestration,
* The following settings only allow high income countries to offset carbon dioxide emissions by planting forests
parameter pcarbon(*);
pcarbon(g)$(sum(SSP,Income(g,SSP))=1)=40;
pcarbon(g)$(not sum(SSP,Income(g,SSP))=1 )=0;
pcarbon(rpa)=pcarbon('Sweden');
display pcarbon;

*******************************************************************************
* Beginning of demand and supply equation specification
*******************************************************************************

PARAMETERS
         bs(c,k)         Slope of MC curve
         as(c,k)         Intercept of MC curve
         bd(c,k)         Slope of demand curve
         ad(c,k)         Intercept of demand curve
         bc(c,k)         Slope of Manu Cost curve
         ac(c,k)         Intercept of Manu Cost curve
         avgbd(k)        Average Slope of demand curve
         avgbs(k1)
;
* -------------- MC and Demand curve parameters ---------------

Y(g,k1) = Y(g,k1)/1000;
Q(g,k1) = Q(g,k1)/1000;
pd(g,k1) = pd(g,k1)*1000;
ps(g,k1) = ps(g,k1)*1000;

*Working supply coefficients

bs(c,k1)$(Y(c,k1) gt 1) = ps(c,k1)/(pes(c,k1)*Y(c,k1));
avgbs(k1) = sum(c, bs(c,k1)$(Y(c,k1) gt 1))/card(c);
bs(c,k1)$(Y(c,k1) le 1) = avgbs(k1);
as(c,k1) = ps(c,k1) - bs(c,k1)*Y(c,k1);


*Supply curve goes through origin
as(c,k1) = 0;
bs(c,k1)$(Y(c,k1) gt 0) = ps(c,k1)/Y(c,k1);
avgbs(k1) = sum(c, bs(c,k1)$(Y(c,k1) gt 1))/card(c);
bs(c,k1)$(Y(c,k1) le 1) = avgbs(k1);

bd(c,f)$(Q(c,f) gt 1) = -1*pd(c,f)/(ped(c,f)*Q(c,f));
avgbd(f) = sum(c, bd(c,f)$(Q(c,f) gt 1))/card(c);
bd(c,f)$(Q(c,f) le 1) = avgbd(f);
ad(c,f) = pd(c,f) + bd(c,f)*Q(c,f);

DISPLAY Income, pd, ps, bs, as, bd, ad, Y, Q;

*******************************************************************************
* End of demand and supply equation specification
*******************************************************************************

*******************************************************************************
* Beginning of model construction
*******************************************************************************
* -------------- Variable definitions ---------------

TABLE ru(k,n) upper bound on recovery factors
         IRC     IRNC    SWC     SWNC    PW      PB      FB      MP      CP      OP      WP      News    PWP     Opap    PEL     CPR
 WP                                                                                              0.8     0.8     0.8
 CPR                     1       1       1
;

TABLE rl(k,n) lower bound on recovery factors
         IRC     IRNC    SWC     SWNC    PW      PB      FB      MP      CP      OP      WP      News    PWP     Opap    PEL     CPR
 WP                                                                                              0       0       0
 CPR                     0       0       0
;

POSITIVE VARIABLES
         flow(c,cc,k)    Shipments from region c to cc of product a
         qs(c,k)         quantity supplied in region c of product k
         qd(c,k)         quantity demanded in region c of product k
;
VARIABLE
         Z               objective value
;
* -------------- Defining equations ---------------
EQUATIONS
         obj             objective function
         harvest1(c)
         harvest2(c)
         supply(c,k)     total shipments must be less than or equal to supply
         demand(c,k)     total imports must be greater than or equal to demand

         Eq1(c,k)        Material balance
         Eq2(c,k)
         Eq3(c,k)
         Eq4(c,k)
         Eq5(c,k)
         import1(k,c)
         import2(k,c)
         export1(k,c)
         export2(k,c)
;

PARAMETER
         IMlag(k,c)
         EXlag(k,c)
         gtrade(k,c)
         Volume(c,species,type)
         Inventory(c,species)
         NPPrate(c,species)
;
IMlag(k,gg) = IM(k,gg);
EXlag(k,g) = EX(k,g);
gtrade(k,g) = sum(SSP, gGDP(g,'2015',SSP));
Inventory(g,species) = Stock(g,species,'2015');
DISPLAY IMlag, EXlag, gtrade, Inventory;

*******************************************************************************
* End of model construction
*******************************************************************************
*******************************************************************************
* Beginning of equation specification
*******************************************************************************
* -------------- Specifying equations ---------------
obj..            Z =E=
                 sum((g,f), ad(g,f)*qd(g,f)-.5*bd(g,f)*sqr(qd(g,f)))
                 - sum((g,k1), as(g,k1)*qs(g,k1) +.5*bs(g,k1)*sqr(qs(g,k1)))
                 - sum((g,gg,k1), (trans(g,gg)*1000 + lambdad(gg,k1) + lambdas(g,k1))*flow(g,gg,k1))
;
* --------------- Downstream product constraints -----------------------------
harvest1(g)..     sum(h1, qs(g,h1))/1000 =L= Inventory(g,'C');
harvest2(g)..     sum(h2, qs(g,h2))/1000 =L= Inventory(g,'NC');

* Downstream wood product constraints
demand(gg,f)..    qd(gg,f) =L= sum(g, flow(g,gg,f));
supply(g,k1)..    sum(gg, flow(g,gg,k1)) =L= qs(g,k1);

* Material balance
Eq1(g,k)..         qs(g,k) + sum(gg, flow(gg,g,k)) - sum(gg, flow(g,gg,k)) =e= qd(g,k) + sum(n, recov(g,k,n)*qs(g,n));

* est production of waste paper minus =L= upper bound on est recovery from paper domestic prod of paper + import - export
Eq2(g,e)..          qs(g,e) - sum(o2, ru(e,o2)*qs(g,o2)) =L= sum(o2, ru(e,o2)*(sum(gg, flow(gg,g,o2)) - sum(gg, flow(g,gg,o2))));
* est production of waste paper minus =G= lower bound on est recovery from paper domestic prod of paper + import - export
Eq3(g,e)..          qs(g,e) - sum(o2, rl(e,o2)*qs(g,o2)) =G= sum(o2, rl(e,o2)*(sum(gg, flow(gg,g,o2)) - sum(gg, flow(g,gg,o2))));
* est production of CPR minus =L= upper bound on est recovery from sawmilling
Eq4(g,r)..          qs(g,r) =L= sum(j3, (sum(j4, recov(g,j4,j3)*qs(g,j3)) - qs(g,j3))*ru(r,j3));
* est production of CPR minus =G= upper bound on est recovery from sawmilling
Eq5(g,r)..          qs(g,r) =G= sum(j3, (sum(j4, recov(g,j4,j3)*qs(g,j3)) - qs(g,j3))*rl(r,j3));

import1(k,gg)..     sum(g$(not (SameAs(g,gg))), flow(g,gg,k))-IMlag(k,gg) =L= gtrade(k,gg)*IMlag(k,gg);
import2(k,gg)..     sum(g$(not (SameAs(g,gg))), flow(g,gg,k))-IMlag(k,gg) =g= -gtrade(k,gg)*IMlag(k,gg);

export1(k,g)..      sum(gg$(not (SameAs(g,gg))), flow(g,gg,k))-EXlag(k,g) =L= gtrade(k,g)*EXlag(k,g);
export2(k,g)..      sum(gg$(not (SameAs(g,gg))), flow(g,gg,k))-EXlag(k,g) =g= -gtrade(k,g)*EXlag(k,g);
* -------------- Solve model----- ----------------------------------------

MODEL tradePMP /obj,harvest1,harvest2,demand,supply,Eq1,Eq2,Eq3,Eq4,Eq5,import1,import2,export1,export2/;

tradePMP.optfile = 1;

qd.l(g,f) = Q(g,f);
qs.l(g,k1) = Y(g,k1);
flow.l(c,cc,k1) = trade(c,cc,k1);

PARAMETERS
         qs1(k,c,t)         quantity supplied in region c of product k
         qd1(k,c,t)         quantity demanded in region c of product k
         as1(k,c,t)
         bs1(k,c,t)
         PriceS1(*,*,t)
         PriceD1(*,*,t)
         ad1(c,k,t)
         bd1(c,k,t)
         removals(c,t)
         Chng_removals(c,t)
         import(k,c,t)
         export(k,c,t)
         recovt(c,k,n,t)
         transt(c,cc,t)
         check3(k,c,t)
         check4(k,c,t)
;

LOOP(t$(ord(t) ge 2 AND ord(t) le period-1),
         gtrade(k,g)$(sum(SSP, gGDP(g,t,SSP)) gt 0.05) = sum(SSP, gGDP(g,t,SSP));
         gtrade(k,g)$(sum(SSP, gGDP(g,t,SSP)) le 0.05) = 0.05;
********************************************************************
         SOLVE tradePMP using qcp maximizing Z;

         Inventory(g,'C') = sum(h1, qs.l(g,h1))*(1 + sum(SSP, gGDPP(g,t,SSP))/4)/1000;
         Inventory(g,'NC') = sum(h2, qs.l(g,h2))*(1 + sum(SSP, gGDPP(g,t,SSP))/4)/1000;

         Inventory('China','C') = sum(h1, qs.l('China',h1))*(1 + sum(SSP, gGDPP('China',t,SSP))/10)/1000;
         Inventory('China','NC') = sum(h2, qs.l('China',h2))*(1 + sum(SSP, gGDPP('China',t,SSP))/10)/1000;
********************************************************************

* -------------- Store current period solution ---------------------------------
         qs1(k,g,t) = qs.l(g,k) ;
         qd1(f,g,t) = qd.l(g,f) ;
         priceS1(k,g,t) = (as(g,k) + bs(g,k)*qs.l(g,k))/1000 ;
         priceD1(k,g,t) = priceS1(k,g,t) ;
         priceD1(f,g,t) = (ad(g,f) - bd(g,f)*qd.l(g,f))/1000;
         ad1(g,f,t) = ad(g,f) ;
         bd1(g,f,t) = bd(g,f) ;
         as1(k,g,t) = as(g,k);
         bs1(k,c,t) = bs(c,k);
         removals(g,t) = sum(h, qs1(h,g,t));
         import(k,gg,t) = sum(g$(not (SameAs(g,gg))), flow.l(g,gg,k)) ;
         export(k,g,t) = sum(gg$(not (SameAs(g,gg))), flow.l(g,gg,k)) ;
* -------------- Exogenous shock to demand -------------------------------------
         qd1(f,g,t+1) = qd1(f,g,t)*(1 + sum(SSP, gGDPP(g,t,SSP))*ied(g,f));
         ad(g,f)$(qd1(f,g,t+1) gt 0 and (not ord(f)=1 ) and (not ord(f)=2) and (not ord(f)=13)) = priceD1(f,g,t)*1000 + bd(g,f)*qd1(f,g,t+1);
         ad(g,'News') = ad(g,'News')*(1 - sum(SSP, gGDPP(g,t,SSP))*4);
         ad(g,f)$(qd1(f,g,t+1) gt 0 and (ord(f)=1)) = ad(g,f)*(1 + sum(SSP, BTdemand(SSP,t+1)));
         ad(g,f)$(qd1(f,g,t+1) gt 0 and (ord(f)=2)) = ad(g,f)*(1 + sum(SSP, BTdemand(SSP,t+1)));
         ad(g,f)$(qd1(f,g,t+1) gt 0 and (ord(f)=13))= ad(g,f)*(1 + sum(SSP, Bdemand(SSP,t+1)));
         ad(g,f)$(qd1(f,g,t+1) gt 0 and (ord(f)=13) and ord(t)=2)= ad(g,f)*(1.25);
         ad('United Kingdom',f)$(qd1(f,'United Kingdom',t+1) gt 0 and (ord(f)=13) and ord(t)=2)= ad('United Kingdom',f)*(2);

***************the proportion of planted forest area************************************************************************************************************************************
**Note:Update the share of planted forest area in the total forest area
         beta(g,t)=  (sum(SSP, Area(g,'NC',SSP,'planted',t))+sum(SSP, Area(g,'C',SSP,'planted',t)))/(sum(SSP, Area(g,'NC',SSP,'total',t)) +sum(SSP, Area(g,'C',SSP,'total',t)));


*=== End IMPORT NPP DATA FROM SPREADSHEET ===***************************************************************************************************************************************************************
**Note:the growth rates of forest stock in planted and other areas are now separated.
** stock growth in planted forests is Gscale times higher than the stock growth in natural forests
         gStock(m,species,type,t)$(NOT tinit(t) AND sum(SSP, Area(m,species,SSP,'total',t-1)) gt 0 AND (Stock(m,species,t-1) gt 0)) = gamma(m,species)*(Stock(m,species,t-1)/sum(SSP, Area(m,species,SSP,'total',t-1)))**Fordata(m,'sigma');
         gStock(m,species,'planted',t)$(NOT tinit(t) AND sum(SSP, Area(m,species,SSP,'planted',t-1)) gt 0 AND (Stock(m,species,t-1) gt 0)) = gamma(m,species)*(1+Gscale(m)*beta(m,t))*(Stock(m,species,t-1)/sum(SSP, Area(m,species,SSP,'total',t-1)))**Fordata(m,'sigma');
         gStock(m,species,'other',t)$(NOT tinit(t) AND sum(SSP, Area(m,species,SSP,'other',t-1)) gt 0 AND (Stock(m,species,t-1) gt 0)) = gamma(m,species)*(Stock(m,species,t-1)/sum(SSP, Area(m,species,SSP,'total',t-1)))**Fordata(m,'sigma');
         Stock(m,species,t+1) = Stock(m,species,t)*(1 + (gStock(m,species,'other',t)*(1-beta(m,t))+gStock(m,species,'planted',t)*(beta(m,t)))*(1+sum((rcp,regions), NPP(t, RCP, regions)*CTR(m,regions))) + sum(SSP, gArea(m,'C',SSP,'total',t))) - sum(h1, qs1(h1,m,t))/1000;
         Stock(m,species,t+1)$(Stock(m,species,t+1) le Stock(m,species,'2015')*0.25) = Stock(m,species,'2015')*0.25;
         Stock(rpa,species,t+1)$(Johngrow(t+1,rpa,species) gt 0) = Stock(rpa,species,t)*(1 + Johngrow(t+1,rpa,species));
         qs1(h1,g,t+1)$(Stock(g,'C',t) gt 0 ) = qs1(h1,g,t)*(1 + sum(SSP, gArea(g,'C',SSP,'total',t))*1 + ((Stock(g,'C',t+1) - Stock(g,'C',t))/Stock(g,'C',t))*1 );
         qs1(h2,g,t+1)$(Stock(g,'NC',t) gt 0 ) = qs1(h2,g,t)*(1 + sum(SSP, gArea(g,'NC',SSP,'total',t))*1 + ((Stock(g,'NC',t+1) - Stock(g,'NC',t))/Stock(g,'NC',t))*1 );

************** Calibration to John's removal volumes ***************************************************************************************
         qs1(h,rpa,t+1)$(Johnremoval(t+1,rpa,h) gt 0.001) = Johnremoval(t+1,rpa,h);
**********************************************************************************************************************************************
         as(g,k1)$(qs1(k1,g,t+1) gt 0.001 ) = priceS1(k1,g,t)*1000 - bs(g,k1)*qs1(k1,g,t+1);
         as(rpa,k1)$(as(rpa,k1) lt 0 ) = as(rpa,k1)/5;

         Chng_removals(c,t)$(removals(c,t-1) gt 0) = (removals(c,t)-removals(c,t-1))/removals(c,t-1) + EPS;
*        Improve resource efficiency/ technological change
         recov(g,k,n) = recov(g,k,n)*(1 - sum(SSP, gGDPP(g,t,SSP))/75);
         recovt(g,k,n,t) = recov(g,k,n);
*        Improved transportation costs under different SSPs scenarios
         trans(g,gg) = sum(SSP,Income(g,SSP))*trans(g,gg)*(1 - sum(SSP, gGDPP(g,t,SSP))/75);
         transt(g,gg,t) = trans(g,gg);

* Here are forest area equations and we've added in changes to planted area through endogenous lagged rwd production
* Next, we want to seperate gStock out from just 'total' to 'total' 'planted' and 'other'
* Then, have Stock change not just on 'total', but now on a weighted avg of the two of 'other' and 'primary' in the Stock
* We can manually allow the planted forest to grow faster.
         Area(c,species,SSP,'total',t+1) = Area(c,species,SSP,'total',t)*(1+gArea(c,species,SSP,'total',t)+plant(c,'RWD')*Chng_removals(c,t)*.05);
         Area(c,species,SSP,'planted',t+1) = Area(c,species,SSP,'planted',t)*(1+gArea(c,species,SSP,'planted',t)+plant(c,'RWD')*Chng_removals(c,t));
         Area(c,species,SSP,'other',t+1) = Area(c,species,SSP,'total',t+1) - Area(c,species,SSP,'planted',t+1);

* -------------- Clear model variables to free up space ------------------------

         IMlag(k,gg)=import(k,gg,t);
         EXlag(k,g)=export(k,g,t);
         Volume(m,species,type)=gStock(m,species,type,t);
         NPPrate(m,species)=sum(type,gStock(m,species,type,t))*(1+sum((rcp,regions), NPP(t, RCP, regions)*CTR(m,regions)/10000));

         OPTION Clear=qs
         OPTION Clear=qd
         OPTION Clear=flow
         OPTION Clear=Z
         DISPLAY IMlag, EXlag, gtrade, Volume, Area, NPPrate,as,bs,qs1,qd1,priceS1;
)

********************************************************************************
********************************************************************************
**********************      Post Processing Calculation     ********************
********************************************************************************
********************************************************************************

$onmulti
set n "US RPA regions" /"HARVEST"/;
         qs1('HARVEST',c,t) = sum(h, qs1(h,c,t));
         qs1('HARVEST',"United States",t) = sum(rpa, sum(h, qs1(h,rpa,t)))
;

mm('United States') = YES;

PARAMETERS
         deltaps(k,rpa,species,t)         quantity supplied in region c of product k
         deltaqs(k,rpa,species,t)         quantity demanded in region c of product k
         avgpriced(k,t)
         avgprices(k,t)
         countries
;
countries = card(g);

LOOP(t$(ord(t) ge 3 AND ord(t) le period-1),
         deltaps('Harvest',rpa,'C',t)=((sum(h1, priceS1(h1,rpa,t)*qs1(h1,rpa,t)) - sum(h1, priceS1(h1,rpa,t-1)*qs1(h1,rpa,t-1)))/sum(h1, priceS1(h1,rpa,t-1)*qs1(h1,rpa,t-1)))*100/5;
         deltaqs('Harvest',rpa,'C',t)=((sum(h1, qs1(h1,rpa,t)) - sum(h1, qs1(h1,rpa,t-1)))/sum(h1, qs1(h1,rpa,t-1)))*100/5;

         deltaps('Harvest',rpa,'NC',t)=((sum(h2, priceS1(h2,rpa,t)*qs1(h2,rpa,t)) - sum(h2, priceS1(h2,rpa,t-1)*qs1(h2,rpa,t-1)))/sum(h2, priceS1(h2,rpa,t-1)*qs1(h2,rpa,t-1)))*100/5;
         deltaqs('Harvest',rpa,'NC',t)=((sum(h2, qs1(h2,rpa,t)) - sum(h2, qs1(h2,rpa,t-1)))/sum(h2, qs1(h2,rpa,t-1)))*100/5;
)
;

avgpriced(k,t) = sum(g, priceD1(k,g,t))/countries;
avgprices(k,t) = sum(g, priceS1(k,g,t))/countries;

********************************************************************************
********************************************************************************
********************** End of Post Processing Calculation     ******************
********************************************************************************
********************************************************************************
* -------------------------------------------------------------------------
PARAMETERS
         check1(*,*)
         check2(*,*)
         CheckJohn(c,h,t)
         cornifer(*,species,tt)
         noncornifer(*,species,tt)
         pulpwoodC(c,t)
         sawtimberC(c,t)
         pulpwoodNC(c,t)
         sawtimberNC(c,t)
         rpaprice(k,c,t)
         rpaharvest(c,t)                                          ;
checkJohn(rpa,h,t) = Johnremoval(t,rpa,h)- qs1(h,rpa,t);
cornifer(g,'C',tt)=  sum(h1, qs1(h1,g,tt));
noncornifer(g,'NC',tt)= sum(h2, qs1(h2,g,tt));
cornifer("WORLD",'C',tt)= sum(g, sum(h1, qs1(h1,g,tt)));
noncornifer("WORLD",'NC',tt)= sum(g, sum(h2, qs1(h2,g,tt)));
cornifer("United States",'C',tt)= sum(rpa, sum(h1, qs1(h1,rpa,tt)));
noncornifer("United States",'NC',tt)= sum(rpa, sum(h2, qs1(h2,rpa,tt)));
pulpwoodC(rpa,t)=sum(k5, recovt(rpa,'IRC',k5,t)*qs1(k5,rpa,t));
pulpwoodNC(rpa,t)=sum(k5, recovt(rpa,'IRNC',k5,t)*qs1(k5,rpa,t));
sawtimberC(rpa,t)=sum(j3, recovt(rpa,'IRC',j3,t)*qs1(j3,rpa,t));
sawtimberNC(rpa,t)=sum(j3, recovt(rpa,'IRNC',j3,t)*qs1(j3,rpa,t));

rpaprice(j4,rpa,t) = priceS1(j4,rpa,t);
rpaharvest(rpa,t) = qs1('HARVEST',rpa,t);

DISPLAY pulpwoodC, pulpwoodNC, sawtimberC, sawtimberNC, checkJohn, flow.l, qs.l, qd.l, qs1, qd1, prices1, priced1, ad1, bd1, as, ad, pd, bd, chng_removals, removals, gstock, Stock, as1, bs1, Area, deltaps, deltaqs, transt, recovt, beta,cornifer,noncornifer;
execute_unload "ForJohn.gdx" pulpwoodC, pulpwoodNC, sawtimberC, sawtimberNC, rpaprice, rpaharvest;
execute 'gdxxrw.exe ForJohn.gdx Output=ForJohn.xls epsout=0 par=pulpwoodC rng=pulpwoodC!a1 par=pulpwoodNC rng=pulpwoodNC!a1 par=sawtimberC rng=sawtimberC!a1 par=sawtimberNC rng=sawtimberNC!a1 par=rpaprice rng=prices!a1 par=rpaharvest rng=totalharvest!a1'


*************************************
*       Post calculation
*       Re-aggregation
*************************************
;

check3(k,c,t)=qs1(k,c,t)+import(k,c,t)-export(k,c,t);
check4(k,c,t)=round(qs1(k,c,t)+import(k,c,t)-export(k,c,t)-qd1(k,c,t),2);

         qs1(k,c,t)$(t.val gt 2070)=0;
         qd1(k,c,t)$(t.val gt 2070)=0;
         PriceS1(k,c,t)$(t.val gt 2070)=0;
         PriceD1(k,c,t)$(t.val gt 2070)=0;
         import(k,c,t) $(t.val gt 2070)=0;
         export(k,c,t) $(t.val gt 2070)=0;

         qd1(k,c,t)$(NOT qd1(k,c,t))= qs1(k,c,t)+import(k,c,t)-export(k,c,t);



set treetype /C coniferour, NC noniferous, T TOTAL harvest/;
set tradetype /IM Net import level, EX Net export level/;

Parameter

*************************************************************************************************
QS_country(*,region,*,tt),  QD_country(*,region,*,tt),
QS_region(*,region,tt),     QD_region(*,region,tt),
Share_tempS(*,region,*,tt), ShareS(*,*,tt),
Share_tempD(*,region,*,tt), ShareD(*,*,tt),
PS_region(*,region,tt),     PD_region(*,region,tt),
IM_region(*,region,tt),     EX_region(*,region,tt),
Net_trade(k1,*, tt),



QS_ALL(*,*,*),
QD_ALL(*,*,*),
PS_ALL(*,*,*),
PD_ALL(*,*,*),


Forest_landarea(*,*),
Forest_landarea_country(*,*,*,*,*,*)
Forest_landarea_region(*,*,*,*,*)

Forest_Harvest(*,*,*),
Forest_Harvest_region(*,*,*),
Forest_Harvest_country(*,*,*,*)

Forest_stock(*,*),
Forest_stock_c(*,*),
Forest_stock_nc(*,*),
Forest_stock_region(*,*,*),
Forest_stock_country(*,*,*,*)

NetImport_ALL(*,*,*),
NetExport_ALL(*,*,*);

*************************************************************************************************

QS_country(g,region, k1,tt)$ mapC2R(g,region)  = sum(mapC2R(g,region),qs1(k1,g,tt));
QD_country(g,region, k1,tt)$ mapC2R(g,region)  = sum(mapC2R(g,region),qd1(k1,g,tt));
QS_region(k1,region,tt)=sum(g,QS_country(g,region, k1,tt));
QD_region(k1,region,tt)=sum(g,QD_country(g,region, k1,tt));

cornifer(region,'C',tt)=  sum(h1, QS_region(h1,region,tt));
noncornifer(region,'NC',tt)= sum(h2, QS_region(h2,region,tt));

QS_country("United States","North America", k1,tt)=sum(RPA,qs1(k1,RPA,tt));
QD_country("United States","North America",  f,tt)=sum(RPA,qd1(f,RPA,tt));

Share_tempS(mm,region, k1,tt)$QS_region(k1,region,tt) = QS_country(mm,region, k1,tt)/QS_region(k1,region,tt);
Share_tempD(mm,region, f ,tt)$QD_region( f,region,tt) = QD_country(mm,region,  f,tt)/QD_region( f,region,tt);

ShareS(mm, k1,tt)= sum(region,Share_tempS(mm,region, k1,tt));
ShareD(mm,  f,tt)= sum(region,Share_tempD(mm,region,  f,tt));


PriceS1(k1,"United States",tt)$QS_country("United States","North America", k1,tt)=sum(RPA,PriceS1(k1,RPA,tt)*qs1(k1,RPA,tt)/QS_country("United States","North America", k1,tt));
PriceD1( f,"United States",tt)$QD_country("United States","North America",  f,tt)=sum(RPA,PriceD1(f,RPA,tt)*qd1(f,RPA,tt)/QD_country("United States","North America",  f,tt));

PS_region(k1,region,tt)=sum((mapC2R(mm,region)),PriceS1(k1,mm,tt)*ShareS(mm, k1,tt));
PD_region( f,region,tt)=sum((mapC2R(mm,region)),PriceD1( f,mm,tt)*ShareD(mm,  f,tt));

IM_region(k1,region, tt) = sum((mapC2R(g,region)),import(k1,g,tt));
EX_region(k1,region, tt) = sum((mapC2R(g,region)),export(k1,g,tt));

Net_trade(k1,g, tt) = import(k1,g,tt) - export(k1,g,tt);
Net_trade(k1,region, tt) = IM_region(k1,region, tt) - EX_region(k1,region, tt);
Net_trade(k1,"World", tt) = sum(g, import(k1,g,tt) - export(k1,g,tt));
Net_trade(k1,"United States", tt) = sum(RPA, import(k1,RPA,tt) - export(k1,RPA,tt));

display QS_country, QD_country, QS_region,QD_region,PS_region,PD_region,IM_region,EX_region,Net_trade;



QS_ALL(k1,g,tt)=qs1(k1, g,tt);
QS_ALL(k1,region,tt)=QS_region(k1, region,tt);
QS_ALL(k1,"World",tt)=sum(g,qs1(k1,g,tt));
QS_ALL(k1,"United States",tt)=sum(RPA,qs1(k1,RPA,tt));


QD_ALL(k1,g,tt)=qd1(k1, g,tt);
QD_ALL(k1,region,tt)=QD_region(k1, region,tt);
QD_ALL(k1,"World",tt)=sum(g,qd1(k1,g,tt));
QD_ALL(k1,"United States",tt)=sum(RPA,qd1(k1,RPA,tt));



Share_tempS(g,region, k2,tt)$QS_region(k2,region,tt) = QS_country(g,region, k2,tt)/QS_region(k2,region,tt);
ShareS(g, k2,tt)= sum(region,Share_tempS(g,region, k2,tt));
PS_region(k2,region,tt)=sum((mapC2R(g,region)),PriceS1(k2,g,tt)*ShareS(g, k2,tt));
PS_ALL(k2,g,tt)=PriceS1(k2, g,tt);
PS_ALL(k2,region,tt)=PS_region(k2, region,tt);
PS_ALL(k2,"United States",tt)$QS_ALL(k2,"United States",tt)=sum(RPA,PriceS1(k2,RPA,tt)*qs1(k2,RPA,tt)/QS_ALL(k2,"United States",tt) );
PS_ALL(k2,"World",tt)$QS_ALL(k2,"World",tt)=sum(region,PS_ALL(k2,region,tt)*QS_ALL(k2,region,tt)/QS_ALL(k2,"World",tt))+
                                            PS_ALL(k2,"ROW",tt)*QS_ALL(k2,"ROW",tt)/QS_ALL(k2,"World",tt);


Share_tempD(g,region, f1 ,tt)$QD_region( f1,region,tt) = QD_country(g,region,  f1,tt)/QD_region( f1,region,tt);
ShareD(g,  f1,tt)= sum(region,Share_tempD(g,region,  f1,tt));
PD_region( f1,region,tt)=sum((mapC2R(g,region)),PriceD1( f1,g,tt)*ShareD(g,  f1,tt));
PD_ALL(f1,g,tt)=PriceD1(f1, g,tt);
PD_ALL(f1,region,tt)=PD_region(f1, region,tt);
PD_ALL(f1,"United States",tt)$QD_ALL(f1,"United States",tt)=sum(RPA,PriceD1(f1,RPA,tt)*qd1(f1,RPA,tt)/QD_ALL(f1,"United States",tt) );
PD_ALL(f1,"World",tt)$QD_ALL(f1,"World",tt)=sum(region,PD_ALL(f1,region,tt)*QD_ALL(f1,region,tt)/QD_ALL(f1,"World",tt)) +
                                            PD_ALL(f1,"ROW",tt)*QD_ALL(f1,"ROW",tt)/QD_ALL(f1,"World",tt);

PD_ALL('News',allcnr,tt) = PS_ALL('News',allcnr,tt) ;
PS_ALL(f1,allcnr,tt) = PD_ALL(f1,allcnr,tt) ;

Forest_Harvest("C",allcnr,tt)=sum(h1,QS_ALL(h1,allcnr,tt));
Forest_Harvest("NC",allcnr,tt)=sum(h2,QS_ALL(h2,allcnr,tt));
Forest_Harvest("T",allcnr,tt)= sum(h,QS_ALL(h,allcnr,tt));

Forest_landarea_country(g,region,species,scenario,type,tt)$ mapC2R(g,region)= sum(mapC2R(g,region),Area(g,species,scenario,type,tt) );
Forest_landarea_region(region,species,scenario,type,tt)=sum(g,Forest_landarea_country(g,region,species,scenario,type,tt));
Forest_landarea(g,tt)=AREA(g,'NC',"%SC%", "TOTAL" ,tt)  + AREA(g,'C',"%SC%", "TOTAL" ,tt);
Forest_landarea(region,tt)=Forest_landarea_region(region,'NC',"%SC%", "TOTAL" ,tt)+Forest_landarea_region(region,'C',"%SC%", "TOTAL" ,tt);
Forest_landarea('World',tt)=sum(g,AREA(g,'NC',"%SC%", "TOTAL" ,tt)  + AREA(g,'C',"%SC%", "TOTAL" ,tt));
Forest_landarea('United States',tt)=sum(RPA,AREA(RPA,'NC',"%SC%", "TOTAL" ,tt)  + AREA(RPA,'C',"%SC%", "TOTAL" ,tt));

Forest_stock_country(g,region,species,tt)$ mapC2R(g,region)= sum(mapC2R(g,region),stock(g,species,tt) );
Forest_stock_region(region,species,tt)=sum(g,Forest_stock_country(g,region,species,tt));
Forest_stock(g,tt)=stock(g,'NC',tt)  + stock(g,'C',tt);
Forest_stock(region,tt)=Forest_stock_region(region,'NC',tt)+Forest_stock_region(region,'C',tt);
Forest_stock('World',tt)=sum(g,stock(g,'NC', tt)  + stock(g,'C' ,tt));
Forest_stock('United States',tt)=sum(RPA,stock(RPA,'NC',tt)  + stock(RPA,'C',tt));

Forest_stock_c(g,tt)=stock(g,'C',tt);
Forest_stock_c(region,tt)=Forest_stock_region(region,'C',tt);
Forest_stock_c('World',tt)=sum(g,stock(g,'C' ,tt));
Forest_stock_c('United States',tt)=sum(RPA, stock(RPA,'C',tt));

Forest_stock_nc(g,tt)=stock(g,'NC',tt);
Forest_stock_nc(region,tt)=Forest_stock_region(region,'NC',tt);
Forest_stock_nc('World',tt)=sum(g,stock(g,'NC', tt) );
Forest_stock_nc('United States',tt)=sum(RPA,stock(RPA,'NC',tt));

display Forest_landarea,Forest_Harvest,Forest_stock,Forest_stock_c,Forest_stock_nc,PS_ALL,PD_ALL;


NetImport_ALL(k1,allcnr,tt)$(Net_trade(k1,allcnr,tt) gt 0)=Net_trade(k1,allcnr,tt);
NetExport_ALL(k1,allcnr,tt)$(Net_trade(k1,allcnr,tt) le 0)=-Net_trade(k1,allcnr,tt);


check1(f1,tt)=round(QD_ALL(f1,"World",tt)-QD_ALL(f1,"ROW",tt)-sum(region,QD_ALL(f1,region,tt)),6);
check2(k2,tt)=round(QS_ALL(k2,"World",tt)-QS_ALL(k2,"ROW",tt)-sum(region,QS_ALL(k2,region,tt)),6);


display QS_ALL, QD_ALL,g,mm,check1,check2,check3,check4;

execute_unload "ForStep5.gdx" QS_ALL, QD_ALL, NetImport_ALL, NetExport_ALL,PS_ALL,PD_ALL,Forest_stock_c,Forest_stock_nc;


File RPA2020 / 'RPA2020---%SC%.csv' /;
*output.nr = 2
put RPA2020;

RPA2020.pc=5;



put  "Results of FOROM model"/;

put / "Production Level" /;
loop (k1,put / k1.te(k1) Loop (tt, put  tt.val );
      loop(allcnr, put / allcnr.tl;
      loop(tt, put  QS_ALL(k1,allcnr,tt) ););  put /)

put  "Consumption Level" /;
loop (k1,put / k1.te(k1) Loop (tt, put  tt.val );
      loop(allcnr, put / allcnr.tl;
      loop(tt, put  QD_ALL(k1,allcnr,tt) ););  put /)

put / "Price" /;
loop (k2,put / k2.te(k2) Loop (tt, put  tt.val );
      loop(allcnr, put / allcnr.tl;
      loop(tt, put  PS_ALL(k2,allcnr,tt) ););  put /)

put / "Timber harvest" /;
loop (treetype,put / treetype.te(treetype) Loop (tt, put  tt.val );
      loop(allcnr, put / allcnr.tl;
      loop(tt, put  Forest_Harvest(treetype,allcnr,tt) ););  put /)

put / "Net Import" /;
loop (k1,put / k1.te(k1) Loop (tt, put  tt.val );
      loop(allcnr, put / allcnr.tl;
      loop(tt, put  NetImport_ALL(k1,allcnr,tt) ););  put /)

put / "Net export" /;
loop (k1,put / k1.te(k1) Loop (tt, put  tt.val );
      loop(allcnr, put / allcnr.tl;
      loop(tt, put  NetExport_ALL(k1,allcnr,tt) ););  put /)

putclose;
*************************************************************************************************
*************************************************************************************************
*************************************************************************************************
*************************************************************************************************
display g;

execute_unload "Results.gdx" qd1, qs1, priced1, prices1, Stock, Area, import, export, deltaps, deltaqs, check1, check2, as1,bs1, ad1,bd1,beta, gstock, cornifer, noncornifer,Forest_landarea,Forest_Harvest,Forest_stock;

execute_unload "%SC%.gdx" qd1, qs1, priced1, prices1, Stock, Area, import, export, deltaps, deltaqs, check1, check2, as1,bs1, ad1,bd1,beta, gGDPP, gstock, cornifer, noncornifer;
