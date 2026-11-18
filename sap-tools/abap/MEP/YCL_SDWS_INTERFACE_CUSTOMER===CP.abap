class-pool .
*"* class pool for class YCL_SDWS_INTERFACE_CUSTOMER

*"* local type definitions
include YCL_SDWS_INTERFACE_CUSTOMER===ccdef.

*"* class YCL_SDWS_INTERFACE_CUSTOMER definition
*"* public declarations
  include YCL_SDWS_INTERFACE_CUSTOMER===cu.
*"* protected declarations
  include YCL_SDWS_INTERFACE_CUSTOMER===co.
*"* private declarations
  include YCL_SDWS_INTERFACE_CUSTOMER===ci.
endclass. "YCL_SDWS_INTERFACE_CUSTOMER definition

*"* macro definitions
include YCL_SDWS_INTERFACE_CUSTOMER===ccmac.
*"* local class implementation
include YCL_SDWS_INTERFACE_CUSTOMER===ccimp.

*"* test class
include YCL_SDWS_INTERFACE_CUSTOMER===ccau.

class YCL_SDWS_INTERFACE_CUSTOMER implementation.
*"* method's implementations
  include methods.
endclass. "YCL_SDWS_INTERFACE_CUSTOMER implementation

