# PRIVATE_CONFIG_HARDWARE_PLACEHOLDER
# Replace this file with the target machine's CURRENT hardware configuration.
{ ... }: {
  assertions = [ {
    assertion = false;
    message = "Hardware template: import the target machine hardware-configuration.nix into private/ before building.";
  } ];
}
