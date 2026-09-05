const { dogBreeds, catBreeds, dewormers } = window.PAW_DATA;

const icons = {
  home: '<svg class="icon" viewBox="0 0 24 24"><path d="m3 11 9-7 9 7"/><path d="M5 10v10h14V10M9 20v-6h6v6"/></svg>',
  notebook: '<svg class="icon" viewBox="0 0 24 24"><rect x="5" y="3" width="15" height="18" rx="3"/><path d="M9 3v18M3 7h4M3 12h4M3 17h4M12 8h5M12 12h5"/></svg>',
  plus: '<svg class="icon" viewBox="0 0 24 24"><path d="M12 5v14M5 12h14"/></svg>',
  star: '<svg class="icon" viewBox="0 0 24 24"><path d="m12 3 2.7 5.5 6.1.9-4.4 4.3 1 6.1-5.4-2.9-5.4 2.9 1-6.1-4.4-4.3 6.1-.9L12 3Z"/></svg>',
  paw: '<svg class="icon" viewBox="0 0 24 24"><path d="M12 13c-4.3 0-7.7 3-7.7 6.1 0 2.7 2.3 4.3 5.2 3 1.6-.7 3.4-.7 5 0 2.9 1.3 5.2-.3 5.2-3 0-3.1-3.4-6.1-7.7-6.1Z"/><ellipse cx="5" cy="10" rx="3" ry="3.5"/><ellipse cx="10" cy="5.5" rx="3" ry="3.5"/><ellipse cx="19" cy="10" rx="3" ry="3.5"/><ellipse cx="15" cy="5.5" rx="3" ry="3.5"/></svg>',
  chevron: '<svg class="icon" viewBox="0 0 24 24"><path d="m9 5 7 7-7 7"/></svg>',
  down: '<svg class="icon" viewBox="0 0 24 24"><path d="m5 9 7 7 7-7"/></svg>',
  close: '<svg class="icon" viewBox="0 0 24 24"><path d="m6 6 12 12M18 6 6 18"/></svg>',
  bell: '<svg class="icon" viewBox="0 0 24 24"><path d="M18 8a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9ZM10 21h4"/></svg>',
  shield: '<svg class="icon" viewBox="0 0 24 24"><path d="M12 3 4 6v5c0 5.1 3.2 8.5 8 10 4.8-1.5 8-4.9 8-10V6l-8-3Z"/><path d="M9 12.5 11 14l4-4"/></svg>',
  capsule: '<svg class="icon" viewBox="0 0 24 24"><path d="M8.4 4.4 4.5 8.3a5 5 0 0 0 7.1 7.1l3.9-3.9a5 5 0 0 0-7.1-7.1Z"/><path d="m7 13 6-6"/></svg>',
  syringe: '<svg class="icon" viewBox="0 0 24 24"><path d="m14 3 7 7M16 5l-9.5 9.5a3.5 3.5 0 0 0-1 2.5v2H3v2h4v-2a3.5 3.5 0 0 0 2.5-1L19 8M12 9l3 3M4 16l4 4"/></svg>',
  food: '<svg class="icon" viewBox="0 0 24 24"><path d="M4 11h16l-1.6 8H5.6L4 11Z"/><path d="M6 11c.4-3.8 2.4-6 6-6s5.6 2.2 6 6M9 8h.01M15 8h.01"/></svg>',
  heart: '<svg class="icon" viewBox="0 0 24 24"><path d="M20.8 5.8a5.5 5.5 0 0 0-7.8 0L12 6.9l-1.1-1.1a5.5 5.5 0 0 0-7.8 7.8l1.1 1.1L12 22l7.8-7.3 1.1-1.1a5.5 5.5 0 0 0-.1-7.8Z"/></svg>',
  camera: '<svg class="icon" viewBox="0 0 24 24"><path d="M4 7h4l1.5-2h5L16 7h4v13H4V7Z"/><circle cx="12" cy="13" r="4"/></svg>',
  search: '<svg class="icon" viewBox="0 0 24 24"><circle cx="11" cy="11" r="7"/><path d="m20 20-4-4"/></svg>',
  check: '<svg class="icon" viewBox="0 0 24 24"><path d="m5 12 4 4L19 6"/></svg>',
  info: '<svg class="icon" viewBox="0 0 24 24"><circle cx="12" cy="12" r="9"/><path d="M12 11v6M12 7h.01"/></svg>',
  cloud: '<svg class="icon" viewBox="0 0 24 24"><path d="M17.5 19H6a4 4 0 0 1-.7-7.9A7 7 0 0 1 19 9a5 5 0 0 1-1.5 10Z"/><path d="m9 14 2 2 4-4"/></svg>',
  user: '<svg class="icon" viewBox="0 0 24 24"><circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/></svg>',
  sliders: '<svg class="icon" viewBox="0 0 24 24"><path d="M4 7h10M18 7h2M4 17h3M11 17h9"/><circle cx="16" cy="7" r="2"/><circle cx="9" cy="17" r="2"/></svg>'
};

const today = new Date();
const iso = (date) => new Date(date).toISOString().slice(0, 10);
const uid = () => `${Date.now()}-${Math.random().toString(16).slice(2)}`;
const formatDate = (value) => new Intl.DateTimeFormat("zh-CN", { month: "short", day: "numeric" }).format(new Date(value));
const typeMeta = {
  deworm: { label: "驱虫", icon: "capsule" },
  vaccine: { label: "疫苗", icon: "syringe" },
  food: { label: "主粮", icon: "food" },
  taste: { label: "口味", icon: "heart" }
};

// 中国大陆常用简称和俗称只用于搜索，不替代正式品种名称。
const chinaBreedAliases = {
  "Chinese Domestic Cat": ["田园猫", "狸花猫", "橘猫", "三花猫", "奶牛猫"],
  "British Shorthair": ["英短", "英国短毛"],
  "American Shorthair": ["美短", "美国短毛"],
  "Exotic Shorthair": ["异短", "加菲猫"],
  "Ragdoll": ["布偶", "仙女猫"],
  "Maine Coon": ["缅因", "缅因库恩"],
  "Sphynx": ["无毛猫", "加拿大无毛猫"],
  "Scottish Fold": ["折耳猫", "苏格兰折耳"],
  "Devon Rex": ["德文", "德文猫"],
  "Cornish Rex": ["柯尼斯", "康沃尔卷毛猫"],
  "Norwegian Forest": ["挪威森林", "挪威森林猫"],
  "Russian Blue": ["俄蓝", "俄罗斯蓝"],
  "Siamese": ["暹罗", "泰国猫"],
  "Persian": ["波斯", "长毛猫"],
  "Bengal": ["孟加拉豹猫", "豹猫"],
  "Chinese Rural Dog": ["田园犬", "土狗", "中华田园狗"],
  "Poodle": ["贵宾", "贵宾犬", "泰迪", "泰迪犬", "迷你贵宾"],
  "Siberian Husky": ["哈士奇", "二哈", "西伯利亚雪橇犬"],
  "Alaskan Malamute": ["阿拉斯加", "阿拉斯加犬", "雪橇犬"],
  "Golden Retriever": ["金毛", "金毛犬", "金毛寻回犬"],
  "Labrador Retriever": ["拉布拉多", "拉布拉多犬"],
  "German Shepherd Dog": ["德牧", "德国牧羊犬", "黑背"],
  "French Bulldog": ["法斗", "法国斗牛犬"],
  "Bulldog": ["英斗", "英国斗牛犬"],
  "Welsh Corgi Pembroke": ["柯基", "柯基犬", "彭布罗克柯基"],
  "Welsh Corgi Cardigan": ["柯基", "卡迪根柯基"],
  "German Spitz": ["德国狐狸犬", "德国尖嘴犬", "博美", "博美犬"],
  "Samoyed": ["萨摩耶", "微笑天使"],
  "Shiba": ["柴犬", "日本柴犬"],
  "Akita": ["秋田", "秋田犬"],
  "Chow Chow": ["松狮", "松狮犬"],
  "Pug": ["巴哥", "巴哥犬", "八哥犬"],
  "Yorkshire Terrier": ["约克夏", "约克夏犬"],
  "Miniature Schnauzer": ["雪纳瑞", "迷你雪纳瑞"],
  "Shetland Sheepdog": ["喜乐蒂", "喜乐蒂牧羊犬"],
  "Border Collie": ["边牧", "边境牧羊犬"],
  "Dobermann": ["杜宾", "杜宾犬"],
  "Cane Corso Italiano": ["卡斯罗", "卡斯罗犬"],
  "Bichon Frise": ["比熊", "比熊犬"],
  "Shih Tzu": ["西施", "西施犬"]
};

