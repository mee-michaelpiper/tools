class-pool .
*"* class pool for class YCL_SDWS_INTERFACE_SALESORDER

*"* local type definitions
include YCL_SDWS_INTERFACE_SALESORDER=ccdef.

*"* class YCL_SDWS_INTERFACE_SALESORDER definition
*"* public declarations
  include YCL_SDWS_INTERFACE_SALESORDER=cu.
*"* protected declarations
  include YCL_SDWS_INTERFACE_SALESORDER=co.
*"* private declarations
  include YCL_SDWS_INTERFACE_SALESORDER=ci.
endclass. "YCL_SDWS_INTERFACE_SALESORDER definition

*"* macro definitions
include YCL_SDWS_INTERFACE_SALESORDER=ccmac.
*"* local class implementation
include YCL_SDWS_INTERFACE_SALESORDER=ccimp.

*"* test class
include YCL_SDWS_INTERFACE_SALESORDER=ccau.

class YCL_SDWS_INTERFACE_SALESORDER implementation.
*"* method's implementations
  include methods.
endclass. "YCL_SDWS_INTERFACE_SALESORDER implementation

