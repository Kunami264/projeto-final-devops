"use strict";

const TOKEN_URL = "/auth/token";

const session = { accessToken: null, username: null };
const state = { users: [], orders: [] };

const $ = (id) => document.getElementById(id);

// ───────────────────────── Autenticação ─────────────────────────

async function login(username, password) {
  const resp = await fetch(TOKEN_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ username, password }),
  });
  if (!resp.ok) return false;
  session.accessToken = (await resp.json()).access_token;
  return true;
}

function logout(message) {
  session.accessToken = session.username = null;
  state.users = [];
  state.orders = [];
  $("app-view").hidden = true;
  $("login-view").hidden = false;
  $("login-password").value = "";
  showError("login-error", message || "");
  $("login-username").focus();
}

// ───────────────────────── Chamadas à API ─────────────────────────

class ApiError extends Error {}

async function api(method, path, body) {
  const send = () =>
    fetch(path, {
      method,
      headers: {
        Authorization: `Bearer ${session.accessToken}`,
        ...(body ? { "Content-Type": "application/json" } : {}),
      },
      body: body ? JSON.stringify(body) : undefined,
    });

  // O token dura 30 minutos: quando expira, pede-se novo login.
  const resp = await send();

  if (resp.status === 401) {
    logout("A sessão expirou. Inicie sessão novamente.");
    throw new ApiError("Sessão expirada");
  }
  if (resp.status === 204) return null;

  const data = await resp.json().catch(() => null);
  if (!resp.ok) throw new ApiError(errorText(resp.status, data));
  return data;
}

function errorText(status, data) {
  if (status === 403) return "Não tem permissão para esta operação.";
  if (status === 422) return "Dados inválidos. Verifique os campos.";
  if (data && typeof data.detail === "string") return data.detail;
  return `Não foi possível concluir a operação (erro ${status}).`;
}

// ───────────────────────── Interface ─────────────────────────

function showError(id, text) {
  $(id).textContent = text;
  $(id).hidden = !text;
}

let messageTimer;
function showMessage(text, isError) {
  const el = $("message");
  el.textContent = text;
  el.classList.toggle("is-error", Boolean(isError));
  el.hidden = false;
  clearTimeout(messageTimer);
  messageTimer = setTimeout(() => (el.hidden = true), 5000);
}

const SVG_NS = "http://www.w3.org/2000/svg";

function icon(name) {
  const svg = document.createElementNS(SVG_NS, "svg");
  svg.setAttribute("aria-hidden", "true");
  const use = document.createElementNS(SVG_NS, "use");
  use.setAttribute("href", `#i-${name}`);
  svg.append(use);
  return svg;
}

function initials(name) {
  const parts = String(name || "?").trim().split(/\s+/);
  const first = parts[0] ? parts[0][0] : "?";
  const last = parts.length > 1 ? parts[parts.length - 1][0] : "";
  return (first + last).toUpperCase();
}

function avatar(name, key) {
  const span = document.createElement("span");
  span.className = `avatar c${Math.abs(Number(key) || 0) % 6}`;
  span.textContent = initials(name);
  span.setAttribute("aria-hidden", "true");
  return span;
}

function cell(content, className) {
  const td = document.createElement("td");
  if (className) td.className = className;
  if (content instanceof Node) td.append(content);
  else td.textContent = content;
  return td;
}

function idBadge(id) {
  const span = document.createElement("span");
  span.className = "id-badge";
  span.textContent = `#${id}`;
  return span;
}

function person(name, key) {
  const div = document.createElement("div");
  div.className = "person";
  const label = document.createElement("span");
  label.textContent = name;
  div.append(avatar(name, key), label);
  return div;
}

function withIcon(name, text) {
  const span = document.createElement("span");
  span.className = "item";
  const label = document.createElement("span");
  label.textContent = text;
  span.append(icon(name), label);
  return span;
}

function pill(text) {
  const span = document.createElement("span");
  span.className = "qty";
  span.textContent = text;
  return span;
}

