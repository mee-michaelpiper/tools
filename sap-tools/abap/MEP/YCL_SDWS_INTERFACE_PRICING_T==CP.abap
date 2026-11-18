class-pool .
*"* class pool for class YCL_SDWS_INTERFACE_PRICING_T

*"* local type definitions
include YCL_SDWS_INTERFACE_PRICING_T==ccdef.

*"* class YCL_SDWS_INTERFACE_PRICING_T definition
*"* public declarations
  include YCL_SDWS_INTERFACE_PRICING_T==cu.
*"* protected declarations
  include YCL_SDWS_INTERFACE_PRICING_T==co.
*"* private declarations
  include YCL_SDWS_INTERFACE_PRICING_T==ci.
endclass. "YCL_SDWS_INTERFACE_PRICING_T definition

*"* macro definitions
include YCL_SDWS_INTERFACE_PRICING_T==ccmac.
*"* local class implementation
include YCL_SDWS_INTERFACE_PRICING_T==ccimp.

*"* test class
include YCL_SDWS_INTERFACE_PRICING_T==ccau.

class YCL_SDWS_INTERFACE_PRICING_T implementation.
*"* method's implementations
  include methods.
endclass. "YCL_SDWS_INTERFACE_PRICING_T implementation

