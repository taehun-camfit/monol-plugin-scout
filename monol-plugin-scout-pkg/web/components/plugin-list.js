/**
 * Scout Plugin List Component
 * 설치된 플러그인 목록을 표시하는 컴포넌트
 */

import { MonolComponent } from '/design-system/component-base.js';

export class ScoutPluginList extends MonolComponent {
  constructor(container, options = {}) {
    super(container, options);
    this.state = {
      plugins: options.plugins || [],
      filter: 'all',
      sortBy: 'name',
      selectedId: null
    };
  }

  async init() {
    if (this.options.apiUrl) {
      await this.fetchPlugins();
    }
    this.render();
  }

  async fetchPlugins() {
    try {
      const response = await fetch(this.options.apiUrl);
      const data = await response.json();
      this.state.plugins = data;
    } catch (error) {
      console.error('Failed to fetch plugins:', error);
    }
  }

  getFilteredPlugins() {
    let plugins = [...this.state.plugins];

    // 필터 적용
    if (this.state.filter !== 'all') {
      plugins = plugins.filter(p => p.status === this.state.filter);
    }

    // 정렬 적용
    plugins.sort((a, b) => {
      switch (this.state.sortBy) {
        case 'score': return (b.score || 0) - (a.score || 0);
        case 'usage': return (b.usage || 0) - (a.usage || 0);
        default: return (a.name || '').localeCompare(b.name || '');
      }
    });

    return plugins;
  }

  render() {
    const plugins = this.getFilteredPlugins();

    this.container.innerHTML = this.html`
      <div class="scout-plugin-list">
        <div class="list-header">
          <div class="list-filters">
            <select class="filter-select" data-action="filter">
              <option value="all" ${this.state.filter === 'all' ? 'selected' : ''}>All</option>
              <option value="active" ${this.state.filter === 'active' ? 'selected' : ''}>Active</option>
              <option value="inactive" ${this.state.filter === 'inactive' ? 'selected' : ''}>Inactive</option>
            </select>
            <select class="sort-select" data-action="sort">
              <option value="name" ${this.state.sortBy === 'name' ? 'selected' : ''}>Name</option>
              <option value="score" ${this.state.sortBy === 'score' ? 'selected' : ''}>Score</option>
              <option value="usage" ${this.state.sortBy === 'usage' ? 'selected' : ''}>Usage</option>
            </select>
          </div>
          <span class="list-count">${plugins.length} plugins</span>
        </div>
        <div class="list-items">
          ${plugins.map(plugin => this.renderPlugin(plugin)).join('')}
        </div>
      </div>
    `;

    this.bindEvents();
  }

  renderPlugin(plugin) {
    const isSelected = this.state.selectedId === plugin.id;
    const scoreColor = this.getScoreColor(plugin.score);

    return this.html`
      <div class="plugin-item ${isSelected ? 'selected' : ''}" data-id="${plugin.id}">
        <div class="plugin-icon">${plugin.icon || '🔌'}</div>
        <div class="plugin-info">
          <div class="plugin-name">${plugin.name}</div>
          <div class="plugin-meta">
            <span class="plugin-version">v${plugin.version || '1.0.0'}</span>
            <span class="plugin-status ${plugin.status}">${plugin.status || 'unknown'}</span>
          </div>
        </div>
        <div class="plugin-score" style="color: ${scoreColor}">
          ${plugin.score || '-'}
        </div>
      </div>
    `;
  }

  getScoreColor(score) {
    if (!score) return 'var(--text-muted)';
    if (score >= 90) return 'var(--accent-green)';
    if (score >= 75) return 'var(--accent-blue)';
    if (score >= 60) return 'var(--accent-orange)';
    return 'var(--accent-red)';
  }

  bindEvents() {
    // 필터 변경
    this.container.querySelector('[data-action="filter"]')?.addEventListener('change', (e) => {
      this.state.filter = e.target.value;
      this.render();
      this.emit('filter-change', { filter: this.state.filter });
    });

    // 정렬 변경
    this.container.querySelector('[data-action="sort"]')?.addEventListener('change', (e) => {
      this.state.sortBy = e.target.value;
      this.render();
      this.emit('sort-change', { sortBy: this.state.sortBy });
    });

    // 플러그인 선택
    this.container.querySelectorAll('.plugin-item').forEach(item => {
      item.addEventListener('click', () => {
        const id = item.dataset.id;
        this.state.selectedId = id;
        const plugin = this.state.plugins.find(p => p.id === id);
        this.render();
        this.emit('plugin-select', plugin);
      });
    });
  }

  selectPlugin(id) {
    this.state.selectedId = id;
    this.render();
  }

  highlightPlugins(ids) {
    this.container.querySelectorAll('.plugin-item').forEach(item => {
      if (ids.includes(item.dataset.id)) {
        item.classList.add('highlighted');
      } else {
        item.classList.remove('highlighted');
      }
    });
  }
}

// CSS 스타일
const style = document.createElement('style');
style.textContent = `
  .scout-plugin-list {
    background: var(--bg-secondary);
    border: 1px solid var(--border-color);
    border-radius: var(--radius-md, 8px);
    overflow: hidden;
  }
  .scout-plugin-list .list-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 12px 16px;
    border-bottom: 1px solid var(--border-color);
    background: var(--bg-tertiary);
  }
  .scout-plugin-list .list-filters {
    display: flex;
    gap: 8px;
  }
  .scout-plugin-list select {
    padding: 6px 10px;
    background: var(--bg-secondary);
    border: 1px solid var(--border-color);
    border-radius: 6px;
    color: var(--text-primary);
    font-size: 12px;
  }
  .scout-plugin-list .list-count {
    font-size: 12px;
    color: var(--text-secondary);
  }
  .scout-plugin-list .list-items {
    max-height: 400px;
    overflow-y: auto;
  }
  .scout-plugin-list .plugin-item {
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 12px 16px;
    border-bottom: 1px solid var(--border-color);
    cursor: pointer;
    transition: background 0.2s;
  }
  .scout-plugin-list .plugin-item:hover {
    background: var(--bg-hover);
  }
  .scout-plugin-list .plugin-item.selected {
    background: var(--bg-active, rgba(56, 139, 253, 0.1));
    border-left: 3px solid var(--accent-blue);
  }
  .scout-plugin-list .plugin-item.highlighted {
    background: var(--bg-active, rgba(56, 139, 253, 0.1));
  }
  .scout-plugin-list .plugin-icon {
    font-size: 20px;
  }
  .scout-plugin-list .plugin-info {
    flex: 1;
  }
  .scout-plugin-list .plugin-name {
    font-weight: 500;
    color: var(--text-primary);
  }
  .scout-plugin-list .plugin-meta {
    display: flex;
    gap: 8px;
    font-size: 11px;
    color: var(--text-secondary);
  }
  .scout-plugin-list .plugin-status.active {
    color: var(--accent-green);
  }
  .scout-plugin-list .plugin-status.inactive {
    color: var(--text-muted);
  }
  .scout-plugin-list .plugin-score {
    font-size: 18px;
    font-weight: 700;
  }
`;
document.head.appendChild(style);

export default ScoutPluginList;
