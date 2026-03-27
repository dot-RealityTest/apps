// ============================================================
// MOCHI'S DAILY QUEST - Renderer v3.0
// Full 5-stage evolution: Egg → Baby → Teen → Mochi → Elder
// ============================================================

// ── Evolution Stages ──────────────────────────────────────
const EVOLUTION = [
  {
    id: 'egg',
    name: 'EGG',
    emoji: '🥚',
    threshold: 0,
    displayName: '✦ EGG ✦',
    // Mood sprites: keyed by happiness range
    moods: [
      { min:0,   max:50,  img:'egg_resting Background Removed',   gif:'egg_idle',   text:'A mysterious egg... something stirs inside.' },
      { min:50,  max:80,  img:'egg_cracking Background Removed',  gif:'egg_crack',  text:'The egg is wobbling! It wants to hatch!' },
      { min:80,  max:101, img:'egg_hatching Background Removed',  gif:'egg_hatch',  text:'The egg is cracking open!! 🥚✨' },
    ],
    sprites: {
      writing:     { png:'egg_resting Background Removed',  gif:'egg_idle'  },
      checkoff:    { png:'egg_hatching Background Removed', gif:'egg_hatch' },
      delete:      { png:'egg_resting Background Removed',  gif:'egg_idle'  },
      levelup:     { png:'egg_hatching Background Removed', gif:'egg_hatch' },
      celebrating: { png:'egg_hatching Background Removed', gif:'egg_hatch' },
      overwhelmed: { png:'egg_cracking Background Removed', gif:'egg_crack' },
      bored:       { png:'egg_resting Background Removed',  gif:'egg_idle'  },
    },
    bgColor: '#e8d5f5',
  },
  {
    id: 'baby',
    name: 'BABY',
    emoji: '🌱',
    threshold: 1,
    displayName: '✦ BABY MOCHI ✦',
    moods: [
      { min:0,   max:25,  img:'baby_sleeping Background Removed', gif:'baby_sleep',   text:'Baby Mochi is sleeping... zzz 💤' },
      { min:25,  max:50,  img:'baby_curious Background Removed',  gif:'baby_curious', text:'Baby Mochi is curious~ 👀' },
      { min:50,  max:75,  img:'baby_idle Background Removed',     gif:'baby_idle',    text:'Baby Mochi is doing okay! 🌸' },
      { min:75,  max:101, img:'baby_happy Background Removed',    gif:'baby_happy',   text:'Baby Mochi is SO happy!! ✨' },
    ],
    sprites: {
      writing:     { png:'baby_curious Background Removed',  gif:'baby_curious' },
      checkoff:    { png:'baby_happy Background Removed',    gif:'baby_bounce'  },
      delete:      { png:'baby_sleeping Background Removed', gif:'baby_sleep'   },
      levelup:     { png:'baby_happy Background Removed',    gif:'baby_happy'   },
      celebrating: { png:'baby_happy Background Removed',    gif:'baby_bounce'  },
      overwhelmed: { png:'baby_sleeping Background Removed', gif:'baby_sleep'   },
      bored:       { png:'baby_sleeping Background Removed', gif:'baby_sleep'   },
    },
    bgColor: '#f5d5e8',
  },
  {
    id: 'teen',
    name: 'TEEN',
    emoji: '🎒',
    threshold: 10,
    displayName: '✦ TEEN MOCHI ✦',
    moods: [
      { min:0,   max:20,  img:'teen_moody Background Removed',       gif:'teen_moody',    text:'Teen Mochi is NOT in the mood... 🌧' },
      { min:20,  max:40,  img:'teen_rebellious Background Removed',  gif:'teen_idle',     text:'Teen Mochi is being rebellious ✌️' },
      { min:40,  max:60,  img:'teen_idle Background Removed',        gif:'teen_idle',     text:'Teen Mochi is... fine. Whatever.' },
      { min:60,  max:80,  img:'teen_studying Background Removed',    gif:'teen_studying', text:'Teen Mochi is actually studying! 📚' },
      { min:80,  max:101, img:'teen_excited Background Removed',     gif:'teen_dancing',  text:'Teen Mochi is HYPED!! 🎉' },
    ],
    sprites: {
      writing:     { png:'teen_studying Background Removed',   gif:'teen_studying' },
      checkoff:    { png:'teen_excited Background Removed',    gif:'teen_excited'  },
      delete:      { png:'teen_rebellious Background Removed', gif:'teen_idle'     },
      levelup:     { png:'teen_excited Background Removed',    gif:'teen_dancing'  },
      celebrating: { png:'teen_excited Background Removed',    gif:'teen_dancing'  },
      overwhelmed: { png:'teen_moody Background Removed',      gif:'teen_moody'    },
      bored:       { png:'teen_phone Background Removed',      gif:'teen_phone'    },
    },
    bgColor: '#ffe5f0',
  },
  {
    id: 'mochi',
    name: 'MOCHI',
    emoji: '🌸',
    threshold: 30,
    displayName: '✦ MOCHI ✦',
    moods: [
      { min:0,   max:15,  img:'mochi_crying Background Removed',        gif:null,           text:'Mochi is crying... 😭' },
      { min:15,  max:30,  img:'mochi_sick Background Removed',          gif:null,           text:'Mochi is very sad...' },
      { min:30,  max:45,  img:'creature_sad',                           gif:null,           text:'Mochi needs love...' },
      { min:45,  max:55,  img:'mochi_thinking Background Removed',      gif:null,           text:'Mochi is thinking... 🤔' },
      { min:55,  max:65,  img:'creature_happy',                         gif:null,           text:'Mochi is okay~ 🌸' },
      { min:65,  max:75,  img:'creature_happy',                         gif:null,           text:'Mochi is happy! ✨' },
      { min:75,  max:85,  img:'mochi_love Background Removed',          gif:null,           text:'Mochi loves you! 💖' },
      { min:85,  max:95,  img:'mochi_dancing Background Removed',       gif:null,           text:'Mochi is dancing! 💃' },
      { min:95,  max:101, img:'mochi_celebrating Background Removed',   gif:null,           text:'MOCHI IS OVERJOYED!! 🎉' },
    ],
    sprites: {
      writing:     { png:'mochi_writing Background Removed',     gif:null },
      checkoff:    { png:'mochi_checkoff Background Removed',    gif:null },
      delete:      { png:'mochi_delete_task Background Removed', gif:null },
      levelup:     { png:'mochi_levelup Background Removed',     gif:null },
      celebrating: { png:'mochi_celebrating Background Removed', gif:null },
      overwhelmed: { png:'mochi_overwhelmed Background Removed', gif:null },
      bored:       { png:'mochi_bored Background Removed',       gif:null },
    },
    bgColor: '#e8d5f5',
  },
  {
    id: 'elder',
    name: 'ELDER',
    emoji: '👵',
    threshold: 75,
    displayName: '✦ ELDER MOCHI ✦',
    moods: [
      { min:0,   max:25,  img:'elder_sleepy Background Removed',      text:'Elder Mochi is resting... 💤' },
      { min:25,  max:50,  img:'elder_idle Background Removed',         text:'Elder Mochi is at peace~ 🌿' },
      { min:50,  max:75,  img:'elder_wise Background Removed',         text:'Elder Mochi is feeling wise! ✨' },
      { min:75,  max:90,  img:'elder_proud Background Removed',        text:'Elder Mochi is so proud of you! 💛' },
      { min:90,  max:101, img:'elder_meditating Background Removed',   text:'Elder Mochi has reached enlightenment!! 🌟' },
    ],
    moods: [
      { min:0,   max:25,  img:'elder_sleepy Background Removed',      gif:'elder_rocking',     text:'Elder Mochi is resting... 💤' },
      { min:25,  max:50,  img:'elder_idle Background Removed',         gif:'elder_idle',        text:'Elder Mochi is at peace~ 🌿' },
      { min:50,  max:75,  img:'elder_wise Background Removed',         gif:'elder_meditating',  text:'Elder Mochi is feeling wise! ✨' },
      { min:75,  max:90,  img:'elder_proud Background Removed',        gif:'elder_proud',       text:'Elder Mochi is so proud of you! 💛' },
      { min:90,  max:101, img:'elder_meditating Background Removed',   gif:'elder_meditating',  text:'Elder Mochi has reached enlightenment!! 🌟' },
    ],
    sprites: {
      writing:     { png:'elder_wise Background Removed',        gif:'elder_meditating' },
      checkoff:    { png:'elder_proud Background Removed',       gif:'elder_proud'      },
      delete:      { png:'elder_idle Background Removed',        gif:'elder_idle'       },
      levelup:     { png:'elder_legacy Background Removed',      gif:'elder_legacy'     },
      celebrating: { png:'elder_legacy Background Removed',      gif:'elder_legacy'     },
      overwhelmed: { png:'elder_sleepy Background Removed',      gif:'elder_rocking'    },
      bored:       { png:'elder_storytelling Background Removed', gif:'elder_rocking'   },
    },
    bgColor: '#fff3e0',
  },
];

