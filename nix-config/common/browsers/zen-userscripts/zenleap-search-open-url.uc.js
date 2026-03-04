// ==UserScript==
// @name           ZenLeap Search Open URL
// @description    In ZenLeap tab search, Enter opens typed URL when no tab matches
// @include        main
// ==/UserScript==

(function () {
  if (window.__zenleapSearchOpenUrlLoaded) {
    return;
  }
  window.__zenleapSearchOpenUrlLoaded = true;

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

  const hasScheme = (value) => /^[a-zA-Z][a-zA-Z0-9+.-]*:/.test(value);

  const isIpv4 = (value) => /^(\d{1,3}\.){3}\d{1,3}(?::\d+)?(\/.*)?$/.test(value);

  const isUrlLike = (value) => {
    if (!value) return false;
    if (hasScheme(value)) return true;
    if (value.startsWith("localhost")) return true;
    if (isIpv4(value)) return true;
    if (value.includes(".")) return true;
    return false;
  };

  const toNavigableUrl = (value) => {
    const trimmed = (value || "").trim();
    if (!trimmed) return null;
    return hasScheme(trimmed) ? trimmed : `https://${trimmed}`;
  };

  const openUrl = (url, inNewTab = false) => {
    try {
      if (!url) {
        return false;
      }

      const where = inNewTab ? "tab" : "current";

      if (typeof window.openTrustedLinkIn === "function") {
        const principal = services?.scriptSecurityManager?.getSystemPrincipal?.();
        window.openTrustedLinkIn(url, where, {
          triggeringPrincipal: principal,
        });
        return true;
      }

      if (!window.gBrowser?.selectedBrowser?.loadURI || !services?.io?.newURI) {
        return false;
      }
      const uri = services.io.newURI(url);
      const principal = services?.scriptSecurityManager?.getSystemPrincipal?.();

      window.gBrowser.selectedBrowser.loadURI(uri, {
        triggeringPrincipal: principal,
      });
      return true;
    } catch {
      return false;
    }
  };

  const getSearchUrl = (query) => {
    try {
      const engine = services?.search?.defaultEngine || services?.search?.defaultPrivateEngine;
      const submission = engine?.getSubmission?.(query, null, "searchbar");
      const spec = submission?.uri?.spec;
      if (spec) {
        return spec;
      }
    } catch {}

    return `https://duckduckgo.com/?q=${encodeURIComponent(query)}`;
  };

  const openSearchQuery = (query, inNewTab = false) => {
    try {
      if (typeof window.openTrustedLinkIn === "function") {
        const principal = services?.scriptSecurityManager?.getSystemPrincipal?.();
        window.openTrustedLinkIn(query, inNewTab ? "tab" : "current", {
          allowThirdPartyFixup: true,
          triggeringPrincipal: principal,
        });
        return true;
      }
    } catch {}

    return openUrl(getSearchUrl(query), inNewTab);
  };

  const closeSearchPrompt = () => {
    // Let ZenLeap close itself via its normal Escape path so internal
    // searchMode state is reset correctly.
    const sendEscape = () => {
      try {
        window.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape", bubbles: true, cancelable: true }));
      } catch {}
    };

    sendEscape();

    // In Vim insert mode, first Escape switches to normal mode.
    // If the prompt is still visible, send a second Escape to fully close.
    setTimeout(() => {
      const modal = document.getElementById("zenleap-search-modal");
      if (modal && modal.classList.contains("active")) {
        sendEscape();
      }
    }, 10);
  };

  window.addEventListener(
    "keydown",
    (event) => {
      if (event.key !== "Enter" || event.altKey) {
        return;
      }

      const inNewTab = event.shiftKey;

      const modal = document.getElementById("zenleap-search-modal");
      if (!modal || !modal.classList.contains("active")) {
        return;
      }

      const icon = document.getElementById("zenleap-search-icon");
      if (icon && icon.textContent === ">") {
        return;
      }

      const hasResults = !!document.querySelector("#zenleap-search-results .zenleap-search-result");
      if (hasResults) {
        return;
      }

      const input = document.getElementById("zenleap-search-input");
      const rawValue = (input && "value" in input) ? input.value : "";
      const typed = (rawValue || "").trim();

      if (!typed) {
        return;
      }

      event.preventDefault();
      event.stopPropagation();

      closeSearchPrompt();
      setTimeout(() => {
        if (isUrlLike(typed)) {
          const target = toNavigableUrl(typed);
          if (target) {
            openUrl(target, inNewTab);
          }
          return;
        }

        openSearchQuery(typed, inNewTab);
      }, 0);
    },
    true
  );
})();
