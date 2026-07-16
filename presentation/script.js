/* ═══════════════════════════════════════════════════════════════════════
   FlexiKeys — Presentation engine
   Keyboard / wheel / touch navigation, progress, notes, fullscreen, zoom.
   ═══════════════════════════════════════════════════════════════════════ */

(function () {
  'use strict';

  const slides = Array.from(document.querySelectorAll('.slide'));
  const total = slides.length;
  let current = 0;
  let isAnimating = false;

  const progressFill = document.getElementById('progressFill');
  const slideNumEl = document.getElementById('slideNum');
  const slideTotalEl = document.getElementById('slideTotal');
  const dotNav = document.getElementById('dotNav');
  const prevBtn = document.getElementById('prevBtn');
  const nextBtn = document.getElementById('nextBtn');
  const notesPanel = document.getElementById('notesPanel');
  const notesBody = document.getElementById('notesBody');
  const notesToggle = document.getElementById('notesToggle');
  const notesClose = document.getElementById('notesClose');
  const themeToggle = document.getElementById('themeToggle');
  const fullscreenToggle = document.getElementById('fullscreenToggle');

  slideTotalEl.textContent = total;

  // ── Build dot navigation ────────────────────────────────────────────────
  slides.forEach((_, i) => {
    const dot = document.createElement('button');
    dot.setAttribute('aria-label', `Go to slide ${i + 1}`);
    dot.addEventListener('click', () => goTo(i));
    dotNav.appendChild(dot);
  });
  const dots = Array.from(dotNav.children);

  // ── Speaker notes extraction ────────────────────────────────────────────
  const notesBySlide = slides.map((slide) => {
    const tag = slide.querySelector('script[type="text/notes"]');
    return tag ? tag.textContent.trim() : 'No notes for this slide.';
  });

  function formatNotes(raw) {
    // Bold the "Presenter says / Estimated time / Transition / Screenshots" labels.
    return raw
      .split('\n')
      .map((line) => {
        const m = line.match(/^(Presenter says|Estimated time|Transition|Screenshots shown):\s*(.*)$/);
        if (m) return `<strong>${m[1]}:</strong> ${m[2]}`;
        return line;
      })
      .join('\n');
  }

  // ── Core navigation ──────────────────────────────────────────────────────
  function render() {
    slides.forEach((slide, i) => {
      slide.classList.toggle('active', i === current);
    });
    const pct = ((current + 1) / total) * 100;
    progressFill.style.width = pct + '%';
    slideNumEl.textContent = current + 1;
    dots.forEach((d, i) => d.classList.toggle('active', i === current));
    prevBtn.disabled = current === 0;
    nextBtn.disabled = current === total - 1;
    notesBody.innerHTML = formatNotes(notesBySlide[current]);
    history.replaceState(null, '', `#slide-${current + 1}`);
  }

  function goTo(index) {
    if (index < 0 || index >= total || index === current || isAnimating) return;
    isAnimating = true;
    current = index;
    render();
    window.setTimeout(() => { isAnimating = false; }, 480);
  }

  function next() { goTo(current + 1); }
  function prev() { goTo(current - 1); }

  // ── Restore from URL hash on load ───────────────────────────────────────
  function initFromHash() {
    const m = window.location.hash.match(/slide-(\d+)/);
    if (m) {
      const idx = parseInt(m[1], 10) - 1;
      if (idx >= 0 && idx < total) current = idx;
    }
    render();
  }

  // ── Keyboard navigation ──────────────────────────────────────────────────
  window.addEventListener('keydown', (e) => {
    // Don't hijack typing inside any future input fields.
    if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA') return;

    switch (e.key) {
      case 'ArrowRight':
      case 'ArrowDown':
      case 'PageDown':
      case ' ':
        e.preventDefault();
        next();
        break;
      case 'ArrowLeft':
      case 'ArrowUp':
      case 'PageUp':
        e.preventDefault();
        prev();
        break;
      case 'Home':
        e.preventDefault();
        goTo(0);
        break;
      case 'End':
        e.preventDefault();
        goTo(total - 1);
        break;
      case 'f':
      case 'F':
        toggleFullscreen();
        break;
      case 'n':
      case 'N':
        toggleNotes();
        break;
      case 'Escape':
        closeNotes();
        closeZoom();
        break;
      default:
        break;
    }
  });

  // ── Mouse wheel navigation (debounced to one slide per gesture) ─────────
  let wheelLock = false;
  window.addEventListener(
    'wheel',
    (e) => {
      if (wheelLock) return;
      if (Math.abs(e.deltaY) < 12) return;
      wheelLock = true;
      if (e.deltaY > 0) next(); else prev();
      window.setTimeout(() => { wheelLock = false; }, 550);
    },
    { passive: true }
  );

  // ── Touch swipe navigation ───────────────────────────────────────────────
  let touchStartX = 0;
  let touchStartY = 0;
  window.addEventListener('touchstart', (e) => {
    touchStartX = e.changedTouches[0].clientX;
    touchStartY = e.changedTouches[0].clientY;
  }, { passive: true });

  window.addEventListener('touchend', (e) => {
    const dx = e.changedTouches[0].clientX - touchStartX;
    const dy = e.changedTouches[0].clientY - touchStartY;
    if (Math.abs(dx) < 60 || Math.abs(dx) < Math.abs(dy) * 1.4) return;
    if (dx < 0) next(); else prev();
  }, { passive: true });

  // ── Arrow / dot buttons ──────────────────────────────────────────────────
  prevBtn.addEventListener('click', prev);
  nextBtn.addEventListener('click', next);

  // ── Speaker notes panel ──────────────────────────────────────────────────
  function toggleNotes() {
    notesPanel.classList.toggle('open');
    notesToggle.classList.toggle('active', notesPanel.classList.contains('open'));
  }
  function closeNotes() {
    notesPanel.classList.remove('open');
    notesToggle.classList.remove('active');
  }
  notesToggle.addEventListener('click', toggleNotes);
  notesClose.addEventListener('click', closeNotes);

  // ── Fullscreen ────────────────────────────────────────────────────────────
  function toggleFullscreen() {
    if (!document.fullscreenElement) {
      document.documentElement.requestFullscreen?.().catch(() => {});
    } else {
      document.exitFullscreen?.();
    }
  }
  fullscreenToggle.addEventListener('click', toggleFullscreen);

  // ── Theme toggle (persisted) ─────────────────────────────────────────────
  const THEME_KEY = 'flexikeys-deck-theme';
  function applyTheme(theme) {
    if (theme) document.documentElement.setAttribute('data-theme', theme);
    else document.documentElement.removeAttribute('data-theme');
  }
  function currentSystemPrefersDark() {
    return window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
  }
  const savedTheme = localStorage.getItem(THEME_KEY);
  if (savedTheme) applyTheme(savedTheme);

  themeToggle.addEventListener('click', () => {
    const isDark = document.documentElement.getAttribute('data-theme') === 'dark'
      || (!document.documentElement.getAttribute('data-theme') && currentSystemPrefersDark());
    const next = isDark ? 'light' : 'dark';
    applyTheme(next);
    localStorage.setItem(THEME_KEY, next);
  });

  // ── Image zoom overlay ───────────────────────────────────────────────────
  const zoomOverlay = document.createElement('div');
  zoomOverlay.className = 'zoom-overlay';
  const zoomImg = document.createElement('img');
  zoomOverlay.appendChild(zoomImg);
  document.body.appendChild(zoomOverlay);

  function openZoom(src, alt) {
    zoomImg.src = src;
    zoomImg.alt = alt || '';
    zoomOverlay.classList.add('open');
  }
  function closeZoom() {
    zoomOverlay.classList.remove('open');
  }
  zoomOverlay.addEventListener('click', closeZoom);

  document.querySelectorAll('.zoomable img').forEach((img) => {
    img.addEventListener('click', (e) => {
      e.stopPropagation();
      openZoom(img.src, img.alt);
    });
  });

  // ── Number counting animation (utility, used if any slide adds .count-up) ─
  document.querySelectorAll('[data-count-to]').forEach((el) => {
    const target = parseFloat(el.dataset.countTo);
    const dur = 1200;
    let startTs = null;
    function step(ts) {
      if (!startTs) startTs = ts;
      const p = Math.min((ts - startTs) / dur, 1);
      const eased = 1 - Math.pow(1 - p, 3);
      el.textContent = Math.round(target * eased);
      if (p < 1) requestAnimationFrame(step);
    }
    const obs = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          requestAnimationFrame(step);
          obs.disconnect();
        }
      });
    });
    obs.observe(el);
  });

  // ── Init ──────────────────────────────────────────────────────────────────
  initFromHash();
})();