// ── State ────────────────────────────────────────────────
let state = {
  happiness: 50,
  tasks: [],
  lastReset: new Date().toDateString(),
  totalCompleted: 0,
  creatureName: 'Mochi',
  xp: 0,
  level: 1,
  xpToNext: 100,
  streak: 0,
  lastActiveDay: new Date().toDateString(),
  rewards: [],
  currentRoom: 0,
  lampOn: true,
  plantLevel: 0,
  snackCooldown: 0,
  evolutionStage: 0,   // 0=egg 1=baby 2=teen 3=mochi 4=elder
  hasHatched: false,   // egg → baby transition flag
};

// ── Room backgrounds ──────────────────────────────────────
const ROOMS = [
  { bg:'assets/room_study.png',             name:'Study Room',       emoji:'📚', unlockLevel:1,  locked:false },
  { bg:'assets/room_bedroom.png',           name:'Bedroom',          emoji:'💤', unlockLevel:1,  locked:false },
  { bg:'assets/room_livingroom.png',        name:'Living Room',      emoji:'🛋️', unlockLevel:1,  locked:false },
  { bg:'assets/room_tokyo_day.png',         name:'Tokyo Day',        emoji:'🌸', unlockLevel:5,  locked:true, travelCity:'TOKYO',    travelFlag:'🇯🇵', travelDesc:'Cherry blossoms & Tokyo Tower' },
  { bg:'assets/room_tokyo_night.png',       name:'Tokyo Night',      emoji:'🌃', unlockLevel:8,  locked:true, travelCity:'TOKYO',    travelFlag:'🇯🇵', travelDesc:'Neon lights & ramen nights' },
  { bg:'assets/room_thailand_beach.png',    name:'Thailand Beach',   emoji:'🏖️', unlockLevel:12, locked:true, travelCity:'THAILAND', travelFlag:'🇹🇭', travelDesc:'Turquoise sea & longtail boats' },
  { bg:'assets/room_thailand_temple.png',   name:'Thailand Temple',  emoji:'🛕', unlockLevel:15, locked:true, travelCity:'THAILAND', travelFlag:'🇹🇭', travelDesc:'Golden temples & sky lanterns' },
];

