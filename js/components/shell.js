/**
 * Shared app shell: sidebar, topbar, auth checks, theme, badges
 */
import { requireAuth, signOut, getSupabase } from '../supabase-client.js';
import { getProfile, isAdmin } from '../services/auth-service.js';

const NAV_ITEMS = [
  { href: '/app/', icon: '🏠', label: 'Home', id: 'home' },
  { href: '/app/groups.html', icon: '👥', label: 'Groups', id: 'groups' },
  { href: '/app/resources.html', icon: '📚', label: 'Resources', id: 'resources' },
  { href: '/app/messages.html', icon: '💬', label: 'Messages', id: 'messages', badge: 'msgBadge' },
  { href: '/app/events.html', icon: '📅', label: 'Events', id: 'events' },
  { href: '/app/opportunities.html', icon: '🎯', label: 'Opportunities', id: 'opportunities' },
  { href: '/app/notifications.html', icon: '🔔', label: 'Notifications', id: 'notifications', badge: 'notifBadge' },
  { href: '/app/profile.html', icon: '👤', label: 'Profile', id: 'profile' },
  { href: '/app/settings.html', icon: '⚙️', label: 'Settings', id: 'settings' }
];

export async function initShell(activeId = 'home') {
  const user = await requireAuth();
  if (!user) return null;

  const profile = await getProfile();
  const admin = await isAdmin();

  // Theme
  if (localStorage.getItem('studeco-theme') === 'dark') {
    document.documentElement.setAttribute('data-theme', 'dark');
  }

  // Wire common elements if present
  const signOutBtn = document.getElementById('signOutBtn');
  if (signOutBtn) signOutBtn.addEventListener('click', () => signOut());

  const sidebarToggle = document.getElementById('sidebarToggle');
  if (sidebarToggle) {
    sidebarToggle.addEventListener('click', () => {
      document.getElementById('sidebar')?.classList.toggle('open');
    });
  }

  const themeToggle = document.getElementById('themeToggle');
  if (themeToggle) {
    themeToggle.addEventListener('click', () => {
      const current = document.documentElement.getAttribute('data-theme');
      const next = current === 'dark' ? 'light' : 'dark';
      document.documentElement.setAttribute('data-theme', next);
      localStorage.setItem('studeco-theme', next);
    });
  }

  const avatar = document.getElementById('userAvatar');
  if (avatar && profile) {
    avatar.textContent = (profile.display_name || '?')[0].toUpperCase();
    if (profile.avatar_url) {
      avatar.style.backgroundImage = `url(${profile.avatar_url})`;
      avatar.style.backgroundSize = 'cover';
      avatar.textContent = '';
    }
  }

  const adminLink = document.getElementById('adminLink');
  if (adminLink && admin) adminLink.hidden = false;

  // Highlight active nav
  document.querySelectorAll('.nav-item').forEach(el => {
    const href = el.getAttribute('href');
    if (href && window.location.pathname.endsWith(href.replace(/^\//, '')) ||
        (activeId === 'home' && (window.location.pathname === '/app/' || window.location.pathname.endsWith('/app/index.html')))) {
      el.classList.add('active');
    }
  });

  // Unread counts
  loadBadges(user.id);

  return { user, profile, admin };
}

async function loadBadges(userId) {
  const supabase = getSupabase();
  try {
    const { count: notifCount } = await supabase
      .from('notifications')
      .select('*', { count: 'exact', head: true })
      .eq('user_id', userId)
      .eq('is_read', false);

    const badge = document.getElementById('notifBadge');
    if (badge && notifCount > 0) {
      badge.textContent = notifCount > 99 ? '99+' : notifCount;
      badge.hidden = false;
    }
  } catch (_) {}
}

export function renderSidebarNav(activeId) {
  return NAV_ITEMS.map(item => `
    <a href="${item.href}" class="nav-item ${item.id === activeId ? 'active' : ''}">
      <span class="nav-icon">${item.icon}</span> ${item.label}
      ${item.badge ? `<span class="badge" id="${item.badge}" hidden>0</span>` : ''}
    </a>
  `).join('') + `
    <a href="/admin/" class="nav-item admin-link" id="adminLink" hidden>
      <span class="nav-icon">🛡️</span> Admin
    </a>
  `;
}

export default { initShell, renderSidebarNav };
