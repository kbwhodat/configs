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

  const REDLIB_HOST = "redlib.catsarch.com/";
  const REDLIB_SETTINGS_PATH = "/settings";
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

  // Check if URL is redlib settings page
  const isRedlibSettings = (spec) => {
    if (!spec) return false;
    try {
      const url = new URL(spec);
      return url.hostname === REDLIB_HOST && url.pathname.startsWith(REDLIB_SETTINGS_PATH);
    } catch {
      return false;
    }
  };

  // Get redlib home URL
  const getRedlibHome = () => `https://${REDLIB_HOST}/`;

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

      // Block redlib settings page - redirect to home
      if (isRedlibSettings(currentSpec)) {
        try {
          if (typeof channel.redirectTo === "function") {
            const uri = newUri(getRedlibHome());
            if (uri) {
              channel.redirectTo(uri);
            }
          }
        } catch {}
        return;
      }

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

    // Block redlib settings page - redirect to home
    if (isRedlibSettings(currentSpec)) {
      try {
        browser.loadURI(getRedlibHome(), {
          triggeringPrincipal: services?.scriptSecurityManager?.getSystemPrincipal?.(),
        });
      } catch {}
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

  // Inject CSS to hide settings UI on redlib pages
  const SETTINGS_HIDE_CSS = `
    a[href="/settings"],
    a[href^="/settings?"],
    a[href^="/settings/"],
    button[aria-label="settings" i],
    a:is([href="/settings"]) {
      display: none !important;
      visibility: hidden !important;
      pointer-events: none !important;
    }
  `;

  const injectSettingsBlocker = (browser) => {
    if (!browser) return;

    try {
      const uri = browser.currentURI;
      if (!uri || uri.host !== REDLIB_HOST) return;

      // Use actor/content script messaging for modern Firefox
      const mm = browser.messageManager;
      if (mm && typeof mm.loadFrameScript === "function") {
        const script = `
          (function() {
            if (content.document.__redlibSettingsHidden) return;
            content.document.__redlibSettingsHidden = true;

            const style = content.document.createElement("style");
            style.textContent = ${JSON.stringify(SETTINGS_HIDE_CSS)};
            content.document.documentElement.appendChild(style);

            // Also hide via JS for dynamic content
            const hide = () => {
              const links = content.document.querySelectorAll('a[href="/settings"], a[href^="/settings?"], a[href^="/settings/"]');
              links.forEach(el => {
                el.style.setProperty("display", "none", "important");
              });
            };
            hide();
            new content.MutationObserver(hide).observe(content.document.documentElement, {childList: true, subtree: true});
          })();
        `;
        mm.loadFrameScript("data:application/javascript," + encodeURIComponent(script), false);
      }
    } catch (e) {
      // Fallback: try insertCSS if available
      try {
        browser.ownerGlobal?.gBrowser?.insertCSS?.(browser, {
          code: SETTINGS_HIDE_CSS,
          cssOrigin: "user",
        });
      } catch {}
    }
  };

  const progressListener = {
    onLocationChange(browser, _webProgress, _request, location) {
      const spec = location?.spec || "";
      redirectBrowser(browser, spec);

      // Inject settings blocker on redlib pages
      if (location?.host === REDLIB_HOST) {
        setTimeout(() => injectSettingsBlocker(browser), 100);
      }
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

  const selectedBrowser = window.gBrowser?.selectedBrowser;
  const selectedSpec = selectedBrowser?.currentURI?.spec || "";
  redirectBrowser(selectedBrowser, selectedSpec);

  // Inject settings blocker on current tab if on redlib
  if (selectedBrowser?.currentURI?.host === REDLIB_HOST) {
    setTimeout(() => injectSettingsBlocker(selectedBrowser), 100);
  }
})();