// ── Room objects ──────────────────────────────────────────
const OBJECTS = {
  computer: {
    gif:'assets/anim_computer.gif', label:'💻 Mochi is checking the task list!',
    action: () => { switchTab('mochi'); return 'Switched to task list! ✨'; }, happiness:0,
  },
  bulletin: {
    gif:'assets/anim_bulletin.gif', label:'📌 Mochi is pinning a new note!',
    action: () => { switchTab('mochi'); setTimeout(()=>document.getElementById('task-input').focus(),400); return 'Add your next quest! 🌸'; }, happiness:2,
  },
  window: {
    gif:'assets/anim_window.gif', label:'🌤 Mochi is daydreaming...',
    action: () => randomMotivation(), happiness:3,
  },
  bookshelf: {
    gif:'assets/anim_bookshelf.gif', label:'📚 Mochi is reading the achievement log!',
    action: () => { switchTab('stats'); return 'Checking achievements! ⭐'; }, happiness:2,
  },
  plant: {
    gif:'assets/anim_plant.gif', label:'🌱 Mochi is watering the plant!',
    action: () => { state.plantLevel = Math.min(state.plantLevel+1,5); gainXP(10); return `Plant grew! Level ${state.plantLevel} 🌿`; }, happiness:5,
  },
  tv: {
    gif:'assets/anim_tv.gif', label:'📺 Mochi is watching a motivational show!',
    action: () => randomMotivation(), happiness:3,
  },
  snack: {
    gif:'assets/anim_snack.gif', label:'🍪 Mochi is eating a yummy snack!',
    action: () => {
      const now = Date.now();
      if (state.snackCooldown && now - state.snackCooldown < 300000) {
        const mins = Math.ceil((300000-(now-state.snackCooldown))/60000);
        return `Mochi is full! Try again in ${mins} min 🍬`;
      }
      state.snackCooldown = now;
      state.happiness = Math.min(100, state.happiness+12);
      updateCreature(true);
      return 'Mochi loved the snack! +12 happiness 🍪';
    }, happiness:0,
  },
  bed: {
    gif:'assets/anim_bed.gif', label:'💤 Mochi is taking a cozy nap...',
    action: () => { state.happiness = Math.min(100,state.happiness+8); updateCreature(true); return 'Mochi rested! +8 happiness 💤'; }, happiness:0,
  },
  lamp: {
    gif:'assets/anim_lamp.gif', label:'💡 Mochi toggled the lamp!',
    action: () => { state.lampOn=!state.lampOn; return state.lampOn?'Lamp on! ✨':'Lamp off~ 🌙'; }, happiness:1,
  },
  fridge: {
    gif:'assets/anim_fridge.gif', label:'🧊 Mochi found something in the fridge!',
    action: () => { gainXP(15); return 'Secret snack found! +15 XP 🍓'; }, happiness:6,
  },
};

// ── Stage GIF lookup ─────────────────────────────────────
// Maps stage mood/action keys to their GIF filenames in assets/
function getGifPath(gifName) {
  if (!gifName) return null;
  return `assets/${gifName}.gif`;
}

// ── Gifts ─────────────────────────────────────────────────
const GIFTS = [
  { img:'assets/gift_wrapped_present Background Removed.png',  title:'SURPRISE GIFT!',   desc:'You earned a wrapped present! 🎁' },
  { img:'assets/gift_mystery_box Background Removed.png',      title:'MYSTERY BOX!',     desc:'A mysterious box appeared! 🎲' },
  { img:'assets/gift_treasure_chest Background Removed.png',   title:'TREASURE CHEST!',  desc:'All quests done! Mochi is thrilled! 💎' },
  { img:'assets/gift_star_reward Background Removed.png',      title:'STAR REWARD!',     desc:'A shining star for your hard work! ⭐' },
  { img:'assets/gift_xp_orb Background Removed.png',           title:'XP ORB!',          desc:'A glowing XP orb! ✨' },
  { img:'assets/gift_streak_flame Background Removed.png',     title:'STREAK BONUS!',    desc:'Your daily streak earned a flame bonus! 🔥' },
  { img:'assets/gift_heart_coin Background Removed.png',       title:'HEART COIN!',      desc:'A golden heart coin! 💛' },
  { img:'assets/gift_potion Background Removed.png',           title:'LEVEL UP POTION!', desc:'A magical potion boosts Mochi\'s power! 🧪' },
  { img:'assets/gift_mochi_opening Background Removed.png',    title:'EVOLUTION GIFT!',  desc:'A special gift for evolving! 🌸' },
];

const MOTIVATIONS = [
  "You're doing amazing! Keep going! 🌟",
  "Mochi believes in you! 💖",
  "Every task is a step forward! ✨",
  "You've got this! Mochi is cheering! 🎉",
  "Small steps lead to big dreams! 🌸",
  "Mochi is proud of you! 🥰",
  "Today is a great day to be productive! ⭐",
  "You're a quest champion! 🏆",
];