const demoState = {
  account: { bound: false, email: "", provider: "", lastSync: "" },
  activePetId: "pet-mochi",
  pets: [
    { id: "pet-mochi", name: "糯米", species: "猫", gender: "母", neuterStatus: "已绝育", breed: "英国短毛猫", birthday: "2023-03-18", avatar: "🐱" },
    { id: "pet-dou", name: "豆包", species: "狗", gender: "公", neuterStatus: "未绝育", breed: "柴犬", birthday: "2021-11-06", avatar: "🐶" }
  ],
  records: [
    { id: "r1", petId: "pet-mochi", type: "vaccine", title: "猫三联 · 第 2 针", detail: "完成注射时间记录", date: "2026-08-12", price: 0 },
    { id: "r2", petId: "pet-mochi", type: "deworm", title: "米尔贝肟吡喹酮片（海乐妙）", detail: "内驱 · ¥46.00 · 每 3 月提醒", date: "2026-07-28", price: 46, frequencyMonths: 3, reminderAt: "2026-10-28" },
    { id: "r3", petId: "pet-mochi", type: "food", title: "鲜朗烘焙猫粮", detail: "1.5 kg · 食用了 36 天", date: "2026-07-20", price: 139 },
    { id: "r4", petId: "pet-mochi", type: "taste", title: "小李子火鸡肉主食罐", detail: "主食罐 · 4.5 星", date: "2026-07-13", rating: 4.5 }
  ],
  tastes: [
    { id: "t1", petId: "pet-mochi", brand: "小李子", product: "火鸡肉主食罐", category: "主食罐", rating: 4.5, emoji: "🥫" },
    { id: "t2", petId: "pet-mochi", brand: "冻干生骨肉", product: "鸡肉小方", category: "冻干", rating: 5, emoji: "🍗" },
    { id: "t3", petId: "pet-mochi", brand: "喵梵思", product: "金枪鱼汤包", category: "汤包", rating: 2.5, emoji: "🐟" },
    { id: "t4", petId: "pet-mochi", brand: "咕噜酱", product: "鸡胸肉猫条", category: "猫条", rating: 3, emoji: "🧡" }
  ]
};

let persisted = null;
try { persisted = JSON.parse(localStorage.getItem("paw-diary-prototype-v8")); } catch (_) {}
const state = { ...structuredClone(demoState), ...(persisted || {}), route: "home", filter: "all", rankingView: "gallery", rating: 4.5, photoData: "", petSpecies: "猫", petDraft: null, recordDraft: null, editingPetId: null, drugSpeciesFilter: "猫", drugScopeFilter: "全部" };
const app = document.querySelector("#app");
const sheetRoot = document.querySelector("#sheet-root");
const toastRoot = document.querySelector("#toast-root");
const photoInput = document.querySelector("#photo-input");

function saveState() {
  const { account, activePetId, pets, records, tastes } = state;
  localStorage.setItem("paw-diary-prototype-v8", JSON.stringify({ account, activePetId, pets, records, tastes }));
}

function ageText(birthday) {
  const start = new Date(birthday);
  let years = today.getFullYear() - start.getFullYear();
  let months = today.getMonth() - start.getMonth();
  if (today.getDate() < start.getDate()) months--;
  if (months < 0) { years--; months += 12; }
  return `${Math.max(0, years)} 岁 ${Math.max(0, months)} 个月`;
}

function activePet() { return state.pets.find(p => p.id === state.activePetId) || state.pets[0]; }
function genderText(pet) {
  if (!pet.gender || pet.gender === "未知") return "性别未知";
  return pet.species === "狗" ? `${pet.gender}犬` : `${pet.gender}猫`;
}
function neuterText(pet) { return pet.neuterStatus || "绝育状态未知"; }
function escapeAttr(value = "") { return String(value).replaceAll("&","&amp;").replaceAll('"',"&quot;").replaceAll("<","&lt;").replaceAll(">","&gt;"); }
function hydrateIcons(root = document) {
  root.querySelectorAll("[data-icon]").forEach(el => { el.innerHTML = icons[el.dataset.icon] || ""; });
}
function toast(message) {
  toastRoot.innerHTML = `<div class="toast">${message}</div>`;
  window.setTimeout(() => { toastRoot.innerHTML = ""; }, 2200);
}
function avatarMarkup(pet) {
  return pet.photo ? `<img src="${pet.photo}" alt="${pet.name}的头像" />` : `<span aria-hidden="true">${pet.avatar || (pet.species === "狗" ? "🐶" : "🐱")}</span>`;
}
function starMarkup(value) {
  return Array.from({ length: 5 }, (_, i) => {
    const remaining = value - i;
    return remaining >= 1 ? "★" : remaining >= .5 ? "⯨" : "☆";
  }).join("");
}

function accountSyncMarkup() {
  const bound = Boolean(state.account?.bound);
  return `<div class="sync-pill ${bound ? "bound" : "local"}"><span class="sync-dot"></span>${bound ? "账号已绑定 · 原型同步演示" : "本地演示数据 · 尚未绑定账号"}</div>`;
}

function accountMetrics() {
  const photos = state.pets.filter(item => item.photo).length + state.records.filter(item => item.photo).length + state.tastes.filter(item => item.photo).length;
  return { pets: state.pets.length, records: state.records.length, photos };
}

function syncTimeText(value) {
  if (!value) return "尚未同步";
  return new Intl.DateTimeFormat("zh-CN", { month:"numeric", day:"numeric", hour:"2-digit", minute:"2-digit" }).format(new Date(value));
}

function render() {
  const routes = { home: renderHome, records: renderRecords, ranking: renderRanking, pets: renderPets };
  app.innerHTML = (routes[state.route] || renderHome)();
  document.querySelectorAll(".nav-item").forEach(item => item.classList.toggle("active", item.dataset.route === state.route));
  hydrateIcons();
  app.scrollTop = 0;
}

