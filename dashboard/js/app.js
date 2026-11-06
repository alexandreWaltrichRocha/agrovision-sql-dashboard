const api = (p) => fetch("/api" + p).then(r => { if (!r.ok) throw new Error(r.status); return r.json(); });
const $ = (id) => document.getElementById(id);
const charts = {};
const PALETA = ["#4ade80", "#38bdf8", "#fbbf24", "#f87171", "#a78bfa", "#fb923c", "#2dd4bf", "#f472b6"];
Chart.defaults.color = "#8fae9a";
Chart.defaults.borderColor = "#243a2c";

function desenhar(id, config) {
  if (charts[id]) charts[id].destroy();
  charts[id] = new Chart($(id), config);
}

async function carregarResumo() {
  const r = await api("/resumo");
  $("c-fazendas").textContent = r.total_fazendas;
  $("c-sensores").textContent = r.total_sensores;
  $("c-sensores-ativos").textContent = r.sensores_ativos + " ativos";
  $("c-alertas").textContent = r.alertas_ativos;
  $("c-criticos").textContent = r.alertas_criticos + " críticos";
  $("c-umidade").textContent = (r.umidade_media ?? "–") + "%";
  $("c-temp").textContent = (r.temperatura_media ?? "–") + "°C";
  $("c-talhoes").textContent = r.talhoes_criticos;
}

async function carregarGraficos() {
  const [u, t, reg] = await Promise.all([api("/umidade-por-fazenda"), api("/temperatura-por-fazenda"), api("/alertas-por-regiao")]);
  desenhar("g-umidade", { type: "bar", data: { labels: u.map(x => x.nome),
    datasets: [{ label: "Umidade média (%)", data: u.map(x => x.media_umidade), backgroundColor: "#38bdf8" }] },
    options: { plugins: { legend: { display: false } }, scales: { y: { beginAtZero: true, max: 100 } } } });
  desenhar("g-temp", { type: "bar", data: { labels: t.map(x => x.nome),
    datasets: [{ label: "Temperatura média (°C)", data: t.map(x => x.media_temperatura), backgroundColor: "#fb923c" }] },
    options: { plugins: { legend: { display: false } }, scales: { y: { beginAtZero: true } } } });
  desenhar("g-regiao", { type: "doughnut", data: { labels: reg.map(x => x.regiao),
    datasets: [{ data: reg.map(x => x.total), backgroundColor: PALETA }] } });
}

// escapa texto vindo da API antes de montar HTML (evita XSS)
const esc = (v) => String(v ?? "").replace(/[&<>"']/g, (c) =>
  ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
const tag = (n) => `<span class="tag ${esc(n)}">${esc(n)}</span>`;

async function carregarTabelas() {
  const [tal, al] = await Promise.all([api("/talhoes-criticos"), api("/alertas?status=ativo&limit=15")]);
  $("t-talhoes").tBodies[0].innerHTML = tal.length ? tal.map(x =>
    `<tr><td>${esc(x.fazenda)}</td><td>${esc(x.talhao)}</td><td>${esc(x.cultura)}</td><td>${esc(x.umidade)}%</td><td>${esc(x.temperatura)}°C</td></tr>`).join("")
    : `<tr><td colspan="5">Nenhum talhão crítico 🎉</td></tr>`;
  $("t-alertas").tBodies[0].innerHTML = al.length ? al.map(x =>
    `<tr><td>${tag(x.nivel)}</td><td>${esc(x.fazenda)}</td><td>${esc(x.talhao ?? "-")}</td><td>${esc(x.mensagem)}</td>
     <td><button onclick="resolver(${Number(x.id)})">Resolver</button></td></tr>`).join("")
    : `<tr><td colspan="5">Sem alertas ativos</td></tr>`;
}

async function resolver(id) {
  const r = await fetch(`/api/alertas/${id}/resolver`, { method: "PATCH" });
  if (!r.ok && r.status !== 404) { alert("Não foi possível resolver o alerta."); return; }
  carregarTudo();
}

async function carregarSensores() {
  const sel = $("sel-sensor");
  if (sel.value) return;
  const s = await api("/sensores?status=ativo");
  sel.innerHTML = s.length
    ? s.map(x => `<option value="${Number(x.id)}">${esc(x.codigo)} – ${esc(x.fazenda)} / ${esc(x.talhao)}</option>`).join("")
    : '<option value="">Nenhum sensor ativo</option>';
}

async function carregarHistorico() {
  const id = $("sel-sensor").value;
  if (!id) return;
  const h = await api(`/sensores/${id}/historico?horas=${$("sel-horas").value}`);
  desenhar("g-historico", { type: "line", data: {
    labels: h.map(x => new Date(x.lida_em).toLocaleString("pt-BR", { day: "2-digit", month: "2-digit", hour: "2-digit" })),
    datasets: [
      { label: "Umidade (%)", data: h.map(x => x.umidade), borderColor: "#38bdf8", pointRadius: 0, tension: .3 },
      { label: "Temperatura (°C)", data: h.map(x => x.temperatura), borderColor: "#fb923c", pointRadius: 0, tension: .3 }] },
    options: { scales: { x: { ticks: { maxTicksLimit: 8 } } } } });
}

async function carregarTudo() {
  try {
    await carregarSensores();
    await Promise.all([carregarResumo(), carregarGraficos(), carregarTabelas(), carregarHistorico()]);
    $("atualizado").textContent = "Atualizado às " + new Date().toLocaleTimeString("pt-BR");
  } catch (e) { $("atualizado").textContent = "Erro ao carregar dados da API"; console.error(e); }
}

$("sel-sensor").addEventListener("change", carregarHistorico);
$("sel-horas").addEventListener("change", carregarHistorico);
carregarTudo();
setInterval(carregarTudo, 30000);