const TASK_MSGS = [
  "Quest complete! Mochi got happier! 💖",
  "Amazing! +happiness for Mochi! ✨",
  "Task done! Mochi is dancing! 💃",
  "You're on fire! 🔥 Keep going!",
  "Mochi gained XP! ⭐",
  "Wonderful! Mochi loves you! 🌸",
  "One step closer to victory! ✦",
];

// ============================================================
// EVOLUTION HELPERS
// ============================================================
function getStageForTasks(total) {
  let stage = 0;
  for (let i = EVOLUTION.length - 1; i >= 0; i--) {
    if (total >= EVOLUTION[i].threshold) { stage = i; break; }
  }
  return stage;
}

function getCurrentStage() {
  return EVOLUTION[state.evolutionStage];
}

function checkEvolution() {
  const newStageIdx = getStageForTasks(state.totalCompleted);
  if (newStageIdx > state.evolutionStage) {
    const prev = state.evolutionStage;
    state.evolutionStage = newStageIdx;
    triggerEvolution(EVOLUTION[prev], EVOLUTION[newStageIdx]);
  }
}

function triggerEvolution(fromStage, toStage) {
  // Flash overlay
  const overlay = document.getElementById('evo-overlay');
  const text    = document.getElementById('evo-text');
  const sub     = document.getElementById('evo-sub');
  if (overlay) {
    text.textContent = `${toStage.emoji} EVOLVED INTO ${toStage.name}! ${toStage.emoji}`;
    sub.textContent  = toStage.displayName;
    overlay.classList.remove('show');
    void overlay.offsetWidth;
    overlay.classList.add('show');
    setTimeout(() => overlay.classList.remove('show'), 2500);
  }

  launchConfetti();
  showToast(`${toStage.emoji} EVOLUTION! Mochi became ${toStage.name}! 🎉`);
  setTimeout(() => showGift(GIFTS[8]), 1500); // evolution gift

  // Update creature name
  document.getElementById('creature-name').textContent = toStage.displayName;

  // Update evolution tab
  updateEvolutionView();
  saveState();
}

// ============================================================
// INIT
// ============================================================
async function init() {
  try {
    const saved = await window.electronAPI.loadData();
    if (saved) {
      state = { ...state, ...saved };
      if (state.lastReset !== new Date().toDateString()) handleNewDay();
    }
  } catch(e) { console.log('Fresh start'); }

  // Ensure evolutionStage is consistent with totalCompleted
  state.evolutionStage = getStageForTasks(state.totalCompleted);

  updateDate();
  renderTasks();
  updateCreature();
  updateStats();
  updateStatsView();
  updateEvolutionView();
  switchRoom(state.currentRoom || 0);
  updateRoomSwitcher();

  // Update creature name display
  document.getElementById('creature-name').textContent = getCurrentStage().displayName;

  document.getElementById('task-input').addEventListener('keydown', e => {
    if (e.key === 'Enter') addTask();
  });

  setInterval(saveState, 30000);
  setInterval(passiveDecay, 300000);
  setInterval(randomIdleBounce, 8000);

  console.log('🌸 Mochi is awake! v3.0 — Evolution system active');
}

// ============================================================
// TAB SWITCHING
// ============================================================
function switchTab(tab) {
  const tabs = ['mochi','room','stats','evolution'];
  document.querySelectorAll('.tab-btn').forEach((b,i) => {
    b.classList.toggle('active', tabs[i] === tab);
  });
  document.querySelectorAll('.view').forEach(v => v.classList.remove('active'));
  const viewMap = { mochi:'view-mochi', room:'view-room', stats:'view-stats', evolution:'view-evolution' };
  const el = document.getElementById(viewMap[tab]);
  if (el) el.classList.add('active');
  if (tab === 'stats') updateStatsView();
  if (tab === 'evolution') updateEvolutionView();
}

// ============================================================
// ROOM SYSTEM
// ============================================================
function switchRoom(index) {
  const room = ROOMS[index];
  if (!room) return;

  // Check if locked
  if (room.locked && state.level < room.unlockLevel) {
    showToast(`🔒 ${room.name} unlocks at Level ${room.unlockLevel}! Keep completing quests! ✨`);
    // Show locked room preview flash
    const bg = document.getElementById('room-bg');
    bg.style.filter = 'grayscale(1) brightness(0.4)';
    setTimeout(() => { bg.style.filter = ''; }, 800);
    return;
  }

  // Unlock if previously locked
  if (room.locked && state.level >= room.unlockLevel) {
    room.locked = false;
  }

  state.currentRoom = index;
  const bg = document.getElementById('room-bg');
  bg.src = room.bg;

  // Show travel banner for travel rooms
  if (room.travelCity) {
    showTravelBanner(room);
  }

  updateRoomSwitcher();
  saveState();
}

