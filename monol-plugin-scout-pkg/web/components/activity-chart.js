/**
 * Scout Activity Chart Component
 * 플러그인 활동 차트를 표시하는 컴포넌트
 */

import { MonolComponent } from '/design-system/component-base.js';

export class ScoutActivityChart extends MonolComponent {
  constructor(container, options = {}) {
    super(container, options);
    this.chart = null;
    this.state = {
      period: options.period || '7d',
      data: options.data || null
    };
  }

  async init() {
    if (this.options.apiUrl) {
      await this.fetchData();
    }
    this.render();
  }

  async fetchData() {
    try {
      const url = `${this.options.apiUrl}?period=${this.state.period}`;
      const response = await fetch(url);
      this.state.data = await response.json();
    } catch (error) {
      console.error('Failed to fetch activity data:', error);
    }
  }

  render() {
    this.container.innerHTML = this.html`
      <div class="scout-activity-chart">
        <div class="chart-header">
          <h3 class="chart-title">${this.options.title || 'Plugin Activity'}</h3>
          <div class="chart-controls">
            <button class="period-btn ${this.state.period === '7d' ? 'active' : ''}" data-period="7d">7D</button>
            <button class="period-btn ${this.state.period === '30d' ? 'active' : ''}" data-period="30d">30D</button>
            <button class="period-btn ${this.state.period === '90d' ? 'active' : ''}" data-period="90d">90D</button>
          </div>
        </div>
        <div class="chart-body">
          <canvas id="${this.getCanvasId()}"></canvas>
        </div>
      </div>
    `;

    this.bindEvents();
    this.renderChart();
  }

  getCanvasId() {
    return `scout-chart-${this.options.id || Math.random().toString(36).substr(2, 9)}`;
  }

  renderChart() {
    const canvas = this.container.querySelector('canvas');
    if (!canvas) return;

    // 기존 차트 파괴
    if (this.chart) {
      this.chart.destroy();
    }

    const ctx = canvas.getContext('2d');
    const data = this.state.data || this.getMockData();

    // MonolCharts 사용 가능하면 사용
    if (window.MonolCharts) {
      this.chart = MonolCharts.createLineChart(ctx, data.labels, [{
        label: 'Plugin Usage',
        data: data.values,
        color: MonolCharts.colors.cyan
      }]);
    } else {
      // 직접 Chart.js 사용
      this.chart = new Chart(ctx, {
        type: 'line',
        data: {
          labels: data.labels,
          datasets: [{
            label: 'Plugin Usage',
            data: data.values,
            borderColor: '#39c5cf',
            backgroundColor: 'rgba(57, 197, 207, 0.1)',
            fill: true,
            tension: 0.4
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          plugins: {
            legend: { display: false }
          },
          scales: {
            x: {
              grid: { display: false },
              ticks: { color: '#8b949e' }
            },
            y: {
              grid: { color: '#30363d' },
              ticks: { color: '#8b949e' },
              beginAtZero: true
            }
          }
        }
      });
    }
  }

  getMockData() {
    const days = this.state.period === '7d' ? 7 : this.state.period === '30d' ? 30 : 90;
    const labels = [];
    const values = [];

    for (let i = days - 1; i >= 0; i--) {
      const d = new Date();
      d.setDate(d.getDate() - i);
      labels.push(d.toLocaleDateString('ko-KR', { month: 'short', day: 'numeric' }));
      values.push(Math.floor(Math.random() * 100) + 20);
    }

    return { labels, values };
  }

  bindEvents() {
    this.container.querySelectorAll('.period-btn').forEach(btn => {
      btn.addEventListener('click', async () => {
        this.state.period = btn.dataset.period;
        if (this.options.apiUrl) {
          await this.fetchData();
        }
        this.render();
        this.emit('period-change', { period: this.state.period });
      });
    });
  }

  updateData(newData) {
    this.state.data = newData;
    this.renderChart();
  }

  destroy() {
    if (this.chart) {
      this.chart.destroy();
    }
    super.destroy();
  }
}

// CSS 스타일
const style = document.createElement('style');
style.textContent = `
  .scout-activity-chart {
    background: var(--bg-secondary);
    border: 1px solid var(--border-color);
    border-radius: var(--radius-md, 8px);
    overflow: hidden;
  }
  .scout-activity-chart .chart-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 16px;
    border-bottom: 1px solid var(--border-color);
  }
  .scout-activity-chart .chart-title {
    font-size: 14px;
    font-weight: 600;
    color: var(--text-primary);
  }
  .scout-activity-chart .chart-controls {
    display: flex;
    gap: 4px;
  }
  .scout-activity-chart .period-btn {
    padding: 4px 10px;
    background: var(--bg-tertiary);
    border: 1px solid var(--border-color);
    border-radius: 4px;
    color: var(--text-secondary);
    font-size: 11px;
    cursor: pointer;
    transition: all 0.2s;
  }
  .scout-activity-chart .period-btn:hover {
    border-color: var(--accent-blue);
    color: var(--text-primary);
  }
  .scout-activity-chart .period-btn.active {
    background: var(--accent-blue);
    border-color: var(--accent-blue);
    color: white;
  }
  .scout-activity-chart .chart-body {
    padding: 16px;
    height: 250px;
  }
`;
document.head.appendChild(style);

export default ScoutActivityChart;
