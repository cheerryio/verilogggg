`include "nps6_ivca.sv"
`include "nps6_ipa.sv"

class nps6_class;

int VERBOSITY_EN;
nps6_reg_class u_nps_reg;

nps_ivca u_nps_ivca[`NOC_NPS6_NUM_PORT];
nps_ipa u_nps_ipa[`NOC_NPS6_NUM_PORT];

int PORT_MAP [`NOC_NPS6_NUM_PORT][`NOC_NPS6_NUM_PORT] = '{'{'d0, 'd0, 'd1, 'd2, 'd3, 'd4}, 
                                                          '{'d3, 'd0, 'd0, 'd0, 'd1, 'd2},
                                                          '{'d2, 'd0, 'd0, 'd3, 'd0, 'd1},
                                                          '{'d1, 'd2, 'd3, 'd0, 'd4, 'd0},
                                                          '{'d0, 'd1, 'd2, 'd3, 'd0, 'd0},
                                                          '{'d3, 'd0, 'd1, 'd2, 'd0, 'd0}};   // Port to arbitration index Mapping
int PORT_UNMAP [`NOC_NPS6_NUM_PORT][`NOC_NPS6_NUM_PORT-1] = '{'{'d1, 'd2, 'd3, 'd4, 'd5},
                                                              '{'d3, 'd4, 'd5, 'd0, 'd0},
                                                              '{'d4, 'd5, 'd0, 'd3, 'd0},
                                                              '{'d5, 'd0, 'd1, 'd2, 'd4},
                                                              '{'d0, 'd1, 'd2, 'd3, 'd0},
                                                              '{'d1, 'd2, 'd3, 'd0, 'd0}};    // arbitration output index to Port Mapping

function new(int verbosity_en, int vc_fifo_depth[`NOC_NPS6_NUM_PORT][`NOC_NPS_NUM_VC], ref nps6_reg_class inst_nps_reg);
  VERBOSITY_EN = verbosity_en;
   this.u_nps_reg = inst_nps_reg;
  for(int i=0;i<`NOC_NPS6_NUM_PORT;i++) begin
    u_nps_ivca[i] = new(u_nps_reg, verbosity_en, i, vc_fifo_depth[i]);
    u_nps_ipa[i]  = new(u_nps_reg, verbosity_en, i, PORT_MAP[i], PORT_UNMAP[i]);
  end  
  //connect 
  for(int i=0;i<`NOC_NPS6_NUM_PORT;i++) begin
    for(int j=0;j<`NOC_NPS6_NUM_PORT;j++) begin
      u_nps_ivca[i].p_nps_ipa[j] = u_nps_ipa[j];
      u_nps_ipa[i].p_nps_ivca[j] = u_nps_ivca[j];
    end  
  end  
endfunction


function void update(input bit [`NOC_NPS_NUM_VC-1:0] valid_in[`NOC_NPS6_NUM_PORT], bit [`NOC_NPP_WIDTH-1:0] flit_in[`NOC_NPS6_NUM_PORT], bit [`NOC_NPS_NUM_VC-1:0] credit_received[`NOC_NPS6_NUM_PORT], bit credit_rdy_in[`NOC_NPS6_NUM_PORT], output bit [`NOC_NPS_NUM_VC-1:0] valid_out[`NOC_NPS6_NUM_PORT], bit [`NOC_NPP_WIDTH-1:0] flit_out[`NOC_NPS6_NUM_PORT], bit flit_out_en [`NOC_NPS6_NUM_PORT], bit [`NOC_NPS_NUM_VC-1:0] credit_to_send[`NOC_NPS6_NUM_PORT], bit credit_rdy_out[`NOC_NPS6_NUM_PORT]);

  //copy input flit and send requestors to ipa
  for(int p=0;p<`NOC_NPS6_NUM_PORT;p++) begin
    if(valid_in[p] != 0) begin 
      u_nps_ivca[p].copy_input_flit(valid_in[p],flit_in[p]);
      `PRINT_NPS6_MODEL(VERBOSITY_EN,$sformatf("Calling ivca[%0d].copy_input_flit\n",p),DBG)
    end
    u_nps_ivca[p].update();
    //`PRINT_NPS6_MODEL(VERBOSITY_EN,$sformatf("Calling ivca[%0d].update\n",p),DBG)
  end  
  //update ipa block to do inport arbitration and get a winner for every outport 
  for(int p=0;p<`NOC_NPS6_NUM_PORT;p++) begin
    if(credit_received[p] != 0) begin
      u_nps_ipa[p].receive_credit(credit_received[p]);
      `PRINT_NPS6_MODEL(VERBOSITY_EN,$sformatf("Calling ipa[%0d].receive_credit\n",p),DBG)
    end
    u_nps_ipa[p].update();
   // `PRINT_NPS6_MODEL(VERBOSITY_EN,$sformatf("Calling ipa[%0d].update\n",p),DBG)
  end   
  //update outputs
  for(int p=0;p<`NOC_NPS6_NUM_PORT;p++) begin
    valid_out[p] = u_nps_ipa[p].winner_npp_valid;
    flit_out[p] = u_nps_ipa[p].winner_npp_flit;
    flit_out_en[p] = u_nps_ipa[p].winner_npp_flit_en;
    credit_rdy_out[p] = 1;
    if(credit_rdy_in[p]) begin 
      credit_to_send[p] = u_nps_ivca[p].send_credit();
     // `PRINT_NPS6_MODEL(VERBOSITY_EN,$sformatf("Calling ivca[%0d].send_credit\n",p),DBG)
    end
  end  
endfunction

endclass
