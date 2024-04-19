execute 'gams Step_4_FOROM_simulation.gms --sc=SSP1'
execute 'gams Step_5_FOROM_History.gms    --sc=SSP1'

execute 'gams Step_4_FOROM_simulation.gms --sc=SSP2'
execute 'gams Step_5_FOROM_History.gms    --sc=SSP2'

execute 'gams Step_4_FOROM_simulation.gms --sc=SSP3'
execute 'gams Step_5_FOROM_History.gms    --sc=SSP3'

execute 'gams Step_4_FOROM_simulation.gms --sc=SSP4'
execute 'gams Step_5_FOROM_History.gms    --sc=SSP4'

execute 'gams Step_4_FOROM_simulation.gms --sc=SSP5'
execute 'gams Step_5_FOROM_History.gms    --sc=SSP5'


execute 'gdxmerge SSP1.gdx SSP2.gdx SSP3.gdx SSP4.gdx SSP5.gdx o=ALLSSP.gdx';
*execute 'gdxmerge SSP*.gdx';
