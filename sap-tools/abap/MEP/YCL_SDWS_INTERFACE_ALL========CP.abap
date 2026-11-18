class-pool .
*"* class pool for class YCL_SDWS_INTERFACE_ALL

*"* local type definitions
include YCL_SDWS_INTERFACE_ALL========ccdef.

*"* class YCL_SDWS_INTERFACE_ALL definition
*"* public declarations
  include YCL_SDWS_INTERFACE_ALL========cu.
*"* protected declarations
  include YCL_SDWS_INTERFACE_ALL========co.
*"* private declarations
  include YCL_SDWS_INTERFACE_ALL========ci.
endclass. "YCL_SDWS_INTERFACE_ALL definition

*"* macro definitions
include YCL_SDWS_INTERFACE_ALL========ccmac.
*"* local class implementation
include YCL_SDWS_INTERFACE_ALL========ccimp.

*"* test class
include YCL_SDWS_INTERFACE_ALL========ccau.

class YCL_SDWS_INTERFACE_ALL implementation.
*"* method's implementations
  include methods.
endclass. "YCL_SDWS_INTERFACE_ALL implementation

