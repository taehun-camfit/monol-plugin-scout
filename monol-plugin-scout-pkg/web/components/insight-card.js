/**
 * Scout Insight Card Component
 * 인사이트 카드 컴포넌트
 */

import { MonolComponent } from '/design-system/component-base.js';

export class ScoutInsightCard extends MonolComponent {
  constructor(container, options = {}) {
    super(container, options);
    this.state = {
      insights: options.insights || [],
      selectedType: 'all',
      loading: true
    };
  }

  async init() {
    if (this.options.apiUrl) {
      await this.fetchInsights();
    } else {
      this.state.insights = this.getMockInsights();
    }
    this.state.loading = false;
    this.render();
  }

  getMockInsights() {
    return [
      { id: 'ins-001', type: 'recommendation', title: 'Consider using TypeScript strict mode', description: 'Based on your codebase patterns, enabling strict mode could catch 15% more potential bugs.', impact: 'high', plugin: 'typescript-analyzer' },
      { id: 'ins-002', type: 'warning', title: 'Unused dependencies detected', description: '3 packages in package.json are not imported anywhere: lodash, moment, axios.', impact: 'medium', plugin: 'dep-scanner' },
      { id: 'ins-003', type: 'tip', title: 'New plugin available', description: 'code-reviewer v2.0 released with AI-powered suggestions. Compatible with your project.', impact: 'low', plugin: 'marketplace' },
      { id: 'ins-004', type: 'recommendation', title: 'Optimize bundle size', description: 'Your bundle is 2.3MB. Consider code splitting for 40% size reduction.', impact: 'high', plugin: 'bundle-analyzer' },
      { id: 'ins-005', type: 'tip', title: 'Team activity spike', description: 'Your team had 3x more sessions this week. Consider scheduling a knowledge share.', impact: 'low', plugin: 'team-insights' }
    ];
  }

  async fetchInsights() {
    try {
      const response = await fetch(this.options.apiUrl);
      this.state.insights = await response.json();
    } catch (error) {
      console.error('Failed to fetch insights:', error);
      this.state.insights = this.getMockInsights();
    }
  }

  getFilteredInsights() {
    const { insights, selectedType } = this.state;
    if (selectedType === 'all') return insights;
    return insights.filter(i => i.type === selectedType);
  }

  render() {
    const { loading, selectedType } = this.state;
    const insights = this.getFilteredInsights();
    const counts = {
      all: this.state.insights.length,
      recommendation: this.state.insights.filter(i => i.type === 'recommendation').length,
      warning: this.state.insights.filter(i => i.type === 'warning').length,
      tip: this.state.insights.filter(i => i.type === 'tip').length
    };

    if (loading) {
      this.container.innerHTML = this.html`
        <div class="scout-insight-card loading">
          <div class="loading-spinner"></div>
        </div>
      `;
      return;
    }

    this.container.innerHTML = this.html`
      <div class="scout-insight-card">
        <div class="card-header">
          <h3>Insights</h3>
          <span class="insight-count">${insights.length} active</span>
        </div>
        <div class="type-filters">
          <button class="type-btn ${selectedType === 'all' ? 'active' : ''}" data-type="all">
            All <span class="count">${counts.all}</span>
          </button>
          <button class="type-btn type-recommendation ${selectedType === 'recommendation' ? 'active' : ''}" data-type="recommendation">
            &#x1F4A1; Recommendations <span class="count">${counts.recommendation}</span>
          </button>
          <button class="type-btn type-warning ${selectedType === 'warning' ? 'active' : ''}" data-type="warning">
            &#x26A0;&#xFE0F; Warnings <span class="count">${counts.warning}</span>
          </button>
          <button class="type-btn type-tip ${selectedType === 'tip' ? 'active' : ''}" data-type="tip">
            &#x2728; Tips <span class="count">${counts.tip}</span>
          </button>
        </div>
        <div class="insight-items">
          ${insights.length === 0
            ? '<div class="empty-state">No insights available</div>'
            : insights.map(i => this.renderInsight(i)).join('')}
        </div>
      </div>
    `;

    this.bindEvents();
  }

  renderInsight(insight) {
    const typeIcon = {
      'recommendation': '&#x1F4A1;',
      'warning': '&#x26A0;&#xFE0F;',
      'tip': '&#x2728;'
    }[insight.type] || '&#x1F4A1;';

    const impactClass = {
      'high': 'impact-high',
      'medium': 'impact-medium',
      'low': 'impact-low'
    }[insight.impact] || '';

    return this.html`
      <div class="insight-item type-${insight.type} ${impactClass}" data-id="${insight.id}">
        <div class="insight-icon">${typeIcon}</div>
        <div class="insight-content">
          <div class="insight-title">${insight.title}</div>
          <div class="insight-description">${insight.description}</div>
          <div class="insight-meta">
            <span class="insight-plugin">&#x1F50C; ${insight.plugin}</span>
            <span class="insight-impact impact-badge-${insight.impact}">${insight.impact} impact</span>
          </div>
        </div>
        <div class="insight-actions">
          <button class="action-btn apply-btn" title="Apply">&#x2705;</button>
          <button class="action-btn dismiss-btn" title="Dismiss">&#x274C;</button>
        </div>
      </div>
    `;
  }

  bindEvents() {
    // Type filter
    this.container.querySelectorAll('.type-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        this.state.selectedType = btn.dataset.type;
        this.render();
      });
    });

    // Insight actions
    this.container.querySelectorAll('.insight-item').forEach(item => {
      const id = item.dataset.id;
      const insight = this.state.insights.find(i => i.id === id);

      item.addEventListener('click', () => {
        this.emit('insight-select', insight);
      });

      item.querySelector('.apply-btn')?.addEventListener('click', (e) => {
        e.stopPropagation();
        this.emit('insight-apply', insight);
        // Remove from list
        this.state.insights = this.state.insights.filter(i => i.id !== id);
        this.render();
      });

      item.querySelector('.dismiss-btn')?.addEventListener('click', (e) => {
        e.stopPropagation();
        this.emit('insight-dismiss', insight);
        // Remove from list
        this.state.insights = this.state.insights.filter(i => i.id !== id);
        this.render();
      });
    });
  }
}

