const pages = [
  ["dashboard", "Dashboard"],
  ["players", "Players"],
  ["virtual", "Virtual Players"],
  ["transactions", "Wallet Transactions"],
  ["matches", "Matches"],
  ["replays", "Replays"],
  ["status", "Server Status"],
  ["audits", "Audit Log"],
];
const $ = (selector) => document.querySelector(selector);
const content = $("#content");
let currentPlayer = null;
let pending = null;

$("nav").innerHTML = pages.map(([id, name]) => `<button data-page="${id}">${name}</button>`).join("");
$("nav").onclick = (event) => {
  const page = event.target.dataset.page;
  if (page) load(page);
};
$("#loginForm").onsubmit = async (event) => {
  event.preventDefault();
  try {
    await api("/api/session", { method: "POST", body: JSON.stringify({ pin: $("#pin").value }) });
    $("#login").hidden = true;
    $("#app").hidden = false;
    load("dashboard");
  } catch (error) {
    $("#loginError").textContent = error.message;
  }
};
$("#backup").onclick = async () => {
  if (!confirm("确认使用固定目录创建 SQLite 在线备份？")) return;
  try {
    const result = await api("/api/backup", { method: "POST" });
    alert(`备份成功：${result.filename}`);
  } catch (error) {
    alert(error.message);
  }
};

async function load(page) {
  document.querySelectorAll("nav button").forEach((button) => button.classList.toggle("active", button.dataset.page === page));
  $("#title").textContent = pages.find((entry) => entry[0] === page)?.[1] || page;
  $("#subtitle").textContent = page === "virtual" ? "Public Virtual Player 安全管理" : "本地游戏运营控制台";
  content.innerHTML = "<p>Loading…</p>";
  try {
    if (page === "dashboard") dashboard(await api("/api/dashboard"));
    else if (page === "players") players();
    else if (page === "virtual") await virtualPlayers();
    else if (page === "status") object(await api("/api/server-status"));
    else objectTable(await api(`/api/${page}`));
  } catch (error) {
    content.innerHTML = `<div class="panel bad">${esc(error.message)}</div>`;
  }
}

function dashboard(data) {
  const metrics = [
    ["数据库", data.database],
    ["游戏服务", data.game_server.running ? "运行中" : "不可达"],
    ["玩家", data.players],
    ["24h 登录", data.active_24h],
    ["Chip 总额", data.chips],
    ["Gem 总额", data.gems],
    ["对局", data.matches],
    ["24h 对局", data.recent_matches],
    ["Replay", data.replays],
    ["Replay 解锁", data.unlocks],
  ];
  content.innerHTML = `<div class="grid">${metrics.map((entry) => `<div class="card"><div class="muted">${entry[0]}</div><div class="metric">${esc(entry[1])}</div></div>`).join("")}</div><h2 class="section-heading">最近管理员操作</h2>${table(data.audits)}`;
}

function players() {
  content.innerHTML = '<div class="toolbar"><input id="search" placeholder="Player ID / Steam ID / 昵称"><button id="searchBtn">搜索</button></div><div id="playerResults"></div>';
  $("#searchBtn").onclick = search;
  $("#search").onkeydown = (event) => {
    if (event.key === "Enter") search();
  };
  search();
}

async function search() {
  const rows = await api(`/api/players?q=${encodeURIComponent($("#search").value)}`);
  $("#playerResults").innerHTML = table(rows, true);
}

content.onclick = (event) => {
  const playerId = event.target.dataset.player;
  if (playerId) detail(playerId);
};

async function detail(id) {
  currentPlayer = id;
  const data = await api(`/api/players/${encodeURIComponent(id)}`);
  $("#title").textContent = `Player · ${data.display_name}`;
  content.innerHTML = `<div class="grid"><div class="card"><span class="muted">Player ID</span><pre>${esc(data.player_id)}</pre><span class="muted">Steam ID</span><pre>${esc(data.steam_id || "unavailable")}</pre></div><div class="card"><span class="muted">Chip / Gem</span><div class="metric">${data.chips} / ${data.gems}</div><span class="muted">XP / Level</span><div>${data.total_xp} / Lv.${data.level}</div></div><div class="card"><span class="muted">封禁状态</span><div class="${data.is_banned ? "bad" : "good"}">${data.is_banned ? "已封禁" : "正常"}</div><span class="muted">最后登录</span><div>${esc(data.last_login_at || "unavailable")}</div></div></div><div class="actions"><button data-act="chips">调整 Chip</button><button data-act="gems">调整 Gem</button><button data-act="xp">设置 XP</button><button data-act="daily_reset">重置 Daily Bonus</button><button class="danger" data-act="${data.is_banned ? "unban" : "ban"}">${data.is_banned ? "解封" : "封禁"}</button></div><div class="panel"><h2>管理员备注</h2><textarea id="note">${esc(data.admin_note)}</textarea><button id="saveNote">保存备注</button></div>${sections(data)}`;
  document.querySelector(".actions").onclick = (event) => {
    if (event.target.dataset.act) openAction(event.target.dataset.act);
  };
  $("#saveNote").onclick = () => postAction({ action: "note", note: $("#note").value, reason: "管理员备注更新" });
}