function showTravelBanner(room) {
  let banner = document.getElementById('travel-banner');
  if (!banner) {
    banner = document.createElement('div');
    banner.id = 'travel-banner';
    banner.style.cssText = `
      position:absolute; top:50px; left:50%; transform:translateX(-50%);
      background:rgba(45,27,78,0.92); color:#fff;
      font-family:'Press Start 2P',monospace; font-size:7px;
      padding:10px 18px; border-radius:12px; z-index:50;
      border:2px solid var(--lavender); text-align:center;
      box-shadow:0 4px 0 var(--lavender-dark);
      animation:fadeUp 0.4s ease;
      white-space:nowrap;
    `;
    document.getElementById('view-room').appendChild(banner);
  }
  banner.innerHTML = `${room.travelFlag} MOCHI IS IN ${room.travelCity}! ${room.travelFlag}<br><span style="font-family:'VT323',monospace;font-size:14px;color:var(--pink)">${room.travelDesc}</span>`;
  banner.style.display = 'block';
  clearTimeout(banner._timer);
  banner._timer = setTimeout(() => { banner.style.display = 'none'; }, 3500);
}

function updateRoomSwitcher() {
  const switcher = document.getElementById('room-switcher');
  if (!switcher) return;
  switcher.innerHTML = ROOMS.map((room, i) => {
    const isActive  = i === state.currentRoom;
    const isLocked  = room.locked && state.level < room.unlockLevel;
    const isTravel  = !!room.travelCity;
    return `<div class="room-dot ${isActive ? 'active' : ''} ${isLocked ? 'locked-dot' : ''} ${isTravel ? 'travel-dot' : ''}"
      onclick="switchRoom(${i})"
      title="${isLocked ? '🔒 ' + room.name + ' (Lv ' + room.unlockLevel + ')' : room.emoji + ' ' + room.name}">
      ${isLocked ? '🔒' : (isTravel ? room.travelFlag : '')}
    </div>`;
  }).join('');
}

function interactObject(objKey) {
  const obj = OBJECTS[objKey];
  if (!obj) return;
  const overlay = document.getElementById('anim-overlay');
  const gif     = document.getElementById('anim-gif');
  const label   = document.getElementById('anim-label');
  gif.src = '';
  setTimeout(() => { gif.src = obj.gif; }, 50);
  label.textContent = obj.label;
  overlay.classList.add('show');
  if (obj.happiness > 0) { state.happiness = Math.min(100, state.happiness+obj.happiness); updateCreature(true); }
  setTimeout(() => { const msg = obj.action(); if (msg) showToast(msg); saveState(); }, 800);
}

function closeAnim() {
  document.getElementById('anim-overlay').classList.remove('show');
  document.getElementById('anim-gif').src = '';
}

// ============================================================
// CREATURE LOGIC — stage-aware
// ============================================================
function getSpritePath(spriteName) {
  // Handles both "Background Removed" filenames and plain ones
  return `assets/${spriteName}.png`;
}

function updateCreature(animate = false) {
  const stage = getCurrentStage();
  const h     = state.happiness;
  const mood  = stage.moods.slice().reverse().find(m => h >= m.min) || stage.moods[0];

  const img      = document.getElementById('creature-img');
  const moodText = document.getElementById('mood-text');

  // Prefer GIF over static PNG when available
  const newSrc = mood.gif ? getGifPath(mood.gif) : getSpritePath(mood.img);

  if (img.src !== newSrc) img.src = newSrc;
  moodText.textContent = mood.text;
  if (animate) triggerBounce();

  updateHearts();
  updateHappinessBar();
}

function showActionSprite(action, duration = 1500) {
  const stage = getCurrentStage();
  const spriteData = stage.sprites[action];
  if (!spriteData) return;
  const img = document.getElementById('creature-img');
  // Use GIF if available, otherwise fall back to PNG
  img.src = spriteData.gif ? getGifPath(spriteData.gif) : getSpritePath(spriteData.png);
  setTimeout(() => updateCreature(), duration);
}

function updateHearts() {
  const filled = Math.ceil((state.happiness / 100) * 5);
  for (let i = 1; i <= 5; i++) {
    const h = document.getElementById(`h${i}`);
    if (h) h.classList.toggle('empty', i > filled);
  }
}

function updateHappinessBar() {
  const bar = document.getElementById('happiness-bar');
  const val = document.getElementById('happiness-val');
  if (bar) bar.style.width = `${state.happiness}%`;
  if (val) val.textContent = `${Math.round(state.happiness)}%`;
}

function updateStats() {
  const xpBar  = document.getElementById('xp-bar');
  const xpVal  = document.getElementById('xp-val');
  const lvlBdg = document.getElementById('level-badge');
  const pct = (state.xp / state.xpToNext) * 100;
  if (xpBar)  xpBar.style.width = `${Math.min(pct,100)}%`;
  if (xpVal)  xpVal.textContent = `${state.xp} XP`;
  if (lvlBdg) lvlBdg.textContent = `LV ${state.level}`;
}

function updateStatsView() {
  const done  = state.tasks.filter(t => t.done).length;
  const total = state.tasks.length;
  const stage = getCurrentStage();

  const set = (id, val) => { const el = document.getElementById(id); if (el) el.textContent = val; };
  set('stat-happiness', `${Math.round(state.happiness)}%`);
  set('stat-level',     state.level);
  set('stat-xp',        state.xp + (state.level-1)*100);
  set('stat-total',     state.totalCompleted);
  set('stat-streak',    state.streak || 0);
  set('stat-stage',     `${stage.emoji} ${stage.name}`);
  set('today-progress', total > 0
    ? `${done} of ${total} quests done (${Math.round(done/total*100)}%)`
    : 'No quests added yet today.');

  const grid = document.getElementById('rewards-grid');
  if (grid) {
    if (!state.rewards || state.rewards.length === 0) {
      grid.innerHTML = '<span style="font-family:\'VT323\',monospace;font-size:13px;color:var(--mid);opacity:0.7">Complete tasks to earn rewards!</span>';
    } else {
      grid.innerHTML = state.rewards.slice(-12).map(r =>
        `<img src="${r.img}" title="${r.title}" style="width:44px;height:44px;object-fit:contain;image-rendering:pixelated;border-radius:8px;border:2px solid var(--border);" />`
      ).join('');
    }
  }
}

