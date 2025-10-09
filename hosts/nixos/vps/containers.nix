{ config, pkgs, lib, ... }:

let
  # Universal container configuration
  commonUID = "1000";
  commonGID = "100";
  systemTZ = config.time.timeZone;
in
{
  # Container definitions for vps host
  virtualisation.oci-containers.containers = {
    # Static web server for homepage
    homepage = {
      image = "docker.io/nginx:alpine";
      
      volumes = [
        "/home/yanlin/www/homepage:/usr/share/nginx/html:ro"
        "/home/yanlin/www/homepage-nginx.conf:/etc/nginx/conf.d/default.conf:ro"
      ];

      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.homepage.rule" = "Host(`www.yanlincs.com`)";
        "traefik.http.routers.homepage.entrypoints" = "websecure";
        "traefik.http.routers.homepage.tls" = "true";
        "traefik.http.routers.homepage.tls.certresolver" = "cloudflare";
        "traefik.http.routers.homepage.tls.domains[0].main" = "yanlincs.com";
        "traefik.http.routers.homepage.tls.domains[0].sans[0]" = "*.yanlincs.com";
        "traefik.http.services.homepage.loadbalancer.server.port" = "80";
      };
      
      extraOptions = [
        "--network=podman"
      ];
      
      autoStart = true;
    };

    # Static web server for blog
    blog = {
      image = "docker.io/nginx:alpine";
      
      volumes = [
        "/home/yanlin/www/blog:/usr/share/nginx/html:ro"
        "/home/yanlin/www/blog-nginx.conf:/etc/nginx/conf.d/default.conf:ro"
      ];

      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.blog.rule" = "Host(`blog.yanlincs.com`)";
        "traefik.http.routers.blog.entrypoints" = "websecure";
        "traefik.http.routers.blog.tls" = "true";
        "traefik.http.routers.blog.tls.certresolver" = "cloudflare";
        "traefik.http.routers.blog.tls.domains[0].main" = "*.yanlincs.com";
        "traefik.http.services.blog.loadbalancer.server.port" = "80";
      };
      
      extraOptions = [
        "--network=podman"
      ];
      
      autoStart = true;
    };

    # OC Backend Scheduler
    oc-scheduler = {
      image = "localhost/oc-scheduler:v1";

      extraOptions = [
        "--network=podman"
        "--security-opt=no-new-privileges:true"
      ];
      
      autoStart = true;
    };
  };
}
