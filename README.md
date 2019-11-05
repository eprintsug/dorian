# dorian

## install
` ./tools/epm link_lib dorian #if required`
` ./tools/epm enable repoid dorian`

## configure

Some config can be found in ARCHIVEID/cfg/cfg.d/zzz_doriancfg.pl

Otherwise there are two manual actions required to complete the installation/configuration

* In your main template (default.xml or equivalent) find `<epc:pin ref="head"/>`  and *ABOVE IT* add `<epc:phrase ref="dorian_head"/>`
* In your abstract citation (summmary_page.xml or equivalent) add ` <epc:print expr="$item.citation('dorian')"/>` wherever and instead of whatever you wish.
* In order to ensure that the change is cascaded correctly to all the pre-existing items in the repository, please make sure that you run the following 2 commands (they both might take a while to complete, depending on the size of the repository): 


```bash
eprint3/bin/epadmin redo_mime_type [ARCHIVE_NAME] document
```
 

and 
 

```bash
eprint3/bin/generate_abstracts [ARCHIVE_NAME]
```