function renderHome() {
  const pet = activePet();
  const records = state.records.filter(r => r.petId === pet.id).slice(0, 3);
  const reminder = state.records.filter(r => r.petId === pet.id && r.type === "deworm" && r.reminderAt).sort((a,b) => new Date(a.reminderAt)-new Date(b.reminderAt))[0];
  return `<div class="page">
    <section class="home-hero">
      <div class="topline">
        <div class="brand-title">宠刻<small>CHONGKE</small></div>
        <div class="top-actions"><button class="icon-button account-button" data-action="open-account" aria-label="账号与云端备份"><span data-icon="user"></span>${state.account?.bound ? '<span class="account-dot" aria-hidden="true"></span>' : ""}</button><button class="icon-button" data-action="open-info" aria-label="关于与记录边界"><span data-icon="shield"></span></button></div>
      </div>
      <button class="pet-switch" data-action="select-pet" aria-label="切换当前宠物">
        <div class="pet-avatar">${avatarMarkup(pet)}</div>
        <div class="pet-meta"><h2>你好呀，${pet.name}</h2><p>${pet.breed} · ${genderText(pet)}</p><span class="age-chip">🎂 ${ageText(pet.birthday)}</span></div>
        <span data-icon="down"></span>
      </button>
      ${accountSyncMarkup()}
    </section>
    <div class="content">
      <div class="section-heading"><h2>今天记点什么？</h2><span></span></div>
      <div class="quick-grid">
        ${quickAction("deworm", "capsule", "驱虫")}
        ${quickAction("vaccine", "syringe", "疫苗")}
        ${quickAction("food", "food", "主粮")}
        ${quickAction("taste", "heart", "口味")}
      </div>
      <div class="section-heading"><h2>下一件小事</h2><button class="text-button" data-route="records">全部记录</button></div>
      ${reminder ? reminderCard(pet, reminder) : `<div class="reminder-card reminder-empty"><span data-icon="bell"></span><div class="reminder-copy"><small>暂无待办</small><h3>${pet.name}还没有设置驱虫提醒</h3><p>记录驱虫时可自行填写“月/次”频次</p></div></div>`}
      <div class="section-heading"><h2>最近记录</h2><button class="text-button" data-route="records">查看全部</button></div>
      <div class="record-list">${records.length ? records.map(recordRow).join("") : emptyState("还没有记录", "点击下方加号，记下第一件小事")} </div>
    </div>
  </div>`;
}

function reminderCard(pet, record) {
  const date = new Date(record.reminderAt);
  const month = new Intl.DateTimeFormat("en-US",{month:"short"}).format(date).toUpperCase();
  const days = Math.max(0, Math.ceil((date - today) / 86400000));
  return `<button class="reminder-card" data-action="reminder-demo" aria-label="查看下一条提醒"><div class="calendar-badge"><small>${month}</small><strong>${date.getDate()}</strong></div><div class="reminder-copy"><small>距离提醒还有 ${days} 天</small><h3>${pet.name} · 下次驱虫记录提醒</h3><p>用户设置：每 ${record.frequencyMonths} 个月一次</p></div><span data-icon="chevron"></span></button>`;
}

function quickAction(type, icon, label) {
  return `<button class="quick-action" data-action="add-record" data-type="${type}" aria-label="新增${label}记录"><span class="quick-icon" data-icon="${icon}"></span><span>${label}</span></button>`;
}

function recordRow(record) {
  const meta = typeMeta[record.type];
  const media = record.photo
    ? `<button class="record-photo has-photo" data-action="view-record-photo" data-id="${record.id}" aria-label="查看${record.title}的产品大图"><img src="${record.photo}" alt="${record.title}的产品照片" /></button>`
    : `<span class="record-photo empty ${record.type}" aria-label="本条记录暂无产品照片，显示${meta.label}图标"><span data-icon="${meta.icon}"></span></span>`;
  return `<article class="record-row">${media}<button class="record-body" data-action="record-detail" data-id="${record.id}"><span class="record-copy"><h3>${record.title}</h3><p>${record.detail}</p></span><time datetime="${record.date}">${formatDate(record.date)}</time></button></article>`;
}

function emptyState(title, copy) {
  return `<div class="empty-state"><div class="empty-icon" data-icon="paw"></div><h3>${title}</h3><p>${copy}</p></div>`;
}

function renderRecords() {
  const pet = activePet();
  const records = state.records.filter(r => r.petId === pet.id && (state.filter === "all" || r.type === state.filter));
  const filters = [["all","全部"],["deworm","驱虫"],["vaccine","疫苗"],["food","主粮"],["taste","口味"]];
  return `<div class="page">
    <header class="page-header"><div class="page-header-row"><div><h1>生活记录</h1><p>每一笔都按时间温柔收好</p></div></div>${pagePetSwitcher(pet,"记录")}</header>
    <div class="filter-scroll">${filters.map(([key,label]) => `<button class="filter-chip ${state.filter===key?"active":""}" data-action="filter" data-filter="${key}">${label}</button>`).join("")}</div>
    <div class="record-page-list">${records.length ? records.map(recordRow).join("") : emptyState("这里还是空的", "换个分类，或新增一条记录吧")}</div>
  </div>`;
}

function renderRanking() {
  const pet = activePet();
  const items = state.tastes.filter(t => t.petId === pet.id).sort((a,b) => b.rating-a.rating);
  const redItems = items.filter(item => Number(item.rating) >= 3);
  const blackItems = items.filter(item => Number(item.rating) < 3).sort((a,b) => a.rating-b.rating);
  const average = items.length ? (items.reduce((s,x)=>s+x.rating,0)/items.length).toFixed(1) : "0.0";
  return `<div class="page">
    <header class="page-header"><div class="page-header-row"><div><h1>口味榜</h1><p>3 星及以上红榜 · 3 星以下黑榜</p></div><button class="icon-button" data-action="add-record" data-type="taste" aria-label="新增口味评分"><span data-icon="plus"></span></button></div>${pagePetSwitcher(pet,"口味榜")}</header>
    <div class="ranking-summary"><div><h2>尝过 ${items.length} 种美味</h2><p>平均评分 ${average} / 5 · 支持半星</p></div><div class="ranking-counts"><span class="red">红 ${redItems.length}</span><span class="black">黑 ${blackItems.length}</span></div></div>
    <div class="taste-toolbar"><span>展示方式</span><div class="view-switch" role="group" aria-label="口味榜展示方式"><button class="${state.rankingView === "list" ? "active" : ""}" data-action="ranking-view" data-view="list" aria-pressed="${state.rankingView === "list"}">列表</button><button class="${state.rankingView === "gallery" ? "active" : ""}" data-action="ranking-view" data-view="gallery" aria-pressed="${state.rankingView === "gallery"}">大图</button></div></div>
    <div class="taste-sections ${state.rankingView}">${tasteRankingSection("red", "红榜", "3 星及以上", redItems)}${tasteRankingSection("black", "黑榜", "3 星以下", blackItems)}</div>
  </div>`;
}

function tasteRankingSection(kind, title, rule, items) {
  return `<section class="taste-section ${kind}" aria-labelledby="taste-${kind}-title"><div class="taste-section-heading"><span class="list-mark" aria-hidden="true">${kind === "red" ? "♥" : "●"}</span><div><h2 id="taste-${kind}-title">${title}<small>${items.length}</small></h2><p>${rule}</p></div></div>${items.length ? `<div class="taste-collection">${items.map(item => tasteRankingItem(item, kind)).join("")}</div>` : `<div class="taste-section-empty">${kind === "red" ? "还没有进入红榜的食物" : "目前没有黑榜记录"}</div>`}</section>`;
}

function tasteRankingItem(item, kind) {
  const media = item.photo
    ? `<button class="taste-photo has-photo" data-action="view-taste-photo" data-id="${item.id}" aria-label="查看${item.product}的大图"><img src="${item.photo}" alt="${item.product}的产品照片" /></button>`
    : `<div class="taste-photo empty" aria-label="暂无产品照片，显示口味记录图标"><span aria-hidden="true">${item.emoji || "🥫"}</span></div>`;
  return `<article class="taste-card ${kind}">${media}<button class="taste-info" data-action="taste-detail" data-id="${item.id}"><span class="ranking-badge ${kind}">${kind === "red" ? "红榜" : "黑榜"}</span><h3>${item.product}</h3><p>${item.brand} · ${item.category}</p><span class="stars">${starMarkup(item.rating)}</span><strong class="rating-value">${Number(item.rating).toFixed(1)}</strong></button></article>`;
}