function actionsCell(onEdit, onDelete) {
  const td = document.createElement("td");
  td.className = "row-actions";
  const edit = document.createElement("button");
  edit.title = "Editar";
  edit.setAttribute("aria-label", "Editar");
  edit.append(icon("edit"));
  edit.addEventListener("click", onEdit);
  const del = document.createElement("button");
  del.title = "Apagar";
  del.setAttribute("aria-label", "Apagar");
  del.className = "danger";
  del.append(icon("trash"));
  del.addEventListener("click", onDelete);
  td.append(edit, del);
  return td;
}

function matches(query, ...fields) {
  const q = query.trim().toLowerCase();
  return !q || fields.some((f) => String(f ?? "").toLowerCase().includes(q));
}

function renderUsers() {
  const query = $("users-search").value;
  const rows = state.users.filter((u) => matches(query, u.name, u.email, u.id));
  $("users-body").replaceChildren(
    ...rows.map((u) => {
      const tr = document.createElement("tr");
      tr.append(
        cell(idBadge(u.id)),
        cell(person(u.name, u.id)),
        cell(u.email, "email"),
        actionsCell(
          () => openUserDialog(u),
          () => confirmDelete(`Apagar o cliente "${u.name}"?`, () => removeUser(u)),
        ),
      );
      return tr;
    }),
  );
  const last = state.users.reduce((a, u) => (!a || u.id > a.id ? u : a), null);
  $("stat-users").textContent = state.users.length;
  $("stat-users-last").textContent = last ? last.name : "—";
  $("users-empty").hidden = state.users.length > 0;
  $("users-nomatch").hidden = state.users.length === 0 || rows.length > 0;
}

function renderOrders() {
  const query = $("orders-search").value;
  const rows = state.orders.filter((o) => matches(query, o.item, o.user && o.user.name, o.id));
  $("orders-body").replaceChildren(
    ...rows.map((o) => {
      const tr = document.createElement("tr");
      tr.append(
        cell(idBadge(o.id)),
        cell(o.user ? person(o.user.name, o.user.id) : "—"),
        cell(withIcon("box", o.item)),
        cell(pill(o.quantity), "num"),
        actionsCell(
          () => openOrderDialog(o),
          () => confirmDelete(`Apagar a encomenda n.º ${o.id} (${o.item})?`, () => removeOrder(o)),
        ),
      );
      return tr;
    }),
  );
  const units = state.orders.reduce((sum, o) => sum + (Number(o.quantity) || 0), 0);
  const customers = new Set(state.orders.map((o) => (o.user ? o.user.id : o.user_id))).size;
  $("stat-orders").textContent = state.orders.length;
  $("stat-units").textContent = units.toLocaleString("pt-PT");
  $("stat-customers").textContent = customers;
  $("orders-empty").hidden = state.orders.length > 0;
  $("orders-nomatch").hidden = state.orders.length === 0 || rows.length > 0;
}

async function loadUsers() {
  state.users = await api("GET", "/users");
  renderUsers();
}

async function loadOrders() {
  state.orders = await api("GET", "/orders");
  renderOrders();
}

function selectTab(tab) {
  for (const name of ["users", "orders"]) {
    $(`${name}-panel`).hidden = name !== tab;
    $(`tab-${name}`).classList.toggle("active", name === tab);
  }
  (tab === "users" ? loadUsers() : loadOrders()).catch(reportError);
}

function reportError(err) {
  if (err instanceof ApiError) {
    if (session.accessToken) showMessage(err.message, true);
  } else {
    showMessage("Sem ligação ao servidor. Tente novamente.", true);
  }
}

// ───────────────────────── Clientes ─────────────────────────

let editingUser = null;

function openUserDialog(user) {
  editingUser = user || null;
  $("user-dialog-title").textContent = user ? "Editar cliente" : "Novo cliente";
  $("user-name").value = user ? user.name : "";
  $("user-email").value = user ? user.email : "";
  showError("user-error", "");
  $("user-dialog").showModal();
}

