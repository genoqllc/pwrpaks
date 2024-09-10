# wh3lk submodular power pack

A lil eurorack power module, primilary for prototyping. Takes 16 pin eurorack power and outputs:

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

- The main board and Gerbers zip
- A BOM in CSV format, ready for JCLPCB assembly
- A POS in CSV format, ready for JCLPCB assembly
