/**
 * Scout Stats Card Component
 * 플러그인 통계를 표시하는 카드 컴포넌트
 */

import { MonolComponent } from '/design-system/component-base.js';

export class ScoutStatsCard extends MonolComponent {
  constructor(container, options = {}) {
    super(container, options);
    this.state = {
      stats: options.stats || {
        installed: 0,
        active: 0,
        score: 0,
        updates: 0
      }
    };
  }

  async init() {
    if (this.options.apiUrl) {
      await this.fetchStats();
    }
    this.render();
  }

  async fetchStats() {
    try {
      const response = await fetch(this.options.apiUrl);
      const data = await response.json();
      this.state.stats = data;
    } catch (error) {
      console.error('Failed to fetch stats:', error);
    }
  }

  render() {
    const { stats } = this.state;

    this.container.innerHTML = this.html`
      <div class="scout-stats-grid">
        <div class="stat-card" data-stat="installed">
          <div class="stat-icon">🔌</div>
          <div class="stat-content">
            <div class="stat-value">${stats.installed}</div>
            <div class="stat-label">Installed</div>
          </div>
        </div>
        <div class="stat-card" data-stat="active">
          <div class="stat-icon">✅</div>
          <div class="stat-content">
            <div class="stat-value">${stats.active}</div>
            <div class="stat-label">Active</div>
          </div>
        </div>
        <div class="stat-card" data-stat="score">
          <div class="stat-icon">⭐</div>
          <div class="stat-content">
            <div class="stat-value">${stats.score}</div>
            <div class="stat-label">Avg Score</div>
          </div>
        </div>
        <div class="stat-card" data-stat="updates">
          <div class="stat-icon">🔄</div>
          <div class="stat-content">
            <div class="stat-value">${stats.updates}</div>
            <div class="stat-label">Updates</div>
          </div>
        </div>
      </div>
    `;

    // 클릭 이벤트 바인딩
    this.container.querySelectorAll('.stat-card').forEach(card => {
      card.addEventListener('click', () => {
        const statType = card.dataset.stat;
        this.emit('stat-click', { type: statType, value: stats[statType] });
      });
    });
  }

  updateStats(newStats) {
    this.setState({ stats: { ...this.state.stats, ...newStats } });
  }
}

// CSS 스타일 (컴포넌트 전용)
const style = document.createElement('style');
style.textContent = `
  .scout-stats-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(140px, 1fr));
    gap: 16px;
  }
  .scout-stats-grid .stat-card {
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 16px;
    background: var(--bg-secondary);
    border: 1px solid var(--border-color);
    border-radius: var(--radius-md, 8px);
    cursor: pointer;
    transition: all 0.2s;
  }
  .scout-stats-grid .stat-card:hover {
    border-color: var(--accent-blue);
    transform: translateY(-2px);
  }
  .scout-stats-grid .stat-icon {
    font-size: 24px;
  }
  .scout-stats-grid .stat-value {
    font-size: 24px;
    font-weight: 700;
    color: var(--text-primary);
  }
  .scout-stats-grid .stat-label {
    font-size: 12px;
    color: var(--text-secondary);
  }
`;
document.head.appendChild(style);

export default ScoutStatsCard;
