`timescale 1ns/1ps
/* Generated vectors are supplied by verify_dw2_firmware.py under /tmp.
 * Compile only this bench and the unchanged DW and quantizer accelerators.
 */
module tb_dw2_mapping;
 reg clk=0,resetn=0,we=0,qwe=0;
 reg [5:0] addr=0;reg [3:0] qaddr=0;
 reg [31:0] wdata=0,qwdata=0;wire [31:0] rdata,qrdata;
 reg [31:0] vec[0:69311];reg [31:0] qvec[0:1023];
 string dwfile,qfile;
 integer v,i,p,index;
 my_dw_conv_accel dut(clk,resetn,addr,we,wdata,rdata);
 my_quant_accel quant(clk,resetn,qaddr,qwe,qwdata,qrdata);
 always #5 clk=~clk;
 task wr(input [5:0] a,input [31:0] d);
 begin @(negedge clk);addr=a;wdata=d;we=1;@(negedge clk);we=0;end endtask
 task qwr(input [3:0] a,input [31:0] d);
 begin @(negedge clk);qaddr=a;qwdata=d;qwe=1;@(negedge clk);qwe=0;end endtask
 initial begin
  if(!$value$plusargs("DW_VECTORS=%s",dwfile))$fatal(1,"missing DW_VECTORS");
  if(!$value$plusargs("QUANT_VECTORS=%s",qfile))$fatal(1,"missing QUANT_VECTORS");
  $readmemh(dwfile,vec);$readmemh(qfile,qvec);
  repeat(2) @(negedge clk);resetn=1;
  for(v=0;v<1824;v=v+1)begin
   p=v*38;for(i=0;i<9;i=i+1)wr(28+i,vec[p+i]);
   for(i=0;i<25;i=i+1)wr(i,vec[p+9+i]);wr(60,1);
   for(i=0;i<4;i=i+1)begin
    index=(i/2)*6+(i%2)*2;addr=40+index;#1;
    if(rdata!==vec[p+34+i])$fatal(1,"DW vector %0d corner %0d got %h expected %h",v,index,rdata,vec[p+34+i]);
   end
  end
  $display("[PASS] unchanged DW RTL: 1568 actual patches + 256 edge/wrap patches");
  for(v=0;v<256;v=v+1)begin
   p=v*4;qwr(0,qvec[p]);qwr(1,qvec[p+1]);qwr(2,qvec[p+2]);qwr(4,1);qaddr=3;#1;
   if(qrdata!==qvec[p+3])$fatal(1,"quant vector %0d got %h expected %h",v,qrdata,qvec[p+3]);
  end
  $display("[PASS] unchanged quantizer RTL: 256 reference vectors");$finish;
 end
endmodule