// CSS
const style = document.createElement('style');
style.textContent = `
  .scout-insight-card {
    background: var(--bg-secondary);
    border: 1px solid var(--border-color);
    border-radius: var(--radius-md, 8px);
    padding: 16px;
  }
  .scout-insight-card.loading {
    display: flex;
    justify-content: center;
    align-items: center;
    min-height: 200px;
  }
  .scout-insight-card .loading-spinner {
    width: 24px;
    height: 24px;
    border: 2px solid var(--border-color);
    border-top-color: var(--accent-cyan);
    border-radius: 50%;
    animation: spin 1s linear infinite;
  }
  .scout-insight-card .card-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 12px;
  }
  .scout-insight-card .card-header h3 {
    font-size: 14px;
    font-weight: 600;
    margin: 0;
  }
  .scout-insight-card .insight-count {
    font-size: 12px;
    color: var(--text-secondary);
  }
  .scout-insight-card .type-filters {
    display: flex;
    gap: 4px;
    margin-bottom: 12px;
    flex-wrap: wrap;
  }
  .scout-insight-card .type-btn {
    padding: 6px 10px;
    border: none;
    background: var(--bg-tertiary);
    border-radius: 16px;
    font-size: 11px;
    cursor: pointer;
    color: var(--text-secondary);
    transition: all 0.2s;
    display: flex;
    align-items: center;
    gap: 4px;
  }
  .scout-insight-card .type-btn:hover {
    color: var(--text-primary);
    background: var(--bg-primary);
  }
  .scout-insight-card .type-btn.active {
    background: var(--accent-cyan);
    color: #000;
  }
  .scout-insight-card .type-btn.type-recommendation.active {
    background: var(--accent-purple, #A371F7);
  }
  .scout-insight-card .type-btn.type-warning.active {
    background: var(--accent-yellow, #FFE66D);
    color: #000;
  }
  .scout-insight-card .type-btn.type-tip.active {
    background: var(--accent-green);
    color: #000;
  }
  .scout-insight-card .type-btn .count {
    padding: 0 4px;
    background: rgba(0,0,0,0.2);
    border-radius: 8px;
    font-size: 10px;
  }
  .scout-insight-card .insight-items {
    display: flex;
    flex-direction: column;
    gap: 8px;
    max-height: 350px;
    overflow-y: auto;
  }
  .scout-insight-card .empty-state {
    text-align: center;
    padding: 32px;
    color: var(--text-secondary);
    font-size: 13px;
  }
  .scout-insight-card .insight-item {
    display: flex;
    align-items: flex-start;
    gap: 12px;
    padding: 12px;
    background: var(--bg-tertiary);
    border: 1px solid var(--border-color);
    border-radius: 8px;
    cursor: pointer;
    transition: all 0.2s;
  }
  .scout-insight-card .insight-item:hover {
    border-color: var(--accent-cyan);
  }
  .scout-insight-card .insight-item.type-recommendation {
    border-left: 3px solid var(--accent-purple, #A371F7);
  }
  .scout-insight-card .insight-item.type-warning {
    border-left: 3px solid var(--accent-yellow, #FFE66D);
  }
  .scout-insight-card .insight-item.type-tip {
    border-left: 3px solid var(--accent-green);
  }
  .scout-insight-card .insight-item.impact-high {
    background: rgba(255, 107, 107, 0.05);
  }
  .scout-insight-card .insight-icon {
    font-size: 18px;
    flex-shrink: 0;
    padding-top: 2px;
  }
  .scout-insight-card .insight-content {
    flex: 1;
    min-width: 0;
  }
  .scout-insight-card .insight-title {
    font-size: 13px;
    font-weight: 500;
    color: var(--text-primary);
    margin-bottom: 4px;
  }
  .scout-insight-card .insight-description {
    font-size: 12px;
    color: var(--text-secondary);
    line-height: 1.4;
    margin-bottom: 6px;
  }
  .scout-insight-card .insight-meta {
    display: flex;
    gap: 12px;
    font-size: 10px;
    color: var(--text-muted);
  }
  .scout-insight-card .insight-plugin {
    color: var(--text-secondary);
  }
  .scout-insight-card .insight-impact {
    padding: 1px 6px;
    border-radius: 4px;
    font-weight: 500;
  }
  .scout-insight-card .impact-badge-high {
    background: rgba(255, 107, 107, 0.2);
    color: var(--accent-red, #FF6B6B);
  }
  .scout-insight-card .impact-badge-medium {
    background: rgba(255, 230, 109, 0.2);
    color: var(--accent-yellow, #FFE66D);
  }
  .scout-insight-card .impact-badge-low {
    background: rgba(50, 205, 50, 0.2);
    color: var(--accent-green);
  }
  .scout-insight-card .insight-actions {
    display: flex;
    gap: 4px;
    opacity: 0;
    transition: opacity 0.2s;
  }
  .scout-insight-card .insight-item:hover .insight-actions {
    opacity: 1;
  }
  .scout-insight-card .action-btn {
    background: none;
    border: none;
    cursor: pointer;
    font-size: 12px;
    padding: 4px 6px;
    border-radius: 4px;
    transition: all 0.2s;
  }
  .scout-insight-card .action-btn:hover {
    background: var(--bg-primary);
  }
`;
document.head.appendChild(style);

export default ScoutInsightCard;