// ============================================================
// EVOLUTION VIEW
// ============================================================
function updateEvolutionView() {
  const container = document.getElementById('evo-stages');
  if (!container) return;

  const total = state.totalCompleted;
  const currentIdx = state.evolutionStage;

  container.innerHTML = EVOLUTION.map((stage, i) => {
    const unlocked = total >= stage.threshold;
    const isCurrent = i === currentIdx;
    const isLocked  = !unlocked;

    // Progress toward this stage
    const nextThreshold = EVOLUTION[i+1] ? EVOLUTION[i+1].threshold : stage.threshold;
    const prevThreshold = stage.threshold;
    const range = nextThreshold - prevThreshold;
    const progress = range > 0 ? Math.min(100, Math.max(0, ((total - prevThreshold) / range) * 100)) : 100;
    const progressVal = range > 0 ? `${Math.min(total, nextThreshold)} / ${nextThreshold}` : '✓';

    // Pick sprite to show — prefer GIF if available
    const midMood    = stage.moods[Math.floor(stage.moods.length / 2)];
    const spriteFile = isLocked ? '' : (midMood.gif ? getGifPath(midMood.gif) : getSpritePath(midMood.img));

    const cardClass = isLocked ? 'evo-card locked' : isCurrent ? 'evo-card current' : 'evo-card completed';

    return `
      <div class="${cardClass}">
        <div class="evo-sprite-wrap">
          ${isLocked
            ? `<div class="evo-lock">🔒</div>`
            : `<img class="evo-sprite" src="${spriteFile}" alt="${stage.name}" onerror="this.style.display='none';this.parentNode.innerHTML+='${stage.emoji}'" />`
          }
        </div>
        <div class="evo-info">
          <div class="evo-stage-num">STAGE ${String(i+1).padStart(2,'0')}</div>
          <div class="evo-stage-name">${stage.emoji} ${stage.name}</div>
          <div class="evo-stage-desc">${getStageDesc(i)}</div>
          <div class="evo-progress-row">
            <span class="evo-prog-label">${isLocked ? 'UNLOCK AT' : isCurrent ? 'PROGRESS' : '✓ UNLOCKED'}</span>
            <span class="evo-prog-val ${isCurrent ? 'current' : ''}">${isLocked ? stage.threshold + ' tasks' : isCurrent ? progressVal : '✓'}</span>
          </div>
          ${isCurrent || (!isLocked && i < EVOLUTION.length-1) ? `
          <div class="evo-bar-outer">
            <div class="evo-bar-fill" style="width:${isCurrent ? progress : 100}%;background:${getStageColor(i)}"></div>
          </div>` : ''}
        </div>
        ${isCurrent ? '<div class="evo-current-badge">CURRENT</div>' : ''}
        ${!isLocked && !isCurrent ? '<div class="evo-done-badge">✓</div>' : ''}
      </div>
      ${i < EVOLUTION.length-1 ? '<div class="evo-arrow">▼</div>' : ''}
    `;
  }).join('');

  // Update lifetime bar
  const lifePct = Math.min(100, (total / 75) * 100);
  const lifeBar = document.getElementById('evo-lifetime-bar');
  const lifeVal = document.getElementById('evo-lifetime-val');
  if (lifeBar) lifeBar.style.width = lifePct + '%';
  if (lifeVal) lifeVal.textContent = `${total} / 75 LIFETIME TASKS`;
}

function getStageDesc(i) {
  const descs = [
    'A mysterious egg, full of potential...',
    'A tiny curious creature, just hatched!',
    'Moody, rebellious, secretly motivated.',
    'Fully grown, expressive, your companion.',
    'Wise, serene, golden-glowing elder.',
  ];
  return descs[i] || '';
}

function getStageColor(i) {
  const colors = [
    'linear-gradient(90deg,#c9b1ff,#e8d5f5)',
    'linear-gradient(90deg,#ff8fab,#ffb3c6)',
    'linear-gradient(90deg,#ffe066,#ffd700)',
    'linear-gradient(90deg,#c9b1ff,#a78bfa)',
    'linear-gradient(90deg,#ffd700,#ffec6e)',
  ];
  return colors[i] || 'linear-gradient(90deg,#c9b1ff,#ff8fab)';
}

// ============================================================
// ANIMATIONS
// ============================================================
function triggerBounce() {
  const img = document.getElementById('creature-img');
  img.classList.remove('bounce','celebrate','idle');
  void img.offsetWidth;
  img.classList.add('bounce');
  setTimeout(() => { img.classList.remove('bounce'); img.classList.add('idle'); }, 600);
}

function triggerCelebrate() {
  const img = document.getElementById('creature-img');
  img.classList.remove('bounce','celebrate','idle');
  void img.offsetWidth;
  img.classList.add('celebrate');
  showActionSprite('celebrating', 1500);
  setTimeout(() => { img.classList.remove('celebrate'); img.classList.add('idle'); }, 1200);
}

