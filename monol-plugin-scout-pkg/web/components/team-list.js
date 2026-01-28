/**
 * Scout Team List Component
 * 팀원 목록 컴포넌트
 */

import { MonolComponent } from '/design-system/component-base.js';

export class ScoutTeamList extends MonolComponent {
  constructor(container, options = {}) {
    super(container, options);
    this.state = {
      members: options.members || [],
      view: 'grid', // grid, list
      loading: true
    };
  }

  async init() {
    if (this.options.apiUrl) {
      await this.fetchMembers();
    } else {
      this.state.members = this.getMockMembers();
    }
    this.state.loading = false;
    this.render();
  }

  getMockMembers() {
    return [
      { id: 'mem-001', name: 'Alice', role: 'Tech Lead', avatar: 'A', plugins: 12, sessions: 156, lastActive: '2h ago', status: 'online' },
      { id: 'mem-002', name: 'Bob', role: 'Backend Dev', avatar: 'B', plugins: 8, sessions: 89, lastActive: '30m ago', status: 'online' },
      { id: 'mem-003', name: 'Charlie', role: 'Frontend Dev', avatar: 'C', plugins: 15, sessions: 124, lastActive: '1d ago', status: 'offline' },
      { id: 'mem-004', name: 'David', role: 'DevOps', avatar: 'D', plugins: 6, sessions: 45, lastActive: '3h ago', status: 'online' },
      { id: 'mem-005', name: 'Eve', role: 'QA Engineer', avatar: 'E', plugins: 9, sessions: 67, lastActive: '2d ago', status: 'offline' }
    ];
  }

  async fetchMembers() {
    try {
      const response = await fetch(this.options.apiUrl);
      this.state.members = await response.json();
    } catch (error) {
      console.error('Failed to fetch team members:', error);
      this.state.members = this.getMockMembers();
    }
  }

  render() {
    const { members, loading, view } = this.state;
    const onlineCount = members.filter(m => m.status === 'online').length;

    if (loading) {
      this.container.innerHTML = this.html`
        <div class="scout-team-list loading">
          <div class="loading-spinner"></div>
        </div>
      `;
      return;
    }

    this.container.innerHTML = this.html`
      <div class="scout-team-list">
        <div class="list-header">
          <div class="header-left">
            <h3>Team Members</h3>
            <span class="online-indicator">
              <span class="online-dot"></span>
              ${onlineCount} online
            </span>
          </div>
          <div class="view-toggle">
            <button class="view-btn ${view === 'grid' ? 'active' : ''}" data-view="grid" title="Grid View">
              &#x25A6;
            </button>
            <button class="view-btn ${view === 'list' ? 'active' : ''}" data-view="list" title="List View">
              &#x2630;
            </button>
          </div>
        </div>
        <div class="member-container ${view}">
          ${members.map(m => this.renderMember(m)).join('')}
        </div>
      </div>
    `;

    this.bindEvents();
  }

  renderMember(member) {
    const statusClass = member.status === 'online' ? 'status-online' : 'status-offline';

    return this.html`
      <div class="member-card ${statusClass}" data-id="${member.id}">
        <div class="member-avatar">
          <span class="avatar-text">${member.avatar}</span>
          <span class="status-dot ${statusClass}"></span>
        </div>
        <div class="member-info">
          <div class="member-name">${member.name}</div>
          <div class="member-role">${member.role}</div>
          <div class="member-stats">
            <span class="stat">&#x1F50C; ${member.plugins}</span>
            <span class="stat">&#x1F4AC; ${member.sessions}</span>
          </div>
          <div class="member-activity">Last: ${member.lastActive}</div>
        </div>
        <div class="member-actions">
          <button class="action-btn message-btn" title="Message">&#x1F4E9;</button>
          <button class="action-btn profile-btn" title="Profile">&#x1F464;</button>
        </div>
      </div>
    `;
  }

  bindEvents() {
    // View toggle
    this.container.querySelectorAll('.view-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        this.state.view = btn.dataset.view;
        this.render();
      });
    });

    // Member actions
    this.container.querySelectorAll('.member-card').forEach(card => {
      const id = card.dataset.id;
      const member = this.state.members.find(m => m.id === id);

      card.addEventListener('click', () => {
        this.emit('member-select', member);
      });

      card.querySelector('.message-btn')?.addEventListener('click', (e) => {
        e.stopPropagation();
        this.emit('member-message', member);
      });

      card.querySelector('.profile-btn')?.addEventListener('click', (e) => {
        e.stopPropagation();
        this.emit('member-profile', member);
      });
    });
  }
}