function pagePetSwitcher(pet, pageName) {
  return `<button class="page-pet-switch" data-action="select-pet" aria-label="当前是${pet.name}的${pageName}，点击切换宠物"><span class="page-pet-avatar">${avatarMarkup(pet)}</span><span class="page-pet-copy"><small>当前宠物</small><strong>${pet.name}</strong><span>${pet.breed} · ${genderText(pet)}</span></span><span class="switch-label">切换</span><span data-icon="down"></span></button>`;
}

function renderPets() {
  return `<div class="page">
    <header class="page-header"><div class="page-header-row"><div><h1>宠物档案</h1><p>先选择宠物，再开始记录</p></div><button class="icon-button" data-action="open-info" aria-label="隐私与记录说明"><span data-icon="shield"></span></button></div></header>
    <div class="pets-list">${state.pets.map(pet => `<article class="pet-card"><button class="pet-card-main" data-action="activate-pet" data-id="${pet.id}" aria-label="选择${pet.name}"><div class="pet-avatar">${avatarMarkup(pet)}</div><div><h3>${pet.name}</h3><p>${pet.breed} · ${genderText(pet)}</p><p>${neuterText(pet)} · ${ageText(pet.birthday)}</p></div></button><div class="pet-card-side">${pet.id===state.activePetId?'<span class="selected-check" data-icon="check" aria-label="当前宠物"></span>':''}<button class="pet-edit" data-action="edit-pet" data-id="${pet.id}">编辑</button></div></article>`).join("")}
      <button class="pet-card add-pet-card" data-action="add-pet"><span data-icon="plus"></span>新建宠物档案</button>
    </div>
    <div class="disclaimer"><span data-icon="shield"></span><span>本应用仅用于保存用户主动录入的生活记录，不提供医疗建议、判断、提醒周期建议或任何专业看法。涉及健康问题请咨询专业兽医。</span></div>
  </div>`;
}

function openSheet(content, title = "") {
  sheetRoot.innerHTML = `<div class="sheet-backdrop"><section class="sheet" role="dialog" aria-modal="true" aria-label="${title}"><div class="sheet-handle"></div>${content}</section></div>`;
  hydrateIcons(sheetRoot);
}
function titlebar(title) { return `<div class="sheet-titlebar"><h2>${title}</h2><button class="close-button" data-action="close-sheet" aria-label="关闭"><span data-icon="close"></span></button></div>`; }
function closeSheet() { sheetRoot.innerHTML = ""; state.photoData = ""; }

function openPhotoViewer(src, title) {
  if (!src) { toast("这条记录还没有照片"); return; }
  sheetRoot.innerHTML = `<div class="photo-lightbox" role="dialog" aria-modal="true" aria-label="查看产品大图"><div class="photo-lightbox-bar"><strong>${title}</strong><button class="close-button" data-action="close-sheet" aria-label="关闭大图"><span data-icon="close"></span></button></div><img src="${src}" alt="${title}的产品大图" /></div>`;
  hydrateIcons(sheetRoot);
}

function openTypeSheet() {
  openSheet(`${titlebar("新增一条记录")}<div class="record-types">
    ${recordType("deworm","capsule","驱虫记录")}${recordType("vaccine","syringe","疫苗记录")}${recordType("food","food","主粮记录")}${recordType("taste","heart","口味评分")}
  </div>`, "选择记录类型");
}
function recordType(type, icon, label) { return `<button class="record-type" data-action="add-record" data-type="${type}"><span class="quick-icon" data-icon="${icon}"></span><span>${label}</span></button>`; }

function petField() {
  const selectedID = state.recordDraft?.petId || state.activePetId;
  return `<div class="field"><label for="record-pet">记录给谁</label><select id="record-pet" name="petId" aria-label="选择这条记录所属的宠物">${state.pets.map(pet => `<option value="${pet.id}" ${pet.id === selectedID ? "selected" : ""}>${pet.name} · ${pet.species} · ${pet.breed}</option>`).join("")}</select><small class="field-hint">可直接选择其它宠物，不会切换当前页面或清空表单</small></div>`;
}
function photoField(kind = "product", existingPhoto = "") {
  const isAvatar = kind === "avatar";
  return `<div class="field"><span class="field-label">${isAvatar ? "宠物头像" : "产品照片（可选）"}</span><button type="button" class="photo-picker" data-action="pick-photo"><span data-icon="camera"></span><span>拍照或从相册选择</span><small>${isAvatar ? "将作为宠物档案头像显示" : "保存后显示为记录缩略图 · 点击可查看大图"}</small></button><div id="photo-preview-wrap">${existingPhoto ? `<img class="photo-preview" src="${existingPhoto}" alt="当前宠物头像预览" />` : ""}</div></div>`;
}
function reminderField() {
  return `<div class="toggle-row"><div class="toggle-copy"><strong>开启下次提醒</strong><small>正式版使用 iOS 本地通知</small></div><button type="button" class="toggle on" data-action="toggle" aria-label="切换下次提醒"></button></div>`;
}
function dewormReminderField(draft = {}) {
  const enabled = draft.reminderEnabled === "true";
  return `<div class="reminder-settings"><div class="toggle-row"><div class="toggle-copy"><strong>设置下次驱虫提醒</strong><small>频次完全由你自行决定</small></div><button type="button" class="toggle ${enabled ? "on" : ""}" data-action="toggle-reminder" aria-label="开启下次驱虫提醒" aria-pressed="${enabled}"></button><input type="hidden" name="reminderEnabled" value="${enabled}" /></div><div class="field reminder-frequency ${enabled ? "" : "is-hidden"}"><label for="deworm-frequency">驱虫频次（用户自定）</label><div class="input-with-suffix"><input id="deworm-frequency" name="frequencyMonths" type="number" min="1" max="120" step="1" inputmode="numeric" placeholder="填写月数" value="${escapeAttr(draft.frequencyMonths || "")}" ${enabled ? "required" : "disabled"} /><span>月/次</span></div><div id="deworm-reminder-preview" class="calculation-preview">开启后填写月数，将根据本次驱虫日期计算提醒日期</div></div></div>`;
}
function boundaryNote() { return `<div class="form-note"><span data-icon="info"></span><span>仅保存你输入的记录；不根据名称、日期或针次提供医疗建议与判断。</span></div>`; }

function openRecordForm(type, preserveDraft = false) {
  if (!preserveDraft) state.recordDraft = null;
  state.rating = 4.5;
  const forms = { deworm: dewormForm, vaccine: vaccineForm, food: foodForm, taste: tasteForm };
  openSheet(forms[type](), `新增${typeMeta[type].label}记录`);
}

function dewormForm() {
  const draft = state.recordDraft?.type === "deworm" ? state.recordDraft : {};
  const selectedScope = draft.scope || "内驱";
  return `${titlebar("记录一次驱虫")}<form class="form-stack" data-form="deworm">
    ${petField()}
    <div class="field"><span class="field-label">驱虫药</span><button type="button" class="select-like" data-action="pick-drug"><span id="drug-label">${draft.drug || "搜索或选择药品"}</span><span data-icon="chevron"></span></button><input type="hidden" name="drug" id="drug-value" value="${escapeAttr(draft.drug || "")}" required /></div>
    <div class="field"><span class="field-label">驱虫类型</span><div class="segmented three">${["内驱","外驱","内外同驱"].map(x=>`<button type="button" class="segment ${x===selectedScope?"active":""}" data-action="segment" data-value="${x}">${x}</button>`).join("")}</div><input type="hidden" name="scope" value="${selectedScope}" /></div>
    <div class="two-columns"><div class="field"><label for="deworm-date">使用日期</label><input id="deworm-date" name="date" type="date" value="${draft.date || iso(today)}" required /></div><div class="field"><label for="deworm-price">购买价格</label><input id="deworm-price" name="price" type="number" min="0" step="0.01" placeholder="¥ 0.00" value="${escapeAttr(draft.price || "")}" /></div></div>
    ${photoField()}${dewormReminderField(draft)}${boundaryNote()}<button class="primary-button" type="submit">保存驱虫记录</button>
  </form>`;
}