function sections(data) {
  return [
    ["最近钱包流水", data.transactions],
    ["最近对局", data.matches],
    ["最近 Replay", data.replays],
    ["Replay 解锁", data.unlocks],
    ["Daily Bonus", data.daily_bonus],
    ["管理员审计", data.audits],
  ].map((entry) => `<h2 class="section-heading">${entry[0]}</h2>${table(entry[1])}`).join("");
}

function openAction(action) {
  pending = action;
  const noValue = ["daily_reset", "ban", "unban"].includes(action);
  $("#actionTitle").textContent = {
    chips: "调整 Chip（正数增加，负数扣除）",
    gems: "调整 Gem（正数增加，负数扣除）",
    xp: "设置 XP 总值",
    daily_reset: "重置全部 Daily Bonus 领取记录",
    ban: "封禁玩家",
    unban: "解封玩家",
  }[action];
  $("#actionValue").hidden = noValue;
  $("#actionValue").required = !noValue;
  $("#actionValue").value = "";
  $("#actionReason").value = "";
  $("#confirmCheck").checked = false;
  $("#actionDialog").showModal();
}

$("#actionForm").onsubmit = async (event) => {
  if (event.submitter.value === "cancel") return;
  event.preventDefault();
  const body = { action: pending, reason: $("#actionReason").value };
  if (pending === "chips" || pending === "gems") {
    body.action = "wallet";
    body.currency = pending;
    body.amount = Number($("#actionValue").value);
  }
  if (pending === "xp") body.value = Number($("#actionValue").value);
  await postAction(body);
  $("#actionDialog").close();
  detail(currentPlayer);
};

async function postAction(body) {
  try {
    return await api(`/api/players/${encodeURIComponent(currentPlayer)}`, { method: "POST", body: JSON.stringify(body) });
  } catch (error) {
    alert(error.message);
    throw error;
  }
}

async function virtualPlayers() {
  const data = await api("/api/virtual");
  const health = data.health || {};
  const config = data.config || {};
  const profiles = Array.isArray(data.profiles) ? data.profiles : [];
  const events = Array.isArray(data.recent_events) ? data.recent_events : [];
  const filledRooms = Array.isArray(data.filled_rooms) ? data.filled_rooms : [];
  const metrics = [
    ["System Enabled", health.enabled ? "Enabled" : "Disabled"],
    ["Online / Target", `${value(health.online)} / ${value(config.target_online)}`],
    ["Maximum Online", value(config.maximum_online)],
    ["Maximum Per Room", value(config.maximum_per_room)],
    ["Queued", value(health.queued)],
    ["Pending Leave", value(health.pending_leave)],
    ["Errors", value(health.errors)],
    ["Filled Rooms", filledRooms.length],
    ["Restart Recovery", value(health.recovered_after_restart)],
    ["Last Scheduler Run", value(health.last_scheduler_run_at)],
    ["Last Scheduler Decision", value(health.last_scheduler_decision)],
    ["Last Scheduler Error", value(health.last_scheduler_error)],
  ];
  content.innerHTML = `
    <div id="virtualFeedback" class="feedback" hidden></div>
    <div class="virtual-header"><h2>状态摘要</h2><button id="virtualRefresh" class="ghost">Refresh</button></div>
    <div class="grid virtual-metrics">${metrics.map((entry) => `<div class="card"><div class="muted">${esc(entry[0])}</div><div class="metric metric-small">${esc(entry[1])}</div></div>`).join("")}</div>
    <h2 class="section-heading">全局操作</h2>
    <div class="panel">
      <p class="safe-note">Disable 或 Safe Offline 只会请求 Virtual 在安全节点离桌，不会从当前手牌中强制删除。</p>
      <div class="actions">
        <button id="virtualEnable">Enable Virtual System</button>
        <button id="virtualDisable" class="danger">Disable Virtual System</button>
        <button id="virtualOfflineAll" class="danger">Safe Offline All</button>
      </div>
    </div>
    <h2 class="section-heading">调度配置</h2>
    ${virtualConfigForm(config)}
    <h2 class="section-heading">Virtual Profiles</h2>
    ${virtualProfileTable(profiles)}
    <h2 class="section-heading">最近生命周期事件</h2>
    ${virtualEventTable(events, profiles)}
  `;
  $("#virtualRefresh").onclick = () => load("virtual");
  $("#virtualEnable").onclick = () => virtualGlobalEnabled(true);
  $("#virtualDisable").onclick = () => virtualGlobalEnabled(false);
  $("#virtualOfflineAll").onclick = virtualOfflineAll;
  $("#virtualConfigForm").onsubmit = virtualConfigSubmit;
  $("#virtualProfiles").onclick = virtualProfileAction;
}

