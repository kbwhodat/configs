// Hotkeys:
// - Ctrl+Shift+U: exit split view
// - Ctrl+Shift+S: start split target selection mode (no popup)
//   - j/k or arrows: cycle target tabs
//   - Enter: split with selected tab
//   - Esc: cancel and return to origin tab
//   - s: open searchable picker UI
(function () {
  if (window.__zenleapSplitPickerLoaded) {
    return;
  }
  window.__zenleapSplitPickerLoaded = true;

  const STYLE_ID = "zenleap-split-picker-style";

  let picker = null;

  function isEditableTarget(target) {
    if (!target || !(target instanceof Element)) {
      return false;
    }
    if (target.closest("input, textarea, select")) {
      return true;
    }
    return !!target.closest("[contenteditable=''], [contenteditable='true']");
  }

  function fuzzyMatch(text, query) {
    const q = (query || "").trim().toLowerCase();
    if (!q) {
      return true;
    }

    const s = (text || "").toLowerCase();
    let qi = 0;
    for (let i = 0; i < s.length && qi < q.length; i++) {
      if (s[i] === q[qi]) {
        qi += 1;
      }
    }
    return qi === q.length;
  }

  function ensureStyle() {
    if (document.getElementById(STYLE_ID)) {
      return;
    }

    const style = document.createElement("style");
    style.id = STYLE_ID;
    style.textContent = `
      .tabbrowser-tab[data-zenleap-split-candidate="true"] .tab-background {
        box-shadow: inset 0 0 0 2px rgba(245, 158, 11, 0.7) !important;
      }

      .tabbrowser-tab[data-zenleap-split-group="true"] .tab-content {
        outline: 1px solid rgba(245, 158, 11, 0.55) !important;
        outline-offset: -1px !important;
      }

      .tabbrowser-tab[data-zenleap-split-selected="true"] .tab-background {
        box-shadow: inset 0 0 0 3px rgba(250, 204, 21, 1) !important;
        background-color: rgba(250, 204, 21, 0.13) !important;
      }

      .tabbrowser-tab[data-zenleap-split-selected="true"] .tab-content {
        outline: 2px solid rgba(250, 204, 21, 0.95) !important;
        outline-offset: -1px !important;
      }
    `;
    document.documentElement.appendChild(style);
  }

  function clearTabHighlight() {
    if (!window.gBrowser) {
      return;
    }
    for (const tab of Array.from(window.gBrowser.tabs)) {
      if (tab && typeof tab.removeAttribute === "function") {
        tab.removeAttribute("data-zenleap-split-candidate");
        tab.removeAttribute("data-zenleap-split-group");
        tab.removeAttribute("data-zenleap-split-selected");
      }
    }
  }

  function getCandidates(originTab) {
    if (!window.gBrowser) {
      return [];
    }

    const splitter = window.gZenViewSplitter;
    const splitGroupByTab = new Map();
    const splitTabsByGroup = new Map();
    const seenSplitGroup = new Set();

    // Treat each split group as one candidate (not one per tab).
    if (splitter?._data && typeof splitter._data === "object") {
      let groupIndex = 0;
      for (const viewData of Object.values(splitter._data)) {
        const tabs = Array.isArray(viewData?.tabs) ? viewData.tabs.filter(Boolean) : [];
        if (tabs.length <= 1) {
          continue;
        }

        const groupId = `split-group-${groupIndex}`;
        groupIndex += 1;
        splitTabsByGroup.set(groupId, tabs);
        for (const tab of tabs) {
          splitGroupByTab.set(tab, groupId);
        }
      }
    }

    return Array.from(window.gBrowser.tabs)
      .filter((tab) => {
        if (!tab || tab.closing || tab === originTab) {
          return false;
        }

        const url = tab.linkedBrowser?.currentURI?.spec || "";
        if (url === "about:blank" || url === "about:newtab") {
          return false;
        }

        // Treat split groups as one candidate.
        const groupId = splitGroupByTab.get(tab);
        if (groupId) {
          if (seenSplitGroup.has(groupId)) {
            return false;
          }
          seenSplitGroup.add(groupId);
        }

        return true;
      })
      .map((tab) => ({
        tab,
        title: (tab.label || "Untitled").replace(/\s+/g, " ").trim(),
        url: tab.linkedBrowser?.currentURI?.spec || "",
        pos: Number.isInteger(tab._tPos) ? tab._tPos : 0,
      }));
  }

  function getSplitGroupTabsForTab(tab) {
    const splitter = window.gZenViewSplitter;
    if (!splitter?._data || !tab) {
      return [tab].filter(Boolean);
    }

    const allTabs = Array.from(window.gBrowser?.tabs || []).filter(Boolean);
    const keyOf = (t) =>
      t?.linkedPanel ||
      (typeof t?.getAttribute === "function" ? t.getAttribute("linkedpanel") : "") ||
      (Number.isInteger(t?._tPos) ? `pos:${t._tPos}` : "");

    const targetKey = keyOf(tab);
    if (!targetKey) {
      return [tab].filter(Boolean);
    }

    const tabByKey = new Map(allTabs.map((t) => [keyOf(t), t]));

    for (const viewData of Object.values(splitter._data)) {
      const tabs = Array.isArray(viewData?.tabs) ? viewData.tabs.filter(Boolean) : [];
      if (tabs.length <= 1) {
        continue;
      }

      const groupKeys = tabs.map(keyOf).filter(Boolean);
      if (groupKeys.includes(targetKey)) {
        const resolved = groupKeys
          .map((k) => tabByKey.get(k))
          .filter((t) => t && !t.closing);
        return resolved.length > 0 ? resolved : [tab].filter(Boolean);
      }
    }

    return [tab].filter(Boolean);
  }

  function closeOverlay() {
    if (!picker || !picker.overlay) {
      return;
    }

    try {
      picker.overlay.remove();
    } catch (_) {
      // no-op
    }

    picker.overlay = null;
    picker.panel = null;
    picker.list = null;
    picker.input = null;
    picker.mode = "quick";
  }

  function stopPicker({ restoreOrigin = false } = {}) {
    if (!picker) {
      return;
    }

    if (restoreOrigin && picker.originTab && !picker.originTab.closing) {
      try {
        window.gBrowser.selectedTab = picker.originTab;
      } catch (_) {
        // no-op
      }
    }

    closeOverlay();
    clearTabHighlight();
    picker = null;
  }

  function refreshFiltered() {
    if (!picker) {
      return;
    }

    const inputWasActive = !!(
      picker.mode === "ui" &&
      picker.input &&
      document.activeElement === picker.input
    );

    const query = picker.input ? picker.input.value || "" : "";
    picker.filtered = picker.candidates.filter((item) =>
      fuzzyMatch(`${item.title} ${item.url}`, query)
    );

    if (picker.filtered.length === 0) {
      picker.index = 0;
      clearTabHighlight();
      renderList();
      if (inputWasActive) {
        picker.input.focus();
      }
      return;
    }

    if (picker.index >= picker.filtered.length) {
      picker.index = 0;
    }

    renderList();

    // While typing in the search field, keep focus in the input and avoid
    // tab switching on every keystroke.
    if (inputWasActive) {
      picker.input.focus();
      const end = picker.input.value.length;
      picker.input.setSelectionRange(end, end);
      return;
    }

    applyPreview();
  }

  function applyPreview() {
    if (!picker || picker.filtered.length === 0) {
      return;
    }

    const active = picker.filtered[picker.index];
    if (!active?.tab || active.tab.closing) {
      return;
    }

    clearTabHighlight();

    for (const item of picker.filtered) {
      const tabsToMark = getSplitGroupTabsForTab(item?.tab);
      const isSplitGroup = tabsToMark.length > 1;

      for (const tab of tabsToMark) {
        if (tab && !tab.closing) {
          tab.setAttribute("data-zenleap-split-candidate", "true");
          if (isSplitGroup) {
            tab.setAttribute("data-zenleap-split-group", "true");
          }
        }
      }
    }

    const selectedTabs = getSplitGroupTabsForTab(active.tab);
    for (const tab of selectedTabs) {
      if (tab && !tab.closing) {
        tab.setAttribute("data-zenleap-split-selected", "true");
      }
    }

    try {
      window.gBrowser.selectedTab = active.tab;
    } catch (_) {
      // no-op
    }
  }

  function renderList() {
    if (!picker || !picker.list) {
      return;
    }

    const { list, filtered, index } = picker;
    list.textContent = "";

    if (filtered.length === 0) {
      const empty = document.createElement("div");
      empty.textContent = "No matching tabs";
      empty.style.padding = "10px 12px";
      empty.style.color = "#9ca3af";
      list.appendChild(empty);
      return;
    }

    filtered.slice(0, 40).forEach((item, i) => {
      const row = document.createElement("button");
      row.type = "button";
      row.style.width = "100%";
      row.style.display = "block";
      row.style.textAlign = "left";
      row.style.padding = "10px 12px";
      row.style.border = "0";
      row.style.background = i === index ? "#111827" : "transparent";
      row.style.color = i === index ? "#f9fafb" : "#d1d5db";
      row.style.cursor = "pointer";
      row.style.borderBottom = "1px solid #111827";

      const title = document.createElement("div");
      title.textContent = `${i + 1}. ${item.title}`;
      title.style.fontSize = "13px";
      title.style.fontWeight = "600";
      title.style.whiteSpace = "nowrap";
      title.style.overflow = "hidden";
      title.style.textOverflow = "ellipsis";

      const url = document.createElement("div");
      url.textContent = item.url;
      url.style.fontSize = "11px";
      url.style.marginTop = "2px";
      url.style.color = i === index ? "#dbeafe" : "#9ca3af";
      url.style.whiteSpace = "nowrap";
      url.style.overflow = "hidden";
      url.style.textOverflow = "ellipsis";

      row.appendChild(title);
      if (item.url) {
        row.appendChild(url);
      }

      row.addEventListener("mouseenter", () => {
        if (!picker) {
          return;
        }
        picker.index = i;
        renderList();
        applyPreview();
      });

      row.addEventListener("click", () => {
        if (!picker) {
          return;
        }
        picker.index = i;
        confirmSplit();
      });

      list.appendChild(row);
    });
  }

  function moveSelection(delta) {
    if (!picker || picker.filtered.length === 0) {
      return;
    }

    picker.index = (picker.index + delta + picker.filtered.length) % picker.filtered.length;
    renderList();
    applyPreview();
  }

  function confirmSplit() {
    if (!picker || picker.filtered.length === 0 || !window.gZenViewSplitter) {
      return;
    }

    const picked = picker.filtered[picker.index];
    const originTab = picker.originTab;
    stopPicker({ restoreOrigin: false });

    if (!picked?.tab || picked.tab.closing || !originTab || originTab.closing || picked.tab === originTab) {
      return;
    }

    try {
      window.gZenViewSplitter.splitTabs([originTab, picked.tab]);
    } catch (_) {
      // no-op
    }
  }

  function openSearchUi() {
    if (!picker || picker.overlay) {
      return;
    }

    const overlay = document.createElement("div");
    overlay.style.position = "fixed";
    overlay.style.inset = "0";
    overlay.style.zIndex = "2147483647";
    overlay.style.background = "rgba(0, 0, 0, 0.45)";
    overlay.style.display = "flex";
    overlay.style.alignItems = "flex-start";
    overlay.style.justifyContent = "center";
    overlay.style.paddingTop = "8vh";

    const panel = document.createElement("div");
    panel.style.width = "min(760px, 92vw)";
    panel.style.maxHeight = "76vh";
    panel.style.border = "1px solid #1f2937";
    panel.style.borderRadius = "10px";
    panel.style.background = "#030712";
    panel.style.color = "#f9fafb";
    panel.style.boxShadow = "0 10px 40px rgba(0,0,0,0.55)";
    panel.style.overflow = "hidden";

    const header = document.createElement("div");
    header.textContent = "Split current tab with...";
    header.style.padding = "10px 12px";
    header.style.fontSize = "13px";
    header.style.fontWeight = "700";
    header.style.borderBottom = "1px solid #1f2937";

    const input = document.createElement("input");
    input.type = "text";
    input.placeholder = "Fuzzy search tabs...";
    input.style.width = "100%";
    input.style.boxSizing = "border-box";
    input.style.border = "0";
    input.style.outline = "none";
    input.style.background = "#111827";
    input.style.color = "#f9fafb";
    input.style.padding = "10px 12px";
    input.style.fontSize = "13px";
    input.style.borderBottom = "1px solid #1f2937";

    const list = document.createElement("div");
    list.style.maxHeight = "58vh";
    list.style.overflow = "auto";

    const hint = document.createElement("div");
    hint.textContent = "Enter: split | Esc: close search | Up/Down or j/k: choose";
    hint.style.padding = "8px 12px";
    hint.style.fontSize = "11px";
    hint.style.color = "#9ca3af";
    hint.style.borderTop = "1px solid #1f2937";

    panel.appendChild(header);
    panel.appendChild(input);
    panel.appendChild(list);
    panel.appendChild(hint);
    overlay.appendChild(panel);
    document.documentElement.appendChild(overlay);

    picker.overlay = overlay;
    picker.panel = panel;
    picker.input = input;
    picker.list = list;
    picker.mode = "ui";

    input.addEventListener("input", refreshFiltered);
    overlay.addEventListener("mousedown", (event) => {
      if (event.target === overlay) {
        closeOverlay();
        refreshFiltered();
      }
    });

    renderList();
    input.focus();
    input.select();
  }

  function startQuickPicker() {
    if (!window.gBrowser || !window.gZenViewSplitter || !window.gBrowser.selectedTab) {
      return;
    }

    const originTab = window.gBrowser.selectedTab;
    const candidates = getCandidates(originTab);
    if (candidates.length === 0) {
      return;
    }

    stopPicker({ restoreOrigin: false });
    ensureStyle();

    let initialIndex = 0;
    const rightIndex = candidates.findIndex((item) => item.pos > (originTab._tPos ?? -1));
    if (rightIndex >= 0) {
      initialIndex = rightIndex;
    }

    picker = {
      originTab,
      candidates,
      filtered: candidates.slice(),
      index: initialIndex,
      mode: "quick",
      overlay: null,
      panel: null,
      input: null,
      list: null,
    };

    applyPreview();
  }

  function handlePickerKeydown(event) {
    if (!picker) {
      return;
    }

    const inputActive = !!(picker.input && document.activeElement === picker.input);

    if (
      event.code === "KeyS" &&
      !event.ctrlKey &&
      !event.shiftKey &&
      !event.altKey &&
      !event.metaKey &&
      !inputActive
    ) {
      event.preventDefault();
      event.stopPropagation();
      openSearchUi();
      return;
    }

    if (event.code === "Escape") {
      event.preventDefault();
      event.stopPropagation();

      if (picker.mode === "ui") {
        closeOverlay();
        refreshFiltered();
        return;
      }

      stopPicker({ restoreOrigin: true });
      return;
    }

    if (event.code === "Enter") {
      event.preventDefault();
      event.stopPropagation();
      confirmSplit();
      return;
    }

    if (event.code === "ArrowDown" || (!inputActive && event.code === "KeyJ")) {
      event.preventDefault();
      event.stopPropagation();
      moveSelection(1);
      return;
    }

    if (event.code === "ArrowUp" || (!inputActive && event.code === "KeyK")) {
      event.preventDefault();
      event.stopPropagation();
      moveSelection(-1);
    }
  }

  function onGlobalKeydown(event) {
    if (picker) {
      handlePickerKeydown(event);
      return;
    }

    if (isEditableTarget(event.target)) {
      return;
    }

    if (!(event.ctrlKey && event.shiftKey && !event.altKey && !event.metaKey)) {
      return;
    }

    if (event.code === "KeyU") {
      const splitter = window.gZenViewSplitter;
      if (!splitter || !splitter.splitViewActive) {
        return;
      }
      event.preventDefault();
      event.stopPropagation();
      try {
        splitter.unsplitCurrentView();
      } catch (_) {
        // no-op
      }
      return;
    }

    if (event.code === "KeyS") {
      event.preventDefault();
      event.stopPropagation();
      startQuickPicker();
    }
  }

  window.addEventListener("keydown", onGlobalKeydown, true);
})();
