`define AddressBus  31:0
`define InstBus     31:0
`define RegAddressBus  4:0
`define RegBus  31:0
`define CSRAddressBus  12:0
`define IcacheSize      256
`define IcacheTagBus    7:0
`define IcacheIndex     9:2
`define IcacheTag       17:10
`define DcacheSize      32
`define DcacheTagBus    12:0
`define DcacheIndex     4:0
`define DcacheIndexLen  5
`define DcacheTag       17:5
`define predictorSize   128
`define predictorTagBus 8:0
`define predictorIndex  8:2
`define predictorTag    17:9

// Stall
`define StallBus    5:0

// Inst
`define InstShort   5:0
`define instNOP 0
`define instADD 1
`define instSUB 2
`define instSLL 3
`define instSLT 4
`define instSLTU 5
`define instXOR 6
`define instSRL 7
`define instSRA 8
`define instOR 9
`define instAND 10
`define instJALR 11
`define instLB 12
`define instLH 13
`define instLW 14
`define instLBU 15
`define instLHU 16
`define instADDI 17
`define instSLTI 18
`define instSLTIU 19
`define instXORI 20
`define instORI 21
`define instANDI 22
`define instSLLI 23
`define instSRLI 24
`define instSRAI 25
`define instSB 26
`define instSH 27
`define instSW 28
`define instBEQ 29
`define instBNE 30
`define instBLT 31
`define instBGE 32
`define instBLTU 33
`define instBGEU 34
`define instLUI 35
`define instAUIPC 36
`define instJAL 37
`define instCSRRW 38
`define instCSRRS 39
`define instCSRRC 40
`define instCSRRWI 41
`define instCSRRSI 42
`define instCSRRCI 43
`define instMRET 44

//CSR
`define csrmtvec 'h305
`define csrmepc 'h341

