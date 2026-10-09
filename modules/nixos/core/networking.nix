{ ... }:

{
  networking.hostName = "virtM";
  networking.networkmanager.enable = true;

  services.openssh.enable = true;
}
