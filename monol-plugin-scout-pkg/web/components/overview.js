/**
 * Scout Overview Component
 * 오버뷰 탭 - 다른 컴포넌트들을 조합
 */

import { MonolComponent } from '/design-system/component-base.js';
import { ScoutStatsCard } from './stats-card.js';
import { ScoutPluginList } from './plugin-list.js';
import { ScoutActivityChart } from './activity-chart.js';

export class ScoutOverview extends MonolComponent {
  constructor(container, options = {}) {
    super(container, options);
    this.components = {};
  }

  async init() {
    this.render();
    await this.initComponents();
  }

  render() {
    this.container.innerHTML = this.html`
      <div class="scout-overview">
        <div class="overview-section">
          <div id="scout-stats-container"></div>
        </div>

        <div class="overview-grid">
          <div class="overview-main">
            <div id="scout-chart-container"></div>
          </div>
          <div class="overview-sidebar">
            <h3 class="section-title">Installed Plugins</h3>
            <div id="scout-plugins-container"></div>
          </div>
        </div>
      </div>
    `;
  }

  async initComponents() {
    // Stats Card
    this.components.stats = new ScoutStatsCard(
      this.container.querySelector('#scout-stats-container'),
      {
        apiUrl: this.options.apiBaseUrl ? `${this.options.apiBaseUrl}/stats` : null,
        stats: this.options.stats || { installed: 12, active: 8, score: 85, updates: 3 }
      }
    );
    await this.components.stats.init();

    // Activity Chart
    this.components.chart = new ScoutActivityChart(
      this.container.querySelector('#scout-chart-container'),
      {
        id: 'overview-activity',
        title: 'Plugin Activity',
        apiUrl: this.options.apiBaseUrl ? `${this.options.apiBaseUrl}/activity` : null
      }
    );
    await this.components.chart.init();

    // Plugin List
    this.components.plugins = new ScoutPluginList(
      this.container.querySelector('#scout-plugins-container'),
      {
        apiUrl: this.options.apiBaseUrl ? `${this.options.apiBaseUrl}/plugins` : null,
        plugins: this.options.plugins || this.getMockPlugins()
      }
    );
    await this.components.plugins.init();

    // 컴포넌트 간 이벤트 연결
    this.setupEventHandlers();
  }

  setupEventHandlers() {
    // 플러그인 선택 시 이벤트 발행
    this.components.plugins.on('plugin-select', (plugin) => {
      this.emit('plugin-select', plugin);
    });

    // Stats 클릭 시 필터 적용
    this.components.stats.on('stat-click', ({ type }) => {
      if (type === 'active') {
        this.components.plugins.state.filter = 'active';
        this.components.plugins.render();
      }
    });
  }

  getMockPlugins() {
    return [
      { id: 'code-review', name: 'Code Review', icon: '🔍', version: '1.2.0', status: 'active', score: 92 },
      { id: 'git-helper', name: 'Git Helper', icon: '📦', version: '2.0.1', status: 'active', score: 88 },
      { id: 'test-runner', name: 'Test Runner', icon: '🧪', version: '1.5.0', status: 'active', score: 85 },
      { id: 'doc-gen', name: 'Doc Generator', icon: '📝', version: '1.0.0', status: 'inactive', score: 78 },
      { id: 'lint-fixer', name: 'Lint Fixer', icon: '✨', version: '1.1.0', status: 'active', score: 90 }
    ];
  }

  // 외부에서 호출 가능한 메서드들
  refreshStats() {
    this.components.stats.fetchStats();
  }

  highlightPlugin(pluginId) {
    this.components.plugins.selectPlugin(pluginId);
  }

  getSelectedPlugin() {
    const id = this.components.plugins.state.selectedId;
    return this.components.plugins.state.plugins.find(p => p.id === id);
  }

  destroy() {
    Object.values(this.components).forEach(c => c.destroy());
    super.destroy();
  }
}

// CSS 스타일
const style = document.createElement('style');
style.textContent = `
  .scout-overview {
    display: flex;
    flex-direction: column;
    gap: 24px;
    padding: 24px;
  }
  .scout-overview .overview-section {
    margin-bottom: 8px;
  }
  .scout-overview .overview-grid {
    display: grid;
    grid-template-columns: 1fr 350px;
    gap: 24px;
  }
  .scout-overview .section-title {
    font-size: 14px;
    font-weight: 600;
    color: var(--text-primary);
    margin-bottom: 12px;
  }
  @media (max-width: 1024px) {
    .scout-overview .overview-grid {
      grid-template-columns: 1fr;
    }
  }
`;
document.head.appendChild(style);

export default ScoutOverview;
