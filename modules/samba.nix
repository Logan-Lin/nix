{ config, pkgs, lib, ... }:

{
  # Enable Samba service
  services.samba = {
    enable = true;
    
    # Enable SMB protocol versions
    package = pkgs.samba4Full;
    
    # Modern Samba configuration using settings
    settings = {
      global = {
        # Server identification
        workgroup = "WORKGROUP";
        "server string" = "hs NAS Server";
        
        # Security settings
        security = "user";
        "map to guest" = "never";
        
        # Performance optimizations
        "socket options" = "TCP_NODELAY IPTOS_LOWDELAY SO_RCVBUF=524288 SO_SNDBUF=524288";
        deadtime = "30";
        "use sendfile" = "yes";
        
        # Logging
        "log file" = "/var/log/samba/log.%m";
        "max log size" = "1000";
        "log level" = "0";
        
        # Disable printer sharing
        "load printers" = "no";
        printing = "bsd";
        "printcap name" = "/dev/null";
        "disable spoolss" = "yes";
      };
      
      # Define shares
      Media = {
        path = "/mnt/storage/Media";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "yanlin";
        "force group" = "users";
        "valid users" = "yanlin";
        comment = "Media Storage";
      };
    };
  };
  
  # Enable SMB discovery
  services.samba-wsdd = {
    enable = true;
    openFirewall = false; # Keep firewall closed as requested
  };
  
  # Configure SMB users - requires manual setup after deployment
  # Run: sudo smbpasswd -a yanlin
}
