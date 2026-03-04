// ==UserScript==
// @name           Reddit to Redlib Redirect
// @description    Redirect reddit.com pages to redlib
// @include        main
// ==/UserScript==

(function () {
  if (window.__redditToRedlibLoaded) {
    return;
  }
  window.__redditToRedlibLoaded = true;

  const REDLIB_HOST = "redlib.kylrth.com";
  const OBSERVER_TOPIC = "http-on-modify-request";

  const getServices = () => {
    try {
      if (typeof Services !== "undefined") {
        return Services;
      }
    } catch {}
    try {
      if (typeof ChromeUtils !== "undefined" && typeof ChromeUtils.importESModule === "function") {
        return ChromeUtils.importESModule("resource://gre/modules/Services.sys.mjs").Services;
      }
    } catch {}
    return null;
  };

  const services = getServices();
  const nsIHttpChannel = (() => {
    try {
      if (typeof Ci !== "undefined" && Ci.nsIHttpChannel) {
        return Ci.nsIHttpChannel;
      }
    } catch {}
    try {
      if (typeof Components !== "undefined" && Components.interfaces?.nsIHttpChannel) {
        return Components.interfaces.nsIHttpChannel;
      }
    } catch {}
    return null;
  })();

  const toRedlibUrl = (spec) => {
    if (!spec) {
      return null;
    }

    let url;
    try {
      url = new URL(spec);
    } catch {
      return null;
    }

    const host = url.hostname.toLowerCase();
    if (host !== "reddit.com" && !host.endsWith(".reddit.com")) {
      return null;
    }

    url.protocol = "https:";
    url.hostname = REDLIB_HOST;
    url.port = "";
    return url.toString();
  };

  const newUri = (spec) => {
    try {
      if (services?.io?.newURI) {
        return services.io.newURI(spec);
      }
    } catch {}
    return null;
  };

  const requestObserver = {
    observe(subject, topic) {
      if (topic !== OBSERVER_TOPIC) {
        return;
      }

      let channel;
      try {
        if (!nsIHttpChannel) {
          return;
        }
        channel = subject.QueryInterface(nsIHttpChannel);
      } catch {
        return;
      }

      const currentSpec = channel?.URI?.spec || "";
      const destination = toRedlibUrl(currentSpec);
      if (!destination || destination === currentSpec) {
        return;
      }

      try {
        if (typeof channel.redirectTo === "function") {
          const uri = newUri(destination);
          if (uri) {
            channel.redirectTo(uri);
          }
        }
      } catch {}
    },
  };

  const redirectBrowser = (browser, currentSpec) => {
    if (!browser || typeof browser.loadURI !== "function") {
      return;
    }

    const destination = toRedlibUrl(currentSpec);
    if (!destination || destination === currentSpec) {
      return;
    }

    try {
      browser.loadURI(destination, {
        triggeringPrincipal: services?.scriptSecurityManager?.getSystemPrincipal?.(),
      });
    } catch {}
  };

  const progressListener = {
    onLocationChange(browser, _webProgress, _request, location) {
      redirectBrowser(browser, location?.spec || "");
    },
    onStateChange() {},
    onProgressChange() {},
    onStatusChange() {},
    onSecurityChange() {},
    onContentBlockingEvent() {},
  };

  if (window.gBrowser && typeof window.gBrowser.addTabsProgressListener === "function") {
    window.gBrowser.addTabsProgressListener(progressListener);
  }

  try {
    services?.obs?.addObserver?.(requestObserver, OBSERVER_TOPIC);
  } catch {}

  window.addEventListener(
    "unload",
    () => {
      try {
        window.gBrowser?.removeTabsProgressListener?.(progressListener);
      } catch {}
      try {
        services?.obs?.removeObserver?.(requestObserver, OBSERVER_TOPIC);
      } catch {}
    },
    { once: true }
  );

  const selectedSpec = window.gBrowser?.selectedBrowser?.currentURI?.spec || "";
  redirectBrowser(window.gBrowser?.selectedBrowser, selectedSpec);
})();