function randomIdleBounce() {
  if (Math.random() > 0.55) triggerBounce();
}

function passiveDecay() {
  const done  = state.tasks.filter(t => t.done).length;
  const total = state.tasks.length;
  if (total > 0 && done < total) {
    state.happiness = Math.max(5, state.happiness - 2);
    updateCreature();
    saveState();
  }
}

// ============================================================
// PARTICLES & CONFETTI
// ============================================================
const PARTICLES = ['✨','💖','⭐','🌸','💫','✦','♥','🌟'];

function spawnParticles() {
  const zone = document.getElementById('creature-zone');
  for (let i = 0; i < 6; i++) {
    setTimeout(() => {
      const p = document.createElement('div');
      p.className = 'particle';
      p.textContent = PARTICLES[Math.floor(Math.random() * PARTICLES.length)];
      p.style.left = (Math.random() * 80 + 10) + '%';
      p.style.top  = (Math.random() * 40 + 30) + '%';
      p.style.animationDelay = (Math.random() * 0.3) + 's';
      zone.appendChild(p);
      setTimeout(() => p.remove(), 1800);
    }, i * 100);
  }
}

function launchConfetti() {
  const canvas = document.getElementById('confetti-canvas');
  const ctx = canvas.getContext('2d');
  canvas.width  = canvas.offsetWidth;
  canvas.height = canvas.offsetHeight;
  const colors = ['#FFB3D1','#C8A8E9','#A8E6CF','#FFE8A3','#A8D8EA','#FF85B3'];
  const pieces = Array.from({length:70}, () => ({
    x:Math.random()*canvas.width, y:-10,
    w:Math.random()*8+4, h:Math.random()*4+2,
    color:colors[Math.floor(Math.random()*colors.length)],
    vx:(Math.random()-0.5)*4, vy:Math.random()*3+2,
    rot:Math.random()*360, rotV:(Math.random()-0.5)*10, opacity:1,
  }));
  let frame = 0;
  function draw() {
    ctx.clearRect(0,0,canvas.width,canvas.height);
    pieces.forEach(p => {
      ctx.save(); ctx.translate(p.x,p.y); ctx.rotate(p.rot*Math.PI/180);
      ctx.globalAlpha=p.opacity; ctx.fillStyle=p.color;
      ctx.fillRect(-p.w/2,-p.h/2,p.w,p.h); ctx.restore();
      p.x+=p.vx; p.y+=p.vy; p.rot+=p.rotV; p.vy+=0.05;
      if (frame>60) p.opacity-=0.015;
    });
    frame++;
    if (frame<130) requestAnimationFrame(draw);
    else ctx.clearRect(0,0,canvas.width,canvas.height);
  }
  draw();
}

// ============================================================
// GIFT SYSTEM
// ============================================================
function showGift(giftData) {
  const popup = document.getElementById('gift-popup');
  const img   = document.getElementById('gift-img');
  const title = document.getElementById('gift-title');
  const desc  = document.getElementById('gift-desc');
  img.src = ''; setTimeout(() => { img.src = giftData.img; }, 50);
  title.textContent = giftData.title;
  desc.textContent  = giftData.desc;
  popup.classList.add('show');
  if (!state.rewards) state.rewards = [];
  state.rewards.push(giftData);
  saveState();
}

function closeGift() {
  document.getElementById('gift-popup').classList.remove('show');
  updateStatsView();
}

function maybeGiveGift(tasksCompleted, totalTasks) {
  const shouldGive = tasksCompleted === 1 || tasksCompleted % 3 === 0 || (tasksCompleted === totalTasks && totalTasks > 0);
  if (shouldGive) {
    const gift = GIFTS[Math.floor(Math.random() * (GIFTS.length - 1))]; // exclude evo gift
    setTimeout(() => showGift(gift), 1200);
  }
}

// ============================================================
// TOAST & MOTIVATION
// ============================================================
function showToast(msg) {
  const toast = document.getElementById('toast');
  toast.textContent = msg;
  toast.classList.add('show');
  setTimeout(() => toast.classList.remove('show'), 2800);
}

function randomMotivation() {
  return MOTIVATIONS[Math.floor(Math.random() * MOTIVATIONS.length)];
}

// ============================================================
// TASK MANAGEMENT
// ============================================================
function addTask() {
  const input = document.getElementById('task-input');
  const text  = input.value.trim();
  if (!text) return;

  showActionSprite('writing', 1500);

  state.tasks.push({ id:Date.now(), text, done:false, createdAt:new Date().toISOString() });
  input.value = '';
  renderTasks();
  updateCreature(true);
  saveState();
  showToast('Quest added! Mochi is ready! 🌸');
}

