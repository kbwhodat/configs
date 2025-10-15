{ pkgs, ... }:

{
  programs.thunderbird = {
    enable = false;
    profiles.default = {
      isDefault = true;
      accountsOrder = ["yahoo"];
      settings = { 
       "toolkit.telemetry.enabled" = false;
        "toolkit.telemetry.unified" = false;
        "datareporting.healthreport.uploadEnabled" = false;
        "datareporting.policy.dataSubmissionEnabled" = false;
        "browser.newtabpage.enabled" = false;
        "app.shield.optoutstudies.enabled" = false;
        "app.update.auto" = false;
        "mailnews.start_page.enabled" = false;                
        "mailnews.message_display.disable_remote_image" = true;
        "mail.phishing.detection.enabled" = true;            
        "mail.phishing.detection.ipaddresses" = true;       
        "mail.phishing.detection.mismatched_hosts" = true; 
        "mail.server.default.login_at_startup" = false;   
        "mail.server.default.check_all_folders_for_new" = false; 
        "mailnews.send_default_charset" = "UTF-8";          
        "mailnews.display.original_date" = true;    
        "extensions.activeThemeID" = "thunderbird-compact-dark@mozilla.org";
      };
    };
    profiles.gmail = {
      isDefault = false;
      accountsOrder = ["gmail"];
      settings = { 
        "toolkit.telemetry.enabled" = false;
        "toolkit.telemetry.unified" = false;
        "datareporting.healthreport.uploadEnabled" = false;
        "datareporting.policy.dataSubmissionEnabled" = false;
        "browser.newtabpage.enabled" = false;
        "app.shield.optoutstudies.enabled" = false;
        "app.update.auto" = false;
        "mailnews.start_page.enabled" = false;                
        "mailnews.message_display.disable_remote_image" = true;
        "mail.phishing.detection.enabled" = true;            
        "mail.phishing.detection.ipaddresses" = true;       
        "mail.phishing.detection.mismatched_hosts" = true; 
        "mail.server.default.login_at_startup" = false;   
        "mail.server.default.check_all_folders_for_new" = false; 
        "mailnews.send_default_charset" = "UTF-8";          
        "mailnews.display.original_date" = true;    
        "extensions.activeThemeID" = "thunderbird-compact-dark@mozilla.org";
      };
    };
  };

  accounts.email = {
    accounts."yahoo" = {
      primary = true;
      realName = "kb";
      address = "byantalok@yahoo.com";
      thunderbird.enable = true;
      thunderbird.profiles = [ "default" ];
    };
    accounts."gmail" = {
      primary = false;
      realName = "kb";
      address = "wbtankeye@gmail.com";
      thunderbird.enable = true;
      thunderbird.profiles = [ "gmail" ];
    };
  };
}