function vaccineForm() {
  const now = new Date(Date.now() - new Date().getTimezoneOffset()*60000).toISOString().slice(0,16);
  return `${titlebar("记录一次疫苗")}<form class="form-stack" data-form="vaccine">
    ${petField()}
    <div class="field"><label for="vaccine-name">疫苗名称</label><input id="vaccine-name" name="name" placeholder="如：疫苗名称或简称" required /></div>
    <div class="two-columns"><div class="field"><label for="vaccine-time">注射时间</label><input id="vaccine-time" name="date" type="datetime-local" value="${now}" required /></div><div class="field"><label for="vaccine-dose">第几针</label><input id="vaccine-dose" name="dose" type="number" min="1" step="1" value="1" required /></div></div>
    ${photoField()}${reminderField()}${boundaryNote()}<button class="primary-button" type="submit">保存疫苗记录</button>
  </form>`;
}

function foodForm() {
  return `${titlebar("记录一袋主粮")}<form class="form-stack" data-form="food">
    ${petField()}<div class="field"><label for="food-name">主粮名称</label><input id="food-name" name="name" placeholder="品牌 + 产品名称" required /></div>
    <div class="two-columns"><div class="field"><label for="food-weight">单包规格（kg）</label><input id="food-weight" name="weight" type="number" min="0" step="0.01" placeholder="1.5" required /></div><div class="field"><label for="food-price">购买价格</label><input id="food-price" name="price" type="number" min="0" step="0.01" placeholder="¥ 0.00" required /></div></div>
    <div class="field"><label for="food-buy">购买日期</label><input id="food-buy" name="buyDate" type="date" value="${iso(today)}" required /></div>
    <div class="two-columns"><div class="field"><label for="food-start">开始吃</label><input id="food-start" name="startDate" type="date" /></div><div class="field"><label for="food-end">吃完日期</label><input id="food-end" name="endDate" type="date" /></div></div>
    <div id="food-calculation" class="form-note"><span data-icon="info"></span><span>填写开始和吃完日期后，自动计算食用天数、每日成本与日均消耗。</span></div>
    ${photoField()}<button class="primary-button" type="submit">保存主粮记录</button>
  </form>`;
}

function tasteForm() {
  return `${titlebar("记下这次口味")}<form class="form-stack" data-form="taste">
    ${petField()}<div class="two-columns"><div class="field"><label for="taste-brand">食物品牌</label><input id="taste-brand" name="brand" placeholder="品牌" required /></div><div class="field"><label for="taste-product">产品名称</label><input id="taste-product" name="product" placeholder="口味/名称" required /></div></div>
    <div class="field"><label for="taste-category">类别</label><input id="taste-category" name="category" list="taste-categories" placeholder="选择或自行输入" required /><datalist id="taste-categories"><option>主食罐</option><option>零食罐</option><option>猫条</option><option>冻干</option><option>汤包</option><option>湿粮包</option><option>肉干</option><option>其它</option></datalist></div>
    <div class="field"><span class="field-label">${activePet().name}有多喜欢？</span><div class="star-picker">${[1,2,3,4,5].map(i=>`<button type="button" class="star-control ${i<=4?"filled":i===5?"half":""}" data-action="rate" data-star="${i}" aria-label="${i}星"><span data-icon="star"></span></button>`).join("")}<span class="score-readout">4.5 星</span></div><input type="hidden" name="rating" value="4.5" /></div>
    ${photoField()}<button class="primary-button" type="submit">保存到口味榜</button>
  </form>`;
}

function openPetSelector() {
  openSheet(`${titlebar("这次记录给谁？")}<div class="option-list">${state.pets.map(p => `<button class="option-row ${p.id===state.activePetId?"selected":""}" data-action="choose-pet" data-id="${p.id}"><span style="font-size:26px">${p.avatar}</span><span><strong>${p.name}</strong><small>${p.breed} · ${genderText(p)} · ${ageText(p.birthday)}</small></span>${p.id===state.activePetId?'<span data-icon="check"></span>':''}</button>`).join("")}<button class="option-row custom-add" data-action="add-pet"><span data-icon="plus"></span>新建宠物档案</button></div>`, "选择宠物");
}

function openDrugPicker() {
  const form = document.querySelector('form[data-form="deworm"]');
  const values = form ? Object.fromEntries(new FormData(form)) : {};
  const selectedPet = state.pets.find(pet => pet.id === values.petId) || activePet();
  state.recordDraft = { type:"deworm", ...values, petId:selectedPet.id, photoData:state.photoData };
  state.drugSpeciesFilter = selectedPet.species;
  state.drugScopeFilter = "全部";
  const initialItems = filteredDewormers("", state.drugSpeciesFilter, state.drugScopeFilter);
  openSheet(`${titlebar("选择驱虫药")}<div class="drug-pet-context"><span>${selectedPet.avatar || "🐾"}</span><span><strong>正在给${selectedPet.name}记录</strong><small>${selectedPet.species} · 默认显示${selectedPet.species}用药品</small></span></div><div class="segmented drug-species-tabs" aria-label="按宠物种类筛选"><button type="button" class="segment ${state.drugSpeciesFilter === "猫" ? "active" : ""}" data-action="drug-species" data-value="猫">猫用</button><button type="button" class="segment ${state.drugSpeciesFilter === "狗" ? "active" : ""}" data-action="drug-species" data-value="狗">狗用</button></div><div class="drug-scope-tabs" role="group" aria-label="按驱虫类型筛选">${["全部","内驱","外驱","内外同驱"].map(scope => `<button type="button" class="scope-chip ${scope === state.drugScopeFilter ? "active" : ""}" data-action="drug-scope" data-value="${scope}">${scope}</button>`).join("")}</div><div class="search-box"><span data-icon="search"></span><input id="drug-search" placeholder="在${drugFilterLabel()}中搜索" autocomplete="off" /></div><div id="drug-options" class="option-list">${drugOptions(initialItems)}</div><p class="source-caption">列表依据新增页选择的宠物显示，不会切换当前页面宠物。名称仅供记录和检索，不构成使用建议。</p>`, "选择驱虫药");
  document.querySelector("#drug-search")?.focus();
}
function drugOptions(items) {
  const rows = items.map(d=>`<button class="option-row" data-action="choose-drug" data-index="${dewormers.indexOf(d)}"><span><strong>${d.name}（${d.brand}）</strong><small>${d.scope}</small></span><span class="species-badge ${d.species === "猫/狗" ? "shared" : ""}">${d.species === "猫/狗" ? "猫狗通用" : `${d.species}用`}</span><span data-icon="chevron"></span></button>`).join("");
  return (rows || `<div class="inline-empty">当前分区没有匹配的药品</div>`) + `<button class="option-row custom-add" data-action="custom-drug"><span data-icon="plus"></span>添加新的${state.drugSpeciesFilter}用药品名称</button>`;
}

function drugFilterLabel() {
  return `${state.drugSpeciesFilter}用${state.drugScopeFilter === "全部" ? "药品" : state.drugScopeFilter}`;
}

function filteredDewormers(query = "", species = state.drugSpeciesFilter, scope = state.drugScopeFilter) {
  const q = query.trim().toLowerCase();
  return dewormers.filter(d => (d.species === species || d.species === "猫/狗") && (scope === "全部" || d.scope === scope) && `${d.name}${d.brand}${d.scope}`.toLowerCase().includes(q));
}