function toggleTask(id) {
  const task = state.tasks.find(t => t.id === id);
  if (!task) return;

  const wasDone = task.done;
  task.done = !task.done;

  if (task.done && !wasDone) {
    const gain = calculateHappinessGain();
    state.happiness = Math.min(100, state.happiness + gain);
    state.totalCompleted++;

    showActionSprite('checkoff', 1200);
    gainXP(20 + Math.floor(Math.random() * 10));
    spawnParticles();

    // Check for evolution AFTER incrementing totalCompleted
    checkEvolution();

    const done  = state.tasks.filter(t => t.done).length;
    const total = state.tasks.length;

    if (done === total && total > 0) {
      setTimeout(() => {
        triggerCelebrate();
        launchConfetti();
        showToast('ALL QUESTS DONE!! Mochi is overjoyed! 🎉✨');
        setTimeout(() => showGift(GIFTS[2]), 1500);
      }, 400);
    } else {
      triggerBounce();
      showToast(TASK_MSGS[Math.floor(Math.random() * TASK_MSGS.length)]);
      maybeGiveGift(done, total);
    }

    // Egg hatch: first task ever
    if (state.totalCompleted === 1 && !state.hasHatched) {
      state.hasHatched = true;
      setTimeout(() => {
        showToast('🥚 THE EGG IS HATCHING!! 🌱');
        launchConfetti();
      }, 600);
    }

  } else if (!task.done && wasDone) {
    state.happiness = Math.max(0, state.happiness - 5);
    showToast('Quest un-done... Mochi is a bit sad 😢');
    updateCreature();
  }

  renderTasks();
  updateStats();
  updateStatsView();
  saveState();
}

function calculateHappinessGain() {
  const total = state.tasks.length;
  if (total === 0) return 10;
  return Math.round(Math.max(8, Math.min(20, 100/total)));
}

function checkTravelUnlock(level) {
  // Announce when a travel room just became available
  const justUnlocked = ROOMS.filter(r => r.travelCity && r.unlockLevel === level);
  justUnlocked.forEach(room => {
    room.locked = false;
    setTimeout(() => {
      showToast(`✈️ NEW ROOM UNLOCKED: ${room.travelFlag} ${room.name}! Tap the dot to visit! 🌍`);
      launchConfetti();
    }, 1200);
  });
}

function gainXP(amount) {
  state.xp += amount;
  while (state.xp >= state.xpToNext) {
    state.xp -= state.xpToNext;
    state.level++;
    state.xpToNext = Math.floor(state.xpToNext * 1.5);
    showToast(`LEVEL UP! Mochi is now LV ${state.level}! ⭐`);
    setTimeout(() => {
      launchConfetti();
      showActionSprite('levelup', 2000);
      showGift(GIFTS[7]);
      updateRoomSwitcher(); // refresh locked/unlocked dots
      checkTravelUnlock(state.level);
    }, 300);
  }
  updateStats();
}

function deleteTask(id, event) {
  event.stopPropagation();
  showActionSprite('delete', 1200);
  state.tasks = state.tasks.filter(t => t.id !== id);
  renderTasks();
  updateCreature();
  saveState();
  showToast('Quest deleted! 🗑️');
}

function renderTasks() {
  const list    = document.getElementById('task-list');
  const countEl = document.getElementById('todo-count');
  const total   = state.tasks.length;
  const done    = state.tasks.filter(t => t.done).length;

  if (countEl) countEl.textContent = `${done}/${total}`;

  if (total === 0) {
    list.innerHTML = `
      <div id="empty-state">
        <div class="emoji">🌸</div>
        <div class="text">No quests yet!<br>Add tasks to feed Mochi~</div>
      </div>`;
    if (state.happiness < 60) showActionSprite('bored', 3000);
    return;
  }

  const pending = state.tasks.filter(t => !t.done).length;
  if (pending >= 5) showActionSprite('overwhelmed', 2500);

  list.innerHTML = state.tasks.map(task => `
    <div class="task-item ${task.done ? 'done' : ''}" onclick="toggleTask(${task.id})">
      <div class="task-checkbox">${task.done ? '✓' : ''}</div>
      <span class="task-text">${escapeHtml(task.text)}</span>
      <div class="task-delete" onclick="deleteTask(${task.id}, event)">✕</div>
    </div>
  `).join('');
}

function escapeHtml(text) {
  const d = document.createElement('div');
  d.appendChild(document.createTextNode(text));
  return d.innerHTML;
}

// ============================================================
// DATE, STREAK & RESET
// ============================================================
function updateDate() {
  const el = document.getElementById('date-display');
  if (!el) return;
  const now    = new Date();
  const days   = ['SUN','MON','TUE','WED','THU','FRI','SAT'];
  const months = ['JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC'];
  el.textContent = `${days[now.getDay()]} ${months[now.getMonth()]} ${now.getDate()}`;
}

function handleNewDay() {
  const today     = new Date().toDateString();
  const yesterday = new Date(Date.now()-86400000).toDateString();
  if (state.lastActiveDay === yesterday) {
    state.streak = (state.streak||0) + 1;
  } else if (state.lastActiveDay !== today) {
    state.streak = 0;
  }
  state.lastActiveDay = today;
  state.tasks         = [];
  state.lastReset     = today;
  state.happiness     = Math.max(20, state.happiness - 10);
  if (state.streak > 0) {
    showToast(`🔥 Day ${state.streak} streak! Keep it up!`);
    if (state.streak % 3 === 0) setTimeout(() => showGift(GIFTS[5]), 1000);
  }
}

function confirmReset() {
  if (confirm('Start a new day? Current tasks will be cleared.')) {
    handleNewDay();
    renderTasks();
    updateCreature();
    updateStatsView();
    saveState();
    showToast('New day started! 🌅');
  }
}

// ============================================================
// PERSISTENCE
// ============================================================
async function saveState() {
  try { await window.electronAPI.saveData(state); } catch(e) {}
}

// ============================================================
// START
// ============================================================
document.addEventListener('DOMContentLoaded', init);
window.addEventListener('beforeunload', saveState);
