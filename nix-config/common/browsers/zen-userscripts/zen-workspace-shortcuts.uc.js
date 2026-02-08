// ==UserScript==
// @name           Zen Workspace Shortcuts
// @description    Keyboard shortcut to create Zen workspaces
// @include        main
// ==/UserScript==

(function () {
  if (window.__zenWorkspaceShortcutsLoaded) return;
  window.__zenWorkspaceShortcutsLoaded = true;

  const promptService = (() => {
    try {
      if (typeof Services !== "undefined" && Services.prompt) return Services.prompt;
    } catch {}
    try {
      if (typeof ChromeUtils !== "undefined" && typeof ChromeUtils.importESModule === "function") {
        return ChromeUtils.importESModule("resource://gre/modules/Services.sys.mjs").Services.prompt;
      }
    } catch {}
    return null;
  })();

  const isEditableTarget = (target) => {
    if (!target) return false;
    if (target.isContentEditable) return true;
    const tag = (target.tagName || "").toLowerCase();
    return tag === "input" || tag === "textarea" || tag === "select";
  };

  const getWorkspaceId = (workspace) => workspace?.uuid || workspace?.id || null;

  const normalizeWorkspaceNames = async () => {
    if (!window.gZenWorkspaces || typeof window.gZenWorkspaces.getWorkspaces !== "function") return;
    if (typeof window.gZenWorkspaces.saveWorkspace !== "function") return;

    const workspaces = window.gZenWorkspaces.getWorkspaces() || [];
    if (!Array.isArray(workspaces)) return;

    for (const ws of workspaces) {
      if (!ws || !getWorkspaceId(ws)) continue;
      if (typeof ws.name === "string") continue;

      let fixedName = "Workspace";
      if (ws.name && typeof ws.name === "object" && typeof ws.name.name === "string" && ws.name.name.trim()) {
        fixedName = ws.name.name.trim();
      }

      ws.name = fixedName;
      try {
        await window.gZenWorkspaces.saveWorkspace(ws);
      } catch {}
    }
  };

  const createWorkspace = async () => {
    if (!window.gZenWorkspaces || typeof window.gZenWorkspaces.createAndSaveWorkspace !== "function") {
      return;
    }

    await normalizeWorkspaceNames();

    const current = window.gZenWorkspaces.getWorkspaces?.() || [];
    const beforeIds = new Set(current.map(getWorkspaceId).filter(Boolean));

    let rawName = null;
    try {
      if (promptService && typeof promptService.prompt === "function") {
        const value = { value: "New Workspace" };
        const ok = promptService.prompt(window, "Zen Workspace", "New workspace name", value, null, {});
        if (!ok) return;
        rawName = value.value;
      } else {
        rawName = window.prompt("New workspace name", "New Workspace");
      }
    } catch {
      rawName = window.prompt("New workspace name", "New Workspace");
    }
    if (rawName === null) return;

    const name = rawName.trim() || "New Workspace";
    await window.gZenWorkspaces.createAndSaveWorkspace(name, undefined, false, 0);

    const all = window.gZenWorkspaces.getWorkspaces?.() || [];
    const created = all.find((ws) => !beforeIds.has(getWorkspaceId(ws))) || all.find((ws) => ws?.name === name);
    const createdId = getWorkspaceId(created);
    if (createdId && typeof window.gZenWorkspaces.changeWorkspaceWithID === "function") {
      await window.gZenWorkspaces.changeWorkspaceWithID(createdId);
    }
  };

  document.addEventListener(
    "keydown",
    (event) => {
      if (event.ctrlKey && event.shiftKey && !event.altKey && !event.metaKey && (event.key === "n" || event.key === "N")) {
        if (isEditableTarget(event.target)) return;
        event.preventDefault();
        event.stopPropagation();
        void createWorkspace();
      }
    },
    true
  );

  setTimeout(() => {
    void normalizeWorkspaceNames();
  }, 1500);
})();
