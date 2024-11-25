///////////////////////////////////////////
// fpu.sv
//
// Written: me@KatherineParry.com, James Stine, Brett Mathis, David Harris
// Modified: 11/09/2024 by Maxim Kudinov
//
// Purpose: Floating Point Unit Top-Level Interface
//
// Documentation: RISC-V System on Chip Design
//
// A component of the CORE-V-WALLY configurable RISC-V project.
// https://github.com/openhwgroup/cvw
//
// Copyright (C) 2021-23 Harvey Mudd College & Oklahoma State University
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file
// except in compliance with the License, or, at your option, the Apache License version 2.0. You
// may obtain a copy of the License at
//
// https://solderpad.org/licenses/SHL-2.1/
//
// Unless required by applicable law or agreed to in writing, any work distributed under the
// License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
// either express or implied. See the License for the specific language governing permissions
// and limitations under the License.
////////////////////////////////////////////////////////////////////////////////////////////////

module wally_fpu (
  input  logic                 clk,
  input  logic                 reset,

  input  logic [4:0]           Operation,
  input  logic [FMTBITS-1:0]   Format,
  input  logic [6:0]           Opcode,
  input  logic [FLEN-1:0]      A,
  input  logic [FLEN-1:0]      B,
  input  logic                 UpValid,

  output logic [FLEN-1:0]      Res,
  output logic                 DownValid,
  output logic                 FDivBusyE,                          // Is the divide/sqrt unit busy (stall execute stage) (to HZU)
  output logic [4:0]           SetFflagsM,                         // FPU flags (to privileged unit)

  // Original FPU outputs, unused

  // Hazards
  output logic                 FPUStallD,                          // Stall the decode stage (To HZU)

  // Execute stage
  output logic                 FWriteIntE,                         // integer register write enable (to IEU)
  output logic                 FCvtIntE,                           // Convert to int (to IEU)

  // Memory stage
  output logic                 FRegWriteM,                         // FP register write enable (to privileged unit)
  output logic                 FpLoadStoreM,                       // Fp load instruction? (to LSU)
  output logic [  FLEN-1:0]    FWriteDataM,                        // Data to be written to memory (to LSU)
  output logic [  XLEN-1:0]    FIntResM,                           // data to be written to integer register (to IEU)
  output logic                 IllegalFPUInstrD,                   // Is the instruction an illegal fpu instruction (to IFU)

  // Writeback stage
  output logic [  XLEN-1:0]    FCvtIntResW,                        // convert result to to be written to integer register (to IEU)
  output logic                 FCvtIntW,                           // select FCvtIntRes (to IEU)
  output logic [  XLEN-1:0]    FIntDivResultW                      // Result from integer division (to IEU)
);

  // RISC-V FPU specifics:
  //    - multiprecision support uses NAN-boxing, putting 1's in unused msbs
  //    - RISC-V detects underflow after rounding

  // control signals
  logic                        FRegWriteW;                         // FP register write enable
  logic [2:0]                  FrmE, FrmM;                         // FP rounding mode
  logic [  FMTBITS-1:0]        FmtE, FmtM;                         // FP precision 0-single 1-double
  logic                        FDivStartE, IDivStartE;             // Start division or squareroot
  logic                        FWriteIntM;                         // Write to integer register
  logic [1:0]                  ForwardXE, ForwardYE, ForwardZE;    // forwarding mux control signals
  logic [2:0]                  OpCtrlE, OpCtrlM;                   // Select which operation to do in each component
  logic [1:0]                  FResSelE, FResSelM, FResSelW;       // Select one of the results that finish in the memory stage
  logic [1:0]                  PostProcSelE, PostProcSelM;         // select result in the post processing unit
  logic [4:0]                  Adr1D, Adr2D, Adr3D;                // register adresses of each input
  logic [4:0]                  Adr1E, Adr2E, Adr3E;                // register adresses of each input
  logic                        XEnD, YEnD, ZEnD;                   // X, Y, Z inputs used for current operation
  logic                        XEnE, YEnE, ZEnE;                   // X, Y, Z inputs used for current operation
  logic                        FRegWriteE;                         // Write floating-point register
  logic                        FPUActiveE;                         // FP instruction being executed
  logic                        ZfaE, ZfaM;                         // Zfa variants of instructions (fli, fminm, fmaxm, fround, froundnx, fleq, fltq, fmvh, fmvp, fcvtmod.w.d)
  logic                        ZfaFRoundNXE;                       // Zfa froundnx variant

  // regfile signals
  logic [  FLEN-1:0]           FRD1D, FRD2D, FRD3D;                // Read Data from FP register - decode stage
  logic [  FLEN-1:0]           FRD1E, FRD2E, FRD3E;                // Read Data from FP register - execute stage
  logic [  FLEN-1:0]           XE;                                 // Input 1 to the various units (after forwarding)
  logic [  XLEN-1:0]           IntSrcXE;                           // Input 1 to the various units (after forwarding)
  logic [  FLEN-1:0]           PreYE, YE;                          // Input 2 to the various units (after forwarding)
  logic [  FLEN-1:0]           PreZE, ZE;                          // Input 3 to the various units (after forwarding)

  // unpacking signals
  logic                        XsE, YsE, ZsE;                      // input's sign - execute stage
  logic                        XsM, YsM;                           // input's sign - memory stage
  logic [  NE-1:0]             XeE, YeE, ZeE;                      // input's exponent - execute stage
  logic [  NE-1:0]             ZeM;                                // input's exponent - memory stage
  logic [  NF:0]               XmE, YmE, ZmE;                      // input's significand - execute stage
  logic [  NF:0]               XmM, YmM, ZmM;                      // input's significand - memory stage
  logic                        XNaNE, YNaNE, ZNaNE;                // is the input a NaN - execute stage
  logic                        XNaNM, YNaNM, ZNaNM;                // is the input a NaN - memory stage
  logic                        XSNaNE, YSNaNE, ZSNaNE;             // is the input a signaling NaN - execute stage
  logic                        XSNaNM, YSNaNM, ZSNaNM;             // is the input a signaling NaN - memory stage
  logic                        XSubnormE;                          // is the input subnormal
  logic                        XZeroE, YZeroE, ZZeroE;             // is the input zero - execute stage
  logic                        XZeroM, YZeroM;                     // is the input zero - memory stage
  logic                        XInfE, YInfE, ZInfE;                // is the input infinity - execute stage
  logic                        XInfM, YInfM, ZInfM;                // is the input infinity - memory stage
  logic                        XExpMaxE;                           // is the exponent all ones (max value)
  logic [  FLEN-1:0]           XPostBoxE;                          // X after fixing bad NaN box.  Needed for 1-input operations
  logic [  NE-2:0]             BiasE;                              // Bias of exponent
  logic [  LOGFLEN-1:0]        NfE;                                // Number of fractional bits

  // Fma Signals
  logic                        FmaAddSubE;                         // Multiply by 1.0 when adding or subtracting
  logic [1:0]                  FmaZSelE;                           // Select Z = Y when adding or subtracting, 0 when multiplying
  logic [  FMALEN-1:0]         SmE, SmM;                           // Sum significand
  logic                        FmaAStickyE, FmaAStickyM;           // FMA addend sticky bit output
  logic [  NE+1:0]             SeE,SeM;                            // Sum exponent
  logic                        InvAE, InvAM;                       // Invert addend
  logic                        AsE, AsM;                           // Addend sign
  logic                        PsE, PsM;                           // Product sign
  logic                        SsE, SsM;                           // Sum sign
  logic [$clog2(  FMALEN+1)-1:0] SCntE, SCntM;                       // LZA sum leading zero count

  // Cvt Signals
  logic [  NE:0]               CeE, CeM;                           // convert intermediate expoent
  logic [  LOGCVTLEN-1:0]      CvtShiftAmtE, CvtShiftAmtM;         // how much to shift by
  logic                        CvtResSubnormUfE, CvtResSubnormUfM; // does the result underflow or is subnormal
  logic                        CsE, CsM;                           // convert result sign
  logic                        IntZeroE, IntZeroM;                 // is the integer zero?
  logic [  CVTLEN-1:0]         CvtLzcInE, CvtLzcInM;               // input to the Leading Zero Counter (priority encoder)
  logic [  XLEN-1:0]           FCvtIntResM;                        // fcvt integer result (for IEU)

  // divide signals
  logic [  DIVb:0]             UmM;                                // fdivsqrt signifcand
  logic [  NE+1:0]             UeM;                                // fdivsqrt exponent
  logic                        DivStickyM;                         // fdivsqrt sticky bit
  logic                        FDivDoneE, IFDivStartE;             // fdivsqrt control signals
  logic [  XLEN-1:0]           FIntDivResultM;                     // fdivsqrt integer division result (for IEU)

  // result and flag signals
  logic [  XLEN-1:0]           ClassResE;                          // classify result
  logic [  FLEN-1:0]           CmpFpResE;                          // compare result to FPU (min/max)
  logic [  XLEN-1:0]           CmpIntResE;                         // compare result to IEU (eq/lt/le)
  logic                        CmpNVE;                             // compare invalid flag (Not Valid)
  logic [  FLEN-1:0]           SgnResE;                            // sign injection result
  logic [  XLEN-1:0]           FIntResE;                           // FPU to IEU E-stage result (classify, compare, move)
  logic [  FLEN-1:0]           PostProcResM;                       // Postprocessor output
  logic [4:0]                  PostProcFlgM;                       // Postprocessor flags
  logic                        PreNVE, PreNVM;                     // selected invalid flag that is ready in the memory stage
  logic                        PreNXE, PreNXM;                     // selected inexact flag that is ready in the memory stage
  logic [  FLEN-1:0]           FpResM, FpResW;                     // FPU preliminary result
  logic [  FLEN-1:0]           PreFpResE, PreFpResM;               // selected result that is ready in the memory stage
  logic [  FLEN-1:0]           FResultW;                           // final FP result being written to the FP register

  // other signals
  logic [  FLEN-1:0]           PreIntSrcE, IntSrcE;                // align SrcA from IEU to the floating point format for fmv / fmvp
  logic [  FLEN-1:0]           BoxedZeroE;                         // Zero value for Z for multiplication, with NaN boxing if needed
  logic [  FLEN-1:0]           BoxedOneE;                          // One value for Z for multiplication, with NaN boxing if needed
  logic                        StallUnpackedM;                     // Stall unpacker outputs during multicycle fdivsqrt
  logic [  FLEN-1:0]           SgnExtXE;                           // Sign-extended X input for move to integer
  logic                        mvsgn;                              // sign bit for extending move
  logic [  FLEN-1:0]           ZfaResE;                            // Result of Zfa fli or fround instruction
  logic                        FRoundNVE, FRoundNXE;               // Zfa fround invalid and inexact flags

  logic                        VldE, VldM, VldW;
  logic                        VldFmaFDiv;

  //////////////////////////////////////////////////////////////////////////////////////////
  // Converted from inputs
  //////////////////////////////////////////////////////////////////////////////////////////

  logic                        StallE, StallM, StallW;             // stall signals
  logic                        FlushE, FlushM, FlushW;             // flush signals
  logic                        IntDivE, W64E;                      // Integer division on FPU

  logic [31:0]                 InstrD;                             // instruction

  logic [  XLEN-1:0]           ForwardedSrcAE, ForwardedSrcBE;     // Integer input for convert, move, and int div (from IEU)
  logic [4:0]                  RdE;                                // which FP register to write to (from IEU)
  logic [4:0]                  RdM;                                // which FP register to write to (from IEU)

  logic [4:0]                  RdW;                                // which FP register to write to (from IEU)
  logic [  FLEN-1:0]           ReadDataW;                          // Read data (from LSU)

  logic [2:0]                  Funct3E;

  //////////////////////////////////////////////////////////////////////////////////////////
  // Disable unused options
  //////////////////////////////////////////////////////////////////////////////////////////

  //                 funct5      fmt   src2  src1  RM    dest    OP-FP
  assign InstrD = { Operation, Format, 5'd0, 5'd0, 3'd0, 5'd0, Opcode };

  // Stall decode -> execute stage when busy
  assign StallE = FDivBusyE;
  assign { StallM, StallW }                 = '0;
  assign { FlushE, FlushM, FlushW }         = '0;

  assign { IntDivE, W64E }                  = '0;

  assign { ForwardedSrcAE, ForwardedSrcBE } = '0;
  assign { RdE, RdM, RdW }                  = '0;
  assign ReadDataW                          = '0;

  //////////////////////////////////////////////////////////////////////////////////////////
  // Decode Stage: fctrl decoder, read register file
  //////////////////////////////////////////////////////////////////////////////////////////

  // calculate FP control signals
  fctrl fctrl (.Funct7D(InstrD[31:25]), .OpD(InstrD[6:0]), .Rs2D(InstrD[24:20]), .Funct3D(InstrD[14:12]),
              .IntDivE, .InstrD,
              .StallE, .StallM, .StallW, .FlushE, .FlushM, .FlushW, .FRM_REGW(3'd0), .STATUS_FS(2'b11), .FDivBusyE,
              .reset, .clk, .FRegWriteE, .FRegWriteM, .FRegWriteW, .ZfaE, .ZfaM, .ZfaFRoundNXE, .FrmE, .FrmM, .FmtE, .FmtM,
              .FDivStartE, .IDivStartE, .FWriteIntE, .FCvtIntE, .FWriteIntM, .OpCtrlE, .OpCtrlM, .FpLoadStoreM,
              .IllegalFPUInstrD, .XEnD, .YEnD, .ZEnD, .XEnE, .YEnE, .ZEnE,
              .FResSelE, .FResSelM, .FResSelW, .FPUActiveE, .PostProcSelE, .PostProcSelM, .FCvtIntW,
              .Adr1D, .Adr2D, .Adr3D, .Adr1E, .Adr2E, .Adr3E);

  // FP register file
  // fregfile #(  FLEN) fregfile (.clk, .reset, .we4(FRegWriteW),
  //   .a1(InstrD[19:15]), .a2(InstrD[24:20]), .a3(InstrD[31:27]),
  //   .a4(RdW), .wd4(FResultW),
  //   .rd1(FRD1D), .rd2(FRD2D), .rd3(FRD3D));

  assign FRD1D = A;
  assign FRD2D = B;
  assign FRD3D = '0;

  // D/E pipeline registers
  flopenrc #(  FLEN) DEReg1(clk, reset, FlushE, ~StallE, FRD1D, FRD1E);
  flopenrc #(  FLEN) DEReg2(clk, reset, FlushE, ~StallE, FRD2D, FRD2E);
  flopenrc #(  FLEN) DEReg3(clk, reset, FlushE, ~StallE, FRD3D, FRD3E);

  flopenrc #(     3) DEReg4(clk, reset, FlushE, ~StallE, InstrD[14:12], Funct3E);
  flopenr  #(     1) DEReg5(clk, reset, ~StallE, UpValid, VldE);

  //////////////////////////////////////////////////////////////////////////////////////////
  // Execute Stage: hazards, forwarding, unpacking, execution units
  //////////////////////////////////////////////////////////////////////////////////////////

  // Hazard unit for FPU: determines if any forwarding or stalls are needed
  fhazard fhazard(.Adr1D, .Adr2D, .Adr3D, .Adr1E, .Adr2E, .Adr3E,
    .FRegWriteE, .FRegWriteM, .FRegWriteW, .RdE, .RdM, .RdW, .FResSelM,
    .XEnD, .YEnD, .ZEnD, .FPUStallD, .ForwardXE, .ForwardYE, .ForwardZE);

  // forwarding muxs
  mux3  #(  FLEN)  fxemux (FRD1E, FResultW, PreFpResM, ForwardXE, XE);
  mux3  #(  FLEN)  fyemux (FRD2E, FResultW, PreFpResM, ForwardYE, PreYE);
  mux3  #(  FLEN)  fzemux (FRD3E, FResultW, PreFpResM, ForwardZE, PreZE);

  // Select NAN-boxed value of Y = 1.0 in proper format for fma to add/subtract X*Y+Z
  if(  FPSIZES == 1) assign BoxedOneE = {2'b0, {  NE-1{1'b1}}, (  NF)'(0)};
  else if(  FPSIZES == 2)
      mux2 #(  FLEN) fonemux ({{  FLEN-  LEN1{1'b1}}, 2'b0, {  NE1-1{1'b1}}, (  NF1)'(0)}, {2'b0, {  NE-1{1'b1}}, (  NF)'(0)}, FmtE, BoxedOneE); // NaN boxing zeroes
  else if(  FPSIZES == 3 |   FPSIZES == 4)
      mux4 #(  FLEN) fonemux ({{  FLEN-  S_LEN{1'b1}}, 2'b0, {  S_NE-1{1'b1}}, (  S_NF)'(0)},
                              {{  FLEN-  D_LEN{1'b1}}, 2'b0, {  D_NE-1{1'b1}}, (  D_NF)'(0)},
                              {{  FLEN-  H_LEN{1'b1}}, 2'b0, {  H_NE-1{1'b1}}, (  H_NF)'(0)},
                              {2'b0, {  NE-1{1'b1}}, (  NF)'(0)}, FmtE, BoxedOneE); // NaN boxing zeroes
  assign FmaAddSubE = OpCtrlE[2]&OpCtrlE[1]&(PostProcSelE==2'b10);
  mux2  #(  FLEN)  fyaddmux (PreYE, BoxedOneE, FmaAddSubE, YE); // Force Y to be 1 for add/subtract

  // Select NAN-boxed value of Z = 0.0 in proper format for FMA for multiply X*Y+Z
  // For add and subtract, Z comes from second source operand
  if(  FPSIZES == 1) assign BoxedZeroE = '0;
  else if(  FPSIZES == 2)
    mux2 #(  FLEN) fmulzeromux ({{  FLEN-  LEN1{1'b1}}, {  LEN1{1'b0}}}, (  FLEN)'(0), FmtE, BoxedZeroE); // NaN boxing zeroes
  else if(  FPSIZES == 3 |   FPSIZES == 4)
    mux4 #(  FLEN) fmulzeromux ({{  FLEN-  S_LEN{1'b1}}, {  S_LEN{1'b0}}},
                                {{  FLEN-  D_LEN{1'b1}}, {  D_LEN{1'b0}}},
                                {{  FLEN-  H_LEN{1'b1}}, {  H_LEN{1'b0}}},
                                (  FLEN)'(0), FmtE, BoxedZeroE); // NaN boxing zeroes
  assign FmaZSelE = {OpCtrlE[2]&OpCtrlE[1], OpCtrlE[2]&~OpCtrlE[1]};
  mux3  #(  FLEN)  fzmulmux (PreZE, BoxedZeroE, PreYE, FmaZSelE, ZE);

  // unpack unit: splits FP inputs into their parts and classifies SNaN, NaN, Subnorm, Norm, Zero, Infifnity
  unpack unpack (.X(XE), .Y(YE), .Z(ZE), .Fmt(FmtE), .Xs(XsE), .Ys(YsE), .Zs(ZsE),
    .Xe(XeE), .Ye(YeE), .Ze(ZeE), .Xm(XmE), .Ym(YmE), .Zm(ZmE), .YEn(YEnE), .FPUActive(FPUActiveE),
    .XNaN(XNaNE), .YNaN(YNaNE), .ZNaN(ZNaNE), .XSNaN(XSNaNE), .XEn(XEnE),
    .YSNaN(YSNaNE), .ZSNaN(ZSNaNE), .XSubnorm(XSubnormE),
    .XZero(XZeroE), .YZero(YZeroE), .ZZero(ZZeroE), .XInf(XInfE), .YInf(YInfE),
    .ZEn(ZEnE), .ZInf(ZInfE), .XExpMax(XExpMaxE), .XPostBox(XPostBoxE), .Bias(BiasE), .Nf(NfE));

  // fused multiply add: fadd/sub, fmul, fmadd/fnmadd/fmsub/fnmsub
  fma fma (.Xs(XsE), .Ys(YsE), .Zs(ZsE), .Xe(XeE), .Ye(YeE), .Ze(ZeE), .Xm(XmE), .Ym(YmE), .Zm(ZmE),
    .XZero(XZeroE), .YZero(YZeroE), .ZZero(ZZeroE), .OpCtrl(OpCtrlE),
    .As(AsE), .Ps(PsE), .Ss(SsE), .Se(SeE), .Sm(SmE), .InvA(InvAE), .SCnt(SCntE), .ASticky(FmaAStickyE));

  // divide and square root: fdiv, fsqrt, optionally integer division
  fdivsqrt fdivsqrt(.clk, .reset, .FmtE, .XmE, .YmE, .XeE, .YeE, .SqrtE(OpCtrlE[0]), .SqrtM(OpCtrlM[0]),
    .XInfE, .YInfE, .XZeroE, .YZeroE, .XNaNE, .YNaNE, .BiasE, .NfE, .FDivStartE, .IDivStartE, .XsE,
    .ForwardedSrcAE, .ForwardedSrcBE, .Funct3E, .Funct3M(Funct3E), .IntDivE, .W64E,
    .StallM, .FlushE, .DivStickyM, .FDivBusyE, .IFDivStartE, .FDivDoneE, .UeM,
    .UmM, .FIntDivResultM);

  // compare: fmin/fmax, flt/fle/feq
  fcmp fcmp (.Fmt(FmtE), .OpCtrl(OpCtrlE), .Zfa(ZfaE), .Xs(XsE), .Ys(YsE), .Xe(XeE), .Ye(YeE),
    .Xm(XmE), .Ym(YmE), .XZero(XZeroE), .YZero(YZeroE), .XNaN(XNaNE), .YNaN(YNaNE),
    .XSNaN(XSNaNE), .YSNaN(YSNaNE), .X(XE), .Y(YE), .CmpNV(CmpNVE),
    .CmpFpRes(CmpFpResE), .CmpIntRes(CmpIntResE));

  // sign injection: fsgnj/fsgnjx/fsgnjn
  fsgninj fsgninj(.OpCtrl(OpCtrlE[1:0]), .Xs(XsE), .Ys(YsE), .X(XPostBoxE), .Fmt(FmtE), .SgnRes(SgnResE));

  // classify: fclass
  fclassify fclassify (.Xs(XsE), .XSubnorm(XSubnormE), .XZero(XZeroE), .XNaN(XNaNE),
    .XInf(XInfE), .XSNaN(XSNaNE), .ClassRes(ClassResE));

  // convert: fcvt.*.*
  fcvt fcvt (.Xs(XsE), .Xe(XeE), .Xm(XmE), .Int(ForwardedSrcAE), .OpCtrl(OpCtrlE),
    .ToInt(FWriteIntE), .XZero(XZeroE), .Fmt(FmtE), .Ce(CeE), .ShiftAmt(CvtShiftAmtE),
    .ResSubnormUf(CvtResSubnormUfE), .Cs(CsE), .IntZero(IntZeroE), .LzcIn(CvtLzcInE));

  // ZFA: fround and floating-point load immediate fli
  if (  ZFA_SUPPORTED) begin:Zfa
    logic [4:0] Rs1E;
    logic [1:0] Fmt2E; // Two-bit format field from instruction
    logic [  FLEN-1:0]           FRoundE;                            // Zfa fround output
    logic [  FLEN-1:0]           FliResE;                            // Zfa Floating-point load immediate value

    // fround
    fround fround(.Xs(XsE), .Xe(XeE), .Xm(XmE),
                       .XNaN(XNaNE), .XSNaN(XSNaNE), .Fmt(FmtE), .Frm(FrmE), .Nf(NfE),
                       .ZfaFRoundNX(ZfaFRoundNXE),
                       .FRound(FRoundE), .FRoundNV(FRoundNVE), .FRoundNX(FRoundNXE));

    // fli
    flopenrc #(5) Rs1EReg(clk, reset, FlushE, ~StallE, InstrD[19:15], Rs1E);
    flopenrc #(2) Fmt2EReg(clk, reset, FlushE, ~StallE, InstrD[26:25], Fmt2E);
    fli fli(.Rs1(Rs1E), .Fmt(Fmt2E), .Imm(FliResE));
    mux2  #(  FLEN) ZfaResMux(FRoundE, FliResE, OpCtrlE[0], ZfaResE);
  end else begin
    assign {FRoundNXE, FRoundNVE} = '0;
    assign ZfaResE = 'x;
  end

  // fmv.*.x: NaN Box SrcA to extend integer to requested FP size
  if(  FPSIZES == 1)
    if (  FLEN >=   XLEN) assign PreIntSrcE = {{  FLEN-  XLEN{1'b1}}, ForwardedSrcAE};
    else                  assign PreIntSrcE = ForwardedSrcAE[  FLEN-1:0];
  else if(  FPSIZES == 2)
    if (  FLEN >=   XLEN)
      mux2 #(  FLEN) SrcAMux ({{  FLEN-  LEN1{1'b1}}, ForwardedSrcAE[  LEN1-1:0]}, {{  FLEN-  XLEN{1'b1}}, ForwardedSrcAE}, FmtE, PreIntSrcE);
    else
      mux2 #(  FLEN) SrcAMux ({{  FLEN-  LEN1{1'b1}}, ForwardedSrcAE[  LEN1-1:0]}, ForwardedSrcAE[  FLEN-1:0], FmtE, PreIntSrcE);
  else if(  FPSIZES == 3 |   FPSIZES == 4) begin
    localparam XD_LEN =   D_LEN <   XLEN ?   D_LEN :   XLEN; // shorter of D_LEN and XLEN
    mux3 #(  FLEN) SrcAMux ({{  FLEN-  S_LEN{1'b1}}, ForwardedSrcAE[  S_LEN-1:0]},
                            {{  FLEN-XD_LEN{1'b1}}, ForwardedSrcAE[XD_LEN-1:0]},
                            {{  FLEN-  H_LEN{1'b1}}, ForwardedSrcAE[  H_LEN-1:0]},
                            FmtE, PreIntSrcE); // NaN boxing zeroes
  end
  // fmvp.*.x: Select pair of registers
  if (  ZFA_SUPPORTED & (  FLEN == 2*  XLEN))
       assign IntSrcE = ZfaE ? {ForwardedSrcBE, ForwardedSrcAE} : PreIntSrcE; // choose pair of integer registers for fmvp.d.x / fmvp.q.x
  else assign IntSrcE = PreIntSrcE;

  // select a result that may be written to the FP register
  mux4  #(  FLEN) FResMux(SgnResE, IntSrcE, CmpFpResE, ZfaResE, {OpCtrlE[2], &OpCtrlE[1:0] | (OpCtrlE == 3'b100) & ZfaE}, PreFpResE);
  assign PreNVE = CmpNVE&(OpCtrlE[2]|FWriteIntE) | FRoundNVE & (OpCtrlE == 3'b100) & ZfaE;
  assign PreNXE = FRoundNXE & (OpCtrlE == 3'b100);

  // fmv.x.*: select the result that may be written to the integer register
  if(  FPSIZES == 1) begin
    assign mvsgn = XE[  FLEN-1];
    assign SgnExtXE = XE;
  end else if(  FPSIZES == 2) begin
    mux2 #(1)      sgnmux (XE[  LEN1-1], XE[  FLEN-1],FmtE, mvsgn);
    mux2 #(  FLEN) sgnextmux ({{  FLEN-  LEN1{mvsgn}}, XE[  LEN1-1:0]}, XE, FmtE, SgnExtXE);
  end else if(  FPSIZES == 3 |   FPSIZES == 4) begin
    mux4 #(1)      sgnmux (XE[  S_LEN-1], XE[  D_LEN-1], XE[  H_LEN-1], XE[  LLEN-1], FmtE, mvsgn);
    mux3 #(  FLEN) sgnextmux ({{  FLEN-  S_LEN{mvsgn}}, XE[  S_LEN-1:0]},
                              {{  FLEN-  D_LEN{mvsgn}}, XE[  D_LEN-1:0]},
                              {{  FLEN-  H_LEN{mvsgn}}, XE[  H_LEN-1:0]},
                                FmtE, SgnExtXE); // Q not needed because there is no fmv.x.q
  end

  // sign extend to XLEN if necessary
  if (  FLEN >= 2*  XLEN)
    if (  ZFA_SUPPORTED) assign IntSrcXE = ZfaE ? XE[2*  XLEN-1:  XLEN] : SgnExtXE[  XLEN-1:0]; // either fmvh.x.* or fmv.x.*
    else                                      assign IntSrcXE = SgnExtXE[  XLEN-1:0];
  else
    assign IntSrcXE = {{(  XLEN-  FLEN){mvsgn}}, SgnExtXE};
  mux3 #(  XLEN) IntResMux (ClassResE, IntSrcXE, CmpIntResE, {~FResSelE[1], FResSelE[0]}, FIntResE);

  // E/M pipe registers

  // Need to stall during divsqrt iterations to avoid capturing bad flags from stale forwarded sources
  assign StallUnpackedM = StallM | (FDivBusyE & ~IFDivStartE | FDivDoneE);

  assign VldFmaFDiv = ~(FDivBusyE || FDivDoneE) && VldE;
  flopenr  #(     1) EMFpReg1 (clk, reset, ~StallM, VldFmaFDiv, VldM);

  flopenrc #(  NF+1) EMFpReg2 (clk, reset, FlushM, ~StallM, XmE, XmM);
  flopenrc #(  NF+1) EMFpReg3 (clk, reset, FlushM, ~StallM, YmE, YmM);
  flopenrc #(  FLEN) EMFpReg4 (clk, reset, FlushM, ~StallM, {ZeE,ZmE}, {ZeM,ZmM});
  flopenrc #(  XLEN) EMFpReg6 (clk, reset, FlushM, ~StallM, FIntResE, FIntResM);
  flopenrc #(  FLEN) EMFpReg7 (clk, reset, FlushM, ~StallM, PreFpResE, PreFpResM);
  flopenr #(13) EMFpReg5 (clk, reset, ~StallUnpackedM,
    {XsE, YsE, XZeroE, YZeroE, XInfE, YInfE, ZInfE, XNaNE, YNaNE, ZNaNE, XSNaNE, YSNaNE, ZSNaNE},
    {XsM, YsM, XZeroM, YZeroM, XInfM, YInfM, ZInfM, XNaNM, YNaNM, ZNaNM, XSNaNM, YSNaNM, ZSNaNM});
  flopenrc #(2)  EMRegCmpFlg (clk, reset, FlushM, ~StallM, {PreNVE, PreNXE}, {PreNVM, PreNXM});
  flopenrc #(  FMALEN) EMRegFma2(clk, reset, FlushM, ~StallM, SmE, SmM);
  flopenrc #($clog2(  FMALEN+1)+7+  NE) EMRegFma4(clk, reset, FlushM, ~StallM,
    {FmaAStickyE, InvAE, SCntE, AsE, PsE, SsE, SeE},
    {FmaAStickyM, InvAM, SCntM, AsM, PsM, SsM, SeM});
  flopenrc #(  NE+  LOGCVTLEN+  CVTLEN+4) EMRegCvt(clk, reset, FlushM, ~StallM,
    {CeE, CvtShiftAmtE, CvtResSubnormUfE, CsE, IntZeroE, CvtLzcInE},
    {CeM, CvtShiftAmtM, CvtResSubnormUfM, CsM, IntZeroM, CvtLzcInM});
  flopenrc #(  FLEN) FWriteDataMReg (clk, reset, FlushM, ~StallM, YE, FWriteDataM);

  //////////////////////////////////////////////////////////////////////////////////////////
  // Memory Stage: postprocessor and result muxes
  //////////////////////////////////////////////////////////////////////////////////////////

  postprocess postprocess(.Xs(XsM), .Ys(YsM), .Xm(XmM), .Ym(YmM), .Zm(ZmM), .Frm(FrmM), .Fmt(FmtM),
    .FmaASticky(FmaAStickyM), .XZero(XZeroM), .YZero(YZeroM), .XInf(XInfM), .YInf(YInfM), .DivUm(UmM), .FmaSs(SsM),
    .ZInf(ZInfM), .XNaN(XNaNM), .YNaN(YNaNM), .ZNaN(ZNaNM), .XSNaN(XSNaNM), .YSNaN(YSNaNM), .ZSNaN(ZSNaNM),
    .FmaSm(SmM), .DivUe(UeM), .FmaAs(AsM), .FmaPs(PsM), .OpCtrl(OpCtrlM), .FmaSCnt(SCntM), .FmaSe(SeM),
    .CvtCe(CeM), .CvtResSubnormUf(CvtResSubnormUfM),.CvtShiftAmt(CvtShiftAmtM), .CvtCs(CsM),
    .ToInt(FWriteIntM), .Zfa(ZfaM), .DivSticky(DivStickyM), .CvtLzcIn(CvtLzcInM), .IntZero(IntZeroM),
    .PostProcSel(PostProcSelM), .PostProcRes(PostProcResM), .PostProcFlg(PostProcFlgM), .FCvtIntRes(FCvtIntResM));

  // FPU flag selection - to privileged
  mux2  #(5)       FPUFlgMux({PreNVM, 3'b0, PreNXM}, PostProcFlgM, (FResSelM == 2'b01), SetFflagsM);
  mux2  #(  FLEN)  FPUResMux(PreFpResM, PostProcResM, FResSelM[0], FpResM);

  // M/W pipe registers
  flopenr  #(     1) MWRegVld(clk, reset, ~StallW, FDivDoneE ? VldE : VldM, VldW);

  flopenrc #(  FLEN) MWRegFp(clk, reset, FlushW, ~StallW, FpResM, FpResW);
  flopenrc #(  XLEN) MWRegIntCvtRes(clk, reset, FlushW, ~StallW, FCvtIntResM, FCvtIntResW);
  flopenrc #(  XLEN) MWRegIntDivRes(clk, reset, FlushW, ~StallW, FIntDivResultM, FIntDivResultW);

  //////////////////////////////////////////////////////////////////////////////////////////
  // Writeback Stage: result mux
  //////////////////////////////////////////////////////////////////////////////////////////

  // select the result to be written to the FP register
  mux2  #(  FLEN)  FResultMux (FpResW, ReadDataW, FResSelW[1], FResultW);

  assign Res = FResultW;
  assign DownValid = VldW;

endmodule // fpu