function virtualConfigForm(config) {
  const editable = [
    ["target_online", "Target Online"],
    ["maximum_online", "Maximum Online"],
    ["maximum_per_room", "Maximum Per Room"],
    ["join_delay_min_ms", "Join Delay Min (ms)"],
    ["join_delay_max_ms", "Join Delay Max (ms)"],
    ["session_hand_min", "Session Hand Min"],
    ["session_hand_max", "Session Hand Max"],
  ];
  return `<form id="virtualConfigForm" class="panel config-form"><div class="config-grid">${editable.map(([key, label]) => `<label>${label}<input name="${key}" type="number" min="0" step="1" value="${esc(config[key])}" required></label>`).join("")}</div><div class="readonly-config"><span>Action Delay: ${esc(value(config.action_delay_min_ms))}–${esc(value(config.action_delay_max_ms))} ms</span><span>Chat Enabled: ${esc(value(config.chat_enabled))}</span></div><button>保存调度配置</button></form>`;
}

function virtualProfileTable(profiles) {
  if (!profiles.length) return '<div class="panel muted">暂无 Virtual profiles</div>';
  const rows = profiles.map((profile) => {
    const state = String(profile.virtual_state || "");
    const knownState = ["offline", "reserved", "queued", "joining", "seated", "playing", "pending_leave", "leaving", "error"].includes(state);
    const runtime = knownState ? `<span class="badge state-${esc(state)}">${esc(state)}</span>` : esc(value(state));
    const progress = Number.isInteger(profile.session_hand_target) && profile.session_hand_target > 0
      ? `${esc(profile.session_hands_played)} / ${esc(profile.session_hand_target)}`
      : "unavailable";
    return `<tr>
      <td>${esc(profile.display_name)}</td><td>${esc(profile.virtual_player_id)}</td><td>${esc(profile.avatar_id)}</td>
      <td>${esc(profile.skill_profile)}</td><td>${profile.enabled ? '<span class="good">Enabled</span>' : '<span class="bad">Disabled</span>'}</td>
      <td>${runtime}</td><td>${esc(value(profile.room_id))}</td><td>${esc(value(profile.seat))}</td><td>${esc(value(profile.chips))}</td>
      <td>${esc(value(profile.hand_id))}</td><td>${progress}</td><td>${esc(value(profile.online_since))}</td>
      <td>${esc(value(profile.last_action_at))}</td><td>${esc(value(profile.join_block_reason))}</td>
      <td>${esc(value(profile.pending_leave_reason))}</td><td>${esc(value(profile.recent_error))}</td>
      <td><div class="row-actions"><button data-virtual-action="enable" data-virtual-player="${esc(profile.virtual_player_id)}">Enable</button><button class="danger" data-virtual-action="disable" data-virtual-player="${esc(profile.virtual_player_id)}">Disable</button><button class="ghost" data-virtual-action="offline" data-virtual-player="${esc(profile.virtual_player_id)}">Safe Offline</button></div></td>
    </tr>`;
  }).join("");
  return `<div id="virtualProfiles" class="table-wrap table-wide"><table><thead><tr><th>Display Name</th><th>Virtual Player ID</th><th>Avatar</th><th>Skill Profile</th><th>Profile Enabled</th><th>Runtime State</th><th>Room</th><th>Seat</th><th>Chips</th><th>Hand ID</th><th>Session Progress</th><th>Online Since</th><th>Last Action</th><th>Join Block Reason</th><th>Pending Leave Reason</th><th>Recent Error</th><th>Actions</th></tr></thead><tbody>${rows}</tbody></table></div>`;
}

function virtualEventTable(events, profiles) {
  if (!events.length) return '<div class="panel muted">暂无生命周期事件</div>';
  const names = new Map(profiles.map((profile) => [profile.virtual_player_id, profile.display_name]));
  const rows = events.map((event) => ({
    time: event.created_at ?? event.time ?? "unavailable",
    virtual_player_id: event.virtual_player_id ?? "unavailable",
    display_name: names.get(event.virtual_player_id) ?? event.display_name ?? "unavailable",
    from_state: event.from_state ?? "unavailable",
    to_state: event.to_state ?? event.event_type ?? "unavailable",
    room_id: event.room_id ?? "unavailable",
    reason: event.reason ?? event.detail ?? "unavailable",
    error: event.error ?? (event.event_type === "error" ? event.detail : "") ?? "unavailable",
  }));
  return table(rows);
}

