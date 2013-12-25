xcom-roguelike
==============

Roguelike game loosely inspired by XCOM: Enemy Unknown

To run:

    coffee -w -j xcomrl.js -c src/{core_ext,unit,map,ui,xcomrl}.coffee

To run tests:

    coffee -w -j xcomrl_test.js -c src/{core_ext,unit,map}.coffee spec/*.coffee