function startPetForm(petId = null) {
  state.editingPetId = petId;
  const pet = petId ? state.pets.find(item => item.id === petId) : null;
  state.petDraft = pet ? { ...pet } : { name:"", species:"猫", gender:"未知", neuterStatus:"未知", breed:"", birthday:"", photo:"" };
  state.petSpecies = state.petDraft.species;
  state.photoData = "";
  openPetForm();
}

function capturePetDraft() {
  const form = document.querySelector('form[data-form="pet"]');
  if (!form) return;
  state.petDraft = { ...state.petDraft, ...Object.fromEntries(new FormData(form)) };
  if (state.photoData) state.petDraft.photo = state.photoData;
  state.petSpecies = state.petDraft.species;
}

function openPetForm() {
  const draft = state.petDraft || { name:"", species:"猫", gender:"未知", neuterStatus:"未知", breed:"", birthday:"", photo:"" };
  const isCat = draft.species === "猫";
  const title = state.editingPetId ? "编辑宠物档案" : "新建宠物档案";
  openSheet(`${titlebar(title)}<form class="form-stack" data-form="pet">
    <div class="field"><label for="pet-name">宠物名称</label><input id="pet-name" name="name" value="${escapeAttr(draft.name)}" placeholder="毛孩子叫什么？" required /></div>
    <div class="field"><span class="field-label">种类</span><div class="segmented"><button type="button" class="segment ${isCat?"active":""}" data-action="species" data-value="猫">猫咪</button><button type="button" class="segment ${isCat?"":"active"}" data-action="species" data-value="狗">狗狗</button></div><input type="hidden" name="species" value="${draft.species}" /></div>
    <div class="field"><span class="field-label">性别</span><div class="segmented three">${["公","母","未知"].map(value => `<button type="button" class="segment ${draft.gender===value?"active":""}" data-action="segment" data-value="${value}">${value}</button>`).join("")}</div><input type="hidden" name="gender" value="${draft.gender}" /></div>
    <div class="field"><span class="field-label">绝育状态</span><div class="segmented three">${["已绝育","未绝育","未知"].map(value => `<button type="button" class="segment ${draft.neuterStatus===value?"active":""}" data-action="segment" data-value="${value}">${value}</button>`).join("")}</div><input type="hidden" name="neuterStatus" value="${draft.neuterStatus}" /></div>
    <div class="field"><span class="field-label">品种</span><button type="button" class="select-like" data-action="pick-breed"><span id="breed-label">${draft.breed || "搜索或选择品种"}</span><span data-icon="chevron"></span></button><input type="hidden" name="breed" id="breed-value" value="${escapeAttr(draft.breed)}" required /></div>
    <div class="field"><label for="pet-birthday">生日</label><input id="pet-birthday" name="birthday" type="date" value="${draft.birthday || ""}" max="${iso(today)}" required /></div>
    ${photoField("avatar",draft.photo)}<button class="primary-button" type="submit">${state.editingPetId ? "更新宠物档案" : "保存宠物档案"}</button>
  </form>`, title);
}

function openBreedPicker(species = "猫") {
  const list = species === "狗" ? dogBreeds : catBreeds;
  openSheet(`${titlebar(`选择${species}的品种`)}<div class="search-box"><span data-icon="search"></span><input id="breed-search" data-species="${species}" placeholder="搜索英短、泰迪、柯基或英文名" autocomplete="off" /></div><div id="breed-options" class="option-list">${breedOptions(list.slice(0,80), species)}</div><p class="source-caption">优先使用中国大陆常见中文名和简称检索，同时保留国际注册名称；本地类型、混种或不确定品种也可以直接选择。</p>`, "选择宠物品种");
}
function breedOptions(items, species) {
  return items.map(b => { const aliases = chinaBreedAliases[b.en] || []; const sub = [b.zh ? b.en : "中文译名待核对", aliases.length ? `国内常用：${aliases.join("、")}` : ""].filter(Boolean).join(" · "); return `<button class="option-row" data-action="choose-breed" data-value="${b.zh || b.en}"><span><strong>${b.zh || b.en}</strong><small>${sub}</small></span><span data-icon="chevron"></span></button>`; }).join("") + `<button class="option-row custom-add" data-action="choose-breed" data-value="其它 / 不确定 / 混种"><span data-icon="plus"></span>其它 / 不确定 / 混种</button>`;
}

function breedMatches(breed, query) {
  return `${breed.zh || ""} ${breed.en || ""} ${(chinaBreedAliases[breed.en] || []).join(" ")}`.toLowerCase().includes(query);
}

function openInfo() {
  openSheet(`${titlebar("安心记录，边界清楚")}<div class="form-stack">
    <div class="toggle-row"><div class="toggle-copy"><strong>Supabase 私有云端档案</strong><small>正式版按账号隔离数据与照片</small></div><span data-icon="cloud" style="width:24px;color:var(--sage)"></span></div>
    <div class="toggle-row"><div class="toggle-copy"><strong>相机与相册</strong><small>仅在你主动拍照或选图时请求权限</small></div><span data-icon="camera" style="width:24px;color:var(--honey-dark)"></span></div>
    <div class="disclaimer" style="margin:0"><span data-icon="shield"></span><span><strong>仅供记录</strong><br />本应用不提供建议、看法或判断，尤其不提供任何医疗建议。提醒时间完全由用户自行设置；疫苗针次与驱虫药名称也仅按用户输入保存。</span></div>
    <button class="primary-button" data-action="close-sheet">我知道了</button>
  </div>`, "记录与隐私说明");
}

function openAccountCenter() {
  if (state.account?.bound) {
    const metrics = accountMetrics();
    openSheet(`${titlebar("账号与云端备份")}<div class="form-stack">
      <section class="account-hero bound"><span class="account-hero-icon" data-icon="cloud"></span><div><span class="status-badge demo">原型绑定演示</span><h3>本机记录已关联账号</h3><p>正式接入后，删除或更换设备时，使用同一账号登录即可从 Supabase 恢复记录与照片。</p></div></section>
      <div class="account-identity"><span class="account-avatar" data-icon="user"></span><span><small>当前演示账号</small><strong>${escapeAttr(state.account.email)}</strong></span><span class="account-provider">${state.account.provider === "apple" ? "Apple" : "邮箱"}</span></div>
      <div class="account-metrics"><div><strong>${metrics.pets}</strong><span>只宠物</span></div><div><strong>${metrics.records}</strong><span>条记录</span></div><div><strong>${metrics.photos}</strong><span>张照片</span></div></div>
      <div class="sync-detail"><span class="sync-detail-icon" data-icon="cloud"></span><span><strong>最近同步演示</strong><small>${syncTimeText(state.account.lastSync)}</small></span></div>
      <button class="primary-button" data-action="account-sync">立即同步（演示）</button>
      <button class="secondary-button" data-action="account-signout-demo">退出演示账号</button>
      <p class="prototype-warning">当前页面只演示账号和恢复流程，数据仍保存在此浏览器。接入真实 Supabase 后才具备卸载 App 后恢复数据的能力。</p>
    </div>`, "账号与云端备份");
    return;
  }
  openSheet(`${titlebar("账号与云端备份")}<div class="form-stack">
    <section class="account-hero"><span class="account-hero-icon" data-icon="cloud"></span><div><span class="status-badge local">尚未连接真实云端</span><h3>给本机记录绑定一个账号</h3><p>正式版注册成功后，会将现有宠物、生活记录和照片上传到你的私有云端档案。</p></div></section>
    <div class="account-benefits"><div><span data-icon="check"></span><span><strong>删除后仍可恢复</strong><small>重新安装后登录同一账号，下载云端数据</small></span></div><div><span data-icon="shield"></span><span><strong>每位用户独立保存</strong><small>数据库与照片均按账号隔离访问</small></span></div><div><span data-icon="cloud"></span><span><strong>先绑定，再持续同步</strong><small>本地记录在首次绑定时安全迁移</small></span></div></div>
    <button class="primary-button" data-action="account-register">注册并绑定本机数据</button>
    <button class="secondary-button" data-action="account-login">已有账号，登录恢复</button>
    <button class="apple-button" data-action="account-apple"><span class="apple-mark"></span> 使用 Apple 登录 / 注册</button>
    <p class="prototype-warning">原型不会发送邮箱、密码或记录。待提供 Supabase 项目地址与公开密钥后再接入真实注册、上传和恢复。</p>
  </div>`, "账号与云端备份");
}

