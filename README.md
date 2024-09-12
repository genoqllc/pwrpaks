# wh3lk submodular power pack

A lil [eurorack power module](https://kicanvas.org/?github=https%3A%2F%2Fgithub.com%2Fgenoqllc%2Fwh3lk%2Fblob%2Fmain%2Fhardware%2Fwh3lk.kicad_pcb), primilary for prototyping. Takes 16 pin eurorack power and outputs:

- +12V
- +5V
- +3.3V
- +3.3VA (filtered for analog devices)
- -12V
- -10V reference
- GND

![image](https://github.com/user-attachments/assets/5e5e1084-b0c8-40ad-8d1a-395b8dbf47f8)

## Releases

Upon merging to `main` and creating a release, the [`Makefile.yml` Github Action](https://github.com/genoqllc/wh3lk/actions/workflows/makefile.yml) will build the project and attach the following to the release:

- `wh3lk-$(GIT_TAG).zip` - Gerbers, drill files, DRC report
- `wh3lk-$(GIT_TAG).bom.csv` - A BOM in CSV format, ready for JLCPCB assembly
- `wh3lk-$(GIT_TAG).bom.xml` - Original KiCad XML BOM
- `wh3lk-$(GIT_TAG).pos.csv` - A POS in CSV format, ready for JLCPCB assembly

![image](https://github.com/user-attachments/assets/caa703a8-b0da-4651-9198-f886544c9dc1)