async function virtualGlobalEnabled(enabled) {
  const action = enabled ? "启用" : "禁用";
  if (!confirm(`确认${action} Virtual System？${enabled ? "" : "现有 Virtual 会在安全节点离桌，不会从当前手牌中强制删除。"}`)) return;
  await virtualWrite("/api/virtual/enabled", { enabled }, `${action}请求已提交`);
}

async function virtualOfflineAll() {
  if (!confirm("确认请求全部 Virtual 安全离桌？它们只会在安全节点离桌，不会从当前手牌中强制删除。")) return;
  await virtualWrite("/api/virtual/offline", {}, "全部 Virtual 安全离桌请求已提交");
}

async function virtualProfileAction(event) {
  const action = event.target.dataset.virtualAction;
  const playerId = event.target.dataset.virtualPlayer;
  if (!action || !playerId) return;
  if (action === "offline") {
    if (!confirm(`确认请求 ${playerId} 在安全节点离桌？`)) return;
    await virtualWrite("/api/virtual/offline", { player_id: playerId }, "安全离桌请求已提交");
    return;
  }
  const enabled = action === "enable";
  if (!confirm(`确认${enabled ? "启用" : "禁用"} profile ${playerId}？${enabled ? "" : "禁用后不再允许调度；当前实例会请求安全离桌。"}`)) return;
  await virtualWrite("/api/virtual/profile", { player_id: playerId, enabled }, `Profile ${enabled ? "已启用" : "已禁用"}`);
}

async function virtualConfigSubmit(event) {
  event.preventDefault();
  try {
    const body = {};
    for (const input of event.target.querySelectorAll("input[name]")) {
      if (input.value === "" || !/^\d+$/.test(input.value)) throw new Error(`${input.name} 必须是非负整数`);
      body[input.name] = Number(input.value);
    }
    validateVirtualConfig(body);
    await virtualWrite("/api/virtual/config", body, "调度配置已保存");
  } catch (error) {
    virtualFeedback(error.message, false);
  }
}

function validateVirtualConfig(config) {
  if (config.maximum_per_room < 1) throw new Error("maximum_per_room 必须至少为 1");
  if (config.target_online > config.maximum_online) throw new Error("target_online 不能大于 maximum_online");
  if (config.join_delay_min_ms > config.join_delay_max_ms) throw new Error("join_delay_min_ms 不能大于 join_delay_max_ms");
  if (config.session_hand_min > config.session_hand_max) throw new Error("session_hand_min 不能大于 session_hand_max");
}

async function virtualWrite(url, body, successMessage) {
  try {
    await api(url, { method: "POST", body: JSON.stringify(body) });
    await virtualPlayers();
    virtualFeedback(successMessage, true);
  } catch (error) {
    virtualFeedback(error.message, false);
  }
}

function virtualFeedback(message, success) {
  const feedback = $("#virtualFeedback");
  if (!feedback) return;
  feedback.hidden = false;
  feedback.className = `feedback ${success ? "feedback-good" : "feedback-bad"}`;
  feedback.textContent = message;
}

function value(input) {
  return input === undefined || input === null || input === "" ? "unavailable" : input;
}

function object(value) {
  content.innerHTML = `<div class="panel"><pre>${esc(JSON.stringify(value, null, 2))}</pre></div>`;
}

function objectTable(value) {
  content.innerHTML = table(value);
}

function table(rows, playerLinks = false) {
  if (!rows?.length) return '<div class="panel muted">暂无数据 / unavailable</div>';
  const columns = Object.keys(rows[0]);
  return `<div class="table-wrap"><table><thead><tr>${columns.map((column) => `<th>${esc(column)}</th>`).join("")}</tr></thead><tbody>${rows.map((row) => `<tr>${columns.map((column) => `<td>${playerLinks && column === "player_id" ? `<span class="link" data-player="${esc(row[column])}">${esc(row[column])}</span>` : esc(row[column])}</td>`).join("")}</tr>`).join("")}</tbody></table></div>`;
}

async function api(url, options = {}) {
  const response = await fetch(url, { headers: { "Content-Type": "application/json" }, ...options });
  const result = await response.json();
  if (!response.ok) throw new Error(result.error || `HTTP ${response.status}`);
  return result;
}

function esc(value) {
  return String(value ?? "").replace(/[&<>"']/g, (character) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[character]));
}