async function saveUser(event) {
  event.preventDefault();
  const data = { name: $("user-name").value.trim(), email: $("user-email").value.trim() };
  try {
    if (editingUser) await api("PUT", `/users/${editingUser.id}`, data);
    else await api("POST", "/users", data);
    $("user-dialog").close();
    showMessage(editingUser ? "Cliente atualizado." : "Cliente criado.");
    await loadUsers();
  } catch (err) {
    showError("user-error", err instanceof ApiError ? err.message : "Sem ligação ao servidor.");
  }
}

async function removeUser(user) {
  await api("DELETE", `/users/${user.id}`);
  showMessage("Cliente apagado.");
  await loadUsers();
}

// ───────────────────────── Encomendas ─────────────────────────

let editingOrder = null;

async function openOrderDialog(order) {
  editingOrder = order || null;
  $("order-dialog-title").textContent = order ? `Editar encomenda n.º ${order.id}` : "Nova encomenda";
  // O cliente de uma encomenda não muda: só se escolhe ao criar.
  $("order-user-field").hidden = Boolean(order);
  $("order-user").required = !order;
  $("order-item").value = order ? order.item : "";
  $("order-quantity").value = order ? order.quantity : 1;
  showError("order-error", "");

  if (!order) {
    try {
      await loadUsers();
    } catch (err) {
      return reportError(err);
    }
    if (state.users.length === 0) return showMessage("Crie primeiro um cliente.", true);
    $("order-user").replaceChildren(
      ...state.users.map((u) => {
        const option = document.createElement("option");
        option.value = u.id;
        option.textContent = `${u.name} (${u.email})`;
        return option;
      }),
    );
  }
  $("order-dialog").showModal();
}

async function saveOrder(event) {
  event.preventDefault();
  const item = $("order-item").value.trim();
  const quantity = Number($("order-quantity").value);
  try {
    if (editingOrder) await api("PUT", `/orders/${editingOrder.id}`, { item, quantity });
    else await api("POST", "/orders", { user_id: Number($("order-user").value), item, quantity });
    $("order-dialog").close();
    showMessage(editingOrder ? "Encomenda atualizada." : "Encomenda criada.");
    await loadOrders();
  } catch (err) {
    showError("order-error", err instanceof ApiError ? err.message : "Sem ligação ao servidor.");
  }
}

async function removeOrder(order) {
  await api("DELETE", `/orders/${order.id}`);
  showMessage("Encomenda apagada.");
  await loadOrders();
}

// ───────────────────────── Confirmação ─────────────────────────

let pendingDelete = null;

function confirmDelete(text, action) {
  pendingDelete = action;
  $("confirm-text").textContent = text;
  $("confirm-dialog").showModal();
}

// ───────────────────────── Eventos ─────────────────────────

$("login-form").addEventListener("submit", async (event) => {
  event.preventDefault();
  const username = $("login-username").value.trim();
  showError("login-error", "");
  let ok = false;
  try {
    ok = await login(username, $("login-password").value);
  } catch {
    return showError("login-error", "Sem ligação ao servidor.");
  }
  if (!ok) return showError("login-error", "Utilizador ou password incorretos.");

  session.username = username;
  $("session-user").textContent = username;
  $("session-avatar").textContent = initials(username);
  $("login-view").hidden = true;
  $("app-view").hidden = false;
  selectTab("users");
});

$("logout").addEventListener("click", () => logout());
$("tab-users").addEventListener("click", () => selectTab("users"));
$("tab-orders").addEventListener("click", () => selectTab("orders"));
$("new-user").addEventListener("click", () => openUserDialog());
$("new-order").addEventListener("click", () => openOrderDialog());
$("users-search").addEventListener("input", renderUsers);
$("orders-search").addEventListener("input", renderOrders);
$("user-form").addEventListener("submit", saveUser);
$("order-form").addEventListener("submit", saveOrder);

$("confirm-dialog").addEventListener("close", () => (pendingDelete = null));
$("confirm-ok").addEventListener("click", (event) => {
  event.preventDefault();
  const action = pendingDelete;
  $("confirm-dialog").close();
  if (action) action().catch(reportError);
});

for (const button of document.querySelectorAll("[data-close]")) {
  button.addEventListener("click", () => button.closest("dialog").close());
}
