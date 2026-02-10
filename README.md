AI SLOP DISCLAIMER
==================

NO PART OF THIS WORK OR WORKS DERIVED THEREFROM MAY BE USED BY ANY MEANS FOR
THE TRAINING OF OR ANALYSIS BY AI TOOLS.

Kasumi Cipher Verilog Implementation
====================================

[Wikipedia on KASUMI](https://en.wikipedia.org/wiki/KASUMI).

Important points:

* includes kasumi (iteratively and fully unrolled), f8 and f9
* passes all provided test cases by spec (full regression testbench)
* (but byte handling is a hassle -> check the testbenches)
* the unrolled cipher is there, but not used in f8 nor f9 (feel free to use it
  in a suitble CBC mode)
* timing is abysmal, but that's down to the cipher (we could improve it, but at
  the expense of extra cycles, which wouldn't help performance)
* code in the f8 and f9 modules should be cleaned up somewhat...
* (there could be more formal checks...)
* (random constrained testbench with golden model still TODO...)

Resource Usage and Timing
-------------------------

Target device: `xc7a100tfgg484-3`

Target frequency: 100 MHz

`kasumi_iter`:

```
+-------------------------+--------------+------------+------------+---------+------+-----+--------+--------+------------+
|         Instance        |    Module    | Total LUTs | Logic LUTs | LUTRAMs | SRLs | FFs | RAMB36 | RAMB18 | DSP Blocks |
+-------------------------+--------------+------------+------------+---------+------+-----+--------+--------+------------+
| kasumi_iter             |        (top) |       1030 |       1030 |       0 |    0 | 325 |      0 |      0 |          0 |
|   (kasumi_iter)         |        (top) |          5 |          5 |       0 |    0 |   4 |      0 |      0 |          0 |
|   kasumi_stage_inst     | kasumi_stage |       1025 |       1025 |       0 |    0 | 321 |      0 |      0 |          0 |
|     (kasumi_stage_inst) | kasumi_stage |        755 |        755 |       0 |    0 | 321 |      0 |      0 |          0 |
|     kasumi_f_inst       |     kasumi_f |        270 |        270 |       0 |    0 |   0 |      0 |      0 |          0 |
|       kasumi_fo_inst    |    kasumi_fo |        270 |        270 |       0 |    0 |   0 |      0 |      0 |          0 |
|         kasumi_fi_inst0 |    kasumi_fi |         91 |         91 |       0 |    0 |   0 |      0 |      0 |          0 |
|         kasumi_fi_inst1 |  kasumi_fi_0 |         84 |         84 |       0 |    0 |   0 |      0 |      0 |          0 |
|         kasumi_fi_inst2 |  kasumi_fi_1 |         95 |         95 |       0 |    0 |   0 |      0 |      0 |          0 |
+-------------------------+--------------+------------+------------+---------+------+-----+--------+--------+------------+
Slack (VIOLATED) :        -0.227ns  (required time - arrival time)
  Source:                 kasumi_stage_inst/r_data_reg[41]/C
                            (rising edge-triggered cell FDRE clocked by clock  {rise@0.000ns fall@5.000ns period=10.000ns})
  Destination:            kasumi_stage_inst/r_data_reg[45]/D
                            (rising edge-triggered cell FDRE clocked by clock  {rise@0.000ns fall@5.000ns period=10.000ns})
  Path Group:             clock
  Path Type:              Setup (Max at Slow Process Corner)
  Requirement:            10.000ns  (clock rise@10.000ns - clock rise@0.000ns)
  Data Path Delay:        10.197ns  (logic 2.325ns (22.801%)  route 7.872ns (77.199%))
  Logic Levels:           17  (LUT3=2 LUT5=3 LUT6=11 MUXF7=1)
```

`kasumi_f8`:

```
+-----------------------------+---------------+------------+------------+---------+------+-----+--------+--------+------------+
|           Instance          |     Module    | Total LUTs | Logic LUTs | LUTRAMs | SRLs | FFs | RAMB36 | RAMB18 | DSP Blocks |
+-----------------------------+---------------+------------+------------+---------+------+-----+--------+--------+------------+
| kasumi_f8                   |         (top) |       1129 |       1129 |       0 |    0 | 666 |      0 |      0 |          0 |
|   (kasumi_f8)               |         (top) |          0 |          0 |       0 |    0 |  72 |      0 |      0 |          0 |
|   kasumi_f8_ctl_inst        | kasumi_f8_ctl |       1129 |       1129 |       0 |    0 | 594 |      0 |      0 |          0 |
|     (kasumi_f8_ctl_inst)    | kasumi_f8_ctl |          9 |          9 |       0 |    0 | 269 |      0 |      0 |          0 |
|     kasumi_iter_inst        |   kasumi_iter |       1120 |       1120 |       0 |    0 | 325 |      0 |      0 |          0 |
|       kasumi_stage_inst     |  kasumi_stage |       1110 |       1110 |       0 |    0 | 321 |      0 |      0 |          0 |
|         (kasumi_stage_inst) |  kasumi_stage |        837 |        837 |       0 |    0 | 321 |      0 |      0 |          0 |
|         kasumi_f_inst       |      kasumi_f |        273 |        273 |       0 |    0 |   0 |      0 |      0 |          0 |
|           kasumi_fo_inst    |     kasumi_fo |        273 |        273 |       0 |    0 |   0 |      0 |      0 |          0 |
|             kasumi_fi_inst0 |     kasumi_fi |         91 |         91 |       0 |    0 |   0 |      0 |      0 |          0 |
|             kasumi_fi_inst1 |   kasumi_fi_0 |         84 |         84 |       0 |    0 |   0 |      0 |      0 |          0 |
|             kasumi_fi_inst2 |   kasumi_fi_1 |         98 |         98 |       0 |    0 |   0 |      0 |      0 |          0 |
+-----------------------------+---------------+------------+------------+---------+------+-----+--------+--------+------------+
Slack (VIOLATED) :        -0.841ns  (required time - arrival time)
  Source:                 kasumi_f8_ctl_inst/kasumi_iter_inst/kasumi_stage_inst/r_data_reg[41]/C
                            (rising edge-triggered cell FDRE clocked by clock  {rise@0.000ns fall@5.000ns period=10.000ns})
  Destination:            kasumi_f8_ctl_inst/kasumi_iter_inst/kasumi_stage_inst/r_data_reg[62]/D
                            (rising edge-triggered cell FDRE clocked by clock  {rise@0.000ns fall@5.000ns period=10.000ns})
  Path Group:             clock
  Path Type:              Setup (Max at Slow Process Corner)
  Requirement:            10.000ns  (clock rise@10.000ns - clock rise@0.000ns)
  Data Path Delay:        10.811ns  (logic 2.718ns (25.141%)  route 8.093ns (74.859%))
  Logic Levels:           21  (LUT2=1 LUT3=3 LUT4=2 LUT5=3 LUT6=11 MUXF7=1)
```

`kasumi_f9`:

```
+-------------------------------+--------------+------------+------------+---------+------+-----+--------+--------+------------+
|            Instance           |    Module    | Total LUTs | Logic LUTs | LUTRAMs | SRLs | FFs | RAMB36 | RAMB18 | DSP Blocks |
+-------------------------------+--------------+------------+------------+---------+------+-----+--------+--------+------------+
| kasumi_f9                     |        (top) |       1338 |       1338 |       0 |    0 | 524 |      0 |      0 |          0 |
|   (kasumi_f9)                 |        (top) |          1 |          1 |       0 |    0 | 199 |      0 |      0 |          0 |
|   kasumi_iter_inst            |  kasumi_iter |       1337 |       1337 |       0 |    0 | 325 |      0 |      0 |          0 |
|     kasumi_stage_inst         | kasumi_stage |       1326 |       1326 |       0 |    0 | 321 |      0 |      0 |          0 |
|       (kasumi_stage_inst)     | kasumi_stage |       1051 |       1051 |       0 |    0 | 321 |      0 |      0 |          0 |
|       kasumi_f_inst           |     kasumi_f |        275 |        275 |       0 |    0 |   0 |      0 |      0 |          0 |
|         kasumi_fo_inst        |    kasumi_fo |        275 |        275 |       0 |    0 |   0 |      0 |      0 |          0 |
|           kasumi_fi_inst0     |    kasumi_fi |         91 |         91 |       0 |    0 |   0 |      0 |      0 |          0 |
|           kasumi_fi_inst1     |  kasumi_fi_0 |         84 |         84 |       0 |    0 |   0 |      0 |      0 |          0 |
|           kasumi_fi_inst2     |  kasumi_fi_1 |        100 |        100 |       0 |    0 |   0 |      0 |      0 |          0 |
|             kasumi_s9_inst_l0 |    kasumi_s9 |         50 |         50 |       0 |    0 |   0 |      0 |      0 |          0 |
|             kasumi_s9_inst_l2 |  kasumi_s9_3 |         50 |         50 |       0 |    0 |   0 |      0 |      0 |          0 |
+-------------------------------+--------------+------------+------------+---------+------+-----+--------+--------+------------+
Slack (VIOLATED) :        -1.188ns  (required time - arrival time)
  Source:                 kasumi_iter_inst/kasumi_stage_inst/r_data_reg[41]/C
                            (rising edge-triggered cell FDRE clocked by clock  {rise@0.000ns fall@5.000ns period=10.000ns})
  Destination:            kasumi_iter_inst/kasumi_stage_inst/r_data_reg[54]/D
                            (rising edge-triggered cell FDRE clocked by clock  {rise@0.000ns fall@5.000ns period=10.000ns})
  Path Group:             clock
  Path Type:              Setup (Max at Slow Process Corner)
  Requirement:            10.000ns  (clock rise@10.000ns - clock rise@0.000ns)
  Data Path Delay:        11.158ns  (logic 2.828ns (25.345%)  route 8.330ns (74.655%))
  Logic Levels:           20  (LUT3=2 LUT5=6 LUT6=10 MUXF7=2)
```

Specifications
--------------

This work is based upon the following specifications:

* 3GPP TS 35.201: "3rd Generation Partnership Project; Technical Specification
  Group Services and System Aspects; 3G Security; Specification of the 3GPP
  Confidentiality and Integrity Algorithms; Document 1: f8 and f9
  Specification".
* 3GPP TS 35.202: "3rd Generation Partnership Project; Technical Specification
  Group Services and System Aspects; 3G Security; Specification of the 3GPP
  Confidentiality and Integrity Algorithms; Document 2: KASUMI Specification".
* 3GPP TS 35.203: "3rd Generation Partnership Project; Technical Specification
  Group Services and System Aspects; 3G Security; Specification of the 3GPP
  Confidentiality and Integrity Algorithms; Document 3: Implementors' Test
  Data".

License
-------

See file `LICENSE` in top directory.

Legal Notice
------------

The code in the repository is public domain and not subject to the Wassenaar
Agreement. See also [here](https://www.gnu.org/philosophy/wassenaar.en.html).