// CSS
const style = document.createElement('style');
style.textContent = `
  .scout-team-list {
    background: var(--bg-secondary);
    border: 1px solid var(--border-color);
    border-radius: var(--radius-md, 8px);
    padding: 16px;
  }
  .scout-team-list.loading {
    display: flex;
    justify-content: center;
    align-items: center;
    min-height: 200px;
  }
  .scout-team-list .loading-spinner {
    width: 24px;
    height: 24px;
    border: 2px solid var(--border-color);
    border-top-color: var(--accent-cyan);
    border-radius: 50%;
    animation: spin 1s linear infinite;
  }
  .scout-team-list .list-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 16px;
  }
  .scout-team-list .header-left {
    display: flex;
    align-items: center;
    gap: 12px;
  }
  .scout-team-list .list-header h3 {
    font-size: 14px;
    font-weight: 600;
    margin: 0;
  }
  .scout-team-list .online-indicator {
    display: flex;
    align-items: center;
    gap: 6px;
    font-size: 12px;
    color: var(--text-secondary);
  }
  .scout-team-list .online-dot {
    width: 8px;
    height: 8px;
    background: var(--accent-green);
    border-radius: 50%;
  }
  .scout-team-list .view-toggle {
    display: flex;
    gap: 4px;
    background: var(--bg-tertiary);
    padding: 2px;
    border-radius: 4px;
  }
  .scout-team-list .view-btn {
    padding: 4px 8px;
    border: none;
    background: none;
    border-radius: 2px;
    font-size: 12px;
    cursor: pointer;
    color: var(--text-secondary);
    transition: all 0.2s;
  }
  .scout-team-list .view-btn:hover {
    color: var(--text-primary);
  }
  .scout-team-list .view-btn.active {
    background: var(--bg-secondary);
    color: var(--accent-cyan);
  }
  .scout-team-list .member-container {
    display: flex;
    flex-direction: column;
    gap: 8px;
    max-height: 350px;
    overflow-y: auto;
  }
  .scout-team-list .member-container.grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
    gap: 12px;
  }
  .scout-team-list .member-card {
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 12px;
    background: var(--bg-tertiary);
    border: 1px solid var(--border-color);
    border-radius: 8px;
    cursor: pointer;
    transition: all 0.2s;
  }
  .scout-team-list .member-card:hover {
    border-color: var(--accent-cyan);
  }
  .scout-team-list .member-card.status-online {
    border-left: 3px solid var(--accent-green);
  }
  .scout-team-list .member-avatar {
    position: relative;
    width: 40px;
    height: 40px;
    background: linear-gradient(135deg, var(--accent-cyan), var(--accent-purple, #A371F7));
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
  }
  .scout-team-list .avatar-text {
    font-size: 16px;
    font-weight: 600;
    color: #000;
  }
  .scout-team-list .status-dot {
    position: absolute;
    bottom: 0;
    right: 0;
    width: 10px;
    height: 10px;
    border-radius: 50%;
    border: 2px solid var(--bg-tertiary);
  }
  .scout-team-list .status-dot.status-online {
    background: var(--accent-green);
  }
  .scout-team-list .status-dot.status-offline {
    background: var(--text-muted);
  }
  .scout-team-list .member-info {
    flex: 1;
    min-width: 0;
  }
  .scout-team-list .member-name {
    font-size: 13px;
    font-weight: 500;
    color: var(--text-primary);
  }
  .scout-team-list .member-role {
    font-size: 11px;
    color: var(--accent-cyan);
    margin-bottom: 4px;
  }
  .scout-team-list .member-stats {
    display: flex;
    gap: 10px;
    font-size: 11px;
    color: var(--text-secondary);
  }
  .scout-team-list .member-activity {
    font-size: 10px;
    color: var(--text-muted);
    margin-top: 2px;
  }
  .scout-team-list .member-actions {
    display: flex;
    flex-direction: column;
    gap: 4px;
    opacity: 0;
    transition: opacity 0.2s;
  }
  .scout-team-list .member-card:hover .member-actions {
    opacity: 1;
  }
  .scout-team-list .action-btn {
    background: none;
    border: none;
    cursor: pointer;
    font-size: 12px;
    padding: 4px;
    border-radius: 4px;
    transition: all 0.2s;
  }
  .scout-team-list .action-btn:hover {
    background: var(--bg-primary);
  }
  .member-container.grid .member-card {
    flex-direction: column;
    text-align: center;
  }
  .member-container.grid .member-info {
    width: 100%;
  }
  .member-container.grid .member-stats {
    justify-content: center;
  }
  .member-container.grid .member-actions {
    flex-direction: row;
    opacity: 1;
  }
`;
document.head.appendChild(style);

export default ScoutTeamList;