function openAccountForm(mode) {
  const registering = mode === "register";
  openSheet(`${titlebar(registering ? "注册并绑定" : "登录并恢复")}<form class="form-stack" data-form="account" data-mode="${mode}">
    <div class="account-form-intro"><span data-icon="${registering ? "cloud" : "user"}"></span><span><strong>${registering ? "绑定当前本机数据" : "恢复已有云端档案"}</strong><small>${registering ? "注册完成后上传当前宠物、记录与照片" : "登录后以云端档案恢复宠物和记录"}</small></span></div>
    <div class="field"><label for="account-email">邮箱</label><input id="account-email" name="email" type="email" autocomplete="email" placeholder="name@example.com" required /></div>
    <div class="field"><label for="account-password">密码</label><input id="account-password" name="password" type="password" autocomplete="${registering ? "new-password" : "current-password"}" minlength="8" placeholder="至少 8 位" required /></div>
    ${registering ? '<div class="field"><label for="account-password-confirm">确认密码</label><input id="account-password-confirm" name="passwordConfirm" type="password" autocomplete="new-password" minlength="8" placeholder="再次输入密码" required /></div><label class="consent-row"><input name="consent" type="checkbox" required /><span>我已阅读并同意未来正式版的用户协议与隐私政策</span></label>' : ""}
    <button class="primary-button" type="submit">${registering ? "注册并绑定本机数据" : "登录并恢复数据"}</button>
    <p class="prototype-warning">这是交互原型：提交仅保存演示邮箱和绑定状态，不会保存密码，也不会连接云端。</p>
  </form>`, registering ? "注册并绑定" : "登录并恢复");
}

function handleSubmit(form) {
  const data = Object.fromEntries(new FormData(form));
  const type = form.dataset.form;
  if (type === "account") {
    if (form.dataset.mode === "register" && data.password !== data.passwordConfirm) {
      const confirm = form.querySelector('[name="passwordConfirm"]');
      confirm.setCustomValidity("两次输入的密码不一致"); confirm.reportValidity();
      confirm.addEventListener("input", () => confirm.setCustomValidity(""), { once:true });
      return;
    }
    state.account = { bound:true, email:data.email.trim(), provider:"email", lastSync:new Date().toISOString() };
    saveState(); closeSheet(); render(); toast(form.dataset.mode === "register" ? "账号绑定流程演示完成" : "云端恢复流程演示完成");
    return;
  }
  if (type === "pet") {
    const editing = Boolean(state.editingPetId);
    const values = { name:data.name, species:data.species, gender:data.gender, neuterStatus:data.neuterStatus, breed:data.breed, birthday:data.birthday, avatar:data.species === "狗" ? "🐶" : "🐱", photo:state.photoData || state.petDraft?.photo || "" };
    let pet;
    if (state.editingPetId) { pet = state.pets.find(item => item.id === state.editingPetId); Object.assign(pet, values); }
    else { pet = { id:uid(), ...values }; state.pets.push(pet); }
    state.activePetId = pet.id; saveState(); closeSheet(); state.petDraft=null; state.editingPetId=null; state.route="pets"; render(); toast(editing ? "宠物档案已更新" : "宠物档案已保存"); return;
  }
  const recordPetId = data.petId || state.activePetId;
  let record;
  if (type === "deworm") {
    const reminderEnabled = data.reminderEnabled === "true";
    const frequencyMonths = reminderEnabled ? Number(data.frequencyMonths) : null;
    const reminderAt = reminderEnabled ? addMonths(data.date, frequencyMonths) : null;
    record = { title: data.drug || "自定义驱虫药", detail: `${data.scope} · ¥${Number(data.price||0).toFixed(2)}${frequencyMonths ? ` · 每 ${frequencyMonths} 月提醒` : ""}`, date: data.date, frequencyMonths, reminderAt };
  }
  if (type === "vaccine") record = { title: `${data.name} · 第 ${data.dose} 针`, detail: "已保存注射时间", date: data.date };
  if (type === "food") {
    const days = data.startDate && data.endDate ? Math.max(1, Math.round((new Date(data.endDate)-new Date(data.startDate))/86400000)+1) : null;
    record = { title: data.name, detail: `${data.weight} kg${days?` · 食用了 ${days} 天`:" · 尚未吃完"}`, date: data.buyDate, price:Number(data.price), weight:Number(data.weight), days };
  }
  if (type === "taste") {
    record = { title: `${data.brand} ${data.product}`, detail: `${data.category} · ${data.rating} 星`, date: iso(today), rating:Number(data.rating) };
    state.tastes.push({ id:uid(), petId:recordPetId, brand:data.brand, product:data.product, category:data.category, rating:Number(data.rating), emoji:"🥫", photo:state.photoData });
  }
  state.records.unshift({ id:uid(), petId:recordPetId, type, ...record, photo:state.photoData });
  state.recordDraft = null; saveState(); closeSheet(); state.route = type === "taste" ? "ranking" : "records"; state.filter = "all"; render(); toast(`${typeMeta[type].label}记录已保存给${state.pets.find(pet => pet.id === recordPetId)?.name || "所选宠物"}`);
}

