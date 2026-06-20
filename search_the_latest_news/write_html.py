html = r"""<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>News Monitor</title>
  <link href="https://fonts.googleapis.com/css2?family=Syne:wght@400;600;800&family=DM+Mono:ital,wght@0,400;0,500;1,400&display=swap" rel="stylesheet" />
  <style>
    :root {
      --bg:        #0a0a0f;
      --surface:   #12121a;
      --surface2:  #1c1c28;
      --border:    #2a2a3d;
      --accent:    #7c6aff;
      --accent2:   #ff6a9e;
      --text:      #e8e8f0;
      --muted:     #6b6b88;
      --user-bg:   #1e1e2e;
      --ai-bg:     #161624;
      --radius:    14px;
      --success:   #4ade80;
      --danger:    #f87171;
    }
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: 'DM Mono', monospace;
      background: var(--bg); color: var(--text);
      min-height: 100vh; display: flex; flex-direction: column;
      overflow: hidden; height: 100vh;
    }
    body::before {
      content: ''; position: fixed; inset: 0;
      background-image:
        linear-gradient(rgba(124,106,255,.03) 1px, transparent 1px),
        linear-gradient(90deg, rgba(124,106,255,.03) 1px, transparent 1px);
      background-size: 40px 40px; pointer-events: none; z-index: 0;
    }
    header {
      position: relative; z-index: 10; padding: 14px 28px;
      border-bottom: 1px solid var(--border);
      background: rgba(10,10,15,.85); backdrop-filter: blur(12px);
      display: flex; align-items: center; gap: 14px;
    }
    .logo-mark {
      width: 36px; height: 36px; border-radius: 10px;
      background: linear-gradient(135deg, var(--accent), var(--accent2));
      display: flex; align-items: center; justify-content: center;
      font-family: 'Syne', sans-serif; font-weight: 800; font-size: 15px; color: #fff; flex-shrink: 0;
    }
    .header-text h1 {
      font-family: 'Syne', sans-serif; font-weight: 800; font-size: 16px; letter-spacing: .02em;
      background: linear-gradient(90deg, var(--accent), var(--accent2));
      -webkit-background-clip: text; -webkit-text-fill-color: transparent; background-clip: text;
    }
    .header-text p { font-size: 11px; color: var(--muted); margin-top: 1px; }
    .status-badge {
      margin-left: auto; padding: 4px 10px; border-radius: 20px;
      background: rgba(124,106,255,.12); border: 1px solid rgba(124,106,255,.3);
      font-size: 11px; color: var(--accent); display: flex; align-items: center; gap: 6px;
    }
    .status-dot {
      width: 7px; height: 7px; border-radius: 50%;
      background: var(--success); box-shadow: 0 0 6px var(--success);
      animation: pulse 2s ease-in-out infinite;
    }
    @keyframes pulse { 0%,100% { opacity: 1; } 50% { opacity: .4; } }
    .tab-nav {
      position: relative; z-index: 10; display: flex;
      background: var(--surface); border-bottom: 1px solid var(--border); padding: 0 28px;
    }
    .tab-btn {
      padding: 12px 20px; background: none; border: none;
      border-bottom: 2px solid transparent; color: var(--muted);
      font-family: 'DM Mono', monospace; font-size: 12px; cursor: pointer;
      transition: all .2s; white-space: nowrap;
    }
    .tab-btn:hover { color: var(--text); }
    .tab-btn.active { color: var(--accent); border-bottom-color: var(--accent); }
    .tab-panel { display: none; flex: 1; flex-direction: column; min-height: 0; position: relative; }
    .tab-panel.active { display: flex; }
    .config-bar {
      position: relative; z-index: 10; padding: 10px 28px;
      background: var(--surface); border-bottom: 1px solid var(--border);
      display: flex; align-items: center; gap: 12px; flex-wrap: wrap;
    }
    .config-label { font-size: 11px; color: var(--muted); white-space: nowrap; }
    .config-input {
      flex: 1; min-width: 200px; background: var(--surface2);
      border: 1px solid var(--border); border-radius: 8px; padding: 6px 10px;
      color: var(--text); font-family: 'DM Mono', monospace; font-size: 12px;
      outline: none; transition: border-color .2s;
    }
    .config-input:focus { border-color: var(--accent); }
    .config-input::placeholder { color: var(--muted); }
    #messages {
      position: relative; z-index: 1; flex: 1; overflow-y: auto; min-height: 0;
      padding: 24px 28px; display: flex; flex-direction: column; gap: 20px; scroll-behavior: smooth;
    }
    #messages::-webkit-scrollbar { width: 4px; }
    #messages::-webkit-scrollbar-track { background: transparent; }
    #messages::-webkit-scrollbar-thumb { background: var(--border); border-radius: 2px; }
    .welcome {
      flex: 1; display: flex; flex-direction: column;
      align-items: center; justify-content: center;
      text-align: center; padding: 40px 20px; opacity: 0;
      animation: fadeIn .6s .2s forwards;
    }
    @keyframes fadeIn { to { opacity: 1; } }
    .welcome-icon {
      width: 64px; height: 64px; border-radius: 18px;
      background: linear-gradient(135deg, var(--accent), var(--accent2));
      display: flex; align-items: center; justify-content: center;
      font-size: 28px; margin-bottom: 20px; box-shadow: 0 8px 32px rgba(124,106,255,.3);
    }
    .welcome h2 { font-family: 'Syne', sans-serif; font-size: 22px; font-weight: 800; margin-bottom: 8px; }
    .welcome p { font-size: 13px; color: var(--muted); max-width: 360px; line-height: 1.7; }
    .welcome-hint { margin-top: 24px; display: flex; gap: 8px; flex-wrap: wrap; justify-content: center; }
    .hint-chip {
      padding: 6px 14px; border-radius: 20px; border: 1px solid var(--border);
      background: var(--surface2); font-size: 11px; color: var(--muted); cursor: pointer; transition: all .2s;
    }
    .hint-chip:hover { border-color: var(--accent); color: var(--accent); background: rgba(124,106,255,.08); }
    .message {
      display: flex; gap: 12px; opacity: 0; transform: translateY(8px);
      animation: slideIn .3s forwards;
    }
    @keyframes slideIn { to { opacity: 1; transform: none; } }
    .message.user { flex-direction: row-reverse; }
    .avatar {
      width: 32px; height: 32px; border-radius: 9px;
      display: flex; align-items: center; justify-content: center; font-size: 14px; flex-shrink: 0;
    }
    .message.user .avatar { background: linear-gradient(135deg, #3b82f6, #6366f1); }
    .message.ai   .avatar { background: linear-gradient(135deg, var(--accent), var(--accent2)); }
    .bubble {
      max-width: 70%; padding: 12px 16px; border-radius: var(--radius);
      font-size: 13px; line-height: 1.75; white-space: pre-wrap; word-break: break-word;
    }
    .message.user .bubble { background: var(--user-bg); border: 1px solid var(--border); border-top-right-radius: 4px; }
    .message.ai   .bubble { background: var(--ai-bg); border: 1px solid rgba(124,106,255,.2); border-top-left-radius: 4px; }
    .bubble-meta { font-size: 10px; color: var(--muted); margin-top: 5px; text-align: right; }
    .message.ai .bubble-meta { text-align: left; }
    .typing-indicator { display: flex; gap: 5px; align-items: center; padding: 4px 0; }
    .typing-indicator span {
      width: 6px; height: 6px; border-radius: 50%; background: var(--accent);
      animation: bounce 1.2s ease-in-out infinite;
    }
    .typing-indicator span:nth-child(2) { animation-delay: .2s; }
    .typing-indicator span:nth-child(3) { animation-delay: .4s; }
    @keyframes bounce { 0%,60%,100% { transform: translateY(0); } 30% { transform: translateY(-6px); } }
    .bubble.error { background: rgba(239,68,68,.08); border-color: rgba(239,68,68,.3); color: var(--danger); }
    .token-stats { display: inline-flex; gap: 8px; font-size: 10px; color: var(--muted); margin-top: 6px; }
    .input-area {
      position: relative; z-index: 10; padding: 16px 28px;
      background: rgba(10,10,15,.85); backdrop-filter: blur(12px); border-top: 1px solid var(--border);
    }
    .input-row { display: flex; gap: 10px; align-items: flex-end; }
    textarea {
      flex: 1; background: var(--surface2); border: 1px solid var(--border); border-radius: var(--radius);
      padding: 12px 16px; color: var(--text); font-family: 'DM Mono', monospace; font-size: 13px;
      resize: none; outline: none; line-height: 1.6; transition: border-color .2s;
      min-height: 46px; max-height: 160px;
    }
    textarea:focus { border-color: var(--accent); }
    textarea::placeholder { color: var(--muted); }
    #clear-btn {
      padding: 10px 16px; background: var(--surface2); border: 1px solid var(--border);
      border-radius: 10px; color: var(--muted); font-family: 'DM Mono', monospace;
      font-size: 12px; cursor: pointer; transition: all .2s; white-space: nowrap;
    }
    #clear-btn:hover { border-color: var(--accent); color: var(--accent); }
    #send-btn {
      width: 46px; height: 46px; border-radius: 12px;
      background: linear-gradient(135deg, var(--accent), var(--accent2));
      border: none; cursor: pointer; display: flex; align-items: center; justify-content: center;
      flex-shrink: 0; transition: opacity .2s;
    }
    #send-btn svg { width: 18px; height: 18px; }
    #send-btn:disabled { opacity: .4; cursor: not-allowed; }
    .input-hint { font-size: 10px; color: var(--muted); margin-top: 8px; text-align: right; }
    /* Monitor tab */
    .items-panel {
      position: relative; z-index: 1; flex: 1; overflow-y: auto; min-height: 0;
      padding: 28px; display: flex; flex-direction: column; gap: 24px;
    }
    .items-panel::-webkit-scrollbar { width: 4px; }
    .items-panel::-webkit-scrollbar-track { background: transparent; }
    .items-panel::-webkit-scrollbar-thumb { background: var(--border); border-radius: 2px; }
    .register-card, .items-list-card {
      background: var(--surface); border: 1px solid var(--border); border-radius: var(--radius); padding: 24px;
    }
    .items-list-card { flex: 1; }
    .card-title {
      font-family: 'Syne', sans-serif; font-size: 14px; font-weight: 700;
      margin-bottom: 16px; color: var(--text); display: flex; align-items: center; gap: 8px;
    }
    .card-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 16px; }
    .form-grid { display: grid; grid-template-columns: 1fr 1fr auto; gap: 12px; align-items: end; }
    @media (max-width: 600px) { .form-grid { grid-template-columns: 1fr; } }
    .form-field { display: flex; flex-direction: column; gap: 6px; }
    .form-label { font-size: 11px; color: var(--muted); }
    .form-input {
      background: var(--surface2); border: 1px solid var(--border); border-radius: 8px;
      padding: 9px 12px; color: var(--text); font-family: 'DM Mono', monospace; font-size: 12px;
      outline: none; transition: border-color .2s;
    }
    .form-input:focus { border-color: var(--accent); }
    .form-input::placeholder { color: var(--muted); }
    .btn-primary {
      padding: 9px 20px; background: linear-gradient(135deg, var(--accent), var(--accent2));
      border: none; border-radius: 8px; color: #fff;
      font-family: 'DM Mono', monospace; font-size: 12px; cursor: pointer;
      white-space: nowrap; transition: opacity .2s;
    }
    .btn-primary:hover { opacity: .85; }
    .btn-primary:disabled { opacity: .4; cursor: not-allowed; }
    .form-message { margin-top: 10px; font-size: 12px; min-height: 18px; }
    .form-message.success { color: var(--success); }
    .form-message.error   { color: var(--danger); }
    .btn-secondary {
      padding: 6px 14px; background: var(--surface2); border: 1px solid var(--border);
      border-radius: 8px; color: var(--muted); font-family: 'DM Mono', monospace;
      font-size: 11px; cursor: pointer; transition: all .2s;
    }
    .btn-secondary:hover { border-color: var(--accent); color: var(--accent); }
    #items-list { display: flex; flex-direction: column; gap: 10px; }
    .item-row {
      display: flex; align-items: center; gap: 12px; padding: 12px 14px;
      background: var(--surface2); border: 1px solid var(--border); border-radius: 10px;
      animation: slideIn .25s forwards;
    }
    .item-keyword { font-size: 13px; color: var(--text); font-weight: 500; flex: 1; }
    .item-email   { font-size: 11px; color: var(--muted); }
    .item-date    { font-size: 10px; color: var(--muted); white-space: nowrap; }
    .item-badge {
      padding: 3px 8px; border-radius: 12px; font-size: 10px;
      background: rgba(74,222,128,.12); border: 1px solid rgba(74,222,128,.3); color: var(--success);
    }
    .btn-delete {
      padding: 5px 12px; background: rgba(248,113,113,.08); border: 1px solid rgba(248,113,113,.25);
      border-radius: 7px; color: var(--danger); font-family: 'DM Mono', monospace;
      font-size: 11px; cursor: pointer; transition: all .2s; white-space: nowrap;
    }
    .btn-delete:hover { background: rgba(248,113,113,.18); border-color: var(--danger); }
    .items-empty   { text-align: center; padding: 40px 20px; color: var(--muted); font-size: 13px; }
    .items-loading { text-align: center; padding: 20px; color: var(--muted); font-size: 12px; }
    .schedule-info {
      background: rgba(124,106,255,.06); border: 1px solid rgba(124,106,255,.2);
      border-radius: 10px; padding: 12px 16px; font-size: 12px; color: var(--muted);
      display: flex; align-items: center; gap: 8px;
    }
  </style>
</head>
<body>

<header>
  <div class="logo-mark">&#10022;</div>
  <div class="header-text">
    <h1>News Monitor</h1>
    <p>Bedrock &#215; Brave Search &#215; SES</p>
  </div>
  <div class="status-badge"><div class="status-dot"></div>Ready</div>
</header>

<nav class="tab-nav">
  <button class="tab-btn active" onclick="switchTab('chat', this)">&#128172; &#12481;&#12515;&#12483;&#12488;</button>
  <button class="tab-btn" onclick="switchTab('monitor', this)">&#128203; &#30417;&#35222;&#12450;&#12452;&#12486;&#12512;</button>
</nav>

<!-- TAB: CHAT -->
<div id="tab-chat" class="tab-panel active">
  <div class="config-bar">
    <span class="config-label">Chat API URL</span>
    <input type="text" id="api-url" class="config-input" placeholder="${api_endpoint}/bedrock" />
  </div>
  <div id="messages">
    <div class="welcome" id="welcome">
      <div class="welcome-icon">&#10022;</div>
      <h2>&#20309;&#12391;&#12418;&#32862;&#12356;&#12390;&#12367;&#12384;&#12373;&#12356;</h2>
      <p>&#19978;&#12398;&#12501;&#12457;&#12540;&#12512;&#12395;API Gateway&#12398;URL&#12434;&#20837;&#21147;&#12375;&#12289;&#19979;&#12398;&#12486;&#12461;&#12473;&#12488;&#12508;&#12483;&#12463;&#12473;&#12391;Claude&#12392;&#20250;&#35441;&#12391;&#12365;&#12414;&#12377;&#12290;</p>
      <div class="welcome-hint">
        <div class="hint-chip" onclick="useHint(this)">Terraform&#12395;&#12388;&#12356;&#12390;&#25르&#12360;&#12390;</div>
        <div class="hint-chip" onclick="useHint(this)">AWS&#12398;&#12505;&#12473;&#12488;&#12503;&#12521;&#12463;&#12486;&#12451;&#12473;&#12399;&#65311;</div>
        <div class="hint-chip" onclick="useHint(this)">Lambda&#12398;&#26009;&#37329;&#12434;&#25르&#12360;&#12390;</div>
      </div>
    </div>
  </div>
  <div class="input-area">
    <div class="input-row">
      <textarea id="prompt-input" rows="1" placeholder="&#12513;&#12483;&#12475;&#12540;&#12472;&#12434;&#20837;&#21147;&#8230; (Shift+Enter &#12391;&#25913;&#34892;)"></textarea>
      <button id="clear-btn" onclick="clearChat()">&#12463;&#12522;&#12450;</button>
      <button id="send-btn" onclick="sendMessage()">
        <svg viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
          <line x1="22" y1="2" x2="11" y2="13"/>
          <polygon points="22 2 15 22 11 13 2 9 22 2"/>
        </svg>
      </button>
    </div>
    <div class="input-hint">Enter &#12391;&#36865;&#20449; &middot; Shift+Enter &#12391;&#25913;&#34892;</div>
  </div>
</div>

<!-- TAB: MONITOR ITEMS -->
<div id="tab-monitor" class="tab-panel">
  <div class="items-panel">
    <div class="schedule-info">
      &#9200; &#30331;&#37682;&#12373;&#12428;&#12383;&#12461;&#12540;&#12527;&#12540;&#12489;&#12399;&#23450;&#26399;&#30340;&#12395;&#33258;&#21205;&#26908;&#32034;&#12373;&#12428;&#12289;&#25351;&#23450;&#12398;&#12513;&#12540;&#12523;&#12450;&#12489;&#12524;&#12473;&#12395;&#26368;&#26032;&#24773;&#22577;&#12364;&#36890;&#30693;&#12373;&#12428;&#12414;&#12377;&#12290;
    </div>
    <div class="register-card">
      <div class="card-title">&#65291; &#30417;&#35222;&#12450;&#12452;&#12486;&#12512;&#12434;&#30331;&#37682;</div>
      <div class="form-grid">
        <div class="form-field">
          <label class="form-label">&#12461;&#12540;&#12527;&#12540;&#12489;</label>
          <input type="text" id="item-keyword" class="form-input" placeholder="&#20363;: AWS re:Invent 2025" />
        </div>
        <div class="form-field">
          <label class="form-label">&#36890;&#30693;&#12513;&#12540;&#12523;&#12450;&#12489;&#12524;&#12473;</label>
          <input type="email" id="item-email" class="form-input" placeholder="&#20363;: you@example.com" />
        </div>
        <button class="btn-primary" id="register-btn" onclick="registerItem()">&#30331;&#37682;</button>
      </div>
      <div id="register-message" class="form-message"></div>
    </div>
    <div class="items-list-card">
      <div class="card-header">
        <div class="card-title" style="margin-bottom:0">&#128203; &#30331;&#37682;&#28168;&#12415;&#12450;&#12452;&#12486;&#12512;</div>
        <button class="btn-secondary" onclick="loadItems()">&#8635; &#26356;&#26032;</button>
      </div>
      <div id="items-list"><div class="items-loading">&#35501;&#12415;&#36796;&#12415;&#20013;&#8230;</div></div>
    </div>
  </div>
</div>

<script>
  const ITEMS_API = '${items_api_endpoint}';

  function switchTab(name, btn) {
    document.querySelectorAll('.tab-panel').forEach(function(p){ p.classList.remove('active'); });
    document.querySelectorAll('.tab-btn').forEach(function(b){ b.classList.remove('active'); });
    document.getElementById('tab-' + name).classList.add('active');
    btn.classList.add('active');
    if (name === 'monitor') loadItems();
  }

  var conversationHistory = [];
  var isLoading = false;
  var promptInput = document.getElementById('prompt-input');
  promptInput.addEventListener('input', function() {
    promptInput.style.height = 'auto';
    promptInput.style.height = Math.min(promptInput.scrollHeight, 160) + 'px';
  });
  promptInput.addEventListener('keydown', function(e) {
    if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); sendMessage(); }
  });
  function useHint(el) { promptInput.value = el.textContent; promptInput.focus(); }

  function clearChat() {
    conversationHistory = [];
    var msgs = document.getElementById('messages');
    msgs.innerHTML = '';
    var w = document.createElement('div');
    w.className = 'welcome'; w.id = 'welcome';
    w.innerHTML = '<div class="welcome-icon">&#10022;</div><h2>&#20309;&#12391;&#12418;&#32862;&#12356;&#12390;&#12367;&#12384;&#12373;&#12356;</h2>'
      + '<p>&#19978;&#12398;&#12501;&#12457;&#12540;&#12512;&#12395;API Gateway&#12398;URL&#12434;&#20837;&#21147;&#12375;&#12289;&#19979;&#12398;&#12486;&#12461;&#12473;&#12488;&#12508;&#12483;&#12463;&#12473;&#12391;Claude&#12392;&#20250;&#35441;&#12391;&#12365;&#12414;&#12377;&#12290;</p>'
      + '<div class="welcome-hint">'
      + '<div class="hint-chip" onclick="useHint(this)">Terraform&#12395;&#12388;&#12356;&#12390;&#25르&#12360;&#12390;</div>'
      + '<div class="hint-chip" onclick="useHint(this)">AWS&#12398;&#12505;&#12473;&#12488;&#12503;&#12521;&#12463;&#12486;&#12451;&#12473;&#12399;&#65311;</div>'
      + '<div class="hint-chip" onclick="useHint(this)">Lambda&#12398;&#26009;&#37329;&#12434;&#25르&#12360;&#12390;</div>'
      + '</div>';
    msgs.appendChild(w);
  }

  function appendMessage(role, text, meta) {
    var w = document.getElementById('welcome'); if (w) w.remove();
    var msgs = document.getElementById('messages');
    var wrap = document.createElement('div'); wrap.className = 'message ' + role;
    var av = document.createElement('div'); av.className = 'avatar';
    av.textContent = role === 'user' ? String.fromCodePoint(0x1F464) : String.fromCodePoint(0x272A);
    var right = document.createElement('div');
    var bubble = document.createElement('div'); bubble.className = 'bubble'; bubble.textContent = text;
    right.appendChild(bubble);
    var me = document.createElement('div'); me.className = 'bubble-meta';
    me.textContent = new Date().toLocaleTimeString('ja-JP', {hour:'2-digit', minute:'2-digit'}); right.appendChild(me);
    if (meta && (meta.input_tokens || meta.output_tokens)) {
      var s = document.createElement('div'); s.className = 'token-stats';
      s.innerHTML = '<span>in: ' + (meta.input_tokens || '-') + '</span><span>out: ' + (meta.output_tokens || '-') + '</span>';
      right.appendChild(s);
    }
    wrap.appendChild(av); wrap.appendChild(right); msgs.appendChild(wrap); msgs.scrollTop = msgs.scrollHeight;
    return bubble;
  }

  function showTyping() {
    var w = document.getElementById('welcome'); if (w) w.remove();
    var msgs = document.getElementById('messages');
    var wrap = document.createElement('div'); wrap.className = 'message ai'; wrap.id = 'typing-msg';
    var av = document.createElement('div'); av.className = 'avatar'; av.textContent = String.fromCodePoint(0x272A);
    var bubble = document.createElement('div'); bubble.className = 'bubble';
    bubble.innerHTML = '<div class="typing-indicator"><span></span><span></span><span></span></div>';
    wrap.appendChild(av); wrap.appendChild(bubble); msgs.appendChild(wrap); msgs.scrollTop = msgs.scrollHeight;
  }
  function hideTyping() { var el = document.getElementById('typing-msg'); if (el) el.remove(); }

  async function sendMessage() {
    if (isLoading) return;
    var apiUrl = document.getElementById('api-url').value.trim();
    var prompt = promptInput.value.trim();
    if (!apiUrl) { alert('API Gateway\u306e URL \u3092\u5165\u529b\u3057\u3066\u304f\u3060\u3055\u3044\u3002'); document.getElementById('api-url').focus(); return; }
    if (!prompt) return;
    conversationHistory.push({role:'user', content:prompt});
    appendMessage('user', prompt);
    promptInput.value = ''; promptInput.style.height = 'auto';
    isLoading = true; document.getElementById('send-btn').disabled = true; showTyping();
    try {
      var res = await fetch(apiUrl, { method:'POST', headers:{'Content-Type':'application/json'}, body: JSON.stringify({messages: conversationHistory}) });
      hideTyping();
      if (!res.ok) { var t = await res.text(); throw new Error('HTTP ' + res.status + ': ' + t); }
      var data = await res.json();
      var parsed = data;
      if (typeof data.body === 'string') { try { parsed = JSON.parse(data.body); } catch(e) { parsed = data; } }
      var reply = parsed.response || parsed.message || parsed.content || JSON.stringify(parsed);
      var meta  = { input_tokens: parsed.input_tokens || null, output_tokens: parsed.output_tokens || null };
      conversationHistory.push({role:'assistant', content:reply});
      appendMessage('ai', reply, meta);
    } catch(err) {
      hideTyping(); appendMessage('ai', '\u30a8\u30e9\u30fc\u304c\u767a\u751f\u3057\u307e\u3057\u305f:\n' + err.message).classList.add('error');
      conversationHistory.pop();
    } finally {
      isLoading = false; document.getElementById('send-btn').disabled = false; promptInput.focus();
    }
  }

  async function loadItems() {
    var listEl = document.getElementById('items-list');
    listEl.innerHTML = '<div class="items-loading">\u8aad\u307f\u8fbc\u307f\u4e2d\u2026</div>';
    try {
      var res = await fetch(ITEMS_API + '/items');
      if (!res.ok) throw new Error('HTTP ' + res.status);
      var data = await res.json();
      renderItems(data.items || []);
    } catch(err) {
      listEl.innerHTML = '<div class="items-empty" style="color:var(--danger)">\u53d6\u5f97\u306b\u5931\u6557\u3057\u307e\u3057\u305f: ' + err.message + '</div>';
    }
  }

  function renderItems(items) {
    var listEl = document.getElementById('items-list');
    if (items.length === 0) { listEl.innerHTML = '<div class="items-empty">\u767b\u9332\u3055\u308c\u3066\u3044\u308b\u30a2\u30a4\u30c6\u30e0\u306f\u3042\u308a\u307e\u305b\u3093\u3002</div>'; return; }
    listEl.innerHTML = '';
    items.forEach(function(item) {
      var row = document.createElement('div'); row.className = 'item-row'; row.id = 'item-' + item.item_id;
      var dateStr = item.created_at ? new Date(item.created_at).toLocaleDateString('ja-JP', {year:'numeric',month:'2-digit',day:'2-digit'}) : '';
      var lastSearched = item.last_searched_at
        ? '\u6700\u7d42\u691c\u7d22: ' + new Date(item.last_searched_at).toLocaleString('ja-JP', {month:'2-digit',day:'2-digit',hour:'2-digit',minute:'2-digit'})
        : '\u672a\u691c\u7d22';
      row.innerHTML = '<div class="item-keyword">\uD83D\uDD0D ' + escHtml(item.keyword) + '</div>'
        + '<div class="item-email">\uD83D\uDCE7 ' + escHtml(item.email) + '</div>'
        + '<div class="item-date" title="' + escHtml(lastSearched) + '">' + dateStr + '</div>'
        + '<span class="item-badge">\u6709\u52b9</span>'
        + '<button class="btn-delete" onclick="deleteItem(\'' + item.item_id + '\', this)">\u524a\u9664</button>';
      listEl.appendChild(row);
    });
  }

  async function registerItem() {
    var keyword = document.getElementById('item-keyword').value.trim();
    var email   = document.getElementById('item-email').value.trim();
    var msgEl   = document.getElementById('register-message');
    var btn     = document.getElementById('register-btn');
    msgEl.textContent = ''; msgEl.className = 'form-message';
    if (!keyword) { setMsg(msgEl, 'error', '\u30ad\u30fc\u30ef\u30fc\u30c9\u3092\u5165\u529b\u3057\u3066\u304f\u3060\u3055\u3044\u3002'); return; }
    if (!email)   { setMsg(msgEl, 'error', '\u30e1\u30fc\u30eb\u30a2\u30c9\u30ec\u30b9\u3092\u5165\u529b\u3057\u3066\u304f\u3060\u3055\u3044\u3002'); return; }
    if (!isValidEmail(email)) { setMsg(msgEl, 'error', '\u6709\u52b9\u306a\u30e1\u30fc\u30eb\u30a2\u30c9\u30ec\u30b9\u3092\u5165\u529b\u3057\u3066\u304f\u3060\u3055\u3044\u3002'); return; }
    btn.disabled = true; btn.textContent = '\u767b\u9332\u4e2d\u2026';
    try {
      var res = await fetch(ITEMS_API + '/items', { method:'POST', headers:{'Content-Type':'application/json'}, body: JSON.stringify({keyword: keyword, email: email}) });
      if (!res.ok) { var e = await res.json().catch(function(){ return {}; }); throw new Error(e.error || 'HTTP ' + res.status); }
      setMsg(msgEl, 'success', '\u2713 \u767b\u9332\u3057\u307e\u3057\u305f');
      document.getElementById('item-keyword').value = '';
      document.getElementById('item-email').value   = '';
      loadItems();
    } catch(err) { setMsg(msgEl, 'error', '\u767b\u9332\u306b\u5931\u6557\u3057\u307e\u3057\u305f: ' + err.message); }
    finally { btn.disabled = false; btn.textContent = '\u767b\u9332'; }
  }

  async function deleteItem(itemId, btn) {
    if (!confirm('\u3053\u306e\u30a2\u30a4\u30c6\u30e0\u3092\u524a\u9664\u3057\u307e\u3059\u304b\uff1f')) return;
    btn.disabled = true; btn.textContent = '\u524a\u9664\u4e2d\u2026';
    try {
      var res = await fetch(ITEMS_API + '/items/' + itemId, { method:'DELETE' });
      if (!res.ok) throw new Error('HTTP ' + res.status);
      var row = document.getElementById('item-' + itemId);
      if (row) { row.style.opacity='0'; row.style.transition='opacity .3s'; setTimeout(function(){ row.remove(); }, 300); }
      setTimeout(function() {
        var l = document.getElementById('items-list');
        if (l.children.length === 0) l.innerHTML = '<div class="items-empty">\u767b\u9332\u3055\u308c\u3066\u3044\u308b\u30a2\u30a4\u30c6\u30e0\u306f\u3042\u308a\u307e\u305b\u3093\u3002</div>';
      }, 400);
    } catch(err) { alert('\u524a\u9664\u306b\u5931\u6557\u3057\u307e\u3057\u305f: ' + err.message); btn.disabled=false; btn.textContent='\u524a\u9664'; }
  }

  function setMsg(el, type, text) {
    el.textContent = text; el.className = 'form-message ' + type;
    if (type === 'success') setTimeout(function(){ el.textContent=''; }, 4000);
  }
  function isValidEmail(v) { return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v); }
  function escHtml(s) { return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;'); }
</script>
</body>
</html>"""

with open(r'c:\Users\Haruya\gitcode\AWS_Terraform\search_the_latest_news\website\index.html.tmp', 'w', encoding='utf-8') as f:
    f.write(html)
print("Written", len(html), "chars")
