`ifndef CPM_PKG_SV
`define CPM_PKG_SV
`include "cpm_dma_defines.vh"

package cpm_wrapper_v1_1_0_pkg;
`include "cpm_dma_reg.svh"
`include "cpm_pcie_dma_attr_defines.svh"

`include "cpm_mdma_defines.svh"
`include "cpm_mdma_reg.svh"
`include "cpm_dma_defines.svh"
`include "cpm_dma_debug_defines.svh"

`include "cpm_dma_pcie_xdma_fab.svh"
`include "cpm_dma_pcie_mdma_fab.svh"
endpackage

`endif