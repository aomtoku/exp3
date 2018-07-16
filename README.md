# Inference Server

# Directory
```
lib/ -> NetFPGA-SUME library
contrib-projects -> The project files for NetFPGA-SUME
```

# Porting to NetFPGA-SUME-dev or live
```
 $ cp -r lib/* <NetFPGA-SUME-live>/lib/hw/std/cores/
 $ cp -r contrib-projects/* <NetFPGA-SUME-live>/contrib-projects/
 $ vim settings.sh
 $ source settings.sh
 $ make -C $SUME_FORDER && make -C $NF_DESIGN_DIR
```

