{ pkgs ? import <nixpkgs> {}, config, ... }:

with pkgs.lib;
with import ./erlexpr.nix;

/*
  Missing modules from Ejabberd:

  mod_announce            Manage announcements
                          DEPENDS: recommends mod_adhoc
  mod_blocking            Simple Communications Blocking (XEP-0191)
                          DEPENDS: mod_privacy
  mod_caps                Entity Capabilities (XEP-0115)
  mod_configure           Server configuration using Ad-Hoc
                          DEPENDS: mod_adhoc
  mod_echo                Echoes XMPP stanzas
  mod_http_fileserver     Small HTTP file server
  mod_irc                 IRC transport
  mod_offline_odbc        Offline message storage (XEP-0160)
                          DEPENDS: ODBC...
  mod_proxy65             SOCKS5 Bytestreams (XEP-0065)
  mod_pubsub              Pub-Sub (XEP-0060), PEP (XEP-0163)
                          DEPENDS: mod_caps
  mod_pubsub_odbc         Pub-Sub (XEP-0060), PEP (XEP-0163)
                          DEPENDS: supported DB (*) and mod_caps
  mod_register_web        Web for Account Registrations
  mod_service_log         Copy user messages to logger service
  mod_shared_roster       Shared roster management
                          DEPENDS: mod_roster or mod_roster_odbc
  mod_shared_roster_ldap  LDAP Shared roster management
                          DEPENDS: mod_roster or mod_roster_odbc
  mod_stats               Statistics Gathering (XEP-0039)
  mod_time                Entity Time (XEP-0202)
  mod_vcard_ldap          vcard-temp (XEP-0054)
                          DEPENDS: LDAP server
  mod_vcard_xupdate       vCard-Based Avatars (XEP-0153)
                          DEPENDS: mod_vcard or mod_vcard_odbc
  mod_version             Software Version (XEP-0092)
*/

let
  mkModuleEx = { description, deps ? [], odbc ? false }: {
    enable = mkEnableOption "Module for ${description}";
    options = mkOption {
      default = {};
      type = types.unspecified;
      description = ''
        Options for module ... TODO
      '';
    };
  };

  mkModule = description: mkModuleEx { inherit description; };
  mkModuleDeps = deps: description: mkModuleEx { inherit deps description; };
  mkModuleDep = dep: mkModuleDeps (singleton dep);
  mkModuleODBC = description: mkModuleEx { inherit description; odbc = true; };

  modules = {
    adhoc = mkModule "Ad-Hoc Commands (XEP-0050)";
    admin_extra = mkModule "Administrative functions and commands";
    bosh = mkModule "XMPP over Bosh service (HTTP Binding)";
    disco = mkModule "Service Discovery (XEP-0030)";
    last = mkModuleODBC "Last Activity (XEP-0012)";
    metrics = mkModule "MongooseIM metrics";
    muc = mkModule "Multi-User Chat (XEP-0045)";
    muc_log = mkModuleDep "mod_muc" "Multi-User Chat room logging";
    offline = mkModule "Offline message storage (XEP-0160)";
    ping = mkModule "XMPP Ping and periodic keepalives (XEP-0199)";
    privacy = mkModuleODBC "Blocking Communication (XEP-0016)";
    private = mkModuleODBC "Private XML Storage (XEP-0049";
    register = mkModule "In-Band Registration (XEP-0077)";
    roster = mkModuleODBC "Roster management (XMPP IM)";
    sic = mkModule "Server IP Check (XEP-0279)";
    snmp = mkModule "SNMP support";
    vcard = mkModuleODBC "vcard-temp (XEP-0054)";
    websockets = mkModule "Websocket support";
  };
in {
  options = modules // {
    generatedConfig = mkOption {
      type = types.lines;
      default = "";
      internal = true;
      description = "Generated configuration values";
    };
  };

  config.generatedConfig = let
    justModules = removeAttrs config [ "generatedConfig" ];
    enabled = filterAttrs (name: mod: mod.enable) justModules;
    mkMod = name: cfg: "{mod_${name}, ${erlPropList cfg.options}}";
  in concatStringsSep ",\n  " (mapAttrsToList mkMod enabled);
}