document.addEventListener("click", (event) => {
  if (event.target.classList.contains("photo-lightbox")) { closeSheet(); return; }
  if (event.target.classList.contains("sheet-backdrop")) { closeSheet(); return; }
  const target = event.target.closest("[data-action], [data-route]");
  if (!target) return;
  if (target.dataset.route) { state.route = target.dataset.route; render(); return; }
  const action = target.dataset.action;
  if (action === "open-add") openTypeSheet();
  if (action === "close-sheet") closeSheet();
  if (action === "add-record") openRecordForm(target.dataset.type);
  if (action === "select-pet") openPetSelector();
  if (action === "choose-pet" || action === "activate-pet") { state.activePetId = target.dataset.id; saveState(); closeSheet(); render(); toast(`已切换到${activePet().name}`); }
  if (action === "filter") { state.filter = target.dataset.filter; render(); }
  if (action === "ranking-view") { state.rankingView = target.dataset.view; render(); }
  if (action === "add-pet") startPetForm();
  if (action === "edit-pet") startPetForm(target.dataset.id);
  if (action === "open-info") openInfo();
  if (action === "open-account") openAccountCenter();
  if (action === "account-register") openAccountForm("register");
  if (action === "account-login") openAccountForm("login");
  if (action === "account-apple") toast("正式版将调用 iOS 原生 Apple 登录");
  if (action === "account-sync") { state.account.lastSync = new Date().toISOString(); saveState(); openAccountCenter(); toast("同步流程演示完成"); }
  if (action === "account-signout-demo") { state.account = { bound:false, email:"", provider:"", lastSync:"" }; saveState(); closeSheet(); render(); toast("已退出演示账号，本机记录仍保留"); }
  if (action === "pick-drug") openDrugPicker();
  if (action === "drug-species") {
    state.drugSpeciesFilter = target.dataset.value;
    target.closest(".segmented").querySelectorAll(".segment").forEach(button => button.classList.toggle("active", button === target));
    const search = document.querySelector("#drug-search");
    if (search) search.placeholder = `在${drugFilterLabel()}中搜索`;
    const options = document.querySelector("#drug-options");
    if (options) { options.innerHTML = drugOptions(filteredDewormers(search?.value || "")); hydrateIcons(options); }
  }
  if (action === "drug-scope") {
    state.drugScopeFilter = target.dataset.value;
    target.closest(".drug-scope-tabs").querySelectorAll(".scope-chip").forEach(button => button.classList.toggle("active", button === target));
    const search = document.querySelector("#drug-search");
    if (search) search.placeholder = `在${drugFilterLabel()}中搜索`;
    const options = document.querySelector("#drug-options");
    if (options) { options.innerHTML = drugOptions(filteredDewormers(search?.value || "")); hydrateIcons(options); }
  }
  if (action === "choose-drug") {
    const drug = dewormers[Number(target.dataset.index)];
    const value = `${drug.name}（${drug.brand}）`;
    state.recordDraft = { ...(state.recordDraft || {}), type:"deworm", drug:value };
    closeSheet(); openRecordForm("deworm", true);
  }
  if (action === "custom-drug") {
    const value = window.prompt("输入新的药品名称（可按“药名（简称）”格式）");
    if (value?.trim()) { state.recordDraft = { ...(state.recordDraft || {}), type:"deworm", drug:value.trim() }; closeSheet(); openRecordForm("deworm", true); }
  }
  if (action === "segment" || action === "species") {
    const group = target.closest(".segmented"); group.querySelectorAll(".segment").forEach(x=>x.classList.remove("active")); target.classList.add("active");
    const hidden = group.parentElement.querySelector('input[type="hidden"]'); if(hidden) hidden.value=target.dataset.value;
    if (action === "species") {
      const changed = state.petDraft && state.petDraft.species !== target.dataset.value;
      state.petSpecies = target.dataset.value;
      if (state.petDraft) { state.petDraft.species = target.dataset.value; if (changed) state.petDraft.breed = ""; }
      if (changed) { const breedValue=document.querySelector("#breed-value"); const breedLabel=document.querySelector("#breed-label"); if (breedValue) breedValue.value=""; if (breedLabel) breedLabel.textContent="搜索或选择品种"; }
    }
  }
  if (action === "pick-photo") photoInput.click();
  if (action === "view-record-photo") { const record=state.records.find(r=>r.id===target.dataset.id); openPhotoViewer(record?.photo, record?.title || "产品照片"); }
  if (action === "view-taste-photo") { const item=state.tastes.find(t=>t.id===target.dataset.id); openPhotoViewer(item?.photo, item?.product || "产品照片"); }
  if (action === "toggle") { target.classList.toggle("on"); target.setAttribute("aria-pressed", target.classList.contains("on")); }
  if (action === "toggle-reminder") {
    const settings = target.closest(".reminder-settings");
    const enabled = !target.classList.contains("on");
    target.classList.toggle("on", enabled); target.setAttribute("aria-pressed", String(enabled));
    settings.querySelector('input[name="reminderEnabled"]').value = String(enabled);
    const frequency = settings.querySelector(".reminder-frequency");
    const input = settings.querySelector('input[name="frequencyMonths"]');
    frequency.classList.toggle("is-hidden", !enabled); input.disabled = !enabled; input.required = enabled;
    if (!enabled) input.value = "";
    updateDewormReminderPreview();
  }
  if (action === "pick-breed") { capturePetDraft(); openBreedPicker(state.petDraft?.species || state.petSpecies); }
  if (action === "choose-breed") {
    const value = target.dataset.value; state.petDraft = { ...state.petDraft, breed:value }; closeSheet(); openPetForm();
  }
  if (action === "rate") {
    const star = Number(target.dataset.star); const rect=target.getBoundingClientRect(); const half=event.clientX-rect.left<rect.width/2; state.rating=star-(half?.5:0);
    const picker=target.closest(".star-picker"); picker.querySelectorAll(".star-control").forEach((b,i)=>{ const r=state.rating-i; b.classList.toggle("filled",r>=1); b.classList.toggle("half",r===.5); });
    picker.querySelector(".score-readout").textContent=`${state.rating.toFixed(1)} 星`; picker.parentElement.querySelector('input[name="rating"]').value=state.rating;
  }
  if (["record-detail","taste-detail","reminder-demo"].includes(action)) toast("这是原型预览，详情编辑将在下一阶段接入");
});

document.addEventListener("submit", event => { event.preventDefault(); handleSubmit(event.target); });
document.addEventListener("input", event => {
  if (event.target.id === "drug-search") {
    const q=event.target.value.trim().toLowerCase(); const items=filteredDewormers(q);
    document.querySelector("#drug-options").innerHTML=drugOptions(items); hydrateIcons(document.querySelector("#drug-options"));
  }
  if (event.target.id === "breed-search") {
    const species=event.target.dataset.species; const list=species==="狗"?dogBreeds:catBreeds; const q=event.target.value.trim().toLowerCase();
    const items=list.filter(b=>breedMatches(b,q)).slice(0,100); document.querySelector("#breed-options").innerHTML=breedOptions(items,species); hydrateIcons(document.querySelector("#breed-options"));
  }
  if (["food-start","food-end","food-price","food-weight"].includes(event.target.id)) {
    const form=event.target.form; const start=form?.startDate.value; const end=form?.endDate.value; const price=Number(form?.price.value); const weight=Number(form?.weight.value); const box=document.querySelector("#food-calculation");
    if (start&&end&&new Date(end)>=new Date(start)) { const days=Math.round((new Date(end)-new Date(start))/86400000)+1; const daily=price?`，每日约 ¥${(price/days).toFixed(2)}`:""; const grams=weight?`，日均约 ${Math.round(weight*1000/days)}g`:""; box.innerHTML=`<span data-icon="info"></span><span>共食用 <strong>${days} 天</strong>${daily}${grams}</span>`; hydrateIcons(box); }
  }
  if (["deworm-date","deworm-frequency"].includes(event.target.id)) updateDewormReminderPreview();
});

function addMonths(dateValue, months) {
  if (!dateValue || !months) return null;
  const date = new Date(`${dateValue}T12:00:00`);
  const originalDay = date.getDate();
  date.setDate(1); date.setMonth(date.getMonth() + Number(months));
  const lastDay = new Date(date.getFullYear(), date.getMonth()+1, 0).getDate();
  date.setDate(Math.min(originalDay,lastDay));
  return iso(date);
}

function updateDewormReminderPreview() {
  const preview = document.querySelector("#deworm-reminder-preview");
  const frequency = document.querySelector("#deworm-frequency");
  const date = document.querySelector("#deworm-date");
  if (!preview || !frequency || frequency.disabled) return;
  const reminderAt = addMonths(date?.value, Number(frequency.value));
  preview.innerHTML = reminderAt ? `预计提醒日期：<strong>${new Intl.DateTimeFormat("zh-CN",{year:"numeric",month:"long",day:"numeric"}).format(new Date(`${reminderAt}T12:00:00`))}</strong>` : "填写月数后自动计算下一次提醒日期";
}

photoInput.addEventListener("change", () => {
  const file=photoInput.files?.[0]; if(!file) return; const reader=new FileReader(); reader.onload=()=>{ state.photoData=reader.result; const wrap=document.querySelector("#photo-preview-wrap"); if(wrap) wrap.innerHTML=`<img class="photo-preview" src="${reader.result}" alt="所选照片预览" />`; toast("照片已加入本条记录"); }; reader.readAsDataURL(file);
});

render();
