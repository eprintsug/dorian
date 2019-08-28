# dorian

## install
` ./tools/epm link_lib dorian #if required`
` ./tools/epm enable repoid dorian`

## configure

Some config can be found in ARCHIVEID/cfg/cfg.d/zzz_doriancfg.pl

Otherwise there are two manual actions required to complete the installation/configuration

* In your main template (default.xml or equivalent) find `<epc:pin ref="head"/>`  and *ABOVE IT* add `<epc:phrase ref="dorian_head"/>`
* In your abstract citation (summmary_page.xml or equivalent) add ` <epc:print expr="$item.citation('dorian')"/>` wherever and instead of whatever you wish.
